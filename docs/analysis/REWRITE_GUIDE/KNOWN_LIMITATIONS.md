
# Known Limitations / Oddities in Decompiled Build

- `Filter_Sideway`, `Filter_News`, `invisible_mode` are declared but unused.
- `I_d_82` offset remains 0; BE/alt TP paths using it are effectively no-ops.
- Some selection conditions use odd logic (likely decompiler artifacts); parity rewrite should keep behavior, not style.
- Slippage/lot rounding defaults are embedded; consider exposing clean inputs in rewrite (behind a parity flag).
