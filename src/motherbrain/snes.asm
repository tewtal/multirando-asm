; The parts of Mother Brain that has to run on the SNES CPU
snes_main:
    ; Set things up for Zelda 1 for now
    ; sep #$20
    
    ; lda #$86
    ; sta $2222   ; Swap Z1 bank into $80-9F

    ; lda #$03
    ; sta $2224

    ; ; Set stack to be NES-compatible
    ; rep #$30
    ; ldx #$01FF
    ; txs

    ; ; Write Z1 NMI to I-RAM
    ; lda #$105c
    ; sta $0037f0

    ; lda #$0008
    ; sta $0037f2   

    ; ; Jump to metroid 1 init code
    ; sep #$30
    ; jml z1_SnesBoot

    ; Boot Zelda 3

    sep #$20
    
    lda #$84
    sta $2220
    sta $2222

    lda #$85
    sta $2221
    sta $2223

    lda #$01
    sta $2224

    rep #$30
    ldx #$1fff
    txs

    ; Write Z3 NMI to I-RAM
    lda #$c95c
    sta $37f0
    lda #$0080
    sta $37f2    

    ; Write Z3 IRQ to I-RAM
    lda #$d85c
    sta $37f4
    lda #$0082
    sta $37f6


    sep #$30
    jml $008000


    ; Boot SM
    ; sep #$20
    
    ; lda #$02
    ; sta $2220

    ; lda #$80
    ; sta $2222
    ; lda #$81
    ; sta $2223

    ; lda #$00
    ; sta $2224

    ; rep #$30
    ; ldx #$1fff
    ; txs

    ; ; Write SM NMI to I-RAM
    ; lda #$835c
    ; sta $37f0
    ; lda #$0095
    ; sta $37f2

    ; ; Write SM IRQ to I-RAM
    ; lda #$6a5c
    ; sta $37f4
    ; lda #$0098
    ; sta $37f6

    ; sep #$30
    ; jml $80841C


    

