;===============================================================================================
;
; PROG : Пример отображения данных для знакосинтезирующего ЖКИ по 4-х битной шине
; OWNER: burnout84@rambler.ru
; PROC : PIC16F84A
; FREQ : 4 MHZ
; DATE : 24.02.2010
;
; WEB  : https://github.com/burnout84
;
;
; Если RS = 0, то адресуется регистр команд (IR)
;      RS = 1, регистр данных (DR)
;
;
;===============================================================================================
LIST P=16F84A               ;
__CONFIG    03FF1H          ; Бит защиты выключен, WDT выключен, стандартный XT - генератор


TMR0                equ 01h ; Регистр TMR0. 
OPTIONR             equ 01h ; Регистр Option - банк 1. 
INTCON              equ 0Bh ; Регистр IntCon. 
INDF                equ 0   ;
PORTA               equ 5   ;
PORTB               equ 6   ;
TRISA               equ 85h ;
TRISB               equ 86h ;
OPTREG              equ 81h ;
STATUS              equ 3   ;
CARRY               equ 0   ;
GIE                 equ 7   ;
MSB                 equ 3   ; 
FSR                 equ 4h  ;
W                   equ 0   ; Результат направить в аккумулятор
F                   equ 1   ; Результат направить в регистр
RP0                 equ 5   ; Бит выбора банка
Z                   equ 2   ; Флаг нулевого результата
С                   equ 0   ; Флаг переноса-заема

RS                  equ 0   ;
RW                  equ 1   ;
E                   equ 2   ;
TEMP_LCD            equ 10h ;
COUNT0              equ 11h ;
COUNT1              equ 12h ;
;===============================================================================================
;                              НАЧАЛО ПРОГРАММЫ
;===============================================================================================
ORG  0                      ;
GOTO START                  ;
START                       ; Точка старта программы

CLRF  PORTA                 ; Очищаем порты
CLRF  PORTB                 ;
BSF STATUS,RP0              ; Переход в 1-й банк. 
MOVLW 0x00                  ; Все выводы порта А работают на выход
MOVWF TRISA                 ;
MOVLW 0x00                  ; Все выводы PORTB - выход
MOVWF TRISB                 ;
BCF STATUS,RP0              ; Установка банка 0

CALL INIT_LCD               ; Подпрограмма инициализации LCD
CALL PRINT_TEXT             ; Подпрограмма вывода текста на экран

LOOP GOTO LOOP              ; Зацикливаемся

;===============================================================================================
;                              ИНИЦИАЛИЗАЦИЯ LCD
;===============================================================================================
INIT_LCD			        ;
CALL DEL_15MS	            ; ОБЯЗАТЕЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ
BCF PORTB,RS                ; RS=0
BCF PORTB,RW                ; RW=0
BCF PORTB,E                 ; E=0
MOVLW h'30'		            ; Настройка
MOVWF PORTA                 ;
BSF	PORTB,E                 ; контроллера
BCF	PORTB,E                 ; LCD модуля
CALL DEL_4MS		        ;
BSF	PORTB,E	                ;
BCF	PORTB,E	                ;
CALL DEL_100MKS	            ;
BSF	PORTB,E	                ;
BCF	PORTB,E        	        ;
CALL BUSY                   ;

MOVLW 0x28                  ; ОТПРАВЛЯЕМ В LCD КОМАНДУ РАБОТЫ В 4-Х БИНОМ РЕЖИМЕ
MOVWF TEMP_LCD              ; т.к. команда отправлется будучи в 8-битном режиме, то отправлеям только один кусок байта
SWAPF TEMP_LCD,0            ;
MOVWF PORTA                 ;
BCF PORTB,RS                ;
BCF PORTB,RW                ;
BSF PORTB,E                 ;
BCF PORTB,E                 ;
CALL BUSY                   ; ОЖИДАЕМ ГОТОВНОСТИ

