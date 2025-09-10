//+------------------------------------------------------------------+
//|                                             Euroscalper_rewrite  |
//| Phase 0 scaffold: boots, logs, no trading                         |
//+------------------------------------------------------------------+
#property strict

#include <WinUser32.mqh>
#include <EuroScalper/logging/Logger.mqh>
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
      string c = StringFormat("closers:daily=%d;equity=%d;open=%d;flt=%.2f",
                              0, 0, oc, flt);
      LogNote("dbg_closers", c, "");

      // dbg_gates (session/time gate only placeholder, block=0)
      string g = StringFormat("gate:dow=%d;hour=%d;block=0", DayOfWeek(), Hour());
      LogNote("dbg_gates", g, "");

      // dbg_scan
      string s = StringFormat("scan:open_count=%d;last_entry=%.5f", oc, last);
      LogNote("dbg_scan", s, "");

      // dbg_signal_in (inputs snapshot similar to baseline)
      int max_trades = MaxTrades;
      int step_pts   = (int)Step;
      int spread_pts = (int)MathRound((Ask - Bid)/Point);
      double open_px = Ask;
      int dist_pts = (last > 0.0) ? (int)MathAbs((open_px - last)/Point) : 0;
      string si = StringFormat("in:bar_ago=0|spread_pts=%d|open_count=%d|max_trades=%d|last_entry=%.5f|step=%d|dist_from_last_pts=%d", spread_pts, oc, max_trades, last, step_pts, dist_pts);
      LogNote("dbg_signal_in", si, "");

      // dbg_signal (no trading; deterministic seed rule echo)
      string sd;
      if (oc == 0) {
         sd = "dir=BUY;rule=grid_seed;add_allowed=0;ok=1";
      } else {
         int under_max = (oc < MaxTrades) ? 1 : 0;
         int add_allowed = (under_max && (dist_pts >= step_pts)) ? 1 : 0;
         int ok = add_allowed;
         sd = StringFormat("dir=NONE;rule=grid_add;add_allowed=%d;ok=%d;why=step", add_allowed, ok);
      }
      LogNote("dbg_signal", sd, "");
   }
   ES_BarTickDbg();
   return 0;
}