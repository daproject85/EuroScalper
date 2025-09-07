// EuroScalper Forensic Logger (CSV)
#ifndef ES_LOGGER_MQH_INCLUDED
#define ES_LOGGER_MQH_INCLUDED

// Levels kept for EA input compatibility; writer respects BASIC+
#define ES_LOG_NONE   0
#define ES_LOG_BASIC  1
#define ES_LOG_DEBUG  2
#define ES_LOG_TRACE  3

// Persistent identity
string  ES_log_symbol   = "";
int     ES_log_magic    = 0;
int     ES_log_build    = 0;
string  ES_log_tf       = "";
string  ES_log_label    = "BASELINE";
int     ES_log_level    = ES_LOG_BASIC;
// Static writer state
int     ES_log_handle   = -1;
int     ES_log_spread_pts = 0;
int     ES_log_slip_pts   = -1;

// Compose filename; do NOT open when magic==0 (avoid _0_ files)
string __es_filename() {
   string base = "EuroScalper_"+ES_log_symbol+"_"+ES_log_tf+"_"+IntegerToString(ES_log_magic)+"_"+IntegerToString(ES_log_build);
   if(StringLen(ES_log_label)>0) base = base + "_" + ES_log_label;
   return(base + ".csv");
}

void __es_header() {
   if(ES_log_handle < 0) return;
      FileWrite(ES_log_handle,
      "ts","build","symbol","tf","magic","ticket","event","side","lots","bid","ask","price","last_entry_price","tp_price","spread_pts","open_count","floating_pl","closed_pl_today","equity","balance","margin_free","reason","err","notes");
FileFlush(ES_log_handle);
}

void __es_open_if_needed() {
   if(ES_log_magic <= 0) return; // postpone until magic is known
   static string opened_name = "";
   string fname = __es_filename();
   if(ES_log_handle >= 0 && opened_name == fname) return;
   if(ES_log_handle >= 0) { FileClose(ES_log_handle); ES_log_handle = -1; }
   ES_log_handle = FileOpen(fname, FILE_CSV|FILE_READ|FILE_WRITE|FILE_SHARE_WRITE, ';');
   if(ES_log_handle >= 0) {
      opened_name = fname;
      int sz = (int)FileSize(ES_log_handle);
      FileSeek(ES_log_handle, 0, SEEK_END);
      if(sz == 0) __es_header();
   }
}

// -------- Public API used by EA --------
void LogSetLevel(int level) { ES_log_level = level; }
void LogSetLabel(string label) { ES_log_label = label; __es_open_if_needed(); }
void LogSetMagic(int magic) { ES_log_magic = magic; __es_open_if_needed(); }

void LogInit(string symbol, int magic, int build, string tf, int spread_pts, int slippage_pts) {
   ES_log_symbol    = symbol;
   ES_log_magic     = magic;
   ES_log_build     = build;
   ES_log_tf        = tf;
   ES_log_spread_pts= spread_pts;
   ES_log_slip_pts  = slippage_pts;
   __es_open_if_needed();
}

