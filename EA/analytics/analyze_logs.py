#!/usr/bin/env python3
import json
import os
import sys

def analyze():
    # Absolute path to the JSONL logs
    log_path = '/home/newuser/docker/mt5-workbench/volumes/config/.wine/drive_c/Program Files/MetaTrader 5/MQL5/Files/afrikenkid/afrikenkid_logs.jsonl'
    
    if not os.path.exists(log_path):
        print(json.dumps({"error": f"Log file not found at {log_path}"}))
        return

    total_trades = 0
    wins = 0
    losses = 0
    total_net_pnl = 0.0
    total_commission = 0.0
    total_swap = 0.0

    mfe_values = []
    mae_values = []
    net_pnl_values = []
    
    profit_wasted_count = 0 

    # MT5 files are often UTF-16. We use 'utf-16' or 'latin-1' to avoid decode errors
    # We try utf-16 first as it's standard for Windows/MT5
    try:
        with open(log_path, 'r', encoding='utf-16') as f:
            lines = f.readlines()
    except UnicodeError:
        try:
            with open(log_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except UnicodeError:
            with open(log_path, 'r', encoding='latin-1') as f:
                lines = f.readlines()

    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            if entry.get("event") == "TRADE_ANALYTICS":
                data = entry.get("data", {})
                total_trades += 1
                net_pnl = data.get("final_net_pnl", 0.0)
                mfe = data.get("max_pnl", 0.0)
                mae = data.get("min_pnl", 0.0)
                
                net_pnl_values.append(net_pnl)
                mfe_values.append(mfe)
                mae_values.append(mae)
                
                total_net_pnl += net_pnl
                total_commission += data.get("commission", 0.0)
                total_swap += data.get("swap", 0.0)
                
                if net_pnl > 0:
                    wins += 1
                else:
                    losses += 1
                
                if mfe > 5.0 and net_pnl <= 0.1:
                    profit_wasted_count += 1

        except json.JSONDecodeError:
            continue

    if total_trades == 0:
        print(json.dumps({"error": "No trade analytics records found. Check if logs are empty or encoded differently."}))
        return

    avg_mfe = sum(mfe_values) / total_trades
    avg_mae = sum(mae_values) / total_trades
    avg_net = total_net_pnl / total_trades
    win_rate = (wins / total_trades) * 100
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
            "max_mfe_recorded": round(max(mfe_values) if mfe_values else 0, 2),
            "avg_mae": round(avg_mae, 2),
            "worst_mae_recorded": round(min(mae_values) if mae_values else 0, 2),
            "profit_leakage_trades": profit_wasted_count
        },
        "heuristic_suggestions": {
            "suggested_risk_drawdown_limit": round(suggested_tight_sl_atr, 2),
            "is_stagnation_exit_leaking": True if profit_wasted_count / total_trades > 0.25 else False
        }
    }
    print(json.dumps(metrics, indent=2))

if __name__ == "__main__":
    analyze()
