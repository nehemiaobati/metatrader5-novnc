#!/usr/bin/env python3
"""
MAYA Quant-System - Trade Log Analyzer
Parses MT5 JSONL logs using streaming O(1) memory evaluation.
"""

import json
import os
import sys

def detect_encoding(file_path: str) -> str:
    """Deterministically identifies file encoding from BOM or standard fallback."""
    with open(file_path, 'rb') as f:
        bom = f.read(4)

    if bom.startswith(b'\xff\xfe\x00\x00') or bom.startswith(b'\x00\x00\xfe\xff'):
        return 'utf-32'
    if bom.startswith(b'\xff\xfe'):
        return 'utf-16-le'
    if bom.startswith(b'\xfe\xff'):
        return 'utf-16-be'
    if bom.startswith(b'\xef\xbb\xbf'):
        return 'utf-8-sig'
    return 'utf-8'

def get_default_log_path() -> str:
    """Resolves log path dynamically relative to the repository root."""
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
    return os.path.join(
        base_dir,
        "volumes/config/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files/afrikenkid/afrikenkid_logs.jsonl"
    )

def analyze(log_path: str = None) -> None:
    if log_path is None:
        log_path = os.environ.get("LOG_PATH") or (sys.argv[1] if len(sys.argv) > 1 else get_default_log_path())

    if not os.path.exists(log_path):
        print(json.dumps({"error": f"Log file not found at {log_path}"}))
        sys.exit(1)

    encoding = detect_encoding(log_path)

    total_trades = 0
    wins = 0
    losses = 0
    total_net_pnl = 0.0
    total_commission = 0.0
    total_swap = 0.0

    mfe_sum = 0.0
    max_mfe = float("-inf")
    mae_sum = 0.0
    worst_mae = float("inf")
    profit_wasted_count = 0

    # Stream line-by-line to achieve O(1) memory complexity
    with open(log_path, 'r', encoding=encoding, errors='replace') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            if entry.get("event") != "TRADE_ANALYTICS":
                continue

            data = entry.get("data", {})
            total_trades += 1

            net_pnl = float(data.get("final_net_pnl", 0.0))
            mfe = float(data.get("max_pnl", 0.0))
            mae = float(data.get("min_pnl", 0.0))

            total_net_pnl += net_pnl
            total_commission += float(data.get("commission", 0.0))
            total_swap += float(data.get("swap", 0.0))

            mfe_sum += mfe
            if mfe > max_mfe:
                max_mfe = mfe

            mae_sum += mae
            if mae < worst_mae:
                worst_mae = mae

            if net_pnl > 0:
                wins += 1
            else:
                losses += 1

            if mfe > 5.0 and net_pnl <= 0.1:
                profit_wasted_count += 1

    if total_trades == 0:
        print(json.dumps({"error": "No trade analytics records found in log file."}))
        return

    avg_mfe = mfe_sum / total_trades
    avg_mae = mae_sum / total_trades
    avg_net = total_net_pnl / total_trades
    win_rate = (wins / total_trades) * 100.0
    suggested_tight_sl_atr = avg_mae * 1.2

    metrics = {
        "summary": {
            "total_trades": total_trades,
            "win_rate_percent": round(win_rate, 2),
            "net_pnl": round(total_net_pnl, 2),
            "avg_net_pnl_per_trade": round(avg_net, 2),
            "commission_total": round(total_commission, 2),
            "swap_total": round(total_swap, 2)
        },
        "quant_curves": {
            "avg_mfe": round(avg_mfe, 2),
            "max_mfe_recorded": round(max_mfe if max_mfe != float("-inf") else 0.0, 2),
            "avg_mae": round(avg_mae, 2),
            "worst_mae_recorded": round(worst_mae if worst_mae != float("inf") else 0.0, 2),
            "profit_leakage_trades": profit_wasted_count
        },
        "heuristic_suggestions": {
            "suggested_risk_drawdown_limit": round(suggested_tight_sl_atr, 2),
            "is_stagnation_exit_leaking": (profit_wasted_count / total_trades) > 0.25
        }
    }

    print(json.dumps(metrics, indent=2))

if __name__ == "__main__":
    analyze()
