; Super Metroid adapter for the quad-wide MSU service. Physical tracks follow
; SMZ3: semantic SM track N is PCM track 100+N. Track 141 is the additional
; storm-without-music variant used by the map randomizer implementation.

!SM_MSU_STATUS = $002000
!SM_MSU_CONTROL = $002007
!SM_SPC_IO0 = $002140
!SM_REQUESTED_MUSIC = $063D
!SM_CURRENT_MUSIC = $064C
!SM_MUSIC_BANK = $07F3
!SM_SPC_MUTE_CODE = $B210
!SM_SPC_MUTE_STATE = $0D
!SM_SPC_MUTED_TRACK = $40

org $808F27
    jsr MSU_Main

org $808F0C
    jml MSU_PollHook
    nop : nop

org $80DA00

MSU_PollHook:
    ; Preserve the exact vanilla contract at $808F0C: the original routine
    ; pushes P, switches A to 16-bit, and leaves A untouched before DEC.  The
    ; continuation at $808F12 can branch into code that still consumes A.
    php
    rep #$20
    pha
    jsl mb_MSU_Service
    sep #$20
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_SM : bne .idle
    lda.l !MSU_STATE
    cmp.b #!MSU_STATE_MISSING : beq .fallback
    cmp.b #!MSU_STATE_ERROR : bne .idle

    ; A cached-present file disappeared. Restart the original unmuted SPC song
    ; and restart SM's eight-frame music downtime window.
.fallback:
    lda.l !MSU_EXPECTED_SPC
    and.b #$3F
    sta.l !SM_SPC_IO0
    lda.b #$00
    sta.l !MSU_EXPECTED_SPC
    sta.l !MSU_NATIVE_MUTE
    lda.b #!MSU_STATE_IDLE : sta.l !MSU_STATE
    rep #$20
    lda.w #$0008 : sta.w $0686
.idle:
    rep #$20
    pla
    dec $063F
    jml $808F12

MSU_Main:
    php : phb
    rep #$30
    pha : phx : phy
    sep #$30
    lda.b #$80 : pha : plb

    lda.l !MSU_PRESENT : bne + : jmp .original
+   lda.w !SM_REQUESTED_MUSIC
    and.b #$7F
    beq .stop

    ; $04 is ambience except during the game-over mode, where SMZ3 track 140
    ; is used.
    cmp.b #$04 : bne +
    lda.w $0998 : cmp.b #$1A : bne .stop
    lda.b #40
    tay
    bra .try_base
+
    cmp.w !SM_CURRENT_MUSIC : beq .exit
    cmp.b #$05 : bmi .mapped

    sec : sbc.b #$05 : tay
    lda.w !SM_MUSIC_BANK
    ldx.b #$00
    sec
-   sbc.b #$03
    bcc +
    inx
    bra -
+   txa : asl : tax
    rep #$20
    lda.l MSU_MusicMappingPointers,x : sta.b $00
    sep #$20
    lda ($00),y
    beq .stop
.mapped:
    tay
    cpy.b #03 : beq .save_resume
    cpy.b #19 : beq .save_resume
    cpy.b #22 : beq .save_resume
    cpy.b #23 : beq .save_resume
    cpy.b #24 : bne .try_extended
.save_resume:
    jsl mb_MSU_SaveResume
.try_extended:
    jsr MSU_SelectExtended
.try_base:
    jsr MSU_TryTrack
    beq .exit

.stop:
    jsl mb_MSU_Stop
.original:
    rep #$30
    ply : plx : pla
    plb : plp
    sta.w $2140
    rts
.exit:
    rep #$30
    ply : plx : pla
    plb : plp
    rts

; Select an extended track when one applies, otherwise return Y.
MSU_SelectExtended:
    ldx.b #$00
    rep #$20
    lda $079B
    cpy.b #10 : beq .samus
    cpy.b #19 : beq .boss1
    cpy.b #22 : beq .boss2
    cpy.b #23 : beq .tension
    bra .return
.samus:
    cmp.w #$DD58 : bne +
    ldx.b #39
+   bra .return
.boss1:
    cmp.w #$DA60 : bne +
    ldx.b #35
+   cmp.w #$B32E : bne .return
    ldx.b #36
    bra .return
.boss2:
    sep #$20
    lda $079F : tax
    lda.l MSU_BossTwoExtended,x : tax
    bra .return8
.tension:
    sep #$20
    lda $079F : tax
    lda.l MSU_TensionExtended,x : tax
    bra .return8
.return:
    sep #$20
