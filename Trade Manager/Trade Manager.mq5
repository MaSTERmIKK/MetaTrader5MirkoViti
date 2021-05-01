﻿//
// Trade Manager.mq4/mq5
// getYourNet.ch
//

#property copyright "Copyright 2021, getYourNet.ch"
#property link "http://shop.getyournet.ch/trademanager"

#ifdef __MQL4__
   #include <..\Libraries\stdlib.mq4>
#endif
#ifdef __MQL5__
   #include <Trade\Trade.mqh>
   #include <errordescription.mqh>

   enum OrderType
   {
      OP_BUY,
      OP_SELL
   };
#endif

#include <CurrencyStrength.mqh>
#include <MultiPivots.mqh>
#ifdef __MQL5__
   //#include <CurrencyStrengthReadDB.mqh>
#endif

enum TypeAutomation
{
   NoAutomation, // None
   Dredging // Dredging System
};

enum TypeInstance
{
   Instance1=1,
   Instance2=2,
   Instance3=3,
   Instance4=4,
   Instance5=5,
   Instance6=6,
   Instance7=7,
   Instance8=8,
   Instance9=9
};

enum TypeStopLossPercentTradingCapitalAction
{
   CloseWorstTrade,
   CloseAllTrades
};

input TypeInstance Instance = 1;
input TypeAutomation Automation = NoAutomation;
input double BreakEvenAfterPips = 5;
input double AboveBEPips = 1;
input double StartTrailingPips = 7;
input double TakeProfitPips = 0;
input double StopLossPips = 0;
input bool HedgeAtStopLoss = false;
input double HedgeVolumeFactor = 1;
input double HedgeFlatAtLevel = 5;
input double TakeProfitPercentTradingCapital = 0;
input double StopLossPercentTradingCapital = 0;
input TypeStopLossPercentTradingCapitalAction StopLossPercentTradingCapitalAction = CloseAllTrades;
input bool CloseTradesBeforeMidnight = false;
input bool ActivateTrailing = false;
input double TrailingFactor = 0.6;
input double OpenLots = 0.01;
input bool ShowInfo = true;
input color TextColor = Gray;
input color TextColorBold = Black;
input color TextColorInfo = DodgerBlue;
input color TextColorPlus = MediumSeaGreen;
input color TextColorMinus = DeepPink;
input int FontSize = 9;
input int TextGap = 16;
input bool ManageOwnTradesOnly = true;
input int ManageMagicNumberOnly = 0;
input int ManageOrderNumberOnly = 0;
input bool SwitchSymbolClickAllCharts = true;
input bool DrawLevelsAllCharts = true;
input bool DrawBackgroundPanel = true;
input int BackgroundPanelWidth = 250;
input color BackgroundPanelColor = clrNONE;
input bool MT5CommissionPerDeal = true;
input double CommissionPerLotPerRoundtrip = 7;
input int AvailableTradingCapital = 0;
input int StartHour = 0;
input int StartMinute = 0;
input int MinPoints1 = 0;
input group "Harvesters";
input bool Harvester_CSGBPBaskets = false;
input group "Trading Hours";
input bool Hour0 = true;
input bool Hour1 = true;
input bool Hour2 = true;
input bool Hour3 = true;
input bool Hour4 = true;
input bool Hour5 = true;
input bool Hour6 = true;
input bool Hour7 = true;
input bool Hour8 = true;
input bool Hour9 = true;
input bool Hour10 = true;
input bool Hour11 = true;
input bool Hour12 = true;
input bool Hour13 = true;
input bool Hour14 = true;
input bool Hour15 = true;
input bool Hour16 = true;
input bool Hour17 = true;
input bool Hour18 = true;
input bool Hour19 = true;
input bool Hour20 = true;
input bool Hour21 = true;
input bool Hour22 = true;
input bool Hour23 = true;
input group "Trading Weekdays";
input bool Sunday = true;
input bool Monday = true;
input bool Tuesday = true;
input bool Wednesday = true;
input bool Thursday = true;
input bool Friday = true;
input bool Saturday = true;

string appname="Trade Manager";
string appnamespace="";
bool working=false;
double pipsfactor;
datetime lasttick;
datetime lasterrortime;
string lasterrorstring;
bool istesting;
bool initerror;
string SymbolExtraChars = "";
string tickchar="";
int magicnumberfloor=0;
int basemagicnumber=0;
int hedgeoffsetmagicnumber=10000;
double _BreakEvenAfterPips;
double _AboveBEPips;
double _StartTrailingPips;
double _TakeProfitPips;
double _StopLossPips;
double _OpenLots;
bool _TradingHours[24];
bool _TradingWeekdays[7];
bool ctrlon;
bool tradelevelsvisible;
int selectedtradeindex;
uint repeatlasttick=0;
int repeatcount=0;
double atr;
int atrday;
int InstrumentSelected;
int TradesViewSelected;
const double DISABLEDPOINTS=1000000;

struct TypeTextObjects
{
   string objects[];
   void AddObject(string name)
   {
      bool found=false;
      int size=ArraySize(objects);
      for(int i=0; i<size; i++)
      {
         if(objects[i]==name)
         {
            found=true;
            break;
         }
      }
      if(!found)
      {
         ArrayResize(objects,size+1);
         objects[size]=name;
      }
   }
   void HideAll()
   {
      int size=ArraySize(objects);
      for(int i=0; i<size; i++)
         ObjectSetInteger(0,objects[i],OBJPROP_XDISTANCE,-1000);
   }
};
TypeTextObjects TextObjects;

enum BEStopModes
{
   None=1,
   HardSingle=2,
   SoftBasket=3
};

enum Instruments
{
   CurrentPair,
   USD,
   EUR,
   GBP,
   JPY,
   CHF,
   CAD,
   AUD,
   NZD,
};

enum TradesView
{
   ByPairs,
   ByCurrencies
};

struct TypeTradeInfo
{
   int orderindex;
   int type;
   double volume;
   double openprice;
   double points;
   double commissionpoints;
   double gain;
   double tickvalue;
   long magicnumber;
   long orderticket;
   TypeTradeInfo()
   {
      orderindex=-1;
      type=NULL;
      volume=0;
      openprice=0;
      points=0;
      commissionpoints=0;
      gain=0;
      tickvalue=0;
      magicnumber=0;
      orderticket=0;
   }
};

struct TypeTradeReference
{
   long magicnumber;
   double points;
   double gain;
   double tickvalue;
   double stoplosspips;
   double stoplosslevel;
   double takeprofitpips;
   double takeprofitlevel;
   double commissionpoints;
   double openprice;
   string pair;
   int type;
   double volume;
   datetime lastupdate;
   TypeTradeReference()
   {
      magicnumber=0;
      points=0;
      gain=0;
      tickvalue=0;
      stoplosspips=DISABLEDPOINTS;
      stoplosslevel=0;
      takeprofitpips=DISABLEDPOINTS;
      takeprofitlevel=0;
      commissionpoints=0;
      openprice=0;
      pair="";
      type=NULL;
      volume=0;
      lastupdate=0;
   }
};

struct TypeCloseCommand
{
   string filter;
   bool executed;
   TypeCloseCommand()
   {
      filter="";
      executed=false;
   }
};

struct TypeCloseCommands
{
   TypeCloseCommand commands[];
   void Init()
   {
      ArrayResize(commands,0);
   }
   void Add(string filter="")
   {
      int size=ArraySize(commands);
      ArrayResize(commands,size+1);
      commands[size].filter=filter;
   }
   int GetNextCommandIndex()
   {
      int index=-1;
      for(int i=ArraySize(commands)-1; i>=0; i--)
      {
         if(!commands[i].executed)
         {
            index=i;
            break;
         }
      }
      return index;
   }
};

struct TypeWorkingState
{
   BEStopModes StopMode;
   bool closebasketatBE;
   bool ManualBEStopLocked;
   bool SoftBEStopLocked;
   double peakgain;
   double peakpips;
   bool TrailingActivated;
   long currentbasemagicnumber;
   TypeTradeReference tradereference[];
   double globalgain;
   datetime lastorderexecution;
   TypeCloseCommands closecommands;
   void Init()
   {
      closebasketatBE=false;
      ManualBEStopLocked=false;
      SoftBEStopLocked=false;
      StopMode=SoftBasket;
      peakgain=0;
      peakpips=0;
      TrailingActivated=false;
      currentbasemagicnumber=basemagicnumber;
      ArrayResize(tradereference,0);
      globalgain=0;
      lastorderexecution=0;
      closecommands.Init();
   };
   void Reset()
   {
      closebasketatBE=false;
      ManualBEStopLocked=false;
      SoftBEStopLocked=false;
      peakgain=0;
      peakpips=0;
      TrailingActivated=false;
      currentbasemagicnumber=basemagicnumber;
      ArrayResize(tradereference,0);
      globalgain=0;
      ToggleTradeLevels(true);
      closecommands.Init();
   };
   void ResetLocks()
   {
      ManualBEStopLocked=false;
      SoftBEStopLocked=false;
   };
   bool IsOrderPending()
   {
      int lastordertimediff = (int)TimeLocal()-(int)lastorderexecution;
      return (lastordertimediff<=5);
   };
};
TypeWorkingState WS;

struct TypeCurrenciesTradesInfo
{
   double buyvolume;
   double sellvolume;
   double buygain;
   double sellgain;
   TypeCurrenciesTradesInfo()
   {
      buyvolume=0;
      sellvolume=0;
      buygain=0;
      sellgain=0;
   }
};

struct TypePairsTradesInfo
{
   string pair;
   double buyvolume;
   double sellvolume;
   double buygain;
   double sellgain;
   double gain;
   double gainpips;
   TypeTradeInfo tradeinfo[];
   TypePairsTradesInfo()
   {
      pair="";
      buyvolume=0;
      sellvolume=0;
      buygain=0;
      sellgain=0;
      gain=0;
      gainpips=0;
      ArrayResize(tradeinfo,0);
   }
};

struct TypeBasketInfo
{
   double gain;
   double gainpips;
   double gainpipsglobal;
   double gainpipsplus;
   double gainpipsminus;
   double volumeplus;
   double volumeminus;
   int buys;
   int sells;
   double buyvolume;
   double sellvolume;
   int managedorders;
   TypePairsTradesInfo pairsintrades[];
   int largestlossindex;
   double largestloss;
   void Init()
   {
      gain=0;
      gainpips=0;
      gainpipsglobal=0;
      gainpipsplus=0;
      gainpipsminus=0;
      volumeplus=0;
      volumeminus=0;
      buys=0;
      sells=0;
      buyvolume=0;
      sellvolume=0;
      managedorders=0;
      ArrayResize(pairsintrades,0);
      largestlossindex=-1;
      largestloss=0;
   };
};
TypeBasketInfo BI;


void OnInit()
{
   atr=0;
   atrday=-1;
   
   InstrumentSelected=CurrentPair;

   TradesViewSelected=ByPairs;

   ctrlon=false;
   tradelevelsvisible=false;

   initerror=false;
   
   appnamespace=appname+" "+IntegerToString(Instance)+" ";

   magicnumberfloor=10000000*Instance;

   basemagicnumber=magicnumberfloor+1;

   istesting=MQLInfoInteger(MQL_TESTER);

   SymbolExtraChars = StringSubstr(Symbol(), 6);

   pipsfactor=1;
   
   lasttick=TimeLocal();

   if(Digits()==5||Digits()==3)
      pipsfactor=10;

   _BreakEvenAfterPips=BreakEvenAfterPips*pipsfactor;
   _AboveBEPips=AboveBEPips*pipsfactor;
   _TakeProfitPips=TakeProfitPips*pipsfactor;
   if(_TakeProfitPips==0)
      _TakeProfitPips=DISABLEDPOINTS;
   _StopLossPips=StopLossPips*pipsfactor;
   if(_StopLossPips==0)
      _StopLossPips=DISABLEDPOINTS;
   _StartTrailingPips=StartTrailingPips*pipsfactor;
   _OpenLots=OpenLots;

   _TradingHours[0]=Hour0;
   _TradingHours[1]=Hour1;
   _TradingHours[2]=Hour2;
   _TradingHours[3]=Hour3;
   _TradingHours[4]=Hour4;
   _TradingHours[5]=Hour5;
   _TradingHours[6]=Hour6;
   _TradingHours[7]=Hour7;
   _TradingHours[8]=Hour8;
   _TradingHours[9]=Hour9;
   _TradingHours[10]=Hour10;
   _TradingHours[11]=Hour11;
   _TradingHours[12]=Hour12;
   _TradingHours[13]=Hour13;
   _TradingHours[14]=Hour14;
   _TradingHours[15]=Hour15;
   _TradingHours[16]=Hour16;
   _TradingHours[17]=Hour17;
   _TradingHours[18]=Hour18;
   _TradingHours[19]=Hour19;
   _TradingHours[20]=Hour20;
   _TradingHours[21]=Hour21;
   _TradingHours[22]=Hour22;
   _TradingHours[23]=Hour23;

   _TradingWeekdays[0]=Sunday;
   _TradingWeekdays[1]=Monday;
   _TradingWeekdays[2]=Tuesday;
   _TradingWeekdays[3]=Wednesday;
   _TradingWeekdays[4]=Thursday;
   _TradingWeekdays[5]=Friday;
   _TradingWeekdays[6]=Saturday;

   WS.Init();
   
   if(!istesting)
      GetGlobalVariables();

   if(DrawBackgroundPanel&&ShowInfo)
   {
      string objname=appnamespace+"Panel";
      ObjectCreate(0,objname,OBJ_RECTANGLE_LABEL,0,0,0,0,0);
      ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,objname,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,objname,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,BackgroundPanelWidth);
      ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,TextGap);
      ObjectSetInteger(0,objname,OBJPROP_XSIZE,BackgroundPanelWidth);
      ObjectSetInteger(0,objname,OBJPROP_YSIZE,10000);
      color c=(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
      if(BackgroundPanelColor!=clrNONE)
         c=BackgroundPanelColor;
      ObjectSetInteger(0,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(0,objname,OBJPROP_BGCOLOR,c);
   }

   InitStrategies();
   
   InitTesting();

   if(!istesting)
   {
      if(!EventSetMillisecondTimer(200))
         initerror=true;
   }
}


