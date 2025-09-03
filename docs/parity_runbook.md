# Parity Runbook
**Generated:** 2025-09-01T04:24:34Z

1. Ensure your symlinks are in place (Experts/Rewrite, Experts/Baseline, Include/EuroScalper).
2. Open MetaEditor from the **same** terminal (build 1143).
3. Open **baseline instrumented EA** and **Compile (F7)**.
4. In Strategy Tester:
   - Modeling: **Every tick**
   - Symbol/TF: **EURUSD M5**
   - Spread: **2 points**
   - Deposit: **10000**, Leverage: **1:500**
   - Server TZ assumption: **GMT+3**
5. Run the initial scenarios (see `tests/parity/SCENARIOS.yaml`) and collect CSV logs from **MQL4/Files**.
