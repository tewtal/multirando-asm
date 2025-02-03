; Originally from Map Randomizer
; https://github.com/blkerby/MapRandomizer/blob/main/patches/src/ultra_low_qol_map_area.asm
;

;;; Hijack map usages of area ($079F) with new area ($1F5B)
org $8085A7  ; Load mirror of current area's map explored
    ldx $1F5B

org $80858F  ; Load mirror of current area's map explored
    lda $1F5B

org $8085C9  ; Mirror current area's map explored
    lda $1F5B

org $8085E6  ; Mirror current area's map explored
    ldx $1F5B

org $82941B  ; Updates the area and map in the map screen
    lda $1F5B

org $829440  ; Updates the area and map in the map screen
    lda $1F5B

org $829475  ; Updates the area and map in the map screen
    ldx $1F5B

org $82952D  ; Draw room select map
    lda $1F5B

org $829562  ; Draw room select map
    ldx $1F5B

org $82962B  ; Something map-related (?)
    lda $1F5B

org $829ED5  ; Something map-related (?)
    lda $1F5B

org $829F01  ; Something map-related (?)
    lda $1F5B

org $90A9BE  ; Update mini-map
    lda $1F5B

org $90AA73  ; Update HUD mini-map tilemap
    lda $1F5B

org $90AA78  ; Update HUD mini-map tilemap
    adc $1F5B

org $848C91  ; Activate map station
    ldx $1F5B

org $8FC90C  ; Tourian first room gives area map (TODO: change this)
    ldx $1F5B

org $84B19C  ; At map station, check if current area map already collected
    ldx $1F5B

;;; Hijack code that loads area from room header
org $82DE80
    jsl load_area
    jmp $DE89
warnpc $82DE89

;;; Put new code in free space at end of bank $82:
org $83F000

;;; X = room header pointer
load_area:
    ;;; Load the original area number into $079F
    lda $0001,x
    and #$00FF
    sta $079F
    asl #7
    clc : adc $079D
    tay
    lda $FD00, y   ; new/map room area = [$8F:FD00 + (original area * 128) + room index]
    and #$00FF
    sta $1F5B
    rtl

org $8FFD00
    fillbyte $00
    fill $80
    fillbyte $01
    fill $80
    fillbyte $02
    fill $80
    fillbyte $03
    fill $80
    fillbyte $04
    fill $80
    fillbyte $05
    fill $80    

warnpc $900000