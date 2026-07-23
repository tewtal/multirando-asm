; Metroid 1 MSU adapter. SoundEngine runs SFX and music as distinct phases;
; these wrappers mark only music output for suppression in EnqueueApuWrite.

!M1_MUSIC_INIT_FLAG = $0685
!M1_MULTI_SFX_FLAG = $0684
!M1_IN_AREA = $74

MSU_MusicWrapper:
    php
    sep #$30
    phx : phy
    lda.w !M1_MUSIC_INIT_FLAG
    beq .drive
    jsr MSU_HandleMusicFlag
.drive:
    lda.l !MSU_NATIVE_MUTE
    sta.l !MSU_WRITE_SUPPRESS
    beq .no_restore
    ; Undo the pause-path PCM mute once the engine is driving music again.
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_M1 : bne .no_restore
    lda.l !MSU_STATE : cmp.b #!MSU_STATE_PLAYING : bne .no_restore
    lda.l config_msu_volume : sta.l $002006     ; MSU volume register
.no_restore:
    jsr $BC36                       ; Vanilla LoadMusicTempFlags
    lda.b #$00 : sta.l !MSU_WRITE_SUPPRESS
    ply : plx : plp
    rts

; NoiseSFXFlag bit 0 (SilenceMusic: Samus death, title flow) makes the sound
; engine jump straight to InitSoundAddresses, clearing CurrentMusic and every
; channel without running the hooked music phases. Stop the PCM with it. The
; tail call keeps the vanilla A=$00/Z contract for the BEQ that follows the
; hooked JSR.
MSU_SilenceMusicWrapper:
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_M1 : bne .vanilla
    lda.l !MSU_NATIVE_MUTE : beq .vanilla
    jsl mb_MSU_Stop
.vanilla:
    jmp $B404                       ; Vanilla InitSoundAddresses

; While paused (MainRoutine 5) the engine freezes the music phases and runs
; PauseSFX once, which clears the sound registers. Mirror the freeze by
; muting the PCM; MSU_MusicWrapper restores the volume after unpausing.
; ClearSounds must stay last-equivalent: the caller expects A=$00 back.
MSU_PauseClearSoundsWrapper:
    jsr $B43E                       ; Vanilla ClearSounds
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_M1 : bne .done
    lda.l !MSU_NATIVE_MUTE : beq .done
    lda.b #$00 : sta.l $002006                  ; MSU volume register
.done:
    lda.b #$00
    rts

MSU_MultiMusicWrapper:
    php
    sep #$30
    phx : phy
    lda.w !M1_MULTI_SFX_FLAG
    and.b #$F0
    beq .sfx
    jsr MSU_HandleMultiMusicFlag
    lda.l !MSU_NATIVE_MUTE
    bra .set_suppression
.sfx:
    lda.b #$00                      ; Low-nibble multichannel events are SFX
.set_suppression:
    sta.l !MSU_WRITE_SUPPRESS
    jsr $B34B                       ; Vanilla LdMultiSFXInitFlags
    lda.b #$00 : sta.l !MSU_WRITE_SUPPRESS
    ply : plx : plp
    rts

MSU_HandleMusicFlag:
    lda.w !M1_MUSIC_INIT_FLAG
    bit.b #$80 : bne .ridley
    bit.b #$40 : bne .tourian_or_boss
    bit.b #$20 : beq + : jmp .item_room : +
    bit.b #$10 : beq + : jmp .kraid : +
    bit.b #$08 : beq + : jmp .norfair : +
    bit.b #$04 : beq + : jmp .escape : +
    bit.b #$02 : beq + : jmp .mother_brain : +
    bit.b #$01 : beq + : jmp .brinstar : +
    rts

.ridley:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0131
    jmp MSU_QueueTrack
.tourian_or_boss:
    lda.b !M1_IN_AREA
    cmp.b #$12 : beq .kraid_boss
    cmp.b #$14 : beq .ridley_boss
    cmp.b #$13 : beq .tourian
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0134
    jmp MSU_QueueTrack
.kraid_boss:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$013A
    jmp MSU_QueueTrack
.ridley_boss:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$013B
    jmp MSU_QueueTrack
.tourian:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0132
    jmp MSU_QueueTrack
.item_room:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0133
    jmp MSU_QueueTrack
.kraid:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0130
    jmp MSU_QueueTrack
.norfair:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$012F
    jmp MSU_QueueTrack
.escape:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0136
    jmp MSU_QueueTrack
.mother_brain:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0135
    jmp MSU_QueueTrack
.brinstar:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$012E
    jmp MSU_QueueTrack

MSU_HandleMultiMusicFlag:
    lda.w !M1_MULTI_SFX_FLAG
    bit.b #$80 : bne .fade
    bit.b #$40 : bne .powerup
    bit.b #$20 : bne .ending
    bit.b #$10 : bne .intro
    rts
.fade:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0139
    jmp MSU_QueueTrack
.powerup:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0137
    jmp MSU_QueueTrack
.ending:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$0138
    jmp MSU_QueueTrack
.intro:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$012D
    jmp MSU_QueueTrack

; Queue A16, using the native engine if no shared fallback is available.
MSU_QueueTrack:
    jsr MSU_TryQueueTrack
    bcc .queued
    jsl mb_MSU_Stop
    sep #$20
    sec
    rts
.queued:
    sep #$20
    lda.b #!MSU_OWNER_M1 : sta.l !MSU_OWNER
    lda.b #$01 : sta.l !MSU_NATIVE_MUTE
    clc
    rts

MSU_TryQueueTrack:
    php
    rep #$20
    pha
    sep #$20
    lda.b #!MSU_OWNER_M1 : sta.l !MSU_OWNER
    lda.b #$00 : sta.l !MSU_EXPECTED_SPC
    rep #$20
    pla
    jsl mb_MSU_Request
    bcs .missing
    plp
    clc
    rts
.missing:
    plp
    sec
    rts
