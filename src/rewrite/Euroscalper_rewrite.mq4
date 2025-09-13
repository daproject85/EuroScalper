//+------------------------------------------------------------------+
//|                                             Euroscalper_rewrite  |
//| Phase 0 scaffold: boots, logs, no trading                         |
//+------------------------------------------------------------------+
#property strict

#include <WinUser32.mqh>
#include <EuroScalper/logging/Logger.mqh>
#include <EuroScalper/logging/Audit.mqh>
#include <EuroScalper/core/Normalize.mqh>

// ---------------- Inputs (parity with baseline) ----------------
extern int ES_LogLevelInput = 1;
extern string Minimal_Deposit = "$200";
extern string Time_Frame = "Time Frame M1";
extern string Pairs = "EurUsd";
extern bool Use_Daily_Target = true;
extern double Daily_Target = 100;
extern bool Hidden_TP = true;
extern double Hiden_TP = 500;
extern double Lot = 0.01;
extern double LotMultiplikator = 1.21;
extern double TakeProfit = 34;
extern double Step = 21;
extern double Averaging = 1;
extern int MaxTrades = 31;
extern bool UseEquityStop;
extern double TotalEquityRisk = 20;
extern int Open_Hour;
extern int Close_Hour = 23;
extern bool TradeOnThursday = true;
extern int Thursday_Hour = 12;
extern bool TradeOnFriday = true;
extern int Friday_Hour = 20;
extern bool Filter_Sideway = true;
extern bool Filter_News = true;
extern bool invisible_mode = true;
extern double OpenRangePips = 1;
extern double MaxDailyRange = 20000;

// ---------------- State ----------------
datetime ES_prev_bar_ts = 0;
int      ES_bar_seq     = 0;
int      ES_magic       = 0;

datetime ES_entry_sent_bar_ts = 0;
// ---------------- Helpers ----------------

// Map current _Symbol to magic (parity with baseline)
int ES_ResolveMagic() {
   int m = 0;
   string s = _Symbol;
   if (s == "EURJPYm" || s == "EURJPY") m = 101110;
   if (s == "EURUSDm" || s == "EURUSD") m = 101111;
   if (s == "GBPCHFm" || s == "GBPCHF") m = 101112;
   if (s == "GBPJPYm" || s == "GBPJPY") m = 101113;
   if (s == "GBPUSDm" || s == "GBPUSD") m = 101114;
   if (s == "NZDJPYm" || s == "NZDJPY") m = 101115;
   if (s == "NZDUSDm" || s == "NZDUSD") m = 101116;
   if (s == "USDCHFm" || s == "USDCHF") m = 101117;
   if (s == "USDJPYm" || s == "USDJPY") m = 101118;
   if (s == "USDCADm" || s == "USDCAD") m = 101119;
   if (m == 0) m = 999999;
   return m;
}

// Snapshot open count and last entry price for this symbol/magic/side-independent
void ES_ScanOpen(int &oc, double &last_entry) {
   oc = 0; last_entry = 0.0;
   datetime t_last = 0;
   int total = OrdersTotal();
   for (int i=0; i<total; i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == _Symbol && OrderMagicNumber() == ES_magic) {
            oc++;
            datetime ot = OrderOpenTime();
            if (ot > t_last) { t_last = ot; last_entry = OrderOpenPrice(); }
         }
      }
   }
}

// Emit once-per-bar debug anchor
void ES_BarTickDbg() {
   datetime bar_ts = iTime(_Symbol, Period(), 0);
   if (bar_ts != ES_prev_bar_ts) {
      ES_prev_bar_ts = bar_ts;
      ES_bar_seq++;
      string hb = StringFormat("bar=M%d;seq=%d", Period(), ES_bar_seq);
      if (LogGetLevel() >= ES_LOG_DEBUG) LogNote("bar_tick_dbg", hb, "");
   }
}

