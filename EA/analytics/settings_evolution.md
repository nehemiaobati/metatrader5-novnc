# AFRIKENKID / MAYA - Settings Evolution Log
## Target Asset: XAUUSD (Gold) | O(1) Continuous Optimization

### 1. Active Configuration & Recommendations
*Last Evaluated: 2026-05-30 | Analysis: 208 Trades Logged*

| Parameter Name | Original | Current Value | Recommended | Control Flag | Quantitative Justification (MFE / MAE / Metrics) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| InpEnableVerboseLogging | true | true | true | ❌ FORBIDDEN | Fixed baseline |
| InpSlippagePoints | 30 | 30 | 30 | ❌ FORBIDDEN | Fixed baseline |
| InpPrimaryTF1 | PERIOD_M1 | PERIOD_M1 | PERIOD_M1 | ✅ ALLOWED | No volatility signal change req. |
| InpPrimaryTF2 | PERIOD_M1 | PERIOD_M1 | PERIOD_M1 | ✅ ALLOWED | No volatility signal change req. |
| InpEntryTimeframe | PERIOD_M1 | PERIOD_M1 | PERIOD_M1 | ✅ ALLOWED | No volatility signal change req. |
| InpLotSize | 0.01 | 0.01 | 0.01 | ❌ FORBIDDEN | Fixed baseline |
| InpNumberOfEntries | 1 | 1 | 1 | ❌ FORBIDDEN | Fixed baseline |
| InpMaxConcurrentPositions | 1 | 1 | 1 | ❌ FORBIDDEN | Fixed baseline |
| InpRewardToRiskRatio | 3.0 | 3.0 | 3.0 | ✅ ALLOWED | avg_mfe (259.53) supports ratio |
| InpAtrPeriod | 14 | 14 | 14 | ✅ ALLOWED | Sufficient period |
| InpAtrMultiplier | 2.4 | 5.2 | 11.0 | ✅ ALLOWED | 🔴 High: avg_mae (-159.58) & worst_mae (-1010.0) |
| InpMagicNumber | 13580 | 13580 | 13580 | ❌ FORBIDDEN | Fixed baseline |
| InpEnableMartingale | false | false | false | ❌ FORBIDDEN | Fixed baseline |
| InpMartingaleFactor | 2.0 | 2.0 | 2.0 | ❌ FORBIDDEN | Fixed baseline |
| InpMartingaleMaxLots | 10.0 | 10.0 | 10.0 | ❌ FORBIDDEN | Fixed baseline |
| InpRequiredConfidenceScore | 4 | 6 | 6 | ✅ ALLOWED | 🟢 Low: net pnl (2467.0) & win rate (50.48%) |
| InpWeightTrendFilter | 1 | 1 | 1 | ✅ ALLOWED | Baseline |
| InpWeightMomentum | 1 | 1 | 1 | ✅ ALLOWED | Baseline |
| InpWeightEntryTrigger | 1 | 1 | 1 | ✅ ALLOWED | Baseline |
| InpWeightRsiConfirm | 1 | 1 | 1 | ✅ ALLOWED | Baseline |
| InpTrendEmaPeriod | 30 | 30 | 30 | ✅ ALLOWED | Baseline |
| InpMomentumEmaFast | 9 | 9 | 9 | ✅ ALLOWED | Baseline |
| InpMomentumEmaSlow | 21 | 21 | 21 | ✅ ALLOWED | Baseline |
| InpEntryEmaPeriod | 9 | 9 | 9 | ✅ ALLOWED | Baseline |
| InpRsiPeriod | 14 | 14 | 14 | ✅ ALLOWED | Baseline |
| InpRsiBuyLevelUpper | 70 | 70 | 70 | ✅ ALLOWED | Baseline |
| InpRsiBuyLevelLower | 50 | 50 | 50 | ✅ ALLOWED | Baseline |
| InpRsiSellLevelUpper | 50 | 50 | 50 | ✅ ALLOWED | Baseline |
| InpRsiSellLevelLower | 30 | 30 | 30 | ✅ ALLOWED | Baseline |
| InpVolatilityAtrPeriod | 14 | 14 | 14 | ✅ ALLOWED | Baseline |
| InpVolatilityAtrMaPeriod | 45 | 45 | 45 | ✅ ALLOWED | Baseline |
| InpMaxVolatilityRatio | 2.0 | 2.0 | 2.0 | ✅ ALLOWED | Baseline |
| InpVolumeMaPeriod | 20 | 20 | 20 | ✅ ALLOWED | Baseline |
| InpMinVolumeRatio | 0.8 | 0.8 | 0.8 | ✅ ALLOWED | Baseline |
| InpEnableTrailingStop | true | true | true | ❌ FORBIDDEN | Fixed baseline |
| InpTrailingTriggerRatio | 0.3 | 0.6 | 0.95 | ✅ ALLOWED | 🟡 Med: profit leakage (70 trades) vs avg_mfe (259.53) |
| InpTrailingDistanceRatio | 1.0 | 1.0 | 1.0 | ✅ ALLOWED | Baseline |
| InpTrailingRatio | 0.75 | 0.75 | 0.75 | ✅ ALLOWED | Baseline |
| InpDrawdownRatchetRatio | 0.50 | 0.50 | 0.50 | ✅ ALLOWED | Baseline |
| InpExitRsiBuyLevel | 40 | 40 | 40 | ✅ ALLOWED | Baseline |
| InpExitRsiSellLevel | 60 | 60 | 60 | ✅ ALLOWED | Baseline |
| InpStagnationCandles | 20 | 5 | 1 | ✅ ALLOWED | 🔴 High: is_stagnation_exit_leaking = true |
| InpEnableProfitTargetExit | false | false | false | ❌ FORBIDDEN | Fixed baseline |
| InpProfitTargetAmount | 10.0 | 10.0 | 10.0 | ❌ FORBIDDEN | Fixed baseline |
| InpUseAccountProtection | false | false | false | ❌ FORBIDDEN | Fixed baseline |
| InpTargetEquity | 0 | 0 | 0 | ❌ FORBIDDEN | Fixed baseline |
| InpTargetBalance | 0 | 0 | 0 | ❌ FORBIDDEN | Fixed baseline |
| InpResumeHour | 3 | 3 | 3 | ❌ FORBIDDEN | Fixed baseline |
| InpResumeMinute | 0 | 0 | 0 | ❌ FORBIDDEN | Fixed baseline |

