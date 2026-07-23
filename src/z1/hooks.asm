optimize address ram

; This macro creates hooks in each bank since it's included multiple times
; Used to hook routines in the common bank (bank 7)
macro zhook(addr, code)
    !a #= !BASE_BANK
    while !a < (!BASE_BANK+8)
        if <addr> >= $C000
            !b #= <addr>+(!a*$10000)
            org !b
            <code>          ; for any other hook, use JML/JSL etc...
            !a #= !a+1
        else
            !b #= <addr>+(!a*$10000)
            org !b
            <code>          ; for any other hook, use JML/JSL etc...
            !a #= !a+1
        endif
    endif
endmacro

; Hook graphic tiles upload routines
org ((!BASE_BANK+1)<<16)+$8D5F : sta.w PPUAddrTmpHi
org ((!BASE_BANK+1)<<16)+$8D70 : jsr SnesTransferPatternBlock
org ((!BASE_BANK+2)<<16)+$802A : sta.w PPUAddrTmpHi
org ((!BASE_BANK+2)<<16)+$803B : jsr SnesTransferPatternBlock
org ((!BASE_BANK+3)<<16)+$8054 : jsr SnesTransferPatternBlock_Indexed
org ((!BASE_BANK+3)<<16)+$80DC : jsr SnesTransferPatternBlock_Indexed : rts

; Disable Sprite-0 wait for statusbar updates
org ((!BASE_BANK+5)<<16)+$8521 : jmp $8528

; Hook scrolling updates
%zhook($E506, "jsl UpdateScrollHDMA : jmp $e518")

; Horizontal scrolling during gameplay
org ((!BASE_BANK+5)<<16)+$8581 : jsl UpdateHScrollHDMA : rts

; Vertical scrolling during gameplay
org ((!BASE_BANK+5)<<16)+$8559 : jsl SnesUpdateVerticalGameScroll : rts
org ((!BASE_BANK+5)<<16)+$84D3 : jsr SnesResetVerticalGameScroll

; Pre-convert play-area attribute halves as soon as the dynamic transfer buffer
; is built, so NMI only has to upload the prepared SNES buffer.
org ((!BASE_BANK+5)<<16)+$8CA6 : jmp CueTransferPlayAreaAttrsHalfAndPrepareSnesBuffer : nop : nop : nop

; Hook the start and end of NMI to be able to inject code to NMI
%zhook($E484, "jmp NMIStart")
%zhook($E573, "jmp NMIEnd")

; Apply the SNES BG-priority replacement after vanilla tile-buffer transfers.
%zhook($E4C1, "jsr TransferCurTileBufAndApplyBGPriority")

; Hook MMC1 Bank switch Routine
%zhook($FFAC, "jsr MMCWriteReg3 : rts")
%zhook($BFAC, "jsr MMCWriteReg3 : rts")

; Hook MMC1 PPU mirroring
%zhook($FF98, "sta CurMMC1Control : jsl EmulateMMC1 : rts")
%zhook($BF98, "sta CurMMC1Control : jsl EmulateMMC1 : rts")

; Hook Clear Nametable
%zhook($E594, "jsl SnesClearNameTable : rts")

; Hook PPUCtrl ($2000) writes
%zhook($E456, "jsr WritePPUCTRL")
%zhook($E492, "jsr WritePPUCTRL")
%zhook($E515, "jsr WritePPUCTRL")
%zhook($E57A, "jsr WritePPUCTRL")
%zhook($E58E, "jsr WritePPUCTRL")
%zhook($E5A1, "jsr WritePPUCTRL")
%zhook($FF54, "jsr WritePPUCTRL")

; Hook PPUCtrl1 ($2001) writes
%zhook($E46A, "jsr WritePPUCTRL1")
%zhook($E4A5, "jsr WritePPUCTRL1")
%zhook($E627, "jsr WritePPUCTRL1AndResetScroll")

; Hook controller reading routine
%zhook($E62D, "jsl SnesReadInputs : rts")

