# mt4-close-orders-script

# Скрипт для закрытия ордеров в MetaTrader 4

Этот скрипт позволяет закрывать ордера по трем режимам:
1. Закрыть все рыночные ордера.
2. Закрыть только прибыльные ордера с прибылью выше указанных пунктов.
3. Закрыть только убыточные ордера.

## Особенности
- Обработка реквотов и разрывов соединения.
- Подробная статистика после выполнения.
- Настройка через внешние параметры.

## Установка
Поместите файл `Scrpt_ManGooRoo_CloseProfit_by_ENUM_***.mq4` в папку `MQL4/Scripts` вашего терминала MetaTrader 4.

## Использование

1. Запустите скрипт на графике.
2. Выберите режим закрытия.
3. Укажите порог прибыли (для режима закрытия прибыли).

# English Version:

Order Closing Script for MetaTrader 4

### This script closes orders using three modes:

1. Close all market orders
2. Close only profitable orders with profit above specified points
3. Close only loss-making orders

## Features

- Handles requotes and disconnections
- Detailed execution statistics
- Customizable via input parameters

## Installation

Place Scrpt_ManGooRoo_CloseProfit_by_ENUM_Eng.mq4 in your Terminal/Data_Folder/MQL4/Scripts/ directory
Restart MetaTrader 4

## Usage

Run the script on any chart

### Select closing mode:

1. CLOSE_ALL: Close all positions
2. CLOSE_PROFIT: Close profitable orders (set profit threshold)
3. CLOSE_LOSS: Close loss-making orders
   
For CLOSE_PROFIT mode, specify minimum profit points

# Spanish Version:

Script para Cerrar Órdenes en MetaTrader 4

### Este script cierra órdenes en tres modos:

1. Cerrar todas las órdenes de mercado
2. Cerrar solo órdenes rentables con ganancia superior a puntos especificados
3. Cerrar solo órdenes con pérdida

## Características

- Maneja reconexiones y desconexiones
- Estadísticas detalladas de ejecución
- Configurable mediante parámetros externos

## Instalación

Coloque Scrpt_ManGooRoo_CerrarPorTipo_Esp.mq4 en su Terminal/Carpeta_Datos/MQL4/Scripts/
Reinicie MetaTrader 4

## Uso

Ejecute el script en cualquier gráfico

### Seleccione modo de cierre:

1. CERRAR_TODO: Cerrar todas las posiciones
2. CERRAR_GANANCIA: Cerrar órdenes rentables (definir umbral de ganancia)
3. CERRAR_PERDIDA: Cerrar órdenes con pérdida
