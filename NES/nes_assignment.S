.db "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

; using UPPERCASE for console addresses/constants
; lowercase for my addresses/constants
; lowercase for commands (just a matter of text highlighting)

; console addresses
.define PPUCTRL $2000
.define PPUMASK $2001
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define OAMDMA $4014
.define JOYPAD1 $4016
; console constants
.define NAMETABLE0 #$20
.define NAMETABLE1 #$24
.define NAMETABLE_START #0
.define HB_PALETTES #$3F
.define BG_PALETTES #$00
.define SPR_PALETTES #$10
; personal addresses
.define do_update? $00
.define buttons $01
.define scrollx $02
.define bg_counter $03
.define bg_pattern_table_counter $04
.define bg_inline_count $05
.define mario_x $06
.define mario_y $07
; personal constants
.define sprite_buffer #$02
.define black #$3F
.define white #$30
.define yellow #$28
.define red #$16
.define blue #$12
.define olive #$18

.org $8000
ldx #$FF
txs

start:
    lda #%10010000
    sta PPUCTRL
    lda #%00011110
    sta PPUMASK
    lda #0
    sta do_update?
    lda #$70
    sta mario_y
    lda #$78
    sta mario_x
set_sprites:
    ldx #0
    set_sprites_loop:
        
set_palettes:
    ; palette for bg
    lda HB_PALETTES
    sta PPUADDR
    lda BG_PALETTES
    sta PPUADDR
    lda black
    sta PPUDATA
    lda white
    sta PPUDATA
    lda yellow
    sta PPUDATA
    lda white
    sta PPUDATA
    ; palette for sprites
    lda HB_PALETTES
    sta PPUADDR
    lda SPR_PALETTES
    sta PPUADDR
    lda black
    sta PPUDATA
    lda red
    sta PPUDATA
    lda olive
    sta PPUDATA
    lda yellow
    sta PPUDATA
set_background:
    ; nametable 0
    lda NAMETABLE0
    sta PPUADDR
    lda NAMETABLE_START
    sta PPUADDR
    lda #0
    sta bg_counter
    sta bg_pattern_table_counter
    sta bg_inline_count
    jsr do_background
    ; nametable 1
    lda NAMETABLE1
    sta PPUADDR
    lda NAMETABLE_START
    sta PPUADDR
    lda #0
    sta bg_counter
    sta bg_pattern_table_counter
    sta bg_inline_count
    jsr do_background
loop:
    lda do_update?
    cmp #1
    bne loop
    ; though it's technically not in the nmi interrupt, this code still gets executed in vblank
    ; because vblank lasts quite a lot of cycles (~2273), enough to cover this simple part of the code
    ; (of course it is triggered only when a vblank is given)
    dec do_update? ; set bool back to false
    jsr draw_mario
    jmp loop
do_background:
    lda bg_counter
    ldx bg_inline_count
    cpx #$0F
    bmi draw_line
    beq draw_line
    draw_white:
    lda #$00
    sta PPUDATA
    cpx #$1F
    beq reset_inline_counter
    inc bg_inline_count
    inc bg_counter
    jmp do_background
    draw_line:
    lda bg_pattern_table_counter
    sta PPUDATA
    cmp #$FF
    beq bg_exit
    inc bg_pattern_table_counter
    inc bg_counter
    inc bg_inline_count
    jmp do_background
    reset_inline_counter:
        lda #0
        sta bg_inline_count
        jmp do_background
    bg_exit:
    rts 
draw_mario:
    ldx mario_x
    ldy mario_y
    lda #$00
    sta OAMADDR
    ; row 1/4
    tya 
    sta OAMDATA
    lda #$32
    sta OAMDATA
    lda #0
    sta OAMDATA
    txa 
    sta OAMDATA
    adc #$07
    tax 
    ; col 2
    tya 
    sta OAMDATA
    adc #$08
    tay 
    lda #$33
    sta OAMDATA
    lda #0
    sta OAMDATA
    txa 
    sta OAMDATA
    sbc #$07
    tax 
    ; row 2/4
    tya 
    sta OAMDATA
    lda #$42
    sta OAMDATA
    lda #0
    sta OAMDATA
    txa 
    sta OAMDATA
    adc #$07
    tax 
    ; col 2
    tya 
    sta OAMDATA
    adc #$08
    tay 
    lda #$43
    sta OAMDATA
    lda #0
    sta OAMDATA
    txa 
    sta OAMDATA
    sbc #$07
    tax 
    rts 
readjoy:
    lda #$01
    sta JOYPAD1
    sta buttons
    lsr a
    sta JOYPAD1
joyloop:
    lda JOYPAD1
    lsr a
    rol buttons
    bcc joyloop
    rts 
nmi:
    pha 
    jsr readjoy
    lda buttons
    do_scroll:
        cmp #$01
        beq branch_right_key
        cmp #$02
        beq branch_left_key
        cmp #$04
        beq move_down
        cmp #$08
        beq move_up
        jmp end_scroll
        branch_left_key:
            lda mario_x
            cmp #$78
            bpl move_left
            jmp decrease_scroll 
        branch_right_key:
            lda mario_x
            cmp #$78
            bmi move_right
            jmp increase_scroll
        increase_scroll:
            lda scrollx
            cmp #$ff
            beq move_right
            inc scrollx
            lda scrollx
            sta PPUSCROLL
            lda #$00
            sta PPUSCROLL
            jmp end_scroll
        decrease_scroll:
            lda scrollx
            cmp #$00
            beq move_left
            dec scrollx
            lda scrollx
            sta PPUSCROLL
            lda #$00
            sta PPUSCROLL
            jmp end_scroll
        move_up:
            lda mario_y
            cmp #$00
            beq end_scroll
            dec mario_y
            jmp end_scroll
        move_down:
            lda mario_y
            cmp #$DF
            beq end_scroll
            inc mario_y
            jmp end_scroll
        move_left:
            lda mario_x
            cmp #$00
            beq end_scroll
            dec mario_x
            jmp end_scroll
        move_right:
            lda mario_x
            cmp #$EF
            beq end_scroll
            inc mario_x
            jmp end_scroll
    end_scroll:
    inc do_update?   ; set to 1
    pla 
    rti 
irq:
rti

.goto $FFFA

.dw nmi
.dw start
.dw irq

.incbin "mario0.chr"
.incbin "aiv256.chr"