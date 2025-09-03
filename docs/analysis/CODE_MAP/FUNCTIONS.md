# Functions

## init()
- **Summary:** Initialize UI strings and symbol→magic map; set rounding/flags; precompute spread; set default slippage/lot mode hints.
- **Approx. size:** 138 lines

## start()
- **Summary:** Main tick loop: gates (daily/hidden TP; session; range; equity stop), detect current basket state, compute lot size, add entries, and synchronize basket TP.
- **Approx. size:** 1425 lines

## deinit()
- **Summary:** Cleanup (only clears chart comment).
- **Approx. size:** 7 lines

## f0_1(bool FuncArg_Boolean_00000000, bool FuncArg_Boolean_00000001)
- **Summary:** Helper: Close BUY and/or SELL positions for this symbol/magic, with trade-context busy retries.
- **Approx. size:** 74 lines

## f0_15(int Fa_i_00, double Fa_d_01, double Fa_d_02, int Fa_i_03, double Fa_d_04, double Fa_d_05, int Fa_i_06, string Fa_s_07, int Fa_i_08, int Fa_i_09, int Fa_i_0A)
- **Summary:** Helper: Unified OrderSend wrapper (handles side, price→stop level normalization, ECN behavior, retry on busy/requote errors). Returns ticket or error.
- **Approx. size:** 314 lines

## f0_18(int Fa_i_00, int Fa_i_01, double Fa_d_02)
- **Summary:** Helper: Trailing/BE adjuster. Iterates orders and moves SL based on thresholds (disabled by default).
- **Approx. size:** 47 lines
