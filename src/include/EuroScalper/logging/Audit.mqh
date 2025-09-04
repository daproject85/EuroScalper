// EuroScalper BASIC auditor (state-delta logger) — Generated 2025-09-03T05:41:13Z
// Observes orders for a given symbol+magic and emits BASIC events:
//   entry_filled, modify_tp_ok, close_filled
// No trading behavior changed.

#ifndef __EUROSCALPER_AUDIT_MQH__
#define __EUROSCALPER_AUDIT_MQH__

struct ES_TicketInfo {
   int      ticket;
   int      type;        // OP_BUY / OP_SELL
   double   lots;
   double   open_price;
   double   tp;
   double   sl;
   datetime open_time;
};

string ES_AUD_symbol = "";
int    ES_AUD_magic  = 0;

// previous snapshot
int    ES_prev_count = 0;
int    ES_prev_tickets[256];
ES_TicketInfo ES_prev_info[256];

// helpers
int ES__FindPrevByTicket(int ticket) {
   for(int i=0;i<ES_prev_count;i++) if(ES_prev_tickets[i]==ticket) return i;
   return -1;
}

void ES__ResetPrev() {
   ES_prev_count = 0;
}

void ES_Audit_Init(string sym, int magic) {
   ES_AUD_symbol = sym;
   ES_AUD_magic  = magic;
   ES__ResetPrev();
}
void ES_Audit_SetMagic(int magic) { ES_AUD_magic = magic; }


double ES__BasketWAP(int side) {
   double sumvol=0, sumval=0;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderSymbol()==ES_AUD_symbol && OrderMagicNumber()==ES_AUD_magic && OrderType()==side) {
         double lots=OrderLots();
         sumvol += lots;
         sumval += lots*OrderOpenPrice();
      }
   }
   if(sumvol<=0) return 0;
   return sumval/sumvol;
}

int ES__SideOpenCount(int side) {
   int c=0;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderSymbol()==ES_AUD_symbol && OrderMagicNumber()==ES_AUD_magic && OrderType()==side) c++;
   }
   return c;
}

double ES__BasketCommonTP(int side) {
   double tp = -1;
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderSymbol()==ES_AUD_symbol && OrderMagicNumber()==ES_AUD_magic && OrderType()==side) {
         double t = OrderTakeProfit();
         if(t<=0) return 0; // not set uniformly
         if(tp<0) tp=t; else if(MathAbs(tp-t) > Point*2) return 0; // not uniform
      }
   }
   return (tp<0?0:tp);
}

double ES__ClosedPLToday() {
   datetime day0 = iTime(ES_AUD_symbol, PERIOD_D1, 0);
   double pl=0;
   int total = OrdersHistoryTotal();
   for(int i=total-1;i>=0;i--) if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
      if(OrderSymbol()!=ES_AUD_symbol) continue;
      if(OrderMagicNumber()!=ES_AUD_magic) continue;
      if(OrderCloseTime() < day0) break;
      pl += OrderProfit()+OrderSwap()+OrderCommission();
   }
   return pl;
}

