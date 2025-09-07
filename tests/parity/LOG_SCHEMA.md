# EuroScalper Log Schema v2

This schema **removes**: `step_pts`, `slippage_pts`, `max_trades`, `tp_pts`, `avg_price`  
This schema **adds**: `bid`, `ask` (after `lots`), `balance` (after `equity`)  
The `notes` column **remains** but its content should be empty for now (reserved).

## Header (exact order)
```
ts;build;symbol;tf;magic;ticket;event;side;lots;bid;ask;price;last_entry_price;tp_price;spread_pts;open_count;floating_pl;closed_pl_today;equity;balance;margin_free;reason;err;notes
```

## Field definitions
- **ts** — Event timestamp (`TimeCurrent()` for EA-side rows; `OrderCloseTime()` for auditor close rows).
- **build** — MT4 build number (e.g., 1143).
- **symbol** — Instrument (e.g., `EURUSD`).
- **tf** — Timeframe (e.g., `M5`).
- **magic** — Strategy magic number used to scope orders.
- **ticket** — Order ticket (`0` for non-order events).
- **event** — `boot|deinit|tick_eval|pipeline|send_req|send_ok|send_err|modify_req|modify_ok|modify_err|close_filled`.
- **side** — `buy|sell|.`
- **lots** — Order lots relevant to the event.
- **bid** — Bid at log time (or at send/modify).
- **ask** — Ask at log time (or at send/modify).
- **price** — Primary price for the event (request/fill/modify/close, as applicable).
- **last_entry_price** — Most recent open entry price in the basket (0 if none).
- **tp_price** — Common TP across opens if equal (>0), else 0.
- **spread_pts** — Current spread in points.
- **open_count** — Number of open orders for (symbol,magic) after the event.
- **floating_pl** — Unrealized P/L for the current basket.
- **closed_pl_today** — Realized P/L for broker day for (symbol,magic).
- **equity** — AccountEquity() at log time.
- **balance** — AccountBalance() at log time.
- **margin_free** — AccountFreeMargin() at log time.
- **reason** — Human tag: e.g., `started|req|filled|modified|hit_tp|closed|stop|scan|counts_only`.
- **err** — GetLastError() for trade ops; 0 on success.
- **notes** — Reserved (empty string).

## Mapping from v1 → v2
- Dropped: `step_pts, slippage_pts, max_trades, tp_pts, avg_price`
- Added: `bid, ask, balance`
- Reordered: inserted `bid,ask` after `lots`; inserted `balance` after `equity`

## Example rows (v2)
```
2025.08.04 02:00:00;1143;EURUSD;M5;101111;0;send_req;buy;0.01;1.15836;1.15838;1.15838;0;0;2;0;0;0;10000;10000;9997.64;req;0;
2025.08.04 02:00:00;1143;EURUSD;M5;101111;1;send_ok;buy;0.01;1.15836;1.15838;1.15838;1.15838;0;2;1;0;0;9999.96;9997.64;filled;0;
2025.08.04 02:00:00;1143;EURUSD;M5;101111;1;modify_req;buy;0.01;1.15836;1.15838;1.15838;1.15838;1.15868;2;1;0;0;9999.96;9997.64;req;0;
2025.08.04 02:00:00;1143;EURUSD;M5;101111;1;modify_ok;buy;0.01;1.15836;1.15838;1.15838;1.15838;1.15868;2;1;0;0;9999.96;9997.64;modified;0;
2025.08.04 02:01:40;1143;EURUSD;M5;101111;1;close_filled;buy;0.01;1.15866;1.15868;1.15868;1.15838;1.15868;2;0;0;0;10002.34;9999.00;hit_tp;0;
```
