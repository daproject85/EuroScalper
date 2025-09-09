# EuroScalper Logging Reference (Baseline + Rewrite)

> This document describes **every log event currently emitted** by the baseline EA and the Phase‑0 rewrite, including the **`reason`** keys and what each value means. It reflects the latest files you provided and the Phase‑0 behavior (rewrite has no trading yet).  
> **Rewrite log filename:** `EuroScalper_EURUSD_M5_101111_1143_REWRITE.csv` (exact).  
> Formatting follows your logger rules: Bid/Ask to **5 dp**, leave fields **blank** where not applicable, and keep the **final `err` column aligned** by inserting the required blanks before it. Notes are retained but generally blank where specified.

---

## Lifecycle

### `boot`
- **When**: EA init/attach (level ≥ BASIC).
- **Baseline**: `reason=started`, `notes="tester profile: build=1143, spread=2pts, slippage=match_baseline"`  
- **Rewrite**: same as baseline (parity).  
- **Meaning**: deterministic run start marker; confirms filename/profile and that the EA is alive.

### `deinit`
- **When**: EA deinit/detach (level ≥ BASIC).
- **All**: `reason=stop`  
- **Meaning**: deterministic run end marker; no orders/actions implied.

---

## Per‑bar anchor

### `bar_tick_dbg`
- **When**: first tick of a new bar (level ≥ DEBUG).
- **`reason` keys**:
  - `bar=M{tf}` — timeframe code (e.g., `M5`).
  - `seq={n}` — monotonic bar sequence (resets on reattach).
- **Meaning**: a bar boundary anchor to align per‑tick debug lines under each bar.

---

## Per‑tick pipeline breadcrumbs (Phase‑0 rewrite emits these; baseline already does)

### `dbg_closers`
- **When**: each tick (level ≥ DEBUG).
- **`reason` keys**:
  - `daily={0|1}` — daily close logic active (often `0` in your runs).
  - `equity={0|1}` — equity‑based closer active (flag).
  - `open={int}` — open positions for this symbol/magic (all sides combined unless split logic is added).
  - `flt={±money}` — `AccountEquity() - AccountBalance()` at the tick.
- **Meaning**: snapshot for closer gates and current float.

### `dbg_gates`
- **When**: each tick (level ≥ DEBUG).
- **`reason` keys**:
  - `dow={0..6}` — day of week (broker time).
  - `hour={0..23}` — current hour (broker time).
  - `block={0|1}` — session/time blockade flag (1 = trading blocked by time/session gate).
- **Meaning**: session/time gate inputs used by the signal.

### `dbg_scan`
- **When**: each tick (level ≥ DEBUG).
- **`reason` keys**:
  - `open_count={int}` — open tickets for this symbol/magic.
  - `last_entry={price}` — most recent open’s price (`0.00000` if none).
- **Meaning**: basket scan snapshot consumed by the entry rules.

### `dbg_signal_in`
- **When**: each tick, **before** the decision (level ≥ DEBUG).
- **`reason` keys**:
  - `bar_ago={0}` — current live bar.
  - `spread_pts={int}` — spread in points at this tick.
  - `open_count={int}` — as above.
  - `max_trades={int}` — configured cap.
  - `last_entry={price}` — as above.
  - `step={int}` — grid step in points.
  - `dist_from_last_pts={int}` — distance in points from decision price to `last_entry` (0 when seeding).
- **Meaning**: exact inputs the signal logic uses.

### `dbg_signal`
- **When**: each tick, **after** the decision (level ≥ DEBUG).
- **`reason` keys**:
  - `dir={BUY|SELL|NONE}` — intended direction (or `NONE`).
  - `rule={grid_seed|grid_add}` — seed when `open_count==0`, else add.
  - `add_allowed={0|1}` — spacing rule permission for add.
  - `ok={0|1}` — final decision to attempt entry (subject to gates).
  - `why={seed|step}` — the dominant reason (`seed` for first entry, `step` for spacing).
- **Meaning**: the decision verdict. In **Phase‑0 rewrite** this is a deterministic echo only; **no trading occurs**.

---

## Trade path (emitted from `Audit.mqh`)

> **Notes must be blank** for these events (your rule). Bid/Ask at 5 dp; lots/price printed only when applicable; irrelevant numeric fields left **blank** instead of `0`.

### `send_req`
- **When**: just **before** `OrderSend` executes.
- **Fields**: `side={buy|sell}`, `lots={volume}`; prices/TP as appropriate.
- **`reason`**: `req`
- **Meaning**: intent to place a market order with the printed params.

