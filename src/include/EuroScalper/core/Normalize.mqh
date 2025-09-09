// Normalize helpers — Phase 1 (broker-safe price/lot math)
#ifndef ES_NORMALIZE_MQH_INCLUDED
#define ES_NORMALIZE_MQH_INCLUDED

// Points ↔ price
double ES_PointsToPrice(int pts)        { return pts * Point; }
double ES_AddPoints(double price, int pts) { return NormalizeDouble(price + pts * Point, Digits); }
double ES_SubPoints(double price, int pts) { return NormalizeDouble(price - pts * Point, Digits); }
double ES_NormalizePrice(double p)         { return NormalizeDouble(p, Digits); }

// Lot step / min / max
double ES_LotStep() { return MarketInfo(Symbol(), MODE_LOTSTEP); }
double ES_MinLot()  { return MarketInfo(Symbol(), MODE_MINLOT);  }
double ES_MaxLot()  { return MarketInfo(Symbol(), MODE_MAXLOT);  }

double ES_NormalizeLot(double lot) {
   double step = ES_LotStep();
   double minL = ES_MinLot();
   double maxL = ES_MaxLot();
   double x = lot;
   if(step > 0) x = MathRound(x/step) * step;
   if(x < minL) x = minL;
   if(maxL > 0 && x > maxL) x = maxL;
   // Round to 2 decimals for CSV readability, brokers commonly accept 2
   return NormalizeDouble(x, 2);
}

// Broker constraints
int ES_StopLevelPts()   { return (int)MarketInfo(Symbol(), MODE_STOPLEVEL);   }
int ES_FreezeLevelPts() { return (int)MarketInfo(Symbol(), MODE_FREEZELEVEL); }

#endif // ES_NORMALIZE_MQH_INCLUDED
