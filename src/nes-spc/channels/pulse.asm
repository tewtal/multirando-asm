;  Methods exposed which control the sq0 and sq1 pulse channels
;  Zero-page variables used by these channels are also declared here

;  Sample data (TODO: rename / inline and add descriptions)

; 1 sample
pulse0: incsrc "../samples/pl1a-0.asm"  ;  f = 2kHz
pulse1: incsrc "../samples/pl1a-1.asm"  ;  f = 2kHz
pulse2: incsrc "../samples/pl1a-2.asm"  ;  f = 2kHz
pulse3: incsrc "../samples/pl1a-3.asm"  ;  f = 2kHz

; 2 samples
pulse0d: incsrc "../samples/pl1-0.asm"  ;  f = 1kHz
pulse1d: incsrc "../samples/pl1-1.asm"  ;  f = 1kHz
pulse2d: incsrc "../samples/pl1-2.asm"  ;  f = 1kHz
pulse3d: incsrc "../samples/pl1-3.asm"  ;  f = 1kHz

; 4 samples
pulse0c: incsrc "../samples/pl2-0.asm"  ;  f = 500Hz
pulse1c: incsrc "../samples/pl2-1.asm"  ;  f = 500Hz
pulse2c: incsrc "../samples/pl2-2.asm"  ;  f = 500Hz
pulse3c: incsrc "../samples/pl2-3.asm"  ;  f = 500Hz

; 8 samples
pulse0b: incsrc "../samples/pl3-0.asm"  ;  f = 250Hz
pulse1b: incsrc "../samples/pl3-1.asm"  ;  f = 250Hz
pulse2b: incsrc "../samples/pl3-2.asm"  ;  f = 250Hz
pulse3b: incsrc "../samples/pl3-3.asm"  ;  f = 250Hz


;  Variables
;  $90->$9f: Square 0 internal state
;  $a0->$af: Square 1 internal state

sq0Duty = $90
sq0SweepPeriod = $91
sq0SweepShift = $92
sq0SweepDivider = $93
sq0RealPeriodLo = $94
sq0RealPeriodHi = $95
sq0Volume     = $96
sq0EnvelopeDivider = $97
sq0EnvelopeCounter = $98
sq0LengthCounter   = $99
sq0LengthReloadValue = $9a
sq0LengthPreviousValue = $9b
sq0TargetPeriodLo = $9c
sq0TargetPeriodHi = $9d

sq0StateFlags = $9f  ;  Channel state boolean flags:
;  d--- ---- :
!SweepEnabled = %10000000
!sq0SweepEnabledFlag   = "sq0StateFlags.7"
!sq1SweepEnabledFlag   = "sq1StateFlags.7"
;  -d-- ---- :  
!LengthEnabled = %01000000
!sq0LengthEnabledFlag   = "sq0StateFlags.6"
!sq1LengthEnabledFlag   = "sq1StateFlags.6"
;  --d- ---- :
!LengthHalt   = %00100000
!sq0LengthHaltFlag   = "sq0StateFlags.5"
!sq1LengthHaltFlag   = "sq1StateFlags.5"
;  ---d ---- :  
!ConstantVolume = %00010000
!sq0ConstantVolumeFlag   = "sq0StateFlags.4"
!sq1ConstantVolumeFlag   = "sq1StateFlags.4"
;  ---- d--- :  
!SweepNegate = %00001000
!sq0SweepNegateFlag   = "sq0StateFlags.3"
!sq1SweepNegateFlag   = "sq1StateFlags.3"
;  ---- -d-- :  Unused
;  ---- --d- :  
!ReloadSweep = %00000010
!sq0ReloadSweepFlag   = "sq0StateFlags.1"
!sq1ReloadSweepFlag   = "sq1StateFlags.1"
;  ---- ---d : 
!EnvelopeStart  = %00000001
!sq0EnvelopeStartFlag   = "sq0StateFlags.0"
!sq1EnvelopeStartFlag   = "sq1StateFlags.0"


sq1Duty = $a0
sq1SweepPeriod = $a1
sq1SweepShift = $a2
sq1SweepDivider = $a3
sq1RealPeriodLo = $a4
sq1RealPeriodHi = $a5
sq1Volume     = $a6
sq1EnvelopeDivider = $a7
sq1EnvelopeCounter = $a8
sq1LengthCounter   = $a9
sq1LengthReloadValue = $aa
sq1LengthPreviousValue = $ab
sq1TargetPeriodLo = $ac
sq1TargetPeriodHi = $ad

