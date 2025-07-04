//+------------------------------------------------------------------+
//|                      Scrpt_ManGooRoo_CloseProfit_by_ENUM_Esp.mq4 |
//|                         Copyright 2025, ManGooRoo Software Corp. |
//|          https://github.com/manguro-code/mt4-close-orders-script |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, ManGooRoo Software Corp."
#property link      "https://github.com/manguro-code/mt4-close-orders-script"
#property version   "1.00"
#property strict
#property script_show_inputs
#property description "Script para cerrar posiciones según el modo seleccionado:\n"
#property description "• Cerrar Todo: Cierra todas las órdenes de mercado\n"
#property description "• Cerrar Ganancia: Cierra órdenes con ganancia superior a puntos especificados\n"
#property description "• Cerrar Pérdida: Cierra solo posiciones perdedoras\n"

// Enumeración de modos de cierre
enum ENUM_MODO_CIERRE {
    CERRAR_TODO,         // Cerrar todas las posiciones
    CERRAR_GANANCIA,     // Cerrar solo con ganancia
    CERRAR_PERDIDA       // Cerrar solo con pérdida
};

// Parámetros de entrada
extern ENUM_MODO_CIERRE ModoCierre = CERRAR_GANANCIA; // Modo de cierre de posiciones
extern int PuntosGanancia = 50;                       // Ganancia en puntos (para modo CERRAR_GANANCIA)

