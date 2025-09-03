# EuroScalper — Parity PRD (Clear Edition)
**Generated:** 2025-09-01T00:19:55Z  
**Purpose:** A single, readable source for **what to build** (Requirements) and **how to ship it iteratively** (Phases). The phases below restate the exact requirements they implement—no cross‑references needed.

---

## A) Product Requirements (authoritative list)
Below is the complete set of requirements for the parity phase, grouped for readability.

### A1. Inputs & Naming
- **Extern inputs preserved exactly:** The new EA must expose the **exact extern parameters** (names, defaults, semantics) used by the decompiled EA. No new externs during the parity phase.
- **Readable internal naming:** Internal variables and functions in the new EA must be **intuitive and self‑descriptive** while keeping externs unchanged.
- **Legacy shim:** Maintain a `start()` shim calling `OnTick()` for compatibility.

### A2. Execution & Normalization
- **Deterministic per‑tick order:** The runtime pipeline must be strictly: **closers → session/range gates → basket scan → signal & entry/add decision → basket TP recompute & sync**. No reordering.
- **Broker normalization:** Normalize prices and lots using `_Point`, `_Digits`, `MODE_MINLOT`, `MODE_MAXLOT`, `MODE_LOTSTEP`, and respect `MODE_STOPLEVEL`/freeze levels.
- **ECN semantics:** If the baseline submits with `SL/TP=0` and modifies after fill, the new EA must do the **same**.
- **Slippage parity:** Use the same default slippage and application as baseline.
- **Multi‑digit brokers:** Identical behavior on 4/5‑digit symbols; no ×10 drift.

### A3. Signal, Entry, Adds, and Limits
- **Direction rule:** `Close[1] ≥ Close[2]` ⇒ **BUY**, else **SELL**. Entry only if all gates pass; use **Bid** for SELL, **Ask** for BUY.
- **First order lots:** Lot sizing for the first order must **match baseline** (model + rounding).
- **Add‑on spacing:** Add to an existing side only when `|price − last_entry_side| ≥ Step × _Point`.
- **Max trades:** Enforce `MaxTrades` exactly.
- **Tick volume gates:** If baseline uses any tick‑volume conditions before adding, replicate them.

### A4. Take Profit / Stop Loss
- **First order TP:** For a single order, TP is entry ± `TakeProfit × _Point` (BUY +, SELL −), identical to baseline.
- **Basket average & TP:** Compute a **lot‑weighted average** per side and set basket TP = `avg ± TakeProfit × _Point` (BUY +, SELL −). Keep the **same TP‑sync cadence** as baseline (e.g., every tick vs after entry only).
- **SL behavior:** Replicate baseline SL behavior (typically none unless trailing/BE is enabled by default).

### A5. Lot Progression
- **Parity of all modes:** Implement fixed lot; multiplicative progression via `LotMultiplikator`; additive progression (adding `Lot`); “last losing lot” mode; and the **Averaging bump** cadence/reset.
- **Indexing & resets:** Use the **same progression index** (e.g., by successful sends/open count) and **the same reset rules** (e.g., the `I_i_76` counter logic). Enforce min/max lot and step rounding exactly.

### A6. Closers & Gates
- **Hidden TP:** Close all when **floating P/L including swap & commission** ≥ `Hiden_TP`.
- **Daily target:** Close all remaining positions when **closed P/L since the current D1 open (server time)** ≥ `Daily_Target`, including swap & commission.
- **Equity stop:** If floating P/L < 0 and `abs(floating) > AccountEquity() × (TotalEquityRisk/100)`, close all.
- **Session/day gates:** Enforce trading hours with wrap‑around; apply **Thursday/Friday cutoffs** exactly; when out‑of‑session, mirror baseline behavior (block new entries and/or close active side).

### A7. Magic, Comments, Errors, State
- **Magic & comments:** Use the **exact symbol→magic** mapping and order comment strings from baseline. Always filter by **symbol + magic**.
- **Error handling & retries:** Match baseline handling/reties for errors (e.g., 4, 136/137, 146, 134 “not enough money”), including whether counters advance on failure vs success.
- **State & restart:** Replicate any sticky state (e.g., last seen balance) and reset conditions when flat.
- **Performance:** Logging must be efficient; avoid timing‑altering operations.

