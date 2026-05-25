;  NES APU Engine for the Quad Randomizer
;  by https://github.com/Andypro1

;  Aims to emulate the NES APU at a fairly low level, while
;  translating the sequencer into samples for the spc-700.

;  References:
;    -  https://www.nesdev.org/wiki/APU
;           Cycle accurate detailed reference on the NES APU
;    -  https://github.com/SourMesen/Mesen2/blob/master/Core/NES/APU
;           A good implementation of the above spec in a high-level language
;           License:  GPL-3.0
;    -  https://github.com/Myself086/Project-Nested/tree/master/Assembly/Project/Spc700
;           Earlier implementation of NES APU functionality on the spc-700
;           License:  MIT
;    -  https://github.com/bbbradsmith/NESertGolfing/blob/snes/spc/
;           Noise channel mixin complement idea from Brad Smith's NESertGolfing snes up-port
;           License:  CC BY 4.0


print "apu init driver start = ", pc
spc_init_driver:
    pha : phx : phy : phb : php
    
    rep #$30
    ldy #spc_driver
    phk : plb
    jsr send_apu_data

    plp : plb : ply : plx : pla
    rtl

incsrc "./apu-send.asm"

print "apu-driver = ", pc
spc_driver:
arch spc700-inline
org $1000
startpos start

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
!Square0AltFlag = #%01000000
!Square1AltFlag = #%10000000

!BothSquare0s = #%01000001
!BothSquare1s = #%10000010

!Square0Offset  = #$00
!Square1Offset  = #$10
!TriangleOffset = #$20
!NoiseOffset    = #$30
!DMCOffset      = #$40
!Square0AltOffset = #$60
!Square1AltOffset = #$70

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
!Square0AltVolumeL = #$60
!Square0AltVolumeR = #$61
!Square1AltVolumeL = #$70
!Square1AltVolumeR = #$71

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
!Square0AltPitchL = #$62
!Square0AltPitchH = #$63
!Square1AltPitchL = #$72
!Square1AltPitchH = #$73

!Square0SRCN  = #$04
!Square1SRCN  = #$14
!TriangleSRCN = #$24
!NoiseSRCN    = #$34
!DmcSRCN      = #$44
!NoiseCompSRCN = #$54
!Square0AltSRCN = #$64
!Square1AltSRCN = #$74

!KON          = #$4c
!KOFF         = #$5c

;  Fixed values
!TriangleVolume   = #$53  ;  Matches NES output dB
!NoiseCompSRCNVal = #$14

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
dmc_attenuation_cutoff: db $41

;  Example dmc table (for Zelda 1):
;  $4000-$400f:  $00,$1d,$20,$4c,$80
;  $4010-$401f:  $0f,$0f,$0f,$0f,$0d
;  $4020-$405f:  $4014,$4014,$5631,$5631,$58b0,$58b0,$7cc2,$7cc2,$9e28,$9e28
;                (little endian, as it appears in aram: 14 40 14 40 31 56 31 56 B0 58 B0 58 C2 7C C2 7C 28 9E 28 9E)
;========================================

;  Apu memory allocations
;  $00->$1e: Reserved for immediate heap access for subroutines (if needed)
BitwiseScratch = $08    ;  subroutine heap storage for values to be operated on using the spc-700 bit instructions

;  $80->$8f: General apu, frame counter, general length counter (if needed)
TimerLatchIndex = $80       ;  Cyclic latch_table lookup providing constant 240Hz ticks
; $81, $82 reserved by Frame Counter
WritesJumpPointer = $83     ;  2-byte address storing the pointer to the write handler
ShiftResult       = $85     ;  2-byte heap variable used by pulse channels
TickStepOccurring = $87
; $88: unused
; $89 reserved by Pulse
NeedToRun         = $8a
; $8b, $8c  reserved by Frame Counter
voicesPlaying   = $8d ; Voice bit flags tracking which are currently playing
; $8e: unused
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
        ;   5: Noise complement
        ;   6: Square Wave 0 alternate range
        ;   7: Square Wave 1 alternate range

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
        mov $F2,#$65
        mov $F3,#0
        mov $F2,#$75
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
        mov $F2,#$67
        mov $F3,#$1F
        mov $F2,#$77
        mov $F3,#$1F

        ;  Init triangle voice
        mov $F2, !TriangleSRCN            ; sample # for triangle
        mov $F3, #triangle_sample_num
        mov a, !TriangleVolume
        mov $F2, !TriangleVolumeL     ; channel volume L
        mov $F3, a
        mov $F2, !TriangleVolumeR     ; channel volume R
        mov $F3, a

        ;  Init noise complement voice - standard pitch $1000
        mov y, #$00
        mov a, !NoiseCompPitchL
        movw $f2, ya
        mov y, #$10
        inc a
        movw $f2, ya

        mov $F2,!NoiseSRCN
        mov $F3,#$00            ; sample # for noise

        mov $F2, !NoiseCompSRCN
        mov $F3, !NoiseCompSRCNVal

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
        ; --- Check and process cpu sends ---
        mov a,$F4
        cmp a,#$d7  ; wait for port 0 to be $d7 (CPU ready)
        beq apurecv ; new cpu data waiting to send
        bra WaitTick

TimerExpired:
        ;  Check for an spc reset signal
        mov a, $f4
        cmp a, #$f5
        bne +
        call to_reset
