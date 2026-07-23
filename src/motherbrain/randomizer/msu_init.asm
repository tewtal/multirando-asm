; Boot-time MSU-1 setup and lookup tables.

print "MSU init = ", pc

; Called once after Mother Brain has initialized/created persistent SRAM.
MSU_Init:
    php
    rep #$30
    pha
    phx
    phy

    lda.w #$0000
    sta.l !MSU_REQUEST_TRACK
    sta.l !MSU_SELECTED_TRACK
    sta.l !MSU_CURRENT_TRACK
    sta.l !MSU_BUSY_FRAMES
    sep #$20
    sta.l !MSU_PRESENT
    sta.l !MSU_STATE
    sta.l !MSU_OWNER
    sta.l !MSU_REQUEST_CONTROL
    sta.l !MSU_NATIVE_MUTE
    sta.l !MSU_WRITE_SUPPRESS
    sta.l !MSU_EXPECTED_SPC
    sta.l !MSU_VOLUME
    sta.l !MSU_CONTROL

    ; Verify the "S-MSU1" device ID.
    rep #$20
    lda.l !MSU_ID
    cmp.w #$2D53
    bne .device_missing
    lda.l !MSU_ID+$2
    cmp.w #$534D
    bne .device_missing
    lda.l !MSU_ID+$4
    cmp.w #$3155
    bne .device_missing
    sep #$20
    lda.b #$01
    sta.l !MSU_PRESENT
    bra .device_ready
.device_missing:
    jmp .restore
.device_ready:

    ; Reuse a complete cache for this seed.
    rep #$20
    lda.l !MSU_CACHE_MAGIC
    cmp.w #!MSU_CACHE_MAGIC_VALUE
    bne .scan
    lda.l config_seed
    cmp.l !MSU_CACHE_SEED
    bne .scan
    lda.l config_seed+$2
    cmp.l !MSU_CACHE_SEED+$2
    bne .scan
    jsr MSU_ResolveFallbacks
    jmp .restore

.scan:
    ; Invalidate before rebuilding the cache.
    lda.w #$0000
    sta.l !MSU_CACHE_MAGIC
    sep #$20
    ldx.w #!MSU_TRACK_CACHE_SIZE-1
.clear_cache:
    sta.l !MSU_TRACK_CACHE,x
    dex
    bpl .clear_cache

    rep #$20
    ldx.w #$0000
.next_range:
    lda.l MSU_TrackManifest,x
    beq .scan_done
    tay
    lda.l MSU_TrackManifest+2,x
    sta.l !MSU_TEMP2
    phx
.range_track:
    tya
    sta.l !MSU_TRACK
    ldx.w #$FFFF

.wait_track:
    sep #$20
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_BUSY
    beq .track_ready
    dex
    beq .scan_timeout
    bra .wait_track

.track_ready:
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_MISSING
    bne .track_missing
    lda.b #$01
    bra .store_track
.track_missing:
    lda.b #$00
.store_track:
    tyx
    sta.l !MSU_TRACK_CACHE,x
    rep #$20
    tya
    cmp.l !MSU_TEMP2
    beq .range_done
    iny
    bra .range_track
.range_done:
    plx
    inx #4
    bra .next_range

.scan_done:
    lda.l config_seed
    sta.l !MSU_CACHE_SEED
    lda.l config_seed+$2
    sta.l !MSU_CACHE_SEED+$2
    lda.w #!MSU_CACHE_MAGIC_VALUE
    sta.l !MSU_CACHE_MAGIC
    jsr MSU_ResolveFallbacks
    sep #$20
    lda.b #$00
    sta.l !MSU_VOLUME
    sta.l !MSU_CONTROL
    bra .restore

.scan_timeout:
    plx
    sep #$20
    lda.b #$00
    sta.l !MSU_PRESENT
    sta.l !MSU_VOLUME
    lda.b #!MSU_STATE_ERROR
    sta.l !MSU_STATE

.restore:
    rep #$30
    ply
    plx
    pla
    plp
    rtl

; Resolve each fallback head to its first available track.
MSU_ResolveFallbacks:
    php
    phb
    rep #$30
    pea $4040 : plb : plb

    ; Zero the resolved table.
    ldy.w #$0000
    lda.w #$0000
