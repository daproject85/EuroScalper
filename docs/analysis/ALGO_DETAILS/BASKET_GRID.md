
# Basket / Grid Behavior

- **Entry spacing**: `Step * _Point` between consecutive entries on the same side.
- **Side detection**: `I_b_18` (BUY side present), `I_b_19` (SELL side present).
- **Add conditions**: Distance gate and optional tick-volume gate (`I_b_20`).
- **TP unification**: Basket TP synchronized to average±TP.
- **Averaging bump**: After `Averaging` successful sends (`I_i_76`), bump base lot once, then reset `I_i_76 = -2`.
