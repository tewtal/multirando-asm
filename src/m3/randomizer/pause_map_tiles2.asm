; Super Metroid: second pause-map tile page (BG chars $300-$3FF)
;
; The pause screen setup ($82:8E97) loads BG chars $000-$1FF from $B68000
; (sm-maptiles.bin) and sprite tiles from $B6C000 into VRAM word $2000.
; Map Overhaul widened that sprite transfer to $3C00 bytes, which in this
; integration only copies tilemap/palette/config bytes from $B6E000+ into
; VRAM words $3000-$3DFF as garbage. Nothing renders from that page: the
; pause spritemaps all use tile numbers < $100 (OBJ page 1).
;
; This patch restores the vanilla $2000-byte sprite transfer and loads a real
; tile sheet (sm-maptiles2.bin) into VRAM words $3000-$3FFF instead: 256 4bpp
; BG chars $300-$3FF usable from the pause-map tilemap. The minimap sheet at
; $B8A000 is grown to 1024 tiles (see the $03FF mask in Minimap.asm), so a map
; data char $3xx renders on both the pause map and the HUD minimap.
;
; Bank $B8 layout (vanilla-empty bank):
;   $B88000-$B88FFF  this loader routine
;   $B89000-$B89FFF  Map Overhaul map construction code
;   $B8A000-$B8DFFF  sm-minimaptiles.bin (1024 x 2bpp)
;   $B8E000-$B8FFFF  sm-maptiles2.bin (256 x 4bpp)

; Map Overhaul (PauseScreenRoutines.asm) sets this transfer size to $3C00 to
; fill OBJ page 2; restore the vanilla sprite-tile transfer size. This file is
; included after map_overhaul so this write wins.
org $828EB1
    dw $2000

; Replace the sprite-transfer trigger (LDA #$02 : STA $420B) with our loader.
org $828EB3
    jsl sm_pause_load_map_tiles2 : nop

org $B88000
sm_pause_load_map_tiles2:
; Called from the pause setup VRAM loader; A is 8-bit here.
    lda.b #$02 : sta.w $420B    ; run the queued sprite-tile transfer
    lda.b #$00 : sta.w $2116
    lda.b #$30 : sta.w $2117    ; VRAM word $3000 (BG chars $300-$3FF)
    lda.b #$80 : sta.w $2115    ; word increment on $2119 write
    jsl $8091A9                 ; queue DMA channel 1 (inline parameters)
    db $01, $01, $18
    dl sm_maptiles2_gfx
    dw $2000
    lda.b #$02 : sta.w $420B    ; run it
    rtl
warnpc $B89000

org $B8E000
sm_maptiles2_gfx:
    incbin ../../data/sm-maptiles2.bin
warnpc $B90000