-   sta.w !MSU_FALLBACK_TABLE&$FFFF,y
    iny #2
    cpy.w #!MSU_TRACK_CACHE_SIZE*2
    bne -

    ; Walk the fallback chains.
    ldx.w #$0000
.next_chain:
    lda.l MSU_FallbackChains,x
    beq .done
    asl
    sta.l !MSU_TEMP
.scan_chain:
    lda.l MSU_FallbackChains,x
    beq .next_chain_entry
    cmp.w #!MSU_TRACK_CACHE_SIZE
    bcs .skip_member
    tay                         ; Y = member track
    lda.w !MSU_TRACK_CACHE&$FFFF,y
    and.w #$00FF
    bne .member_present
.skip_member:
    inx #2
    bra .scan_chain
.member_present:
    tya
    pha
    lda.l !MSU_TEMP
    tay
    pla
    sta.w !MSU_FALLBACK_TABLE&$FFFF,y
.chain_end:
    lda.l MSU_FallbackChains,x
    beq .next_chain_entry
    inx #2
    bra .chain_end
.next_chain_entry:
    inx #2
    bra .next_chain
.done:
    plb
    plp
    rts

; Inclusive track ranges to scan.
MSU_TrackManifest:
    dw   1,  61     ; A Link to the Past
    dw  99,  99     ; A Link to the Past credits
    dw 101, 141     ; Super Metroid
    dw 201, 218     ; Zelda 1
    dw 301, 315     ; Metroid 1
    dw 0

; Null-terminated fallback chains in priority order.
MSU_FallbackChains:
    ; Zelda 1 -> A Link to the Past
    dw 201,1,0            ; Title -> Title ~ Link to the Past
    dw 202,2,0            ; Overworld -> Hyrule Field
    dw 203,17,0           ; Generic dungeon -> pendant dungeon
    dw 204,46,22,0        ; Level 9 -> Ganon's Tower -> crystal dungeon
    dw 205,29,0           ; Ganon -> Release of Ganon
    dw 206,19,0           ; Dungeon clear -> Great Victory!
    dw 207,25,0           ; Zelda rescued -> Princess Zelda's Rescue
    dw 209,34,0           ; Ending -> Staff Roll

    ; Prefer the Z1 generic track, then use Z3's dungeon fallback.
    dw 211,203,35,17,0    ; Eastern Palace
    dw 212,203,36,17,0    ; Desert Palace
    dw 213,203,43,17,0    ; Tower of Hera
    dw 214,203,39,22,0    ; Palace of Darkness
    dw 215,203,38,22,0    ; Swamp Palace
    dw 216,203,41,22,0    ; Skull Woods
    dw 217,203,42,22,0    ; Ice Palace
    dw 218,203,40,22,0    ; Misery Mire

    ; Super Metroid extended tracks -> base tracks
    dw 131,123,0          ; Kraid tension
    dw 132,122,0          ; Kraid
    dw 133,123,0          ; Phantoon tension
    dw 134,122,0          ; Phantoon
    dw 135,119,0          ; Draygon
    dw 136,119,0          ; Ridley
    dw 137,123,0          ; Tourian tension
    dw 138,122,0          ; Mother Brain
    dw 139,110,0          ; Hyper Beam

    ; Metroid 1 -> Super Metroid
    dw 301,104,0          ; Intro -> Opening
    dw 302,110,0          ; Brinstar -> Green Brinstar
    dw 303,112,0          ; Norfair -> Upper Norfair
    dw 304,111,0          ; Kraid hideout -> Red Brinstar (Kraid's lair)
    dw 305,113,0          ; Ridley hideout -> Lower Norfair
    dw 306,117,0          ; Tourian -> Tourian
    dw 307,103,0          ; Item room -> Item Room
    dw 308,119,0          ; Generic boss -> Big Boss Battle 1
    dw 309,118,0          ; Mother Brain -> Mother Brain
    dw 310,120,0          ; Escape -> Evacuation
    dw 311,102,0          ; Power-up -> Item Acquisition
    dw 312,130,0          ; Ending -> Credits
    dw 313,101,0          ; Samus Fanfare -> Samus Fanfare
    dw 314,308,132,122,0  ; Kraid battle -> generic boss -> SM Kraid -> Big Boss Battle 2
    dw 315,308,136,119,0  ; Ridley battle -> generic boss -> SM Ridley -> Big Boss Battle 1
    dw 0                   ; end of blob

print "MSU init end = ", pc
