print "spc init driver start = ", pc
spc_init_driver:
    pha : phx : phy : phb : php
    
    rep #$30
    ldy #spc_driver
    phk : plb
    jsr send_apu_data

    plp : plb : ply : plx : pla
    rtl

incsrc "./apu-send.asm"

print "spc-driver = ", pc
spc_driver:
arch spc700-inline
org $1000
startpos start

;========================================
;       NES Registers
;----------------------------------------

; sq4000     = $40 ; $4000 - Pulse/square 0 channel
; sq4001     = $41 ; $4001
; sq4002     = $42 ; $4002
; sq4003     = $43 ; $4003
; sq4004     = $44 ; $4004 - Pulse/square 1 channel
; sq4005     = $45 ; $4005
; sq4006     = $46 ; $4006
; sq4007     = $47 ; $4007
; tr4008     = $48 ; $4008 - Triangle channel
; tr4009     = $49 ; $4009
; tr400A     = $4A ; $400A
; tr400B     = $4b ; $400B
; no400C     = $4C ; $400C - Noise channel
; no400D     = $4D ; $400D
; no400E     = $4E ; $400E
; no400F     = $4F ; $400F
; pcm_freq   = $50 ; $4010 - DMC channel
; pcm_raw    = $51 ; $4011
; pcm_addr   = $52 ; $4012
; pcm_length = $53 ; $4013

; sound_ctrl = $55 ; $4015

; no4016     = $56 ; $4016
; ; Bit flags for no4016:
; ; 0x01 = Reset square 0
; ; 0x02 = Reset square 1
; ; 0x04 = Reset triangle
; ; 0x08 = Reset noise
; ; 0x10 = Initiate dmc playback
; ; 0x20 = [repurposed as $4017 write active]
; ; 0x40 = Square 0 sweep
; ; 0x80 = Square 1 sweep

; apu4017    = $57 ; $4017

;=====================
;     SPC Memory
;---------------------

; pulse0duty       = $60
; pulse0dutyold    = $61
; pulse1duty       = $62
; pulse1dutyold    = $63
; puls0_sample     = $64
; puls1_sample     = $65
; puls0_sample_old = $66
; puls1_sample_old = $67
; temp1            = $68
; temp2            = $69
; temp3            = $6A
; temp4            = $6B
; temp5            = $6C
; temp6            = $6D
; temp7            = $6E
; temp8            = $6F
; old4003          = $70

; sweeptemp1    = $78
; sweeptemp2    = $79
; sweep_freq_lo = $7A
; sweep_freq_hi = $7B

; linear_count_lo = $7D
; linear_count_hi = $7E
; timer3count_lo  = $7F
; timer3count_hi  = $80
; sweep1          = $81
; sweep2          = $82
; sweep_freq_lo2  = $83
; sweep_freq_hi2  = $84
; timer3val       = $85 ; Captures up counter for Timer 3. Value only ever 0, 1, or 2
; decay1volume    = $86
; decay1rate      = $87 ; Square 0 channel
; decay_status    = $88 ; Voice bit flags indicating which have currently decrementing length counters
; decay2volume    = $89
; decay2rate      = $8A ; Square 1 channel
; decay3volume    = $8B
; decay3rate      = $8C ; Noise channel
; tri_sample      = $8E
voicesPlaying   = $8f ; Voice bit flags tracking which are currently playing


;=====================
;     Constants
;---------------------

;  Voice flags
!Square0Flag  = #%00000001
!Square1Flag  = #%00000010
!TriangleFlag = #%00000100
!NoiseFlag    = #%00001000
!DmcFlag      = #%00010000

!Square0Offset = #$00
!Square1Offset = #$10

;  SPC dsp registers
!Square0VolumeL  = #$00
!Square0VolumeR  = #$01
!Square1VolumeL  = #$10
!Square1VolumeR  = #$11
!TriangleVolumeL = #$20
!TriangleVolumeR = #$21
!NoiseVolumeL    = #$30
!NoiseVolumeR    = #$31
!DmcVolumeL      = #$40
!DmcVolumeR      = #$41

!Square0PitchL  = #$02
!Square0PitchH  = #$03
!Square1PitchL  = #$12
!Square1PitchH  = #$13
!TrianglePitchL = #$22
!TrianglePitchH = #$23
!NoisePitchL    = #$32
!NoisePitchH    = #$33
!DmcPitchL      = #$42
!DmcPitchH      = #$43

