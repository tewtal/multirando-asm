;  NES APU Engine for the Quad Randomizer
;  by https://github.com/Andypro1

;  Aims to emulate the NES APU at a fairly low level, while
;  translating the sequencer into samples for the spc-700.

;  References:
;    -  https://www.nesdev.org/wiki/APU
;           Cycle accurate detailed reference on the NES APU
;    -  https://github.com/SourMesen/Mesen2/blob/master/Core/NES/APU
;           A good implementation of the above spec in a high-level language
;    -  https://github.com/Myself086/Project-Nested/tree/master/Assembly/Project/Spc700
;           Earlier implementation of NES APU functionality on the spc-700
;    -  https://github.com/bbbradsmith/NESertGolfing/blob/snes/spc/
;           Noise channel sample mixin from Brad Smith's NESertGolfing snes up-port
;           License:  CC BY 4.0


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
!Square0Flag   = #%00000001
!Square1Flag   = #%00000010
!TriangleFlag  = #%00000100
!NoiseFlag     = #%00001000
!DmcFlag       = #%00010000
!NoiseCompFlag = #%00100000

!Square0Offset  = #$00
!Square1Offset  = #$10
!TriangleOffset = #$20
!NoiseOffset    = #$30

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
!NoiseCompVolumeL = #$50
!NoiseCompVolumeR = #$51

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
!NoiseCompPitchL      = #$52
!NoiseCompPitchH      = #$53

!Square0SRCN  = #$04
!Square1SRCN  = #$14
!TriangleSRCN = #$24
!NoiseSRCN    = #$34
!DmcSRCN      = #$44
!NoiseCompSRCN = #$54

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
; $81, $82 reserved by Frame Counter
WritesJumpPointer = $83     ;  2-byte address storing the pointer to the write handler
ShiftResult       = $85     ;  2-byte heap variable used by pulse channels
; $87, $88 reserved by Apu Status
; $89 reserved by Pulse
NeedToRun         = $8a
; $8b, $8c  reserved by Frame Counter
; $8d, $8e: unused
; $8f reserved by Frame Counter

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
        mov $F2,#$55
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
        mov $F2,#$57
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

        mov $F2, !NoiseCompSRCN
        mov $F3, #$18  ; TODO: de-constantize

        mov $F2,!KON
        mov $F3,#%00101111      ;  KON sq0, sq1, tri, noise, and noise complement

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

        ;  Initialize game startup state that we skip due to jumping directly to gameplay modes
        ;  via portal transitions.  Check the other games; z1 writes $0f to $4015 on the 3rd frame of execution
        ;  and I suspect the other games do similarly just to enable the audio channels.
        ;  Mimic $0f -> $4015 write.
        call Run

        set1 $9f.6
        set1 $af.6
        set1 $bf.6
        set1 $cf.6
        ; TODO: rest

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


;;;  DEBUG:
; .noisedebug:
;     ; Oscillate a duty cycle for mixed noise clock generation
;     !DSP_FLG = #$6C     ;  DSP register: FLG (noise clock)
;     mov $F2, !DSP_FLG
;     mov a, noiseDuty
; ;     and a, #$02         ; 2-1-2-1 cadence (66% cycle)
;     bne ..cyclen
; ..cycle0:
;     mov $F3, #$29       ;  DEBUG: test a typical noise clock value on cycle 0: #$3e with spectroid
;     inc noiseDuty
;     bra +
; ..cyclen:
;     mov $F3, #$3f       ;  DEBUG: try flattening freq curve with some low "punch" on cycle n
;     mov a, #$00         ;  reset duty cycle
;     mov noiseDuty, a
; +

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
incsrc "./channels/pulse.asm"
incsrc "./channels/triangle.asm"
incsrc "./channels/noise.asm"
incsrc "./apu-status.asm"

;  Safe fill for invalid register values
NullRoutine: jmp ProcessWrites_handlerReturn

