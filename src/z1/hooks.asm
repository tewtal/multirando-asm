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
