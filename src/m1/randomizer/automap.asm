; ============================================================================
; Metroid 1 Automap renderer and persistent state
; ============================================================================

; The HUD buffer holds three BG3 rows. NMI copies them to VRAM when flagged;
; the minimap occupies columns 24-28.
!M1_HUD_VRAM_WORD = $5020           ; BG3 tilemap word address of HUD row 0 (byte $A040)
!M1_HUD_BYTES = $00C0               ; three full 32-tile rows
!M1_HUD_MINIMAP_OFFSET = $0030      ; HUD row 0, column 24 (VRAM byte $A070)

; Map words use the popup font palette; the renderer substitutes these palettes.
!M1_MAP_PAL_VISITED = $0400         ; BG3 palette 1 (CGRAM $04-$07): SM map pink
!M1_MAP_PAL_CURRENT = $0800         ; BG3 palette 2 (CGRAM $08-$0B): yellow
!M1_MAP_PAL_REVEALED = $1400        ; BG3 palette 5 (CGRAM $14-$17): map-tile blue

; Full-screen map view: one whole 32x32 BG3 screen composed at $7E8800 and
; DMA:d to tilemap screen 0. 256px of map rows in a 224px window -> 32px of
; vertical scroll range.
!M1_MAP_VIEW_VRAM_WORD = $5000
!M1_MAP_VIEW_BUFFER = $8800         ; word address within bank $7E
!M1_MAP_VIEW_BYTES = $0800
!M1_MAP_VIEW_VOFS_MAX = $0020

; SNES controller bits as read by M1MapReadPad (standard JOY1 layout)
!M1_PAD_UP = $0800
!M1_PAD_DOWN = $0400
!M1_PAD_X = $0040
!M1_PAD_L = $0020
!M1_PAD_R = $0010

; MapPos leads by one room while scrolling down or right. Correct that lead,
; then advance to the next room after Samus crosses the scroll midpoint.
; D must address the NES zero page. Exits with rep #$30.
; Out: A = cell index (row*32 + column).
M1MapComputePlayerCell:
    sep #$30
    ldx.b MapPosX                   ; X = player column
    ldy.b MapPosY                   ; Y = player row
    lda.b ScrollDir
    and.b #$02
    bne .horizontal
    lda.b ScrollY
    beq .combine                    ; aligned: MapPosY is the on-screen room
    lda.b ScrollDir
    cmp.b #$01                      ; 1 = scrolling down: MapPosY runs a room ahead
    bne +
    dey
+   lda.b ScrollY
    bpl .combine                    ; seam in the upper half: still the origin room
    iny
    bra .combine
.horizontal
    lda.b ScrollX
    beq .combine                    ; aligned: MapPosX is the on-screen room
    lda.b ScrollDir
    cmp.b #$03                      ; 3 = scrolling right: MapPosX runs a room ahead
    bne +
    dex
+   lda.b ScrollX
    bpl .combine
    inx
.combine
    rep #$30
    tya
    and.w #$001f
    asl #5
    pha
    txa
    and.w #$001f
    clc : adc $01,s                 ; cell = row*32 + column
    plx
    rts

; Runs each stable gameplay frame. Re-render the minimap and mark a cell
; visited when Samus enters it.
; Called with rep #$30, D = NES zero page, DB = a bank mirroring low WRAM.
M1MapTrackPlayer:
    jsl M1MapGetCurrentAreaIndex
    bcs .done                       ; not in a mapped area
    asl #10                         ; area * !M1_MAP_CELLS_PER_AREA
    pha
    jsr M1MapComputePlayerCell
    clc : adc $01,s                 ; A = area*$400 + cell, never $FFFF
    plx
    cmp.w m1_MapLastCell
    beq .done
    sta.w m1_MapLastCell
    jsl M1MapRenderMiniMap
.done
    rts

