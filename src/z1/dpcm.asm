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

    ldy #$4000  ;  Start an upload at $4000 aram
    jsr spc_begin_upload

    ;  Send brr_swordbeam to aram
    ldx #$0000

.nextbyte:
    lda brr_swordbeam,x
    jsr spc_upload_byte
    inx
    cpx #(brr_swordbeamend-brr_swordbeam)
    bne .nextbyte

    ; lda #$fe  ;  upload test bytes
    ; jsr spc_upload_byte
    ; lda #$dc  ;  upload test bytes
    ; jsr spc_upload_byte
    ; lda #$ba  ;  upload test bytes
    ; jsr spc_upload_byte

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