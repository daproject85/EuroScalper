
# Money & Risk

- **Base lot (`I_d_44`)**:
  - If `I_b_10` (fixed lot mode): `I_d_44 = Lot`.
  - Else (balance mode): 
    - First time: `I_d_44 = (AccountBalance() * I_d_105 / 100) / 10000`
    - After `Averaging` sends: if multiplicative mode (`I_i_77==1`) multiply by `LotMultiplikator`; else add `Lot`.
- **Progression index**: `I_i_90 = I_i_88` (current number of open orders). Lot decision uses either current cycle or last losing ticket (mode 2).
- **Normalize lots** using `I_d_67` digits.
- **Max exposure**: Prevent adds when `I_i_88 >= MaxTrades`.
- **Equity stop**: Close all if `abs(floating P/L)` > `TotalEquityRisk% * Equity`.
