// EuroScalper Forensic Audit — request/reply wrappers for MT4 trade calls
#ifndef __EUROSCALPER_AUDIT_MQH__
#define __EUROSCALPER_AUDIT_MQH__

/* Keep stubs to satisfy EA includes without altering behavior */
void ES_Audit_Init(string sym, int magic) { /* no-op */ }
void ES_Audit_OnTick(int step_pts, int tp_pts, int max_trades) { /* no-op */ }

// ---- Forensic wrappers ----
// Logs exact request parameters and broker reply for full fidelity.

int ES_OrderSendLogged(string sym, int type, double volume, double price, int slippage,
                       double sl, double tp, string comment, int magic, datetime expiry, color arrow_color)
{
   datetime ts_req = TimeCurrent();
   string side = (type==OP_BUY ? "buy" : (type==OP_SELL ? "sell" : "other"));
   // request
   LogEventAt(ts_req, "send_req", side, 0, volume, price,
              0, 0, tp, 0, 0, (int)MarketInfo(sym, MODE_SPREAD), slippage,
              0, 0, 0, 0, AccountEquity(), AccountFreeMargin(),
              "req", 0, StringFormat("sym=%s type=%d lots=%G req_price=%G sl=%G tp=%G slip=%d comment=%s magic=%d expiry=%d bid=%G ask=%G",
                                     sym, type, volume, price, sl, tp, slippage, comment, magic, expiry, Bid, Ask));
   int ticket = OrderSend(sym, type, volume, price, slippage, sl, tp, comment, magic, expiry, arrow_color);
   int err = GetLastError();
   if(ticket > 0) {
      datetime tfill = ts_req; double pfill=price;
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) || OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
         tfill = OrderOpenTime(); pfill = OrderOpenPrice();
      }
      LogEventAt(tfill, "send_ok", side, ticket, volume, pfill,
                 pfill, 0, tp, 0, 0, (int)MarketInfo(sym, MODE_SPREAD), slippage,
                 0, 0, 0, 0, AccountEquity(), AccountFreeMargin(),
                 "filled", err, StringFormat("sym=%s type=%d", sym, type));
   } else {
      LogEventAt(ts_req, "send_err", side, 0, volume, price,
                 0, 0, tp, 0, 0, (int)MarketInfo(sym, MODE_SPREAD), slippage,
                 0, 0, 0, 0, AccountEquity(), AccountFreeMargin(),
                 "broker_error", err, StringFormat("sym=%s type=%d", sym, type));
   }
   return ticket;
}

bool ES_OrderModifyLogged(int ticket, double price, double sl, double tp, datetime expiration, color Color)
{
   datetime ts_req = TimeCurrent();
   string side = ""; double lots=0, openp=0;
   if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) || OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
      side = (OrderType()==OP_BUY ? "buy" : (OrderType()==OP_SELL ? "sell" : ""));
      lots = OrderLots(); openp = OrderOpenPrice();
   }
   LogEventAt(ts_req, "modify_req", side, ticket, lots, price,
              openp, 0, tp, 0, 0, 0, 0, 0, 0,
              0, 0, AccountEquity(), AccountFreeMargin(), "req", 0,
              StringFormat("ticket=%d new_sl=%G new_tp=%G new_price=%G", ticket, sl, tp, price));
   bool ok = OrderModify(ticket, price, sl, tp, expiration, Color);
   int err = GetLastError();
   if(ok) {
      LogEventAt(ts_req, "modify_ok", side, ticket, lots, price,
                 openp, 0, tp, 0, 0, 0, 0, 0, 0,
                 0, 0, AccountEquity(), AccountFreeMargin(), "modified", err, "");
   } else {
      LogEventAt(ts_req, "modify_err", side, ticket, lots, price,
                 openp, 0, tp, 0, 0, 0, 0, 0, 0,
                 0, 0, AccountEquity(), AccountFreeMargin(), "broker_error", err, "");
   }
   return ok;
}

bool ES_OrderCloseLogged(int ticket, double lots, double price, int slippage, color Color)
{
   datetime ts_req = TimeCurrent();
   string side = ""; double openp=0;
   if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) || OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
      side = (OrderType()==OP_BUY ? "buy" : (OrderType()==OP_SELL ? "sell" : ""));
      openp= OrderOpenPrice();
   }
   LogEventAt(ts_req, "close_req", side, ticket, lots, price,
              openp, 0, 0, 0, 0, 0, slippage, 0, 0,
              0, 0, AccountEquity(), AccountFreeMargin(), "req", 0, "");
   bool ok = OrderClose(ticket, lots, price, slippage, Color);
   int err = GetLastError();
   if(ok) {
      datetime tfill = ts_req; double pfill=price;
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
         tfill = OrderCloseTime(); pfill = OrderClosePrice();
      }
      LogEventAt(tfill, "close_ok", side, ticket, lots, pfill,
                 openp, 0, 0, 0, 0, 0, slippage, 0, 0,
                 0, 0, AccountEquity(), AccountFreeMargin(), "closed", err, "");
   } else {
      LogEventAt(ts_req, "close_err", side, ticket, lots, price,
                 openp, 0, 0, 0, 0, 0, slippage, 0, 0,
                 0, 0, AccountEquity(), AccountFreeMargin(), "broker_error", err, "");
   }
   return ok;
}

#endif // __EUROSCALPER_AUDIT_MQH__
