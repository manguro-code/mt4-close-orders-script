﻿//+------------------------------------------------------------------+
//|                      Scrpt_ManGooRoo_CloseProfit_by_ENUM_Eng.mq4 |
//|                         Copyright 2025, ManGooRoo Software Corp. |
//|          https://github.com/manguro-code/mt4-close-orders-script |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, ManGooRoo Software Corp."
#property link      "https://github.com/manguro-code/mt4-close-orders-script"
#property version   "1.00"
#property strict
#property script_show_inputs
#property description "Script for closing positions based on selected mode:\n"
#property description "• Close All: Closes all market orders\n"
#property description "• Close Profit: Closes orders with profit over specified points\n"
#property description "• Close Loss: Closes only losing positions\n"

// Close mode enumeration
enum ENUM_CLOSE_MODE {
    CLOSE_ALL,         // Close all positions
    CLOSE_PROFIT,      // Close only profitable
    CLOSE_LOSS         // Close only loss-making
};

// Input parameters
extern ENUM_CLOSE_MODE CloseMode = CLOSE_PROFIT; // Position closing mode
extern int ProfitPoints = 50;                    // Profit in points (for CLOSE_PROFIT mode)

//+------------------------------------------------------------------+
//| Script start function                                            |
//+------------------------------------------------------------------+
void OnStart()
{
    double startBalance = AccountBalance();   // Starting account balance
    double startEquity = AccountEquity();     // Starting account equity
    
    int suitableOrders = 0;    // Count of orders matching criteria
    int closedOrders = 0;       // Count of successfully closed orders
    double totalProfit = 0.0;   // Total profit from closed orders (in account currency)
    double totalPoints = 0.0;   // Total points gained/lost
    int profitableCount = 0;    // Count of profitable orders closed
    int lossCount = 0;          // Count of loss-making orders closed

    // Iterate through all orders in reverse order
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            // Check if it's a market order (BUY or SELL)
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                // Calculate profit in points
                double pointProfit = CalculateProfitInPoints();
                
                // Flag to determine if closing is needed
                bool needClose = false;
                
                // Check conditions based on selected mode
                switch(CloseMode)
                {
                    case CLOSE_ALL:    // Close all positions
                        needClose = true;
                        break;
                        
                    case CLOSE_PROFIT: // Close only profitable
                        needClose = (pointProfit > ProfitPoints);
                        break;
                        
                    case CLOSE_LOSS:   // Close only losing positions
                        needClose = (pointProfit < 0);
                        break;
                }
                
                // Close order if conditions are met
                if(needClose)
                {
                    // Calculate order profit before closing
                    double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
                    double orderPoints = pointProfit;
                    
                    suitableOrders++;
                    if(CloseOrderWithRetry(OrderTicket(), OrderLots(), OrderType()))
                    {
                        closedOrders++;
                        totalProfit += orderProfit;
                        totalPoints += orderPoints;
                        
                        if(orderProfit >= 0) profitableCount++;
                        else lossCount++;
                    }
                }
            }
        }
    }
    
    // Calculate account statistics
    double endBalance = AccountBalance();
    double endEquity = AccountEquity();
    double balanceChange = endBalance - startBalance;
    double equityChange = endEquity - startEquity;
    double balanceChangePercent = (startBalance != 0) ? (balanceChange / startBalance) * 100 : 0;
    
    // Display results summary
    string resultMessage = "";
    string alertMessage = "";
    
    if(suitableOrders == 0)
    {
        switch(CloseMode)
        {
            case CLOSE_PROFIT:
                resultMessage = "No profitable orders found with profit > " + IntegerToString(ProfitPoints) + " points";
                alertMessage = "Close Profit: No matching orders";
                break;
                
            case CLOSE_LOSS:
                resultMessage = "No loss-making orders found";
                alertMessage = "Close Loss: No matching orders";
                break;
                
            case CLOSE_ALL:
                resultMessage = "No market orders found to close";
                alertMessage = "Close All: No orders found";
                break;
        }
        Print(resultMessage);
        Alert(alertMessage);
    }
    else
    {
        resultMessage = "Execution report: " + IntegerToString(suitableOrders) + " suitable orders, " 
                      + IntegerToString(closedOrders) + " successfully closed";
        
        alertMessage = "Execution Complete:\n" + resultMessage;
        
        // Add detailed statistics if orders were closed
        if(closedOrders > 0)
        {
            alertMessage += "\n\n=== Profit Statistics ===";
            alertMessage += "\nTotal Profit/Loss: " + DoubleToString(totalProfit, 2) + " " + AccountCurrency();
            alertMessage += "\nTotal Points: " + DoubleToString(totalPoints, 2) + " points";
            alertMessage += "\nProfitable Orders: " + IntegerToString(profitableCount);
            alertMessage += "\nLoss Orders: " + IntegerToString(lossCount);
            
            alertMessage += "\n\n=== Account Impact ===";
            alertMessage += "\nBalance Change: " + DoubleToString(balanceChange, 2) + " " + AccountCurrency();
            alertMessage += "\nBalance Change: " + DoubleToString(balanceChangePercent, 2) + "%";
            alertMessage += "\nEquity Change: " + DoubleToString(equityChange, 2) + " " + AccountCurrency();
            alertMessage += "\nNew Balance: " + DoubleToString(endBalance, 2) + " " + AccountCurrency();
            alertMessage += "\nNew Equity: " + DoubleToString(endEquity, 2) + " " + AccountCurrency();
        }
        
        // Show warning if not all orders were closed
        if(closedOrders < suitableOrders)
        {
            int failedOrders = suitableOrders - closedOrders;
            alertMessage += "\n\nWarning: " + IntegerToString(failedOrders) + " orders failed to close!";
        }
        
        Print(resultMessage);
        Alert(alertMessage);
    }
}