void InitTesting()
{
   if(!istesting)
      return;

   //WS.StopMode=None;
   //_OpenLots=0.1;
   //ctrlon=true;
   //TradesViewSelected=ByCurrencies;

   //OpenBuy("GBPUSD");
   //OpenSell("EURGBP");
   //OpenBuy("GBPJPY");
   //OpenBuy("GBPCHF");
   //OpenBuy("GBPCAD");
   //OpenBuy("GBPAUD");
   //OpenBuy("GBPNZD");

   //OpenSell("GBPUSD");
   //OpenBuy("EURGBP");
   //OpenSell("GBPJPY");
   //OpenSell("GBPCHF");
   //OpenSell("GBPCAD");
   //OpenSell("GBPAUD");
   //OpenSell("GBPNZD");

   //WS.closecommands.Add();

   //ArrayResize(strats,1);
   //strats[0]=new StrategyCSGBPBaskets;
   //strats[0]=new StrategyOutOfTheBox;
   //strats[0]=new StrategyLittleDD;
   //strats[0]=new StrategyPivotsH4FibonacciR1S1Reversal;

#ifdef __MQL5__
   //OpenDBConnection();
   //CloseDBConnection();
#endif
}


void InitStrategies()
{
   ArrayResize(strats,0);

   if(Harvester_CSGBPBaskets)
   {
      ArrayResize(strats,1);
      strats[0]=new StrategyCSGBPBaskets;
   }
}


void OnDeinit(const int reason)
{
   for(int i=ArraySize(strats)-1; i>=0; i--)
      delete strats[i];

   EventKillTimer();
#ifdef __MQL5__
   if(istesting)
   {
      //CloseDBConnection();
   //if(!MQL5InfoInteger(MQL5_OPTIMIZATION))
   }
#endif
   if(!istesting)
   {
      DeleteAllObjects();
      SetGlobalVariables();
      ToggleCtrl(true);
      ToggleTradeLevels(true);
   }
}


void OnTick()
{
   lasttick=TimeLocal();

   if(ctrlon)
      DrawLevels();

   Manage();
}


void OnTimer()
{
   Manage();
}


void Manage()
{
   if(working||initerror||!TerminalInfoInteger(TERMINAL_CONNECTED))
      return;
   working=true;

   int closecommandindex=WS.closecommands.GetNextCommandIndex();
   while(closecommandindex>-1)
   {
      CloseAllInternal(WS.closecommands.commands[closecommandindex].filter);
      WS.closecommands.commands[closecommandindex].executed=true;
      closecommandindex=WS.closecommands.GetNextCommandIndex();
   }

   if(ManageOrders())
   {
      ManageBasket();
      DisplayText();
   }

   for(int i=ArraySize(strats)-1; i>=0; i--)
      strats[i].Calculate();

   working=false;
}


void SetBEClose()
{
   if(WS.globalgain<0)
   {
      WS.closebasketatBE=!WS.closebasketatBE;
   }
   if(WS.globalgain>=0)
   {
      WS.ManualBEStopLocked=!WS.ManualBEStopLocked;
   }
}


void SetSoftStopMode()
{
   if(WS.StopMode==None)
      WS.StopMode=SoftBasket;
   else if(WS.StopMode==HardSingle)
      WS.StopMode=None;
   else
      WS.StopMode=None;

   WS.ResetLocks();
      
   SetGlobalVariables();
}


void SetHardStopMode()
{
   if(WS.StopMode==None)
      WS.StopMode=HardSingle;
   else if(WS.StopMode==SoftBasket)
      WS.StopMode=None;
   else
      WS.StopMode=None;

   WS.ResetLocks();
      
   SetGlobalVariables();
}


void SetGlobalVariables()
{
   string varname;
   GlobalVariableSet(appnamespace+"StopMode",WS.StopMode);
   GlobalVariableSet(appnamespace+"peakgain",WS.peakgain);
   GlobalVariableSet(appnamespace+"peakpips",WS.peakpips);
   GlobalVariableSet(appnamespace+"OpenLots",_OpenLots);
   GlobalVariableSet(appnamespace+"StopLossPips",_StopLossPips);
   GlobalVariableSet(appnamespace+"TakeProfitPips",_TakeProfitPips);
   GlobalVariableSet(appnamespace+"currentbasemagicnumber",WS.currentbasemagicnumber);
   varname=appnamespace+"ManualBEStopLocked";
   if(WS.ManualBEStopLocked)
      GlobalVariableSet(varname,0);
   else
      GlobalVariableDel(varname);
   varname=appnamespace+"closebasketatBE";
   if(WS.closebasketatBE)
      GlobalVariableSet(varname,0);
   else
      GlobalVariableDel(varname);

   GlobalVariableSet(appnamespace+"InstrumentSelected",InstrumentSelected);

   GlobalVariableSet(appnamespace+"TradesViewSelected",TradesViewSelected);

   int asize=ArraySize(WS.tradereference);
   for(int i=0; i<asize; i++)
   {
      GlobalVariableSet(appnamespace+"TradeReference.gain"+IntegerToString(WS.tradereference[i].magicnumber),WS.tradereference[i].gain);
      GlobalVariableSet(appnamespace+"TradeReference.stoplosspips"+IntegerToString(WS.tradereference[i].magicnumber),WS.tradereference[i].stoplosspips);
      GlobalVariableSet(appnamespace+"TradeReference.stoplosslevel"+IntegerToString(WS.tradereference[i].magicnumber),WS.tradereference[i].stoplosslevel);
      GlobalVariableSet(appnamespace+"TradeReference.takeprofitpips"+IntegerToString(WS.tradereference[i].magicnumber),WS.tradereference[i].takeprofitpips);
      GlobalVariableSet(appnamespace+"TradeReference.takeprofitlevel"+IntegerToString(WS.tradereference[i].magicnumber),WS.tradereference[i].takeprofitlevel);
   }
}


void GetGlobalVariables()
{
   string varname=appnamespace+"StopMode";
   if(GlobalVariableCheck(varname))
      WS.StopMode=(BEStopModes)GlobalVariableGet(varname);
   varname=appnamespace+"peakgain";
   if(GlobalVariableCheck(varname))
      WS.peakgain=GlobalVariableGet(varname);
   varname=appnamespace+"peakpips";
   if(GlobalVariableCheck(varname))
      WS.peakpips=GlobalVariableGet(varname);
   varname=appnamespace+"OpenLots";
   if(GlobalVariableCheck(varname))
      _OpenLots=GlobalVariableGet(varname);
   varname=appnamespace+"StopLossPips";
   if(GlobalVariableCheck(varname))
      _StopLossPips=GlobalVariableGet(varname);
   varname=appnamespace+"TakeProfitPips";
   if(GlobalVariableCheck(varname))
      _TakeProfitPips=GlobalVariableGet(varname);
   varname=appnamespace+"currentbasemagicnumber";
   if(GlobalVariableCheck(varname))
      WS.currentbasemagicnumber=(int)GlobalVariableGet(varname);
   varname=appnamespace+"ManualBEStopLocked";
   if(GlobalVariableCheck(varname))
      WS.ManualBEStopLocked=true;
   varname=appnamespace+"closebasketatBE";
   if(GlobalVariableCheck(varname))
      WS.closebasketatBE=true;
   varname=appnamespace+"InstrumentSelected";
   if(GlobalVariableCheck(varname))
      InstrumentSelected=(int)GlobalVariableGet(varname);
   varname=appnamespace+"TradesViewSelected";
   if(GlobalVariableCheck(varname))
      TradesViewSelected=(int)GlobalVariableGet(varname);
      
   int varcount=GlobalVariablesTotal();
   for(int i=0; i<varcount; i++)
   {
      string n=GlobalVariableName(i);
      string s;
      long magicnumber;
      int p;

      s=appnamespace+"TradeReference.gain";
      p=StringFind(n,s);
      if(p==0)
      {
         magicnumber=StringToInteger(StringSubstr(n,StringLen(s)));
         UpdateTradeReference(magicnumber,GlobalVariableGet(n));
      }

      s=appnamespace+"TradeReference.stoplosspips";
      p=StringFind(n,s);
      if(p==0)
      {
         magicnumber=StringToInteger(StringSubstr(n,StringLen(s)));
         UpdateTradeReference(magicnumber,NULL,GlobalVariableGet(n));
      }

      s=appnamespace+"TradeReference.stoplosslevel";
      p=StringFind(n,s);
      if(p==0)
      {
         magicnumber=StringToInteger(StringSubstr(n,StringLen(s)));
         UpdateTradeReference(magicnumber,NULL,NULL,NULL,GlobalVariableGet(n));
      }

      s=appnamespace+"TradeReference.takeprofitpips";
      p=StringFind(n,s);
      if(p==0)
      {
         magicnumber=StringToInteger(StringSubstr(n,StringLen(s)));
         UpdateTradeReference(magicnumber,NULL,NULL,GlobalVariableGet(n));
      }

      s=appnamespace+"TradeReference.takeprofitlevel";
      p=StringFind(n,s);
      if(p==0)
      {
         magicnumber=StringToInteger(StringSubstr(n,StringLen(s)));
         UpdateTradeReference(magicnumber,NULL,NULL,NULL,NULL,GlobalVariableGet(n));
      }
   }
}


double GetGlobalReferencesGain()
{
   double gain=0;
   int asize=ArraySize(WS.tradereference);
   for(int i=0; i<asize; i++)
      gain+=WS.tradereference[i].gain;
   return gain;
}


void ClearGlobalReferences()
{
   GlobalVariablesDeleteAll(appnamespace+"TradeReference");
   GlobalVariablesDeleteAll(appnamespace+"currentbasemagicnumber");
}


bool IsOrderToManage()
{
   bool manage=true,
   ismagicnumber=(OrderMagicNumberX()==ManageMagicNumberOnly),
   isinternalmagicnumber=(OrderMagicNumberX()>=basemagicnumber)&&(OrderMagicNumberX()<=basemagicnumber+(hedgeoffsetmagicnumber*100)),
   isordernumber=(OrderTicketX()==ManageOrderNumberOnly);
   
   if((ManageMagicNumberOnly>0&&!ismagicnumber)||(ManageOwnTradesOnly&&ManageMagicNumberOnly==0&&!isinternalmagicnumber))
      manage=false;
   
   if(ManageOrderNumberOnly>0&&!isordernumber)
      manage=false;
   return manage;
}


bool ManageOrders()
{
   int cnt, ordertotal=OrdersTotalX();

   BI.Init();

   for(cnt=0;cnt<ordertotal;cnt++)
   {
      if(OrderSelectX(cnt))
      {
         if(IsOrderToManage())
         {
            double tickvalue=OrderSymbolTickValue();
            if(tickvalue==0)
               return false;
            double gain=OrderProfitNet();
            double gainpips=(gain/OrderLotsX())/tickvalue;

            TypeTradeInfo ti;
            ti.orderindex=cnt;

            BI.managedorders++;
            int pidx=AddPairsInTrades(OrderSymbolX());

            BI.pairsintrades[pidx].gainpips+=gainpips/pipsfactor;

            double BESL=0;
            bool NeedSetSL=false;
            int hedgeordertype=0;
            if(OrderTypeSell())
            {
               ti.type=OP_SELL;
               hedgeordertype=OP_BUY;
               BESL=OrderOpenPriceX()-(_AboveBEPips*SymbolInfoDouble(OrderSymbolX(),SYMBOL_POINT));
               BI.sells++;
               BI.sellvolume+=OrderLotsX();
               BI.pairsintrades[pidx].sellvolume+=OrderLotsX();
               BI.pairsintrades[pidx].sellgain+=gain;
               if(OrderStopLossX()==0||OrderStopLossX()>BESL)
                  NeedSetSL=true;
            }
            if(OrderTypeBuy())
            {
               ti.type=OP_BUY;
               hedgeordertype=OP_SELL;
               BESL=OrderOpenPriceX()+(_AboveBEPips*SymbolInfoDouble(OrderSymbolX(),SYMBOL_POINT));
               BI.buys++;
               BI.buyvolume+=OrderLotsX();
               BI.pairsintrades[pidx].buyvolume+=OrderLotsX();
               BI.pairsintrades[pidx].buygain+=gain;
               if(OrderStopLossX()==0||OrderStopLossX()<BESL)
                  NeedSetSL=true;
            }

            BI.pairsintrades[pidx].gain+=gain;
            if(gain<0&&gain<BI.largestloss)
            {
               BI.largestlossindex=cnt;
               BI.largestloss=gain;
            }
            BI.gain+=gain;

            if(gainpips<0)
            {
               BI.gainpipsminus+=gainpips*OrderLotsX()*tickvalue;
               BI.volumeminus+=OrderLotsX()*tickvalue;
            }
            else
            {
               BI.gainpipsplus+=gainpips*OrderLotsX()*tickvalue;
               BI.volumeplus+=OrderLotsX()*tickvalue;
            }
            
            if(WS.StopMode==HardSingle&&gainpips>=_BreakEvenAfterPips&&NeedSetSL)
               SetOrderSL(BESL);

            ti.volume=OrderLotsX();
            ti.openprice=OrderOpenPriceX();
            ti.points=gainpips;
            ti.commissionpoints=NormalizeDouble((OrderCommissionSwap()/ti.volume)/tickvalue,0);
            ti.gain=gain;
            ti.tickvalue=tickvalue;
            ti.magicnumber=OrderMagicNumberX();
            ti.orderticket=OrderTicketX();
            AddTrade(BI.pairsintrades[pidx],BI.pairsintrades[pidx].tradeinfo,ti);
         }
      }
   }
   return true;
}


