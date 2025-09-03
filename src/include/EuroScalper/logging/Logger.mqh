// EuroScalper Logger — clean MQL4 implementation — 2025-09-03T02:13:11Z
#ifndef __EUROSCALPER_LOGGER_MQH__
#define __EUROSCALPER_LOGGER_MQH__

enum ES_LogLevel_e { ES_LOG_NONE=0, ES_LOG_BASIC=1, ES_LOG_DEBUG=2, ES_LOG_TRACE=3 };

int    ES__log_level          = ES_LOG_TRACE;
int    ES__log_handle         = -1;
string ES__log_filename       = "";
string ES__symbol             = "";
int    ES__magic              = 0;
int    ES__build              = 0;
string ES__tf                 = "";
int    ES__profile_spread_pts = 0;
int    ES__profile_slip_pts   = -1;
string ES__label              = "";
bool   ES__flat_path          = false;

string ES__NowISO() { return(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)); }

void ES__WriteHeader() {
   if(ES__log_handle < 0) return;
   if(FileTell(ES__log_handle) == 0) {
      FileWrite(ES__log_handle,
         "ts","build","symbol","tf","magic","ticket","event","side","lots","price",
         "last_entry_price","avg_price","tp_price","step_pts","tp_pts","spread_pts","slippage_pts",
         "open_count","max_trades","floating_pl","closed_pl_today","equity","margin_free",
         "reason","err","notes");
   }
}

void LogSetLevel(int level) { ES__log_level = MathMax(ES_LOG_NONE, MathMin(ES_LOG_TRACE, level)); }
int  LogGetLevel() { return(ES__log_level); }
void LogSetLabel(string label) { ES__label = label; }

void LogInit(string sym, int magic, int build, string tf, int spread_pts, int slippage_pts) {
   ES__symbol = sym; ES__magic = magic; ES__build = build; ES__tf = tf;
   ES__profile_spread_pts = spread_pts; ES__profile_slip_pts = slippage_pts;

   string base = StringFormat("EuroScalper_%s_%s_%d_%d", sym, tf, magic, build);
   ES__log_filename = (StringLen(ES__label)>0 ? base + "_" + ES__label + ".csv" : base + ".csv");

   string preferred = "EuroScalper\\logs\\" + ES__log_filename; // under MQL4/Files
   ES__log_handle = FileOpen(preferred, FILE_CSV|FILE_READ|FILE_WRITE|FILE_ANSI);
   if(ES__log_handle < 0) { ES__flat_path = true; ES__log_handle = FileOpen(ES__log_filename, FILE_CSV|FILE_READ|FILE_WRITE|FILE_ANSI); }
   if(ES__log_handle < 0) return;
   ES__WriteHeader();
}

void ES__WriteRow(string event, string side, double lots, double price, double last_entry_price,
                  double avg_price, double tp_price, int step_pts, int tp_pts, int spread_pts, int slippage_pts,
                  int open_count, int max_trades, double floating_pl, double closed_pl_today,
                  double equity, double margin_free, string reason, int err, string notes) {
   if(ES__log_handle < 0) return;
   FileWrite(ES__log_handle,
      ES__NowISO(), ES__build, ES__symbol, ES__tf, ES__magic, 0, event, side, lots, price,
      last_entry_price, avg_price, tp_price, step_pts, tp_pts, spread_pts, slippage_pts,
      open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
}

void LogEvent(string event, string side, double lots, double price, double last_entry_price,
              double avg_price, double tp_price, int step_pts, int tp_pts, int spread_pts, int slippage_pts,
              int open_count, int max_trades, double floating_pl, double closed_pl_today,
              double equity, double margin_free, string reason, int err, string notes) {
   if(ES__log_level < ES_LOG_BASIC) return;
   ES__WriteRow(event, side, lots, price, last_entry_price, avg_price, tp_price, step_pts, tp_pts, spread_pts, slippage_pts,
                open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
}

void LogEventDebug(string event, string side, double lots, double price, double last_entry_price,
                   double avg_price, double tp_price, int step_pts, int tp_pts, int spread_pts, int slippage_pts,
                   int open_count, int max_trades, double floating_pl, double closed_pl_today,
                   double equity, double margin_free, string reason, int err, string notes) {
   if(ES__log_level < ES_LOG_DEBUG) return;
   ES__WriteRow(event, side, lots, price, last_entry_price, avg_price, tp_price, step_pts, tp_pts, spread_pts, slippage_pts,
                open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
}

void LogEventTrace(string event, string side, double lots, double price, double last_entry_price,
                   double avg_price, double tp_price, int step_pts, int tp_pts, int spread_pts, int slippage_pts,
                   int open_count, int max_trades, double floating_pl, double closed_pl_today,
                   double equity, double margin_free, string reason, int err, string notes) {
   if(ES__log_level < ES_LOG_TRACE) return;
   ES__WriteRow(event, side, lots, price, last_entry_price, avg_price, tp_price, step_pts, tp_pts, spread_pts, slippage_pts,
                open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
}

void LogNote(string event, string side, string notes) {
   if(ES__log_level < ES_LOG_BASIC) return;
   ES__WriteRow(event, side, 0, 0, 0, 0, 0, 0, 0, ES__profile_spread_pts, ES__profile_slip_pts,
                0, 0, 0, 0, AccountEquity(), AccountFreeMargin(), "", 0, notes + (ES__flat_path? " (flat_path)" : ""));
}

#endif // __EUROSCALPER_LOGGER_MQH__
