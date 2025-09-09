//+------------------------------------------------------------------+
//|                                             Euroscalper_rewrite  |
//| Phase 0 scaffold: boots, logs, no trading                         |
//+------------------------------------------------------------------+
#property strict

#include <WinUser32.mqh>
#include <EuroScalper/logging/Logger.mqh>
#include <EuroScalper/core/Normalize.mqh>

// ---------------- Inputs (minimal) ----------------
extern int    ES_LogLevelInput = 2;   // 0=none,1=basic,2=debug

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
      if (ES_LogLevelInput >= 2) LogNote("bar_tick_dbg", hb, "");
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

   // Boot row
   if (ES_LogLevelInput >= 1) {
      string r = StringFormat("boot:app=Euroscalper_rewrite|build=%d|log_suffix=_REWRITE|magic=%d", 1143, ES_magic);
      LogNote("boot", r, "");
   }
   return 0;
}

int deinit() {
   if (ES_LogLevelInput >= 1) LogNote("shutdown", "reason=detach", "");
   return 0;
}

int start() {
   // Per tick; do not trade in Phase 0
   ES_BarTickDbg();

   if (ES_LogLevelInput >= 2) {
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
      int max_trades = 47;
      int step_pts   = 15;
      int spread_pts = 2;
      string si = StringFormat("in:bar_ago=0;spread_pts=%d;open_count=%d;max_trades=%d;last_entry=%.5f;step=%d;dist_from_last_pts=%d",
                               spread_pts, oc, max_trades, last, step_pts, 0);
      LogNote("dbg_signal_in", si, "");

      // dbg_signal (no trading; deterministic seed rule echo)
      string sd = "dir=BUY;rule=grid_seed;add_allowed=0;ok=1";
      LogNote("dbg_signal", sd, "");
   }
   return 0;
}