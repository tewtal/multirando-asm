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
; Route item/door collected-state tracking through the bit planes (see newitems.asm)
; instead of the vanilla "unique item history". Mother Brain and the 5 Zebetites stay
; on the linear history.
;
; AddItemToHistory body ($DC51) is diverted to the plane writer; the raw linear writer
; ($DC54) is relocated to bank $99 and a JSL trampoline left in the freed tail. The
; bank-$99 handlers return via RTL, so each hook ends in RTS to match the vanilla
; routine's RTS return. Freed $DC51-$DC66 tail layout:
;   $DC51 jsl AddItemToHistory_plane   (4)
;   $DC55 rts                          (1)  return to GetItemXYPos's caller
;   $DC56 jsl AddItemToHistory_raw     (4)  MB/Zeb trampoline
;   $DC5A rts                          (1)
%hook($DC51, "jsl AddItemToHistory_plane : rts")
%hook($DC56, "jsl AddItemToHistory_raw : rts")
%hook($EE4A, "jsl CheckForItem_plane : rts")

; Repoint the two raw-history callers (MB at $FDF6, Zeb at $FE18) from $DC54 to the
; $DC56 trampoline. Same opcode and length, so nothing shifts.
%hook($FDF6, "jsr $DC56")
%hook($FE18, "jmp $DC56")

; Record beam weapons (Long/Wave/Ice) in the bit plane like any other item. Vanilla
; skips the history write for beams ($DBB6 INY : BEQ +); NOP the skip so beams fall
; through to GetItemXYPos -> AddItemToHistory_plane, preventing their orbs respawning.
%hook($DBB7, "nop #2")

; ============================================================================
; Allow new item types to support out-of-game items easily
; This extends the game with item type $0B, which can have 256 entries in an
; extended graphics data table
; ============================================================================
%hook($EDDF, "jsr ChooseRoutineExtended : dl ChooseHandlerTable_extended")
%hook($EE2E, "jsl StorePowerUpYCoord_extended : nop")
%hook($DE74, "jsl GetFramePtrTable_extended : nop #6")
%hook($DDC4, "jsl GetEnemyFramePtrTable_extended : nop #13")
%hook($DF02, "jsl StoreSpriteAttributes_extended : nop #3")
%hook($DBB0, "jsl PickupItem_extended : bcs $2d")
%hook($DB73, "jsl UpdatePaletteEffect_extended : nop #5")

;  Hooks below reference struct FrameData $00d9 (see randomizer/newitems.asm:3)
%hook($DCC7, "lda [$d9], y")
%hook($DE08, "lda [$d9], y")
%hook($DE11, "lda [$d9], y")
%hook($DEBF, "lda [$d9], y")
%hook($DEC8, "lda [$d9], y")
%hook($DEF7, "lda [$d9], y")
%hook($DF1B, "lda [$d9], y")
%hook($DF47, "lda [$d9], y")
%hook($DF52, "lda [$d9], y")
%hook($DF5F, "lda [$d9], y")
%hook($E03A, "lda [$d9], y")
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
%hook($CB4B, "jml SamusEnterDoor_extended : nop #2")

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

; ==============================================
; Skip intro and start the game right away
; ==============================================

; Go directly to "start pressed" mode
org $90802C
    dw $90e4

; Don't reset items on game start
org $9090E4
    jsl LoadItems : rts
