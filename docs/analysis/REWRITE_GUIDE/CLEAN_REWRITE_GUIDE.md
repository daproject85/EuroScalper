
# Clean Rewrite Guide

## Naming & Structure
- Rename obfuscated globals to intent-revealing identifiers (e.g., `I_i_88` → `open_count`, `I_d_48` → `avg_price`).
- Extract modules: `session_gates`, `range_gate`, `lot_model`, `grid_add`, `basket_tp`, `closers`.
- No side-effects in getters; pure functions for calculations.

## Behavior to Preserve (Parity)
- Two-close direction rule and add-step distance.
- Lot progression math, including mode 2 (last losing lot) behavior.
- Basket TP = weighted average ± TP points and the sync cadence.
- Daily target, hidden TP, equity stop exact thresholds.
- Magic mapping.

## Staged Plan
1. **Wrap MT4 API** with safe helpers (normalize, retry table, error log).
2. Replace globals with `struct` state passed through functions.
3. Add deterministic logging matching `LOG_SCHEMA.md`.
4. Validate with `SCENARIOS.yaml` fixtures on historical replays.