; Mark bomb/cloud sprites so the SNES OAM converter can draw them above
; the priority doorway tiles.
%zhook($F9CB, "ldy #$08 : stz $0f")

; Hook TransferTileBuf writes (dynamic tilemap/attribute writes)
org ((!BASE_BANK+$6)<<16)+$A08C : jsr SnesTransferTileBuf

; ------------------------------------------------------------------------------
; Remove remaining NES PPU register accesses. $2000-$2007 are the MSU-1
; registers on the SNES ($2004/$2005 track select, $2006 volume, $2007
; control), so every surviving vanilla access corrupts MSU state, and the
; $2002 status polls spin forever on the constant MSU ID bytes. The SNES
; port replaces all of this PPU work (OAM DMA, scroll HDMA, VRAM uploads),
; so the vanilla accesses are simply removed. Registers/flags stay intact:
; every removed store/read is followed by a fresh load in the vanilla code.
; ------------------------------------------------------------------------------

; NMI body: OAMADDR reset, scroll reset, palette-latch $3F00 sequence, and
; the sprite-0 hit wait ($2002 bit 6 is always set in the MSU ID byte 'S',
; so the vanilla wait would hang every frame).
%zhook($E4AC, "nop : nop : nop")                                        ; STA $2003
%zhook($E4B6, "nop : nop : nop : nop : nop : nop")                      ; STA $2005 x2
%zhook($E4C6, "nop : nop : nop")                                        ; STA $2006
%zhook($E4CB, "nop : nop : nop : nop : nop : nop : nop : nop : nop")    ; STA $2006 x3
%zhook($E4D4, "nop : nop : nop : nop : nop : nop : nop : nop : nop : nop") ; sprite-0 wait + LDA $2002

; InitializeAllScrolling: raw scroll writes ($FD/$FC shadows remain).
%zhook($E582, "nop : nop : nop")                                        ; STA $2005
%zhook($E587, "nop : nop : nop")                                        ; STA $2005

; Orphaned nametable-fill helper at $E59A (no remaining callers, but its
; PPU stores are neutralized in case a stray path still enters it).
%zhook($E59A, "nop : nop : nop")                                        ; LDA $2002
%zhook($E5A8, "nop : nop : nop")                                        ; STA $2006
%zhook($E5AD, "nop : nop : nop")                                        ; STY $2006
%zhook($E5BC, "nop : nop : nop")                                        ; STA $2007
%zhook($E5CF, "nop : nop : nop")                                        ; STA $2006
%zhook($E5D4, "nop : nop : nop")                                        ; STA $2006
%zhook($E5D9, "nop : nop : nop")                                        ; STY $2007

; Reset stub: the two PPU warm-up vblank waits poll $2002 bit 7, which is
; always clear in the MSU ID byte, hanging the boot. No warm-up is needed.
%zhook($FF5A, "nop : nop : nop : nop : nop : nop : nop : nop : nop : nop : nop : nop : nop : nop")

; Status-bar/scroll code (bank 5): PPUCTRL nametable-select and scroll
; writes; the $FF shadow (PPUCNT0ZP) is already updated right before each,
; and the port derives scroll/layer state from the shadows via HDMA.
org ((!BASE_BANK+5)<<16)+$8528 : nop : nop : nop    ; LDA $2002 (discarded)
org ((!BASE_BANK+5)<<16)+$857E : nop : nop : nop    ; STA $2000
org ((!BASE_BANK+5)<<16)+$8588 : nop : nop : nop    ; STA $2005
org ((!BASE_BANK+5)<<16)+$8599 : nop : nop : nop    ; STA $2000
org ((!BASE_BANK+5)<<16)+$A8B8 : nop : nop : nop    ; STA $2000

; CHR upload preambles (banks 1-3): $2002 latch-reset reads, value unused.
org ((!BASE_BANK+1)<<16)+$8D4A : nop : nop : nop    ; LDA $2002
org ((!BASE_BANK+2)<<16)+$8015 : nop : nop : nop    ; LDA $2002
org ((!BASE_BANK+3)<<16)+$8047 : nop : nop : nop    ; LDA $2002
