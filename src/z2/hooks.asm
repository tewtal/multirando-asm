optimize address ram

; This macro creates hooks in each bank since it's included multiple times
; Used to hook routines in the common bank (bank 7)
macro z2hook(addr, code)
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

; Hook the start and end of NMI to be able to inject code to NMI
%z2hook($C07B, "jmp NMIStart")
%z2hook($C1A8, "jmp NMIEnd")
%z2hook($C074, "jmp NMIEnd_Code1")

org ((!BASE_BANK+$5)<<16)+$A693 : jmp NMIEnd_Bank5

; Patch boot sequence
%z2hook($FF74, "jsr WritePPUCTRL_x")
%z2hook($FF78, "lda.w $4210")
%z2hook($FF80, "nop")


; Patch PPU_CTRL writes
%z2hook($C005, "jsr WritePPUCTRL")
%z2hook($C08E, "jsr WritePPUCTRL")
%z2hook($C0F3, "jsr WritePPUCTRL")
%z2hook($C4CD, "jsr WritePPUCTRL")
%z2hook($C4DA, "jsr WritePPUCTRL")
%z2hook($D320, "jsr WritePPUCTRL")
%z2hook($D4C5, "jsr WritePPUCTRL")


org ((!BASE_BANK+$5)<<16)+$8B7E : jsr WritePPUCTRL
org ((!BASE_BANK+$5)<<16)+$A619 : jsr WritePPUCTRL
org ((!BASE_BANK+$5)<<16)+$A665 : jsr WritePPUCTRL
org ((!BASE_BANK+$5)<<16)+$A69C : jsr WritePPUCTRL
org ((!BASE_BANK+$5)<<16)+$A6D5 : jsr WritePPUCTRL
org ((!BASE_BANK+$5)<<16)+$A754 : jsr WritePPUCTRL
org ((!BASE_BANK+$5)<<16)+$AB8A : jsr WritePPUCTRL


; Patch PPU_MASK writes
%z2hook($C002, "jsr WritePPUCTRL1")
%z2hook($C0AC, "jsr WritePPUCTRL1")
%z2hook($C105, "jsr WritePPUCTRL1")

org ((!BASE_BANK+$5)<<16)+$A620 : jsr WritePPUCTRL1
org ((!BASE_BANK+$5)<<16)+$A675 : jsr WritePPUCTRL1
org ((!BASE_BANK+$5)<<16)+$A6BB : jsr WritePPUCTRL1

; Patch PPU_STATUS reads
%z2hook($D4B2, "bit.w $4210")
org ((!BASE_BANK+$5)<<16)+$A73D : bit.w $4210
org ((!BASE_BANK+$5)<<16)+$A767 : lda.w $4210
org ((!BASE_BANK+$5)<<16)+$AB73 : bit.w $4210

; Hook MMC1 Bank switch Routines
%z2hook($FFCC, "jsr MMCWriteReg3 : rts")
%z2hook($FF9D, "sta z2_CurMMC1Control : jsl EmulateMMC1 : rts")

%z2hook($C0D9, "jsr SnesTransferTileBuf")
org ((!BASE_BANK+$5)<<16)+$A650 : jsr SnesTransferTileBuf