.return8:
    txa
    bne .selected
    tya
.selected:
    rts

; A8 = semantic SM track, Y8 = generic track used for loop policy.
; Returns zero when queued, nonzero when no fallback is available.
MSU_TryTrack:
    pha
    jsr MSU_TrackControl
    sta.l !MSU_REQUEST_CONTROL
    pla
    rep #$20
    and.w #$00FF
    clc : adc.w #$0064
    pha
    sep #$20
    lda.b #!MSU_OWNER_SM : sta.l !MSU_OWNER
    lda.w !SM_REQUESTED_MUSIC
    and.b #$3F
    ora.b #!SM_SPC_MUTED_TRACK
    sta.l !MSU_EXPECTED_SPC
    rep #$20
    pla
    jsl mb_MSU_Request
    bcs .missing

    sep #$20
    lda.b #$01 : sta.l !MSU_NATIVE_MUTE
    lda.l !MSU_EXPECTED_SPC : sta.w $2140
    lda.b #$00
    rts
.missing:
    sep #$20
    lda.b #$00 : sta.l !MSU_EXPECTED_SPC
    lda.b #$08
    rts

MSU_TrackControl:
    cpy.b #01 : beq .one_shot
    cpy.b #02 : beq .one_shot
    cpy.b #29 : beq .one_shot
    cpy.b #30 : beq .one_shot
    lda.b #$03
    rts
.one_shot:
    lda.b #$01
    rts

MSU_MusicMappingPointers:
    dw .bank00,.bank03,.bank06,.bank09,.bank0C,.bank0F,.bank12,.bank15
    dw .bank18,.bank1B,.bank1E,.bank21,.bank24,.bank27,.bank2A,.bank2D
    dw .bank30,.bank33,.bank36,.bank39,.bank3C,.bank3F,.bank42,.bank45,.bank48
.bank00: db 04,05,00
.bank03: db 04,05
.bank06: db 06,41,07
.bank09: db 08,09
.bank0C: db 10
.bank0F: db 11
.bank12: db 12
.bank15: db 13
.bank18: db 14
.bank1B: db 15,16
.bank1E: db 17,00
.bank21: db 18
.bank24: db 19,21,20
.bank27: db 22,23
.bank2A: db 24
.bank2D: db 00,25,00,00
.bank30: db 26,27
.bank33: db 00
.bank36: db 28
.bank39: db 29
.bank3C: db 30
.bank3F: db 00
.bank42: db 00
.bank45: db 22,23
.bank48: db 10

MSU_BossTwoExtended:
    db 00,32,00,34,00,38
MSU_TensionExtended:
    db 00,31,00,33,00,37

warnpc $80DD00

; Extend the uploaded SM SPC command handler. Bit 6 requests silent music
; sequencing while leaving SPC sound effects audible.
;
; The map randomizer reference addresses assume the vanilla audio layout
; (engine block at $CF:8108, ARAM $B210 image at $D0:9439). This base packs
; the vanilla 64KB audio banks $C0+n into 32KB halves of bank $C0+n/2 (see
; recalc_addr in sa1rom.asm), so the engine block (ARAM $1500) is at $C7:8108
; and the ARAM $B210 bytes of the boot sample block ($6E00 @ $C7:D029+4) are
; at $C8:1439.
org $C78108+($1799-$1500)
    db $5F
    dw !SM_SPC_MUTE_CODE

pushpc
org $C81439
arch spc700
base !SM_SPC_MUTE_CODE
MSU_SPCMuteHandler:
    CMP A,#$F0
    BNE +
        JMP $1750
+   CMP A,#$F1
    BEQ .original
    CMP A,#$FF
    BEQ .original
    BBC6 $00,.unmuted
    CMP Y,$00
    BEQ .continue
    MOV A,!SM_SPC_MUTE_STATE
    BNE .load_muted
    MOV A,#$E8
    MOV $1E15,A
    MOV A,#$00
    MOV $1E16,A
    MOV !SM_SPC_MUTE_STATE,#$01
.load_muted:
    MOV A,$00
    PUSH A
    AND A,#$3F
    CALL $1740
    POP A
    MOV $04,A
    RET
.unmuted:
    MOV A,!SM_SPC_MUTE_STATE
    BEQ .original
    MOV A,#$CF
    MOV $1E15,A
    MOV A,#$DD
    MOV $1E16,A
    MOV !SM_SPC_MUTE_STATE,#$00
.original:
    MOV A,$00
    JMP $179D
.continue:
    JMP $17A9
warnpc $B515
arch 65816
pullpc
