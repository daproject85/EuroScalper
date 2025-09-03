
# Exit Logic (Closes)

1. **Hidden Basket TP** (`Hidden_TP/Hiden_TP`): Sum floating profit across EA orders for this symbol; if ≥ threshold → close all open orders.
2. **Daily Target** (`Use_Daily_Target/Daily_Target`): Sum *closed* profit since `iTime(...,PERIOD_D1,0)`; if ≥ threshold → close all still-open orders.
3. **Equity Stop** (`UseEquityStop/TotalEquityRisk`): If floating P/L < 0 and |P/L| > (% of equity), close all open orders.
4. **Session Timeout (`L_s_2 == "true"`)**: If out of trade hours and flag set, **close all orders of the side** via `f0_1` helper.
5. **Normal TP hits**: Broker-side TP on each order is unified to the basket target and will naturally close when touched.