+
        inc TickStepOccurring   ; mark that we've entered an apu step for FrameCounter.Run()
        inc TimerLatchIndex     ; advance pattern index
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
incsrc "./channels/dmc.asm"
incsrc "./apu-status.asm"

;  Safe fill for invalid register values
NullRoutine: jmp ProcessWrites_handlerReturn

JumpTable:
    ;  Square channel 0
    dw Pulse_Envelope_Init, Pulse_Sweep_Init, Pulse_Period_SetLow, Pulse_LengthCounter_Load
    ;  Square channel 1
    dw Pulse_Envelope_Init2, Pulse_Sweep_Init2, Pulse_Period_SetLow2, Pulse_LengthCounter_Load2
    ;  Triangle channel
    dw Triangle_LinearCounter_Init, NullRoutine, Triangle_Period_SetLow, Triangle_Period_SetHigh
    ;  Noise channel
    dw Noise_Envelope_Init, NullRoutine, Noise_Period_Set, Noise_LengthCounter_Load
    ;  DMC
    dw DMC_Period_Set, DMC_Volume_Set, DMC_Sample_Set, DMC_Length_Set
    ;  Status and Frame counter
    dw NullRoutine, Status_Set, NullRoutine, FrameCount_Set


;  This subroutine is a hack to guarantee apu writes and ticks are processed 100% in sequence.
;  Unfortunately, ProcessWrites can take up so much apu time that not all ticks occur before the next
;  sequence of writes.  Particularly FrameCounterStep $03.  fc==3 *must* run before $4017 resets it
;  to 0 - otherwise the envelope and linear counters can be off by 1.
;  We'll revisit the need for this after cycle optimization.
CheckInterimTick:
    mov a, FrameCounterCycle
    cmp a, #$03
    !bge .end

    ; --- Perform variable-length work ---
    inc TickStepOccurring
    call TickHandler
.end:
    ret


;------------------------------------------------------------------------
;  Process all queued apu register writes in the order they were recieved
;------------------------------------------------------------------------
ProcessWrites:
; NumbersQueue = $20
; ValuesQueue  = $50

    call CheckInterimTick   ;  Ensure all of the prior frames ticks have been processed before processing new writes

    ;  Run call precedes all register writes.  
    ;  Instead of calling it for each queued write which would
    ;  take too long, we do it once at the start
    call Run

    mov y, #$00
.loop:
    cmp y, QueueLength
    bcs .done

    ;  Calculate a jump pointer based on this register number
    mov a, NumbersQueue+y
    asl a
    mov x, a
    mov a, JumpTable+x
    mov WritesJumpPointer, a
    inc x
    mov a, JumpTable+x
    mov WritesJumpPointer+1, a

    mov a, ValuesQueue+y    ;  Load param in [A]
    mov x, #$00
    ;jmp [WritesJumpPointer+x]  ;  Handler specified in jump table
    db $1f, WritesJumpPointer, $00  ;  ASAR doesn't handle this spc syntax correctly; db the opcode directly

.handlerReturn:
    inc y
    bra .loop

.done:
    mov QueueLength, #$00    ; finished; reset writes queue index

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
    call DMC_Run
ret


;------------------------------------
; Frame tick routine (runs at 240 Hz)
;------------------------------------
TickHandler:
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

    ;  Tick the active DMC regardless of frame counter rules/steps.
    ;  This operates on a strict 240Hz cadence
    call DMC_Length_Tick
ret


;==========~ Subroutines ~========
;  Subroutines to support the main
;  processing loop
;=================================

;---------------------------------
; CalcPitch
; Input : PeriodLo / PeriodHi
; Output: PitchLo  / PitchHi
;---------------------------------
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


;  Used on game transitions to silence audio and reset the spc
to_reset:
    pop a : pop a  ;  Remove call stack entry
    mov     $F2,!KOFF
    mov     $F3,#$FF        ;  KOFF all notes

    mov	$F1,#$B0
    jmp $ffc0

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


;  Clears internal state at driver initialization
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


;  Initializes the SRCN sample lookup directory table
set_directory:
    mov x, #(end_directory_lut-set_directory_lut-1)

set_directory_loop:
    mov	a,set_directory_lut+x
    mov	$0200+x,a
    dec	x
    bpl	set_directory_loop

    ;  Append dynamic dmc entries from $4020
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
    dw	pulse0,pulse0, pulse0,pulse0, pulse0b,pulse0b, pulse0b,pulse0b
    dw	pulse1,pulse1, pulse1,pulse1, pulse1b,pulse1b, pulse1b,pulse1b
    dw	pulse2,pulse2, pulse2,pulse2, pulse2b,pulse2b, pulse2b,pulse2b
    dw	pulse3,pulse3, pulse3,pulse3, pulse3b,pulse3b, pulse3b,pulse3b
    dw  tri_samp0,tri_samp0, tri_samp0, tri_samp0, tri_samp3, tri_samp3, tri_samp3, tri_samp3
    dw  noise_complement,noise_complement,noise_complement,noise_complement,noise_complement,noise_complement,noise_complement,noise_complement
end_directory_lut:

    triangle_sample_num = $10
    srcn_base           = $18

;  NES apu length counter lookup
lengthCounterTable:
    db 10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14, 12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30

PitchTable_Index0d: incsrc "apu-pitch-table.asm"

spc_driver_end:
print "apu driver end = ", pc
dw $0000
dw $1000
arch 65816