JumpTableLo:
    ;  Square channel 0
    db Pulse_Envelope_Init&$FF, Pulse_Sweep_Init&$FF, Pulse_Period_SetLow&$FF, Pulse_LengthCounter_Load&$FF
    ;  Square channel 1
    db Pulse_Envelope_Init2&$FF, Pulse_Sweep_Init2&$FF, Pulse_Period_SetLow2&$FF, Pulse_LengthCounter_Load2&$FF
    ;  Triangle channel
    db Triangle_LinearCounter_Init&$FF, NullRoutine&$FF, Triangle_Period_SetLow&$FF, Triangle_Period_SetHigh&$FF
    ;  Noise channel
    db Noise_Envelope_Init&$FF, NullRoutine&$FF, Noise_Period_Set&$FF, Noise_LengthCounter_Load&$FF
    ;  DMC
    db NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF, NullRoutine&$FF
    ;  Status and Frame counter
    db NullRoutine&$FF, Status_Set&$FF, NullRoutine&$FF, FrameCount_Set&$FF


JumpTableHi:
    ;  Square channel 0
    db Pulse_Envelope_Init>>8, Pulse_Sweep_Init>>8, Pulse_Period_SetLow>>8, Pulse_LengthCounter_Load>>8
    ;  Square channel 1
    db Pulse_Envelope_Init2>>8, Pulse_Sweep_Init2>>8, Pulse_Period_SetLow2>>8, Pulse_LengthCounter_Load2>>8
    ;  Triangle channel
    db Triangle_LinearCounter_Init>>8, NullRoutine>>8, Triangle_Period_SetLow>>8, Triangle_Period_SetHigh>>8
    ;  Noise channel
    db Noise_Envelope_Init>>8, NullRoutine>>8, Noise_Period_Set>>8, Noise_LengthCounter_Load>>8
    ;  DMC
    db NullRoutine>>8, NullRoutine>>8, NullRoutine>>8, NullRoutine>>8
    ;  Status and Frame counter
    db NullRoutine>>8, Status_Set>>8, NullRoutine>>8, FrameCount_Set>>8


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

    ;  Run call precedes all register writes.  
    ;  Instead of calling it for each queued write, try doing it once at the start.
    call Run

    mov y, #$00
.loop:
    cmp y, QueueLength
    bcs .done

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
    ;  Process NeedToRun once at the end of ProcessWrites
    ;  that may have resulted from the register writes
    ;  (length/linear counter loads/inits).
    mov a, NeedToRun
    beq .exit
    mov NeedToRun, #$00 ; reset NeedToRun flag
    call Run

.exit:
ret

incsrc "./apu-frame-counter.asm"

;  Execute the apu logic which updates the framecounter and all channels
Run:
    call FrameCount_Run

    call Pulse_LengthCounter_Reload     ; Square 0
    call Pulse_LengthCounter_Reload2    ; Square 1
    call Triangle_LengthCounter_Reload  ; Triangle
    call Noise_LengthCounter_Reload     ; Noise

    ;  channels->Run():
    call Pulse_UpdateOutput
    call Pulse_UpdateOutput2
    call Triangle_UpdateOutput
    call Noise_UpdateOutput
    ;  TODO: rest
ret


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

    ;  DONE: Find out why Mesen2 clocks length counters on frame numbers 0 and 2 (and not 1, 3, or 4)
        ;  because $4017 mode $80 performs immediate half-frame tick, then blocks FC tick for 2 cycles (0th and 1st)
        ;  just implement frameCounter->Run as mesen2 does and verify results

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

    ;  When a 240Hz tick step has fired, the frame counter needs to run which triggers the apu's need to run, so we call Run
    call Run
ret



;-------------------------------------------------
; CalcPitch
; Input : PeriodLo/PeriodHi
; Output: PitchLo/PitchHi
;-------------------------------------------------
CalcPitch:
    !pitchtable = PitchTable_Index0d-$1a
    PeriodLo = $02
    PeriodHi = $03

    PitchLo  = $06
    PitchHi  = $07

    mov   a,PeriodLo
    asl   a
    mov   y,a

    mov   a,PeriodHi
    rol   a                ; include carry from low byte shift
    clrc
    adc   a,#((!pitchtable>>8)&$FF)
    mov   $01,a

    mov   $00,#!pitchtable&$FF

    mov   a,($00)+y
    mov   PitchLo,a
    inc   y
    mov   a,($00)+y
    mov   PitchHi,a
    ret