// ---------------- Lifecycle ----------------
int init() {
   // Init logger: symbol, magic (0 for now), build=1143, tf tag, fixed spread=2, slippage=-1 (unset)
   LogSetLabel("REWRITE");
   LogSetLevel(ES_LogLevelInput);
   LogInit(Symbol(), /*magic*/0, 1143, "M"+IntegerToString(Period()), 2, -1);

   // Resolve magic and open the log under the exact filename with suffix
   ES_magic = ES_ResolveMagic();
   LogSetMagic(ES_magic);
   ES_Audit_Init(Symbol(), ES_magic);

// Phase 1 unit/normalization checks (acceptance: log-only)
if (LogGetLevel() >= ES_LOG_BASIC) {
   double _p   = Point;
   int    _d   = Digits;
   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double minlot  = MarketInfo(Symbol(), MODE_MINLOT);
   double maxlot  = MarketInfo(Symbol(), MODE_MAXLOT);
   double probe_lot = 0.037;
   // Normalize lot: round to step and clamp [min,max]
   double norm_lot = probe_lot;
   if (lotstep > 0) norm_lot = MathRound(probe_lot/lotstep)*lotstep;
   if (norm_lot < minlot) norm_lot = minlot;
   if (maxlot > 0 && norm_lot > maxlot) norm_lot = maxlot;
   // Points <-> price demo using Step
   int step_pts_chk = (int)MathRound(Step);
   double px_up = NormalizeDouble(Bid + step_pts_chk * Point, Digits);
   int back_pts = (int)MathRound((px_up - Bid)/Point);
   string nc = StringFormat("norm:pnt=%.10f;digits=%d;lotstep=%.3f;minlot=%.2f;maxlot=%.2f;probe=%.3f->norm=%.3f;stop_lvl_pts=%d;back_pts=%d",
                            _p, _d, lotstep, minlot, maxlot, probe_lot, norm_lot, (int)MarketInfo(Symbol(), MODE_STOPLEVEL), back_pts);
}


   // Boot row
   if (LogGetLevel() >= ES_LOG_BASIC) {
      string r = StringFormat("boot:app=Euroscalper_rewrite|build=%d|log_suffix=_REWRITE|magic=%d", 1143, ES_magic);
      LogNote("boot", "started", "tester profile: build=1143, spread=2pts, slippage=match_baseline");
   }
   return 0;
}

int deinit() {
   if (LogGetLevel() >= ES_LOG_BASIC) LogNote("deinit", "stop", "");
   return 0;
}

