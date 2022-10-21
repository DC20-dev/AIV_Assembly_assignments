; basic setup for the 6502
.org $8000
start:
LDX #$FF
TXS
; sets the "player" in the center (sort of)
LDA #1
STA $0288 ; 0200 => VGA, 0x88 = 0xFF/2 => center sort of
; store the address les significant bites in zero page at 02
; these represent the position on the screen
LDA #$88
STA $02

loop:
; input --> managed by the cpu
; ---------------
; update

; reset the last lit pixel (on screen)
; loads old position in X and keeps it until before clearing
LDX $02
; update the position
JSR do_movement
; ---------------
; draw
LDA #0 ; black
STA $0200, X
LDA #1
LDY $02
STA $0200, Y
; ---------------

JMP loop ; find an exit condition

JMP setup ; if exits of loop goes back to start

do_movement:   ; subroutine to move the player
; $4000 is the address where to find the bitmask for the input
; up = 0001, down = 0010, left = 0100, right = 1000
; LDA $4000 every time and AND #$01 etc, or LDA #$01 etc and AND $4000 costs the same...
LDA $4000
AND #$01
BNE move_up
LDA $4000
AND #$02
BNE move_down
LDA $4000
AND #$04
BNE move_left
LDA $4000
AND #$08
BNE move_right
; the $02 value is changed, now we absolute access the value and use $02 as offset
; to find the new pixel to be lit

RTS

; movement coroutines to jump to during loop
; 1) load the bits containing the screen pos
; 2) perform adds/subs
; 3) store back the value -> update of $02

move_up:
; decrease by 0x0010
SEC ; sets the carry to avoid crossing to a different line
; haven't really understood why but ok
LDA $02
SBC #$10
STA $02
RTS

move_down:
CLC ; clears carry for the same reason as above
LDA $02
ADC #$10
STA $02
; increase by 0x0010
RTS

move_left:
; decrease by 0x0001
LDA $02
SBC #$01
STA $02
RTS

move_right:
; increase by 0x0001
LDA $02
ADC #$01
STA $02
RTS


; ; sets the last values in the rom (interrupt ones) to start address
.goto $FFFA
.dw start ; non maskable
.dw start ; reset
.dw start ; interrupt