void ManageBasket()
{
   if(BI.managedorders==0&&WS.IsOrderPending())
      return;

   if(BI.managedorders==0)
   {
      WS.Reset();
      ClearGlobalReferences();
      
      for(int i=ArraySize(strats)-1; i>=0; i--)
         strats[i].IdleCalculate();

#ifdef __MQL5__
      //#include <TradeManagerEntryTesting1.mqh>
      
      // Dredging Test
      //OpenBuy();
      //OpenSell();
#endif

      return;
   }
   
   bool closeall=false;
   
   WS.globalgain=GetGlobalReferencesGain();

   BI.gainpips=(BI.gainpipsplus+BI.gainpipsminus)/(BI.volumeplus+BI.volumeminus);
   
   BI.gainpipsglobal=0;
   if(BI.gain!=0)
      BI.gainpipsglobal=(BI.gainpips/BI.gain)*WS.globalgain;

   WS.peakpips=MathMax(BI.gainpipsglobal,WS.peakpips);
   
   WS.peakgain=MathMax(WS.globalgain,WS.peakgain);

   int size1=ArraySize(BI.pairsintrades);
   for(int i=0; i<size1; i++)
   {
      int size2=ArraySize(BI.pairsintrades[i].tradeinfo);
      for(int j=0; j<size2; j++)
      {
         TypeTradeInfo ti=BI.pairsintrades[i].tradeinfo[j];
         TypeTradeReference tr=WS.tradereference[TradeReferenceIndex(ti.magicnumber)];

         if(OrderSelectX(ti.orderindex)&&IsAutoTradingEnabled())
         {
         
            double bid=BidX(tr.pair);

            if((tr.takeprofitpips!=DISABLEDPOINTS&&(ti.points-tr.takeprofitpips)>=0)
            ||(tr.takeprofitlevel!=0&&bid!=0&&((ti.type==OP_SELL&&bid<=tr.takeprofitlevel)||(ti.type==OP_BUY&&bid>=tr.takeprofitlevel))))
            {
               if(CloseSelectedOrder())
               {

// EXPERIMENTAL
                  if(Automation==Dredging)
                  {
                     if(j==size2-1||j==size2-2)
                     {
                        OpenBuy(BI.pairsintrades[i].pair);
                        OpenSell(BI.pairsintrades[i].pair);
                     }
                  }


               }
            }

            if((tr.stoplosspips!=DISABLEDPOINTS&&(ti.points+tr.stoplosspips)<=0)
            ||(tr.stoplosslevel!=0&&bid!=0&&((ti.type==OP_SELL&&bid>=tr.stoplosslevel)||(ti.type==OP_BUY&&bid<=tr.stoplosslevel))))
            {
               if(HedgeAtStopLoss)
               {
                  long hedgemagicnumber=GetHedgeMagicNumber(BI.pairsintrades[i].tradeinfo,ti);
                  double hedgevolume=GetHedgeVolume(BI.pairsintrades[i].tradeinfo,ti);
                  if(hedgemagicnumber>-1&&hedgevolume>0)
                  {
                     if(OpenOrder(HedgeType(ti.type),BI.pairsintrades[i].pair+SymbolExtraChars,hedgevolume,hedgemagicnumber))
                     {
                     }
                  }
               }
               else
               {
                  if(CloseSelectedOrder())
                  {
                  }
               }
            }
            
         }
      }
   }

   if(StopLossPercentTradingCapital>0)
   {
      if((WS.globalgain)+((MathMax(AccountBalanceX(),AvailableTradingCapital)/100)*StopLossPercentTradingCapital)<=0)
      {
         if(StopLossPercentTradingCapitalAction==CloseWorstTrade)
         {
            if(OrderSelectX(BI.largestlossindex)&&IsAutoTradingEnabled())
            {
               if(CloseSelectedOrder())
               {
               }
            }
         }
         else if(StopLossPercentTradingCapitalAction==CloseAllTrades)
         {
            closeall=true;
         }
      }
   }

   if(ActivateTrailing&&_StartTrailingPips>0&&BI.gainpipsglobal>=_StartTrailingPips)
      WS.TrailingActivated=true;

   if(TakeProfitPercentTradingCapital>0&&WS.globalgain/(MathMax(AccountBalanceX(),AvailableTradingCapital)/100)>=TakeProfitPercentTradingCapital)
      closeall=true;

   if(WS.TrailingActivated&&WS.globalgain<=GetTrailingLimit())
      closeall=true;
   
   if(WS.closebasketatBE&&WS.globalgain>=0)
      closeall=true;

   if(WS.ManualBEStopLocked&&WS.globalgain<=0)
      closeall=true;
   
   if(WS.StopMode==SoftBasket&&_BreakEvenAfterPips>0&&WS.peakpips>=_BreakEvenAfterPips)
      WS.SoftBEStopLocked=true;   
   
   if(WS.SoftBEStopLocked&&BI.gainpipsglobal<_AboveBEPips)
      closeall=true;

   if(CloseTradesBeforeMidnight)
   {
      MqlDateTime tc;
      TimeCurrent(tc);
      if(tc.hour==23)
         closeall=true;
   }

   if(closeall)
      CloseAllInternal();
      
   if(tradelevelsvisible)
   {
      if(TimeLocal()-WS.tradereference[selectedtradeindex].lastupdate>1)
         ToggleTradeLevels(false);
   }
}


double GetTrailingLimit()
{
   return WS.peakgain*TrailingFactor;
}


void DisplayText()
{
   if(!ShowInfo)
      return;

   DeleteText();

   if(tickchar=="")
      tickchar="-";
   else
      tickchar="";

   int rowindex=0;

   if(!IsAutoTradingEnabled())
   {
      CreateLabel(rowindex,FontSize,TextColorMinus,tickchar+" Autotrading Disabled");
      rowindex++;
   }
   else
   {
      if(TimeLocal()-lasttick>60)
         CreateLabel(rowindex,FontSize,TextColorMinus,tickchar+" No Market Activity");
      else
         CreateLabel(rowindex,FontSize,TextColorPlus,tickchar+" Running");
      rowindex++;
   }
   
   for(int i=ArraySize(strats)-1; i>=0; i--)
   {
      color c=TextColorPlus;

      MqlDateTime tc;
      TimeCurrent(tc);
      if(!_TradingHours[tc.hour]||!_TradingWeekdays[tc.day_of_week])
         c=TextColorMinus;
   
      CreateLabel(rowindex,FontSize,c,strats[i].GetName());
      rowindex++;
   }

   string stopmodetext="";
   if(WS.StopMode==None)
      stopmodetext="No Break Even Mode";
   if(WS.StopMode==HardSingle)
      stopmodetext="Hard Single Break Even Mode";
   if(WS.StopMode==SoftBasket)
      stopmodetext="Soft Basket Break Even Mode";
   CreateLabel(rowindex,FontSize,TextColor,stopmodetext);
   rowindex++;

   if(CloseTradesBeforeMidnight)
   {
      CreateLabel(rowindex,FontSize,TextColor,"Closing all Trades at 23:00");
      rowindex++;
   }

   string moretradingcapital="";
   if(AvailableTradingCapital>AccountBalanceX())
      moretradingcapital=" | "+IntegerToString(AvailableTradingCapital);
   CreateLabel(rowindex,FontSize,TextColor,"Balance: "+DoubleToString(AccountBalanceX(),0)+moretradingcapital);
   rowindex++;
   
   CreateLabel(rowindex,FontSize,TextColor,"Free Margin: "+DoubleToString(AccountFreeMarginX(),1));
   rowindex++;

   CreateLabel(rowindex,FontSize,TextColor,"Leverage: "+IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)));
   rowindex++;

   if(StopLossPercentTradingCapital>0)
   {
      CreateLabel(rowindex,FontSize,TextColor,"General Stop Loss: "+DoubleToString(StopLossPercentTradingCapital,1)+"%");
      rowindex++;
   }

   if(TakeProfitPercentTradingCapital>0)
   {
      CreateLabel(rowindex,FontSize,TextColor,"General Take Profit: "+DoubleToString(TakeProfitPercentTradingCapital,1)+"%");
      rowindex++;
   }

   if(ctrlon)
   {
      CreateLabel(rowindex,FontSize,TextColorInfo,"Open Volume: "+DoubleToString(_OpenLots,2));
      rowindex++;
      
      string instrumenttext="Open all ";
      if(InstrumentSelected==USD)
         instrumenttext+="USD";
      if(InstrumentSelected==EUR)
         instrumenttext+="EUR";
      if(InstrumentSelected==GBP)
         instrumenttext+="GBP";
      if(InstrumentSelected==JPY)
         instrumenttext+="JPY";
      if(InstrumentSelected==CHF)
         instrumenttext+="CHF";
      if(InstrumentSelected==CAD)
         instrumenttext+="CAD";
      if(InstrumentSelected==AUD)
         instrumenttext+="AUD";
      if(InstrumentSelected==NZD)
         instrumenttext+="NZD";
      instrumenttext+=" Pairs";

      if(InstrumentSelected!=CurrentPair)
      {
         CreateLabel(rowindex,FontSize,TextColorInfo,instrumenttext);
         rowindex++;
      }
   }

   double tickvalue=CurrentSymbolTickValue();
   int spreadpoints=(int)MathRound((AskX()-BidX())/Point());
   if((_StopLossPips!=DISABLEDPOINTS&&ctrlon)||tradelevelsvisible)
   {
      color c=TextColorInfo;
      double risk=_StopLossPips*_OpenLots*tickvalue;
      double riskpercent=risk/(AccountBalanceX()/100);
      double atrfactor=_StopLossPips/(ATR()/Point());
      if(tradelevelsvisible)
      {
         c=TextColorInfo;
         risk=0;
         if(WS.tradereference[selectedtradeindex].stoplosspips!=DISABLEDPOINTS)
         {
            risk=WS.tradereference[selectedtradeindex].stoplosspips*WS.tradereference[selectedtradeindex].volume*tickvalue;
            riskpercent=risk/(AccountBalanceX()/100);
            atrfactor=WS.tradereference[selectedtradeindex].stoplosspips/(ATR()/Point());
         }
      }
      if(risk!=0)
      {
         string riskpercenttradingcapital="";
         if(AvailableTradingCapital>AccountBalanceX())
            riskpercenttradingcapital=" | "+DoubleToString(risk/(AvailableTradingCapital/100),2)+"%";
         CreateLabel(rowindex,FontSize,c,"Risk: "+DoubleToString(risk,2)+" | "+DoubleToString(riskpercent,2)+"%"+riskpercenttradingcapital+" | "+DoubleToString(atrfactor*100,0)+"%ATR");
         rowindex++;
      }
   }
   if((_TakeProfitPips!=DISABLEDPOINTS&&ctrlon)||tradelevelsvisible)
   {
      color c=TextColorInfo;
      double reward=_TakeProfitPips*_OpenLots*tickvalue;
      double rewardpercent=reward/(AccountBalanceX()/100);
      if(tradelevelsvisible)
      {
         c=TextColorInfo;
         reward=0;
         if(WS.tradereference[selectedtradeindex].takeprofitpips!=DISABLEDPOINTS)
         {
            reward=WS.tradereference[selectedtradeindex].takeprofitpips*WS.tradereference[selectedtradeindex].volume*tickvalue;
            rewardpercent=reward/(AccountBalanceX()/100);
         }
      }
      if(reward!=0)
      {
         string rewardpercenttradingcapital="";
         if(AvailableTradingCapital>AccountBalanceX())
            rewardpercenttradingcapital=" | "+DoubleToString(reward/(AvailableTradingCapital/100),2)+"%";
         CreateLabel(rowindex,FontSize,c,"Reward: "+DoubleToString(reward,2)+" | "+DoubleToString(rewardpercent,2)+"%"+rewardpercenttradingcapital);
         rowindex++;
      }
   }

   if(BI.managedorders!=0)
   {
      if(BI.buyvolume>0)
      {      
         CreateLabel(rowindex,FontSize,TextColor,IntegerToString(BI.buys)+" Buy: "+DoubleToString(BI.buyvolume,2));
         rowindex++;
      }
   
      if(BI.sellvolume>0)
      {
         CreateLabel(rowindex,FontSize,TextColor,IntegerToString(BI.sells)+" Sell: "+DoubleToString(BI.sellvolume,2));
         rowindex++;
      }
   
      CreateLabel(rowindex,FontSize,TextColor,"Pips: "+DoubleToString(BI.gainpipsglobal/pipsfactor,1));
      rowindex++;
   
      string performancepercenttradingcapital="";
      if(AvailableTradingCapital>AccountBalanceX())
         performancepercenttradingcapital=" | "+DoubleToString(WS.globalgain/(AvailableTradingCapital/100),2)+"%";
      CreateLabel(rowindex,FontSize,TextColor,"Performance: "+DoubleToString(WS.globalgain/(AccountBalanceX()/100),2)+"%"+performancepercenttradingcapital);
      rowindex++;

      if(!WS.TrailingActivated&&!WS.ManualBEStopLocked&&!WS.SoftBEStopLocked)
      {
         double totalrisk=0;
         int asize=ArraySize(WS.tradereference);
         for(int i=0; i<asize; i++)
         {
            if(TimeLocal()-WS.tradereference[i].lastupdate<2)
            {
               if(WS.tradereference[i].stoplosspips!=DISABLEDPOINTS)
                  totalrisk+=WS.tradereference[i].stoplosspips*WS.tradereference[i].volume*WS.tradereference[i].tickvalue;
               else
               {
                  totalrisk=DBL_MAX;
                  break;
               }
            }
         }
         if(totalrisk!=DBL_MAX)
            totalrisk-=(WS.globalgain-BI.gain);

         if(StopLossPercentTradingCapital>0)
         {
            double ptcrisk=(MathMax(AccountBalanceX(),AvailableTradingCapital)/100)*StopLossPercentTradingCapital;
            totalrisk=MathMin(ptcrisk,totalrisk);
         }

         color c=TextColorMinus;
         string risktext="Risk Unlimited";
         if(totalrisk!=DBL_MAX)
         {
            risktext="At Risk: ";
            if(totalrisk<=0)
            {
               totalrisk=0-totalrisk;
               c=TextColorPlus;
               risktext="Locked: ";
            }
            string riskpercenttradingcapital="";
            if(AvailableTradingCapital>AccountBalanceX())
               riskpercenttradingcapital=" | "+DoubleToString(totalrisk/(AvailableTradingCapital/100),2)+"%";
            risktext+=DoubleToString(totalrisk,2)+" | "+DoubleToString(totalrisk/(AccountBalanceX()/100),2)+"%"+riskpercenttradingcapital;
         }
         CreateLabel(rowindex,FontSize,c,risktext);
         rowindex++;
      }
   
      if(WS.closebasketatBE)
      {
         CreateLabel(rowindex,FontSize,TextColorMinus,"Close Basket at Break Even");
         rowindex++;
      }
   
      if(WS.TrailingActivated)
      {
         CreateLabel(rowindex,FontSize,TextColorPlus,"Trailing Activ, Current Limit: "+DoubleToString(GetTrailingLimit(),2));
         rowindex++;
      }
      else
      {
         if(WS.ManualBEStopLocked)
         {
            CreateLabel(rowindex,FontSize,TextColorPlus,"Manual Break Even Stop Locked");
            rowindex++;
         }
      
         if(WS.SoftBEStopLocked)
         {
            CreateLabel(rowindex,FontSize,TextColorPlus,"Basket Break Even Stop Locked");
            rowindex++;
         }
      }

      color gaincolor=TextColorPlus;
      double gain=BI.gain;
      if(tradelevelsvisible)
         gain=WS.tradereference[selectedtradeindex].gain;
      if(gain<0)
         gaincolor=TextColorMinus;
      CreateLabel(rowindex,(int)MathFloor(FontSize*2.3),gaincolor,DoubleToString(gain,2));
      rowindex++;
      rowindex++;
      
      double globalgain=NormalizeDouble(WS.globalgain,2);
      if(globalgain!=NormalizeDouble(BI.gain,2))
      {
         color closedlossescolor=TextColorPlus;
         double gaintotal=globalgain;
         if(gaintotal<0)
            closedlossescolor=TextColorMinus;
         CreateLabel(rowindex,FontSize,closedlossescolor,DoubleToString(gaintotal,2));
         rowindex++;
      }
   
      int asize=ArraySize(BI.pairsintrades);

      if(TradesViewSelected==ByPairs)
      {
         if(asize>0)
         {
            CreateLabel(rowindex,FontSize,TextColor,"Sells","1",65);
            CreateLabel(rowindex,FontSize,TextColor,"Buys","2",140);
            rowindex++;
         }

         for(int i=0; i<asize; i++)
         {
            color paircolor=TextColor;
            if(BI.pairsintrades[i].pair+SymbolExtraChars==Symbol())
               paircolor=TextColorBold;
            CreateLabel(rowindex,FontSize,paircolor,BI.pairsintrades[i].pair,"-TMSymbolButton",0,"");
   
            int hshift=60;
            if(BI.pairsintrades[i].buyvolume>0)
            {
               color pcolor=TextColorPlus;
               if(BI.pairsintrades[i].buygain<0)
                  pcolor=TextColorMinus;
               CreateLabel(rowindex,FontSize,pcolor,DoubleToString(BI.pairsintrades[i].buyvolume,2)+" "+DoubleToString(BI.pairsintrades[i].buygain,2),"-TMCC-Buys-"+BI.pairsintrades[i].pair,140,"Click to Close");
               hshift+=90;
            }
            if(BI.pairsintrades[i].sellvolume>0)
            {
               color pcolor=TextColorPlus;
               if(BI.pairsintrades[i].sellgain<0)
                  pcolor=TextColorMinus;
               CreateLabel(rowindex,FontSize,pcolor,DoubleToString(BI.pairsintrades[i].sellvolume,2)+" "+DoubleToString(BI.pairsintrades[i].sellgain,2),"-TMCC-Sells"+BI.pairsintrades[i].pair,65,"Click to Close");
            }
            rowindex++;
         }
      }

      if(TradesViewSelected==ByCurrencies)
      {
         TypeCurrenciesTradesInfo ti[8];
         string currencies[8]={"USD","EUR","GBP","JPY","CHF","CAD","AUD","NZD"};
         for(int i=0; i<asize; i++)
         {
            int basepos=-1, quotepos=-1;
            for(int p=0; p<8; p++)
            {
               int pos=StringFind(BI.pairsintrades[i].pair,currencies[p]);
               if(pos==0)
                  basepos=p;
               if(pos==3)
                  quotepos=p;
               if(basepos>-1&&quotepos>-1)
                  break;
            }
            if(basepos>-1)
            {
               ti[basepos].buygain+=BI.pairsintrades[i].buygain;
               ti[basepos].buyvolume+=BI.pairsintrades[i].buyvolume;
               ti[basepos].sellgain+=BI.pairsintrades[i].sellgain;
               ti[basepos].sellvolume+=BI.pairsintrades[i].sellvolume;
            }
            if(quotepos>-1)
            {
               ti[quotepos].buygain+=BI.pairsintrades[i].sellgain;
               ti[quotepos].buyvolume+=BI.pairsintrades[i].sellvolume;
               ti[quotepos].sellgain+=BI.pairsintrades[i].buygain;
               ti[quotepos].sellvolume+=BI.pairsintrades[i].buyvolume;
            }
         }

         bool headercreated=false;
         for(int i=0; i<8; i++)
         {
            if(ti[i].buyvolume>0||ti[i].sellvolume>0)
            {
               if(!headercreated)
               {
                  CreateLabel(rowindex,FontSize,TextColor,"Sells","1",35);
                  CreateLabel(rowindex,FontSize,TextColor,"Buys","2",110);
                  headercreated=true;
                  rowindex++;
               }

               CreateLabel(rowindex,FontSize,TextColor,currencies[i],"-TMCurrency",0,"");
               if(ti[i].buyvolume>0)
               {
                  color pcolor=TextColorPlus;
                  if(ti[i].buygain<0)
                     pcolor=TextColorMinus;
                  CreateLabel(rowindex,FontSize,pcolor,DoubleToString(ti[i].buyvolume,2)+" "+DoubleToString(ti[i].buygain,2),"-TMCC-Buys-"+currencies[i],110,"Click to Close");
               }
               if(ti[i].sellvolume>0)
               {
                  color pcolor=TextColorPlus;
                  if(ti[i].sellgain<0)
                     pcolor=TextColorMinus;
                  CreateLabel(rowindex,FontSize,pcolor,DoubleToString(ti[i].sellvolume,2)+" "+DoubleToString(ti[i].sellgain,2),"-TMCC-Sells"+currencies[i],35,"Click to Close");
               }
               rowindex++;
            }
         }
      }
   }

   if(TimeLocal()-lasterrortime<3)
   {
      CreateLabel(rowindex,FontSize,TextColorMinus,lasterrorstring);
      rowindex++;
   }
   ChartRedraw();
}


