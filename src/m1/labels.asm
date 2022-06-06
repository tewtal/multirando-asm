; Snes Port Labels
PPUAddress = $0800
PPUAddressLo = $0800
PPUAddressHi = $0801

NMIJumpBank = $0813

BankSwitchBank = $0FF2
BankSwitchAddr = $0FF0

LastWritten = $0B08
TransferCount = $0B0A
TransferAddress = $0B0C
TransferNT = $0B10
TransferTmp = $0B12
TransferRLE = $0B14
TransferFlags = $0B16
TransferTarget = $0B18
TransferSourceSet = $0B20
PalIdx = $0B0E

APUBase = $0900
APUExtraControl = $0916
APUSq0Length = $0920
APUSq1Length = $0922
APUTriLength = $0924
APUNoiLength = $0926


M1CurMMC1Control = $0A00
M1NTTransferOffset = $0A02
M1AttrTransferOffset = $0A04
M1CurSplitVScroll = $0A06
M1VScrolling = $0A08

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

SnesPPUDataString = $7E3002
SnesPPUDataStringPtr = $7E3000

; Internal M1 RAM Labels
MirrorCntrl = $fa
ScrollY = $fc
ScrollX = $fd
PPUCNT1ZP = $fe
PPUCNT0ZP = $ff
Sprite00RAM = $0200
NMIStatus = $1a
ScrollDir = $49
TempScrollDir = $4a
PPUDataPending = $1B	; 1=not PPU data pending, 1=data pending.
PPUStrIndex = $07A0	    ; # of bytes of data in PPUDataString. #$4F bytes max.
PPUDataString = $07A1	; Thru $07F0. String of data bytes to be written to PPU.

; Internal M1 Functions
GetRoomNum = $E720