### A8. Logging & Acceptance
- **Shared logging framework:** Modular logging usable by **both** EAs with levels `none/basic/debug/trace`.
- **Trace details:** On relevant ticks, log enough fields to diagnose differences in entries, basket TP assignment, and closures.
- **Acceptance tests:** Require event‑sequence parity, value tolerances (prices, lots, P/L), and a fixed scenario matrix (first entry, add at Step, hidden TP, daily target, equity stop, session closure, requote, 134). 
- **Tester determinism:** Fix MT4 build/model/spread/timezone/slippage/deposit/leverage for reproducible parity.

---

## B) Development Phases (each phase restates the requirements it fulfills)
Each phase ships a testable slice. The **Requirements implemented in this phase** are fully restated below the phase so you don’t have to look elsewhere.

### Phase 0 — Preflight & Harness
**Objective:** Ensure deterministic environment and shared logging scaffold.  
**Requirements implemented here:**
- **Shared logging framework:** Provide a modular logger for both EAs with levels `none/basic/debug/trace`; deterministic, non‑blocking logging that doesn’t alter timing. 
- **Tester determinism:** Establish a fixed MT4 profile (build, modeling, spread, timezone, slippage, deposit, leverage).
- **Provenance parity:** Extract and centralize **symbol→magic mapping** and **order comments** so both EAs use the exact same values.
**Deliverables:** Tester profile + runbook; logger headers; magic/comment header.  
**Acceptance:** A dry run produces a `boot`/environment log row and empty TRACE scaffolding.

### Phase 1 — Inputs & Normalization Contract
**Objective:** Lock externs and numerical normalization before touching trading logic.  
**Requirements implemented here:**
- **Extern inputs preserved exactly; no new externs.**
- **Readable internal naming** (externs unchanged).
- **Broker normalization:** Helpers for `_Point`, `_Digits`, min/max lot, lot step; respect `MODE_STOPLEVEL`/freeze.  
- **Multi‑digit brokers:** Point/pip math identical for 4/5 digits.
**Deliverables:** EA builds with exact externs; normalization helpers; quick chart echo for manual inspection.  
**Acceptance:** Logged unit checks: rounding to lot step; points→price conversions on sample symbols.

### Phase 2 — Direction & First Entry
**Objective:** Single‑order parity (open only).  
**Requirements implemented here:**
- **Deterministic per‑tick order:** Honor the pipeline up to the entry decision.  
- **Direction rule:** `Close[1] ≥ Close[2]` ⇒ BUY; else SELL; entry only if gates allow; **Ask** for BUY, **Bid** for SELL; **slippage parity**.  
- **First order lots:** Lot model and rounding identical to baseline.
**Deliverables:** First entry opens exactly like baseline.  
**Acceptance:** BUY/SELL first‑entry scenarios match entry price & lot within tolerances; TRACE logs include `entry_open` details.

### Phase 3 — First TP (Single Order)
**Objective:** TP parity for single‑order case.  
**Requirements implemented here:**
- **First order TP:** TP = entry ± `TakeProfit × _Point` (BUY +, SELL −); **ECN modify‑after‑fill** if baseline does.  
- **SL behavior:** Mirror baseline default (usually none unless trailing/BE is default‑on).
**Deliverables:** TP set and hit identically in replay.  
**Acceptance:** TP price parity within tolerance; close via TP recorded with correct fields.

### Phase 4 — Basket Average & TP Sync (Multiple Orders)
**Objective:** Multi‑order basket math parity.  
**Requirements implemented here:**
- **Basket average & TP:** Lot‑weighted average per side; basket TP = `avg ± TakeProfit × _Point` (BUY +, SELL −).  
- **TP‑sync cadence:** Sync frequency (every tick vs after entry) identical to baseline.
**Deliverables:** Accurate TP synchronization across all orders on a side.  
**Acceptance:** Multi‑order scenario shows matching average and TP; logs show `tp_sync` with `avg_price,tp_price,open_count`.