---

### 2. Historical Iterations (Last 3 Steps)

#### Iteration 20 (2026-05-30)
- **Changes Made:** Metrics updated to 208 trades. Increased InpAtrMultiplier (9.5 -> 11.0) to buffer worst_mae (-1010.0). Incremented InpTrailingTriggerRatio (0.90 -> 0.95) to suppress profit leakage (70 trades).
- **Result:** Net PnL (2467.0), Win Rate (50.48%), Profit Leakage (70 trades).

#### Iteration 19 (2026-05-30)
- **Changes Made:** Metrics updated to 208 trades. Increased InpAtrMultiplier (9.0 -> 9.5) to further buffer against worst_mae (-1010.0). Incremented InpTrailingTriggerRatio (0.85 -> 0.90) to further suppress profit leakage (70 trades).
- **Result:** Net PnL (2467.0), Win Rate (50.48%), Profit Leakage (70 trades).

#### Iteration 18 (2026-05-29)
- **Changes Made:** Metrics updated to 207 trades. Increased InpAtrMultiplier (8.5 -> 9.0) to counter worst_mae (-1010.0). Incremented InpTrailingTriggerRatio (0.8 -> 0.85) to minimize leakage (70 trades).
- **Result:** Net PnL (2553.0), Win Rate (50.72%), Profit Leakage (70 trades).