int start() {
   // Per tick; do not trade in Phase 0
   

   if (LogGetLevel() >= ES_LOG_DEBUG) {
      // dbg_closers
      int oc=0; double last=0.0; ES_ScanOpen(oc, last);
      double flt = AccountEquity() - AccountBalance();
      string c = StringFormat("closers:daily=%d|equity=%d|open=%d|flt=%.2f",
                              0, 0, oc, flt);
      LogNote("dbg_closers", c, "");

            // dbg_gates (session/time gate)
      int dow  = DayOfWeek();
      datetime now = TimeCurrent();
      int hour = TimeHour(now);
      int block = 0; // LOG ONLY: Thu/Fri toggles & cutoffs
      if (dow == 4) { if (!TradeOnThursday || hour >= Thursday_Hour) block = 1; }
      if (dow == 5) { if (!TradeOnFriday  || hour >= Friday_Hour)   block = 1; }
      string g = StringFormat("gate:dow=%d|hour=%d|block=%d", dow, hour, block);
      LogNote("dbg_gates", g, "");
      // Send-gate: daily window + Thu/Fri cutoffs (not logged)
      int block_send = 0;
      if (hour < Open_Hour || hour >= Close_Hour) block_send = 1;
      if (dow == 4) { if (!TradeOnThursday || hour >= Thursday_Hour) block_send = 1; }
      if (dow == 5) { if (!TradeOnFriday  || hour >= Friday_Hour)   block_send = 1; }
// dbg_scan
      string s = StringFormat("scan:open_count=%d|last_entry=%.5f", oc, last);
      LogNote("dbg_scan", s, "");

      // dbg_signal_in (inputs snapshot similar to baseline)
      int max_trades = MaxTrades;
      int step_pts = (int)MathRound(Step);
      ES_Audit_OnTick(step_pts, (int)MathRound(TakeProfit), max_trades);
      int spread_pts = (int)MathRound((Ask - Bid)/Point);
      //double open_px = Ask;
      double open_px = Open[0];
      //int dist_pts = (last > 0.0) ? (int)MathAbs((open_px - last)/Point) : 0;
      int dist_pts = (oc > 0 && last > 0.0) ? (int)MathRound(MathAbs((open_px - last)/Point)): 0;
      string si = StringFormat("in:bar_ago=0|spread_pts=%d|open_count=%d|max_trades=%d|last_entry=%.5f|step=%d|dist_from_last_pts=%d", spread_pts, oc, max_trades, last, step_pts, dist_pts);
      LogNote("dbg_signal_in", si, "");

      // dbg_signal (no trading; deterministic seed rule echo)
      string sd;
      // Direction per baseline: Close[1] >= Close[2] => BUY else SELL
      double c1 = iClose(_Symbol, Period(), 1);
      double c2 = iClose(_Symbol, Period(), 2);
      int    dir_is_buy = (c1 >= c2) ? 1 : 0;
      string dir_s      = dir_is_buy ? "BUY" : "SELL";
      if (oc == 0) {
         sd = "dir=BUY|rule=grid_seed|add_allowed=0|ok=1";
      } else {
         int under_max = (oc < MaxTrades) ? 1 : 0;
         int add_allowed = (under_max && (dist_pts >= step_pts)) ? 1 : 0;
         int ok = add_allowed;
         sd = StringFormat("dir=NONE|rule=grid_add|add_allowed=%d|ok=%d|why=step", add_allowed, ok);
      }
      LogNote("dbg_signal", sd, "");
      ES_BarTickDbg();

      // Phase 2: first entry (only if none open and not sent this bar)
      if (block_send == 0 && oc == 0) {

         datetime bar_ts = iTime(_Symbol, Period(), 0);
         if (ES_entry_sent_bar_ts != bar_ts) {
            ES_entry_sent_bar_ts = bar_ts;
            int type   = dir_is_buy ? OP_BUY : OP_SELL;
            double req = dir_is_buy ? Ask    : Bid;
            // Lot parity: extern Lot rounded to step and clamped to broker min/max
            double step = MarketInfo(_Symbol, MODE_LOTSTEP);
            double minL = MarketInfo(_Symbol, MODE_MINLOT);
            double maxL = MarketInfo(_Symbol, MODE_MAXLOT);
            double lots = Lot;
            if (step > 0) lots = MathRound(lots/step)*step;
            if (lots < minL) lots = minL;
            if (maxL > 0 && lots > maxL) lots = maxL;
            lots = NormalizeDouble(lots, 2);
            ES_SetLotPolicy("marti");
            int slippage = 5;
            int ticket = ES_OrderSendLogged(_Symbol, type, lots, req, slippage, 0, 0, "", ES_magic, 0, clrNONE);
            // Phase 3: First TP (Single Order) — set TP after fill (ECN parity)
            if (ticket > 0) {
               if (OrderSelect(ticket, SELECT_BY_TICKET)) {
                  double fill_px = OrderOpenPrice();
                  int ot = OrderType();
                  double tp = (ot == OP_BUY) ? (fill_px + TakeProfit * Point)
                                             : (fill_px - TakeProfit * Point);
                  tp = NormalizeDouble(tp, Digits);
                  int _mod = ES_OrderModifyLogged(ticket, fill_px, OrderStopLoss(), tp, 0, clrNONE);
               }
            }

         }
      }

      // Phase 5: grid add (same-side, spacing, max, gates, once-per-bar)
      if (block_send == 0 && oc > 0) {
         // add_allowed computed above in dbg_signal path: under_max && dist_pts>=step_pts
         int under_max2 = (oc < MaxTrades) ? 1 : 0;
         int add_allowed2 = (under_max2 && (dist_pts >= step_pts)) ? 1 : 0;
         if (add_allowed2 == 1) {
            datetime bar_ts2 = iTime(_Symbol, Period(), 0);
            if (ES_entry_sent_bar_ts != bar_ts2) {
               // Determine basket side (any order decides)
               int total2 = OrdersTotal();
               int basket_is_buy = 0; int basket_is_sell = 0;
               for (int k=0; k<total2; k++) if (OrderSelect(k, SELECT_BY_POS, MODE_TRADES)) {
                  if (OrderSymbol()==_Symbol && OrderMagicNumber()==ES_magic) {
                     if (OrderType()==OP_BUY)  basket_is_buy  = 1;
                     if (OrderType()==OP_SELL) basket_is_sell = 1;
                  }
               }
               int type2 = basket_is_buy ? OP_BUY : OP_SELL;
               double req2 = basket_is_buy ? Ask : Bid;
               // Lots for add: Lot * (LotMultiplikator ^ oc), then broker normalization/clamp
               double stepL = MarketInfo(_Symbol, MODE_LOTSTEP);
               double minL2 = MarketInfo(_Symbol, MODE_MINLOT);
               double maxL2 = MarketInfo(_Symbol, MODE_MAXLOT);
               double lots2 = Lot;
               if (LotMultiplikator > 0) {
                  lots2 = Lot * MathPow(LotMultiplikator, oc);
               }
               if (stepL > 0) lots2 = MathRound(lots2/stepL)*stepL;
               if (lots2 < minL2) lots2 = minL2;
               if (maxL2 > 0 && lots2 > maxL2) lots2 = maxL2;
               lots2 = NormalizeDouble(lots2, 2);
               int slippage2 = 5;
               int ticket2 = ES_OrderSendLogged(_Symbol, type2, lots2, req2, slippage2, 0, 0, "", ES_magic, 0, clrNONE);
               ES_entry_sent_bar_ts = bar_ts2;
            }
         }
      }
   }
   // Phase 4: Basket TP averaging & sync
   {
      int total = OrdersTotal();
      double sumL_buy=0.0, sumPx_buy=0.0; int cnt_buy=0;
      double sumL_sell=0.0, sumPx_sell=0.0; int cnt_sell=0;
      for (int j=total-1; j>=0; j--) {
         if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol()==_Symbol && OrderMagicNumber()==ES_magic) {
               double l = OrderLots();
               if (OrderType()==OP_BUY)  { sumL_buy += l;  sumPx_buy  += l*OrderOpenPrice(); cnt_buy++; }
               if (OrderType()==OP_SELL) { sumL_sell+= l;  sumPx_sell += l*OrderOpenPrice(); cnt_sell++; }
            }
         }
      }
      double tol = Point * 0.1;
      if (cnt_buy > 1 && sumL_buy > 0.0) {
         double avg_buy = sumPx_buy / sumL_buy;
         double tp_buy = NormalizeDouble(avg_buy + TakeProfit * Point, Digits);
         for (int j=total-1; j>=0; j--) {
            if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
               if (OrderSymbol()==_Symbol && OrderMagicNumber()==ES_magic && OrderType()==OP_BUY) {
                  if (MathAbs(OrderTakeProfit() - tp_buy) > tol) {
                     int _ = ES_OrderModifyLogged(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), tp_buy, 0, clrNONE);
                  }
               }
            }
         }
      }
      if (cnt_sell > 1 && sumL_sell > 0.0) {
         double avg_sell = sumPx_sell / sumL_sell;
         double tp_sell = NormalizeDouble(avg_sell - TakeProfit * Point, Digits);
         for (int j=total-1; j>=0; j--) {
            if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
               if (OrderSymbol()==_Symbol && OrderMagicNumber()==ES_magic && OrderType()==OP_SELL) {
                  if (MathAbs(OrderTakeProfit() - tp_sell) > tol) {
                     int _ = ES_OrderModifyLogged(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), tp_sell, 0, clrNONE);
                  }
               }
            }
         }
      }
   }
   ES_BarTickDbg();
   return 0;
}