!Square0SRCN  = #$04
!Square1SRCN  = #$14
!TriangleSRCN = #$24
!NoiseSRCN    = #$34
!DmcSRCN      = #$44

!KON          = #$4c
!KOFF         = #$5c

!blt = "BCC"
!bge = "BCS"

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

TimerLatchIndex = $80       ;  Cyclic latch_table lookup providing constant 240Hz ticks
WritesJumpPointer = $81     ;  2-byte address storing the pointer to the write handler
ShiftResult       = $83     ;  2-byte heap variable used by pulse channels

start:
.start:
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

        ;  Init triangle voice
        mov $F2,!TriangleSRCN            ; sample # for triangle
        mov $F3,#triangle_sample_num
        mov $F2,!TriangleVolumeL
        mov $F3,#$7F    ; max vol L
        mov $F2,!TriangleVolumeR
        mov $F3,#$7F    ; max vol R

        mov $F2,!NoiseSRCN
        mov $F3,#$00            ; sample # for noise


        mov $F2,!KON
        mov $F3,#%00001111      ;  KON sq0, sq1, tri, and noise


        mov $F2,#$0C            ; main vol L
        mov $F3,#$7F
        mov $F2,#$1C            ; main vol R
        mov $F3,#$7F

        mov $F2,#$6C
        mov $F3,#%00100000      ; soft reset, mute, and echo disabled

        mov $F2,#$6D            ; Echo buffer address
        mov $F3,#$7d

        mov $F2,#$3D            ; noise on voice 3
        mov $F3,!NoiseFlag

        ; Zero port 4 for CPU-side optimization
        mov $F7,#0

        ;  Clear internal state [not needed; zp is zeroed out already]
;         mov x, #$60
; ..clearState:
;         mov a, #$00
;         mov (x+), a
;         cmp x, #$c0
;         bne ..clearState
;         bra ..done
..done:
        bra Start240

;-------------------------------------------------
; 240 Hz scheduler using Timer0
; TickHandler executes BEFORE the wait loop.
; Timer period pattern: 33, 33, 34 ticks.
;-------------------------------------------------
latch_table:
        db 33, 33, 34           ; fractional 33⅓ pattern

;-----------------------------------------------
; Initialization entry point
;-----------------------------------------------
Start240:
        mov a, #$00
        mov $f1, a                  ; stop all timers
        mov TimerLatchIndex, a

        mov $F4,#$7D            ; move $7D to port 0 (SPC ready)
        ; bra MainLoop

;-----------------------------------------------
; Main loop
;-----------------------------------------------
MainLoop:
        ; --- Set latch for next period ---
        mov a, TimerLatchIndex
        mov x, a  ; tax
        mov a, #$00
        mov $f1, a                  ; stop timers before latch write
        mov a, latch_table+x
        mov $FA, a                  ; Timer0 latch
        mov a, #$01
        mov $f1, a                   ; start Timer0 (ST0=1)

        ; --- Perform variable-length work ---
        call TickHandler

        ; --- Wait for timer completion ---
WaitTick:
        mov a, $FD                  ; read Timer0 counter (read clears)
        bne TimerExpired

cpucheck:
        ; --- Check and process cpu sends
        mov a,$F4
        cmp	a,$F4
        bne cpucheck

        cmp a,#$F5              ; wait for port 0 to be $F5 (Reset)
        bne +
        call to_reset
+
        cmp a,#$d7              ; wait for port 0 to be $d7 (CPU ready)    --  this seems to take the bulk of the cycles, which makes sense
        beq apurecv  ;  New cpu data waiting to send
        bra WaitTick

TimerExpired:
        ; --- Advance pattern index ---
        inc TimerLatchIndex
        mov a, TimerLatchIndex
        cmp a, #3
        bne MainLoop
        mov a, #$00
        mov TimerLatchIndex, a
        bra MainLoop

incsrc "./apu-recv.asm"
incsrc "./apu-status.asm"
incsrc "./channels/pulse.asm"

;  Safe fill for invalid register values
NullRoutine: jmp ProcessWrites_handlerReturn