void CreateLabel(int RI, int fontsize, color c, string text, string group="", int xshift=0, string tooltip="")
{
   string objname=appnamespace+"Text"+IntegerToString(RI+1)+group;
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,5+xshift);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,20+(TextGap*RI));
   ObjectSetInteger(0,objname,OBJPROP_COLOR,c);
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
   ObjectSetString(0,objname,OBJPROP_TEXT,text);
   if(StringLen(tooltip)>0)
      ObjectSetString(0,objname,OBJPROP_TOOLTIP,tooltip);
   TextObjects.AddObject(objname);
}


void NextTradeLevels(bool backward=false)
{
   int indexes[];
   int count=0;
   int currentpositionindex=-1;
   int asize=ArraySize(WS.tradereference);
   for(int i=0; i<asize; i++)
   {
      if(WS.tradereference[i].pair+SymbolExtraChars==Symbol() && TimeLocal()-WS.tradereference[i].lastupdate<2)
      {
         ArrayResize(indexes,count+1);
         indexes[count]=i;
         if(selectedtradeindex==i)
            currentpositionindex=count;
         count++;
      }
   }
   if(count>1)
   {
      DeleteSelectedTradeLevels();
      if(backward)
         currentpositionindex--;
      else
         currentpositionindex++;
      if(currentpositionindex>(count-1))
         currentpositionindex=0;
      if(currentpositionindex<0)
         currentpositionindex=(count-1);
      selectedtradeindex=indexes[currentpositionindex];
      DrawSelectedTradeLevels();
   }
}


void ToggleTradeLevels(bool disable=false)
{
   selectedtradeindex=-1;

   if(!tradelevelsvisible && !disable)
   {
      ToggleCtrl(true);

      int asize=ArraySize(WS.tradereference);
      for(int i=0; i<asize; i++)
      {
         if(WS.tradereference[i].pair+SymbolExtraChars==Symbol() && TimeLocal()-WS.tradereference[i].lastupdate<2)
         {
            selectedtradeindex=i;
            break;
         }
      }
      if(selectedtradeindex>-1)
      {
         tradelevelsvisible=true;
         DrawSelectedTradeLevels();
      }
   }
   else if(tradelevelsvisible)
   {
      DeleteSelectedTradeLevels();
      tradelevelsvisible=false;
   }
}


void DeleteSelectedTradeLevels()
{
   if(DrawLevelsAllCharts)
   {
      long chartid=ChartFirst();
      while(chartid>-1)
      {
         if(ChartSymbol(chartid)==Symbol())
            ObjectsDeleteAll(chartid,appnamespace+"TradeLevel");
   
         chartid=ChartNext(chartid);
      }
   }
   else
      ObjectsDeleteAll(0,appnamespace+"TradeLevel");
}


void DrawSelectedTradeLevels()
{
   if(DrawLevelsAllCharts)
   {
      long chartid=ChartFirst();
      while(chartid>-1)
      {
         if(ChartSymbol(chartid)==Symbol())
            DrawTradeLevels(chartid,selectedtradeindex);
   
         chartid=ChartNext(chartid);
      }
   }
   else
      DrawTradeLevels(0,selectedtradeindex);
}


void DrawTradeLevels(long chartid, int i)
{
   CreateLevel(chartid,appnamespace+"TradeLevelOpen"+IntegerToString(i),DodgerBlue,WS.tradereference[i].openprice);

   double stopprice=0;
   double commissionpoints=MathAbs(WS.tradereference[i].commissionpoints);
   if(WS.tradereference[i].stoplosspips!=DISABLEDPOINTS)
   {
      if(WS.tradereference[i].type==OP_BUY)
         stopprice=WS.tradereference[i].openprice-((WS.tradereference[i].stoplosspips-commissionpoints)*Point());
      if(WS.tradereference[i].type==OP_SELL)
         stopprice=WS.tradereference[i].openprice+((WS.tradereference[i].stoplosspips-commissionpoints)*Point());
      CreateLevel(chartid,appnamespace+"TradeLevelStop"+IntegerToString(i),DeepPink,stopprice);
   }
   if(WS.tradereference[i].takeprofitpips!=DISABLEDPOINTS)
   {
      double takeprice=0;
      if(WS.tradereference[i].type==OP_BUY)
         takeprice=WS.tradereference[i].openprice+((WS.tradereference[i].takeprofitpips+commissionpoints)*Point());
      if(WS.tradereference[i].type==OP_SELL)
         takeprice=WS.tradereference[i].openprice-((WS.tradereference[i].takeprofitpips+commissionpoints)*Point());
      CreateLevel(chartid,appnamespace+"TradeLevelTake"+IntegerToString(i),SeaGreen,takeprice);
   }

   ChartRedraw(chartid);
}


void ToggleCtrl(bool disable=false)
{
   if(!ctrlon && !disable)
   {
      ToggleTradeLevels(true);
      DrawLevels();
      //DisplayLegend();
      ctrlon=true;
   }
   else if(ctrlon)
   {
      DeleteLevels();
      //DeleteLegend();
      ctrlon=false;
   }
}


void DrawLevels()
{
   if(DrawLevelsAllCharts)
   {
      long chartid=ChartFirst();
      while(chartid>-1)
      {
         if(ChartSymbol(chartid)==Symbol())
            DrawLevels(chartid);
         chartid=ChartNext(chartid);
      }
   }
   else
      DrawLevels(0);
}


void DrawLevels(long chartid)
{
   //CreateLevel(chartid,appnamespace+"Level1",MediumSeaGreen,Bid-(AboveBEPips*Point));
   //CreateLevel(chartid,appnamespace+"Level2",DeepPink,Bid-(BreakEvenAfterPips*Point));
   //CreateLevel(chartid,appnamespace+"Level3",MediumSeaGreen,Ask+(AboveBEPips*Point));
   //CreateLevel(chartid,appnamespace+"Level4",DeepPink,Ask+(BreakEvenAfterPips*Point));

   int cp=SymbolCommissionPoints();

   if(_StopLossPips!=DISABLEDPOINTS)
   {
      CreateLevel(chartid,appnamespace+"Level1",DeepPink,BidX()+((_StopLossPips-cp)*Point()));
      CreateLevel(chartid,appnamespace+"Level2",DeepPink,AskX()-((_StopLossPips-cp)*Point()));
   }
   if(_TakeProfitPips!=DISABLEDPOINTS)
   {
      CreateLevel(chartid,appnamespace+"Level3",SeaGreen,BidX()+((_TakeProfitPips+cp)*Point()));
      CreateLevel(chartid,appnamespace+"Level4",SeaGreen,AskX()-((_TakeProfitPips+cp)*Point()));
   }

   CreateRectangle(chartid,appnamespace+"Rectangle10",WhiteSmoke,AskX()+((_BreakEvenAfterPips+cp)*Point()),BidX()-((_BreakEvenAfterPips+cp)*Point()));
   CreateRectangle(chartid,appnamespace+"Rectangle11",WhiteSmoke,AskX()+((_AboveBEPips+cp)*Point()),BidX()-((_AboveBEPips+cp)*Point()));

   ChartRedraw(chartid);
}