//+------------------------------------------------------------------+
//| Calculate profit in points for current order                     |
//+------------------------------------------------------------------+
double CalculateProfitInPoints()
{
    string symbol = OrderSymbol();  // Order symbol
    double pointValue = MarketInfo(symbol, MODE_POINT); // Point size
    
    if(OrderType() == OP_BUY) // For Buy order
    {
        double currentBid = MarketInfo(symbol, MODE_BID); // Current Bid price
        return (currentBid - OrderOpenPrice()) / pointValue;
    }
    else if(OrderType() == OP_SELL) // For Sell order
    {
        double currentAsk = MarketInfo(symbol, MODE_ASK); // Current Ask price
        return (OrderOpenPrice() - currentAsk) / pointValue;
    }
    return 0; // Return 0 for other order types
}

//+------------------------------------------------------------------+
//| Close order with retries and error handling                      |
//+------------------------------------------------------------------+
bool CloseOrderWithRetry(int ticket, double lots, int orderType)
{
    int slippage = 3;             // Allowed slippage in points
    color arrowColor = clrRed;    // Closing arrow color
    int maxAttempts = 10;         // Maximum retry attempts
    int sleepTime = 1000;         // Delay between attempts (1 second)
    
    // Retry loop
    for(int attempt = 0; attempt < maxAttempts; attempt++)
    {
        // Check if trading is allowed
        if(!IsTradeAllowed())
        {
            Print("Trading not allowed. Attempt ", attempt+1);
            Sleep(sleepTime);
            continue;
        }
        
        // Check server connection
        if(!IsConnected())
        {
            Print("No server connection. Attempt ", attempt+1);
            Sleep(sleepTime);
            continue;
        }

        // Refresh market rates
        RefreshRates();
        
        // Determine closing price
        double closePrice;
        string symbol = OrderSymbol();
        
        if(orderType == OP_BUY)
            closePrice = MarketInfo(symbol, MODE_BID); // Close BUY at Bid price
        else if(orderType == OP_SELL)
            closePrice = MarketInfo(symbol, MODE_ASK); // Close SELL at Ask price

        // Attempt to close order
        bool success = OrderClose(ticket, lots, closePrice, slippage, arrowColor);
        
        // Check if successful
        if(success) 
        {
            Print("Order ", ticket, " closed successfully.");
            return true;
        }

        // Handle closing errors
        int error = GetLastError();
        
        // Analyze error type
        switch(error)
        {
            case 0: // No error
                break;
                
            // Critical errors - no retry
            case 2:   // TRADE_TIMEOUT
            case 64:  // ACCOUNT_DISABLED
            case 133: // TRADE_DISABLED
            case 4108:// WRONG_SYMBOL
                Print("Critical closing error: ", error, " - ", ErrorDescription(error));
                return false;
                
            // Retryable errors
            case 6:   // NO_CONNECTION
            case 128: // TRADE_TIMEOUT
            case 129: // INVALID_PRICE
            case 135: // PRICE_CHANGED
            case 136: // OFF_QUOTES
            case 138: // REQUOTE
            case 146: // TRADE_CONTEXT_BUSY
            case 147: // TRADE_EXPIRATION_DENIED
                Print("Retryable error (", error, "): ", ErrorDescription(error), ". Attempt ", attempt+1);
                Sleep(sleepTime);
                break;
                
            // Other errors
            default: 
                Print("Unknown error: ", error, " - ", ErrorDescription(error));
                Sleep(sleepTime);
                break;
        }
    }
    
    // Failure message after all attempts
    Print("Failed to close order ", ticket, " after ", maxAttempts, " attempts");
    return false;
}

//+------------------------------------------------------------------+
//| Error description function                                       |
//+------------------------------------------------------------------+
string ErrorDescription(int errorCode)
{
    switch(errorCode)
    {
        case 0:   return "No error";
        case 2:   return "Timeout error";
        case 6:   return "No connection to server";
        case 64:  return "Account disabled";
        case 128: return "Trade timeout";
        case 129: return "Invalid price";
        case 135: return "Price changed";
        case 136: return "No quotes";
        case 138: return "Requote";
        case 146: return "Trade context busy";
        case 133: return "Trading prohibited";
        case 147: return "Order expiration denied";
        case 4108:return "Invalid symbol";
        default:  return "Unknown error (" + IntegerToString(errorCode) + ")";
    }
}
//+------------------------------------------------------------------+
