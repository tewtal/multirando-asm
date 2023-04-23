; This file contains the boot code for both the SNES CPU and SA-1 CPU as well as vectors and ROM headers

; org $00ffc0
;     db "MOTHER BRAIN   "

; org $00ffd5
;     db $23, $35, $0D, $06, $00, $33, $00

org $00ffe6
    dw snes_brk

org $00ffea
    dw !IRAM_NMI

org $00ffee
    dw !IRAM_IRQ

org $00fffa
    dw !IRAM_NMI

org $00fffe
    dw !IRAM_IRQ

org $00ffec
    dw snes_reset

org $00fffc
    dw snes_reset

org $00ffa0
sa1_vectors:
    dw sa1_reset
    dw sa1_nmi
    dw sa1_irq

sa1_reset:
    jml init
sa1_nmi:
sa1_irq:
    rti

org $00fe00
snes_brk:
    jml snes_brk

snes_reset:
    sei
    clc
    xce
    rep #$38
    lda #$0000
    sta $4200
    tcd
    lda #$1fff
    tcs
    phk
    plb

    jsr sa1_setup
    jsr randomizer_setup
    jml snes_main

randomizer_setup:
    %a16()
    lda #$00ff
    sta !SRAM_CURRENT_GAME
    lda #$0000
    sta !SRAM_SAVING
    %a8()
    
    rts

sa1_setup:    
    sep #$20    ; Initialize SA-1 ROM Mapping    

    lda #$80
    sta $2222   ; Map LoROM banks 80-9F using first 1MB of ROM
    
    lda #$07
    sta $2223   ; Map HiROM banks F0-FF using the last 1MB of ROM

    lda #$80    ; Map LoROM banks 00-1F using first 1MB of ROM
    sta $2220   ; 

    lda #$80    ; Map LoROM banks 20-3F using first 1MB of ROM
    sta $2221                   

    lda #$02
    sta $2225   ; Set the fourth (6000-7FFF) region of BW-RAM to be used as game SRAM
	sta $2224

    lda #$80
    sta $2226

    lda #$00
    sta $2228

    lda #$ff
    sta $2229

    rep #$30
    lda sa1_vectors
    sta $2203
    lda sa1_vectors+2
    sta $2205
    lda sa1_vectors+4
    sta $2207

    rep #$30

	ldx #$0000		; Clear SA-1 IRAM
	lda #$0000
-
	sta $3000, x
	inx
	inx
	cpx #$0800
	bne -

	ldx #$0000		; Clear WRAM
-
	sta.l $7E0000, x
	inx
	inx
	cpx #$1f00
	bne -

	ldx #$2000		; Clear WRAM
-
	sta.l $7E0000, x
	inx
	inx
	bne -

	ldx #$0000		; Clear WRAM
-
	sta.l $7F0000, x
	inx
	inx
	bne -

    ldx #$0000
 -
    lda.l $FFE000, x
	sta.l $40E000, x
	inx
	inx
    cpx #$2000
	bne -   

    sep #$20
    lda #$00
    sta $2200   ; Bring the SA-1 out of reset
    rep #$30

    rts