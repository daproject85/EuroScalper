# Input Parameters (extern)

### Minimal_Deposit  
- **Type:** `string`  
- **Default:** "$200"  
- **Purpose:** Informational banner text; not used for logic.

### Time_Frame  
- **Type:** `string`  
- **Default:** "Time Frame M1"  
- **Purpose:** Informational banner text for recommended timeframe; not used for logic.

### Pairs  
- **Type:** `string`  
- **Default:** "EurUsd"  
- **Purpose:** Informational banner text for suggested symbol; not used for logic.

### Use_Daily_Target  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** If true, close ALL open positions for this symbol/magic when today’s cumulative profit >= Daily_Target.

### Daily_Target  
- **Type:** `double`  
- **Default:** 100  
- **Purpose:** Target profit for current day in account currency; used with Use_Daily_Target.

### Hidden_TP  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** If true, use a “hidden/basket” take-profit: sum profit across orders and close all when profit >= Hiden_TP.

### Hiden_TP  
- **Type:** `double`  
- **Default:** 500  
- **Purpose:** Hidden basket TP threshold in account currency (mis‑spelled in code); when reached closes all open orders of this EA on the symbol.

### Lot  
- **Type:** `double`  
- **Default:** 0.01  
- **Purpose:** Base lot size (when using fixed lot mode or as the base before progression).

### LotMultiplikator  
- **Type:** `double`  
- **Default:** 1.21  
- **Purpose:** Lot multiplier for progression (martingale‑style) when I_i_77 == 1.

### TakeProfit  
- **Type:** `double`  
- **Default:** 34  
- **Purpose:** Target in POINTS (multiplied by _Point) added/subtracted from weighted average price for basket TP.

### Step  
- **Type:** `double`  
- **Default:** 21  
- **Purpose:** Minimum distance in POINTS between successive entries on the same side before adding another position.

### Averaging  
- **Type:** `double`  
- **Default:** 1  
- **Purpose:** How many successful sends (I_i_76) before increasing the base lot (bump once then reset).

### MaxTrades  
- **Type:** `int`  
- **Default:** 31  
- **Purpose:** Maximum number of concurrent market orders allowed for this symbol/magic.

### UseEquityStop  
- **Type:** `bool`  
- **Default:** (none)  
- **Purpose:** If true and current symbol’s floating P/L is negative, compute risk vs equity and close basket if drawdown exceeds TotalEquityRisk %.

### TotalEquityRisk  
- **Type:** `double`  
- **Default:** 20  
- **Purpose:** Percent of equity permitted as drawdown before the EA force‑closes the basket (UseEquityStop).

### Open_Hour  
- **Type:** `int`  
- **Default:** (none)  
- **Purpose:** Session start hour (0–23). 24 is normalized to 0. Used with Close_Hour to gate trading.

### Close_Hour  
- **Type:** `int`  
- **Default:** 23  
- **Purpose:** Session end hour (0–23). 24 is normalized to 0.

### TradeOnThursday  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** Enable trading on Thursday; with Thursday_Hour as cut‑off.

### Thursday_Hour  
- **Type:** `int`  
- **Default:** 12  
- **Purpose:** Hour after which Thursday trading is disabled if TradeOnThursday is true.

### TradeOnFriday  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** Enable trading on Friday; with Friday_Hour as cut‑off.

### Friday_Hour  
- **Type:** `int`  
- **Default:** 20  
- **Purpose:** Hour after which Friday trading is disabled if TradeOnFriday is true.

### Filter_Sideway  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** Declared but not used in logic (no references).

### Filter_News  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** Declared but not used in logic (no references).

### invisible_mode  
- **Type:** `bool`  
- **Default:** true  
- **Purpose:** Declared but not used in logic (no references).

### OpenRangePips  
- **Type:** `double`  
- **Default:** 1  
- **Purpose:** Daily open range threshold (POINTS) used with MaxDailyRange gate before entries are allowed.

### MaxDailyRange  
- **Type:** `double`  
- **Default:** 20000  
- **Purpose:** Max daily range (POINTS) relative to open; used to gate trading after excessive expansion.
