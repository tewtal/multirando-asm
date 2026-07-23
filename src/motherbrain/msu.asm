; Shared MSU-1 runtime transport.

; Queue A16, using its resolved fallback when necessary.
; Returns carry set if no track is available.
MSU_Request:
    php
    rep #$30
    phx
    tax
    sep #$20
    lda.l !MSU_PRESENT
    beq .missing
    rep #$20
    cpx.w #!MSU_TRACK_CACHE_SIZE
    bcs .missing
    sep #$20
    lda.l !MSU_TRACK_CACHE,x
    bne .found

    rep #$20
    txa
    asl
    tax
    lda.l !MSU_FALLBACK_TABLE,x
    beq .missing
    tax
    sep #$20

.found:
    rep #$20
    txa
    sta.l !MSU_REQUEST_TRACK
    sep #$20
    lda.l !MSU_STATE
    cmp.b #!MSU_STATE_PLAYING
    beq +
    rep #$20
    lda.w #$0000
    sta.l !MSU_SELECTED_TRACK
+
    rep #$20
    lda.w #$0000
    sta.l !MSU_BUSY_FRAMES
    sep #$20
    lda.b #!MSU_STATE_REQUESTED
    sta.l !MSU_STATE
    rep #$30
    plx
    plp
    clc
    rtl
.missing:
    rep #$30
    plx
    plp
    sec
    rtl


; Advance the transport by at most one step.
MSU_Service:
    php
    rep #$30
    pha
    phx
    sep #$20
    lda.l !MSU_PRESENT
    bne .dispatch
    jmp .done

.dispatch:
    lda.l !MSU_STATE
    cmp.b #!MSU_STATE_STOPPING
    beq .stop_pending
    cmp.b #!MSU_STATE_ERROR
    beq .stop_pending
    cmp.b #!MSU_STATE_PLAYING
    beq .check_one_shot
    cmp.b #!MSU_STATE_REQUESTED
    beq .advance
    cmp.b #!MSU_STATE_LOADING
    beq .advance
    jmp .done
.stop_pending:
    jmp .finish_stop

.check_one_shot:
    rep #$20
    lda.l !MSU_BUSY_FRAMES
    beq .check_playing
    dec
    sta.l !MSU_BUSY_FRAMES
    sep #$20
    jmp .done
.check_playing:
    sep #$20
    lda.l !MSU_REQUEST_CONTROL
    and.b #$02
    bne .playing
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_PLAYING
    bne .playing
    lda.b #$00
    sta.l !MSU_NATIVE_MUTE
    sta.l !MSU_EXPECTED_SPC
    lda.b #!MSU_STATE_ENDED
    sta.l !MSU_STATE
    jmp .done
.playing:
    jmp .done

.advance:
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_BUSY
    beq .ready
.wait_frame:
    rep #$20
    lda.l !MSU_BUSY_FRAMES
    inc
    sta.l !MSU_BUSY_FRAMES
    cmp.w #!MSU_BUSY_TIMEOUT
    bcs .request_timeout
    jmp .done16
.request_timeout:
    sep #$20
    lda.b #$00
    sta.l !MSU_VOLUME
    sta.l !MSU_NATIVE_MUTE
    rep #$20
    lda.w #$0000
    sta.l !MSU_REQUEST_TRACK
    sep #$20
    lda.b #!MSU_STATE_ERROR
    sta.l !MSU_STATE
    jmp .done

.ready:
    rep #$20
    lda.l !MSU_REQUEST_TRACK
    bne .has_request
    jmp .idle16
.has_request:
    cmp.l !MSU_SELECTED_TRACK
    beq .selected

    ; Mute before selecting a new track.
    sep #$20
    lda.b #$00
    sta.l !MSU_VOLUME
    rep #$20
    lda.l !MSU_REQUEST_TRACK
    sta.l !MSU_TRACK
    sta.l !MSU_SELECTED_TRACK
    sep #$20
    lda.b #!MSU_STATE_LOADING
    sta.l !MSU_STATE
    jmp .done

.selected:
    sep #$20
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_MISSING
    bne .missing_track

    lda.l !MSU_EXPECTED_SPC
    beq .start
    cmp.l !MSU_SPC_IO0
    beq .start
    jmp .wait_frame
.start:
    lda.l !MSU_REQUEST_CONTROL
    sta.l !MSU_CONTROL
    lda.l config_msu_volume
    sta.l !MSU_VOLUME
    rep #$20
    lda.l !MSU_REQUEST_TRACK
    sta.l !MSU_CURRENT_TRACK
    lda.w #$0002
    sta.l !MSU_BUSY_FRAMES
    lda.w #$0000
    sta.l !MSU_REQUEST_TRACK
    sep #$20
    lda.b #$00
    sta.l !MSU_EXPECTED_SPC
    lda.b #!MSU_STATE_PLAYING
    sta.l !MSU_STATE
    bra .done

.missing_track:
    rep #$20
    lda.l !MSU_REQUEST_TRACK
    tax
    sep #$20
    lda.b #$00
    sta.l !MSU_TRACK_CACHE,x
    sta.l !MSU_VOLUME
    sta.l !MSU_CONTROL
    sta.l !MSU_NATIVE_MUTE
    rep #$20
    lda.w #$0000
    sta.l !MSU_REQUEST_TRACK
    sta.l !MSU_SELECTED_TRACK
    sta.l !MSU_CURRENT_TRACK
    sep #$20
    lda.b #!MSU_STATE_MISSING
    sta.l !MSU_STATE
    bra .done

.finish_stop:
    lda.b #$00
    sta.l !MSU_VOLUME
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_BUSY
    bne .done
    lda.b #$00
    sta.l !MSU_CONTROL
    rep #$20
    lda.w #$0000
    sta.l !MSU_SELECTED_TRACK
    sta.l !MSU_CURRENT_TRACK
.idle16:
    sep #$20
    lda.b #!MSU_STATE_IDLE
    sta.l !MSU_STATE
    bra .done

.done16:
    sep #$20
.done:
    rep #$30
    plx
    pla
    plp
    rtl

; Mute PCM and cancel the current request.
MSU_Stop:
    php
    rep #$20
    pha
    sep #$20
    lda.b #$00
    sta.l !MSU_VOLUME
    sta.l !MSU_NATIVE_MUTE
    sta.l !MSU_WRITE_SUPPRESS
    sta.l !MSU_EXPECTED_SPC
    sta.l !MSU_OWNER
    rep #$20
    lda.w #$0000
    sta.l !MSU_REQUEST_TRACK
    sta.l !MSU_BUSY_FRAMES
    sep #$20
    lda.b #!MSU_STATE_STOPPING
    sta.l !MSU_STATE
    lda.l !MSU_STATUS
    and.b #!MSU_STATUS_BUSY
    bne .return
    lda.b #$00
    sta.l !MSU_CONTROL
    rep #$20
    lda.w #$0000
    sta.l !MSU_SELECTED_TRACK
    sta.l !MSU_CURRENT_TRACK
    sep #$20
    lda.b #!MSU_STATE_IDLE
    sta.l !MSU_STATE
.return:
    rep #$20
    pla
    plp
    rtl

; Save the current position and force the next request to reselect.
MSU_SaveResume:
    php
    rep #$20
    pha
    sep #$20
    lda.l !MSU_PRESENT
    beq .return
    lda.l !MSU_STATE
    cmp.b #!MSU_STATE_PLAYING
    bne .return
    lda.b #$04
    sta.l !MSU_CONTROL
    rep #$20
    lda.w #$0000
    sta.l !MSU_SELECTED_TRACK
.return:
    rep #$20
    pla
    plp
    rtl
