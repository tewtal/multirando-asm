print "spc init driver start = ", pc
spc_init_driver:
    pha : phx : phy : phb : php
    
    rep #$30
    ldy #spc_driver
    phk : plb
    jsr send_apu_data

    plp : plb : ply : plx : pla
    rtl

;;; SPC Upload Code Borrowed from Super Metroid ;;;
;;; $8059: Send APU data ;;;
send_apu_data:
{
;; Parameters:
;;     Y: Address of data
;;     DB: Bank of data

; Data format:
;     ssss dddd [xx xx...] (data block 0)
;     ssss dddd [xx xx...] (data block 1)
;     ...
;     0000 aaaa
; Where:
;     s = data block size in bytes
;     d = destination address
;     x = data
;     a = entry address. Ignored by SPC engine after first APU transfer

; The xx data can cross bank boundaries, but the data block entries otherwise can't (i.e. s, d, a and 0000) unless they're word-aligned

; Wait until APU sets APU IO 0..1 = AAh BBh
; Kick = CCh
; For each data block:
;    APU IO 2..3 = destination address
;    APU IO 1 = 1 (arbitrary non-zero value)
;    APU IO 0 = kick
;    Wait until APU echoes kick back through APU IO 0
;    Index = 0
;    For each data byte
;       APU IO 1 = data byte
;       APU IO 0 = index
;       Wait until APU echoes index back through APU IO 0
;       Increment index
;    Increment index (and again if resulting in 0)
;    Kick = index
; Send entry address through APU IO 2..3
; APU IO 1 = 0
; APU IO 0 = kick
; (Optionally wait until APU echoes kick back through APU IO 0)

        PHP
        REP #$30
        LDA.w #$3000             ;\
        STA.l $000641               ;|
                                  ;|
.apuWait 
        LDA.w #$BBAA                ;|
        CMP.l $002140               ;|
        BEQ .apuReady                   ;} Wait until [APU IO 0..1] = AAh BBh
        LDA.l $000641               ;|
        DEC A                     ;|
        STA.l $000641               ;|
        BNE .apuWait                   ;/
.crash
        BRA .crash                   ; If exceeded 3000h attempts: crash

.apuReady
        SEP #$20
        LDA.b #$CC                  ; Kick = CCh
        BRA .processDataBlock     ; Go to BRANCH_PROCESS_DATA_BLOCK

; BRANCH_UPLOAD_DATA_BLOCK
.uploadDataBlock
        LDA.w $0000,y               ;\
        JSR .incY                 ;} Data = [[Y++]]
        XBA                       ;/
        LDA.b #$00                  ; Index = 0
        BRA .uploadData           ; Go to BRANCH_UPLOAD_DATA

; LOOP_NEXT_DATA
.loopNextData
        XBA                       ;\
        LDA.w $0000,y               ;|
        JSR .incY                 ;} Data = [[Y++]]
        XBA
-                                 ;/
        CMP.l $002140               ;\
        BNE -                     ;} Wait until APU IO 0 echoes
        INC A                     ; Increment index

; BRANCH_UPLOAD_DAT             
.uploadData
        REP #$20
        STA.l $002140               ; APU IO 0..1 = [index] [data]
        SEP #$20
        DEX                       ; Decrement X (block size)
        BNE .loopNextData                   ; If [X] != 0: go to LOOP_NEXT_DATA
-
        CMP.l $002140               ;\
        BNE -                     ;} Wait until APU IO 0 echoes

.ensureKick       
        ADC.b #$03                  ; Kick = [index] + 4
        BEQ .ensureKick                     ; Ensure kick != 0

; BRANCH_PROCESS_DATA_BLOCK
.processDataBlock
        PHA
        REP #$20
        LDA.w $0000,y               ;\
        JSR .incY2                ;} X = [[Y]] (block size)
        TAX                       ;} Y += 2
        LDA.w $0000,y               ;\
        JSR .incY2                 ;} APU IO 2..3 = [[Y]] (destination address)
        STA.l $002142               ;} Y += 2
        SEP #$20
        CPX.w #$0001                ;\
        LDA.b #$00                  ;|
        ROL A                     ;} If block size = 0: APU IO 1 = 0 (EOF), else APU IO 1 = 1 (arbitrary non-zero value)
        STA.l $002141               ;/
        ADC.b #$7F               ; Set overflow if block size != 0, else clear overflow
        PLA                    ;\
        STA.l $002140               ;} APU IO 0 = kick
        PHX
        LDX.w #$1000                ;\

-                                  ;|
        DEX                       ;} Wait until APU IO 0 echoes
        BEQ .ret                  ;} If exceeded 1000h attempts: return
        CMP.l $002140               ;|
        BNE -                     ;/
        
        PLX
        BVS .uploadDataBlock      ; If block size != 0: go to BRANCH_UPLOAD_DATA_BLOCK
        SEP #$20
        STZ.w $2141               
        STZ.w $2142               
        STZ.w $2143               
        PLP
        RTS
.ret
        SEP #$20
        STZ.w $2141
        STZ.w $2142
        STZ.w $2143
        PLX
        PLP
        RTS
}


;;; $8100: Increment Y twice, bank overflow check ;;;
.incY2
{
; Only increments Y once if overflows bank first time (which is a bug scenario)
        INY
        BEQ .next
}


;;; $8103: Increment Y, bank overflow check ;;;
.incY
{
        INY
        BEQ .next                 
        RTS
.next
        INC $02                   ; Increment $02
        PEI ($01)                 ;\
        PLB                    ;} DB = [$02]
        PLB                    ;/
        LDY.w #$8000             ; Y = 8000h
        RTS
}


print "spc-driver = ", pc
spc_driver:
arch spc700-inline
org $1000
startpos start

;========================================
;       NES Registers
;----------------------------------------
		sq4000      =    $40   ; $4000
		sq4001      =    $41   ; $4001
		sq4002      =    $42   ; $4002
		sq4003      =    $43   ; $4003
		sq4004      =    $44   ; $4004
		sq4005      =    $45   ; $4005
		sq4006      =    $46   ; $4006
		sq4007      =    $47   ; $4007
		tr4008      =    $48   ; $4008
		tr4009      =    $49   ; $4009
		tr400A      =    $4A   ; $400A
		tr400B      =    $4b   ; $400B
		no400C      =    $4C   ; $400C
		no400D      =    $4D   ; $400D
		no400E      =    $4E   ; $400E
		no400F      =    $4F   ; $400F
		pcm_freq    =    $50   ; $4010
		pcm_raw     =    $51   ; $4011
		pcm_addr    =    $52   ; $4012
		pcm_length  =    $53   ; $4013

		sound_ctrl	=	$55   ; $4015
		no4016		=	$56   ; $4016
		; 0x01 = Reset square 0
		; 0x02 = Reset square 1
		; 0x04 = Reset triangle
		; 0x08 = Reset noise
		; 0x10 = 
		; 0x20 = Mono
		; 0x40 = Square 0 sweep
		; 0x80 = Square 1 sweep
