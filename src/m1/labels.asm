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

m1_APUBase = $0900
m1_APUExtraControl = $0916
m1_APUSq0Length = $0920
m1_APUSq1Length = $0922
m1_APUTriLength = $0924
m1_APUNoiLength = $0926
m1_APUIOTemp = $0928

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

m1_ItemBitArray = $7E00