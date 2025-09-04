// EuroScalper Logger (CSV) — implementation
#ifndef ES_LOGGER_MQH_INCLUDED
#define ES_LOGGER_MQH_INCLUDED

#define ES_LOG_NONE   0
#define ES_LOG_BASIC  1
#define ES_LOG_DEBUG  2
#define ES_LOG_TRACE  3

string  ES_log_symbol   = "";
int     ES_log_magic    = 0;
int     ES_log_build    = 0;
string  ES_log_tf       = "";
string  ES_log_label    = "BASELINE";

int     ES_log_level    = ES_LOG_BASIC;
int     ES_log_handle   = -1;
string  ES_log_fname    = "";

void LogSetLevel(int lvl){ if(lvl<0) lvl=0; if(lvl>3) lvl=3; ES_log_level=lvl; }
void LogSetLabel(string lbl){ ES_log_label=lbl; }

string __es_build_base(){
   string base = "EuroScalper_"+ES_log_symbol+"_"+ES_log_tf+"_"+IntegerToString(ES_log_magic)+"_"+IntegerToString(ES_log_build);
   if(StringLen(ES_log_label)>0) base += "_"+ES_log_label;
   return base;
}

void __es_open_if_needed(){
   if(ES_log_magic<=0) return;
   string fname = __es_build_base()+".csv";
   if(ES_log_handle>=0 && fname==ES_log_fname) return;
   if(ES_log_handle>=0) FileClose(ES_log_handle);
   ES_log_fname = fname;
   ES_log_handle = FileOpen(ES_log_fname, FILE_CSV|FILE_WRITE, ';');
   if(ES_log_handle>=0){
      FileWrite(ES_log_handle,
         "ts","build","symbol","tf","magic","ticket","event","side","lots","price",
         "last_entry_price","avg_price","tp_price","step_pts","tp_pts",
         "spread_pts","slippage_pts","open_count","max_trades",
         "floating_pl","closed_pl_today","equity","margin_free","reason","err","notes"
      );
      FileFlush(ES_log_handle);
   }
}

void LogInit(string sym, int magic, int build, string tf, int spread_unused, int slippage_unused){
   ES_log_symbol=sym; ES_log_magic=magic; ES_log_build=build; ES_log_tf=tf;
   __es_open_if_needed();
}

void LogSetMagic(int magic){
   ES_log_magic = magic;
   __es_open_if_needed();
}

void __es_row(string event, string side, int ticket, double lots, double price,
              double last_entry_price, double avg_price, double tp_price,
              int step_pts, int tp_pts, int spread_pts, int slippage_pts,
              int open_count, int max_trades, double floating_pl, double closed_today,
              double equity, double margin_free, string reason, int err, string notes)
{
   if(ES_log_level<=ES_LOG_NONE) return;
   __es_open_if_needed();
   if(ES_log_handle<0) return;
   string ts = TimeToStr(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   FileWrite(ES_log_handle,
      ts, IntegerToString(ES_log_build), ES_log_symbol, ES_log_tf, IntegerToString(ES_log_magic),
      IntegerToString(ticket), event, side,
      DoubleToString(lots, 2), DoubleToString(price, Digits),
      DoubleToString(last_entry_price, Digits), DoubleToString(avg_price, Digits),
      DoubleToString(tp_price, Digits), IntegerToString(step_pts), IntegerToString(tp_pts),
      IntegerToString(spread_pts), IntegerToString(slippage_pts),
      IntegerToString(open_count), IntegerToString(max_trades),
      DoubleToString(floating_pl,2), DoubleToString(closed_today,2),
      DoubleToString(equity,2), DoubleToString(margin_free,2),
      reason, IntegerToString(err), notes
   );
   FileFlush(ES_log_handle);
}

void LogEvent(string event, string side, double lots, double price, double last_entry_price,
              double avg_price, double tp_price, int step_pts, int tp_pts,
              int spread_pts, int slippage_pts, int open_count, int max_trades,
              double floating_pl, double closed_today, double equity, double margin_free,
              string reason, int err, string notes)
{
   __es_row(event, side, 0, lots, price, last_entry_price, avg_price, tp_price,
            step_pts, tp_pts, spread_pts, slippage_pts, open_count, max_trades,
            floating_pl, closed_today, equity, margin_free, reason, err, notes);
}

void LogNote(string event, string reason, string notes){
   double eq = AccountEquity();
   double mf = AccountFreeMargin();
   __es_row(event, "", 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            eq, mf, reason, 0, notes);
}

#endif // ES_LOGGER_MQH_INCLUDED