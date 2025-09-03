
# Pseudocode

## init()
- Set display strings and hints.
- Map `_Symbol` → `I_i_0` magic; default 999999 if unknown.
- Initialize rounding (`I_d_67=2`), slippage (`I_d_34≈5`), defaults for filters and flags.

## start()
- If `Use_Daily_Target`: sum today’s closed profit for `I_i_0`; if ≥ `Daily_Target` → close all market orders.
- If `Hidden_TP`: sum floating P/L for current symbol; if ≥ `Hiden_TP` → close all market orders.
- Maintain sticky `I_d_43` balance to detect external cash changes when flat.
- Decide base lot `I_d_44` (fixed vs balance) and bump via `Averaging`/`I_i_77` rules.
- Scan orders to compute: side presence, last entry prices `I_d_63/I_d_64`, and counts `I_i_88`.
- If side exists:
  - If out-of-session or kill switch → `f0_1` to close that side (and compute next lot by flip rules).
  - Else if distance ≥ `Step` (and optional volume gate) → compute lot & `f0_15` to add.
- If no side:
  - Apply daily-range/session gate; derive direction by `Close[2]` vs `Close[1]`; compute lot; `f0_15` to open first order.
- Recompute basket average and set TP price for each order via `OrderModify`.
- If `UseEquityStop`: compute drawdown vs equity; if threshold exceeded → close all.

## deinit()
- Clear chart comment.