M1MapRenderMiniMap:
    pha
    phx
    phy
    php
    phb

    jsr M1MapComputePlayerCell     ; A = the cell Samus occupies (exits rep #$30)
    pea $7e7e : plb : plb
    sta.w m1_MiniMapCellTmp        ; Remember the player's cell for highlighting
    tax                            ; X = player cell

    jsl M1MapGetCurrentAreaIndex   ; Get current map area index into A
    sta.w m1_MiniMapAreaTmp
    stz.w m1_MiniMapIndexTmp

    ; Mark the current cell visited.
    jsl M1MapMarkVisited           ; A = area, X = player cell

    ; Precompute whether the whole area is revealed by a map station/item;
    ; unvisited cells then render in the dim blue palette instead of hiding
    lda.w m1_MiniMapAreaTmp
    jsl M1MapIsAreaRevealed
    cmp.w #$0001
    beq +
    lda.w #$0000
+   sta.w m1_MiniMapRevealedTmp

    lda.w m1_MiniMapCellTmp
    sec : sbc.w #(!M1_MAP_WIDTH+$02) ; Go one tile up and 2 left for the starting index
    tax

    ; $B7/$B8 belong to the NES game, so preserve them while borrowing the
    ; direct-page word as an indirect destination pointer.
    lda.b $b7
    pha
    lda.w #((MiniMapBuffer+!M1_HUD_MINIMAP_OFFSET)&$ffff)
    sta.b $b7

    ldy.w #$0000
.row_loop
    lda.w m1_MiniMapAreaTmp
    jsl M1MapIsVisited             ; Carry set when visited or invalid
    bcc .unvisited
    cmp.w #$ffff
    beq .blank                     ; Out-of-range cells (window past a map edge)

    lda.w m1_MiniMapAreaTmp
    jsl M1MapGetTile
    sta.w m1_MiniMapTileTmp
    and.w #!M1_MAP_TILE_CHARACTER_MASK
    cmp.w #!M1_MAP_BG3_TEXT_TILE_COUNT
    bcc .text_marker
    lda.w m1_MiniMapTileTmp
    and.w #(!M1_MAP_TILE_PALETTE_MASK^$ffff)
    cpx.w m1_MiniMapCellTmp
    beq .current
    ora.w #!M1_MAP_PAL_VISITED
    bra .store
.current
    ora.w #!M1_MAP_PAL_CURRENT
    bra .store
.unvisited
    lda.w m1_MiniMapAreaTmp
    jsl M1MapGetTile
    sta.w m1_MiniMapTileTmp
    and.w #!M1_MAP_TILE_CHARACTER_MASK
    cmp.w #!M1_MAP_BG3_TEXT_TILE_COUNT
    bcc .text_marker
    sec : sbc.w #!M1_MAP_BG3_MAPSTATION_TILE_BASE
    cmp.w #!M1_MAP_MAPSTATION_TILE_COUNT
    bcc .draw_dim                  ; Map stations always draw as a landmark
    lda.w m1_MiniMapRevealedTmp    ; Hidden unless the area has been revealed
    beq .blank
.draw_dim
    lda.w m1_MiniMapTileTmp
    and.w #(!M1_MAP_TILE_PALETTE_MASK^$ffff)
    ora.w #!M1_MAP_PAL_REVEALED
    bra .store
.text_marker
    lda.w m1_MiniMapTileTmp
    bra .store
.blank
    lda.w #$0000
.store
    sta.b ($b7)
    inc.b $b7 : inc.b $b7
    inx : iny
    cpy.w #$0005
    bne .row_loop
    lda.w m1_MiniMapIndexTmp
    inc
    cmp.w #$0003
    beq .done
    sta.w m1_MiniMapIndexTmp
    txa : clc : adc.w #(!M1_MAP_WIDTH-$05) : tax
    lda.b $b7 : clc : adc.w #((!M1_MAP_WIDTH-$05)*2) : sta.b $b7
    ldy.w #$0000
    jmp .row_loop

.done
    rep #$20
    pla
    sta.b $b7
    sep #$20
    lda.b #$01
    sta.w m1_HudRedraw              ; Queue the HUD transfer for the next NMI
    plb
    plp
    ply
    plx
    pla
    rtl

; Called from NMIStart (vblank). Bulk-copies the HUD tilemap buffer to the
; BG3 tilemap when the redraw flag is set, and drives the full-screen map
; view (its DMA, BG3 scroll, and the frame tick its frozen main-thread loop
; waits on). Long addressing throughout since the caller's DB is whatever
; NES bank was mapped when NMI fired.
M1MapHudTransfer:
    php
    sep #$20

    lda.l m1_MapViewActive
    beq +
    lda.l m1_MapViewVofs
    sta.l $002112
    lda.b #$00
    sta.l $002112
    lda.b #$01
    sta.l m1_MapViewTick
+
    ; The full-screen transfer runs first; the HUD rows may follow in the
    ; same vblank (used on close: blank the screen, then HUD back on top)
    lda.l m1_MapViewDMA
    beq .check_hud
    lda.b #$00
    sta.l m1_MapViewDMA

    lda.b #$80
    sta.l $002115
    rep #$20
    lda.w #!M1_MAP_VIEW_VRAM_WORD
    sta.l $002116
    lda.w #$1801
    sta.l $004320
    lda.w #!M1_MAP_VIEW_BUFFER
    sta.l $004322
    sep #$20
    lda.b #$7e
    sta.l $004324
    rep #$20
    lda.w #!M1_MAP_VIEW_BYTES
    sta.l $004325
    sep #$20
    lda.b #$04
    sta.l $00420b

.check_hud
    lda.l m1_HudRedraw
    beq .done
    lda.b #$00
    sta.l m1_HudRedraw

    lda.b #$80
    sta.l $002115                   ; VMAIN: increment word address after $2119
    rep #$20
    lda.w #!M1_HUD_VRAM_WORD
    sta.l $002116
    lda.w #$1801
    sta.l $004320                   ; CPU->PPU, write $2118/$2119 (channel 2, like the overlay)
    lda.w #(MiniMapBuffer&$ffff)
    sta.l $004322
    sep #$20
    lda.b #(MiniMapBuffer>>16)
    sta.l $004324
    rep #$20
    lda.w #!M1_HUD_BYTES
    sta.l $004325
    sep #$20
    lda.b #$04
    sta.l $00420b
.done
    plp
    rtl

; Upload the minimap palettes to CGRAM $04-$0B (BG3 palettes 1 and 2).
; Call during forced blank, alongside nes_overlay_init.
M1MapUploadPalettes:
    php
    phx
    sep #$30
    lda.b #$04
    sta.l $002121
    ldx.b #$00
.loop
    lda.l M1MapHudPalette,x
    sta.l $002122
    inx
    cpx.b #$10
    bne .loop
    lda.b #$14
    sta.l $002121
.loop2
    lda.l M1MapHudPalette,x
    sta.l $002122
    inx
    cpx.b #$18
    bne .loop2
    plx
    plp
    rtl

M1MapHudPalette:
    ; Palette 1 - visited: SM map pink fill, white walls, amber accents
    dw $0000, $48FB, $7FFF, $16FF
    ; Palette 2 - current cell: yellow fill, white walls, amber accents
    dw $0000, $037F, $7FFF, $16FF
    ; Palette 5 - revealed but unvisited: the map art's native blue/white/amber
    dw $0000, $6627, $779C, $16FF

; Clear the HUD tilemap buffer to blank tiles and queue a full redraw. Must
; run on every entry into M1 (cold boot and cross-game transition) since the
; other games are free to clobber this WRAM region.
M1MapClearHud:
    php
    phx
    rep #$30
    lda.w #$0000
    ldx.w #(!M1_HUD_BYTES-$02)
.clear
    sta.l MiniMapBuffer,x
    dex #2
    bpl .clear
    lda.w #$ffff
    sta.l m1_MapLastCell            ; force a render on the next tracked frame
    sep #$20
    lda.b #$01
    sta.l m1_HudRedraw
    plx
    plp
    rtl

; ============================================================================
; Full-screen map view
; ============================================================================

; Read SNES controller 1 from the hardware auto-poller. $4218/9 hold the same
; JOY1 word the old serial reader assembled by hand; waiting out an in-flight
; auto-read makes this safe both mid-frame and right after the NMI tick.
; Out: A (16-bit) = B,Y,Sel,Start,U,D,L,R,A,X,L,R,ssss (JOY1 layout).
M1MapReadPad:
    php
    sep #$20
-   lda.l $004212
    lsr
    bcs -
    rep #$20
    lda.l $004218
    plp
    rts

; Called once per frame from SnesProcessFrame (main thread, right before the
; NMI wait-loop). During stable gameplay this tracks the cell Samus occupies
; (re-rendering the minimap when it changes) and opens the full-screen map
; view when X is newly pressed.
M1MapViewFrame:
    pha
    phx
    phy
    php
    phb
    phk : plb
    rep #$30

    jsr M1MapReadPad
    pha
    eor.w m1_PadHeld
    and $01,s                       ; A = newly pressed buttons
    ply                             ; Y = current pad word
    sty.w m1_PadHeld
    tax                             ; X = newly pressed buttons

    sep #$20
    lda.b $1d                       ; GameMode: 0 = game running, 1 = intro
    bne .done
    lda.b $1e                       ; MainRoutine 3 = stable game engine
    cmp.b #$03
    bne .done
    rep #$20

    phx
    jsr M1MapTrackPlayer
    plx

    txa
    and.w #!M1_PAD_X
    beq .done

    jsr M1MapViewRun
.done
    plb
    plp
    ply
    plx
    pla
    rtl

; The modal map view. Runs with DB = this bank, D = 0. The game loop stays
; frozen in here; NMI keeps firing and handles music, the queued map DMAs,
; BG3 scroll, and the per-frame tick this loop waits on.
M1MapViewRun:
    rep #$30
    jsl M1MapGetCurrentAreaIndex
    bcc +
    rts                             ; not in a mapped area
+   sta.w m1_MapViewArea

    ; Cancel any active item popup; the map view owns BG3 (and its scroll) now
    lda.w #$0000
    sta.l nes_overlay_state
    sta.w m1_HudRedraw              ; Do not overlay pending HUD rows on the map DMA

    jsr M1MapViewCenter
    jsr M1MapViewCompose

    sep #$20
    lda.b #$01
    sta.w m1_MapViewActive
    ; BG3 color 0 stays transparent, so the map can sit over the dimmed game.
    ; Normal M1 OBJ palettes cannot use color math, so hide sprites in this
    ; modal view rather than leave them at full brightness.
    lda.b #$00
    sta.l $00212d                   ; No subscreen: use the fixed color
    lda.b #$00
    sta.l $002130                   ; Fixed color, never block color math
    lda.b #$20
    sta.l $002132                   ; Fixed-color red = 0
    lda.b #$40
    sta.l $002132                   ; Fixed-color green = 0
    lda.b #$80
    sta.l $002132                   ; Fixed-color blue = 0
    lda.b #$d1
    sta.l $002131                   ; Half-subtract BG1 and OBJ, leave BG3 bright
    lda.b #$09                      ; Mode 1 with BG3 priority over the gameplay layer
    sta.l $002105
    lda.b #$05                      ; BG1 + BG3; hide sprites during the map view
    sta.l $00212c
    rep #$20

.frame_loop
    sep #$20
    lda.b #$00
    sta.w m1_MapViewTick
-   lda.w m1_MapViewTick            ; wait for the next NMI
    beq -
    rep #$30

    jsr M1MapReadPad
    pha
    eor.w m1_PadHeld
    and $01,s                       ; A = newly pressed buttons
    ply                             ; Y = current pad word
    sty.w m1_PadHeld
    tax                             ; X = newly pressed buttons

    and.w #!M1_PAD_X                ; X closes the map
    bne .exit

    txa
    and.w #!M1_PAD_L                ; L = previous area
    beq +
    lda.w m1_MapViewArea
    dec
    bpl ++
    lda.w #(!M1_MAP_AREA_COUNT-1)
++  sta.w m1_MapViewArea
    jsr M1MapViewCenter
    jsr M1MapViewCompose
+   txa
    and.w #!M1_PAD_R                ; R = next area
    beq +
    lda.w m1_MapViewArea
    inc
    cmp.w #!M1_MAP_AREA_COUNT
    bcc ++
    lda.w #$0000
++  sta.w m1_MapViewArea
    jsr M1MapViewCenter
    jsr M1MapViewCompose
+
    tya
    and.w #!M1_PAD_UP               ; held up/down scroll the view
    beq +
    lda.w m1_MapViewVofs
    beq +
    dec #2
    sta.w m1_MapViewVofs
+   tya
    and.w #!M1_PAD_DOWN
    beq +
    lda.w m1_MapViewVofs
    cmp.w #!M1_MAP_VIEW_VOFS_MAX
    bcs +
    inc #2
    sta.w m1_MapViewVofs
+
    bra .frame_loop

.exit
    ; Blank BG3 with one full-screen transfer and re-queue the HUD rows on
    ; top; both land in the same vblank (map DMA runs first in the handler)
    jsr M1MapViewBlank
    sep #$20
    lda.b #$01
    sta.w m1_HudRedraw
    lda.b #$00
    sta.w m1_MapViewTick
-   lda.w m1_MapViewTick            ; let that final transfer land first
    beq -
    lda.b #$00
    sta.w m1_MapViewActive
    sta.l $002112                   ; BG3 scroll back to 0 for the HUD
    sta.l $002112
    sta.l $002130                   ; Restore normal M1 color math and subscreen state
    sta.l $002131
    sta.l $00212d
    lda.b #$09                      ; Mode 1 with M1's normal BG3 foreground priority
    sta.l $002105
    lda.b #$15                      ; BG1 + BG3 + sprites back on
    sta.l $00212c
    rep #$30
    rts

; Compute the compose translation and initial scroll for m1_MapViewArea.
; The player's own area centers on the player; other areas center their
; bounds rectangle. Both are clamped so no map content shifts off the grid,
; and dest row 0 is kept free for the area name whenever the area fits.
M1MapViewCenter:
    rep #$30
    lda.w m1_MapViewArea
    asl #2
    tax
    lda.l M1MapAreaBounds,x         ; minX | maxX<<8
    sta.w m1_MapViewBndX
    lda.l M1MapAreaBounds+$02,x     ; minY | maxY<<8
    sta.w m1_MapViewBndY

    ; Empty/default bounds ($FF,$00): no shift, neutral scroll
    sep #$20
    lda.w m1_MapViewBndX+$01        ; maxX
    cmp.w m1_MapViewBndX            ; < minX means empty
    rep #$20
    bcs .valid
    lda.w #$0000
    sta.w m1_MapViewShiftX
    sta.w m1_MapViewShiftY
    sta.w m1_MapViewVofs
    rts

.valid
    ; ---- horizontal: target column at dest col 16 ----
    lda.w m1_MapViewArea
    cmp.w m1_MiniMapAreaTmp
    bne .bounds_x
    lda.w m1_MiniMapCellTmp
    and.w #$001f                    ; player column
    bra .have_tx
.bounds_x
    lda.w m1_MapViewBndX
    and.w #$00ff
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewBndX
    xba : and.w #$00ff
    clc : adc.w m1_MapViewTgtTmp
    inc
    lsr                             ; bounds center column
.have_tx
    eor.w #$ffff : inc
    clc : adc.w #$0010              ; shiftX = 16 - target
    sta.w m1_MapViewShiftX
    lda.w m1_MapViewBndX
    and.w #$00ff
    eor.w #$ffff : inc              ; lower clamp: -minX
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewShiftX
    sec : sbc.w m1_MapViewTgtTmp
    bpl +
    lda.w m1_MapViewTgtTmp
    sta.w m1_MapViewShiftX
+   lda.w m1_MapViewBndX
    xba : and.w #$00ff
    eor.w #$ffff : inc
    clc : adc.w #$001f              ; upper clamp: 31 - maxX
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewShiftX
    sec : sbc.w m1_MapViewTgtTmp
    bmi +
    beq +
    lda.w m1_MapViewTgtTmp
    sta.w m1_MapViewShiftX
+
    ; ---- vertical: target row at dest row 15 ----
    lda.w m1_MapViewArea
    cmp.w m1_MiniMapAreaTmp
    bne .bounds_y
    lda.w m1_MiniMapCellTmp
    lsr #5                          ; player row
    bra .have_ty
.bounds_y
    lda.w m1_MapViewBndY
    and.w #$00ff
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewBndY
    xba : and.w #$00ff
    clc : adc.w m1_MapViewTgtTmp
    inc
    lsr                             ; bounds center row
.have_ty
    eor.w #$ffff : inc
    clc : adc.w #$000e              ; shiftY = 14 - target (center of the
    sta.w m1_MapViewShiftY          ; rows visible below the name at vofs 0)
    lda.w m1_MapViewBndY
    xba : and.w #$00ff
    eor.w #$ffff : inc
    clc : adc.w #$001f              ; upper clamp: 31 - maxY
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewShiftY
    sec : sbc.w m1_MapViewTgtTmp
    bmi +
    beq +
    lda.w m1_MapViewTgtTmp
    sta.w m1_MapViewShiftY