; CalcPitch_dep:
;     PeriodLo  = $02
;     PeriodHi  = $03

;     DLo       = $04
;     DHi       = $05

;     PitchLo  = $06
;     PitchHi  = $07

;     TmpLo    = $08
;     TmpHi    = $09

;     Remainder = $0a

;     NextLo   = $0b
;     NextHi   = $0c

;     DeltaLo  = $0d
;     DeltaHi  = $0e

;     MulR     = $0f

;     MulLo    = $10
;     MulHi    = $11

;     AccLo    = $12
;     AccHi    = $13

;     push x

; ; --- D = P + 1 ----------------------------------  ✓
;     clrc
;     mov   a, PeriodLo
;     inc   a
;     mov   DLo, a
;     mov   a, PeriodHi
;     adc   a, #0
;     mov   DHi, a

; ; ---- r = D & 31 --------------------------------  ✓
;     mov   a, DLo
;     and   a, #$1F
;     mov   Remainder, a          ; r

; ; ---- i = (D >> 5) * 2 --------------------------  ✓
;     mov   TmpLo, DLo
;     mov   TmpHi, DHi

;     lsr   TmpHi
;     ror   TmpLo
;     lsr   TmpHi
;     ror   TmpLo
;     lsr   TmpHi
;     ror   TmpLo
;     lsr   TmpHi
;     ror   TmpLo
;     lsr   TmpHi
;     ror   TmpLo

;     mov   a, TmpLo
;     and   a, #$3F
;     asl   a                     ; word index
;     mov   x, a

; ; ---- load Pitch_i -------------------------------  ✓
;     mov   a, PitchTable64+x
;     mov   PitchLo, a
;     mov   a, PitchTable64+1+x
;     mov   PitchHi, a

; ; ---- Pitch_{i+1} -------------------------------
;     inc   x
;     inc   x
;     mov   a, PitchTable64+x
;     mov   NextLo, a
;     mov   a, PitchTable64+1+x
;     mov   NextHi, a

; ; ---- delta = Pitch_i - Pitch_{i+1} (unsigned) --
;     mov   a, PitchLo
;     setc : sbc   a, NextLo
;     mov   DeltaLo, a
;     mov   a, PitchHi
;     sbc   a, NextHi
;     mov   DeltaHi, a

; ; ---- multiply delta * r ------------------------
;     mov   MulLo, DeltaLo
;     mov   MulHi, DeltaHi
;     mov   MulR,  Remainder

;     mov   AccLo, #0
;     mov   AccHi, #0
;     mov   x, #8

; MulLoop:
;     mov   a, MulR
;     and   a, #1
;     beq   NoAdd

;     mov   a, AccLo
;     clrc : adc   a, MulLo
;     mov   AccLo, a
;     mov   a, AccHi
;     adc   a, MulHi
;     mov   AccHi, a

; NoAdd:
;     asl   MulLo
;     rol   MulHi
;     lsr   MulR

;     dec   x
;     bne   MulLoop

; ; ---- divide by 32 (unsigned, safe) -------------  ✓
;     lsr   AccHi
;     ror   AccLo
;     lsr   AccHi
;     ror   AccLo
;     lsr   AccHi
;     ror   AccLo
;     lsr   AccHi
;     ror   AccLo
;     lsr   AccHi
;     ror   AccLo

; ; ---- Pitch = Pitch_i - correction --------------
;     mov   a, PitchLo
;     setc : sbc   a, AccLo
;     mov   PitchLo, a
;     mov   a, PitchHi
;     sbc   a, AccHi
;     mov   PitchHi, a

