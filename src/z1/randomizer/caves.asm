; Cave / shop item loading, extended to support cave indices beyond the vanilla
; 20 (cave IDs 0x10-0x23). The vanilla engine indexes two tables by cave index:
;   - the item/flag/price wares (handled by LoadCaveShopItems_extended below)
;   - the OverworldPersonTextSelectors byte, which supplies BOTH the shopkeeper
;     text selector (low 6 bits) AND the PickItem/Shop cave-flag bits (high 2
;     bits, stored in $03 and folded into CaveFlags later).
; The vanilla OverworldPersonTextSelectors table only has 20 entries, so new
; cave IDs would read past it. LoadCaveTextSelector_extended replaces that read
; with one indexed into a 48-entry extended table (written by the randomizer),
; covering cave indices 0-0x2F (cave IDs 0x10-0x3F).

; Y = cave index (ObjType+1 - 0x6A) on entry, as in vanilla InitCaveContinue.
; Sets PersonTextSelector ($0415) = low 6 bits, $03 = high 2 bits.
LoadCaveTextSelector_extended:
    phx
    tyx
    lda.l CaveShopText_extended, x   ; extended per-cave text/flag byte
    plx
    pha
    and #$3F
    sta.w $0415                      ; PersonTextSelector
    pla
    and #$C0
    sta.b $03                        ; PickItem/Shop bits (folded into CaveFlags)
    rtl

; Y = cave index * 3 (+ slot), X = slot (0-2) on entry. Copies one ware's
; item id, per-slot flag bits, and price from the extended tables.
LoadCaveShopItems_extended:
    phx
    tyx
    lda.l CaveShopItems_extended, x : sta.w CaveItemTemp
    lda.l CaveShopFlags_extended, x : sta.w CaveItemTempFlags
    lda.l CaveShopPrices_extended, x : sta.w CaveItemTempPrice
    plx

    lda.w CaveItemTemp : sta.w $0422, x
    lda.w CaveItemTempFlags : sta.b $00, x
    lda.w CaveItemTempPrice : sta.w $0430, x
    rtl

; Cave-person sprite index is ObjType+1; the engine's person/moblin animation table
; only covers vanilla cave types (<= ~0x7D). Clamp any object type >= 0x7E to 0x7B
; (the single-item moblin shopkeeper, e.g. caves 0x21-0x23) so extended buy-once shops
; draw a valid sprite. The final CPY #$7B sets carry for the caller's mirror decision
; (>= 0x7B => not mirrored).
ClampCaveTypeAndCompare:
    ldy.w $0350                  ; ObjType+1
    cpy.b #$7E
    bcc +                        ; < 0x7E: a vanilla cave type, leave as-is
    ldy.b #$7B                   ; >= 0x7E: clamp to the moblin shopkeeper type
+
    cpy.b #$7B                   ; set carry for the mirror decision
    rtl
