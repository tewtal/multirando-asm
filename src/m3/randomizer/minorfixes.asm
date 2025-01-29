;Fix music coming into the maridia portal
org $8FD924
    db $1B, $05

;Fix for escape bomb block softlock by Capn
;Hijack the door ASM
org $8fe4cf
	jsr NewShaftDoorASM
	rts

;Free space at ec00
org $8fec00
NewShaftDoorASM:
	;Start with Original ASM functions
	php
	%a8()
	lda #$01
	sta $7ecd38
	lda #$00
	sta $7ecd39
	;Set all blocks in RAM to air
	;Got lucky here that asm code is done after tile loading ^_^
	%a16()
	lda #$00ff
	sta $7f3262
	sta $7f3264
	sta $7f32c2
	sta $7f32c4
	sta $7f3322
	sta $7f3324
	sta $7f3382
	sta $7f3384
	plp
	rts


; During horizontal door transitions, the "ready for NMI" flag is set by IRQ at the bottom of the door as an optimisation,
; but the PLM drawing routine hasn't necessarily finished processing yet.
; The Kraid quick kill vomit happens because NMI actually interrupts the PLM drawing routine for the PLM that clears the spike floor,
; *whilst* it's in the middle of writing entries to the $D0 table, which the NMI processes.

; This fix simply clears this NMI-ready flag for the duration of the PLM drawing routine.
; Place this into the freespace after the free space used by items.asm
org $84fe00

drawPlmSafe:
{
lda.w $05B4 : pha ; Back up NMI ready flag
stz.w $05B4 ; Not ready for NMI
jsr $8DAA   ; Draw PLM
pla : sta.w $05B4 ; Restore NMI ready flag
rts

warnpc $84feff
}

; Patch calls to draw PLM
org $84861a ; End of PLM processing. Probably the only particularly important one to patch
jsr drawPlmSafe

; org $c48b50 ; End of block respawn instruction. Shouldn't need patching
; base $848b50
; jsr drawPlmSafe

org $84e094 ; End of animated PLM drawing instruction. Could theoretically happen...
jsr drawPlmSafe




org $cf6000
NewMapRoomLevelData:
db $0A, $00, $02, $40, $89, $21, $89, $22, $89, $41, $89, $42, $43, $89, $2A, $00
db $8D, $C7, $04, $C7, $14, $06, $41, $89, $20, $89, $01, $89, $02, $C8, $20, $02
db $4D, $89, $4D, $C4, $24, $C7, $14, $02, $41, $89, $00, $C6, $28, $00, $42, $43
db $89, $0A, $04, $8D, $2D, $89, $2D, $8D, $C3, $08, $C3, $50, $C3, $58, $43, $40
db $89, $C3, $5C, $0B, $00, $89, $44, $89, $26, $8D, $25, $8D, $48, $89, $48, $8D
db $C3, $08, $02, $03, $8D, $40, $C4, $58, $43, $20, $89, $C3, $80, $01, $03, $89
db $4F, $FF, $00, $00, $03, $C4, $84, $02, $20, $81, $00, $C2, $80, $00, $04, $D0
db $1E, $C3, $2E, $C3, $18, $05, $40, $81, $40, $94, $0C, $C4, $57, $FF, $00, $07
db $0C, $C0, $40, $90, $60, $94, $2C, $D4, $D7, $20, $07, $2C, $D0, $60, $90, $60
db $9C, $2C, $DC, $D8, $20, $05, $D8, $60, $98, $40, $9C, $0C, $CA, $20, $03, $07
db $15, $07, $11, $CA, $60, $02, $D8, $40, $98, $43, $42, $81, $03, $01, $81, $04
db $81, $C3, $C0, $06, $28, $15, $0C, $85, $0B, $85, $28, $C4, $22, $02, $04, $85
db $01, $44, $85, $42, $00, $41, $C2, $20, $05, $21, $81, $22, $81, $03, $85, $C3
db $E2, $02, $47, $85, $4A, $C4, $08, $04, $03, $85, $22, $85, $21, $C4, $1C, $03
db $02, $81, $20, $81, $C3, $24, $00, $00, $43, $81, $05, $07, $85, $0D, $81, $0D
db $85, $26, $85, $25, $C5, $3A, $03, $85, $02, $85, $20, $C2, $3A, $00, $40, $C2
db $60, $00, $02, $C2, $66, $07, $0A, $81, $0A, $85, $4D, $81, $4D, $85, $C3, $08
db $01, $42, $85, $C3, $14, $01, $22, $85, $C5, $1C, $C3, $60, $00, $42, $43, $81
db $2A, $00, $85, $C7, $04, $01, $02, $85, $C3, $74, $00, $02, $C2, $84, $C5, $1C
db $C3, $86, $CB, $20, $00, $22, $C4, $60, $C3, $84, $E4, $60, $00, $00, $41, $2B
db $00, $01, $40, $01, $C2, $FD, $2A, $00, $03, $FF, $01, $00, $FE, $2B, $00, $03
db $FE, $01, $00, $FD, $24, $00, $00, $01, $C5, $37, $01, $FD, $01, $25, $00, $C2
db $07, $CC, $48, $E4, $49, $00, $00, $8E, $43, $01, $8F, $03, $05, $8E, $05, $86
db $43, $01, $87, $02, $05, $86, $05, $CF, $10, $00, $84, $43, $01, $85, $03, $05
db $84, $05, $80, $43, $01, $81, $01, $05, $80, $D0, $10, $00, $8A, $43, $01, $8B
db $03, $05, $8A, $05, $82, $43, $01, $83, $01, $05, $82, $D0, $10, $C7, $58, $00
db $88, $43, $01, $89, $01, $05, $88, $D0, $10, $C7, $58, $D7, $10, $CF, $48, $D7
db $58, $F8, $27, $48, $D7, $58, $97, $02, $03, $D7, $F8, $C7, $10, $C7, $F8, $C7
db $C8, $CF, $10, $C7, $58, $C7, $C8, $CF, $10, $C7, $58, $C7, $80, $CF, $10, $F8
db $27, $80, $97, $42, $03, $9F, $02, $03, $FF, $FF