void CreateLevel(long chartid, string objname, color c, double price, int width=2)
{
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_HLINE,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_WIDTH,width);
      ObjectSetInteger(chartid,objname,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,price);
}


void CreateRectangle(long chartid, string objname, color c, double price1, double price2)
{
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_RECTANGLE,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_FILL,true);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_BGCOLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,0,price1);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,0,TimeCurrent()-4000000);
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,1,price2);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,1,TimeCurrent());
}


void DisplayLegend()
{
   CreateLegend(appnamespace+"Legend1",5+(int)MathFloor(TextGap*2.4),"Hotkeys: Press Ctrl plus");
   CreateLegend(appnamespace+"Legend2",5+(int)MathFloor(TextGap*1.6),"1 Open Buy | 3 Open Sell | 0 Close All");
   CreateLegend(appnamespace+"Legend3",5+(int)MathFloor(TextGap*0.8),"5 Hard SL | 6 Soft SL | 8 Close at BE");
   CreateLegend(appnamespace+"Legend4",5+(int)MathFloor(TextGap*0),"; Decrease Volume | : Increase Volume");
}


void CreateLegend(string objname, int y, string text)
{
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,TextColor);
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,(int)MathFloor(FontSize*0.8));
   ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
   ObjectSetString(0,objname,OBJPROP_TEXT,text);
}


void DeleteLegend()
{
   ObjectsDeleteAll(0,appnamespace+"Legend");
}


void DeleteLevels()
{
   if(DrawLevelsAllCharts)
   {
      long chartid=ChartFirst();
      while(chartid>-1)
      {
         if(ChartSymbol(chartid)==Symbol())
         {
            ObjectsDeleteAll(chartid,appnamespace+"Level");
            ObjectsDeleteAll(chartid,appnamespace+"Rectangle");
            ChartRedraw(chartid);
         }
         chartid=ChartNext(chartid);
      }
   }
   else
      ObjectsDeleteAll(0,appnamespace+"Level");
}


void DeleteText()
{
   //ObjectsDeleteAll(0,appnamespace+"Text");
   // Workaround: We move objects out of view, because if we delete it, click events can get lost
   TextObjects.HideAll();
}


void DeleteAllObjects()
{
   ObjectsDeleteAll(0,appnamespace);
}


long GetHedgeLevel(long mn)
{
   long t1=mn-magicnumberfloor;
   return (long)MathFloor(t1/hedgeoffsetmagicnumber);
}


long GetMagicNumberFraction(long mn)
{
   long t1=mn-magicnumberfloor;
   long t2=(long)MathFloor(t1/hedgeoffsetmagicnumber);
   long t3=t1-(hedgeoffsetmagicnumber*t2);
   if(t3<0)
      t3=0;
   return t3;
}


double GetHedgeVolume(TypeTradeInfo& tradeinfo[], TypeTradeInfo& tiin)
{
   double ret=0;
   long mn=GetMagicNumberFraction(tiin.magicnumber);
   double sells=0, buys=0, factor=HedgeVolumeFactor;
   long hedgelevel=GetHedgeLevel(tiin.magicnumber);
   if(hedgelevel>=(HedgeFlatAtLevel-1))
      factor=1;
   int size=ArraySize(tradeinfo);
   for(int i=0; i<size; i++)
   {
      if(GetMagicNumberFraction(tradeinfo[i].magicnumber)==mn)
      {
         if(tradeinfo[i].type==OP_BUY)
            buys+=tradeinfo[i].volume;
         if(tradeinfo[i].type==OP_SELL)
            sells+=tradeinfo[i].volume;
      }
   }
   if(tiin.type==OP_BUY)
      ret=(buys*factor)-sells;
   if(tiin.type==OP_SELL)
      ret=(sells*factor)-buys;
   return NormalizeDouble(ret,2);
}


long GetHedgeMagicNumber(TypeTradeInfo& tradeinfo[], TypeTradeInfo& tiin)
{
   long r=tiin.magicnumber+hedgeoffsetmagicnumber;
   if(TradeReferenceIndex(r)>-1)
      r=-1;
   return r;
}


int HedgeType(int type)
{
   if(type==OP_BUY)
      return OP_SELL;
   if(type==OP_SELL)
      return OP_BUY;
   return -1;
}


bool OpenOrder(int type, string symbol=NULL, double volume=NULL, long magicnumber=NULL)
{
   if(type==OP_BUY)
      return OpenBuy(symbol,volume,magicnumber);
   if(type==OP_SELL)
      return OpenSell(symbol,volume,magicnumber);
   return false;
}


