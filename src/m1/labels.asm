; Snes Port Labels
m1_PPUAddress = $0800
m1_PPUAddressLo = $0800
m1_PPUAddressHi = $0801
m1_NMIJumpBank = $0813

m1_TableBankTemp = $0820


m1_BankSwitchBank = $0FF2
m1_BankSwitchAddr = $0FF0

m1_LastWritten = $0B08
m1_TransferCount = $0B0A
m1_TransferAddress = $0B0C
m1_TransferNT = $0B10
m1_TransferTmp = $0B12
m1_TransferRLE = $0B14
m1_TransferFlags = $0B16
m1_TransferTarget = $0B18
m1_TransferSourceSet = $0B20
m1_PalIdx = $0B0E

; Automap state
m1_MiniMapAreaTmp = $0A20
m1_MiniMapIndexTmp = $0A22
m1_HudRedraw = $0A24        ; Nonzero = DMA the HUD tilemap buffer to BG3 during next NMI
m1_MiniMapCellTmp = $0A26   ; Player's current world-map cell index (Y*32+X)
m1_MiniMapRevealedTmp = $0A28 ; Nonzero while rendering an area revealed by a map station/item
m1_MapViewArea = $0A2A      ; Area index shown in the full-screen map view
m1_MapViewDMA = $0A2C       ; Nonzero = NMI bulk-copies the map-view buffer to BG3
m1_MapViewActive = $0A2E    ; Nonzero while the full-screen map view is open
m1_MapViewVofs = $0A30      ; BG3 vertical scroll while the map view is open
m1_MapViewTick = $0A32      ; Set by NMI each frame; the frozen view loop waits on it
m1_PadHeld = $0A34          ; SNES controller word from the previous frame (edge detect)
m1_MapViewBndX = $0A36      ; Viewed area bounds: minX | maxX<<8
m1_MapViewBndY = $0A38      ; Viewed area bounds: minY | maxY<<8
m1_MapViewShiftX = $0A3A    ; Compose translation (signed): dest col = src col + shift
m1_MapViewShiftY = $0A3C    ; Compose translation (signed): dest row = src row + shift
m1_MapViewTgtTmp = $0A3E    ; Scratch for the centering math
m1_MapViewSrcRow = $0A40    ; Compose loop: current source row
m1_MapViewSrcCol = $0A42    ; Compose loop: current source column
m1_MapViewTileBase = $0A44  ; Byte offset of the viewed area's ROM tilemap
m1_MapViewVisitBase = $0A46 ; Byte offset of the viewed area's visited plane
m1_MapViewSrcCell = $0A48   ; Compose loop: current source cell index
m1_MapViewTileTmp = $0A4A   ; Compose loop: current tilemap word
m1_MapViewMaskTmp = $0A4C   ; Compose loop: visited bit mask
m1_MapViewMaxX = $0A4E      ; Compose loop: inclusive source-column limit
m1_MapViewMaxY = $0A50      ; Compose loop: inclusive source-row limit
m1_MapViewDestTmp = $0A52   ; Compose loop: destination byte offset
m1_MapLastCell = $0A54      ; area*$400+cell the tracker last rendered; $FFFF forces one
m1_MiniMapTileTmp = $0A56   ; Minimap loop: current tilemap word
m1_MapViewBuffer = $7E8800  ; 32x32-word compose buffer for the full-screen map view

M1CurMMC1Control = $0A00
M1NTTransferOffset = $0A02
M1AttrTransferOffset = $0A04
M1CurSplitVScroll = $0A06
M1VScrolling = $0A08

; Item animations
;struct Animations $0aa0  ;  Already defined in common/nes/items.asm; but don't put anything else here

struct ATTR $7E0B30
    .TopLeft: skip 1
    .TopRight: skip 1
    .BottomLeft: skip 1
    .BottomRight: skip 1
endstruct

struct OAMNES $7E0200
    .Y: skip 1
    .Index: skip 1
    .Attr: skip 1
    .X: skip 1
endstruct

struct OAM $7E2000
    .X: skip 1
    .Y: skip 1
    .Index: skip 1
    .Attr: skip 1
endstruct

m1_SnesPPUDataString = $7E3002
m1_SnesPPUDataStringPtr = $7E3000

; Internal M1 RAM Labels
m1_FrameCounter = $2d
m1_RoomPalette = $68
m1_CurrentArea = $74    ;  $10 = Brinstar, $11 = Norfair, $12 = Kraid, $13 = Tourian, $14 = Ridley
m1_MapPosY = $4f
m1_MapPosX = $50
m1_MirrorCntrl = $fa
m1_ScrollY = $fc
m1_ScrollX = $fd
m1_PPUCNT1ZP = $fe
m1_PPUCNT0ZP = $ff
m1_Sprite00RAM = $0200
m1_NMIStatus = $1a
m1_ScrollDir = $49
m1_TempScrollDir = $4a
m1_PPUDataPending = $1B	; 1=not PPU data pending, 1=data pending.
m1_PPUStrIndex = $07A0	    ; # of bytes of data in PPUDataString. #$4F bytes max.
m1_PPUDataString = $07A1	; Thru $07F0. String of data bytes to be written to PPU.

; Internal M1 Functions
GetRoomNum = $E720

; Vanilla M1 "unique item history" RAM (NES cart RAM), used only by Mother Brain and the
; 5 Zebetites. The scan indexes entries with y = count (even, descending): writes store
; $06 at UnqItmHist,y and $07 at UnqItmHist+1,y; the scan reads them back as
; NumUniqueItems,y ($07) and DataSlot,y ($06). The differing bases line up because the
; scan starts at y = count (see CheckForItem_plane .linear).
DataSlot       = $6885      ; $06 high-byte read base in the scan
NumUniqueItems = $6886      ; entry count, increments by 2; also the $07 read base
UnqItmHist     = $6887      ; thru $68FC: write base, 2 bytes per entry

; Collected-object bit planes for items and doors, indexed by world-map cell (Y*32+X),
; 1 bit/cell, 128 bytes each. 
m1_ItemBitArray = $7E00     ; item plane  ($7E00-$7E7F)
m1_DoorBitArray = $7E80     ; door plane  ($7E80-$7EFF)

; Automap buffers
m1_MiniMapBuffer = $7E8000  ; HUD tilemap buffer (3 full BG3 rows) DMA:d to VRAM word $5020;
                            ; the minimap occupies columns 24-28 (byte offset $30 per row)