sq1StateFlags = $af  ;  Channel state boolean flags (see sq0 above)

;  Methods
Pulse:

;.GetOutput(?)
;.GetState(?)

.Envelope:

;  Start a new envelope value in [A]
..Init2:
    mov x, !Square1Offset
    bra ..Init_Start
..Init:
    mov x, !Square0Offset
...Start:
    push y
    mov y, a

    ;  Set duty
    and a, #$c0
    rep 6 : lsr a
    mov sq0Duty+x, a

    ;  Set halt
...setHalt:
    mov a, y
    and  a, #$20
    cmp x, !Square0Offset
    bne ....sq1
    clr1 !sq0LengthHaltFlag
    or a, sq0StateFlags
    mov  sq0StateFlags, a
    bra +
....sq1:
    clr1 !sq1LengthHaltFlag
    or a, sq1StateFlags
    mov  sq1StateFlags, a
+

    ;  Set constant volume
...setConstantVolume:
    mov a, y
    and a, #$10
    cmp x, !Square0Offset
    bne ....sq1
    clr1 !sq0ConstantVolumeFlag
    or a, sq0StateFlags
    mov  sq0StateFlags, a
    bra +
....sq1:
    clr1 !sq1ConstantVolumeFlag
    or a, sq1StateFlags
    mov  sq1StateFlags, a
+

    ;  Set volume
    mov a, y
    and a, #$0f
    mov sq0Volume+x, a

    pop y
    jmp ProcessWrites_handlerReturn

;  Tick the envelope
..Tick:
    mov a, sq0StateFlags+x
    and a, #!EnvelopeStart
    bne ...stopped                  ;  if not start, then
    dec sq0EnvelopeDivider+x        ;  divider--
    bpl ...end
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

    mov a, sq0EnvelopeCounter+x
    beq ...counterzero
    dec sq0EnvelopeCounter+x        ;  counter--
    bra ...end
...counterzero:
    mov a, sq0StateFlags+x
    and a, #!LengthHalt
    beq ...end                      ;  if halted, then
    mov a, #$0f
    mov sq0EnvelopeCounter+x, a     ;  counter = 15
    bra ...end

...stopped:
    cmp x, !Square0Offset
    bne ...sq1
    clr1 !sq0EnvelopeStartFlag      ;  start = false
    bra +
...sq1:
    clr1 !sq1EnvelopeStartFlag      ;  start = false
+
    mov a, #$0f
    mov sq0EnvelopeCounter+x, a     ;  counter = 15
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

...end:
ret

.Sweep:
;  Start a new sweep value in [A]
..Init2:
    mov x, !Square1Offset
    bra ..Init_Start
..Init:
    mov x, !Square0Offset
...Start:
    push y
    mov y, a

    ;  Set sweep enabled
...sweepEnable:
    and a, #$80
    beq ....disable
    mov a, sq0StateFlags+x
    or a, #!SweepEnabled
    bra +
....disable:
    mov a, sq0StateFlags+x
    and a, #~!SweepEnabled
+
    mov sq0StateFlags+x, a

    ;  Set sweep negate
...sweepNegate:
    mov a, y
    and a, #$08
    beq ....disable
    mov a, sq0StateFlags+x
    or a, #!SweepNegate
    bra +
....disable:
    mov a, sq0StateFlags+x
    and a, #~!SweepNegate
+
    mov sq0StateFlags+x, a

    ;  Set sweep period
    mov a, y
    and a, #$70
    rep 4 : lsr a
    inc a
    mov sq0SweepPeriod+x, a

    ;  Set sweep shift
    mov a, y
    and a, #$07
    mov sq0SweepShift+x, a

    call ._UpdateTargetPeriod

    ;  Set reloadSweep = true
    mov a, sq0StateFlags+x
    or a, #!ReloadSweep
    mov sq0StateFlags+x, a

    pop y
    jmp ProcessWrites_handlerReturn