bool OpenBuy(string symbol=NULL, double volume=NULL, long magicnumber=NULL, double sl=NULL, double tp=NULL, double sll=NULL, double tpl=NULL)
{
   double v=_OpenLots;
   if(volume!=NULL)
      v=volume;
   long m=WS.currentbasemagicnumber;
   if(magicnumber!=NULL)
      m=magicnumber;
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
   string c=appnamespace+IntegerToString(m);
   WS.lastorderexecution=TimeLocal();
#ifdef __MQL4__
   int ret=OrderSend(s,OP_BUY,v,AskX(s),5,0,0,c,m);
   if(ret>-1)
      NewTradeReference(m,true,sl,tp,sll,tpl);
   if(ret>-1&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastError(ret);
   return (ret>-1);
#endif
#ifdef __MQL5__
   CTrade trade;
   trade.SetExpertMagicNumber(m);
   //bool ret=trade.PositionOpen(s,ORDER_TYPE_BUY,v,AskX(s),NULL,NULL,c);
   bool ret=trade.PositionOpen(s,ORDER_TYPE_BUY,v,0,NULL,NULL,c);
   if(ret)
      NewTradeReference(m,true,sl,tp,sll,tpl);
   if(ret&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastErrorBool(ret);
   return ret;
#endif
}


bool OpenSell(string symbol=NULL, double volume=NULL, long magicnumber=NULL, double sl=NULL, double tp=NULL, double sll=NULL, double tpl=NULL)
{
   double v=_OpenLots;
   if(volume!=NULL)
      v=volume;
   long m=WS.currentbasemagicnumber;
   if(magicnumber!=NULL)
      m=magicnumber;
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
   string c=appnamespace+IntegerToString(m);
   WS.lastorderexecution=TimeLocal();
#ifdef __MQL4__
   int ret=OrderSend(s,OP_SELL,v,BidX(s),5,0,0,c,m);
   if(ret>-1)
      NewTradeReference(m,true,sl,tp,sll,tpl);
   if(ret>-1&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastError(ret);
   return (ret>-1);
#endif
#ifdef __MQL5__
   CTrade trade;
   trade.SetExpertMagicNumber(m);
   //bool ret=trade.PositionOpen(s,ORDER_TYPE_SELL,v,BidX(s),NULL,NULL,c);
   bool ret=trade.PositionOpen(s,ORDER_TYPE_SELL,v,0,NULL,NULL,c);
   if(ret)
      NewTradeReference(m,true,sl,tp,sll,tpl);
   if(ret&&magicnumber==NULL)
      WS.currentbasemagicnumber++;
   SetLastErrorBool(ret);
   return ret;
#endif
}


int NewTradeReference(long magicnumber, bool InitWithCurrentSettings, double sl=NULL, double tp=NULL, double sll=NULL, double tpl=NULL)
{
   int asize=ArraySize(WS.tradereference);
   ArrayResize(WS.tradereference,asize+1);
   WS.tradereference[asize].magicnumber=magicnumber;
   if(InitWithCurrentSettings)
   {
      WS.tradereference[asize].stoplosspips=_StopLossPips;
      WS.tradereference[asize].takeprofitpips=_TakeProfitPips;
   }
   if(sl!=NULL)
      WS.tradereference[asize].stoplosspips=sl;
   if(sll!=NULL)
      WS.tradereference[asize].stoplosslevel=sll;
   if(tp!=NULL)
      WS.tradereference[asize].takeprofitpips=tp;
   if(tpl!=NULL)
      WS.tradereference[asize].takeprofitlevel=tpl;
   return asize;
}


void UpdateTradeReference(TypePairsTradesInfo& piti, TypeTradeInfo& tiin)
{
   int index=TradeReferenceIndex(tiin.magicnumber);
   if(index==-1)
      index=NewTradeReference(tiin.magicnumber,false);
   WS.tradereference[index].gain=tiin.gain;
   WS.tradereference[index].tickvalue=tiin.tickvalue;
   WS.tradereference[index].points=tiin.points;
   WS.tradereference[index].openprice=tiin.openprice;
   WS.tradereference[index].pair=piti.pair;
   WS.tradereference[index].type=tiin.type;
   WS.tradereference[index].volume=tiin.volume;
   WS.tradereference[index].commissionpoints=tiin.commissionpoints;
   WS.tradereference[index].lastupdate=TimeLocal();
}


void UpdateTradeReference(long magicnumber, double gain=NULL, double stoplosspips=NULL, double takeprofitpips=NULL, double stoplosslevel=NULL, double takeprofitlevel=NULL)
{
   int index=TradeReferenceIndex(magicnumber);
   if(index==-1)
      index=NewTradeReference(magicnumber,false);
   if(gain!=NULL)
      WS.tradereference[index].gain=gain;
   if(stoplosspips!=NULL)
      WS.tradereference[index].stoplosspips=stoplosspips;
   if(stoplosslevel!=NULL)
      WS.tradereference[index].stoplosslevel=stoplosslevel;
   if(takeprofitpips!=NULL)
      WS.tradereference[index].takeprofitpips=takeprofitpips;
   if(takeprofitlevel!=NULL)
      WS.tradereference[index].takeprofitlevel=takeprofitlevel;
}


int TradeReferenceIndex(long magicnumber)
{
   int asize=ArraySize(WS.tradereference);
   int index=-1;
   for(int i=0; i<asize; i++)
   {
      if(WS.tradereference[i].magicnumber==magicnumber)
      {
         index=i;
         break;
      }
   }
   return index;
}


void AddTrade(TypePairsTradesInfo& piti, TypeTradeInfo& ti[], TypeTradeInfo& tiin)
{
   UpdateTradeReference(piti,tiin);

   int asize=ArraySize(ti);
   ArrayResize(ti,asize+1);
   ti[asize].orderindex=tiin.orderindex;
   ti[asize].type=tiin.type;
   ti[asize].volume=tiin.volume;
   ti[asize].openprice=tiin.openprice;
   ti[asize].points=tiin.points;
   ti[asize].gain=tiin.gain;
   ti[asize].tickvalue=tiin.tickvalue;
   ti[asize].magicnumber=tiin.magicnumber;
   ti[asize].orderticket=tiin.orderticket;
}


int AddPairsInTrades(string tradedsymbol)
{
   int asize=ArraySize(BI.pairsintrades), idx=-1;
   string symbol=StringSubstr(tradedsymbol,0,6);
   bool found=false;
   for(int i=0; i<asize; i++)
   {
      if(BI.pairsintrades[i].pair==symbol)
      {
         found=true;
         idx=i;
         break;
      }
   }
   if(!found)
   {
      ArrayResize(BI.pairsintrades,asize+1);
      BI.pairsintrades[asize].pair=symbol;
      idx=asize;
   }
   return idx;
}


void WriteToClose()
{
#ifdef __MQL5__
   if(istesting)
   {
      int total=OrdersTotalX();
      int cnt=0;
      for(cnt=total-1;cnt>=0;cnt--)
      {
         if(OrderSelectX(cnt))
         {
            if(IsOrderToManage())
            {
               datetime os=(datetime)PositionGetInteger(POSITION_TIME);
               MqlDateTime dt;
               TimeToStruct(os,dt);
               if(dt.min==1)
               {
                  string wstr="";
                  wstr+=PositionGetString(POSITION_SYMBOL);
                  wstr+=" ";
                  wstr+=IntegerToString(dt.min);
                  wstr+=" ";
                  wstr+=DoubleToString(OrderOpenPriceX(),5);
                  int file_handle=FileOpen("Order-Log.txt",FILE_WRITE|FILE_READ|FILE_TXT);
                  FileSeek(file_handle,0,SEEK_END);
                  FileWriteString(file_handle,wstr+"\r\n");
                  FileClose(file_handle);
               }            
            }
         }
      }
   }
#endif
}


void CloseAllInternal(string filter="")
{
   bool closeall=StringLen(filter)==0;
   bool buys=StringFind(filter,"Buys")==0;
   string asset="";
   if(!closeall)
      asset=StringSubstr(filter,5);

   int total=OrdersTotalX();
   int cnt=0, delcnt=0;
#ifdef __MQL4__
   RefreshRates();
#endif
   for(cnt=total-1;cnt>=0;cnt--)
   {
      if(OrderSelectX(cnt))
         if(IsOrderToManage())
            if(closeall 
                  || (((OrderTypeBuy()&&buys) || (!OrderTypeBuy()&&!buys)) && OrderSymbolX()==asset) 
                  || (((OrderTypeBuy()&&buys) || (!OrderTypeBuy()&&!buys)) && StringFind(OrderSymbolX(),asset)==0 ) 
                  || (((OrderTypeBuy()&&!buys) || (!OrderTypeBuy()&&buys)) && StringFind(OrderSymbolX(),asset)==3 ) 
               )
               if(CloseSelectedOrder())
                  delcnt++;
   }
   if(delcnt>0)
      DeleteText();
}


bool CloseSelectedOrder()
{
   bool ret;
#ifdef __MQL4__
   if(OrderType()==OP_BUY)
      ret=OrderClose(OrderTicketX(),OrderLotsX(),MarketInfo(OrderSymbolX(),MODE_BID),5);
   if(OrderType()==OP_SELL) 
      ret=OrderClose(OrderTicketX(),OrderLotsX(),MarketInfo(OrderSymbolX(),MODE_ASK),5);
   if(OrderType()>OP_SELL)
      ret=OrderDelete(OrderTicketX());
   SetLastErrorBool(ret);
#endif
#ifdef __MQL5__
   CTrade trade;
   ret=trade.PositionClose(OrderTicketX());
   SetLastErrorBool(ret);
#endif
   return ret;
}


bool IsAutoTradingEnabled()
{
   return AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)
         &&AccountInfoInteger(ACCOUNT_TRADE_EXPERT)
         &&TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)
         &&MQLInfoInteger(MQL_TRADE_ALLOWED);
}


int ExtendedRepeatingFactor()
{
   int factor=1;
   if(GetTickCount()-repeatlasttick<=200)
      repeatcount++;
   else
      repeatcount=0;
   factor=1+(int)MathFloor(repeatcount/4);
   repeatlasttick=GetTickCount();
   return factor;
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      //Print("CHARTEVENT_OBJECT_CLICK "+sparam);

      if(StringFind(sparam,"-TMSymbolButton")>-1)
         SwitchSymbol(ObjectGetString(0,sparam,OBJPROP_TEXT));

      if(ctrlon)
      {
         int f1=StringFind(sparam,"-TMCC-");
         if(f1>-1)
            WS.closecommands.Add(StringSubstr(sparam,f1+6));
      }
   }
   
   if(id==CHARTEVENT_KEYDOWN)
   {
      //Print(lparam);

      if(lparam==17)
         ToggleCtrl();

      //if(TimeLocal()-lastctrl<2)
      if(ctrlon)
      {
         double margin=(2*pipsfactor)+(int)MathRound((AskX()-BidX())/Point());

         //lastctrl=TimeLocal();

         if (lparam == 49)
         {
            if(InstrumentSelected==CurrentPair)
               OpenBuy();
            if(InstrumentSelected==USD)
            {
               OpenSell("EURUSD");
               OpenSell("GBPUSD");
               OpenBuy("USDJPY");
               OpenBuy("USDCHF");
               OpenBuy("USDCAD");
               OpenSell("AUDUSD");
               OpenSell("NZDUSD");
            }
            if(InstrumentSelected==EUR)
            {
               OpenBuy("EURUSD");
               OpenBuy("EURGBP");
               OpenBuy("EURJPY");
               OpenBuy("EURCHF");
               OpenBuy("EURCAD");
               OpenBuy("EURAUD");
               OpenBuy("EURNZD");
            }
            if(InstrumentSelected==GBP)
            {
               OpenBuy("GBPUSD");
               OpenSell("EURGBP");
               OpenBuy("GBPJPY");
               OpenBuy("GBPCHF");
               OpenBuy("GBPCAD");
               OpenBuy("GBPAUD");
               OpenBuy("GBPNZD");
            }
            if(InstrumentSelected==JPY)
            {
               OpenSell("USDJPY");
               OpenSell("EURJPY");
               OpenSell("GBPJPY");
               OpenSell("CHFJPY");
               OpenSell("CADJPY");
               OpenSell("AUDJPY");
               OpenSell("NZDJPY");
            }
            if(InstrumentSelected==CHF)
            {
               OpenSell("USDCHF");
               OpenSell("EURCHF");
               OpenSell("GBPCHF");
               OpenBuy("CHFJPY");
               OpenSell("CADCHF");
               OpenSell("AUDCHF");
               OpenSell("NZDCHF");
            }
            if(InstrumentSelected==CAD)
            {
               OpenSell("USDCAD");
               OpenSell("EURCAD");
               OpenSell("GBPCAD");
               OpenBuy("CADJPY");
               OpenBuy("CADCHF");
               OpenSell("AUDCAD");
               OpenSell("NZDCAD");
            }
            if(InstrumentSelected==AUD)
            {
               OpenBuy("AUDUSD");
               OpenSell("EURAUD");
               OpenSell("GBPAUD");
               OpenBuy("AUDJPY");
               OpenBuy("AUDCHF");
               OpenBuy("AUDCAD");
               OpenBuy("AUDNZD");
            }
            if(InstrumentSelected==NZD)
            {
               OpenBuy("NZDUSD");
               OpenSell("EURNZD");
               OpenSell("GBPNZD");
               OpenBuy("NZDJPY");
               OpenBuy("NZDCHF");
               OpenBuy("NZDCAD");
               OpenSell("AUDNZD");
            }
         }
         if (lparam == 51)
         {
            if(InstrumentSelected==CurrentPair)
               OpenSell();
            if(InstrumentSelected==USD)
            {
               OpenBuy("EURUSD");
               OpenBuy("GBPUSD");
               OpenSell("USDJPY");
               OpenSell("USDCHF");
               OpenSell("USDCAD");
               OpenBuy("AUDUSD");
               OpenBuy("NZDUSD");
            }
            if(InstrumentSelected==EUR)
            {
               OpenSell("EURUSD");
               OpenSell("EURGBP");
               OpenSell("EURJPY");
               OpenSell("EURCHF");
               OpenSell("EURCAD");
               OpenSell("EURAUD");
               OpenSell("EURNZD");
            }
            if(InstrumentSelected==GBP)
            {
               OpenSell("GBPUSD");
               OpenBuy("EURGBP");
               OpenSell("GBPJPY");
               OpenSell("GBPCHF");
               OpenSell("GBPCAD");
               OpenSell("GBPAUD");
               OpenSell("GBPNZD");
            }
            if(InstrumentSelected==JPY)
            {
               OpenBuy("USDJPY");
               OpenBuy("EURJPY");
               OpenBuy("GBPJPY");
               OpenBuy("CHFJPY");
               OpenBuy("CADJPY");
               OpenBuy("AUDJPY");
               OpenBuy("NZDJPY");
            }
            if(InstrumentSelected==CHF)
            {
               OpenBuy("USDCHF");
               OpenBuy("EURCHF");
               OpenBuy("GBPCHF");
               OpenSell("CHFJPY");
               OpenBuy("CADCHF");
               OpenBuy("AUDCHF");
               OpenBuy("NZDCHF");
            }
            if(InstrumentSelected==CAD)
            {
               OpenBuy("USDCAD");
               OpenBuy("EURCAD");
               OpenBuy("GBPCAD");
               OpenSell("CADJPY");
               OpenSell("CADCHF");
               OpenBuy("AUDCAD");
               OpenBuy("NZDCAD");
            }
            if(InstrumentSelected==AUD)
            {
               OpenSell("AUDUSD");
               OpenBuy("EURAUD");
               OpenBuy("GBPAUD");
               OpenSell("AUDJPY");
               OpenSell("AUDCHF");
               OpenSell("AUDCAD");
               OpenSell("AUDNZD");
            }
            if(InstrumentSelected==NZD)
            {
               OpenSell("NZDUSD");
               OpenBuy("EURNZD");
               OpenBuy("GBPNZD");
               OpenSell("NZDJPY");
               OpenSell("NZDCHF");
               OpenSell("NZDCAD");
               OpenBuy("AUDNZD");
            }
         }
         if (lparam == 48)
             WS.closecommands.Add();
         if (lparam == 56)
            SetBEClose();
         if (lparam == 54)
            SetSoftStopMode();
         if (lparam == 53)
            SetHardStopMode();
         if (lparam == 188)
            _OpenLots=MathMax(_OpenLots-(0.01*ExtendedRepeatingFactor()),0.01);
         if (lparam == 190)
            _OpenLots+=(0.01*ExtendedRepeatingFactor());
         if (lparam == 65)
         {
            double breach=0+(SymbolCommissionPoints()+margin);
            if(_StopLossPips==DISABLEDPOINTS)
               return;
            _StopLossPips=MathMax(_StopLossPips-((0.1*ExtendedRepeatingFactor())*pipsfactor),breach);
            if(_StopLossPips==breach)
            {
               _StopLossPips=DISABLEDPOINTS;
               DeleteLevels();
            }
            DrawLevels();
         }
         if (lparam == 83)
         {
            double breach=0+(SymbolCommissionPoints()+margin);
            if(_StopLossPips==DISABLEDPOINTS)
               _StopLossPips=breach;
            _StopLossPips+=((0.1*ExtendedRepeatingFactor())*pipsfactor);
            DrawLevels();
         }
         if (lparam == 68)
         {
            double breach=0-(SymbolCommissionPoints()-margin);
            if(_TakeProfitPips==DISABLEDPOINTS)
               return;
            _TakeProfitPips=MathMax(_TakeProfitPips-((0.1*ExtendedRepeatingFactor())*pipsfactor),breach);
            if(_TakeProfitPips==breach)
            {
               _TakeProfitPips=DISABLEDPOINTS;
               DeleteLevels();
            }
            DrawLevels();
         }
         if (lparam == 70)
         {
            double breach=0-(SymbolCommissionPoints()-margin);
            if(_TakeProfitPips==DISABLEDPOINTS)
               _TakeProfitPips=breach;
            _TakeProfitPips+=((0.1*ExtendedRepeatingFactor())*pipsfactor);
            DrawLevels();
         }

         if (lparam == 88)
         {
            InstrumentSelected+=1;
            if(InstrumentSelected>NZD)
               InstrumentSelected=USD;
         }
         if (lparam == 89)
         {
            InstrumentSelected=0;
         }

         if (lparam == 86)
         {
            TradesViewSelected+=1;
            if(TradesViewSelected>ByCurrencies)
               TradesViewSelected=ByPairs;
         }
      }

      if (lparam == 16)
         ToggleTradeLevels();

      if(tradelevelsvisible)
      {
         double margin=(5*pipsfactor)+(int)MathRound((AskX()-BidX())/Point());

         if (lparam == 65)
         {
            double breach=0-(WS.tradereference[selectedtradeindex].points-(margin));
            if(WS.tradereference[selectedtradeindex].stoplosspips==DISABLEDPOINTS)
               return;
            WS.tradereference[selectedtradeindex].stoplosspips=MathMax(WS.tradereference[selectedtradeindex].stoplosspips-((0.1*ExtendedRepeatingFactor())*pipsfactor),breach);
            if(WS.tradereference[selectedtradeindex].stoplosspips==breach)
            {
               WS.tradereference[selectedtradeindex].stoplosspips=DISABLEDPOINTS;
               DeleteSelectedTradeLevels();
            }
            DrawSelectedTradeLevels();
         }
         if (lparam == 83)
         {
            double breach=0-(WS.tradereference[selectedtradeindex].points-(margin));
            if(WS.tradereference[selectedtradeindex].stoplosspips==DISABLEDPOINTS)
               WS.tradereference[selectedtradeindex].stoplosspips=breach;
            WS.tradereference[selectedtradeindex].stoplosspips+=((0.1*ExtendedRepeatingFactor())*pipsfactor);
            DrawSelectedTradeLevels();
         }
         if (lparam == 68)
         {
            double breach=WS.tradereference[selectedtradeindex].points+(margin);
            if(WS.tradereference[selectedtradeindex].takeprofitpips==DISABLEDPOINTS)
               return;
            WS.tradereference[selectedtradeindex].takeprofitpips=MathMax(WS.tradereference[selectedtradeindex].takeprofitpips-((0.1*ExtendedRepeatingFactor())*pipsfactor),breach);
            if(WS.tradereference[selectedtradeindex].takeprofitpips==breach)
            {
               WS.tradereference[selectedtradeindex].takeprofitpips=DISABLEDPOINTS;
               DeleteSelectedTradeLevels();
            }
            DrawSelectedTradeLevels();
         }
         if (lparam == 70)
         {
            double breach=WS.tradereference[selectedtradeindex].points+(margin);
            if(WS.tradereference[selectedtradeindex].takeprofitpips==DISABLEDPOINTS)
               WS.tradereference[selectedtradeindex].takeprofitpips=breach;
            WS.tradereference[selectedtradeindex].takeprofitpips+=((0.1*ExtendedRepeatingFactor())*pipsfactor);
            DrawSelectedTradeLevels();
         }
         if (lparam == 71)
            NextTradeLevels(true);
         if (lparam == 72)
            NextTradeLevels();

      }

   }
}


void SwitchSymbol(string tosymbol)
{
   if(istesting)
      return;
   string currentsymbol=StringSubstr(ChartSymbol(),0,6);
   if(currentsymbol!=tosymbol)
   {
      if(SwitchSymbolClickAllCharts)
      {
         long chartid=ChartFirst();
         while(chartid>-1)
         {
            if(chartid!=ChartID())
               ChartSetSymbolPeriod(chartid,tosymbol+SymbolExtraChars,ChartPeriod(chartid));
            chartid=ChartNext(chartid);
         }
      }
      ChartSetSymbolPeriod(0,tosymbol+SymbolExtraChars,0);
   }
}


void SetLastErrorBool(bool result)
{
   if(!result)
      SetLastError(-1);
}


void SetLastError(int result)
{
   if(result>-1)
      return;
   lasterrortime=TimeLocal();
   lasterrorstring="Went wrong, "+ErrorDescription(GetLastError());
}


int SymbolCommissionPoints()
{
   double tickvalue=CurrentSymbolTickValue();
   return (int)NormalizeDouble(CommissionPerLotPerRoundtrip/tickvalue,0);
}


long OrderMagicNumberX()
{
#ifdef __MQL4__
   return OrderMagicNumber();
#endif
#ifdef __MQL5__
   return PositionGetInteger(POSITION_MAGIC);
#endif
}


long OrderTicketX()
{
#ifdef __MQL4__
   return OrderTicket();
#endif
#ifdef __MQL5__
   return PositionGetInteger(POSITION_TICKET);
#endif
}


int OrdersTotalX()
{
#ifdef __MQL4__
   return OrdersTotal();
#endif
#ifdef __MQL5__
   return PositionsTotal();
#endif
}


