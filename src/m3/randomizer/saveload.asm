; Based on Scyzer's replacement of saving/loading, to fix map saving.
; From https://metroidconstruction.com/SMMM/Scyzer_map_fix_saveload.zip
; From https://github.com/blkerby/MapRandomizer/blob/main/patches/src/ultra_low_qol_saveload.asm
org $819A47		;Fix File Copy for the new SRAM files
	LDA.l SRAMAddressTable,X : Skip 7 : LDA.l SRAMAddressTable,X : Skip 11 : CPY #$0A00
org $819CAE		;Fix File Clear for the new SRAM files
	LDA.l SRAMAddressTable,X : Skip 12 : CPY #$0A00
	
org $818000
	JMP SaveGame
org $818085
	JMP LoadGame
org $81EF20
SRAMAddressTable:
	; There is only one logical SM save. Alias the disabled file-select slots
	; to slot 0 so native copy/erase code cannot overwrite persistent map data.
	DW $0010,$0010,$0010
CheckSumAdd: CLC : ADC $14 : INC A : STA $14 : RTS

SaveGame: jsl sm_save_hook : PHP : REP #$30 : PHB : PHX : PHY
	; The title-screen patch exposes only save slot 0. Force
	; the runtime state and save routine to agree so the unused slot 1
	; block remains safe for persistent randomized-map progress.
	PEA $7E7E : PLB : PLB : STZ $14 : STZ $0952 : LDA #$0000 : STA $12
	LDA $1F5B : INC A : XBA : TAX : LDY #$00FE
SaveMap: LDA $07F7,Y : STA $CD50,X : DEX : DEX : DEY : DEY : BPL SaveMap		;Saves the current map
	LDY #$005E
SaveItems: LDA $09A2,Y : STA $D7C0,Y : DEY : DEY : BPL SaveItems				;Saves current equipment	
	LDA $078B : STA $D916		;Current save for the area
	LDA $079F : STA $D918		;Current Area
	LDA $1F5B : STA $7EFE00     ;Current Map-area
	LDX $12 : LDA.l SRAMAddressTable,X : TAX : LDY #$0000		;How much data to save for items and event bits
SaveSRAMItems: LDA $D7C0,Y : STA $400000,X : JSR CheckSumAdd : INX : INX : INY : INY : CPY #$0160 : BNE SaveSRAMItems	
	LDY #$06FE		;How much data to save for maps
SaveSRAMMaps: LDA $CD52,Y : STA $400000,X : INX : INX : DEY : DEY : BPL SaveSRAMMaps	
	PEA $7E7E : PLB : PLB : LDY #$00FE		;How much extra data to save per save
SaveSRAMExtra: LDA $FE00,Y : STA $400000,X : INX : INX : DEY : DEY : BPL SaveSRAMExtra
	LDY #$00FE : LDX #$1E10					;How much extra data to save globally (affects all saves)
SaveSRAMExtraA: LDA $FF00,Y : STA $400000,X : INX : INX : DEY : DEY : BPL SaveSRAMExtraA
SaveChecksum: LDX $12 : LDA $14 : STA $400000,X : STA $401FF0,X : EOR #$FFFF : STA $400008,X : STA $401FF8,X
EndSaveGame: PLY : PLX : PLB : PLP : jsl sm_save_done_hook : RTL

LoadGame: jsl sm_load_hook : PHP : REP #$30 : PHB : PHX : PHY
	; See SaveGame: all loads are canonicalized to slot 0 before looking
	; up an SRAM block.
	PEA $7E7E : PLB : PLB : STZ $14 : STZ $0952 : LDA #$0000 : STA $12
	TAX : LDA.l SRAMAddressTable,X : STA $16 : TAX : LDY #$0000		;How much data to load for items and event bits
LoadSRAMItems: LDA $400000,X : STA $D7C0,Y : JSR CheckSumAdd : INX : INX : INY : INY : CPY #$0160 : BNE LoadSRAMItems	
	LDY #$06FE		;How much data to load for maps
LoadSRAMMaps: LDA $400000,X : STA $CD52,Y : INX : INX : DEY : DEY : BPL LoadSRAMMaps
	PEA $7E7E : PLB : PLB : LDY #$00FE		;How much extra data to load per save
LoadSRAMExtra: LDA $400000,X : STA $FE00,Y : INX : INX : DEY : DEY : BPL LoadSRAMExtra
	LDY #$00FE : LDX #$1E10					;How much extra data to load globally (affects all saves)