//+------------------------------------------------------------------+
//| Función de inicio del script                                     |
//+------------------------------------------------------------------+
void OnStart()
{
    double balanceInicial = AccountBalance();   // Balance inicial de la cuenta
    double equityInicial = AccountEquity();     // Equity inicial de la cuenta
    
    int ordenesAptas = 0;       // Contador de órdenes que cumplen los criterios
    int ordenesCerradas = 0;     // Contador de órdenes cerradas exitosamente
    double gananciaTotal = 0.0;  // Ganancia total de órdenes cerradas (en moneda de la cuenta)
    double puntosTotales = 0.0;  // Puntos totales ganados/perdidos
    int ordenesGanadoras = 0;    // Contador de órdenes con ganancia cerradas
    int ordenesPerdedoras = 0;   // Contador de órdenes con pérdida cerradas

    // Iterar sobre todas las órdenes en orden inverso
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            // Verificar si es una orden de mercado (COMPRA o VENTA)
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                // Calcular ganancia en puntos
                double gananciaPuntos = CalcularGananciaEnPuntos();
                
                // Bandera para determinar si se necesita cerrar
                bool necesitaCierre = false;
                
                // Verificar condiciones según el modo seleccionado
                switch(ModoCierre)
                {
                    case CERRAR_TODO:    // Cerrar todas las posiciones
                        necesitaCierre = true;
                        break;
                        
                    case CERRAR_GANANCIA: // Cerrar solo con ganancia
                        necesitaCierre = (gananciaPuntos > PuntosGanancia);
                        break;
                        
                    case CERRAR_PERDIDA:  // Cerrar solo con pérdida
                        necesitaCierre = (gananciaPuntos < 0);
                        break;
                }
                
                // Cerrar orden si se cumplen las condiciones
                if(necesitaCierre)
                {
                    // Calcular ganancia de la orden antes de cerrar
                    double gananciaOrden = OrderProfit() + OrderSwap() + OrderCommission();
                    double puntosOrden = gananciaPuntos;
                    
                    ordenesAptas++;
                    if(CerrarOrdenConReintentos(OrderTicket(), OrderLots(), OrderType()))
                    {
                        ordenesCerradas++;
                        gananciaTotal += gananciaOrden;
                        puntosTotales += puntosOrden;
                        
                        if(gananciaOrden >= 0) ordenesGanadoras++;
                        else ordenesPerdedoras++;
                    }
                }
            }
        }
    }
    
    // Calcular estadísticas de la cuenta
    double balanceFinal = AccountBalance();
    double equityFinal = AccountEquity();
    double cambioBalance = balanceFinal - balanceInicial;
    double cambioEquity = equityFinal - equityInicial;
    double porcentajeCambioBalance = (balanceInicial != 0) ? (cambioBalance / balanceInicial) * 100 : 0;
    
    // Mostrar resumen de resultados
    string mensajeResultado = "";
    string mensajeAlerta = "";
    
    if(ordenesAptas == 0)
    {
        switch(ModoCierre)
        {
            case CERRAR_GANANCIA:
                mensajeResultado = "No se encontraron órdenes rentables con ganancia > " + IntegerToString(PuntosGanancia) + " puntos";
                mensajeAlerta = "Cerrar Ganancia: No hay órdenes coincidentes";
                break;
                
            case CERRAR_PERDIDA:
                mensajeResultado = "No se encontraron órdenes con pérdida";
                mensajeAlerta = "Cerrar Pérdida: No hay órdenes coincidentes";
                break;
                
            case CERRAR_TODO:
                mensajeResultado = "No se encontraron órdenes de mercado para cerrar";
                mensajeAlerta = "Cerrar Todo: No se encontraron órdenes";
                break;
        }
        Print(mensajeResultado);
        Alert(mensajeAlerta);
    }
    else
    {
        mensajeResultado = "Informe de ejecución: " + IntegerToString(ordenesAptas) + " órdenes aptas, " 
                         + IntegerToString(ordenesCerradas) + " cerradas exitosamente";
        
        mensajeAlerta = "Ejecución completada:\n" + mensajeResultado;
        
        // Añadir estadísticas detalladas si se cerraron órdenes
        if(ordenesCerradas > 0)
        {
            mensajeAlerta += "\n\n=== Estadísticas de Ganancia ===";
            mensajeAlerta += "\nGanancia/Pérdida Total: " + DoubleToString(gananciaTotal, 2) + " " + AccountCurrency();
            mensajeAlerta += "\nPuntos Totales: " + DoubleToString(puntosTotales, 2) + " puntos";
            mensajeAlerta += "\nÓrdenes Ganadoras: " + IntegerToString(ordenesGanadoras);
            mensajeAlerta += "\nÓrdenes Perdedoras: " + IntegerToString(ordenesPerdedoras);
            
            mensajeAlerta += "\n\n=== Impacto en la Cuenta ===";
            mensajeAlerta += "\nCambio en Balance: " + DoubleToString(cambioBalance, 2) + " " + AccountCurrency();
            mensajeAlerta += "\nCambio en Balance: " + DoubleToString(porcentajeCambioBalance, 2) + "%";
            mensajeAlerta += "\nCambio en Equity: " + DoubleToString(cambioEquity, 2) + " " + AccountCurrency();
            mensajeAlerta += "\nNuevo Balance: " + DoubleToString(balanceFinal, 2) + " " + AccountCurrency();
            mensajeAlerta += "\nNuevo Equity: " + DoubleToString(equityFinal, 2) + " " + AccountCurrency();
        }
        
        // Mostrar advertencia si no se cerraron todas las órdenes
        if(ordenesCerradas < ordenesAptas)
        {
            int ordenesFallidas = ordenesAptas - ordenesCerradas;
            mensajeAlerta += "\n\nAdvertencia: " + IntegerToString(ordenesFallidas) + " órdenes no se pudieron cerrar!";
        }
        
        Print(mensajeResultado);
        Alert(mensajeAlerta);
    }
}

//+------------------------------------------------------------------+
//| Calcular ganancia en puntos para la orden actual                 |
//+------------------------------------------------------------------+
double CalcularGananciaEnPuntos()
{
    string simbolo = OrderSymbol();  // Símbolo de la orden
    double valorPunto = MarketInfo(simbolo, MODE_POINT); // Tamaño del punto
    
    if(OrderType() == OP_BUY) // Para orden de compra
    {
        double bidActual = MarketInfo(simbolo, MODE_BID); // Precio Bid actual
        return (bidActual - OrderOpenPrice()) / valorPunto;
    }
    else if(OrderType() == OP_SELL) // Para orden de venta
    {
        double askActual = MarketInfo(simbolo, MODE_ASK); // Precio Ask actual
        return (OrderOpenPrice() - askActual) / valorPunto;
    }
    return 0; // Devolver 0 para otros tipos de orden
}

