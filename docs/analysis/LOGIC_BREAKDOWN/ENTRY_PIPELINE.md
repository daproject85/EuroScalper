
# Entry Pipeline (Market Orders)

1. **Session & daily-range gates**
   - Hours: `Open_Hour`→`Close_Hour` with wrap-around handling (24→0). Thursday/Friday additional cutoffs.
   - Daily open-range gate: compute today's open (`iOpen`) and allow only within `[open+OpenRangePips, open+OpenRangePips+MaxDailyRange]` window.
2. **De-dup & side presence**
   - Flags `I_b_18`/`I_b_19` summarize whether BUY/SELL baskets exist.
3. **Signal**
   - If `Close[2] > Close[1]` → **SELL**; else → **BUY**.
4. **Lot sizing choice (`I_i_98`)**
   - `0`: fixed lot = `I_d_44` (derived from `Lot` or balance % formula).
   - `1`: progression by current cycle index `I_i_90` using `LotMultiplikator` (or additive if `I_i_77 != 1`).
   - `2`: progression based on most recent *closed* losing trade size.
5. **Grid add check**
   - If side already exists, require `|price - last_entry_side| >= Step * _Point` (and optionally tick-volume conditions when `I_b_20` is true).
6. **OrderSend**
   - Use wrapper `f0_15(side, lots, price, slippage, ...)`.
   - On success: increment `I_i_76` (averaging counter). On error 134 (not enough money) mark lotsize result with -2.