MOVLW h'28'		            ; ПОВТОРЯЕМ КОМАНДУ РАБОТЫ В 4-Х БИТНОМ РЕЖИМЕ, НО ОТПРАВЯЛЕМ 2 КУСКА (Шина-4bit, 2 строки, матрица 5х8 пикс)
CALL WRC	                ; 
MOVLW h'0C'	    	        ; ОТОБРАЖЕНИЕ БЕЗ КУРСОРА
CALL WRC	                ;
MOVLW h'06'		            ; АВТОМАТИЧЕСКОЕ ПЕРЕМЕЩЕНИЕ КУРСОРА СЛЕВА НАПРАВО
CALL WRC	                ;
MOVLW h'01'		            ; ОЧИСТИТЬ ДИСПЛЕЙ
CALL WRC	                ;
RETURN                      ;
;===============================================================================================
;                              ЗАПИСЬ КОДА КОМАНД LCD
;===============================================================================================
WRC                         ;
BCF PORTB,RS                ; Установить значение линии RS = 0
BCF PORTB,RW                ;
MOVWF TEMP_LCD              ; Вывести значение старшей тетрады байта данных на линии шины DB4..DB7
SWAPF TEMP_LCD,1            ; 
MOVFW TEMP_LCD              ;
MOVWF PORTA                 ;
BSF PORTB,E                 ; Установить линию E = 1
NOP                         ;
BCF PORTB,E                 ; Установить линию E = 0
SWAPF TEMP_LCD,1            ; Вывести значение младшей тетрады байта данных на линии шины DB4..DB7
MOVFW TEMP_LCD              ;
MOVWF PORTA                 ;
BSF PORTB,E                 ; Установить линию E = 1
NOP                         ;
BCF PORTB,E                 ; Установить линию E = 0
CALL BUSY                   ; Ожидаем готовности
RETURN                      ;
;===============================================================================================
;                             ЗАПИСЬ КОДА ДАННЫХ LCD
;===============================================================================================
WRD                         ;
BSF PORTB,RS                ; Установить значение линии RS = 0
MOVWF TEMP_LCD              ; Вывести значение старшей тетрады байта данных на линии шины DB4..DB7
SWAPF TEMP_LCD,1            ; 
MOVFW TEMP_LCD              ;
MOVWF PORTA                 ;
BSF PORTB,E                 ; Установить линию E = 1
NOP                         ;
BCF PORTB,E                 ; Установить линию E = 0
SWAPF TEMP_LCD,1            ; Вывести значение младшей тетрады байта данных на линии шины DB4..DB7
MOVFW TEMP_LCD              ;
MOVWF PORTA                 ;
BSF PORTB,E                 ; Установить линию E = 1
NOP                         ;
BCF PORTB,E                 ; Установить линию E = 0
CALL BUSY                   ; Ожидаем готовности
RETURN                      ;
;===============================================================================================
;                             ЧТЕНИЯ КОДА КОМАНД LCD
;===============================================================================================
C_READ                      ;
BCF PORTB,RS                ; Установить значение линии RS = 0
BSF PORTB,RW                ; Установить линию RW = 1
BSF PORTB,E                 ; Установить линию E = 1
MOVF PORTA,W                ; Считать значение старшей тетрады байта данных с линии DB4..DB7
MOVWF TEMP_LCD              ;
BCF PORTB,E                 ; Установить линию E = 0
BSF PORTB,E                 ; Установить линию E = 1
MOVF PORTA,W                ; Считать значение младшей тетрады байта данных с линии DB4..DB7
BCF PORTB,E                 ; Установить линию E = 0
BCF PORTB,RW                ; Установить линию RW = 0
RETURN                      ;
;===============================================================================================
;                      ПРОВЕРКА ГОТОВНОСТИ LCD
;===============================================================================================
BUSY                        ;
BSF STATUS,RP0 	            ;
MOVLW B'11111111'           ;
MOVWF TRISA                 ;
BCF	STATUS,RP0              ;
CALL C_READ                 ;
BTFSC TEMP_LCD,3            ;
GOTO BUSY                   ;
BSF STATUS,RP0              ;
MOVLW B'00000000'           ;
MOVWF TRISA                 ;
BCF	STATUS,RP0              ;
RETURN                      ;
;===============================================================================================
;                      ЗАДЕРЖКА 15 МС
;===============================================================================================
DEL_15MS                    ;
CLRF COUNT0                 ;
MOVLW .20                   ;
MOVWF COUNT1                ;
DECFSZ COUNT0               ;
GOTO $-1                    ;
DECFSZ COUNT1               ;
GOTO $-3                    ;
RETURN                      ;
;===============================================================================================
;                      ЗАДЕРЖКА 4 МС
;===============================================================================================
DEL_4MS                     ;
CLRF COUNT0                 ;
MOVLW .6                    ;
MOVWF COUNT1                ;
DECFSZ COUNT0               ;
GOTO $-1                    ;
DECFSZ COUNT1               ;
GOTO $-3                    ;
RETURN                      ;
;===============================================================================================
;                      ЗАДЕРЖКА 100 МКС
;===============================================================================================
DEL_100MKS                  ;
MOVLW .34                   ;
MOVWF COUNT0                ;
DECFSZ COUNT0               ;
GOTO $-1                    ;
RETURN                      ;
;===============================================================================================
;                      ЗАГРУЗКА СТРОК
;===============================================================================================
PRINT_TEXT                  ;

