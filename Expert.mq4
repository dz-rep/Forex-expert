//+------------------------------------------------------------------+
//|                                                      pamTest.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

enum onoff {
   on = 1, //On
   off = 0 //Off
};

//--- input parameters
input onoff     Buy=on;
input onoff     Sell=on;
input double   LotBuy=0.1;
input double   LotSell=0.1;
input double   stoploss=0.0;
input double   TPBuy=0.001;
input double   TPSell=0.001;
input double   StepBuy=0.0005;
input double   StepSell=0.0005;
double point = 0;
int buy;
int sell;
int count;
int prev_reason = -1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (prev_reason != 3 && prev_reason != 9 && prev_reason != 7) {
      int total = OrdersTotal();
      bool can_buy = true;
      bool can_sell = true;
      for (int i = 0; i < total; i++) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
         if (OrderType() == OP_BUY && OrderSymbol() == Symbol()) {
            double diff = Ask - OrderOpenPrice();
            if (diff <= StepBuy && diff >= (0 - StepBuy)) {
               can_buy = false;
            }
         }
         if (OrderType() == OP_SELL && OrderSymbol() == Symbol()) {
            double diff = Bid - OrderOpenPrice();
            if (diff <= StepSell && diff >= (0 - StepSell)) {
               can_sell = false;
            }
         }
      }
      buy = Buy;
      sell = Sell;
      count = 0;
      if (buy == 1 && can_buy) {
         setOrder("B");
         
      }
      if (sell == 1 && can_sell) {
         setOrder("S");
      }
      point = Bid;
   }
   PutButton("B",10,30,"BUY", buy);
   PutButton("S",100,30,"SELL", sell);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   prev_reason = reason;
   if (reason != 3 && reason != 9 && reason != 7) {
      ObjectDelete("B");
      ObjectDelete("S");
   }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int total = OrdersTotal();
   bool can_buy = true;
   bool can_sell = true;
   for (int i = 0; i < total; i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderType() == OP_BUY  && OrderSymbol() == Symbol()) {
         double diff = NormalizeDouble(Ask - OrderOpenPrice(), 4);
         if (diff <= StepBuy && diff >= (0 - StepBuy)) {
            can_buy = false;
         }
      }
      if (OrderType() == OP_SELL  && OrderSymbol() == Symbol()) {
         double diff = NormalizeDouble(Bid - OrderOpenPrice(), 4);
         if (diff <= StepSell && diff >= (0 - StepSell)) {
            can_sell = false;
         }
      }
   }

   if (buy == 1 && can_buy == true) {
      if (point == 0 || NormalizeDouble((Bid - point), 4) >= StepBuy){
        setOrder("B");
      }
   }
   if (sell == 1 && can_sell == true) {
      if (point == 0 || NormalizeDouble((point - Bid), 4) >= StepSell){
        setOrder("S");
      } 
   }
   if ((Bid - point) >= StepBuy || (point - Bid) >= StepSell){
      point = Bid;
   }
  }
//+------------------------------------------------------------------+
void PutButton(string name,int x,int y,string text, int type)
  {
   long chart_id = ChartID();
   ObjectCreate(chart_id, name,OBJ_BUTTON,0,0,0);

//--- установим координаты кнопки
   ObjectSetInteger(chart_id, name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_id, name,OBJPROP_YDISTANCE,y);
//--- установим размер кнопки
   ObjectSetInteger(chart_id, name,OBJPROP_XSIZE,80);
   ObjectSetInteger(chart_id, name,OBJPROP_YSIZE,30);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(chart_id, name,OBJPROP_CORNER,4);
//--- установим текст
   ObjectSetString(chart_id, name,OBJPROP_TEXT,text);
//--- установим шрифт текста
   ObjectSetString(chart_id, name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
   ObjectSetInteger(chart_id, name,OBJPROP_FONTSIZE,12);
//--- установим цвет текста
   ObjectSetInteger(chart_id, name,OBJPROP_COLOR,White);
//--- установим цвет фона
   if (type == 1)
      ObjectSetInteger(chart_id, name,OBJPROP_BGCOLOR,Green);
   else if (type == 0)
      ObjectSetInteger(chart_id, name,OBJPROP_BGCOLOR,Red);
//--- установим цвет границы
   ObjectSetInteger(chart_id, name,OBJPROP_BORDER_COLOR,Blue);
}

void setOrder(string type) {
   double SLB = Ask - stoploss;
   double SLS = Bid + stoploss;
   double TPB = Ask + TPBuy;
   double TPS = Bid - TPSell;
   if (stoploss == 0){
      SLB = 0;
      SLS = 0;
   }
   if (TPBuy == 0)
      TPB = 0;
   if (TPSell == 0)
      TPS = 0;
   if (type == "B")
      int order =  OrderSend(Symbol(),OP_BUY,LotBuy, Ask, 50, SLB, TPB,NULL, 1111);
   else if (type == "S")
      int order =  OrderSend(Symbol(),OP_SELL,LotSell, Bid, 50, SLS, TPS,NULL, 1111);
   count++;
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  long chart_id = ChartID();
//--- проверим событие на нажатие кнопки мышки
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      string clickedChartObject=sparam;
      //--- если нажатие на объекте с именем "B"
      if(clickedChartObject=="B")
        {
            if (buy == 1) {
               buy = 0;
               ObjectSetInteger(chart_id, "B",OBJPROP_BGCOLOR,Red);
            }
            else if (buy == 0) {
               buy = 1;
               ObjectSetInteger(chart_id, "B",OBJPROP_BGCOLOR,Green);
            }
        }
      //--- если нажатие на объекте с именем "S"
      if(clickedChartObject=="S")
        {
            if (sell == 1) {
               sell = 0;
               ObjectSetInteger(chart_id, "S",OBJPROP_BGCOLOR,Red);
            }
            else if (sell == 0) {
               sell = 1;
               ObjectSetInteger(chart_id, "S",OBJPROP_BGCOLOR,Green);
            }
        }
      ChartRedraw();// принудительно перерисуем все объекты на графике
     }
  }
