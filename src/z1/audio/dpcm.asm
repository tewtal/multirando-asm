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

;  Constant
dmc_lookup_start_pos = $4060

spc_init_dpcm:
    pha : phx : phy : phb : php

    sep #$20    ; 8-bit A

    jsr spc_wait_boot

    ;  $4000-$400f:  dmc address bytes (see ../nes-spc/spc.asm:267)
    ldy #$4000  ;  Start an upload at $4000 aram
    jsr spc_begin_upload

    lda #$00
    jsr spc_upload_byte
    lda #$1d
    jsr spc_upload_byte
    lda #$20
    jsr spc_upload_byte
    lda #$4c
    jsr spc_upload_byte
    lda #$80
    jsr spc_upload_byte
    lda #$28
    jsr spc_upload_byte

    ;  $4010-$401f:  frequency cutoff values (see ../nes-spc/spc.asm:268)
    ldy #$4010  ;  Start an upload at $4010 aram
    jsr spc_begin_upload

    lda #$0f
    jsr spc_upload_byte
    lda #$0f
    jsr spc_upload_byte
    lda #$0f
    jsr spc_upload_byte
    lda #$0f
    jsr spc_upload_byte
    lda #$0d
    jsr spc_upload_byte
    lda #$0f
    jsr spc_upload_byte

    ;  $4020-$405f: SRCN lookup entries (see ../nes-spc/spc.asm:271)
    ldy #$4020  ;  Start an upload at $4020 aram
    jsr spc_begin_upload

    ;  Send scrn lookup entries to aram
    %uploadDirectoryEntry(dmc_lookup_start_pos)    ;  Initial position after the dmc lookup entries
    %uploadDirectoryEntry(dmc_lookup_start_pos+brr_swordbeamend-brr_swordbeam)
    %uploadDirectoryEntry(dmc_lookup_start_pos+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt)
    %uploadDirectoryEntry(dmc_lookup_start_pos+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt+brr_boss2end-brr_boss2)
    %uploadDirectoryEntry(dmc_lookup_start_pos+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt+brr_boss2end-brr_boss2+brr_boss1end-brr_boss1)
    ;  The filter0 block ~22% into boss2.brr sample for dodongo roar
    %uploadDirectoryEntry(dmc_lookup_start_pos+brr_swordbeamend-brr_swordbeam+brr_linkhurtend-brr_linkhurt+$7d7)

    ldy #$4060  ;  Start an upload at $4060 aram
    jsr spc_begin_upload

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

    ;  Send brr_boss2 to aram
    ldx #$0000
.nextbyte3:
    lda brr_boss2,x
    jsr spc_upload_byte
    inx
    cpx #(brr_boss2end-brr_boss2)
    bne .nextbyte3

    ;  Send brr_boss1 to aram
    ldx #$0000
.nextbyte4:
    lda brr_boss1,x
    jsr spc_upload_byte
    inx
    cpx #(brr_boss1end-brr_boss1)
    bne .nextbyte4

    ;  Send brr_doorunlock to aram
    ldx #$0000
.nextbyte5:
    lda brr_doorunlock,x
    jsr spc_upload_byte
    inx
    cpx #(brr_doorunlockend-brr_doorunlock)
    bne .nextbyte5

    ;  Set bit 0x80 in F1 control register (already set; not needed)
    ; ldx #$80f1    ;  prep to read IPL ROM
    ; jsr write_dsp

    ;  Reset to the IPC ROM after we've finished loading to aram
    jsr reset_to_ipc_rom

    plp : plb : ply : plx : pla
rtl

;  Execute spc starting at location in Destination (the IPC rom at $ffc0)
reset_to_ipc_rom:
  Destination = $ffc0 ; Program's address in SPC700 RAM
  lda.b #Destination&$00ff
  sta $2142
  lda.b #Destination>>8
  sta $2143

  stz $2141          ; Zero = start the program that was sent over

  lda $2140          ; Must be at least 2 higher than the previous APUIO0 value.
  inc : inc
  sta $2140          ; Tell the SPC700 to start running the new program.

.wait:                 ; Wait for the SPC700 to acknowledge this.
  cmp $2140
  bne .wait
rts

spc_dpcm_end:
print "spc dpcm end = ", pc