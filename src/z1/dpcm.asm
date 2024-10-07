;  Send 2 copies of a 16-bit aram address to audio ram.
;  e.g.: $4014,$4014
macro uploadDirectoryEntry(entry)
    rep #$30    ; 16-bit load
    lda #<entry>
    sep #$20    ; 8-bit A
    jsr spc_upload_byte
    xba
    jsr spc_upload_byte
    rep #$30    ; 16-bit load
    lda #<entry>
    sep #$20    ; 8-bit A
    jsr spc_upload_byte
    xba
    jsr spc_upload_byte
endmacro

; Waits for SPC to finish booting. Call before first
; using SPC or after bootrom has been re-run.
; Preserved: X, Y
spc_wait_boot:
    lda #$AA
.wait:  cmp $2140
    bne .wait

    ; Clear in case it already has $CC in it
    ; (this actually occurred in testing)
    sta $2140

    lda #$BB
.wait2: cmp $2141
    bne .wait2
rts

; Starts upload to SPC addr Y and sets Y to
; 0 for use as index with spc_upload_byte.
; Preserved: X
spc_begin_upload:
    sty $2142

    ; Send command
    lda $2140
    clc
    adc #$22
    bne skip       ; special case fully verified
    inc
skip:  sta $2141
    sta $2140

    ; Wait for acknowledgement
waitUploadStartAck:  cmp $2140
    bne waitUploadStartAck

    ; Initialize index
    ldy #$0000
rts


; Uploads byte A to SPC and increments Y. The low byte
; of Y must not changed between calls.
; Preserved: X
spc_upload_byte:
    sta $2141

    ; Signal that it's ready
    tya
    sta $2140
    iny

    ; Wait for acknowledgement
waitUploadByteAck:
    cmp $2140
    bne waitUploadByteAck
rts


spc_init_dpcm:
    pha : phx : phy : phb : php

    sep #$20    ; 8-bit A

    jsr spc_wait_boot

    ldy #$4000  ;  Start an upload at $4000 aram
    jsr spc_begin_upload

    ;  Send scrn lookup entries to aram
    %uploadDirectoryEntry($4014)    ;  Initial position after the dmc lookup entries
    %uploadDirectoryEntry($4014+brr_swordbeamend-brr_swordbeam)    ;  Initial position after the dmc lookup entries
    %uploadDirectoryEntry($4014+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt)    ;  Initial position after the dmc lookup entries
    %uploadDirectoryEntry($4014+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt+brr_boss1end-brr_boss1)    ;  Initial position after the dmc lookup entries
    %uploadDirectoryEntry($4014+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt+brr_boss1end-brr_boss1+brr_boss2end-brr_boss2)    ;  Initial position after the dmc lookup entries

    ;  Send brr_swordbeam to aram
    ldx #$0000

.nextbyte:
    lda brr_swordbeam,x
    jsr spc_upload_byte
    inx
    cpx #(brr_swordbeamend-brr_swordbeam)
    bne .nextbyte

    ;  Send brr_linkhurt to aram
    ldx #$0000
.nextbyte2:
    lda brr_linkhurt,x
    jsr spc_upload_byte
    inx
    cpx #(brr_linkhurtend-brr_linkhurt)
    bne .nextbyte2

    ;  Send brr_boss1 to aram
    ldx #$0000
.nextbyte3:
    lda brr_boss1,x
    jsr spc_upload_byte
    inx
    cpx #(brr_boss1end-brr_boss1)
    bne .nextbyte3

    ;  Send brr_boss2 to aram
    ldx #$0000
.nextbyte4:
    lda brr_boss2,x
    jsr spc_upload_byte
    inx
    cpx #(brr_boss2end-brr_boss2)
    bne .nextbyte4

    ;  Send brr_doorunlock to aram
    ldx #$0000
.nextbyte5:
    lda brr_doorunlock,x
    jsr spc_upload_byte
    inx
    cpx #(brr_doorunlockend-brr_doorunlock)
    bne .nextbyte5

    ;  Set bit 0x80 in F1 control register
    ; ldx #$80f1    ;  prep to read IPL ROM
    ; jsr write_dsp

    ;  Jump spc to $ffc0 to reset to the IPC ROM after we've finished loading to aram
    jsr run_spc_program

    plp : plb : ply : plx : pla
rtl

write_dsp:
    phx
    ; Just do a two-byte upload to $00F2-$00F3, so we
    ; set the DSP address, then write the byte into that.
    ldy #$00F2
    jsr spc_begin_upload
    pla
    jsr spc_upload_byte     ; low byte of X to $F2
    pla
    jsr spc_upload_byte     ; high byte of X to $F3
rts

;  Execute spc starting at location in Destination
run_spc_program:
  Destination = $ffc0 ; Program's address in SPC700 RAM
  lda.b #Destination&$00ff
  sta $2142
  lda.b #Destination>>8
  sta $2143

  stz $2141          ; Zero = start the program that was sent over

  lda $2140          ; Must be at least 2 higher than the previous APUIO0 value.
  inc
  inc
  sta $2140          ; Tell the SPC700 to start running the new program.

.wait:                 ; Wait for the SPC700 to acknowledge this.
  cmp $2140
  bne .wait
rts

spc_dpcm_end:
print "spc dpcm end = ", pc