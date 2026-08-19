* TELCN: TELCO UBERGROM CODE INJECTION
* 12.28.2019 TT
*
* Contributed by Tim / InsaneMultitasker.
* Baud Rate locked to 38.4K
* See "baud" label
*
* This patch does not fix file transfers.
* The modules manipulate the CIB directly.

       DEF  START,SFIRST,SLAST

       AORG >3000

SFIRST EQU $
START  EQU $

       LWPI >EBAC      TELCO STARTUP WS

       LI   R0,>D030   OVER SPOOLER
       LI   R1,UINIT
PAT1   MOV  *R1+,*R0+
       CI   R1,URCVED  ; END OF CODE?
       JLE  PAT1

       LI   R0,TINIT
       MOV  *R0+,@>A856
       MOV  *R0+,@>A858

       LI   R0,TXMIT
       MOV  *R0+,@>AA00
       MOV  *R0+,@>AA02

       LI   R0,TRCV
       MOV  *R0+,@>A744
       MOV  *R0+,@>A746

       MOV  @SPOOL,@>D022 SPOOLER DISABLE
       MOV  @SPOOL+2,@>D024
       MOV  @SPOOL+4,@>D026

       B    @>A000     FORCE STARTUP

* COMPUTE ENTRY POINTS
       TEXT 'LENS'
TINIT  DATA >0460,>D030
TXMIT  DATA >0460,UXMIT-UINIT+>D030
TRCV   DATA >0460,URCV-UINIT+>D030

SPOOL  DATA >0000,>0380,>045B  RTWP,RT

       TEXT 'UBER'

* INIT UBERGROM UART
UINIT  LIMI 0
       LI   R12,>9C3E
       LI   R0,>A021
       MOVB R0,*R12
       SWPB R0
       MOVB R0,*R12
       LI   R0,>2300       * MSBYTE: 8N1 + U2X
       MOVB R0,@>9C3C
       MOV  @BAUD,R0
       MOVB R0,@>9C3C
       SWPB R0
       MOVB R0,@>9C3C
       LIMI 1
       RTWP

* UBERGROM XMIT ONE BYTE
UXMIT  LIMI 0
       LI   R12,>9C3E
       LI   R0,>A100
       MOVB R0,*R12
       SWPB R0
       MOVB R0,*R12
       MOVB @2(R13),@>9C3C  * via TELCO
       LIMI 1
       B    @>AA10

* UBERGROM RCV/BUFFER
       JMP  BR
URCV   LI   R12,>9C3E
       LI   R0,>A024
       MOVB R0,*R12
       SWPB R0
       MOVB R0,*R12
       CLR  R3
       MOVB @>983C,R3
       JEQ  BR             * NO CHARS
       SRL  R3,8

       LI   R0,>B000
       MOVB R0,*R12
       SWPB R0
       MOVB R0,*R12

* FILL TELCO 4K INTERNAL BUFFER
* WITH DATA FROM UBERGROM FIFO
       MOV  @BS,R2
BY     CLR  R1
       MOVB @>983C,R1
       MOV  @BU,@BU
       JEQ  BV
       ANDI R1,>7F00
BV     MOVB R1,*R2+
       C    R2,@BW
       JNE  BT
       MOV  @BX,R2
BT     DEC  R3
       JNE  BY
       MOV  R2,@BS          * SAVE PTR

BR     B    @>A78A
URCVED EQU $

       TEXT 'BAUD'
BAUD   DATA >1900
* >1900=38.4; >3200=19.2

BS     EQU >A110
BU     EQU >A6A8
BW     EQU >D158
BX     EQU >D156

SLAST  END
