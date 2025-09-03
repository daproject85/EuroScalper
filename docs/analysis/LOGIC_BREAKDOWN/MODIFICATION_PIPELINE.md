
# Modification Pipeline (Basket TP Sync)

- After a (new) entry or when flagged:
  1. Recompute **weighted average entry** across all open orders for this symbol/magic into `I_d_48`.
  2. Compute side TP price:
     - BUY: `I_d_80 = I_d_48 + TakeProfit * _Point`
     - SELL: `I_d_80 = I_d_48 - TakeProfit * _Point`
  3. Iterate each order and `OrderModify(..., tp=I_d_80)` to **synchronize** TP.
  4. Trailing / BE (`f0_18`) is **available** but disabled by default; if enabled, it walks SL forward using thresholds `I_d_49/I_d_50`.
