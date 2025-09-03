
# Broker Gotchas & Normalization

- Uses `_Point/_Digits` to normalize prices and lots.
- ECN behavior handled by applying TP via `OrderModify` after fill.
- Error handling in wrappers includes busy/requote codes 4/137/146.
- Magic numbers are **per-symbol**; if a symbol is unmapped, magic defaults to `999999`.
- TP/Step values are **in points** (e.g., on 5-digit quotes, 10 points = 1 pip).