JumpTableLo:
    ;  Square channel 0
    db Pulse_Envelope_Init&$FF, Pulse_Sweep_Init&$FF, Pulse_Period_SetLow&$FF, Pulse_LengthCounter_Reload&$FF
    ;  Square channel 1
    db NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF
    ;  Triangle channel
    db NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF
    ;  Noise channel
    db NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF
    ;  DMC
    db NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF
    ;  Status and Frame counter
    db NullRoutine&$FF, Status_set&$FF, NullRoutine&$FF, FrameCount_set&$FF


JumpTableHi:
    ;  Square channel 0
    db Pulse_Envelope_Init>>8, Pulse_Sweep_Init>>8, Pulse_Period_SetLow>>8, Pulse_LengthCounter_Reload>>8
    ;  Square channel 1
    db NullRoutine>>8, NullRoutine>>8, NullRoutine>>8, NullRoutine>>8
    ;  Triangle channel
    db NullRoutine>>8, NullRoutine>>8, NullRoutine>>8, NullRoutine>>8
    ;  Noise channel
    db NullRoutine>>8, NullRoutine>>8, NullRoutine>>8, NullRoutine>>8
    ;  DMC
    db NullRoutine>>8, NullRoutine>>8, NullRoutine>>8, NullRoutine>>8
    ;  Status and Frame counter
    db NullRoutine>>8, Status_set>>8, NullRoutine>>8, FrameCount_set>>8


;------------------------------------------------------------------------
;  Process all queued apu register writes in the order they were recieved
;------------------------------------------------------------------------
ProcessWrites:
    ;  x=0; while x<queuelength
    ;   switch NumbersQueue, x
    ;       case 0:
    ;       case 1:
    ;       ...
    ;       case 17:
    ;
    ;
    ;   x++
    ;  end while
;     QueueLength  = $1f
; NumbersQueue = $20
; ValuesQueue  = $50

    mov y, #$00
.loop:
    cmp y, QueueLength
    beq .done

    ;  Calculate a jump pointer based on this register number
    ;  [OPT TODO]: Single dw'd jump table and x *= 2
    mov a, NumbersQueue+y
    mov x, a
    mov a, JumpTableLo+x
    mov WritesJumpPointer, a
    mov a, JumpTableHi+x
    mov WritesJumpPointer+1, a

    mov a, ValuesQueue+y    ;  Load param in [A]
    mov x, #$00
    ;jmp [WritesJumpPointer+x]  ;  Handler specified in jump table
    db $1f, WritesJumpPointer, $00

.handlerReturn:
    inc y
    bra .loop

.done:
ret

incsrc "./apu-frame-counter.asm"

;------------------------------------
; Frame tick routine (runs at 240 Hz)
;------------------------------------
TickHandler:
    ;  General structure:
    ;  1.  Housekeeping:
    ;       DONE:  increment frame counter cycle number (0->3 or 4)
    ;       DONE:  use current $4017 mode value and fccn index above to select a lookup table value:
    ;           - l - l    OR    - l - - l 
    ;           e e e e          e e e - e
    ;       - call subroutines (in large beq case statement?) for all 4 channels:
    ;           tickenvelope, ticklinearcounter, ticklengthcounter, ticksweep

    ;  Zero page memory allocations
    ;  $00->$1e: Reserved for immediate heap access for subroutines (if needed)
    ;  $1f:      Register writes queue length
    ;  $20->$4f: Register writes "reg. number" queue
    ;  $50->$7f: Register writes "value" queue
    ;  $80->$8f: General apu, frame counter, general length counter (if needed)
    ;  $90->$9f: Square 0 internal state
    ;  $a0->$af: Square 1 internal state
    ;  $b0->$bf: Triangle channel internal state
    ;  $c0->$cf: Noise channel internal state
    ;  $d0->$df: DMC channel internal state
    ;  $e0->$ef: Reserved for future expansion audio support





    ;  TODO: Case statement determining which processes should be run on the current frame tick
    call FrameCount_tick
    


;  Task lists for the current frame count:
;  fc == 0 ?  envelopes
;  fc == 1 ?  length counters; sweeps; envelopes
;  fc == 2 ?  envelopes
;  fc == 3 ?  mode == 0 ? length counters; sweeps; envelopes : (none)
;  fc == 4 ?  length counters; sweeps; envelopes

;  "Process envelopes" = !(mode == 1 && fc == 3)
;   reduces nicely to mode + fc != 4

    mov a, FrameCounterStepMode
    clrc : adc a, FrameCounterCycle
    cmp a, #$04     ;  Only way to have 4 here is 3+1 (can never have 4+0)
    beq .endHandler