### `send_ok`
- **When**: on successful `OrderSend`.
- **Fields**: `ticket` now set to the new order id; `side/lots/price` as filled.
- **`reason`**: `filled`
- **Meaning**: order accepted and live.

### `modify_req`
- **When**: before `OrderModify` (to set TP/SL).
- **`reason`**: `req`
- **Meaning**: intent to modify an existing order’s TP/SL.

### `modify_ok`
- **When**: on successful `OrderModify`.
- **`reason`**: `modified`
- **Meaning**: TP/SL successfully synchronized.

### `close_filled`
- **When**: when a position is closed (by TP/SL/manual).
- **`reason`**: typically `closed` (or the short tag your code uses).
- **Meaning**: position no longer open; equity/float on subsequent lines reflect this.

> **Phase‑0 rewrite:** trading is **disabled**, so these events won’t appear in rewrite logs yet; they are present in the baseline and will appear in the rewrite once trading is enabled in later phases.

---

## Lot‑progression debug (A5/A6)

> Implemented minimally so you can observe sizing inputs/result without changing behavior. These fire **inside the send path** only.

### `dbg_lots_in`
- **When**: inside the send path, **before** `send_req`.
- **`reason` keys**:
  - `policy={fixed|marti}` — label propagated from EA (e.g., via `LotMultiplikator` check).
  - `base_lot={volume}` — proposed lot before broker rounding.
  - `prev_lot={volume}` — most recent lot on the same side (`0.00` if none).
  - `open_count={int}` — current open positions for this symbol/magic.
- **Meaning**: inputs snapshot to the lot sizing decision.

### `dbg_lots`
- **When**: immediately after sizing/rounding.
- **`reason` keys**:
  - `prev_lot={volume}` — as above.
  - `proposed={volume}` — computed lot before normalization.
  - `rounded={volume}` — final lot after normalization/rounding.
  - `ok=1` — present implementation always emits `1` unless you introduce guards.
- **Meaning**: the lot decision that will be used for `send_req`.

> **Phase‑0 rewrite:** these won’t appear yet (no trading). Baseline shows them on actual send attempts.

---

## Field conventions (recap)

- **Bid/Ask**: print to **5 decimals**.
- **Lots/Price**: output only when applicable; otherwise leave **blank**.
- **`last_entry_price` / `tp_price`**: blank when not applicable.
- **Final `err` column**: visually aligned by inserting the configured number of blank columns before it.
- **`notes`**: retained but generally blank; **must be blank** for `send_req`, `send_ok`, `modify_req`, `modify_ok` (per your rule).

---

## Quick recognition snippets

```
...;boot;...;reason=started;;;;0;tester profile: build=1143, spread=2pts, slippage=match_baseline
...;bar_tick_dbg;;;<bid>;<ask>;;;;2;bar=M5|seq=26;;;0;
...;dbg_closers;;;<bid>;<ask>;;;;2;closers:daily=0|equity=0|open=1|flt=-0.05;;;0;
...;dbg_gates;;;<bid>;<ask>;;;;2;gate:dow=1|hour=2|block=0;;;0;
...;dbg_scan;;;<bid>;<ask>;;;;2;scan:open_count=1|last_entry=1.15838;;;0;
...;dbg_signal_in;;;<bid>;<ask>;;;;2;in:bar_ago=0|spread_pts=2|open_count=1|max_trades=47|last_entry=1.15838|step=15|dist_from_last_pts=2;;;0;
...;dbg_signal;;;<bid>;<ask>;;;;2;dir=NONE|rule=grid_add|add_allowed=0|ok=0|why=step;;0;
...;dbg_lots_in;buy;0.02;<bid>;<ask>;;;;2;lots_in:policy=marti|base_lot=0.02|prev_lot=0.01|open_count=3;;;0;
...;dbg_lots   ;buy;0.02;<bid>;<ask>;;;;2;lots:prev_lot=0.01|proposed=0.02|rounded=0.02|ok=1;;;0;
...;send_req   ;buy;0.02;<bid>;<ask>;;;;2;req;;;;0;
...;send_ok    ;buy;0.02;...;...;...;...;;;;2;filled;;;;0;
...;modify_req ;buy;0.02;...;...;...;...;tp=...;;;;2;req;;;;0;
...;modify_ok  ;buy;0.02;...;...;...;...;tp=...;;;;2;modified;;;;0;
...;deinit;...;reason=stop;;;;0;
```

---

**Notes**
- TRACE logging is **deferred** by your choice; this document intentionally omits `trace_*` events.
- If you later enable basket math/TP sync (A4) or determinism anchors beyond Phase‑0, we can extend this reference with `dbg_basket_in` / `dbg_tp_sync` in the same style without changing the column schema.
