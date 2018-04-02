//+------------------------------------------------------------------+
//|                                                         qOTA.mq5 |
//|                              Copyright 2018, qOTA Software Corp. |
//|                                           http://www.qota.com.br |
//+------------------------------------------------------------------+

#property copyright   "2018, qOTA Software Corp."
#property link        "http://www.qota.com.br"
#property description "qOTA"

#include <MovingAverages.mqh>
#include <iBarShift.mqh>

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   3

#property indicator_type1   DRAW_LINE
#property indicator_color1  C'20,20,20'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label1  "ADX"

#property indicator_type2   DRAW_LINE
#property indicator_color2  C'0,80,0'
#property indicator_style2  STYLE_DOT
#property indicator_width2  2
#property indicator_label2  "Positivo +DI"

#property indicator_type3   DRAW_LINE
#property indicator_color3  C'140,0,0'
#property indicator_style3  STYLE_DOT
#property indicator_width3  2
#property indicator_label3  "Negativo -DI"

input string Separador1 = "CONFIGURAÇÕES"; // ____________________________
input int ADX_T_Periodo = 4; // ADX | Periodo

double C_Porcentagem = C_T_Porcentagem / 100.00, ADX_B[], ADX_B_I_Positivo[], ADX_B_I_Negativo[], ADX_B_Positivo[], ADX_B_Negativo[], ADX_B_Temporario[], HA_Abertura[], HA_Fechamento[], HA_Minima[], HA_Maxima[];
int ADX_Periodo, HA_Verde, HA_Vermelho, Win, Loss, Win_T, Loss_T, Win_Combo, Loss_Combo;

bool HA(const int i) {

    if (HA_Abertura[i - 1] < HA_Fechamento[i - 1]) {

        HA_Verde++;
        HA_Vermelho = 0;

        return true;

    } else {

        HA_Verde = 0;
        HA_Vermelho++;

        return false;

    }

}

void Win(const int i, const bool Tipo, const datetime &Time[]) {

    Win_T++;
    Win++;

    if (Loss_T > Loss_Combo) {

        Loss_Combo = Loss_T;

    }

    Loss_T = 0;

    if (Tipo) {

        Print("WIN-: Compra: " + TimeToString(Time[i]), "  |  HA_Verde---: " + IntegerToString(HA_Verde));
        ObjectSetInteger(0, "Compra " + IntegerToString(i), OBJPROP_COLOR, C'0,80,0');

    } else {

        Print("WIN-: Venda-: " + TimeToString(Time[i]), "  |  HA_Vermelho: " + IntegerToString(HA_Vermelho));
        ObjectSetInteger(0, "Venda " + IntegerToString(i), OBJPROP_COLOR, C'140,0,0');

    }

}

void Loss(const int i, const bool Tipo, const datetime &Time[]) {

    Loss_T++;
    Loss++;

    if (Win_T > Win_Combo) {

        Win_Combo = Win_T;

    }

    Win_T = 0;

    if (Tipo) {

        Print("LOSS: Compra: " + TimeToString(Time[i]), "  |  HA_Verde---: " + IntegerToString(HA_Verde));
        ObjectSetInteger(0, "Compra " + IntegerToString(i), OBJPROP_COLOR, C'50,50,50');

    } else {

        Print("LOSS: Venda-: " + TimeToString(Time[i]), "  |  HA_Vermelho: " + IntegerToString(HA_Vermelho));
        ObjectSetInteger(0, "Venda " + IntegerToString(i), OBJPROP_COLOR, C'50,50,50');

    }

}

void Compra(const int i, const double &Open[], const double &Close[], const datetime &Time[]) {

    ObjectCreate(0, "Compra " + IntegerToString(i), OBJ_VLINE, 0, Time[i], 0);

    if (Close[i] == Open[i]) {

        Loss(i, true, Time);

    } else if (Open[i] < Close[i]) {

        Win(i, true, Time);

    } else {

        Loss(i, true, Time);

    }

}

void Venda(const int i, const double &Open[], const double &Close[], const datetime &Time[]) {

    ObjectCreate(0, "Venda " + IntegerToString(i), OBJ_VLINE, 0, Time[i], 0);

    if (Close[i] == Open[i]) {

        Loss(i, false, Time);

    } else if (Open[i] < Close[i]) {

        Loss(i, false, Time);

    } else {

        Win(i, false, Time);

    }

}