;  Tick the sweep
..Tick:
    dec sq0SweepDivider+x
    bne ...reloadSweep
    mov a, sq0SweepShift+x
    beq ...done
    mov a, sq0StateFlags+x
    and a, #!SweepEnabled
    beq ...done
    mov a, sq0TargetPeriodHi+x
    and a, #$f8
    bne ...done
    mov a, sq0RealPeriodLo+x
    and a, #$f8
    bne ...setPeriod
    mov a, sq0RealPeriodHi+x
    beq ...done

...setPeriod:
    mov a, sq0TargetPeriodLo+x
    mov sq0RealPeriodLo+x, a
    mov a, sq0TargetPeriodHi+x
    mov sq0RealPeriodHi+x, a    ; realperiod = targetperiod

    call ._UpdateTargetPeriod

...done:
    mov a, sq0SweepPeriod+x
    mov sq0SweepDivider+x, a    ; divider = period

...reloadSweep:
    mov a, sq0StateFlags+x
    and a, #!ReloadSweep
    beq +
    mov a, sq0SweepPeriod+x
    mov sq0SweepDivider+x, a    ; divider = period
+
ret


._UpdateTargetPeriod:
    ; TODO (no): calc lookup tables
    ;  old spc uses SNESTABL, a *4096* byte lookup table
    ;  we need to either burn cycles and do the 16-bit math,
    ;  or generate an 7+3-bit lookup table: 1024 bytes I guess?

    ;  Load period heap memory
    ShiftResultLo = $00
    ShiftResultHi = $01

    mov a, sq0RealPeriodLo+x
    mov ShiftResultLo, a
    mov a, sq0RealPeriodHi+x
    mov ShiftResultHi, a

..sweepShift:
    mov sq0SweepShift+x, a
    beq ...done          ; 0-bit shift → no work

...loop:
    lsr ShiftResultHi           ; shift high byte right
    ror ShiftResultLo             ; rotate carry into low byte
    dec a
    bne ...loop
...done:

    mov a, sq0StateFlags+x
    and a, #!SweepNegate
    beq ...add
...subtract:
    setc

    mov a, sq0RealPeriodLo+x
    sbc a, ShiftResultLo
    mov sq0TargetPeriodLo+x, a

    mov a, sq0RealPeriodHi+x
    sbc a, ShiftResultHi
    mov sq0TargetPeriodHi+x, a

    cmp x, #$00
    beq +
    dec sq0TargetPeriodLo+x     ;  sweep target period -1
    ;  TODO: check above dec for underflow
    bra +

...add:
    clrc

    mov a, sq0RealPeriodLo+x
    adc a, ShiftResultLo
    mov sq0TargetPeriodLo+x, a

    mov a, sq0RealPeriodHi+x
    adc a, ShiftResultHi
    mov sq0TargetPeriodHi+x, a
+
ret


.Volume:

..Get:
    ;  Just returns the length counter OR the volume if constantvolume==true (TODO:)
ret

.LengthCounter:

;  Tick the length counter for the pulse channel flag in [A]
..Tick:

ret

;  Load the length counter with value in [A]
..Load:
    ; 	_envelope.LengthCounter.LoadLengthCounter(value >> 3);
    push y
    mov y, a
    mov a, sq0StateFlags+x
    and a, !LengthEnabled
    beq ...done             ; if length enabled, then
    push x
    mov a, y
    clrc : ror a : ror a : ror a    ; value >> 3
    mov x, a                ; retrieve value as index
    mov a, lengthCounterTable+x
    pop x
    mov sq0LengthReloadValue+x, a

    mov a, sq0LengthCounter+x
    mov sq0LengthPreviousValue+x, a ; previous value = counter
    
    ; TODO:?? follow "Set need to run" logic

...done:
    ; SetPeriod((_realPeriod & 0xFF) | ((value & 0x07) << 8));
    mov a, y
    and a, #$07
    mov sq0RealPeriodHi+x, a

    ; //The envelope is also restarted.
    ; _envelope.ResetEnvelope();
    ;  Set reloadSweep = true
    mov a, sq0StateFlags+x
    or a, #!EnvelopeStart
    mov sq0StateFlags+x, a

    pop y
    jmp ProcessWrites_handlerReturn

;..SetEnabled(?)
;..GetStatus(?)

.Period:

;  Set the period low byte in [A]
..SetLow:
    mov sq0RealPeriodLo+x, a
    call ._UpdateTargetPeriod

    jmp ProcessWrites_handlerReturn

..SetHigh:

ret