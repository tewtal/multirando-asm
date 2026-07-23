;  Sound engine hooks

; This hooks the routine that uses indirect addressing to write
; SFX data to APU registers and redirects it properly
%hook($B384, "jsr LoadSFXRegisters")

; Separate regular and multichannel music phases from the surrounding SFX
; phases. The wrappers selectively suppress only music-generated APU writes.
%hook($B3CD, "jsr MSU_MultiMusicWrapper")
%hook($B3D3, "jsr MSU_MusicWrapper")

; Stop the PCM when the engine takes the NoiseSFXFlag bit-0 silence path,
; and mute it across the pause freeze (PauseSFX's ClearSounds call).
%hook($B3EB, "jsr MSU_SilenceMusicWrapper")
%hook($B392, "jsr MSU_PauseClearSoundsWrapper")

; Hook initial status register write
%hook($C0A3, "jsr WriteAPUControl")

; Hook writes to Square Wave Channel 1
%hook($B440, "jsr WriteAPUSq0Ctrl0")
%hook($B5CF, "jsr WriteAPUSq0Ctrl0")
%hook($B5FF, "jsr WriteAPUSq0Ctrl0")
%hook($B6F4, "jsr WriteAPUSq0Ctrl0")
%hook($B78F, "jsr WriteAPUSq0Ctrl0")
%hook($BA8C, "jsr WriteAPUSq0Ctrl0_Y")
%hook($BB8E, "jsr WriteAPUSq0Ctrl0_I_Y")

%hook($B5D7, "jsr WriteAPUSq0Ctrl1")
%hook($BA15, "jsr WriteAPUSq0Ctrl1")
%hook($BBA5, "jsr WriteAPUSq0Ctrl1_I_Y")

%hook($B635, "jsr WriteAPUSq0Ctrl2")
%hook($B661, "jsr WriteAPUSq0Ctrl2")
%hook($B67C, "jsr WriteAPUSq0Ctrl2")
%hook($B6C0, "jsr WriteAPUSq0Ctrl2")
%hook($B7A0, "jsr WriteAPUSq0Ctrl2")
%hook($BA1B, "jsr WriteAPUSq0Ctrl2")
%hook($BB99, "jsr WriteAPUSq0Ctrl2_I_Y")

%hook($B6C6, "jsr WriteAPUSq0Ctrl3")
%hook($BA21, "jsr WriteAPUSq0Ctrl3")
%hook($BB9F, "jsr WriteAPUSq0Ctrl3_I_Y")

; Hook writes to Square Wave Channel 2
%hook($B443, "jsr WriteAPUSq1Ctrl0")
%hook($B5D2, "jsr WriteAPUSq1Ctrl0")
%hook($B602, "jsr WriteAPUSq1Ctrl0")
%hook($BA88, "jsr WriteAPUSq1Ctrl0_Y")

%hook($B5DA, "jsr WriteAPUSq1Ctrl1")
%hook($BA27, "jsr WriteAPUSq1Ctrl1")

%hook($B62F, "jsr WriteAPUSq1Ctrl2")
%hook($B66F, "jsr WriteAPUSq1Ctrl2")
%hook($B691, "jsr WriteAPUSq1Ctrl2")
%hook($BA2D, "jsr WriteAPUSq1Ctrl2")

%hook($BA33, "jsr WriteAPUSq1Ctrl3")

; Hook write to Triangle Channel
%hook($B44B, "jsr WriteAPUTriCtrl0")
%hook($B898, "jsr WriteAPUTriCtrl0")

%hook($B828, "jsr WriteAPUTriCtrl2")
%hook($B86C, "jsr WriteAPUTriCtrl2")
%hook($B8C7, "jsr WriteAPUTriCtrl2")

%hook($B830, "jsr WriteAPUTriCtrl3")
%hook($B874, "jsr WriteAPUTriCtrl3")
%hook($B8A0, "jsr WriteAPUTriCtrl3")
%hook($B8CE, "jsr WriteAPUTriCtrl3")

; Hook write to Noise Channel
%hook($B446, "jsr WriteAPUNoiseCtrl0")
%hook($B524, "jsr WriteAPUNoiseCtrl0")
%hook($B594, "jsr WriteAPUNoiseCtrl0")
%hook($BBE8, "jsr WriteAPUNoiseCtrl0")

%hook($B56A, "jsr WriteAPUNoiseCtrl2")
%hook($BBEE, "jsr WriteAPUNoiseCtrl2")

%hook($BBF4, "jsr WriteAPUNoiseCtrl3")

; Hook writes to frame counter
%hook($B3B6, "jsr WriteApuFrameCounter")