bool OrderSelectX(int index)
{
#ifdef __MQL4__
   return OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
#endif
#ifdef __MQL5__
   return (StringLen(PositionGetSymbol(index))>0);
#endif
}


string OrderSymbolX()
{
#ifdef __MQL4__
   return OrderSymbol();
#endif
#ifdef __MQL5__
   return PositionGetString(POSITION_SYMBOL);
#endif
}


double CurrentSymbolTickValue()
{
#ifdef __MQL4__
   return MarketInfo(Symbol(),MODE_TICKVALUE);
#endif
#ifdef __MQL5__
   return SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);
#endif
}


double OrderSymbolTickValue()
{
#ifdef __MQL4__
   return MarketInfo(OrderSymbolX(),MODE_TICKVALUE);
#endif
#ifdef __MQL5__
   return SymbolInfoDouble(OrderSymbolX(),SYMBOL_TRADE_TICK_VALUE);
#endif
}


double OrderCommissionSwap()
{
#ifdef __MQL4__
   return OrderCommission()+OrderSwap();
#endif
#ifdef __MQL5__
   double commission=0;
   if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
   {
      ulong Ticket=0;
      int dealscount=HistoryDealsTotal();
      for(int i=0;i<dealscount;i++)
      {
         ulong TicketDeal=HistoryDealGetTicket(i);
         if(TicketDeal>0)
         {
            if(HistoryDealGetInteger(TicketDeal,DEAL_ENTRY)==DEAL_ENTRY_IN)
            {
               Ticket=TicketDeal;
               break;
            }
         }
      }
      if(Ticket>0)
      {
         double LotsIn=HistoryDealGetDouble(Ticket,DEAL_VOLUME);
         if(LotsIn>0)
            commission=HistoryDealGetDouble(Ticket,DEAL_COMMISSION)*PositionGetDouble(POSITION_VOLUME)/LotsIn;
         if(MT5CommissionPerDeal)
            commission=commission*2;
      }
   }
   return PositionGetDouble(POSITION_SWAP)+commission;
#endif
}


double OrderProfitNet()
{
#ifdef __MQL4__
   return OrderProfit()+OrderCommissionSwap();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_PROFIT)+OrderCommissionSwap();
#endif
}


double OrderLotsX()
{
#ifdef __MQL4__
   return OrderLots();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_VOLUME);
#endif
}


bool OrderTypeBuy()
{
#ifdef __MQL4__
   return (OrderType()==OP_BUY);
#endif
#ifdef __MQL5__
   return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
#endif
}


bool OrderTypeSell()
{
#ifdef __MQL4__
   return (OrderType()==OP_SELL);
#endif
#ifdef __MQL5__
   return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL);
#endif
}


double OrderOpenPriceX()
{
#ifdef __MQL4__
   return OrderOpenPrice();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_PRICE_OPEN);
#endif
}


double OrderStopLossX()
{
#ifdef __MQL4__
   return OrderStopLoss();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_SL);
#endif
}


double OrderTakeProfitX()
{
#ifdef __MQL4__
   return OrderTakeProfit();
#endif
#ifdef __MQL5__
   return PositionGetDouble(POSITION_TP);
#endif
}

double AccountBalanceX()
{
#ifdef __MQL4__
   return AccountBalance();
#endif
#ifdef __MQL5__
   return AccountInfoDouble(ACCOUNT_BALANCE);
#endif
}


double AccountFreeMarginX()
{
#ifdef __MQL4__
   return AccountFreeMargin();
#endif
#ifdef __MQL5__
   return AccountInfoDouble(ACCOUNT_MARGIN_FREE);
#endif
}


double AskX(string symbol=NULL)
{
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
//#ifdef __MQL4__
//   return Ask;
//#endif
//#ifdef __MQL5__
   MqlTick last_tick;
   if(SymbolInfoTick(s,last_tick))
      return last_tick.ask;
   else
      return 0;
//#endif
}


double BidX(string symbol=NULL)
{
   string s=Symbol();
   if(symbol!=NULL)
      s=symbol;
//#ifdef __MQL4__
//   return Bid;
//#endif
//#ifdef __MQL5__
   MqlTick last_tick;
   if(SymbolInfoTick(s,last_tick))
      return last_tick.bid;
   else
      return 0;
//#endif
}


void SetOrderSL(double sl)
{
#ifdef __MQL4__
   SetLastErrorBool(OrderModify(OrderTicketX(),OrderOpenPriceX(),sl,OrderTakeProfitX(),0));
#endif
#ifdef __MQL5__
   CTrade trade;
   SetLastErrorBool(trade.PositionModify(OrderTicketX(),sl,OrderTakeProfitX()));
#endif
}


double ATR()
{
   MqlDateTime dtcurrent;
   TimeCurrent(dtcurrent);
   if(dtcurrent.day!=atrday)
   {
      MqlRates rates[];
      int bars=16;
      int copied=CopyRates(Symbol(),PERIOD_D1,0,bars,rates);
      if(copied==bars)
      {
         atr=0;
         for(int k=1; k<=14; k++)
            atr += MathMax(rates[k].high,rates[k-1].close)-MathMin(rates[k].low,rates[k-1].close);
         atr/=(double)14;
         atrday=dtcurrent.day;
      }
   }
   return atr;
}


















////////////////////////////////////////////////////////////////////////////////////
// STRATEGIES
////////////////////////////////////////////////////////////////////////////////////


interface Strategy 
{
public:
   string GetName();
   void IdleCalculate();
   void Calculate();
};


class StrategyOutOfTheBox : public Strategy
{
public:

   datetime lastsignal;

   StrategyOutOfTheBox()
   {
      lastsignal=0;
   }
   
   void Calculate()
   {
   
   }

   void IdleCalculate()
   {
      int startboxhour=9;
      int endboxhour=12;

      MqlDateTime dtcurrent;
      TimeCurrent(dtcurrent);
      if(dtcurrent.min!=0 ||
         (dtcurrent.hour<=endboxhour && dtcurrent.hour>=startboxhour)
      )
         return;

      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      int bars=20;
      int copied=CopyRates(Symbol(),PERIOD_H1,0,bars,rates); 
      if(copied==bars)
      {
         double boxhigh=0;
         double boxlow=DBL_MAX;
         double maxgapclose=0;
         double mingapclose=DBL_MAX;
         
         bool boxfound=false;

         for(int i=2; i<bars; i++)
         {
            if(rates[i].time<=lastsignal)
               break;

            MqlDateTime dtbar;
            TimeToStruct(rates[i].time,dtbar);
            
            if(dtbar.hour<=endboxhour&&dtbar.hour>=startboxhour)
            {
               boxhigh=MathMax(boxhigh,rates[i].high);
               boxlow=MathMin(boxlow,rates[i].low);
            }
            else
            {
               maxgapclose=MathMax(maxgapclose,rates[i].close);
               mingapclose=MathMin(mingapclose,rates[i].close);
            }

            if(dtbar.hour==startboxhour)
            {
               boxfound=true;
               break;
            }
         }
         
         if(boxfound &&
            rates[1].close>boxhigh &&
            maxgapclose<boxhigh
         )
         {
            lastsignal=rates[0].time;
            OpenBuy(NULL,0.01,0,NULL,NULL,boxlow,NormalizeDouble(boxhigh+((boxhigh-boxlow)/2),Digits()));
         }
         
      }

   }
};


class StrategyLittleDD : public Strategy
{
public:

   StrategyLittleDD()
   {
   
   }

   void Calculate()
   {
   
   }

   void IdleCalculate()
   {
      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      int bars=20;
      int copied=CopyRates(Symbol(),Period(),0,bars,rates); 
      if(copied==bars)
      {
         //MqlDateTime dtcurrent;
         //TimeToStruct(rates[0].time,dtcurrent);
         //if(dtcurrent.hour<8||dtcurrent.hour>18)
         //   return;
         
         double pipsize=SymbolInfoDouble(Symbol(),SYMBOL_POINT)*pipsfactor;
         
         double highest=DBL_MIN;
         double lowest=DBL_MAX;

         for(int i=1; i<bars-3; i++)
         {
            if(i>1)
            {
               highest=MathMax(highest,rates[i-1].high);
               lowest=MathMin(lowest,rates[i-1].low);
            }
            if(rates[i].close<rates[i+1].open && rates[i+1].close>rates[i+1].open && rates[i+2].close>rates[i+2].open && highest<rates[i+1].open && rates[0].close>=rates[i+1].open && rates[0].high<=(rates[i+1].open+pipsize))
               OpenSell(NULL,0.1,0,200,200);
         }
      
      }
   }
};


class StrategyPivotsDay : public Strategy
{
public:
   TypePivotsData pivotsdata;
   datetime lastdaysignal;

   StrategyPivotsDay()
   {
      pivotsdata.Settings.draw=true;
      pivotsdata.Settings.PivotTypeHour=PIVOT_FIBONACCI;
      pivotsdata.Settings.PivotTypeFourHour=PIVOT_FIBONACCI;
      pivotsdata.Settings.PivotTypeDay=PIVOT_FIBONACCI;
      pivotsdata.Settings.PivotTypeWeek=PIVOT_FIBONACCI;
      lastdaysignal=0;
   }

   void Calculate()
   {

   }

   void IdleCalculate()
   {
      MqlDateTime dtcurrent;
      TimeCurrent(dtcurrent);
      //if(dtcurrent.hour!=16)
      //   return;

      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      int copied=CopyRates(Symbol(),PERIOD_M1,0,1,rates); 
      if(copied==1)
      {
         if(!pivotsdata.Calculate(rates[0].time))
            return;
         
         datetime starttime=rates[0].time;

         copied=CopyRates(Symbol(),PERIOD_D1,0,1,rates);
         if(copied==-1)
            return;

         datetime endtime=rates[0].time;
         if(lastdaysignal==endtime)
            return;

         //copied=CopyRates(Symbol(),PERIOD_M1,starttime,endtime,rates);
         int copycount=500;
         copied=CopyRates(Symbol(),PERIOD_M1,0,copycount,rates);
         if(copied<copycount)
            return;
            
         //Print(IntegerToString(rates[0].time));
         
         double tickvalue=CurrentSymbolTickValue();
         if(tickvalue==0)
            return;
         
         double upperlevel=pivotsdata.PivotsDay.R1;
         double lowerlevel=pivotsdata.PivotsDay.S1;
         double centerlevel=pivotsdata.PivotsDay.P;
         double upperrange=NormalizeDouble((upperlevel-centerlevel)/Point(),0);
         double lowerrange=NormalizeDouble((centerlevel-lowerlevel)/Point(),0);

         double percentbalance=2;
         double uppervolume=NormalizeDouble(((AccountBalanceX()/100)*percentbalance)/(tickvalue*upperrange),2);
         double lowervolume=NormalizeDouble(((AccountBalanceX()/100)*percentbalance)/(tickvalue*lowerrange),2);

         //if(rates[0].close>=upperlevel&&uppervolume>=0.01&&upperrange>=100)
         if(rates[0].close>=upperlevel   &&   rates[0].close<=upperlevel+(Point()*10)   /*&&   upperrange>=50*/   &&   uppervolume>=0.01)
         {
            //Print("Range: "+upperrange+" | Volume: "+uppervolume);
            lastdaysignal=endtime;
            OpenSell(NULL,uppervolume,0,upperrange+10,upperrange-10);
         }

         //if(rates[0].close<=lowerlevel&&lowervolume>=0.01)
         //{
         //   lasth4signal=endtime;
         //   OpenBuy(NULL,lowervolume,0,lowerrange,lowerrange);
         //}

      }
   }
};


class StrategyPivotsH4FibonacciR1S1Reversal : public Strategy
{
public:
   TypePivotsData pivotsdata;
   datetime lasth4signal;

   StrategyPivotsH4FibonacciR1S1Reversal()
   {
      pivotsdata.Settings.draw=true;
      pivotsdata.Settings.PivotTypeHour=NONE;
      pivotsdata.Settings.PivotTypeFourHour=PIVOT_FIBONACCI;
      pivotsdata.Settings.PivotTypeDay=NONE;
      pivotsdata.Settings.PivotTypeWeek=NONE;
      pivotsdata.Settings.PivotTypeMonth=NONE;
      pivotsdata.Settings.PivotTypeYear=NONE;
      lasth4signal=0;
   }

   void Calculate()
   {

   }