; ; ---- final pitch in PitchHi:PitchLo ------------
;     pop x
;     ret


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


;  TODO: rewrite / rename vars and DOCUMENT
set_directory_lut:
		dw	pulse0,pulse0, pulse0d,pulse0d, pulse0c,pulse0c, pulse0b,pulse0b
		dw	pulse1,pulse1, pulse1d,pulse1d, pulse1c,pulse1c, pulse1b,pulse1b
		dw	pulse2,pulse2, pulse2d,pulse2d, pulse2c,pulse2c, pulse2b,pulse2b
		dw	pulse3,pulse3, pulse3d,pulse3d, pulse3c,pulse3c, pulse3b,pulse3b
                dw      tri_samp0,tri_samp0, tri_samp1, tri_samp1, tri_samp2, tri_samp2, tri_samp3, tri_samp3
                dw      tri_samp4,tri_samp4, tri_samp5, tri_samp5, tri_samp6, tri_samp6, tri_samp7, tri_samp7
                dw      noise_complement,noise_complement,noise_complement,noise_complement,noise_complement,noise_complement,noise_complement,noise_complement
end_directory_lut:


        triangle_sample_num = $10
        srcn_base           = $1c


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

lengthCounterTable:
        db 10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14, 12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30


; Maps $00–$0F to $00–$7F (linear scaling)
volumeTable:
    db $00, $08, $11, $19, $22, $2A, $33, $3B
    db $44, $4C, $55, $5D, $66, $6E, $77, $7F


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

PitchTable64:
    ; dw $6FDC, $165F, $0C6D, $089A, $0694, $0553, $0479, $03DB
    ; dw $0363, $0305, $02BA, $027C, $0248, $021C, $01F6, $01D5
    ; dw $01B8, $019F, $0188, $0173, $0161, $0150, $0141, $0133
    ; dw $0127, $011B, $0110, $0106, $00FD, $00F4, $00EC, $00E5
    ; dw $00DD, $00D7, $00D1, $00CB, $00C5, $00C0, $00BB, $00B6
    ; dw $00B1, $00AD, $00A9, $00A5, $00A1, $009E, $009A, $0097
    ; dw $0094, $0091, $008E, $008B, $0089, $0086, $0083, $0081
    ; dw $007F, $007D, $007A, $0078, $0076, $0074, $0073, $0071
    dw $1BF7, $1BF7, $0DFB, $0952
    dw $06FD, $0597, $04A9, $03FE
    dw $037E, $031B, $02CB, $028A
    dw $0254, $0226, $01FF, $01DD
    dw $01BF, $01A5, $018D, $0178
    dw $0165, $0154, $0145, $0137
    dw $012A, $011E, $0113, $0109
    dw $00FF, $00F6, $00EE, $00E6
    dw $00DF, $00D8, $00D2, $00CC
    dw $00C6, $00C1, $00BC, $00B7
    dw $00B2, $00AE, $00AA, $00A6
    dw $00A2, $009F, $009B, $0098
    dw $0095, $0092, $008F, $008C
    dw $0089, $0087, $0084, $0082
    dw $007F, $007D, $007B, $0079
    dw $0077, $0075, $0073, $0071

freqtable: incsrc "snestabl.asm"
PitchTable_Index0d: incsrc "apu-pitch-table.asm"

; tritable: incsrc "tritabl3.asm"

; tri_samp0: incsrc "./samples/tri6_sl3.asm"
; tri_samp1: incsrc "./samples/tri6_sl2.asm"
; tri_samp2: incsrc "./samples/tri6_sl1.asm"
; tri_samp3: incsrc "./samples/tri6.asm"
; tri_samp4: incsrc "./samples/tri6_sr1.asm"
; tri_samp5: incsrc "./samples/tri6_sr2.asm"
; tri_samp6: incsrc "./samples/tri6_sr3.asm"
; tri_samp7: incsrc "./samples/tri6_sr4.asm"

spc_driver_end:
print "spc driver end = ", pc
dw $0000
dw $1000
arch 65816