//+------------------------------------------------------------------+
//| Cerrar orden con reintentos y manejo de errores                  |
//+------------------------------------------------------------------+
bool CerrarOrdenConReintentos(int ticket, double volumen, int tipoOrden)
{
    int deslizamiento = 3;        // Deslizamiento permitido en puntos
    color colorFlecha = clrRed;   // Color de la flecha de cierre
    int maxIntentos = 10;         // Máximo de intentos
    int tiempoEspera = 1000;      // Tiempo entre intentos (1 segundo)
    
    // Bucle de reintentos
    for(int intento = 0; intento < maxIntentos; intento++)
    {
        // Verificar si el trading está permitido
        if(!IsTradeAllowed())
        {
            Print("Trading no permitido. Intento ", intento+1);
            Sleep(tiempoEspera);
            continue;
        }
        
        // Verificar conexión con el servidor
        if(!IsConnected())
        {
            Print("Sin conexión al servidor. Intento ", intento+1);
            Sleep(tiempoEspera);
            continue;
        }

        // Actualizar precios de mercado
        RefreshRates();
        
        // Determinar precio de cierre
        double precioCierre;
        string simbolo = OrderSymbol();
        
        if(tipoOrden == OP_BUY)
            precioCierre = MarketInfo(simbolo, MODE_BID); // Cerrar COMPRA al precio Bid
        else if(tipoOrden == OP_SELL)
            precioCierre = MarketInfo(simbolo, MODE_ASK); // Cerrar VENTA al precio Ask

        // Intentar cerrar la orden
        bool exito = OrderClose(ticket, volumen, precioCierre, deslizamiento, colorFlecha);
        
        // Verificar si fue exitoso
        if(exito) 
        {
            Print("Orden ", ticket, " cerrada exitosamente.");
            return true;
        }

        // Manejar errores de cierre
        int error = GetLastError();
        
        // Analizar tipo de error
        switch(error)
        {
            case 0: // Sin error
                break;
                
            // Errores críticos - no reintentar
            case 2:   // TRADE_TIMEOUT
            case 64:  // ACCOUNT_DISABLED
            case 133: // TRADE_DISABLED
            case 4108:// WRONG_SYMBOL
                Print("Error crítico al cerrar: ", error, " - ", DescripcionError(error));
                return false;
                
            // Errores reintentables
            case 6:   // NO_CONNECTION
            case 128: // TRADE_TIMEOUT
            case 129: // INVALID_PRICE
            case 135: // PRICE_CHANGED
            case 136: // OFF_QUOTES
            case 138: // REQUOTE
            case 146: // TRADE_CONTEXT_BUSY
            case 147: // TRADE_EXPIRATION_DENIED
                Print("Error reintentable (", error, "): ", DescripcionError(error), ". Intento ", intento+1);
                Sleep(tiempoEspera);
                break;
                
            // Otros errores
            default: 
                Print("Error desconocido: ", error, " - ", DescripcionError(error));
                Sleep(tiempoEspera);
                break;
        }
    }
    
    // Mensaje de fallo después de todos los intentos
    Print("Fallo al cerrar orden ", ticket, " después de ", maxIntentos, " intentos");
    return false;
}

//+------------------------------------------------------------------+
//| Función de descripción de errores                                |
//+------------------------------------------------------------------+
string DescripcionError(int codigoError)
{
    switch(codigoError)
    {
        case 0:   return "Sin error";
        case 2:   return "Error de tiempo de espera";
        case 6:   return "Sin conexión al servidor";
        case 64:  return "Cuenta deshabilitada";
        case 128: return "Tiempo de espera de operación agotado";
        case 129: return "Precio inválido";
        case 135: return "Precio cambiado";
        case 136: return "Sin cotizaciones";
        case 138: return "Re-cotización solicitada";
        case 146: return "Contexto de operación ocupado";
        case 133: return "Operación prohibida";
        case 147: return "Vencimiento de orden denegado";
        case 4108:return "Símbolo inválido";
        default:  return "Error desconocido (" + IntegerToString(codigoError) + ")";
    }
}
//+------------------------------------------------------------------+