LoadSRAMExtraA: LDA $400000,X : STA $FF00,Y : INX : INX : DEY : DEY : BPL LoadSRAMExtraA
LoadCheckSum: LDX $12 : LDA $400000,X : CMP $14 : BNE $0B : EOR #$FFFF : CMP $14 : BNE $02 : BRA LoadSRAM
	LDA $14 : CMP $401FF0,X : BNE SetupClearSRAM : EOR #$FFFF : CMP $401FF8,X : BRA LoadSRAM ; We ignore bad checksums for now  ;BNE SetupClearSRAM : BRA LoadSRAM
LoadSRAM: PEA $7E7E : PLB : PLB : LDY #$005E
	JSL sm_merge_persistent_map_progress
LoadItems: LDA $D7C0,Y : STA $09A2,Y : DEY : DEY : BPL LoadItems		;Loads current equipment	
	LDA $D916 : STA $078B		;Current save for the area
	LDA $D918 : STA $079F		;Current Area
    LDA $7EFE00 : STA $1F5B     ;Current Map-area
	PLY : PLX : PLB : PLP : CLC : RTL
SetupClearSRAM: LDX $16 : LDY #$09FE : LDA #$0000
ClearSRAM: STA $400000,X : INX : INX : DEY : DEY : BPL ClearSRAM
    LDA #$0000 : STA $7E078B : STA $7E079F
	PLY : PLX : PLB : PLP : SEC : RTL

    warnpc $81f100

; Persistent randomized-map progress uses the data block normally owned by
; save slot 1 (the second displayed save file). Slots 1 and 2 are hidden by
; titlescreen.asm, and SaveGame/LoadGame above force every caller to slot 0.
;
; Slot layout:
;   $400010-$400A0F  slot 0 (the only playable save)
;   $400A10-$40140F  slot 1 (repurposed here)
;   $401410-$401E0F  slot 2 (unused)
;   $401E10-$401F0F  global SM extra data
;   $401FF0-$401FFF  backup checksum words
; Slot-0 checksum/item-sync loops stop before $400A00. SM's boot SRAM probe
; backs up and restores all $2000 bytes; only fresh randomizer initialization
; intentionally clears this block.
!SM_PERSIST_SLOT_START = $400A10
!SM_PERSIST_SLOT_END = $401410
!SM_PERSIST_MAP = !SM_PERSIST_SLOT_START
!SM_PERSIST_MAP_SIZE = $0700
!SM_PERSIST_MAP_END = !SM_PERSIST_MAP+!SM_PERSIST_MAP_SIZE
!SM_PERSIST_MAP_STATIONS = !SM_PERSIST_MAP_END
!SM_PERSIST_MAP_STATIONS_SIZE = $0008
!SM_PERSIST_END = !SM_PERSIST_MAP_STATIONS+!SM_PERSIST_MAP_STATIONS_SIZE

; A portal-revert checkpoint does not need its own copy of the explored-map
; block: when map randomization is enabled, the persistent data above is the
; authoritative map and is merged after every load. Keep only the material
; parts of slot 0 here.
!SM_PORTAL_BACKUP_STATE = !SM_PERSIST_END
!SM_PORTAL_BACKUP_STATE_SIZE = $0160
!SM_PORTAL_BACKUP_EXTRA = !SM_PORTAL_BACKUP_STATE+!SM_PORTAL_BACKUP_STATE_SIZE
!SM_PORTAL_BACKUP_EXTRA_SIZE = $0100
!SM_PORTAL_BACKUP_META = !SM_PORTAL_BACKUP_EXTRA+!SM_PORTAL_BACKUP_EXTRA_SIZE
!SM_PORTAL_BACKUP_MARKER = !SM_PORTAL_BACKUP_META
!SM_PORTAL_BACKUP_MARKER_INV = !SM_PORTAL_BACKUP_MARKER+$0002
!SM_PORTAL_BACKUP_COMPLETION = !SM_PORTAL_BACKUP_MARKER_INV+$0002
!SM_PORTAL_BACKUP_COMPLETION_SIZE = $0008
!SM_PORTAL_BACKUP_Z1_TUNIC = !SM_PORTAL_BACKUP_COMPLETION+!SM_PORTAL_BACKUP_COMPLETION_SIZE
!SM_PORTAL_BACKUP_META_END = !SM_PORTAL_BACKUP_Z1_TUNIC+$0002

; The third displayed SM slot holds the complete shared inventory buffer.
; This includes the SM mirror as well as ALTTP, Z1, and M1, keeping capture
; and restore symmetric and leaving $0400 bytes for future audited state.
!SM_PORTAL_BACKUP_SHARED = $401410
!SM_PORTAL_BACKUP_SHARED_SIZE = $0600
!SM_PORTAL_BACKUP_SHARED_END = !SM_PORTAL_BACKUP_SHARED+!SM_PORTAL_BACKUP_SHARED_SIZE
!SM_DISABLED_SLOTS_END = $401E10