;========================================
;       SPC Memory
;----------------------------------------

		pulse0duty			=	$60
		pulse0dutyold		=	$61
		pulse1duty			=	$62
		pulse1dutyold		=	$63
		puls0_sample		=	$64
		puls1_sample		=	$65
		puls0_sample_old    =    $66
		puls1_sample_old    =    $67
		temp1				=	$68
		temp2				=	$69
		temp3				=	$6A
		temp4				=	$6B
		temp5				=	$6C
		temp6				=	$6D
		temp7				=	$6E
		temp8				=	$6F
		old4003				=	$70

		sweeptemp1			=	$78
		sweeptemp2			=	$79
		sweep_freq_lo		=	$7A
		sweep_freq_hi		=	$7B

		linear_count_lo		=	$7D
		linear_count_hi		=	$7E
		timer3count_lo		=	$7F
		timer3count_hi		=	$80
		sweep1				=	$81
		sweep2				=	$82
		sweep_freq_lo2		=	$83
		sweep_freq_hi2		=	$84
		timer3val			=	$85
		decay1volume		=	$86
		decay1rate			=	$87
		decay_status		=	$88
		decay2volume		=	$89
		decay2rate			=	$8A
		decay3volume		=	$8B
		decay3rate			=	$8C
                tri_sample                      =       $8E

;  To enable dmc audio, preload a lookup table in aram at address $4000 as follows:
;  $4000-$400f:  (Up to) 16 one-byte dmc address bytes that appear in NES register $4012 (pcm_addr)
;  $4010-$401f:  (Up to) 16 one-byte frequency cutoff value that dictates the playback speed to be used.
;                        Values less than these bytes will trigger the .slowspeed playback rate.
;                        Appears in NES register $4010 (pcm_freq)
;  $4020-$405f:  (Up to) 16 directory entries for the brr samples in audio ram.
;                        This data is appended directly after the static directory lookup data at aram $0200
;  One byte value below indicating volume attenuation cutoff as it appears in NES register $4011 (pcm_raw)
;  (this is very game specific, and most games do not use this trickery (Zelda 1 does)):
dmc_attenuation_cutoff: db $20

;  Example dmc table (for Zelda 1):
;  $4000-$400f:  $00,$1d,$20,$4c,$80
;  $4010-$401f:  $0f,$0f,$0f,$0f,$0d
;  $4020-$405f:  $4014,$4014,$5631,$5631,$58b0,$58b0,$7cc2,$7cc2,$9e28,$9e28
;                (little endian, as it appears in aram: 14 40 14 40 31 56 31 56 B0 58 B0 58 C2 7C C2 7C 28 9E 28 9E)
;========================================


start:
        clrp                    ; clear direct page flag (DP = $0000-$00FF)
        mov x,#$F0
        mov SP,x

        mov a,#%00110000
        mov $F1,a               ; clear all ports, disable timers

        call reset_dsp         ; clear DSP registers
        call set_directory     ; set sample directory

        mov $F2,#$5D           ; directory offset
        mov $F3,#$02           ; $200

        ;  Voices:
        ;   0: Square Wave 0
        ;   1: Square Wave 1
        ;   2: Triangle Wave
        ;   3: Noise
        ;   4: dmc

        mov $F2,#$05            ; ADSR off, GAIN enabled
        mov $F3,#0
        mov $F2,#$15            ; ADSR off, GAIN enabled
        mov $F3,#0
        mov $F2,#$25
        mov $F3,#0
        mov $F2,#$35
        mov $F3,#0
        mov $F2,#$45
        mov $F3,#0

        mov $F2,#$07            ; infinite gain
        mov $F3,#$1F
        mov $F2,#$17            ; infinite gain
        mov $F3,#$1F
        mov $F2,#$27
        mov $F3,#$1F
        mov $F2,#$37
        mov $F3,#$1F
        mov $F2,#$47
        mov $F3,#$1F

        mov $F2,#$24            ; sample # for triangle
        mov $F3,#triangle_sample_num

        mov $F2,#$34
        mov $F3,#$00            ; sample # for noise

        mov $F2,#$4C            ; key on
        mov $F3,#%00001111

        mov $F2,#$0C            ; main vol L
        mov $F3,#$7F
        mov $F2,#$1C            ; main vol R
        mov $F3,#$7F

        mov $F2,#$6C
        mov $F3,#%00100000      ; soft reset, mute, and echo disabled

        mov $F2,#$6D            ; Echo buffer address
        mov $F3,#$7d

        mov $F2,#$3D            ; noise on voice 3
        mov $F3,#%00001000

        call enable_timer3

        ; Zero port 4 for CPU-side optimization
        mov $F7,#0

next_xfer:
        mov $F4,#$7D            ; move $7D to port 0 (SPC ready)
wait:
        call check_timer3
        call check_timers
        call check_timers2

wait2:
        mov a,$F4
		cmp	a,$F4
		bne	wait2

        cmp a,#$F5              ; wait for port 0 to be $F5 (Reset)
        beq to_reset
        cmp a,#$D7              ; wait for port 0 to be $D7 (CPU ready)
        bne wait
        mov $F4,a               ; reply to CPU with $D7 (begin transfer)
        mov $F5, #$ff

		; 63.613 cycles per scanline
		; Transfer via HDMA must take no more than 66 cycles per byte
		; Cycles used during transfer: 25 = 3+2 + 3+5+4 + 2+2+4

        mov x,#0
xfer:
		cmp x,$F4               ; wait for port 0 to have current byte #
		bne xfer

		mov a,$F5               ; load data on port 1
		mov $40+x,a             ; store data at $40 - $55

		inc x
                mov a, x
                mov $F5, a
		cmp x,#$17
		bne xfer

		jmp square0

to_reset:
                ; Key off all notes
                mov     $F2,#$5C
                mov     $F3,#$FF

		mov	$F1,#$B0
		jmp $ffc0