   void IdleCalculate()
   {
      MqlDateTime t;
      TimeCurrent(t);
      if(!_TradingHours[t.hour])
         return;

      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      int copied=CopyRates(Symbol(),PERIOD_M1,0,1,rates); 
      if(copied==1)
      {
         if(!pivotsdata.Calculate(rates[0].time))
            return;
         
         datetime starttime=rates[0].time;

         copied=CopyRates(Symbol(),PERIOD_H4,0,1,rates);
         if(copied==-1)
            return;

         datetime endtime=rates[0].time;
         if(lasth4signal==endtime)
            return;

         //copied=CopyRates(Symbol(),PERIOD_M1,starttime,endtime,rates);
         int copycount=500;
         copied=CopyRates(Symbol(),PERIOD_M1,0,copycount,rates);
         if(copied<copycount)
            return;
            
         //Print(IntegerToString(rates[0].time));
         
         double tickvalue=CurrentSymbolTickValue();
         if(tickvalue==0)
            return;
         
         double upperlevel=pivotsdata.PivotsFourHour.R1;
         double lowerlevel=pivotsdata.PivotsFourHour.S1;
         double centerlevel=pivotsdata.PivotsFourHour.P;
         double upperrange=NormalizeDouble((upperlevel-centerlevel)/Point(),0);
         double lowerrange=NormalizeDouble((centerlevel-lowerlevel)/Point(),0);

         double percentbalance=2;
         double uppervolume=NormalizeDouble(((AccountBalanceX()/100)*percentbalance)/(tickvalue*upperrange),2);
         double lowervolume=NormalizeDouble(((AccountBalanceX()/100)*percentbalance)/(tickvalue*lowerrange),2);

         bool BaerishRelation=pivotsdata.PivotsFourHourList[1].P<pivotsdata.PivotsFourHourList[2].P;
         bool BullishRelation=pivotsdata.PivotsFourHourList[1].P>pivotsdata.PivotsFourHourList[2].P;

         bool Inside=pivotsdata.PivotsFourHourList[1].TC<pivotsdata.PivotsFourHourList[2].TC&&pivotsdata.PivotsFourHourList[1].BC>pivotsdata.PivotsFourHourList[2].BC;

         bool Engulfing=pivotsdata.PivotsFourHourList[1].TC>pivotsdata.PivotsFourHourList[2].TC&&pivotsdata.PivotsFourHourList[1].BC<pivotsdata.PivotsFourHourList[2].BC;

         bool LargerRange=(pivotsdata.PivotsFourHourList[1].TC-pivotsdata.PivotsFourHourList[1].BC)>(pivotsdata.PivotsFourHourList[2].TC-pivotsdata.PivotsFourHourList[2].BC);

         if(rates[0].close>=upperlevel&&uppervolume>=0.01&&upperrange>=100)
         //if(Inside  &&  rates[0].close>=upperlevel   &&   rates[0].close<=upperlevel+(Point()*10)   /*&&   upperrange>=50*/   &&   uppervolume>=0.01   &&   upperrange>=MinPoints1)
         {
            //Print("Range: "+upperrange+" | Volume: "+uppervolume);
            lasth4signal=endtime;
            OpenSell(NULL,uppervolume,0,NULL,NULL,upperlevel+(upperlevel-centerlevel),centerlevel);
         }

         //if(rates[0].close<=lowerlevel&&lowervolume>=0.01)
         //{
         //   lasth4signal=endtime;
         //   OpenBuy(NULL,lowervolume,0,lowerrange,lowerrange);
         //}

      }
   }
};


class StrategyCSH4Reversal : public Strategy
{
public:
   TypeCurrencyStrength CS[1];
   bool tradesstarted;

   StrategyCSH4Reversal()
   {
      CS[0].Init(
         10,
         10,
         StringSubstr(Symbol(),6),
         PERIOD_H4,
         false,
         pr_close
         );
   }

   void Calculate()
   {
      MqlDateTime dtcurrent;
      TimeCurrent(dtcurrent);
      //if((dtcurrent.hour==3||dtcurrent.hour==7||dtcurrent.hour==11||dtcurrent.hour==15||dtcurrent.hour==19)&&dtcurrent.min==59)
      if(dtcurrent.hour==11&&dtcurrent.min==59)
      //if((dtcurrent.hour==11||dtcurrent.hour==15)&&dtcurrent.min==59)
      //if(dtcurrent.min==59||dtcurrent.min==29)
      //if(dtcurrent.min==59)
      {
         bool csok=CS_CalculateIndex(CS[0]);
         if(dtcurrent.sec>=50&&csok&&!tradesstarted)
         {
            tradesstarted=true;
            for(int z=0; z<4; z++)
            {
               if(CS[0].Currencies.Trade[z].buy)
                  OpenSell(CS[0].Currencies.Trade[z].name);
               else
                  OpenBuy(CS[0].Currencies.Trade[z].name);
            }
         }
      }
      else
         tradesstarted=false;
   }

   void IdleCalculate() {}
};


class StrategyTest1 : public Strategy
{
public:
   void Calculate() {}

   void IdleCalculate()
   {
       OpenBuy(NULL,0.01,0,0,400);
       OpenSell(NULL,0.01,0,0,400);
       return;

      MqlRates rates[];
      ArraySetAsSeries(rates,true); 
      int copied=CopyRates(Symbol(),0,0,10,rates); 
      if(copied==10)
      {
         MqlDateTime dtcurrent;
         TimeToStruct(rates[0].time,dtcurrent);
         if(dtcurrent.hour<8||dtcurrent.hour>18)
            return;
      
         //if(rates[1].close>rates[1].open && rates[1].close>rates[2].open && rates[2].close<rates[2].open && rates[3].close<rates[3].open && rates[0].close<=rates[2].open)
         //if(rates[1].close>rates[1].open && rates[1].close>rates[2].open && rates[2].close<rates[2].open && rates[3].close<rates[3].open)
         double lastcandlehight=(rates[1].close-rates[1].open)/Point();
         //if(rates[1].close>rates[1].open && rates[2].close<rates[2].open && rates[3].close<rates[3].open && lastcandlehight>=30)
         if(rates[1].close>rates[2].open && rates[2].close<rates[2].open && rates[3].close<rates[3].open)
            OpenBuy(NULL,0.01,0,0,400);
         if(rates[1].close<rates[2].open && rates[2].close>rates[2].open && rates[3].close>rates[3].open)
            OpenSell(NULL,0.01,0,0,400);
      }
   }
};


class StrategyCSGBPBaskets : public Strategy
{

#define CS_DB_Backtest

public:

#ifdef CS_DB_Backtest

   string GetName() { return "Harvester CSGBPBaskets DB Backtest"; }

#else

   string GetName() { return "Harvester CSGBPBaskets"; }

#endif

#ifdef CS_DB_Backtest

   int db;
   int request;

#else

   TypeCurrencyStrength CS[2];

#endif

   datetime lastminute;
   int lastday;
   int daytrend;

   struct TypeTimes
   {
      datetime t1;
      MqlDateTime t2;
   };
   TypeTimes times;

   struct TypeRow
   {
      int TIME;
      int YEAR;
      int MONTH;
      int DAY;
      int DAYOFWEEK;
      int HOUR;
      int MINUTE;
      int C1;
      int C2;
      int C3;
      int C4;
      int C5;
      int C6;
      int C7;
      int C8;
      int D1;
      int D2;
      int D3;
      int D4;
      int D5;
      int D6;
      int D7;
      int D8;
      int DD1;
      int DD2;
      int DD3;
      int DD4;
      int DD5;
      int DD6;
      int DD7;
      int DD8;
      int DDD1;
      int DDD2;
      int DDD3;
      int DDD4;
      int DDD5;
      int DDD6;
      int DDD7;
      int DDD8;
      int O1;
      int O2;
      int O3;
      int O4;
      int O5;
      int O6;
      int O7;
      int O8;
      int MA1;
      int MA2;
      int MA3;
      int MA4;
      int MA5;
      int MA6;
      int MA7;
      int MA8;
      TypeRow()
      {
         TIME=0;
      }
   };
   TypeRow r[100];
  
   StrategyCSGBPBaskets()
   {
      lastminute=0;
      lastday=0;
      daytrend=-1;
      
#ifdef CS_DB_Backtest

      db=DatabaseOpen("CS.sqlite", DATABASE_OPEN_READONLY | DATABASE_OPEN_COMMON);
      request=DatabasePrepare(db, "SELECT * FROM MinutesCS WHERE TIME=?");   

#else

      M15DayInit();

#endif
   }

   ~StrategyCSGBPBaskets()
   {
#ifdef CS_DB_Backtest

      DatabaseClose(db);

#endif
   }

#ifdef CS_DB_Backtest

#else

   void M15DayInit()
   {
      int zeropoint=100;
   
      datetime Arr[];
      if(CopyTime(Symbol(),PERIOD_M15,0,100,Arr)==100)
      {
         for(int i=100-2; i>=0; i--)
         {
            MqlDateTime dt;
            MqlDateTime dtp;
            TimeToStruct(Arr[i],dt);
            TimeToStruct(Arr[i+1],dtp);
            zeropoint=100-1-i;
            if(dt.day!=dtp.day)
               break;
         }
      }
   
      CS[0].Init(
         100,
         zeropoint,
         StringSubstr(Symbol(),6),
         PERIOD_M15,
         false,
         pr_close,
         19,
         5,
         true
         );
      CS[0].recalculate=true;
   
      CS[1].Init(
         100,
         zeropoint,
         StringSubstr(Symbol(),6),
         PERIOD_M15,
         false,
         pr_close,
         6,
         0,
         true
         );
      CS[1].recalculate=true;
   }

#endif

   bool GetM1Time()
   {
      datetime time[];
      int copied=CopyTime(Symbol(),PERIOD_M1,0,1,time); 
      if(copied==1)
      {
         times.t1=time[0];
         TimeToStruct(time[0],times.t2);
         return true;
      }
      return false;
   }
   
   bool IsM15NewBar()
   {
      if(MathMod(times.t2.min,15)!=0)
      {
#ifdef CS_DB_Backtest

#else

         CS_CalculateIndex(CS[0]);
         CS_CalculateIndex(CS[1]);

#endif
         return false;
      }
#ifdef CS_DB_Backtest

#else

      else
      {
         M15DayInit();
      }

#endif

      return true;
   }

   bool IsTradingTime()
   {
      if(!_TradingHours[times.t2.hour])
         return false;
      if(!_TradingWeekdays[times.t2.day_of_week])
         return false;
      return true;
   }

   void GetIndexData()
   {
#ifdef CS_DB_Backtest

      for(int i=0; i<100; i++)
      {
         int t=(int)times.t1-60-(PeriodSeconds(PERIOD_M15)*i);
         DatabaseReset(request);
         DatabaseBind(request,0,t);
         if(!DatabaseReadBind(request,r[i]))
            break;
      }

#else

      for(int i=0; i<100; i++)
      {
         for(int z=0; z<8; z++)
         {
            int Ox=(int)MathRound(CS[0].Currencies.Currency[z].index[CS[0].bars-1-i].laging.value1*100000);
            int MAx=(int)MathRound(CS[1].Currencies.Currency[z].index[CS[1].bars-1-i].laging.value1*100000);
            if(z==0) { r[i].O1=Ox; r[i].MA1=MAx; }
            if(z==1) { r[i].O2=Ox; r[i].MA2=MAx; }
            if(z==2) { r[i].O3=Ox; r[i].MA3=MAx; }
            if(z==3) { r[i].O4=Ox; r[i].MA4=MAx; }
            if(z==4) { r[i].O5=Ox; r[i].MA5=MAx; }
            if(z==5) { r[i].O6=Ox; r[i].MA6=MAx; }
            if(z==6) { r[i].O7=Ox; r[i].MA7=MAx; }
            if(z==7) { r[i].O8=Ox; r[i].MA8=MAx; }
         }
      }

#endif
   }

#define CS_GBP_Reverse_Basket
//#define Simple_45Min_CS_GBP_Basket

#ifdef CS_GBP_Reverse_Basket

   void IdleCalculate() {}

   void Calculate()
   {
      if(!GetM1Time())
         return;

      if(!IsM15NewBar())
         return;

      if(!IsTradingTime())
         return;

      if(times.t1==lastminute)
         return;

      GetIndexData();
      
      bool isnewday=lastday!=times.t2.day_of_year;
      if(isnewday)
         daytrend=-1;

      double openlots=NormalizeDouble((AccountBalanceX()/10000)*_OpenLots,2);
      //openlots=_OpenLots;

      //if((daytrend==OP_BUY && row.D3<0) || (daytrend==OP_SELL && row.D3>0))
      //   CloseAllInternal();

      //if(dtcurrent.hour==22)
      //{
      //   CloseAllInternal();
      //   return;
      //}

      if(
         r[1].O3>r[2].O3 &&
         r[0].O3<r[1].O3 &&
         r[1].O3>=100 &&
         r[0].MA3>=75 /*&&
         isnewday*/
      )
      {
         SellGBP(openlots);
         lastday=times.t2.day_of_year;
         daytrend=OP_SELL;
      }
      if(
         r[1].O3<r[2].O3 &&
         r[0].O3>r[1].O3 &&
         r[1].O3<=-100 &&
         r[0].MA3<=-75 /*&&
         isnewday*/
      )
      {
         BuyGBP(openlots);
         lastday=times.t2.day_of_year;
         daytrend=OP_BUY;
      }

      lastminute=times.t1;
   }

#endif

#ifdef Simple_45Min_CS_GBP_Basket

   void Calculate() {}

   void IdleCalculate()
   {
      MqlRates rates[];
      ArraySetAsSeries(rates,true); 
      int copied=CopyRates(Symbol(),0,0,1,rates); 
      if(copied==1)
      {
         MqlDateTime dtcurrent;
         TimeToStruct(rates[0].time,dtcurrent);
         if(!_TradingHours[dtcurrent.hour])
            return;

         DatabaseReset(request);
         DatabaseBind(request,0,rates[0].time-60);
         if(!DatabaseReadBind(request,row))
            return;

         double openlots=NormalizeDouble((AccountBalanceX()/10000)*_OpenLots,2);

         if(row.C3>row.C1&&row.C3>row.C2&&row.C3>row.C4&&row.C3>row.C5&&row.C3>row.C6&&row.C3>row.C7&&row.C3>row.C8 &&true)
            BuyGBP(openlots);
         if(row.C3<row.C1&&row.C3<row.C2&&row.C3<row.C4&&row.C3<row.C5&&row.C3<row.C6&&row.C3<row.C7&&row.C3<row.C8 &&true)
            SellGBP(openlots);

      }
   }

#endif
   
   void BuyGBP(double openlots)
   {
      OpenBuy("GBPUSD",openlots);
      OpenSell("EURGBP",openlots);
      OpenBuy("GBPJPY",openlots);
      OpenBuy("GBPCHF",openlots);
      OpenBuy("GBPCAD",openlots);
      OpenBuy("GBPAUD",openlots);
      OpenBuy("GBPNZD",openlots);
   }

   void SellGBP(double openlots)
   {
      OpenSell("GBPUSD",openlots);
      OpenBuy("EURGBP",openlots);
      OpenSell("GBPJPY",openlots);
      OpenSell("GBPCHF",openlots);
      OpenSell("GBPCAD",openlots);
      OpenSell("GBPAUD",openlots);
      OpenSell("GBPNZD",openlots);
   }
   
};


Strategy* strats[];
