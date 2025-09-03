
# Order Wrapper Details

## f0_15(...)
- Inputs include: side (0=BUY,1=SELL), lot, price, slippage, stop distances, comment, magic.
- Normalizes stop/TP distances vs `_Point` and broker min stop levels.
- Retries on common transient errors (4, 137, 146). Increments `I_i_76` on success.

## f0_1(closeBUY, closeSELL)
- Iterates market orders for this symbol/magic and closes requested side(s). Handles trade-context-busy with retries and timestamp guard.

## f0_18(trigger, step, priceRef)
- Optional trailing/BE adjust: walks SL to `Ask + step*_Point` (for BUY) or symmetric for SELL after `trigger` points.
