; Super Metroid SA-1 patch
;

!SRAM_BANK = #$0080
!SRAM_BASE = $806000	; Select where SRAM is mapped to (default is a0:6000-7FFF)

; Patch out copy protection
org $808000
    db $ff

;========================== SRAM Load/Save Repoint ===============================

org $808257
	sta !SRAM_BASE+$1fe0,x

org $80828a
	sta !SRAM_BASE+$1fe0,x

org $808297
	lda !SRAM_BASE+$1fe0,x

org $808698
	lda !SRAM_BASE,x
	
org $8086aa
	sta !SRAM_BASE,x
	
org $8086b8
	sta !SRAM_BASE,x
	
org $8086c7
	cmp !SRAM_BASE,x

org $8086d9
	sta !SRAM_BASE,x
	
org $818056
	sta !SRAM_BASE,x
	
org $81806c
	sta !SRAM_BASE,x
	sta !SRAM_BASE+$1ff0,x
	eor #$ffff
	sta !SRAM_BASE+$0008,x
	sta !SRAM_BASE+$1ff8,x

org $8180a0
	lda !SRAM_BASE,x
	
org $8180b9
	cmp !SRAM_BASE,x

org $8180c2
	cmp !SRAM_BASE+$0008,x
	
org $8180cc
	cmp !SRAM_BASE+$1ff0,x
	
org $8180d5
	cmp !SRAM_BASE+$1ff8,x
	
org $81810b
	sta !SRAM_BASE,x
		
org $819ed8
	lda !SRAM_BASE+$1fec
	
org $819ee7
	and !SRAM_BASE+$1fee
	
org $819ccb
	sta !SRAM_BASE,x
	sta !SRAM_BASE+$0008,x
	sta !SRAM_BASE+$1ff0,x
	sta !SRAM_BASE+$1ff8,x

org $81a23c
	sta !SRAM_BASE+$1fec

org $81a243
	sta !SRAM_BASE+$1fee

org $819a3b
	lda !SRAM_BANK

org $819a58
	ldy #$6000

org $819a61
	cpy #$665c

org $819a6b
	lda !SRAM_BASE+$1ff0,x
	pha
	lda !SRAM_BASE+$1ff8,X
	pha
	lda !SRAM_BASE,x
	pha
	lda !SRAM_BASE+$0008,x
	pha

org $819a85
	sta !SRAM_BASE+$0008,x
	pla
	sta !SRAM_BASE,x
	pla
	sta !SRAM_BASE+$1ff8,x
	pla
	sta !SRAM_BASE+$1ff0,x

org $819ca4
	lda !SRAM_BANK

org $819cb4
	ldy #$6000

org $819cbe
	cpy #$665c


;==================================================================================
	

;========================== Music/SFX Bank Loading ===============================
org $808044			; Patch music loading code to load from full HiROM banks
	jmp recalc_addr
		
org $808101			; These patches adjusts the music loading to wrap to next bank
	beq nextbank	; at 0x8000
org $808104		
	beq nextbank
	
org $808107
nextbank:
	
org $80810d			; Start at $0000 in the new bank and not $8000
	ldy #$0000
	; nop : nop : nop
;==================================================================================


;=========================== Decompression routines ===============================
org $80b266							; Modify the bank wrapping routine to detect if
	jmp wrap_bank					; bank >= $c0 and in that case wrap at $8000
									
org $80b123							; Check the starting bank and if it's >= $c0
	jmp modify_address_ram			; then subtract $8000 from the starting address
	
org $80b27b
	jmp modify_address_vram

;==================================================================================


;================================ Hud fixes ========================================
org $809b4a
	jmp fix_hud_digits	; Make HUD digits load from bank 80 instead of 00
;==================================================================================


;============================== New hook routines =================================	
org $80fc00

recalc_addr:
	lda $02			; Load bank
	and #$01		; If odd, set high bit of 16-bit address
	bne .odd
					; Otherwise even, clear high bit
	rep #$20		
	lda $00
	and #$7FFF
	tay
	bra .bank
.odd
	rep #$20
	lda $00
	ora #$8000
	tay
.bank
	sep #$20
	lda $02
	sec
	sbc #$c0
	lsr
	clc
	adc #$c0
	sta $02
	jmp $8048

wrap_bank:
	pha
	phb
	pla
	cmp #$bf		; If bank >= $bf, set X to $0000, else $8000
	bcc +
	ldx #$0000
	jmp $b26a
+
	ldx #$8000
	jmp $b26a

modify_address_ram:	
	pha
	lda $49
	cmp #$c0		; IF bank >=$c0, set to lower address space
	bcc .end

	and #$01
	bne .odd

	rep #$20
	lda $47
	and #$7fff
	sta $47
	bra .bank

.odd
	rep #$20
	lda $47
	ora #$8000
	sta $47

.bank	
	sep #$20
	lda $49
	sec
	sbc #$c0
	lsr
	clc
	adc #$c0
	sta $49
	pha
	plb
	
.end
	pla				; Restore A and execute hijacked code
	stz $50
	ldy #$0000
	jmp $b128	
	
modify_address_vram:	
	pha
	lda $49
	cmp #$c0		; IF bank >=$c0, set to lower address space
	bcc .end

	and #$01
	bne .odd

	rep #$20
	lda $47
	and #$7fff
	sta $47
	bra .bank

.odd
	rep #$20
	lda $47
	ora #$8000
	sta $47

.bank	
	sep #$20
	lda $49
	sec
	sbc #$c0
	lsr
	clc
	adc #$c0
	sta $49
	pha
	plb

.end
	pla				; Restore A and execute hijacked code
	stz $50
	ldy $4c
	jmp $b27f

fix_hud_digits:
	sep #$20
	lda #$80
	sta $02
	rep #$30
	jmp $9b4e
;==================================================================================