### Phase 5 — Grid Adds & Spacing
**Objective:** Controlled scaling with exact spacing and caps.  
**Requirements implemented here:**
- **Add‑on spacing:** Only add when `|price − last_entry_side| ≥ Step × _Point`.  
- **Max trades:** Enforce `MaxTrades` exactly.  
- **Tick‑volume gates:** If baseline checks tick volume before adding, replicate that logic.
**Deliverables:** Adds occur/skip at the precise distances; respect cap.  
**Acceptance:** Adds at exactly/over Step; no add under Step; cap enforced—validated via TRACE `add` events.

### Phase 6 — Lot Progression & Averaging Cadence
**Objective:** Parity for lot growth across the basket.  
**Requirements implemented here:**
- **Lot progression modes:** Fixed; multiplicative via `LotMultiplikator`; additive (adding `Lot`); “last losing lot”; with the **Averaging bump cadence** and **reset rules**.  
- **Indexing & resets:** Use the same progression index (open count/successful sends) and the same counter resets as baseline; enforce min/max/step rounding.
**Deliverables:** Next‑lot computations match baseline across the ladder.  
**Acceptance:** Snapshot after N adds shows identical lot sizes; TRACE `lot_progress` includes `mode,index,next_lot,counter`.

### Phase 7 — Closers (Hidden TP, Daily Target, Equity Stop)
**Objective:** Non‑broker closures parity.  
**Requirements implemented here:**
- **Hidden TP:** Close all when **floating P/L including swap & commission** ≥ `Hiden_TP`.  
- **Daily target:** Close all remaining positions when **closed P/L since D1 open (server time)** ≥ `Daily_Target`, including swap & commission.  
- **Equity stop:** If floating P/L < 0 and `abs(floating) > AccountEquity() × (TotalEquityRisk/100)`, close all.
**Deliverables:** Parity of triggers and close‑all behavior.  
**Acceptance:** Deterministic triggers fire and close sequences match; TRACE logs capture thresholds & values.

### Phase 8 — Session/Day Gating & Out‑of‑Session Close
**Objective:** Time‑window behavior parity.  
**Requirements implemented here:**
- **Session/day gates:** Enforce trading hours (including wrap‑around) and **Thursday/Friday cutoffs**; when out‑of‑session, mirror baseline (block new entries and/or close active side as baseline does).
**Deliverables:** Entries and side‑closures adhere to time windows.  
**Acceptance:** Out‑of‑session tests show identical behavior and logs.

### Phase 9 — Error Handling & Retries
**Objective:** Production‑grade parity under broker errors.  
**Requirements implemented here:**
- **Error handling & retries:** Same behavior for errors (4, 136/137, 146, 134), same retry counts/spacing, and the same rules for advancing or not advancing internal counters after failures.
**Deliverables:** Robust, parity‑matching error paths.  
**Acceptance:** Fault‑injection runs exercise each path; logs include error codes and decisions.

### Phase 10 — Determinism, Multi‑Digit, Performance
**Objective:** Final environment and performance checks.  
**Requirements implemented here:**
- **Multi‑digit brokers:** Confirm identical results on 4/5 digits.  
- **Performance constraints:** Logging overhead acceptable; no timing drift.  
- **Tester determinism:** Re‑validate fixed profile.
**Deliverables:** Cross‑digit pass and perf summary.  
**Acceptance:** Repeat scenarios under 4/5 digits with fixed spread; summarize timings.

### Phase 11 — Sign‑off & Freeze
**Objective:** Validate, tag, and freeze parity build.  
**Requirements implemented here:**
- **Acceptance tests:** Event‑sequence parity; value tolerances; scenario matrix pass; **log parity**.  
- **Change control:** Zero intentional behavior deviations.  
- **Deliverables:** New EA source; shared logging module; runbook + passing logs.
**Deliverables:** Final parity report; tag `v1.0-parity`.  
**Acceptance:** QA checklist fully ticked; side‑by‑side log diffs attached.

---

## C) QA Checklist (for final sign‑off)
- Externs and defaults are exact.  
- Per‑tick pipeline order is unchanged.  
- Direction rule, spacing, `MaxTrades` match.  
- Basket average & TP sync match.  
- Lot progression matches for all modes.  
- Hidden TP, Daily target, Equity stop, Session gates match.  
- Magic mapping and order comments are identical.  
- Error handling & retry behavior match.  
- Logs at TRACE level enable parity diffing.  
- Acceptance scenarios pass within tolerances.