int Engolfo(const int i, const double &Open[], const double &Close[]) {

    int Anterior = (int) MathAbs(NormalizeDouble(Close[i - 2] - Open[i - 2], _Digits) / _Point);
    int Atual = (int) MathAbs(NormalizeDouble(Close[i - 1] - Open[i - 1], _Digits) / _Point);

    if (Open[i - 2] > Close[i - 2] && Open[i - 1] < Close[i - 1] && Atual > Anterior) {

        return 1;

    } else if (Open[i - 2] < Close[i - 2] && Open[i - 1] > Close[i - 1] && Atual > Anterior) {

        return 2;

    } else {

        return 0;

    }

}

int ADX_Engolfo(const int i) {

    if (ADX_B_I_Positivo[i - 1] < ADX_B_I_Negativo[i - 1] && ADX_B_I_Positivo[i] > ADX_B_I_Negativo[i]) {

        return 1;

    } else if (ADX_B_I_Positivo[i - 1] > ADX_B_I_Negativo[i - 1] && ADX_B_I_Positivo[i] < ADX_B_I_Negativo[i]) {

        return 2;

    } else {

        return 0;

    }

}

void OnInit() {

    if (ADX_T_Periodo >= 100 || ADX_T_Periodo <= 0) {

        ADX_Periodo = 4;
        printf("Valor incorreto para a variável de entrada Period_ADX = %d. Indicator usará Value = %d para cálculos.", ADX_T_Periodo, ADX_Periodo);

    } else {

        ADX_Periodo = ADX_T_Periodo;

    }

    SetIndexBuffer(0, ADX_B, INDICATOR_CALCULATIONS);
    SetIndexBuffer(1, ADX_B_I_Positivo, INDICATOR_CALCULATIONS);
    SetIndexBuffer(2, ADX_B_I_Negativo, INDICATOR_CALCULATIONS);
    SetIndexBuffer(3, ADX_B_Positivo, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, ADX_B_Negativo, INDICATOR_CALCULATIONS);
    SetIndexBuffer(5, ADX_B_Temporario, INDICATOR_CALCULATIONS);
    SetIndexBuffer(6, HA_Abertura, INDICATOR_DATA);
    SetIndexBuffer(7, HA_Maxima, INDICATOR_DATA);
    SetIndexBuffer(8, HA_Minima, INDICATOR_DATA);
    SetIndexBuffer(9, HA_Fechamento, INDICATOR_DATA);

    IndicatorSetInteger(INDICATOR_DIGITS, 2);

    IndicatorSetString(INDICATOR_SHORTNAME, "qOTA");

    PlotIndexSetString(0, PLOT_LABEL, "qOTA");

}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &Time[], const double &Open[], const double &High[], const double &Low[], const double &Close[], const long &TickVolume[], const long &Volume[], const int &Spread[]) {

    int Inicio, Inicio1, Inicio2, Inicio3, Inicio4, Fim1, Fim2, Fim3, Fim4;

    if (rates_total < ADX_Periodo) {

        return (0);

    }

    if (prev_calculated > 1) {

        HA_Minima[0] = Low[0];
        HA_Maxima[0] = High[0];
        HA_Abertura[0] = Open[0];
        HA_Fechamento[0] = Close[0];
        Inicio = prev_calculated - 1;

    } else {

        Inicio = 1;
        ADX_B_I_Positivo[0] = 0.0;
        ADX_B_I_Negativo[0] = 0.0;
        ADX_B[0] = 0.0;

    }

    if (ObjectFind(0, "Inicio1") == 0 && ObjectFind(0, "Fim1") == 0) {

        Inicio1 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Inicio1", OBJPROP_TIME, 0)) + 1;
        Fim1 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Fim1", OBJPROP_TIME, 0)) + 1;

    } else {

        Inicio1 = 0;
        Fim1 = 0;

    }

    if (ObjectFind(0, "Inicio2") == 0 && ObjectFind(0, "Fim2") == 0) {

        Inicio2 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Inicio2", OBJPROP_TIME, 0)) + 1;
        Fim2 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Fim2", OBJPROP_TIME, 0)) + 1;

    } else {

        Inicio2 = 0;
        Fim2 = 0;

    }

    if (ObjectFind(0, "Inicio3") == 0 && ObjectFind(0, "Fim3") == 0) {

        Inicio3 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Inicio3", OBJPROP_TIME, 0)) + 1;
        Fim3 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Fim3", OBJPROP_TIME, 0)) + 1;

    } else {

        Inicio3 = 0;
        Fim3 = 0;

    }

    if (ObjectFind(0, "Inicio4") == 0 && ObjectFind(0, "Fim4") == 0) {

        Inicio4 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Inicio4", OBJPROP_TIME, 0)) + 1;
        Fim4 = iBarShift(_Symbol, _Period, ObjectGetInteger(0, "Fim4", OBJPROP_TIME, 0)) + 1;

    } else {

        Inicio4 = 0;
        Fim4 = 0;

    }

    HA_Verde = 0;
    HA_Vermelho = 0;

    for (int i = Inicio; i < rates_total && !IsStopped(); i++) {

        double HA_T_Abertura = (HA_Abertura[i - 1] + HA_Fechamento[i - 1]) / 2, HA_T_Fechamento = (Open[i] + High[i] + Low[i] + Close[i]) / 4;
        double HA_T_Maxima = MathMax(High[i], MathMax(HA_T_Abertura, HA_T_Fechamento)), Maxima = High[i], Maxima_Anterior = High[i - 1], Minima = Low[i], Minima_Anterior = Low[i - 1], Fechamento_Anterior = Close[i - 1];
        double HA_T_Minima = MathMin(Low[i], MathMin(HA_T_Abertura, HA_T_Fechamento)), ADX_T_Positivo = Maxima - Maxima_Anterior, ADX_T_Negativo = Minima_Anterior - Minima;

        HA_Minima[i] = HA_T_Minima;
        HA_Maxima[i] = HA_T_Maxima;
        HA_Abertura[i] = HA_T_Abertura;
        HA_Fechamento[i] = HA_T_Fechamento;

        if (ADX_T_Positivo < 0.0) {

            ADX_T_Positivo = 0.0;

        }

        if (ADX_T_Negativo < 0.0) {

            ADX_T_Negativo = 0.0;

        }

        if (ADX_T_Positivo > ADX_T_Negativo) {

            ADX_T_Negativo = 0.0;

        } else {

            if (ADX_T_Positivo < ADX_T_Negativo) {

                ADX_T_Positivo = 0.0;

            } else {

                ADX_T_Positivo = 0.0;
                ADX_T_Negativo = 0.0;

            }

        }

        double tr = MathMax(MathMax(MathAbs(Maxima - Minima), MathAbs(Maxima - Fechamento_Anterior)), MathAbs(Minima - Fechamento_Anterior));

        if (tr != 0.0) {

            ADX_B_Positivo[i] = 100.0 * ADX_T_Positivo / tr;
            ADX_B_Negativo[i] = 100.0 * ADX_T_Negativo / tr;

        } else {

            ADX_B_Positivo[i] = 0.0;
            ADX_B_Negativo[i] = 0.0;

        }

        ADX_B_I_Positivo[i] = ExponentialMA(i, ADX_Periodo, ADX_B_I_Positivo[i - 1], ADX_B_Positivo);
        ADX_B_I_Negativo[i] = ExponentialMA(i, ADX_Periodo, ADX_B_I_Negativo[i - 1], ADX_B_Negativo);

        double ADX_Temporario = ADX_B_I_Positivo[i] + ADX_B_I_Negativo[i];

        if (ADX_Temporario != 0.0) {

            ADX_Temporario = 100.0 * MathAbs((ADX_B_I_Positivo[i] - ADX_B_I_Negativo[i]) / ADX_Temporario);

        } else {

            ADX_Temporario = 0.0;

        }

        ADX_B_Temporario[i] = ADX_Temporario;
        ADX_B[i] = ExponentialMA(i, ADX_Periodo, ADX_B[i - 1], ADX_B_Temporario);

        ObjectDelete(0, "Compra " + IntegerToString(i));
        ObjectDelete(0, "Venda " + IntegerToString(i));

        HA(i);
        if ((i >= (rates_total - Inicio1) && i <= (rates_total - Fim1) && Inicio1 != 0) || (i >= (rates_total - Inicio2) && i <= (rates_total - Fim2) && Inicio2 != 0) || (i >= (rates_total - Inicio3) && i <= (rates_total - Fim3) && Inicio3 != 0) || (i >= (rates_total - Inicio4) && i <= (rates_total - Fim4) && Inicio4 != 0)) {

            if (HA_Verde > 0) {

                Compra(i, Open, Close, Time);

            } else if (HA_Vermelho > 0) {

                //Venda(i, Open, Close, Time);
                Compra(i, Open, Close, Time);

            }

            Comment("WinCOMBO: " + IntegerToString(Win_Combo), "  |  LossCOMBO: " + IntegerToString(Loss_Combo), "  |  Win: " + IntegerToString(Win), "  |  Loss: " + IntegerToString(Loss), "  |  Total: " + IntegerToString((Win + Loss)));
            
        }

    }

    if (rates_total != prev_calculated) {

    }

    return (rates_total);

}