// Low-level row writer
void __es_row_at(datetime ts_at,
                 string event, string side,
                 int ticket,
                 double lots, double price,
                 double last_entry_price, double avg_price, double tp_price,
                 int step_pts, int tp_pts, int spread_pts, int slippage_pts,
                 int open_count, int max_trades,
                 double floating_pl, double closed_pl_today,
                 double equity, double margin_free,
                 string reason, int err, string notes)
{
   if(ES_log_level < ES_LOG_BASIC) return;
   __es_open_if_needed();
   if(ES_log_handle < 0) return;
   string ts = TimeToString(ts_at, TIME_DATE|TIME_SECONDS);
   string _bid  = DoubleToStr(Bid, 5);
string _ask  = DoubleToStr(Ask, 5);
string _lots = (lots == 0.0 ? "" : DoubleToStr(lots, 2));
string _price= (price == 0.0 ? "" : DoubleToStr(price, 5));
string _lep  = (last_entry_price == 0.0 ? "" : DoubleToStr(last_entry_price, 5));
string _tp   = (tp_price == 0.0 ? "" : DoubleToStr(tp_price, 5));
bool _is_io  = (event == "send_req" || event == "send_ok" || event == "modify_req" || event == "modify_ok" || event == "close_filled");

string _notes = (event == "modify_req" || event == "send_req" || event == "send_ok") ? "" : notes;
bool _dbg_g1   = (event == "dbg_gates");
bool _dbg_g2   = (event == "dbg_scan" || event == "bar_tick_dbg");

if(_is_io) {
   // I/O events: keep 3 blanks after reason
   FileWrite(ES_log_handle, ts, ES_log_build, ES_log_symbol, ES_log_tf, ES_log_magic,
             ticket, event, side, _lots, _bid, _ask, _price, _lep, _tp,
             spread_pts, open_count, floating_pl, closed_pl_today,
             equity, AccountBalance(), margin_free, reason, "", "", "", err, _notes);
} else if(_dbg_g2) {
   // dbg_scan / bar_tick_dbg: 2 blanks after reason
   FileWrite(ES_log_handle, ts, ES_log_build, ES_log_symbol, ES_log_tf, ES_log_magic,
             ticket, event, side, _lots, _bid, _ask, _price, _lep, _tp,
             spread_pts, open_count, floating_pl, closed_pl_today,
             equity, AccountBalance(), margin_free, reason, "", "", err, _notes);
} else if(_dbg_g1) {
   // dbg_gates: 1 blank after reason
   FileWrite(ES_log_handle, ts, ES_log_build, ES_log_symbol, ES_log_tf, ES_log_magic,
             ticket, event, side, _lots, _bid, _ask, _price, _lep, _tp,
             spread_pts, open_count, floating_pl, closed_pl_today,
             equity, AccountBalance(), margin_free, reason, "", err, _notes);
} else {
   // default path: no extra blanks
   FileWrite(ES_log_handle, ts, ES_log_build, ES_log_symbol, ES_log_tf, ES_log_magic,
             ticket, event, side, _lots, _bid, _ask, _price, _lep, _tp,
             spread_pts, open_count, floating_pl, closed_pl_today,
             equity, AccountBalance(), margin_free, reason, err, _notes);
}
FileFlush(ES_log_handle);
}

// Convenience wrappers
void LogEventAt(datetime ts_at, string event, string side, int ticket,
                double lots, double price,
                double last_entry_price, double avg_price, double tp_price,
                int step_pts, int tp_pts, int spread_pts, int slippage_pts,
                int open_count, int max_trades,
                double floating_pl, double closed_pl_today,
                double equity, double margin_free,
                string reason, int err, string notes)
{
   __es_row_at(ts_at, event, side, ticket, lots, price, last_entry_price, avg_price, tp_price,
               step_pts, tp_pts, spread_pts, slippage_pts,
               open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
}

void LogEvent(string event, string side, int ticket,
              double lots, double price,
              double last_entry_price, double avg_price, double tp_price,
              int step_pts, int tp_pts, int spread_pts, int slippage_pts,
              int open_count, int max_trades,
              double floating_pl, double closed_pl_today,
              double equity, double margin_free,
              string reason, int err, string notes)
{
   __es_row_at(TimeCurrent(), event, side, ticket, lots, price, last_entry_price, avg_price, tp_price,
               step_pts, tp_pts, spread_pts, slippage_pts,
               open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
}

void LogNote(string event, string reason, string notes) {
   __es_row_at(TimeCurrent(), event, "", 0, 0, 0, 0, 0, 0,
               0, 0, ES_log_spread_pts, ES_log_slip_pts,
               0, 0, 0, 0, AccountEquity(), AccountFreeMargin(), reason, 0, notes);
}

#endif // ES_LOGGER_MQH_INCLUDED