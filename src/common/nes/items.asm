;  NES-specific item handling routines

; Global storage for items which require animation (in nes games only)
struct Animations $0aa0
    .itemid: skip 1
    .vramslot: skip 2
endstruct

;  Clear the Animations struct
ClearAnimatedItems:
    php
    rep #$20
    stz.w Animations.itemid
    stz.w Animations.vramslot
    plp
rtl

; [A] = vram slot for item
; [X] = item ID
; Returns the item ID in [A]
; Assumes execution is in a16 mode
StoreAnimatedItems:
    php
    sep #$10    ; i8
    cpx #$34        ;  z3 rupee
    beq .animated
    cpx #$35        ;  z3 rupee
    beq .animated
    cpx #$36        ;  z3 rupee
    beq .animated
    cpx #$47        ;  z3 rupee
    beq .animated

    ;  Item not animated; clear Animations struct
    ;  if the incoming slot matches the animated vram slot
    cmp.w Animations.vramslot
    bne .done
    stz.w Animations.itemid
    stz.w Animations.vramslot
    bra .done

.animated
;  TODO: implement a list to store up to 5(?) items for animation
;  more than 2 slots won't ever be needed unless enemizer or shop shuffle
;  gets implemented for the nes games.  Also you have to consider how much
;  of NMI will get taken up by 5x80 bytes being DMAed.
;   phx : pha

;     ;  Find an empty slot for this animateable item
;     ldx #$00

; -
;     lda.w Animations.itemid, x
;     beq .foundNewSlot
;     inx
;     cpx #$05
;     bne -
;     bra .done   ;  None of the five slots open; skip storing for animation
; .foundNewSlot

;  In the meantime, just use a single slot at $0aa0

    stx.w Animations.itemid
    sta.w Animations.vramslot

.done
    txa
    plp
rtl

; [A] = Frame count
; Returns the item ID in [A]
UpdateItemAnimations:
    php
    tax     ;  Frame count to [X]
    rep #$20    ; a16

    lda.w Animations.vramslot
    beq .done   ;  No item needs animating

    LDA #$1801
    STA $4300   ;  DMAP0 and BBAD0

    lda.l Z3RupeeAnimationLookup, x
    and.w #$00ff
    asl : tax  ;  double index for word offset

    lda.l Z3RupeeFrameOffsets, x
    STA $4302   ;
    LDA #$00fb  ;  source address is the desired item graphic (e.g. $fba880)
    STA $4304
    LDA #$0080  ;  transfer 4 8x8 tiles (one item)
    STA $4305
    lda Animations.vramslot
    sta $2116   ;  vram word address

    SEP #$20

    lda #$80
    sta $2115   ;  VMAIN

    LDA #$01
    STA $420B
.done
    plp
rtl

Z3RupeeFrameOffsets:
    dw $0000, $a880, $aa00, $aa80

;  Utterly wasteful I know.  We weren't using these bytes anyway ;p
Z3RupeeAnimationLookup:
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    db $02, $02, $03, $03, $03, $03, $03, $03, $01, $01, $01, $01, $01, $01, $01, $01
    db $01, $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $02, $03, $03
    db $03, $03, $03, $03, $03, $03
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    db $02, $02, $03, $03, $03, $03, $03, $03, $01, $01, $01, $01, $01, $01, $01, $01
    db $01, $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $02, $03, $03
    db $03, $03, $03, $03, $03, $03
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    db $02, $02, $03, $03, $03, $03, $03, $03, $01, $01, $01, $01, $01, $01, $01, $01
    db $01, $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $02, $03, $03
    db $03, $03, $03, $03, $03, $03
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    db $02, $02, $03, $03, $03, $03, $03, $03, $01, $01, $01, $01, $01, $01, $01, $01
    db $01, $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $02, $03, $03
    db $03, $03, $03, $03, $03, $03
    db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    db $02, $02, $03, $03, $03, $03, $03, $03, $01, $01, $01, $01, $01, $01, $01, $01
    db $01, $01, $01, $01, $01, $01, $01, $01