; ============================================================================
; Repoint the vanilla item tables to bank 88 so we can extend them easily
; ============================================================================

; L9598:  .word SpecItmsTbl               ;($A3D6)Beginning of special items table.
org $819598
    dw brinstar_item_table
org $829598
    dw norfair_item_table
org $839598
    dw tourian_item_table
org $849598
    dw kraid_item_table
org $859598
    dw ridley_item_table

%hook($ED98, "jsl ScanForItems_Start : nop")
%hook($EDA4, "lda [$00], y")
%hook($EDAD, "lda [$00], y")
%hook($EDB1, "and [$00], y")
%hook($EDB7, "lda [$00], y")
%hook($EDC5, "lda [$00], y")
%hook($EDDB, "lda [$00], y")
%hook($EE0F, "lda [$00], y")
%hook($EE20, "lda [$00], y")
%hook($EF00, "lda [$00], y")
; ============================================================================

; ============================================================================
; Allow new item types to support out-of-game items easily
; This extends the game with item type $0B, which can have 256 entries in an
; extended graphics data table
; ============================================================================
%hook($EDDF, "jsr ChooseRoutineExtended : dl ChooseHandlerTable_extended")
%hook($EE2E, "jsl StorePowerUpYCoord_extended : nop")
%hook($DE74, "jsl GetFramePtrTable_extended : nop #6")
%hook($DDC4, "jsl GetEnemyFramePtrTable_extended : nop #13")
%hook($DCC7, "lda [$CC], y")
%hook($DE08, "lda [$CC], y")
%hook($DE11, "lda [$CC], y")
%hook($DEBF, "lda [$CC], y")
%hook($DEC8, "lda [$CC], y")
%hook($DEF7, "lda [$CC], y")
%hook($DF1B, "lda [$CC], y")
%hook($DF47, "lda [$CC], y")
%hook($DF52, "lda [$CC], y")
%hook($DF5F, "lda [$CC], y")
%hook($E03A, "lda [$CC], y")
%hook($DF04, "jsl StoreSpriteAttributes_extended : nop")
%hook($DBB0, "jsl PickupItem_extended : bcs $20")
%hook($DB73, "jsl UpdatePaletteEffect_extended : nop #5")
; ============================================================================