.processEnvelopes:
    ;  Process all envelopes and triangle linear counter
    mov a, !Square0Flag
    call Pulse_Envelope_Tick
    ;  TODO: all the rest


;  "Process length counters & sweeps" = fc==1 || fc==4 || (fc==3 && mode==0) 
;   already in simplest form

    mov a, FrameCounterCycle
    cmp a, #$01
    beq .processLCs
    cmp a, #$04
    beq .processLCs
    cmp a, #$03
    bne .endHandler
    cmp FrameCounterStepMode, #$00
    bne .endHandler

.processLCs:
    ;  Process all length counters and sweeps
    ;  TODO: all


.setOutput:
    mov a, sq0EnvelopeCounter
    mov x,!Square0Flag
    call playVoiceInX
.endHandler:
ret


to_reset:
    pop a : pop a  ;  Remove call stack entry [check]
    mov     $F2,!KOFF
    mov     $F3,#$FF        ;  KOFF all notes

    mov	$F1,#$B0
    jmp $ffc0

;=====================================


; ;-------------------------------------
; square0:
;     mov a,sound_ctrl
;     and a,!Square0Flag
;     bne sq0_enabled
; silence:
;     mov x,!Square0Flag        ; Square 0 voice
;     call stopVoiceInX

;     ret

; sq0_enabled:

