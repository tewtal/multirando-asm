; Zelda 1 MSU adapter. The original sequencer continues to run, but writes
; emitted during DriveSong are discarded while a PCM replacement is active.

MSU_DriveTune1Wrapper:
    php
    sep #$30
    phx : phy
    lda.w Tune1Request
    cmp.b #$40
    bne .select_suppression
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20
    lda.w #$00D2
    jsr MSU_TryQueueTrack
    bcs .game_over_native
    sep #$20
    lda.b #!MSU_OWNER_Z1 : sta.l !MSU_OWNER
    lda.b #$01 : sta.l !MSU_NATIVE_MUTE
    bra .suppress
.game_over_native:
    jsl mb_MSU_Stop
    sep #$20
.select_suppression:
    lda.l !MSU_NATIVE_MUTE
    beq .audible
    rep #$20
    lda.l !MSU_REQUEST_TRACK : cmp.w #$00D2 : beq .suppress16
    lda.l !MSU_CURRENT_TRACK : cmp.w #$00D2 : bne .audible16
.suppress16:
    sep #$20
.suppress:
    lda.b #$01
    bra .drive
.audible16:
    sep #$20
.audible:
    lda.b #$00
.drive:
    sta.l !MSU_WRITE_SUPPRESS
    jsr $9AD5                       ; Vanilla DriveTune1
    lda.b #$00 : sta.l !MSU_WRITE_SUPPRESS
    ply : plx : plp
    rts

MSU_DriveSongWrapper:
    php
    sep #$30
    phx : phy
    lda.w SongRequest
    beq .drive
    jsr MSU_HandleSongRequest
.drive:
    lda.l !MSU_NATIVE_MUTE
    sta.l !MSU_WRITE_SUPPRESS
    beq .no_restore
    ; Undo the pause-path PCM mute once the engine is driving music again.
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_Z1 : bne .no_restore
    lda.l !MSU_STATE : cmp.b #!MSU_STATE_PLAYING : bne .no_restore
    lda.l config_msu_volume : sta.l $002006     ; MSU volume register
.no_restore:
    jsr $9C6B                       ; Vanilla DriveSong
    lda.b #$00
    sta.l !MSU_WRITE_SUPPRESS
    ply : plx : plp
    rts

; Every native background-song stop funnels through SilenceSong at $9D46:
; the Tune0 $80 silence signal (caves, death, mode changes, demo/ending),
; the bit-7 tune pre-silence (recorder), and non-repeating songs reaching
; their end marker. Vanilla zeroes Song and flushes $4015; mirror it by
; stopping the PCM. The hook replaces the leading LDA #$00 : STA Song, and
; the caller still expects A=$00 for the queued $4015 write that follows.
MSU_SilenceSongWrapper:
    lda.b #$00
    sta.w Song
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_Z1 : bne .done
    lda.l !MSU_NATIVE_MUTE : beq .done
    jsl mb_MSU_Stop
.done:
    lda.b #$00
    rts

; While Paused ($E0) is nonzero the engine silences the channels each frame
; and freezes the song sequencer instead of stopping it (Select pause and
; the potion heart-fill). DriveSong is skipped entirely on that path, so
; mute the PCM here; MSU_DriveSongWrapper restores the volume when the
; engine resumes. Called with A=$00 in place of the original silence write.
MSU_PauseSilenceWrapper:
    jsr WriteAPUControl
    lda.l !MSU_OWNER : cmp.b #!MSU_OWNER_Z1 : bne .done
    lda.l !MSU_NATIVE_MUTE : beq .done
    lda.b #$00 : sta.l $002006                  ; MSU volume register
.done:
    rts

MSU_HandleSongRequest:
    lda.w SongRequest
    cmp.b #$80 : beq .title
    cmp.b #$40 : bne + : jmp .dungeon : +
    cmp.b #$20 : bne + : jmp .level9 : +
    cmp.b #$10 : beq .ending
    cmp.b #$08 : beq .item
    cmp.b #$06 : beq .zelda
    cmp.b #$04 : beq .level_clear
    cmp.b #$02 : beq .ganon
    cmp.b #$01 : beq .overworld
    jmp .native

.title:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00C9
    jmp .queue
.overworld:
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00CA
    jmp .queue
.ending:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00D1
    jmp .queue
.item:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00D0
    jmp .queue
.zelda:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00CF
    jmp .queue
.level_clear:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00CE
    jmp .queue
.ganon:
    lda.b #$01 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00CD
    jmp .queue

.dungeon:
    ; Levels 1-8 use tracks 211-218.
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    lda.b CurLevel
    beq .generic_dungeon
    cmp.b #$0A : bcs .generic_dungeon
    rep #$20
    and.w #$00FF
    clc : adc.w #$00D2
    bra .queue
.generic_dungeon:
    lda.b CurLevel
    cmp.b #$09 : beq .level9
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00CB
    bra .queue

.level9:
    ; Level 9 always requests the $20 song (never the $40 dungeon song), so
    ; it has no dungeon-specific slot; 204 is its dedicated theme.
    lda.b #$03 : sta.l !MSU_REQUEST_CONTROL
    rep #$20 : lda.w #$00CC

.queue:
    jsr MSU_TryQueueTrack
    bcc .success
.native:
    jsl mb_MSU_Stop
    sep #$20
    sec
    rts
.success:
    sep #$20
    lda.b #!MSU_OWNER_Z1 : sta.l !MSU_OWNER
    lda.b #$01 : sta.l !MSU_NATIVE_MUTE
    clc
    rts

; A16 = physical track, control already stored. Carry mirrors mb_MSU_Request.
MSU_TryQueueTrack:
    php
    rep #$20
    pha
    sep #$20
    lda.b #!MSU_OWNER_Z1 : sta.l !MSU_OWNER
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