assert !SM_PERSIST_MAP == $400A10
assert !SM_PERSIST_MAP_END == $401110
assert !SM_PERSIST_MAP_STATIONS == $401110
assert !SM_PERSIST_END == $401118
assert !SM_PERSIST_END <= !SM_PERSIST_SLOT_END
assert !SM_PERSIST_END <= !SRAM_SM_EXIT
assert !SM_PORTAL_BACKUP_STATE == $401118
assert !SM_PORTAL_BACKUP_EXTRA == $401278
assert !SM_PORTAL_BACKUP_META == $401378
assert !SM_PORTAL_BACKUP_META_END == $401386
assert !SM_PORTAL_BACKUP_META_END <= !SRAM_SM_EXIT
assert !SM_PORTAL_BACKUP_META_END <= !SM_PERSIST_SLOT_END
assert !SM_PORTAL_BACKUP_SHARED == !SM_PERSIST_SLOT_END
assert !SM_PORTAL_BACKUP_SHARED_END == $401A10
assert !SM_PORTAL_BACKUP_SHARED_END <= !SM_DISABLED_SLOTS_END
assert !SM_PERSIST_SLOT_END <= $401E10
assert !SM_PERSIST_SLOT_END <= $401FF0

; Free space at the end of SM's area-map bank.
org $B5F000

; Record the explored byte containing the tile selected by X/Y.
; Input matches Map Overhaul's UpdateActiveMapWithExplored:
;   X = bit index, Y = byte index within the current area's $100-byte map.
; The routine accepts either 8- or 16-bit caller register widths.
sm_persist_explored_tile:
	php
	rep #$30
	pha : phx : phy
	lda $12
	pha

	lda.l config_sm_map_randomization
	beq .done

	lda $1F5B
	and #$00FF
	cmp #$0007
	bcs .done
	xba
	sta $12
	tya
	and #$00FF
	clc
	adc $12
	tax

	sep #$20
	lda $07F7,y
	ora.l !SM_PERSIST_MAP,x
	sta.l !SM_PERSIST_MAP,x

.done
	rep #$30
	pla
	sta $12
	ply : plx : pla
	plp
	rtl

; Record the current area's map-station byte. This is called after each
; normal/custom map construction and explicitly by Tourian's setup ASM.
sm_persist_current_map_station:
	php
	rep #$30
	pha : phx

	lda.l config_sm_map_randomization
	beq .done

	lda $1F5B
	and #$00FF
	cmp #$0008
	bcs .done
	tax

	sep #$20
	lda.l $7ED908,x
	ora.l !SM_PERSIST_MAP_STATIONS,x
	sta.l !SM_PERSIST_MAP_STATIONS,x

.done
	rep #$30
	plx : pla
	plp
	rtl

; Replacement for Tourian's setup ASM at $8F:C90A. It uses the randomized
; map-area index, preserves the vanilla collected-map behavior, and records
; the station byte immediately.
sm_set_tourian_collected_map:
	rep #$30
	ldx $1F5B
	lda.l $7ED908,x
	ora #$0001
	sta.l $7ED908,x
	sta $0789
	jsl sm_persist_current_map_station
	rtl

; Union the persistent state with a successfully loaded slot-0 save. Writing
; the union to both sides seeds the persistent block from existing saves while
; guaranteeing that neither explored bits nor station flags can be removed.
sm_merge_persistent_map_progress:
	php
	rep #$30
	pha : phx

	lda.l config_sm_map_randomization
	beq .done

	ldx #$0000
.map_loop
	lda.l !SM_PERSIST_MAP,x
	ora.l $7ECD52,x
	sta.l !SM_PERSIST_MAP,x
	sta.l $7ECD52,x
	inx : inx
	cpx #!SM_PERSIST_MAP_SIZE
	bne .map_loop

	ldx #$0000
.station_loop
	lda.l !SM_PERSIST_MAP_STATIONS,x
	ora.l $7ED908,x
	sta.l !SM_PERSIST_MAP_STATIONS,x
	sta.l $7ED908,x
	inx : inx
	cpx #!SM_PERSIST_MAP_STATIONS_SIZE
	bne .station_loop

.done
	plx : pla
	plp
	rtl

sm_persistent_map_code_end:
assert sm_persistent_map_code_end == $B5F0C2
warnpc $B5F0C2
