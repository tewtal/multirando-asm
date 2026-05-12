optimize address ram

; This macro creates hooks in each bank since it's included multiple times
macro hook(addr, code)
    !a #= !BASE_BANK
    while !a < (!BASE_BANK+7)
        if <addr> >= $C000
            !b #= <addr>+(!a*$10000)
            org !b
            <code>          ; for any other hook, use JML/JSL etc...
            !a #= !a+1
        else
            if !a != (!BASE_BANK+6)
                !b #= <addr>+(!a*$10000)
                org !b
                <code>          ; for any other hook, use JML/JSL etc...
            endif
            !a #= !a+1
        endif
    endif
endmacro

; Hook NMI start/end
%hook($C0D9, "jmp NMIStart")
%hook($C10D, "jmp NMIEnd")

; Hook NMIOn routine to read from RDNMI instead of PPUStatus
%hook($C487, "lda.w $4210")

; Patch all copies of the MMC register write routine
%hook($C4FA, "jml MMCWriteReg3")

; Patch MMC register writes for mirroring
%hook($C4B6, "jsl SetPPUMirror : rts")

; Patch all writes to PPUCTRL0 in Bank 7 (STA $2000)
%hook($C08C, "jsr WritePPUCTRL")
%hook($C17E, "jsr WritePPUCTRL")
%hook($C321, "jsr WritePPUCTRL")
%hook($C44F, "jsr WritePPUCTRL")
%hook($C46A, "jsr WritePPUCTRL")
%hook($C474, "jsr WritePPUCTRL")
%hook($C481, "jsr WritePPUCTRL")
%hook($C7CA, "jsr WritePPUCTRL")
%hook($C885, "jsr WritePPUCTRL")
%hook($FFB4, "jsr WritePPUCTRL")

; Patch all write to PPUCTRL1 in Bank 7 (STA $2001)
%hook($C454, "jsr WritePPUCTRL1")
%hook($FFB7, "jsr WritePPUCTRL1")

; Patch startup to not trash the stack
%hook($C03E, "nop")

; Hook ProcessPPUString so that it can upload data converted to SNES format
%hook($C30C, "jsl ProcessPPUString : jmp $C29A")    ;  return-jumps to prg $69429A

; Hook GFXCopyLoop that uploads tile data
%hook($C7D5, "jsl GFXCopyLoop : rts")

; Hook ClearNameTable
%hook($C158, "jsl ClearNameTable : rts")

; Hook routine for uploading nametables to VRAM when starting a game
%hook($C88B, "jsl UploadStartTilemap : jmp $C8A4")

; Call the SNES OAM DMA routine instead of triggering NES OAM DMA
%hook($C0DF, "jsl SnesOamDMA : jmp $C0E9")

; Hook WriteScroll
%hook($C29A, "jsl WriteScroll : rts")

; Hook into "Wait for NMI", so routines can be execute at the end of frame processing before NMI
; LC0C7:	lda #$00			;
; LC0C9:	sta NMIStatus		; Wait for next NMI to end.
%hook($C0C7, "jsl SnesProcessFrame")

; Hook code that creates PPU strings outside of the regular gameplay modes
%hook($C20E, "jsl PreparePPUProcess")

; The title screen uses this routine instead of the common one
org (!BASE_BANK<<16)+$9449
    jsl PreparePPUProcess