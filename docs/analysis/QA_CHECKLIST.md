
# Parity QA Checklist

- [ ] Entries match direction on the same ticks in reference logs.
- [ ] Add-on timing matches (distance >= Step from last side entry).
- [ ] Lot sizes match (modes 0/1/2; multiplier/additive; Averaging bump cadence).
- [ ] Basket TP equals weighted average ± TP points and is synchronized after each entry.
- [ ] Hidden TP fires at correct floating profit (including commissions/swaps if applicable in code path).
- [ ] Daily target uses *closed* P/L since D1 bar open and closes remaining orders exactly.
- [ ] Equity stop compares absolute floating loss against TotalEquityRisk% * equity and closes all correctly.
- [ ] Session and Thu/Fri hour gates block entries and trigger side-closes as in baseline.
- [ ] Magic mapping and symbol filtering preserved.
- [ ] No regression on 4/5-digit brokers (point math).