+   ; lower clamp: 1 - minY reserves dest row 0 for the area name; when an
    ; area is too tall for that, the upper clamp above already won
    lda.w m1_MapViewBndY
    and.w #$00ff
    eor.w #$ffff : inc
    inc                             ; 1 - minY
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewShiftY
    sec : sbc.w m1_MapViewTgtTmp
    bpl +
    lda.w m1_MapViewTgtTmp
    sta.w m1_MapViewShiftY
    lda.w m1_MapViewBndY
    xba : and.w #$00ff
    eor.w #$ffff : inc
    clc : adc.w #$001f
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewShiftY
    sec : sbc.w m1_MapViewTgtTmp
    bmi +
    beq +
    lda.w m1_MapViewTgtTmp
    sta.w m1_MapViewShiftY
+
    ; The view always opens scrolled fully up so the area name on dest row 0
    ; stays on screen; centering comes entirely from the compose translation,
    ; and down-panning is still available for areas taller than the window.
    lda.w #$0000
    sta.w m1_MapViewVofs
    rts

; Compose the 32x32 map view of m1_MapViewArea into the buffer, translated
; by the shifts from M1MapViewCenter, with the area name across dest row 0.
; Cell rules match the minimap: visited = pink (player's cell yellow),
; unvisited = blue when the area is revealed, hidden otherwise. The full view
; uses validated area bounds and direct ROM/visited-plane access so it does not
; pay the generic helper and input-validation cost for every map cell.
M1MapViewCompose:
    php
    phb
    phk : plb
    rep #$30

    lda.w m1_MapViewArea
    jsl M1MapIsAreaRevealed
    cmp.w #$0001
    beq +
    lda.w #$0000
+   sta.w m1_MiniMapRevealedTmp

    ; Start from a known blank screen and then visit only the area's bounding
    ; rectangle. Blank holes inside the bounds need no destination write.
    lda.w #$0000
    ldx.w #(!M1_MAP_VIEW_BYTES-$02)
.clear
    sta.l MapViewBuffer,x
    dex #2
    bpl .clear

    lda.w m1_MapViewArea
    asl #11                         ; $800 ROM bytes per area
    sta.w m1_MapViewTileBase
    lda.w m1_MapViewArea
    asl #7                          ; $80 visited bytes per area
    sta.w m1_MapViewVisitBase

    lda.w m1_MapViewBndX
    and.w #$00ff
    sta.w m1_MapViewSrcCol          ; min X (reset again at each row)
    lda.w m1_MapViewBndX
    xba : and.w #$00ff
    sta.w m1_MapViewMaxX
    cmp.w m1_MapViewSrcCol
    bcs +
    jmp .write_name                 ; empty/default bounds
+

    lda.w m1_MapViewBndY
    and.w #$00ff
    sta.w m1_MapViewSrcRow
    lda.w m1_MapViewBndY
    xba : and.w #$00ff
    sta.w m1_MapViewMaxY
    cmp.w m1_MapViewSrcRow
    bcs +
    jmp .write_name
+

.row
    lda.w m1_MapViewBndX
    and.w #$00ff
    sta.w m1_MapViewSrcCol

    ; Compute the byte offset of (source + compose shift) in the destination.
    lda.w m1_MapViewSrcRow
    clc : adc.w m1_MapViewShiftY
    asl #6
    sta.w m1_MapViewTgtTmp
    lda.w m1_MapViewSrcCol
    clc : adc.w m1_MapViewShiftX
    asl
    clc : adc.w m1_MapViewTgtTmp
    sta.w m1_MapViewDestTmp

.cell
    lda.w m1_MapViewSrcRow
    asl #5
    clc : adc.w m1_MapViewSrcCol    ; source cell = row*32 + col
    sta.w m1_MapViewSrcCell
    asl
    clc : adc.w m1_MapViewTileBase
    tax
    lda.l M1MapTilemaps,x
    bne +
    jmp .next                       ; blank hole inside the bounds
+
    sta.w m1_MapViewTileTmp
    and.w #!M1_MAP_TILE_CHARACTER_MASK
    cmp.w #!M1_MAP_BG3_TEXT_TILE_COUNT
    bcc .text_marker
    lda.w m1_MapViewTileTmp
    and.w #(!M1_MAP_TILE_PALETTE_MASK^$ffff)
    sta.w m1_MapViewTileTmp

    lda.w m1_MapViewSrcCell
    and.w #$0007
    tax
    sep #$20
    lda.l M1MapVisitedBitMasks,x
    sta.w m1_MapViewMaskTmp
    rep #$20
    lda.w m1_MapViewSrcCell
    lsr #3
    clc : adc.w m1_MapViewVisitBase
    tax
    sep #$20
    lda.w !M1_MAP_VISITED_BASE,x
    and.w m1_MapViewMaskTmp
    beq .unvisited

    rep #$20
    lda.w m1_MapViewArea
    cmp.w m1_MiniMapAreaTmp         ; highlight only within the player's area
    bne .visited
    lda.w m1_MapViewSrcCell
    cmp.w m1_MiniMapCellTmp
    bne .visited
    lda.w m1_MapViewTileTmp
    ora.w #!M1_MAP_PAL_CURRENT
    bra .store
.visited
    lda.w m1_MapViewTileTmp
    ora.w #!M1_MAP_PAL_VISITED
    bra .store
.text_marker
    lda.w m1_MapViewTileTmp
    bra .store
.unvisited
    rep #$20
    lda.w m1_MapViewTileTmp
    and.w #!M1_MAP_TILE_CHARACTER_MASK
    sec : sbc.w #!M1_MAP_BG3_MAPSTATION_TILE_BASE
    cmp.w #!M1_MAP_MAPSTATION_TILE_COUNT
    bcc .draw_dim                   ; Map stations always draw as a landmark
    lda.w m1_MiniMapRevealedTmp
    beq .next
.draw_dim
    lda.w m1_MapViewTileTmp
    ora.w #!M1_MAP_PAL_REVEALED
.store
    ldx.w m1_MapViewDestTmp
    sta.l MapViewBuffer,x
.next
    lda.w m1_MapViewDestTmp
    inc #2
    sta.w m1_MapViewDestTmp
    lda.w m1_MapViewSrcCol
    inc
    sta.w m1_MapViewSrcCol
    lda.w m1_MapViewMaxX
    cmp.w m1_MapViewSrcCol
    bcs .more_cells

    lda.w m1_MapViewSrcRow
    inc
    sta.w m1_MapViewSrcRow
    lda.w m1_MapViewMaxY
    cmp.w m1_MapViewSrcRow
    bcs .more_rows
    bra .write_name

.more_cells
    jmp .cell
.more_rows
    jmp .row

.write_name
    ; Area name across dest row 0
    lda.w m1_MapViewArea
    asl #6                          ; 32 words per name line
    tay
    ldx.w #$0000
.name_loop
    lda.w M1MapViewAreaNames,y      ; DB is this routine's program bank
    sta.l MapViewBuffer,x
    iny #2
    inx #2
    cpx.w #$0040
    bne .name_loop

    sep #$20
    lda.b #$01
    sta.w m1_MapViewDMA
    rep #$20
    plb
    plp
    rts

M1MapViewAreaNames:
    table ../../data/tables/small_overlay.tbl,rtl
    dw "            Brinstar            "
    dw "            Norfair             "
    dw "          Kraid's Lair          "
    dw "            Tourian             "
    dw "         Ridley's Lair          "
    cleartable

; Blank the map-view buffer and queue its transfer (used when closing).
M1MapViewBlank:
    php
    phb
    pea $7e7e : plb : plb
    rep #$30
    lda.w #$0000
    ldx.w #(!M1_MAP_VIEW_BYTES-$02)
.clear
    sta.w !M1_MAP_VIEW_BUFFER,x
    dex #2
    bpl .clear
    sep #$20
    lda.b #$01
    sta.w m1_MapViewDMA
    rep #$20
    plb
    plp
    rts

; Clear cart RAM while preserving the persistent automap block. Invalid map
; state is reset later by M1MapEnsureInitialized.
M1BootClearCartRam:
    phb : phk : plb
    php
    rep #$30
    lda.w #$0000
    ldx.w #(!M1_MAP_STATE_BASE-$6000-$02)
.below
    sta.w $6000,x
    dex #2
    bpl .below
    ldx.w #($8000-!M1_MAP_STATE_END-$02)
.above
    sta.w !M1_MAP_STATE_END,x
    dex #2
    bpl .above
    plp
    plb
    rtl

; Validate the persistent state against both the format and generated map ID.
; Clears only the automap-owned $7900-$7BFF range when they do not match.
M1MapEnsureInitialized:
    php
    phx
    phb : phk : plb
    rep #$30

    lda.w !M1_MAP_STATE_MAGIC
    cmp.w #$314D                    ; "M1"
    bne .reset
    lda.w !M1_MAP_STATE_MAGIC+$02
    cmp.w #$504D                    ; "MP"
    bne .reset

    sep #$20
    lda.w !M1_MAP_STATE_VERSION
    cmp.b #!M1_MAP_FORMAT_VERSION
    bne .reset

    rep #$20
    lda.w !M1_MAP_STATE_SEED_ID
    cmp.l M1MapSeedId
    bne .reset
    lda.w !M1_MAP_STATE_SEED_ID+$02
    cmp.l M1MapSeedId+$02
    beq .done

.reset
    rep #$30
    lda.w #$0000
    ldx.w #(!M1_MAP_STATE_END-!M1_MAP_STATE_BASE-$02)
.clear
    sta.w !M1_MAP_STATE_BASE,x
    dex #2
    bpl .clear

    lda.w #$314D
    sta.w !M1_MAP_STATE_MAGIC
    lda.w #$504D
    sta.w !M1_MAP_STATE_MAGIC+$02
    lda.l M1MapSeedId
    sta.w !M1_MAP_STATE_SEED_ID
    lda.l M1MapSeedId+$02
    sta.w !M1_MAP_STATE_SEED_ID+$02
    sep #$20
    lda.b #!M1_MAP_FORMAT_VERSION
    sta.w !M1_MAP_STATE_VERSION

.done
    plb
    plx
    plp
    rtl

; Return the current vanilla area as a 0-4 automap area index.
M1MapGetCurrentAreaIndex:
    rep #$30
    lda.w m1_CurrentArea
    and.w #$00FF
    beq .brinstar
    sec
    sbc.w #$0010
.brinstar
    cmp.w #!M1_MAP_AREA_COUNT
    bcs .invalid
    clc
    rtl
.invalid
    sec
    rtl

; In:  A = area index, X = cell index.
; Out: X = visited byte offset, A = bit mask, carry clear.
;      Y is clobbered.
M1MapComputeVisitedIndex:
    rep #$30
    cmp.w #!M1_MAP_AREA_COUNT
    bcs .invalid
    cpx.w #!M1_MAP_CELLS_PER_AREA
    bcs .invalid

    asl #7                          ; area * $80
    pha
    txa
    and.w #$0007
    tay
    txa
    lsr #3
    clc
    adc $01,s
    tax
    pla
    lda.w #$0001
.mask_loop
    cpy.w #$0000
    beq .mask_done
    asl
    dey
    bra .mask_loop
.mask_done
    clc
    rtl
.invalid
    sec
    rtl

; Mark one cell visited and mark its area seen.
; In: A = area index, X = cell index. Preserves X/Y.
; Sets DB to its own bank so the persistent planes are always addressed
; through the BW-RAM window, regardless of the caller's DB.
M1MapMarkVisited:
    phb : phk : plb
    rep #$30
    phx
    phy
    pha
    jsl M1MapComputeVisitedIndex
    bcs .invalid

    sep #$20
    ora.w !M1_MAP_VISITED_BASE,x
    sta.w !M1_MAP_VISITED_BASE,x
    rep #$20
    pla
    tax
    sep #$20
    lda.l M1MapAreaBits,x
    ora.w !M1_MAP_STATE_SEEN_AREAS
    sta.w !M1_MAP_STATE_SEEN_AREAS
    rep #$20
    ply
    plx
    plb
    clc
    rtl

.invalid
    pla
    ply
    plx
    plb
    sec
    rtl

; Test one cell. Returns carry set when visited or when input is invalid;
; invalid input can be distinguished by A=$FFFF.
; In: A = area index, X = cell index. Preserves X/Y and addresses the
; persistent planes through its own DB like M1MapMarkVisited.
M1MapIsVisited:
    phb : phk : plb
    rep #$30
    phx
    phy
    jsl M1MapComputeVisitedIndex
    bcs .invalid
    sep #$20
    and.w !M1_MAP_VISITED_BASE,x
    beq .not_visited
    rep #$20
    lda.w #$0001
    ply
    plx
    plb
    sec
    rtl
.not_visited
    rep #$20
    lda.w #$0000
    ply
    plx
    plb
    clc
    rtl
.invalid
    lda.w #$FFFF
    ply
    plx
    plb
    sec
    rtl

; Load one final SNES BG tilemap word from ROM.
; In: A = area index, X = cell index. Out: A = tilemap word, carry clear.
M1MapGetTile:
    phx
    php
    rep #$30
    cmp.w #!M1_MAP_AREA_COUNT
    bcs .invalid
    cpx.w #!M1_MAP_CELLS_PER_AREA
    bcs .invalid
    asl #11                         ; area * $800 bytes
    pha
    txa
    asl                             ; two bytes per map cell
    clc
    adc $01,s
    tax
    pla
    lda.l M1MapTilemaps,x
    plp
    clc
    plx
    rtl
.invalid
    lda.w #$FFFF
    plp
    sec
    plx
    rtl

; Reveal an entire area for later map-station/map-item behavior. This does not
; mark every cell visited; the renderer can draw revealed cells with a dim
; palette while visited cells remain bright.
; In: A = area index. Preserves X/Y; DB-agnostic like the routines above.
M1MapRevealArea:
    phb : phk : plb
    rep #$30
    cmp.w #!M1_MAP_AREA_COUNT
    bcs .invalid
    phx
    tax
    sep #$20
    lda.l M1MapAreaBits,x
    ora.w !M1_MAP_STATE_REVEALED_AREAS
    sta.w !M1_MAP_STATE_REVEALED_AREAS
    ora.w !M1_MAP_STATE_SEEN_AREAS
    sta.w !M1_MAP_STATE_SEEN_AREAS
    rep #$20
    plx
    plb
    clc
    rtl
.invalid
    plb
    sec
    rtl

; Test whether an entire area has been revealed by a map station/item.
; In: A = area index. Out: carry set + A=1 when revealed, A=0 + carry clear
; when not, A=$FFFF + carry set when the area index is invalid.
; Preserves X/Y; DB-agnostic like the routines above.
M1MapIsAreaRevealed:
    phb : phk : plb
    rep #$30
    cmp.w #!M1_MAP_AREA_COUNT
    bcs .invalid
    phx
    tax
    sep #$20
    lda.l M1MapAreaBits,x
    and.w !M1_MAP_STATE_REVEALED_AREAS
    rep #$20
    and.w #$00ff
    beq .not_revealed
    lda.w #$0001
    plx
    plb
    sec
    rtl
.not_revealed
    plx
    plb
    clc
    rtl
.invalid
    lda.w #$FFFF
    plb
    sec
    rtl

M1MapAreaBits:
    db $01,$02,$04,$08,$10

M1MapVisitedBitMasks:
    db $01,$02,$04,$08,$10,$20,$40,$80