;=====================================


;-------------------------------------
square0:

        mov a,sound_ctrl
        and a,#%00000001
        bne sq0_enabled
silence:
        mov $F2,#0
        mov $F3,#0
        mov $F2,#1
        mov $F3,#0
        jmp square1

sq0_enabled:



;-------------------------------------
                                ; emulate duty cycle (select sample #)
                                ; check first the octave sample to be played

        mov a,sq4000            ; emulate duty cycle
        and a,#%11000000
		xcn	a

		and	puls0_sample,#$03
		or	a,puls0_sample
        mov puls0_sample,a
        cmp a,puls0_sample_old
        beq sq1_no_change

sq1_sample_change:

        mov $F2,#$04            ; sample # reg
        mov $F3,puls0_sample

        mov $F2,#$4C            ; key on
        mov $F3,#%00000001

sq1_no_change:

        mov puls0_sample_old,puls0_sample
                
;-------------------------------------

                        ; check if sweeps are enabled
        mov a,$41
        and a,#%10000000
        beq skip00
        mov a,$41
        and a,#%00000111
        beq skip00

        call check_timers
        bra nextsq0

skip00:


        mov a,sq4003            ; check if freq is 0 or too high
        and a,#%00000111
        bne ok1
        mov a,sq4002
        ;cmp a,#8
        ;bcc silence
ok1:
        



        and $43,#%00000111

        mov a,$42
        clrc
        rol a
        push p
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,$43
        rol a
        ror temp3
        adc a,#(freqtable/256)&255
        mov temp2,a

		mov	x,#$02
		call change_pulse

;-----------------------------------------------

nextsq0:

        mov a,sq4000            ; check volume decay disable
        and a,#%00010000
        bne decay_disabled

        call check_timer3

        mov a,no4016
        and a,#%00000001
        beq no_reset

;        mov a,sq4000
;        and a,#%00001111
;        mov x,a
;        mov a,volume_decay_rates+X
;        mov decay1rate,a
        bra no_reset


volume_decay_rates:
        db 3
        db 6
        db 9
        db 12
        db 15
        db 18
        db 21
        db 24
        db 27
        db 30
        db 33
        db 36
        db 40
        db 44
        db 48
        db 52
        db 56

;        mov a,sq4000
;        and a,#%00001111
;        mov x,a
;        mov a,volume_decay_table+X
;        mov $F2,#$07
;        mov $F3,a
;
;        mov $F2,#$08             ; envx
;        mov $F3,#%01111000
;
;
;        mov $F2,#$04
;        mov $F3,puls0_sample
;        mov $F2,#$4C
;        mov $F3,#%00000001
;
;        mov a,#$1F
;        mov $F2,#$08
;        mov $F3,a
;
;        bra write_volume

decay_disabled:
        mov $F2,#$07
        mov $F3,#$1F

        mov a,no4016
        and a,#$20
        beq mono

        mov a,sq4000
        and a,#%00001111
        asl a
        asl a
        asl a
;        asl a

        mov $F2,#0
        mov $F3,a
        mov $F2,#1
        mov $F3,a
        bra no_reset


mono:
        mov a,sq4000            ; emulate volume, square 0
        and a,#%00001111
        asl a
        asl a
        asl a

write_volume:
        mov $F2,#0              ; write volume
        mov $F3,a
        mov $F2,#1
        mov $F3,a
;        mov $F3,#0

no_reset:



;=====================================

;-------------------------------------
square1:

        mov a,sound_ctrl
        and a,#%00000010
        bne sq1_enabled
silence2:
        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,#0
        jmp triangle

sq1_enabled:


;-------------------------------------
                                ; emulate duty cycle (select sample #)
                                ; check first the octave sample to be played

        mov a,sq4004            ; emulate duty cycle
        and a,#%11000000
		xcn	a

		and	puls1_sample,#$03
		or	a,puls1_sample
        mov puls1_sample,a
        cmp a,puls1_sample_old
        beq sq2_no_change

sq2_sample_change:

        mov $F2,#$14            ; sample # reg
        mov $F3,puls1_sample

        mov $F2,#$4C            ; key on
        mov $F3,#%00000010

sq2_no_change:

        mov puls1_sample_old,puls1_sample
        

        


;        mov puls0_sample,#0
;
;        mov y,a
;
;        mov a,sq4003
;        and a,#%00000111
;        mov x,a
;        mov a,y
;;        cmp x,#%00000101
;;        beq pitch0
;        cmp x,#%00000110
;        beq pitch0
;        cmp x,#%00000111
;        beq pitch0
;
;        clrc
;        adc a,#4
;        mov puls0_sample,#1
;
;pitch0:
;        mov $F2,#$04            ; sample #
;        mov $F3,a
;
;        mov $F2,#$4C            ; key on
;        mov $F3,#%00000001          
;no_change:
;        mov pulse0dutyold,pulse0duty
;        mov puls0_sample_old,puls0_sample
;-------------------------------------


                        ; check if sweeps are enabled
        mov a,$45
        and a,#%10000000
        beq skip01
        mov a,$45
        and a,#%00000111
        beq skip01

        call check_timers2
        bra nextsq1

skip01:


        mov a,sq4007            ; check if freq is 0 or too high
        and a,#%00000111
        bne ok2
        mov a,sq4006
        ;cmp a,#8
        ;bcc silence2
ok2:


        and $47,#%00000111

        mov a,$46
        clrc
        rol a
        push p
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,$47
        rol a
        ror temp3
        adc a,#(freqtable/256)&255
        mov temp2,a

		mov	x,#$12
		call change_pulse

;--------------------------------------

nextsq1:

        mov a,sq4004            ; check decay disabled
        and a,#%00010000
        bne decay_disabled2

        mov a,no4016
        and a,#%00000010
        beq no_reset2
        bra no_reset2

;        mov a,sq4004
;        and a,#%00001111
;        mov x,a
;        mov a,volume_decay_table+X
;        mov $F2,#$17
;        mov $F3,a
;
;        mov $F2,#$18             ; envx
;        mov $F3,#%01111000
;
;
;        mov $F2,#$14
;        mov $F3,puls0_sample
;        mov $F2,#$4C
;        mov $F3,#%00000010
;
;        mov a,#$1F
;        mov $F2,#$18
;        mov $F3,a
;
;        bra write_volume2

decay_disabled2:
        mov $F2,#$17
        mov $F3,#$1F

        mov a,no4016
        and a,#$20
        beq mono2

        mov a,sq4004
        and a,#%00001111
        asl a
        asl a
        asl a
;        asl a

        mov $F2,#$10
        mov $F3,a
        mov $F2,#$11
        mov $F3,a
        bra no_reset2
        

mono2:
        mov a,sq4004            ; emulate volume, square 0
        and a,#%00001111
        asl a
        asl a
        asl a

write_volume2:
        mov $F2,#$10            ; write volume
;        mov $F3,#0
        mov $F3,a
        mov $F2,#$11
        mov $F3,a

no_reset2:
 


;=====================================

;-------------------------------------
triangle:
        mov a,sound_ctrl
        and a,#%00000100        ; check triangle bit of $4015
        bne tri_enabled

silence3:
        mov $F2,#$20
        mov $F3,#0
        mov $F2,#$21
        mov $F3,#0
        jmp noise

tri_enabled:

;        mov a,no4016
;        and a,#%00000100
;        beq silence3

        mov a,tr4008
        beq silence3
        and a,#%10000000
        beq tri_length_enabled
        mov a,tr4008
        and a,#%01111111
        beq silence3

        mov a,no4016
        and a,#$20
        beq mono3

        ;  Why is triangle channel referencing pcm_raw??
        ;  A likely bug.  removing block below
        ; ----------------------------------------------
        ; mov a,pcm_raw   
        ; lsr a
        ; mov temp_add,a
        mov a,#$7F

        ; setc
        ; sbc a,temp_add
        ; ----------------------------------------------

        mov $F2,#$20
        mov $F3,a
        mov $F2,#$21
        mov $F3,a

 
;        mov $F2,#$20    ; set volume
;        mov $F3,#$3F
;        mov $F2,#$21
;        mov $F3,#$3F
	  
	  bra notimer
mono3:

        mov $F2,#$20
        mov $F3,#$7F
        mov $F2,#$21
        mov $F3,#$7F

        bra notimer

tri_length_enabled:

        mov a,no4016
        and a,#%00000100
        beq notimer
        mov a,tr4008
        and a,#%01111111
        mov y,#3
        mul ya
        mov linear_count_hi,y
        mov linear_count_lo,a

        mov a,$FF                ; clear counter
notimer:	  

        call check_timer3



        and $4B,#%00000111

        mov a,$4A
        clrc
        rol a
        push p
        clrc
        adc a,#tritable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,$4B
        rol a
        ror temp3
        adc a,#(tritable/256)&255
        mov temp2,a

        mov y,#0
        mov a,(temp1)+y
        mov $F2,#$22

        mov $F3,a
        inc y
        mov a,(temp1)+y
        and a,#$1f
        mov $F2,#$23
        mov $F3,a

        ; Change sample
        mov a,(temp1)+y
        and a,#$e0
        xcn a
        lsr a
        adc a,#triangle_sample_num&255	; Assume carry clear from LSR
        cmp a,tri_sample
        beq triangle_skip1
                mov tri_sample,a
                mov $F2,#$24			; Sample # reg
                mov $F3,a
                ; mov $F2,#$4C			; Key on
                ; mov $F3,#$04
triangle_skip1:

;=====================================

;-------------------------------------
noise:
        mov a,sound_ctrl
        and a,#%00001000
        bne noise_enabled

        mov $F2,#$30
        mov $F3,#0
        mov $F2,#$31
        mov $F3,#0

        bra noise_off

noise_enabled:
        mov a,no400C            ; check decay disable
        and a,#%00010000
        bne decay_disabled3

        bra no_reset3

;        mov a,$56
;        and a,#%00001000
;        beq no_reset3
;
;        mov a,no400C
;        and a,#%00001111
;        mov x,a
;        mov a,volume_decay_table+X
;        mov $F2,#$37
;        mov $F3,a
;
;        mov $F2,#$38
;        mov $F3,#%01111000
;
;        mov $F2,#$34
;        mov $F3,#0        ;puls0_sample
;        mov $F2,#$4C
;        mov $F3,#%00001000
;
;        mov a,#$08
;        mov $F2,#$38
;        mov $F3,a
;
;        bra write_volume3

decay_disabled3:
        mov $F2,#$37
        mov $F3,#$1F

        mov a,no4016
        and a,#$20
        beq mono4

        mov a,no400C
        and a,#%00001111
        bra write_volume3

mono4:
        mov a,no400C            ; write noise volume
        and a,#%00001111
        asl a
        mov x,a

        ;  Why is noise channel referencing pcm_raw??
        ;  A likely bug.  removing block below
        ; ----------------------------------------------
        ; mov a,pcm_raw
        ; lsr a
        ; lsr a
        ; mov temp_add,a
        ; mov a,x
        ; setc
        ; sbc a,temp_add
        ; bcs just_fine
        ; mov a,#0
        ; ----------------------------------------------
just_fine:

;        mov $F2,#$30
;        mov $F3,a
;        mov $F2,#$31
;        mov $F3,a



;        asl a
;        asl a
;        asl a
write_volume3:
        mov $F2,#$30
        mov $F3,a
        mov $F2,#$31
        mov $F3,a

no_reset3:
;---------------------------------------
                                ; write noise frequency
        mov a,no400E
        and a,#%00001111
        mov x,a
        mov a,noise_freq_table+X

        mov $F2,#$6C
        mov $F3,a


;        mov $F2,#$6C
;        mov a,no400E
;        eor a,#$FF
;        and a,#%00001111
;        asl a
;        or  a,#%00100000        ; set echo disable
;        mov $F3,a               ; write noise frequency

noise_off:


;  
dmc:
        mov a,no4016
        and a,#%00010000        ; check for toggle on of dmc bit of $4015
        bne dmc_play

        mov $f2,#$7c
        mov a,$f3   ; check if dmc voice is finished playing
        and a,#%00010000
        bne dmc_silence
        jmp dmc_continue_playing

dmc_silence:
        mov $F2,#$4c
        mov $F3,#%00000000  ;  disable KON
        mov $F2,#$5c
        mov $F3,#%00010000  ;  KOFF dpcm channel

        jmp next_xfer

dmc_play:
        mov x,#$00
.selectSample:
        mov a,$4000+x
        cmp a,pcm_addr
        beq .setSample
        inc x
        cmp x,#$10
        beq dmc_silence ;  Sample not found
        jmp .selectSample

        ;  X now contains the index of the chosen sample
.setSample:
        mov a,x
        clrc : adc a,#srcn_base  ;  Calculate the SRCN
        mov $F2,#$44
        mov $F3,a       ;  Set srcn with the selected sample from pcm_addr

.selectPlaybackSpeed:
        mov a,pcm_freq
        cmp a,$4010+x
        bcc .slowspeed        ;  If pcm_freq < threshold value in a, slow speed

.normalspeed:                 ;  Otherwise, normal speed
        mov $F2,#$42
        mov $F3,#$06    ;  Pitch lower bits
        mov $F2,#$43
        mov $F3,#$0b    ;  Pitch higher bits
        jmp .selectPlaybackVolume
.slowspeed:                     
        mov $F2,#$42
        mov $F3,#$45    ;  Pitch lower bits
        mov $F2,#$43
        mov $F3,#$08    ;  Pitch higher bits

.selectPlaybackVolume:
        mov a,dmc_attenuation_cutoff
        cmp a,pcm_raw
        bcc .halfvolume         ;  If pcm_raw > threshold value in dmc_attenuation_cutoff, half volume

.fullvolume:                    ;  Otherwise, full volume
        mov $F2,#$40
        mov $F3,#$7f    ;  Full volume
        mov $F2,#$41
        mov $F3,#$7f    ;  Full volume
        jmp .turnOn
.halfvolume:
        mov $F2,#$40
        mov $F3,#$3f    ;  Half volume
        mov $F2,#$41
        mov $F3,#$3f    ;  Half volume

.turnOn:
        mov $F2,#$5c
        mov $F3,#%00000000  ;  disable KOFF
        mov $F2,#$4c
        mov $F3,#%00010000  ;  KON dpcm channel

dmc_continue_playing:
        jmp next_xfer
;  END processing loop


;======================================
; timer notes:
;               linear counter
;               267.094 Timer2 units (15.6ms) for 1/240hz
;               267.094 / 3 = 89.031 (timer value)
;               4-bit counter / 3 is number of .25-frames passed
;                       maxmimum time allowed between checks
;                       before 4-bit overflow: 22.2 milliseconds!
;                       

enable_timer3:
        mov $F1,#0                              ; disable timers
        mov $FC,#89				; 89 * 3 = 267
        mov $FB,#22                             ; 22.2222 * 3 = 66.66666
        mov $FA,#22
        mov a,$FF                               ; clear counters
        mov a,$FE
        mov a,$FD
        mov $F1,#%00000111              ; enable timers
        ret


check_timer3:
        mov a,$FF               ; timer's 4-bit counter
        mov timer3val,a

        mov a,sq4000
        and a,#%00010000
        beq decay1
        jmp no_decay1
decay1:

        mov a,no4016
        and a,#%00000001
        beq no_decay_reset

        mov a,#%00001111        ; reset decay
        mov decay1volume,a
        mov a,#0
        mov decay1rate,a

        mov a,decay_status
        or a,#%00000001
        mov decay_status,a

        bra write_decay_volume

no_decay_reset:

        mov a,decay_status
        and a,#%00000001
        bne no_decay1x
        jmp no_decay1
no_decay1x:

        mov a,sq4000
        and a,#%00001111
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay1rate
        mov decay1rate,a

        cmp a,volume_decay_rates+X
        bcc no_decay1

        mov a,#0
        mov decay1rate,a

        mov a,decay1volume
        bne no_decay_end

        mov a,sq4000
        and a,#%00100000        ; decay looping enabled?
        beq decay1_end
        mov a,#%00010000        ; looped, reset volume
        mov decay1volume,a
        bra no_decay1

decay1_end:
        mov a,decay_status      ; disabled!
        and a,#%11111110
        mov decay_status,a
        bra no_decay1

no_decay_end:
        dec decay1volume

write_decay_volume:
        mov a,decay1volume
        asl a
        asl a
        asl a
        mov x,a

        mov a,sound_ctrl
        and a,#%00000001
        beq silenced1

        mov a,sq4001
        and a,#%10000000
        beq okd1y
        mov a,sq4001
        and a,#%00000111
        beq okd1y
        bra ooykd

okd1y:
        mov a,sq4003
        and a,#%00000111
        bne okd1                ; check if freq is 0 or too high
        mov a,sq4002
        ;cmp a,#8
        ;bcc silenced1
        bra okd1
        
ooykd:
        mov a,sweep_freq_lo
        and a,#%00000111
        bne okd1                ; check if freq is 0 or too high
        mov a,sweep_freq_hi
        ;cmp a,#8
        ;bcc silenced1
        bra okd1

silenced1:
        mov x,#0
okd1:
        mov a,no4016
        and a,#$20
        beq monod1

        mov $F2,#0
        mov $F3,x
        mov $F2,#1
        mov $F3,x
        bra no_decay1

monod1:
        mov $F2,#0              ; write volume
        mov $F3,x
        mov $F2,#1
        mov $F3,x


no_decay1:

        mov a,sq4004
        and a,#%00010000
        beq decay2
        jmp no_decay2
decay2:

        mov a,no4016
        and a,#%00000010
        beq no_decay_reset2

        mov a,#%00001111        ; reset decay
        mov decay2volume,a
        mov a,#0
        mov decay2rate,a

        mov a,decay_status
        or a,#%00000010
        mov decay_status,a

        bra write_decay_volume2

no_decay_reset2:

        mov a,decay_status
        and a,#%00000010
        bne no_decay2x
        jmp no_decay2
no_decay2x:

        mov a,sq4004
        and a,#%00001111
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay2rate
        mov decay2rate,a

        cmp a,volume_decay_rates+X
        bcc no_decay2

        mov a,#0
        mov decay2rate,a

        mov a,decay2volume
        bne no_decay_end2

        mov a,sq4004
        and a,#%00100000        ; decay looping enabled?
        beq decay2_end
        mov a,#%00010000        ; looped, reset volume
        mov decay2volume,a
        bra no_decay2

decay2_end:
        mov a,decay_status      ; disabled!
        and a,#%11111101
        mov decay_status,a
        bra no_decay2

no_decay_end2:
        dec decay2volume

write_decay_volume2:
        mov a,decay2volume
        asl a
        asl a
        asl a
        mov x,a

        mov a,sound_ctrl
        and a,#%00000010
        beq silenced2

        mov a,sq4005
        and a,#%10000000
        beq okd2y
        mov a,sq4005
        and a,#%00000111
        beq okd2y
        bra ooykd2

okd2y:
        mov a,sq4007
        and a,#%00000111
        bne okd2                ; check if freq is 0 or too high
        mov a,sq4006
        ;cmp a,#8
        ;bcc silenced2
        bra okd2
        
ooykd2:


        mov a,sweep_freq_lo2
        and a,#%00000111
        bne okd2                ; check if freq is 0 or too high
        mov a,sweep_freq_hi2
        ;cmp a,#8
        ;bcc silenced2
        bra okd2

silenced2:
        mov x,#0
okd2:
        mov a,no4016
        and a,#$20
        beq monod2

        mov $F2,#$10
        mov $F3,x
        mov $F2,#$11
        mov $F3,x
        bra no_decay2

monod2:
        mov $F2,#$10              ; write volume
        mov $F3,x
        mov $F2,#$11
        mov $F3,x


no_decay2:


        mov a,no400C
        and a,#%00010000
        bne no_decay3


        mov a,sound_ctrl
        and a,#%00001000
        beq no_decay3

        mov a,no4016
        and a,#%00001000
        beq no_decay_reset3

        mov a,#%00001111        ; reset decay
        mov decay3volume,a
        mov a,#0
        mov decay3rate,a

        mov a,decay_status
        or a,#%00001000
        mov decay_status,a

        bra write_decay_volume3

no_decay_reset3:

        mov a,decay_status
        and a,#%00001000
        beq no_decay3

        mov a,no400C
        and a,#%00001111
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay3rate
        mov decay3rate,a

        cmp a,volume_decay_rates+X
        bcc no_decay3

        mov a,#0
        mov decay3rate,a

        mov a,decay3volume
        bne no_decay_end3

        mov a,no400C
        and a,#%00100000        ; decay looping enabled?
        beq decay3_end
        mov a,#%00010000        ; looped, reset volume
        mov decay3volume,a
        bra no_decay3

decay3_end:
        mov a,decay_status      ; disabled!
        and a,#%11110111
        mov decay_status,a
        bra no_decay3

no_decay_end3:
        dec decay3volume

        mov a,sound_ctrl
        and a,#%00001000
        bne write_decay_volume3
        mov x,#0
        bra noise_decayed

write_decay_volume3:
        mov a,decay3volume
        asl a
;        asl a
;        asl a
        mov x,a

noise_decayed:
        mov $F2,#$30              ; write volume
        mov $F3,x
        mov $F2,#$31
        mov $F3,x


no_decay3:


        mov a,sound_ctrl
        and a,#%00000100
        beq timer3_complete

        mov a,linear_count_hi
        bne needed
        mov a,linear_count_lo
        beq not_needed
needed:        
        mov a,timer3val

        clrc
        adc a,timer3count_lo
        mov timer3count_lo,a
        mov a,#0
        adc a,timer3count_hi
        mov timer3count_hi,a

        cmp a,linear_count_hi
        bcc timer3_ongoing

        mov a,timer3count_lo
        cmp a,linear_count_lo
        bcs timer3_complete
timer3_ongoing:        

        mov $F2,#$20    ; set volume
        mov $F3,#$7F
        mov $F2,#$21
        mov $F3,#$7F

not_needed:
        ret

timer3_complete:
;        mov $F1,#0

        mov $F2,#$20
        mov $F3,#0
        mov $F2,#$21
        mov $F3,#0
        mov linear_count_lo,#0
        mov linear_count_hi,#0

        mov timer3count_lo,#0
        mov timer3count_hi,#0
        ret


        mov a,tr4008
        and a,#0
        ret


silencex1:
        mov $F2,#0
        mov $F3,#0
        mov $F2,#1
        mov $F3,#0
        
nonsweep:
        ret

check_timers:
        mov a,sq4001
        and a,#%10000000
        beq nonsweep
        mov a,sq4001
        and a,#%00000111
        beq nonsweep

        mov a,no4016
        and a,#%01000000
        beq nofreqchange

        and no4016,#%10111111   ; disable!
        mov a,$FD               ; clear counter

        mov a,sq4002
        mov sweep_freq_lo,a
        mov a,sq4003
        and a,#%00000111
        mov sweep_freq_hi,a

        bne ok1x                ; check if freq is 0 or too high
        mov a,sweep_freq_lo
        ;cmp a,#8
        ;bcc silencex1
ok1x:

        mov a,sweep_freq_hi
        and a,#%11111000
        bne silencex1


        mov a,sweep_freq_lo
        clrc
        rol a
        push p
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,sweep_freq_hi
        rol a
        ror temp3
        adc a,#(freqtable/256)&255
        mov temp2,a

		mov	x,#$02
		call change_pulse


nofreqchange:

        mov a,sq4001
        and a,#%01110000
        lsr a
        lsr a
        lsr a
        lsr a
        mov x,a

        mov a,$FD
        clrc
        adc a,sweep1
        mov sweep1,a

        cmp a,sweeptimes+x

        bcc nonsweep

        mov a,#0
        mov sweep1,a
        
        mov a,sweep_freq_lo
        mov sweeptemp1,a
        mov a,sweep_freq_hi
        mov sweeptemp2,a

        mov a,sq4001
        and a,#%00000111
        bne swcont
        ret

swcont:
        clrc
        ror sweeptemp2
        ror sweeptemp1
        dec a
        bne swcont

        mov a,sweeptemp1        ; decrease by 1 (sweep channel difference)
        setc
        sbc a,#1
        mov sweeptemp1,a
        mov a,sweeptemp2
        sbc a,#0
        mov sweeptemp2,a


        mov a,sweep_freq_hi
        bne ok3x                ; check if freq is 0 or too high
        mov a,sweep_freq_lo
        ;cmp a,#8
        ;bcc silencex2
ok3x:

        mov a,sweep_freq_hi
        and a,#%11111000
        bne silencex2

        
        mov a,sq4001
        and a,#%00001000
        bne decrease

        mov a,sweep_freq_lo
        clrc
        adc a,sweeptemp1
        mov sweep_freq_lo,a

        mov a,sweep_freq_hi
        adc a,sweeptemp2
        mov sweep_freq_hi,a
        bra swupdate

decrease:
        mov a,sweep_freq_lo
        setc
        sbc a,sweeptemp1
        mov sweep_freq_lo,a

        mov a,sweep_freq_hi
        sbc a,sweeptemp2
        mov sweep_freq_hi,a


swupdate:
        mov a,sweep_freq_hi
        bne ok2x                ; check if freq is 0 or too high
        mov a,sweep_freq_lo
        ;cmp a,#8
        ;bcc silencex2
ok2x:

        mov a,sweep_freq_hi
        and a,#%11111000
        bne silencex2


        mov a,sweep_freq_lo
        clrc
        rol a
        push p
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,sweep_freq_hi
        rol a
        ror temp3
        adc a,#(freqtable/256)&255
        mov temp2,a

		mov	x,#$02
		call change_pulse

swzero:
        ret


silencex2:
        mov $F2,#0
        mov $F3,#0
        mov $F2,#1
        mov $F3,#0
        ret



sweeptimes:
        db 3,6,9,12,15,18,21,24


silencex12:
        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,#0
        
nonsweepx:
        ret



check_timers2:
        mov a,sq4005
        and a,#%10000000
        beq nonsweepx
        mov a,sq4005
        and a,#%00000111
        beq nonsweepx

        mov a,no4016
        and a,#%10000000
        beq nofreqchangex

        and no4016,#%01111111   ; disable!
        mov a,$FE               ; clear counter

        mov a,sq4006
        mov sweep_freq_lo2,a
        mov a,sq4007
        and a,#%00000111
        mov sweep_freq_hi2,a

        bne ok1x2               ; check if freq is 0 or too high
        mov a,sweep_freq_lo2
        ;cmp a,#8
        ;bcc silencex12
ok1x2:

        mov a,sweep_freq_hi2
        and a,#%11111000
        bne silencex12


        mov a,sweep_freq_lo2
        clrc
        rol a
        push p
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,sweep_freq_hi2
        rol a
        ror temp3
        adc a,#(freqtable/256)&255
        mov temp2,a

		mov	x,#$12
		call change_pulse


nofreqchangex:

        mov a,sq4005
        and a,#%01110000
        lsr a
        lsr a
        lsr a
        lsr a
        mov x,a

        mov a,$FE
        clrc
        adc a,sweep2
        mov sweep2,a

        cmp a,sweeptimes+x

        bcc nonsweepx

        mov a,#0
        mov sweep2,a
        
        mov a,sweep_freq_lo2
        mov sweeptemp1,a
        mov a,sweep_freq_hi2
        mov sweeptemp2,a

        mov a,sq4005
        and a,#%00000111
        beq swzero2

swcont2:
        clrc
        ror sweeptemp2
        ror sweeptemp1
        dec a
        bne swcont2


        mov a,sweep_freq_hi2
        bne ok3x2               ; check if freq is 0 or too high
        mov a,sweep_freq_lo2
        ;cmp a,#8
        ;bcc silencex22
ok3x2:

        mov a,sweep_freq_hi2
        and a,#%11111000
        bne silencex22

        
        mov a,sq4005
        and a,#%00001000
        bne decrease2

        mov a,sweep_freq_lo2
        clrc
        adc a,sweeptemp1
        mov sweep_freq_lo2,a

        mov a,sweep_freq_hi2
        adc a,sweeptemp2
        mov sweep_freq_hi2,a
        bra swupdate2

decrease2:
        mov a,sweep_freq_lo2
        setc
        sbc a,sweeptemp1
        mov sweep_freq_lo2,a

        mov a,sweep_freq_hi2
        sbc a,sweeptemp2
        mov sweep_freq_hi2,a


swupdate2:
        mov a,sweep_freq_hi2
        bne ok2x2               ; check if freq is 0 or too high
        mov a,sweep_freq_lo2
        ;cmp a,#8
        ;bcc silencex22
ok2x2:

        mov a,sweep_freq_hi2
        and a,#%11111000
        bne silencex22


        mov a,sweep_freq_lo2
        clrc
        rol a
        push p
        clrc
        adc a,#freqtable&255
        rol temp3
        mov temp1,a
        pop p
        mov a,sweep_freq_hi2
        rol a
        ror temp3
        adc a,#(freqtable/256)&255
        mov temp2,a

		mov	x,#$12
		call change_pulse

swzero2:
        ret


silencex22:
        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,#0
        ret





;======================================
reset_dsp:
        mov y,#0
        mov x,#0
clear:
        mov $F2,x
        mov $F3,y
        inc x
        mov a,x
        and a,#%00001111
        cmp a,#$0A
        bne clear
        mov a,x
        and a,#%11110000
        clrc
        adc a,#$10
        mov x,a
        cmp x,#$80
        bne clear

        mov a,#$0C
clear2:
        mov $F2,a
        mov $F3,y
        clrc
        adc a,#$10
        cmp a,#$6C
        bne clear2

        mov a,#$0D
clear3:
        mov $F2,a
        mov $F3,y
        clrc
        adc a,#$10
        cmp a,#$8D
        bne clear3

        mov a,#$0F
clear4:
        mov $F2,a
        mov $F3,y
        clrc
        adc a,#$10
        cmp a,#$8F
        bne clear4

                                ; clear zero-page
        mov a,#0
        mov x,#$EF
clear5:
        mov $00+x,a
        dec x
        bne clear5
        mov $00,a

        ret


;======================================

set_directory:
        mov x, #(end_directory_lut-set_directory_lut-1)

set_directory_loop:
        mov	a,set_directory_lut+x
        mov	$0200+x,a
        dec	x
        bpl	set_directory_loop

        ;  Append dynamic dmc entries from $4020 (see spc.asm:270)
        mov x, #0

add_dynamic_entries:
        mov a,$4020+x
        mov ($200+end_directory_lut-set_directory_lut)+x,a
        inc x
        cmp x,#$40
        bne add_dynamic_entries
ret


set_directory_lut:
		dw	pulse0,pulse0, pulse0d,pulse0d, pulse0c,pulse0c, pulse0b,pulse0b
		dw	pulse1,pulse1, pulse1d,pulse1d, pulse1c,pulse1c, pulse1b,pulse1b
		dw	pulse2,pulse2, pulse2d,pulse2d, pulse2c,pulse2c, pulse2b,pulse2b
		dw	pulse3,pulse3, pulse3d,pulse3d, pulse3c,pulse3c, pulse3b,pulse3b
                dw      tri_samp0,tri_samp0, tri_samp1, tri_samp1, tri_samp2, tri_samp2, tri_samp3, tri_samp3
                dw      tri_samp4,tri_samp4, tri_samp5, tri_samp5, tri_samp6, tri_samp6, tri_samp7, tri_samp7
end_directory_lut:

        triangle_sample_num	 =	$10
        srcn_base = $18

;======================================

change_pulse:
		; Read frequency
        mov y,#0
        mov a,(temp1)+y
		mov	temp4,a
		mov	$F5,a
        inc y
        mov a,(temp1)+y
		mov	temp5,a
		
		mov	$F5,temp1
		mov	$F6,temp2

		; Which sample are we using?
		mov	a,#$00
		mov	y,#$1f
		cmp	y,temp5
		bcc	change_pulse_1
			inc	a
			asl	temp4
			rol	temp5
			cmp	y,temp5
			bcc	change_pulse_1
				inc	a
				asl	temp4
				rol	temp5
				cmp	y,temp5
				bcc	change_pulse_1
					inc	a
					asl	temp4
					rol	temp5

change_pulse_1:
		; Which pulse channel?
		cmp	x,#$10
		bcs	change_pulse_pulse1
			; Apply sample change
			and	puls0_sample,#$0c
			or	a,puls0_sample
			mov puls0_sample,a
			cmp a,puls0_sample_old
			beq	change_pulse_rtn
			mov puls0_sample_old,puls0_sample

			mov $F2,#$04            ; sample # reg
			mov $F3,puls0_sample
			; mov $F2,#$4C            ; key on
			; mov $F3,#$01

			; Apply frequency
			mov $F2,x
			mov $F3,temp4
			inc	x
			mov $F2,x
			mov $F3,temp5

			ret

change_pulse_pulse1:
			; Apply sample change
			and	puls1_sample,#$0c
			or	a,puls1_sample
			mov puls1_sample,a
			cmp a,puls1_sample_old
			beq	change_pulse_rtn
			mov puls1_sample_old,puls1_sample

			mov $F2,#$14            ; sample # reg
			mov $F3,puls1_sample
			; mov $F2,#$4C            ; key on
			; mov $F3,#$02

change_pulse_rtn:
		; Apply frequency
        mov $F2,x
        mov $F3,temp4
		inc	x
        mov $F2,x
        mov $F3,temp5
		ret

;======================================================================
;       DSP value            NES reg    NES decay       SPC decay       
;----------------------------------------------------------------------
;volume_decay_table:    ( no longer used )
;        db $8D                 ; $00   240Hz .25 sec   260 msec
;        db $8A                 ; $01   120Hz .5 sec    510 msec
;        db $88                 ; $02   80Hz .75 sec    770 msec
;        db $87                 ; $03   60Hz 1 sec      1 second
;        db $86                 ; $04   48Hz 1.25 sec   1.3 seconds
;        db $85                 ; $05   40Hz 1.5 sec    1.5 seconds
;        db $85                 ; $06   34Hz 1.764 sec  1.5 seconds
;        db $84                 ; $07   30Hz 2 sec      2.0 seconds
;        db $83                 ; $08   26Hz 2.307 sec  2.6 seconds
;        db $83                 ; $09   24Hz 2.5 sec    2.6 seconds
;        db $83                 ; $0A   21Hz 2.857 sec  2.6 seconds
;        db $82                 ; $0B   20Hz 3 sec      3.1 seconds
;        db $82                 ; $0C   18Hz 3.333 sec  3.1 seconds
;        db $82                 ; $0D   17Hz 3.529 sec  3.1 seconds
;        db $81                 ; $0E   16Hz 3.75 sec   4.1 seconds
;        db $81                 ; $0F   15Hz 4 sec      4.1 seconds
;======================================================================
;       DSP value            NES reg    NES noise freq  SPC noise freq
;----------------------------------------------------------------------
noise_freq_table:
        db %00111111           ; $0                    32mhz
        db %00111111           ; $1                    32mhz
        db %00111111           ; $2                    32mhz
        db %00111111           ; $3                    32mhz
        db %00111111           ; $4                    32mhz
        db %00111111           ; $5                    32mhz
        db %00111110           ; $6                    16mhz
        db %00111110           ; $7                    16mhz
        db %00111110           ; $8    16744.04mhz     16mhz
        db %00111110           ; $9    14080hz         16mhz
        db %00111100           ; $A    9397.28hz       8.0mhz
        db %00111011           ; $B    7040hz          6.4mhz
        db %00111001           ; $C    4698.64hz       4.0mhz
        db %00111000           ; $D    35200hz         3.2mhz
        db %00110101           ; $E    17600 hz        1.6mhz
        db %00110010           ; $F    880 hz          800hz
;======================================================================

; 1 sample
pulse0: incsrc "pl1a-0.asm"
pulse1: incsrc "pl1a-1.asm"
pulse2: incsrc "pl1a-2.asm"
pulse3: incsrc "pl1a-3.asm"

; 2 samples
pulse0d: incsrc "pl1-0.asm"
pulse1d: incsrc "pl1-1.asm"
pulse2d: incsrc "pl1-2.asm"
pulse3d: incsrc "pl1-3.asm"

; 4 samples
pulse0c: incsrc "pl2-0.asm"
pulse1c: incsrc "pl2-1.asm"
pulse2c: incsrc "pl2-2.asm"
pulse3c: incsrc "pl2-3.asm"

; 8 samples
pulse0b: incsrc "pl3-0.asm"
pulse1b: incsrc "pl3-1.asm"
pulse2b: incsrc "pl3-2.asm"
pulse3b: incsrc "pl3-3.asm"

; 2 samples (again?)
pulse0e: incsrc "pl1-0.asm"
pulse1e: incsrc "pl1-1.asm"
pulse2e: incsrc "pl1-2.asm"
pulse3e: incsrc "pl1-3.asm"

freqtable: incsrc "snestabl.asm"
tritable: incsrc "tritabl3.asm"



;        incsrc "sq2.asm"
;        incsrc "peeko1.asm"

;        incsrc "puls2y2.asm"
;        incsrc "pl2.asm"


; triang: incsrc "tri5.asm"

tri_samp0: incsrc "tri6_sl3.asm"
tri_samp1: incsrc "tri6_sl2.asm"
tri_samp2: incsrc "tri6_sl1.asm"
tri_samp3: incsrc "tri6.asm"
tri_samp4: incsrc "tri6_sr1.asm"
tri_samp5: incsrc "tri6_sr2.asm"
tri_samp6: incsrc "tri6_sr3.asm"
tri_samp7: incsrc "tri6_sr4.asm"

spc_driver_end:
print "spc driver end = ", pc
dw $0000
dw $1000
arch 65816
