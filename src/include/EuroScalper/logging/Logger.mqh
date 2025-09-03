#ifndef __EUROSCALPER_LOGGER_MQH__
#define __EUROSCALPER_LOGGER_MQH__

enum ES_LogLevel { ES_LOG_NONE=0, ES_LOG_BASIC=1, ES_LOG_DEBUG=2, ES_LOG_TRACE=3 };

// Context
string ES_log_label      = "";
int    ES_log_level      = ES_LOG_BASIC;
string ES_log_symbol     = "";
int    ES_log_magic      = 0;
int    ES_log_build      = 0;
string ES_log_tf         = "";
string ES_log_fname      = "";
int    ES_log_handle     = -1;

void LogSetLabel(string lbl) { ES_log_label = lbl; }
void LogSetLevel(int lvl)    { ES_log_level = lvl; }

void __LogHeader() {
   if(ES_log_handle < 0) return;
   FileWrite(ES_log_handle,
      "ts","build","symbol","tf","magic","ticket","event","side","lots","price",
      "last_entry_price","avg_price","tp_price","step_pts","tp_pts","spread_pts","slippage_pts",
      "open_count","max_trades","floating_pl","closed_pl_today","equity","margin_free","reason","err","notes");
   FileFlush(ES_log_handle);
}

void LogInit(string sym, int magic, int build, string tf, int spread_pts, int slippage_pts) {
   ES_log_symbol = sym;
   ES_log_magic  = magic;
   ES_log_build  = build;
   ES_log_tf     = tf;
   string base = "EuroScalper_"+sym+"_"+tf+"_"+IntegerToString(magic)+"_"+IntegerToString(build);
   if(StringLen(ES_log_label) > 0) base = base + "_" + ES_log_label;
   ES_log_fname = base + ".csv";
   if(ES_log_handle >= 0) FileClose(ES_log_handle);
   ES_log_handle = FileOpen(ES_log_fname, FILE_CSV|FILE_WRITE, ';');
   if(ES_log_handle >= 0) __LogHeader();
}

// Light note helper for boot/deinit/etc.
void LogNote(string event, string reason, string notes) {
   if(ES_log_handle < 0 || ES_log_level < ES_LOG_BASIC) return;
   string ts = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   FileWrite(ES_log_handle, ts, ES_log_build, ES_log_symbol, ES_log_tf, ES_log_magic,
             0, event, "", 0, 0, 0, 0, 0, 0, 0, 0,
             0, 0, 0, 0, AccountEquity(), AccountFreeMargin(), reason, 0, notes);
   FileFlush(ES_log_handle);
}

// Full row event (BASIC and above)
void LogEvent(string event, string side,
              double lots, double price,
              double last_entry_price, double avg_price, double tp_price,
              int step_pts, int tp_pts, int spread_pts, int slippage_pts,
              int open_count, int max_trades,
              double floating_pl, double closed_pl_today,
              double equity, double margin_free,
              string reason, int err, string notes)
{
   if(ES_log_handle < 0 || ES_log_level < ES_LOG_BASIC) return;
   string ts = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   FileWrite(ES_log_handle, ts, ES_log_build, ES_log_symbol, ES_log_tf, ES_log_magic,
             0, event, side, lots, price, last_entry_price, avg_price, tp_price,
             step_pts, tp_pts, spread_pts, slippage_pts,
             open_count, max_trades, floating_pl, closed_pl_today, equity, margin_free, reason, err, notes);
   FileFlush(ES_log_handle);
}

#endif // __EUROSCALPER_LOGGER_MQH__