void ES_Audit_OnTick(int step_pts, int tp_pts, int max_trades) {
   // build current snapshot
   int curr_count=0;
   static int curr_tickets[256];
   static ES_TicketInfo curr_info[256];

      ArrayInitialize(curr_tickets, 0);
   for(int __k=0; __k<256; __k++) { curr_info[__k].ticket=0; curr_info[__k].type=0; curr_info[__k].lots=0; curr_info[__k].open_price=0; curr_info[__k].tp=0; curr_info[__k].sl=0; curr_info[__k].open_time=0; }
for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if(OrderSymbol()==ES_AUD_symbol && OrderMagicNumber()==ES_AUD_magic) {
         ES_TicketInfo ti;
         ti.ticket     = OrderTicket();
         ti.type       = OrderType();
         ti.lots       = OrderLots();
         ti.open_price = OrderOpenPrice();
         ti.tp         = OrderTakeProfit();
         ti.sl         = OrderStopLoss();
         ti.open_time  = OrderOpenTime();
         curr_tickets[curr_count] = ti.ticket;
         curr_info[curr_count]    = ti;
         curr_count++;
      }
   }

   int spread_pts = (int)MathRound((Ask - Bid) / Point);
   double eq = AccountEquity();
   double mf = AccountFreeMargin();
   double closed_today = ES__ClosedPLToday();

   // detect entries & modifies
   for(int c=0;c<curr_count;c++) {
      int t = curr_tickets[c];
      int idx_prev = ES__FindPrevByTicket(t);
      string side = (curr_info[c].type==OP_BUY ? "buy" : (curr_info[c].type==OP_SELL?"sell":"."));
      int side_code = curr_info[c].type;
      int open_count = ES__SideOpenCount(side_code);
      double wap = ES__BasketWAP(side_code);
      double basket_tp = ES__BasketCommonTP(side_code);

      if(idx_prev<0) {
         // entry_filled
         LogEvent("entry_filled", side,
                  curr_info[c].lots, curr_info[c].open_price,
                  curr_info[c].open_price, // last_entry_price
                  wap, basket_tp,
                  step_pts, tp_pts, spread_pts, 0,
                  open_count, max_trades, 0, closed_today,
                  eq, mf, "grid_entry", 0,
                  StringFormat("bid=%G ask=%G req=? fill=%G grid_idx=%d basket_tp=%G",
                               Bid, Ask, curr_info[c].open_price, open_count-1, basket_tp));
         // log same-tick TP assignment for newly opened ticket
         if(curr_info[c].tp > 0) {
            LogEvent("modify_tp_ok", side,
                     curr_info[c].lots, 0,
                     0, wap, curr_info[c].tp,
                     step_pts, tp_pts, spread_pts, 0,
                     open_count, max_trades, 0, closed_today,
                     eq, mf, "ticket_tp_set", 0,
                     StringFormat("old_tp=%G new_tp=%G", 0.0, curr_info[c].tp));
         }

      } else {
         // compare TP change
         double prev_tp = ES_prev_info[idx_prev].tp;
         double new_tp  = curr_info[c].tp;
         if(MathAbs(prev_tp - new_tp) > Point*1) {
            LogEvent("modify_tp_ok", side,
                     curr_info[c].lots, prev_tp, // price column stores old TP for context
                     0, wap, new_tp,
                     step_pts, tp_pts, spread_pts, 0,
                     open_count, max_trades, 0, closed_today,
                     eq, mf, "ticket_tp_set", 0,
                     StringFormat("old_tp=%G new_tp=%G", prev_tp, new_tp));
         }
      }
   }

   // detect closes
   for(int p=0;p<ES_prev_count;p++) {
      int t = ES_prev_tickets[p];
      // find in current
      bool still_open=false;
      for(int c=0;c<curr_count;c++) if(curr_tickets[c]==t) { still_open=true; break; }
      if(!still_open) {
         // moved to history → close_filled
         if(OrderSelect(t, SELECT_BY_TICKET, MODE_HISTORY)) {
            int   type = OrderType();
            string side = (type==OP_BUY?"buy":(type==OP_SELL?"sell":"."));
            double lots = OrderLots();
            double close_price = OrderClosePrice();
            double profit = OrderProfit()+OrderSwap()+OrderCommission();
            string reason = ".";
            double prev_tp = ES_prev_info[p].tp;
            double prev_sl = ES_prev_info[p].sl;
            if(prev_tp>0 && MathAbs(close_price - prev_tp) <= Point*2) reason="hit_tp";
            else if(prev_sl>0 && MathAbs(close_price - prev_sl) <= Point*2) reason="hit_sl";
            else reason="manual";
            int open_count = ES__SideOpenCount(type);
            double wap = ES__BasketWAP(type);
            double basket_tp = ES__BasketCommonTP(type);

            LogEvent("close_filled", side,
                     lots, close_price, 0, wap, basket_tp,
                     step_pts, tp_pts, spread_pts, 0,
                     open_count, max_trades, 0, ES__ClosedPLToday(),
                     AccountEquity(), AccountFreeMargin(), reason, 0,
                     StringFormat("duration=%s profit=%G", TimeToString(OrderCloseTime()-OrderOpenTime(), TIME_SECONDS), profit));
         }
      }
   }

   // rotate snapshots
   ES_prev_count = 0;
   for(int c=0;c<curr_count;c++) {
      ES_prev_tickets[ES_prev_count] = curr_tickets[c];
      ES_prev_info[ES_prev_count]    = curr_info[c];
      ES_prev_count++;
   }
}

#endif // __EUROSCALPER_AUDIT_MQH__
