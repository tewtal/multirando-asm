;  Sound engine hooks

!B0 = ((!BASE_BANK)<<16)
!B7 = ((!BASE_BANK+$7)<<16)

;  APU Status writes ($4015)
org !B0+$982B : jsr WriteAPUControl
org !B0+$9830 : jsr WriteAPUControl
org !B0+$9928 : jsr WriteAPUControl
org !B0+$9BA6 : jsr WriteAPUControl
org !B0+$9D4B : jsr WriteAPUControl
org !B0+$9D50 : jsr WriteAPUControl
org !B7+$E465 : jsr WriteAPUControl
org !B7+$ec46 : jsr WriteAPUControl
org !B0+$9be5 : jsr WriteAPUControl
org !B0+$9bea : jsr WriteAPUControl

;  Frame counter writes ($4017)
org !B0+$9837 : jsr WriteApuFrameCounter

;  Square Wave Channel 1 writes ($4000 -> $4003)
org !B0+$9900 : jsr WriteAPUSq0Ctrl0_X
org !B0+$9911 : jsr WriteAPUSq0Ctrl0
org !B0+$9C06 : jsr WriteAPUSq0Ctrl0_X
org !B0+$9E01 : jsr WriteAPUSq0Ctrl0

org !B0+$9922 : jsr WriteAPUSq0Ctrl1
org !B0+$9C03 : jsr WriteAPUSq0Ctrl1_Y
org !B0+$9E16 : jsr WriteAPUSq0Ctrl1

org !B0+$990A : jsr WriteAPUSq0Ctrl2_X
org !B0+$9C15 : jsr WriteAPUSq0Ctrl2
org !B0+$9E11 : jsr WriteAPUSq0Ctrl2_X

org !B0+$9905 : jsr WriteAPUSq0Ctrl3_X
org !B0+$9C1D : jsr WriteAPUSq0Ctrl3

;  Square Wave Channel 2 writes ($4004 -> $4007)
org !B0+$9B14 : jsr WriteAPUSq1Ctrl0_X
org !B0+$9B3C : jsr WriteAPUSq1Ctrl0
org !B0+$9B57 : jsr WriteAPUSq1Ctrl0
org !B0+$9C21 : jsr WriteAPUSq1Ctrl0_X
org !B0+$9D96 : jsr WriteAPUSq1Ctrl0

org !B0+$9B37 : jsr WriteAPUSq1Ctrl1
org !B0+$9C24 : jsr WriteAPUSq1Ctrl1_Y
org !B0+$9D9B : jsr WriteAPUSq1Ctrl1_X

org !B0+$9B21 : jsr WriteAPUSq1Ctrl2_X
org !B0+$9B61 : jsr WriteAPUSq1Ctrl2_X
org !B0+$9C33 : jsr WriteAPUSq1Ctrl2
org !B0+$9DAB : jsr WriteAPUSq1Ctrl2_X

org !B0+$9B19 : jsr WriteAPUSq1Ctrl3_X
org !B0+$9C3B : jsr WriteAPUSq1Ctrl3

;  Triangle Channel writes ($4008 -> $400b)
org !B0+$9E5D : jsr WriteAPUTriCtrl0
org !B0+$9E92 : jsr WriteAPUTriCtrl0

org !B0+$9C48 : jsr WriteAPUTriCtrl2
org !B0+$9E84 : jsr WriteAPUTriCtrl2_X

org !B0+$9C50 : jsr WriteAPUTriCtrl3

;  Noise Channel writes ($400c -> $400f)
org !B0+$997B : jsr WriteAPUNoiseCtrl0
org !B0+$9989 : jsr WriteAPUNoiseCtrl0
org !B0+$9A2A : jsr WriteAPUNoiseCtrl0
org !B0+$9EC4 : jsr WriteAPUNoiseCtrl0

org !B0+$9971 : jsr WriteAPUNoiseCtrl2
org !B0+$99F4 : jsr WriteAPUNoiseCtrl2_X
org !B0+$9A2F : jsr WriteAPUNoiseCtrl2_X
org !B0+$9ECA : jsr WriteAPUNoiseCtrl2

org !B0+$9980 : jsr WriteAPUNoiseCtrl3
org !B0+$9A34 : jsr WriteAPUNoiseCtrl3
org !B0+$9ED0 : jsr WriteAPUNoiseCtrl3

;  DMC writes ($4010 -> $4013)
org !B0+$9bcf : jsr WriteAPUDMCFreq
org !B0+$9bb7 : jsr WriteAPUDMCCounter
org !B7+$e460 : jsr WriteAPUDMCCounter
org !B0+$9bd5 : jsr WriteAPUDMCAddr
org !B0+$9bdb : jsr WriteAPUDMCLength