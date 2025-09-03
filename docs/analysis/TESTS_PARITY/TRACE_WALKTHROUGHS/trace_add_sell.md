
# Trace: Add SELL
- SELL side present; check |Bid - last_sell_price| >= Step*_Point
- if yes: compute next lots by progression; f0_15(1, lots, Bid, slippage, ...)
- recalc avg and TP = avg - TP*_Point; sync via OrderModify