MOVLW 0x80                  ; ПЕРВАЯ СТРОКА
CALL WRC                    ;
MOVLW 0x57                  ; W
CALL WRD                    ;
MOVLW 0x57                  ; W
CALL WRD                    ;
MOVLW 0x57                  ; W
CALL WRD                    ;
MOVLW 0x2E                  ; .
CALL WRD                    ;
MOVLW 0x50                  ; P
CALL WRD                    ;
MOVLW 0x48                  ; H
CALL WRD                    ;
MOVLW 0x52                  ; R
CALL WRD                    ; 
MOVLW 0x45                  ; E
CALL WRD                    ;
MOVLW 0x41                  ; A
CALL WRD                    ; 
MOVLW 0x4B                  ; K
CALL WRD                    ;
MOVLW 0x45                  ; E
CALL WRD                    ;
MOVLW 0x52                  ; R
CALL WRD                    ;
MOVLW 0x53                  ; S
CALL WRD                    ;
MOVLW 0x2E                  ; .
CALL WRD                    ;
MOVLW 0x55                  ; U
CALL WRD                    ;
MOVLW 0x53                  ; S
CALL WRD                    ;

MOVLW 0xC0                  ; ВТОРАЯ СТРОКА
CALL WRC                    ;
MOVLW 0x48                  ; H
CALL WRD                    ;
MOVLW 0x4F                  ; O
CALL WRD                    ;
MOVLW 0x50                  ; P
CALL WRD                    ;
MOVLW 0x3A                  ; :
CALL WRD                    ;
MOVLW 0x20                  ; пробел
CALL WRD                    ;
MOVLW 0x45                  ; E
CALL WRD                    ;
MOVLW 0x46                  ; F
CALL WRD                    ;
MOVLW 0x39                  ; 9
CALL WRD                    ;
MOVLW 0x42                  ; B
CALL WRD                    ;
MOVLW 0x45                  ; E
CALL WRD                    ;
MOVLW 0x45                  ; E
CALL WRD                    ;
MOVLW 0x30                  ; 0
CALL WRD                    ;
MOVLW 0x32                  ; 2
CALL WRD                    ;
MOVLW 0x2E                  ; .
CALL WRD                    ;
MOVLW 0x2E                  ; .
CALL WRD                    ;
MOVLW 0x2E                  ; .
CALL WRD                    ;

RETURN

END