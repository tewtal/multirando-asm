; ============================================================================
; Repoint the vanilla item tables to bank 88 so we can extend them easily
; ============================================================================

; L9598:  .word SpecItmsTbl               ;($A3D6)Beginning of special items table.
org $919598
    dw brinstar_item_table
org $929598
    dw norfair_item_table
org $939598
    dw tourian_item_table
org $949598
    dw kraid_item_table
org $959598
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

; Hook all the extra special handlers that reads from the item tables
%hook($EC0F, "lda [$00], y")            ; Elevator
%hook($EDF8, "jsr GetEnemyData_long")   ; Squeept
org $939CF6 : lda [$00], y              ; Cannon
org $939D07 : lda [$00], y              ; Cannon
org $939D3D : lda [$00], y              ; Zebetite
org $939D79 : lda [$00], y              ; Rinka
%hook($EEF4, "jsr LoadDoor_long")       ; Door
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
%hook($DF04, "jsl StoreSpriteAttributes_extended : nop")
%hook($DBB0, "jsl PickupItem_extended : bcs $2d")
%hook($DB73, "jsl UpdatePaletteEffect_extended : nop #5")
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
; ============================================================================

; ============================================================================
; Disable item fanfare delay
; ============================================================================
%hook($DBE3, "lda.b #$ff : sta $0748, x : jsr $cbc0 : jmp $dbf3")

; ============================================================================
; Save items directly on Password screen
;
; L9360:  LDX #$7F                ;Low byte of start of PPU data.
; L9362:  LDY #$93                ;High byte of start of PPU data.
; ============================================================================
org $909360 : jsl SaveItems

; ============================================================================
; Disable reloading items from password
; ============================================================================
org $908D3D : rts

; ============================================================================
; Cross-game transitions
; ============================================================================
%hook($8B74, "jsl SamusInDoor_extended : rts")

; ============================================================================
; Wavy-ice patch by snarfblam
; ============================================================================
%hook($DBD2, "nop #8")
%hook($D5C5, "jmp WavyIce_NewBehavior")
%hook($F5EE, "jmp WavyIce_NewDamage")

; ============================================================================
; Spawn with full health
; ============================================================================
%hook($C922, "jsl RestoreSamusHealth : rts")

; ============================================================================
; Move Up+A (Up+B on SNES) to controller 1
; ============================================================================
%hook($C9B1, "lda.b $14")

; ============================================================================
; Patch ending sequence to check for full game completion
; ============================================================================
org $908000
    ; LDA TitleRoutine ($1F) : CMP #$15
    jsl CheckExtraEndingTitleModes        

; Patch the code where the game sets the escape timer flag after defeating
; mother brain to not set it in the case where all games are not completed
org $939EDE
    ; LDA #$05 : STA $98
    ; LDA #$80 : STA #$99
    ; RTS
    jsl CheckEndingSequence
    rts

org $909BCD
    jsl StartCredits