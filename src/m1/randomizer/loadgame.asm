; Runs at password screen to save items
SaveItems:
    php
    rep #$30

    lda #$0003                     ; Since M1 "saves" on death, we need to properly save all items found
    jsl mb_RestoreItemBuffers      ; Restore all item buffers to proper SRAM in all games
    
    jsl backup_wram                ; Backup M1 WRAM to buffer
    lda #$0003
    jsl mb_CopyItemBuffer          ; Copy the M1 items to item buffer so that on a reset no M1 items are lost

    jsl nes_ClearAnimatedItems     ; Avoid interference with ppu writes by disabling any active animations

    plp

    ; Original hooked code
    ldx.b #$7f
    ldy.b #$93
    rtl

RestoreSamusHealth:
    php
    sep #$30
    lda.w $6877
    and.b #$0F
    asl #4
    ora.b #$09
    sta $107
    lda.b #$90
    sta $106
    plp
    rtl

; Runs at startup, restore items from SRAM backup and boot into the
; configured start area (config_m1_start_area) the same way a vanilla
; password start does: housekeeping + InArea + MainRoutine + SwitchPending.
; InitBank1 only performs the housekeeping when booting into Brinstar, so
; do it here for all areas, matching vanilla InitializeGame ($9092D4).
LoadItems:
    php
    rep #$30
    lda.w #$0003
    jsl mb_RestoreItemBuffer
    jsl M1MapEnsureInitialized
    jsl M1MapClearHud

    sep #$30

    lda.b #$00
    ldx.b #$33
-
    sta.b $00, x                   ; ClearRAM_33_DF equivalent
    inx
    cpx.b #$E0
    bne -

    ldx.b #$0F
-
    sta.w $0100, x                 ; ClearSamusStats equivalent
    dex
    bpl -

    lda.l config_m1_start_area
    cmp.b #$05
    bcc +
    lda.b #$00                     ; Out-of-range -> Brinstar
+
    tax
    ora.b #$10
    sta.b $74                      ; InArea = $10-$14
    lda.b #$00
    sta.b $1E                      ; MainRoutine = AreaInit; the non-Brinstar
                                   ; bank init routines don't set this
    lda.l m1_start_area_bank_table, x
    sta.b $24                      ; SwitchPending = area PRG page + 1

    plp
    rtl

; SwitchPending values per area, same as vanilla BankTable ($CA30)
m1_start_area_bank_table:
    db $02, $03, $05, $04, $06     ; Brinstar, Norfair, Kraid, Tourian, Ridley

; Replaces SamusInit's orientation selection ($C8FC-$C909, see hooks.asm).
; Vanilla hardcodes "Brinstar = horizontal room, everything else = vertical
; room" when picking the initial scroll direction and PPU mirroring; with a
; randomized start/respawn cell either orientation can occur in any area.
; Must exit with Y = the MirrorCntrl value: the vanilla code that follows
; stores Y into MaxMissilePickup/MaxEnergyPickup.
M1StartOrientation:
    php
    sep #$30
    phx
    lda.b $74                      ; InArea
    and.b #$0F
    tax
    lda.l config_m1_start_orientation, x
    beq .horizontal
    lsr.b $49                      ; ScrollDir: left (2) -> down (1)
    ldy.b #$2F                     ; Horizontal mirroring
    bra .store

.horizontal
    ldy.b #$27                     ; Vertical mirroring

.store
    sty.b $FA                      ; MirrorCntrl
    plx
    plp
    rtl

