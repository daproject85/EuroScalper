// EuroScalper Forensic Audit — request/reply wrappers for MT4 trade calls

// ---- Lot policy label propagated from EA (A5) ----
string ES_LOT_POLICY = "fixed";
void ES_SetLotPolicy(const string s){ ES_LOT_POLICY = s; }
// ---------------------------------------------------

#ifndef __EUROSCALPER_AUDIT_MQH__
#define __EUROSCALPER_AUDIT_MQH__

/* Keep stubs to satisfy EA includes without altering behavior */
static string ES_A_SYM="";
static int    ES_A_MAGIC=0;
#ifndef ES_A_MAX
#define ES_A_MAX 512
#endif
static int    ES_A_prev_n=0;
static int    ES_A_prev_ticket[ES_A_MAX];
static double ES_A_prev_open[ES_A_MAX];
static double ES_A_prev_tp[ES_A_MAX];
static int    ES_A_prev_type[ES_A_MAX];
static double ES_A_prev_lots[ES_A_MAX];

void ES_Audit_Init(string sym, int magic)
{
   ES_A_SYM = sym; ES_A_MAGIC = magic;
   ES_A_prev_n = 0;
   for(int i=0;i<OrdersTotal() && ES_A_prev_n<ES_A_MAX;i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderSymbol()==ES_A_SYM && OrderMagicNumber()==ES_A_MAGIC){
            ES_A_prev_ticket[ES_A_prev_n] = OrderTicket();
            ES_A_prev_open  [ES_A_prev_n] = OrderOpenPrice();
            ES_A_prev_tp    [ES_A_prev_n] = OrderTakeProfit();
            ES_A_prev_type  [ES_A_prev_n] = OrderType();
            ES_A_prev_lots  [ES_A_prev_n] = OrderLots();
            ES_A_prev_n++;
         }
      }
   }
}
void ES_Audit_OnTick(int step_pts, int tp_pts, int max_trades)
{
   int curr_n=0; int curr_ticket[ES_A_MAX]={0};
   for(int i=0;i<OrdersTotal() && curr_n<ES_A_MAX;i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderSymbol()==ES_A_SYM && OrderMagicNumber()==ES_A_MAGIC){
            curr_ticket[curr_n++] = OrderTicket();
         }
      }
   }
   for(int p=0;p<ES_A_prev_n;p++){
      int tk = ES_A_prev_ticket[p];
      bool still_open=false;
      for(int c=0;c<curr_n;c++){ if(curr_ticket[c]==tk){ still_open=true; break; } }
      if(!still_open && tk>0){
         if(OrderSelect(tk, SELECT_BY_TICKET, MODE_HISTORY)){
            datetime tclose = OrderCloseTime();
            double   pclose = OrderClosePrice();
            string side = (ES_A_prev_type[p]==OP_BUY? "buy" : (ES_A_prev_type[p]==OP_SELL? "sell":""));
            string reason = (MathAbs(pclose - ES_A_prev_tp[p]) <= (Point*2) && ES_A_prev_tp[p]>0) ? "hit_tp" : "closed";
            LogEventAt(tclose, "close_filled", side, tk,
                       ES_A_prev_lots[p], pclose,
                       ES_A_prev_open[p], 0, ES_A_prev_tp[p],
                       step_pts, tp_pts, (int)MarketInfo(ES_A_SYM, MODE_SPREAD), -1,
                       0, max_trades,
                       0, 0,
                       AccountEquity(), AccountFreeMargin(), reason, 0, "");
         }
      }
   }
   ES_A_prev_n = 0;
   for(int i2=0;i2<OrdersTotal() && ES_A_prev_n<ES_A_MAX;i2++){
      if(OrderSelect(i2, SELECT_BY_POS, MODE_TRADES)){
         if(OrderSymbol()==ES_A_SYM && OrderMagicNumber()==ES_A_MAGIC){
            ES_A_prev_ticket[ES_A_prev_n] = OrderTicket();
            ES_A_prev_open  [ES_A_prev_n] = OrderOpenPrice();
            ES_A_prev_tp    [ES_A_prev_n] = OrderTakeProfit();
            ES_A_prev_type  [ES_A_prev_n] = OrderType();
            ES_A_prev_lots  [ES_A_prev_n] = OrderLots();
            ES_A_prev_n++;
         }
      }
   }
}

// ---- Forensic wrappers ----
// Logs exact request parameters and broker reply for full fidelity.

int ES_OrderSendLogged(string sym, int type, double volume, double price, int slippage,
                       double sl, double tp, string comment, int magic, datetime expiry, color arrow_color)
{
   datetime ts_req = TimeCurrent();
   string side = (type==OP_BUY ? "buy" : (type==OP_SELL ? "sell" : "other"));
   
// A5/A6: lot progression debug (policy label provided by ES_SetLotPolicy)
int oc_dbg = 0; double prev_lot_dbg = 0; datetime prev_t_dbg = 0;
for(int ii=0; ii<OrdersTotal(); ii++){
   if(OrderSelect(ii, SELECT_BY_POS, MODE_TRADES)){
      if(OrderSymbol()==sym && OrderMagicNumber()==magic){
         oc_dbg++;
         if(OrderType()==type){
            if(prev_t_dbg==0 || OrderOpenTime()>prev_t_dbg){
               prev_t_dbg = OrderOpenTime();
               prev_lot_dbg = OrderLots();
            }
         }
      }
   }
}
string lots_in_dbg = StringFormat("lots_in:policy=%s|base_lot=%.2f|prev_lot=%.2f|open_count=%d",
                                  ES_LOT_POLICY, volume, prev_lot_dbg, oc_dbg);
LogEventAt(ts_req, "dbg_lots_in", side, 0, volume, 0, 0, 0, 0,
           0, 0, (int)MarketInfo(sym, MODE_SPREAD), slippage,
           oc_dbg, 0, 0, 0, AccountEquity(), AccountFreeMargin(),
           lots_in_dbg, 0, "");

// Decision result: proposed==rounded==volume here (normalization happens upstream)
string lots_dbg = StringFormat("lots:prev_lot=%.2f|proposed=%.2f|rounded=%.2f|ok=1",
                               prev_lot_dbg, volume, volume);
LogEventAt(ts_req, "dbg_lots", side, 0, volume, 0, 0, 0, 0,
           0, 0, (int)MarketInfo(sym, MODE_SPREAD), slippage,
           oc_dbg, 0, 0, 0, AccountEquity(), AccountFreeMargin(),
           lots_dbg, 0, "");
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
