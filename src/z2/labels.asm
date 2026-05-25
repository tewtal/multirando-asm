!VScrollOffset = $0F
!VSpriteOffset = $0F

; INIDISP = $2100
; TM = $212C
; TS = $212D
; SETINI = $2133
; BGMODE = $2105
; MOSAIC = $2106

; NMITIMEN = $4200
; RDNMI = $4210

z2_NMIJumpBank = $0813
z2_BankSwitchBank = $0FF2
z2_BankSwitchAddr = $0FF0

z2_CurVScroll = $FC
z2_CurHScroll = $FD

z2_CurMMC1Control = $A00
z2_NTTransferOffset = $A02
z2_AttrTransferOffset = $A04
z2_CurSplitVScroll = $A06
z2_VScrolling = $A08

z2_ChrBank0Current = $A10
z2_ChrBank0Request = $A14

z2_ChrBankSource = $A20
z2_ChrBankTarget = $A24

z2_Sq0Duty_4000 = $900
z2_Sq0Sweep_4001 = $901
z2_Sq0Timer_4002 = $902
z2_Sq0Length_4003 = $903
z2_Sq1Duty_4004 = $904
z2_Sq1Sweep_4005 = $905
z2_Sq1Timer_4006 = $906
z2_Sq1Length_4007 = $907
z2_TrgLinear_4008 = $908
z2_TrgTimer_400A = $90A
z2_TrgLength_400B = $90B
z2_NoiseVolume_400C = $90C
z2_NoisePeriod_400E = $90E
z2_NoiseLength_400F = $90F
z2_DmcFreq_4010 = $910
z2_DmcCounter_4011 = $911
z2_DmcAddress_4012 = $912
z2_DmcLength_4013 = $913
z2_ApuStatus_4015 = $915

z2_APUBase = $0900
z2_APUExtraControl = $0916
z2_APUSq0Length = $0920
z2_APUSq1Length = $0922
z2_APUTriLength = $0924
z2_APUNoiLength = $0926
z2_APUIOTemp = $0928

struct Z2ATTR $7E0B30
    .TopLeft: skip 1
    .TopRight: skip 1
    .BottomLeft: skip 1
    .BottomRight: skip 1
endstruct

struct Z2OAMNES $7E0200
    .Y: skip 1
    .Index: skip 1
    .Attr: skip 1
    .X: skip 1
endstruct

struct Z2OAM $7E2000
    .X: skip 1
    .Y: skip 1
    .Index: skip 1
    .Attr: skip 1
endstruct

z2_SnesPPUDataString = $7E3002
z2_SnesPPUDataStringPtr = $7E3000

; Snes Port Labels
z2_PPUAddress = $0800
z2_PPUAddressLo = $0800
z2_PPUAddressHi = $0801

z2_LastWritten = $0B08
z2_TransferCount = $0B0A
z2_TransferAddress = $0B0C
z2_TransferNT = $0B10
z2_TransferTmp = $0B12
z2_TransferRLE = $0B14
z2_TransferFlags = $0B16
z2_TransferTarget = $0B18
z2_TransferSourceSet = $0B20
z2_PalIdx = $0B0E

z2_NeedsBGPriorityUpdate = $0B22

z2_PPUAddrTmpLo = $0A30
z2_PPUAddrTmpHi = $0A32
z2_ScrollYDMA = $0A40
z2_ScrollXDMA = $0A42
z2_VScrollAddrTmp = $0A44
z2_VScrollSplit = $0A46
z2_VScrollSplitTest = $0A48

z2_ButtonsPressedSnes = $0A4A
z2_ButtonsDownSnes = $0A4C

z2_MirrorCntrl = $fa
z2_ScrollY = $fc
z2_ScrollX = $fd
z2_PPUCNT1ZP = $fe
z2_PPUCNT0ZP = $ff
z2_Sprite00RAM = $0200
z2_NMIStatus = $1a
z2_ScrollDir = $49
z2_TempScrollDir = $4a
z2_PPUDataPending = $1B	; 1=not PPU data pending, 1=data pending.
z2_PPUStrIndex = $0301	    ; # of bytes of data in PPUDataString. #$4F bytes max.
z2_PPUDataString = $0302	; Thru $07F0. String of data bytes to be written to PPU.