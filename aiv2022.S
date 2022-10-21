.org $8000
start:
LDX #$FF
TXS
; load 0x17 into A
LDA #$17

LDA #1 ; red
LDX #0 ; offset
loop:
LDA $4000
STA $0200, X ; 0x0200 + X
INX

BNE loop

JMP start

dummyfunc:
LDY #5
RTS


.goto $FFFA
.dw start ; non maskable
.dw start ; reset
.dw start ; interrupt