; ;-------------------------------------
;                                 ; emulate duty cycle (select sample #)
;                                 ; check first the octave sample to be played

;         mov a,sq4000            ; emulate duty cycle
;         and a,#%11000000
; 		xcn	a

; 		and	puls0_sample,#$03
; 		or	a,puls0_sample
;         mov puls0_sample,a
;         cmp a,puls0_sample_old
;         beq sq1_no_change

; sq1_sample_change:
;         mov $F2,!Square0SRCN            ; sample # reg
;         mov $F3,puls0_sample

; sq1_no_change:
;         mov puls0_sample_old,puls0_sample
                
; ;-------------------------------------

;         ; check if sweeps are enabled
;         mov a,$41
;         and a,#%10000000
;         beq skip00
;         mov a,$41
;         and a,#%00000111
;         beq skip00

;         ; call check_timers
;         bra nextsq0

; skip00:
;         mov a,sq4003            ; check if freq is 0 or too high
;         and a,#%00000111
;         bne ok1
;         mov a,sq4002
;         ;cmp a,#8
;         ;bcc silence

; ok1:
;         and $43,#%00000111

;         mov a,$42
;         clrc
;         rol a
;         push p
;         clrc
;         adc a,#freqtable&255
;         rol temp3
;         mov temp1,a
;         pop p
;         mov a,$43
;         rol a
;         ror temp3
;         adc a,#(freqtable/256)&255
;         mov temp2,a

;         mov	x,#$02
;         call change_pulse

; ;-----------------------------------------------

; nextsq0:
;         mov a,no4016
;         and a,!Square0Flag
;         beq .afterResetCheck

;         ;  A "reset sq0" in no4016 inidicates a nes apu write just happened to $4003
;         ;  KOFF the channel and KON again required to emulate what the NES APU does
;         mov x,!Square0Flag
;         call stopVoiceInX
;         call playVoiceInX

; .afterResetCheck
;         mov a,sq4000            ; check volume decay disable
;         and a,#%00010000
;         bne decay_disabled

;         ; call check_timer3

;         mov a,no4016
;         and a,!Square0Flag
;         beq no_reset

; ;        mov a,sq4000
; ;        and a,#%00001111
; ;        mov x,a
; ;        mov a,volume_decay_rates+X
; ;        mov decay1rate,a
;         bra no_reset            ;  TODO: opt


; volume_decay_rates:
;         db 3
;         db 6
;         db 9
;         db 12
;         db 15
;         db 18
;         db 21
;         db 24
;         db 27
;         db 30
;         db 33
;         db 36
;         db 40
;         db 44
;         db 48
;         db 52
;         db 56

; ;        mov a,sq4000
; ;        and a,#%00001111
; ;        mov x,a
; ;        mov a,volume_decay_table+X
; ;        mov $F2,#$07
; ;        mov $F3,a
; ;
; ;        mov $F2,#$08             ; envx
; ;        mov $F3,#%01111000
; ;
; ;
; ;        mov $F2,#$04
; ;        mov $F3,puls0_sample
; ;        mov $F2,!KON
; ;        mov $F3,!Square0Flag
; ;
; ;        mov a,#$1F
; ;        mov $F2,#$08
; ;        mov $F3,a
; ;
; ;        bra write_volume

; decay_disabled:
;         mov a,no4016
;         and a,#$20
;         beq mono

;         mov a,sq4000
;         and a,#%00001111
;         asl a
;         asl a
;         asl a
; ;        asl a

;         mov $F2,!Square0VolumeL
;         mov $F3,a
;         mov $F2,!Square0VolumeR
;         mov $F3,a
;         bra no_reset

; mono:
;         mov a,sq4000            ; emulate volume, square 0
;         and a,#%00001111
;         asl a
;         asl a
;         asl a

; write_volume:
;         mov $F2,!Square0VolumeL              ; write volume
;         mov $F3,a
;         mov $F2,!Square0VolumeR
;         mov $F3,a

; no_reset:
;         mov x,!Square0Flag
;         call playVoiceInX
;     ret



;==========~ Subroutines ~========
;  Subroutines to support the main
;  processing loop begin below.
;=================================


;  Initiates playback of the voice(s) indicated
;  by the flag value in [X], but only if the
;  voice is not already playing.  Does not affect
;  other voices.
playVoiceInX:
    mov a,x
    and a,voicesPlaying     ;  Check if selected voice is playing
    bne .alreadyPlaying
    
    mov a,x
    or  a,voicesPlaying
    mov voicesPlaying,a      ;  Set voice as playing in voicesPlaying var

    mov $F2,!KON
    mov $F3,x       ;  KON selected voice only
    mov $F2,!KOFF
    mov a,x
    eor a,#$ff     ;  invert [A]
    and a,$F3       ;  xor with current KOFF'ed voices
    mov $F3,a      ;  disable KOFF for selected voice only
.alreadyPlaying:
ret

;  Stops playback for the voice indicated
;  by the flag value in [X].  Does not affect
;  other voices.
stopVoiceInX:
    mov a,x
    eor a,#$ff     ;  invert [A]
    and a,voicesPlaying       ;  AND voicesPlaying with [X']
    mov voicesPlaying,a      ;  to reset playing flag for selected voice only

    mov $F2,!KOFF
    mov $F3,x      ;  Update selected voice only
ret

;======================================
; timer notes (original):
;               linear counter
;               267.094 Timer2 units (15.6ms) for 1/240hz [ATS - what??]
;               267.094 / 3 = 89.031 (timer value)
;               4-bit counter / 3 is number of .25-frames passed
;                       maxmimum time allowed between checks
;                       before 4-bit overflow: 22.2 milliseconds!

;======================================
;  Timer notes (ATS 2024):
;  Example calculation for 15ms: 120 (0x78) to FA (15/(1000/8000) = 15*8 = 120)
;  $FA timer:  22/8 = 2.75 ms
;  $FB timer:  22/8 = 2.75 ms
;  $FC timer:  89/64 = 1.3906 ms

;  Timer0 ($fa) is used for the Square 0 channel frequency sweeps
;  Timer1 ($fb) is used for the Square 1 channel frequency sweeps
;  Timer2 ($fc) is used for length counters for *all* four sound channels at once


;======================================
;  Reset DSP subroutine
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


        triangle_sample_num = $10
        srcn_base           = $18


; ;======================================
; ;  Change Pulse subroutine
; change_pulse:
;         ; Read frequency
;         mov y,#0
;         mov a,(temp1)+y
; 		mov	temp4,a
; 		mov	$F5,a
;         inc y
;         mov a,(temp1)+y
; 		mov	temp5,a
		
; 		mov	$F5,temp1
; 		mov	$F6,temp2

; 		; Which sample are we using?
; 		mov	a,#$00
; 		mov	y,#$1f
; 		cmp	y,temp5
; 		bcc	change_pulse_1
; 			inc	a
; 			asl	temp4
; 			rol	temp5
; 			cmp	y,temp5
; 			bcc	change_pulse_1
; 				inc	a
; 				asl	temp4
; 				rol	temp5
; 				cmp	y,temp5
; 				bcc	change_pulse_1
; 					inc	a
; 					asl	temp4
; 					rol	temp5

; change_pulse_1:
; 		; Which pulse channel?
; 		cmp	x,#$10
; 		bcs	change_pulse_pulse1
; 			; Apply sample change
; 			and	puls0_sample,#$0c
; 			or	a,puls0_sample
; 			mov puls0_sample,a
; 			cmp a,puls0_sample_old
; 			beq	change_pulse_rtn
; 			mov puls0_sample_old,puls0_sample

; 			mov $F2,!Square0SRCN            ; sample # reg
; 			mov $F3,puls0_sample


; 			; Apply frequency
; 			mov $F2,x
; 			mov $F3,temp4
; 			inc	x
; 			mov $F2,x
; 			mov $F3,temp5

; 			ret

; change_pulse_pulse1:
; 			; Apply sample change
; 			and	puls1_sample,#$0c
; 			or	a,puls1_sample
; 			mov puls1_sample,a
; 			cmp a,puls1_sample_old
; 			beq	change_pulse_rtn
; 			mov puls1_sample_old,puls1_sample

; 			mov $F2,!Square1SRCN            ; sample # reg
; 			mov $F3,puls1_sample


; change_pulse_rtn:
;         ; Apply frequency
;         mov $F2,x
;         mov $F3,temp4
;         inc	x
;         mov $F2,x
;         mov $F3,temp5
; ret

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
;       DSP value     old val           NES reg         NES noise freq
;----------------------------------------------------------------------
noise_freq_table:     ;  Added $20 to all values to keep bit 5 always set
        db #$3f       ;%00111111        $0              447kHz  
        db #$3f       ;%00111111        $1              224kHz  
        db #$3f       ;%00111111        $2              112kHz  
        db #$3f       ;%00111111        $3              55,930Hz
        db #$3f       ;%00111111        $4              27,965Hz
        db #$3e       ;%00111111        $5              18,643Hz
        db #$3e       ;%00111110        $6              13,983Hz
        db #$3d       ;%00111110        $7              11,186Hz
        db #$3c       ;%00111110        $8              8,860Hz 
        db #$3b       ;%00111110        $9              7,046Hz 
        db #$3a       ;%00111100        $A              4,710Hz 
        db #$38       ;%00111011        $B              3,523Hz 
        db #$36       ;%00111001        $C              2,349Hz 
        db #$35       ;%00111000        $D              1,762Hz 
        db #$32       ;%00110101        $E              880Hz   
        db #$2f       ;%00110010        $F              440Hz   
;======================================================================

; ; 1 sample
; pulse0: incsrc "pl1a-0.asm"
; pulse1: incsrc "pl1a-1.asm"
; pulse2: incsrc "pl1a-2.asm"
; pulse3: incsrc "pl1a-3.asm"

; ; 2 samples
; pulse0d: incsrc "pl1-0.asm"
; pulse1d: incsrc "pl1-1.asm"
; pulse2d: incsrc "pl1-2.asm"
; pulse3d: incsrc "pl1-3.asm"

; ; 4 samples
; pulse0c: incsrc "pl2-0.asm"
; pulse1c: incsrc "pl2-1.asm"
; pulse2c: incsrc "pl2-2.asm"
; pulse3c: incsrc "pl2-3.asm"

; ; 8 samples
; pulse0b: incsrc "pl3-0.asm"
; pulse1b: incsrc "pl3-1.asm"
; pulse2b: incsrc "pl3-2.asm"
; pulse3b: incsrc "pl3-3.asm"

; ; 2 samples (again?)
; pulse0e: incsrc "pl1-0.asm"
; pulse1e: incsrc "pl1-1.asm"
; pulse2e: incsrc "pl1-2.asm"
; pulse3e: incsrc "pl1-3.asm"

freqtable: incsrc "snestabl.asm"
tritable: incsrc "tritabl3.asm"

tri_samp0: incsrc "./samples/tri6_sl3.asm"
tri_samp1: incsrc "./samples/tri6_sl2.asm"
tri_samp2: incsrc "./samples/tri6_sl1.asm"
tri_samp3: incsrc "./samples/tri6.asm"
tri_samp4: incsrc "./samples/tri6_sr1.asm"
tri_samp5: incsrc "./samples/tri6_sr2.asm"
tri_samp6: incsrc "./samples/tri6_sr3.asm"
tri_samp7: incsrc "./samples/tri6_sr4.asm"

spc_driver_end:
print "spc driver end = ", pc
dw $0000
dw $1000
arch 65816