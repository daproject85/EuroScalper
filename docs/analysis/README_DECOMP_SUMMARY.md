
# EuroScalper (Decompiled) — Deep Technical Teardown

**Source:** Provided decompiled `.mq4` file: `EuroScalper MQ4 source code.mq4`  
**Generated:** 2025-08-31T20:12:59Z  
**Goal:** Create repo-ready documentation for a parity rewrite.  

## What it is
Grid-style scalper that:
- Opens a **market BUY** when Close[1] ≥ Close[2]; opens a **market SELL** when Close[1] < Close[2] (simple momentum flip using the last two closes).
- Adds positions on the **same side** when price moves **≥ `Step` points** from the last entry on that side.
- Sets a **basket TP** at the **weighted-average entry price ± `TakeProfit` points** (buy = `avg + TP`, sell = `avg − TP`) and synchronizes TP across the basket.
- Supports **lot progression** (multiplicative via `LotMultiplikator` or additive by `Lot`), controlled by `Averaging`, `I_i_77`, and `I_i_98`.
- Provides **daily target** and **hidden basket TP** closures, plus an optional **equity % drawdown stop**.
- Has **session and day-of-week gating** and a **daily-open range / max-range gate** before new entries.

## Compile/runtime assumptions
- Designed for MT4 classic trade API (`OrderSend/Modify/Close`).
- Point/pip safe via `_Point`/`_Digits`; works on both 4/5-digit brokers (but TP/Step are **in points**, not "pips").
- ECN-safe: TP/SL may be applied post-fill (uses `OrderModify` after).

## Parity priorities
1. **Entry timing & side** based on the two-close comparison.  
2. **Grid add distance** using `Step` and last side’s last entry price.  
3. **Basket TP calculation** and synchronization behavior.  
4. **Lot progression** math & reset cadence (`Averaging`, `I_i_76` → `-2`).  
5. **Closures**: hidden TP, daily TP, equity stop, and session timeouts.  

