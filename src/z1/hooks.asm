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

; Hook Init mode 4 for setting up after entering a dungeon
; 858824  20 13 70       JSR $7013
org ((!BASE_BANK+5)<<16)+$8824 : jsr InitMode_EnterRoom_UW_Hook

; Hook the start and end of NMI to be able to inject code to NMI
%zhook($E484, "jmp NMIStart")
%zhook($E573, "jmp NMIEnd")

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

; Hook TransferTileBuf writes (dynamic tilemap/attribute writes)
org ((!BASE_BANK+$6)<<16)+$A08C : jsr SnesTransferTileBuf

; Sound engine hooks

!B0 = ((!BASE_BANK)<<16)
!B7 = ((!BASE_BANK+$7)<<16)

; Patch APU status calls
org !B0+$982B : jsr WriteAPUControl
; org !B0+$9830 : sta $0915
org !B0+$9928 : jsr WriteAPUControl
org !B0+$9BA6 : jsr WriteAPUControl
; org !B0+$9BE1 : sta $0915
org !B0+$9D4B : jsr WriteAPUControl
; org !B0+$9D5C : sta $0915
org !B7+$E467 : jsr WriteAPUControl

; Hook writes to Square Wave Channel 1
org !B0+$9900 : jsr WriteAPUSq0Ctrl0_X
org !B0+$9911 : jsr WriteAPUSq0Ctrl0
org !B0+$9C06 : jsr WriteAPUSq0Ctrl0_X
org !B0+$9E01 : jsr WriteAPUSq0Ctrl0

org !B0+$9922 : jsr WriteAPUSq0Ctrl1
org !B0+$9C03 : jsr WriteAPUSq0Ctrl1_Y
org !B0+$9E16 : jsr WriteAPUSq0Ctrl1

org !B0+$990A : jsr WriteAPUSq0Ctrl2_X
org !B0+$9C15 : jsr WriteAPUSq0Ctrl2
org !B0+$9E11 : jsr WriteAPUSq0Ctrl2_X

org !B0+$9905 : jsr WriteAPUSq0Ctrl3_X
org !B0+$9C1D : jsr WriteAPUSq0Ctrl3


; Hook writes to Square Wave Channel 2
org !B0+$9B14 : jsr WriteAPUSq1Ctrl0_X
org !B0+$9B3C : jsr WriteAPUSq1Ctrl0
org !B0+$9B57 : jsr WriteAPUSq1Ctrl0
org !B0+$9C21 : jsr WriteAPUSq1Ctrl0_X
org !B0+$9D96 : jsr WriteAPUSq1Ctrl0

org !B0+$9B37 : jsr WriteAPUSq1Ctrl1
org !B0+$9C24 : jsr WriteAPUSq1Ctrl1_Y
org !B0+$9D9B : jsr WriteAPUSq1Ctrl1_X

org !B0+$9B21 : jsr WriteAPUSq1Ctrl2_X
org !B0+$9B61 : jsr WriteAPUSq1Ctrl2_X
org !B0+$9C33 : jsr WriteAPUSq1Ctrl2
org !B0+$9DAB : jsr WriteAPUSq1Ctrl2_X

org !B0+$9B19 : jsr WriteAPUSq1Ctrl3_X
org !B0+$9C3B : jsr WriteAPUSq1Ctrl3

; Hook writes to Triangle Channel
org !B0+$9E5D : jsr WriteAPUTriCtrl0
org !B0+$9E92 : jsr WriteAPUTriCtrl0

org !B0+$9C48 : jsr WriteAPUTriCtrl2
org !B0+$9E84 : jsr WriteAPUTriCtrl2_X

org !B0+$9C50 : jsr WriteAPUTriCtrl3

; Hook writes to Noise Channel
org !B0+$997B : jsr WriteAPUNoiseCtrl0
org !B0+$9989 : jsr WriteAPUNoiseCtrl0
org !B0+$9A2A : jsr WriteAPUNoiseCtrl0
org !B0+$9EC4 : jsr WriteAPUNoiseCtrl0

org !B0+$9971 : jsr WriteAPUNoiseCtrl2
org !B0+$99F4 : jsr WriteAPUNoiseCtrl2_X
org !B0+$9A2F : jsr WriteAPUNoiseCtrl2_X
org !B0+$9ECA : jsr WriteAPUNoiseCtrl2

org !B0+$9980 : jsr WriteAPUNoiseCtrl3
org !B0+$9A34 : jsr WriteAPUNoiseCtrl3
org !B0+$9ED0 : jsr WriteAPUNoiseCtrl3

;  Hook writes to DMC
org !B0+$9bb7 : jsr WriteAPUDMCCounter
org !B0+$9bcf : jsr WriteAPUDMCFreq
org !B0+$9bd5 : jsr WriteAPUDMCAddr
org !B0+$9bdb : jsr WriteAPUDMCLength
org !B0+$9bea : jsr WriteAPUDMCPlay