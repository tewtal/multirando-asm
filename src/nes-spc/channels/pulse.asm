;  Methods exposed which control the sq0 and sq1 pulse channels
;  Zero-page variables used by these channels are also declared here
SpcRegisterSelector = $89

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
sq0Srcn           = $9e

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
sq1Srcn           = $ae

sq1StateFlags = $af  ;  Channel state boolean flags (see sq0 above)

;  Methods
Pulse:

;.GetOutput(?)
;.GetState(?)

;  Sends current pulse channel state to spc control registers
.UpdateOutput2
    mov x, !Square1Offset
    mov SpcRegisterSelector, !Square1Offset
    bra .UpdateOutput_Start
.UpdateOutput
    mov x, !Square0Offset
    mov SpcRegisterSelector, !Square0Offset
..Start:
    ;  if (_realPeriod < 8 || (!_sweepNegate && _sweepTargetPeriod > 0x7FF))
    mov a, sq0RealPeriodHi+x
    bne ..sweepCheck
    mov a, sq0RealPeriodLo+x
    cmp a, #$09
    !blt ..muted     ; if real period < 8, muted
..sweepCheck:
    mov a, sq0StateFlags+x
    and a, #!SweepNegate
    bne ..notMuted  ; if sweepNegate, not muted
    mov a, sq0TargetPeriodHi+x
    cmp a, #$08
    bpl ..muted     ; if target period > 0x7ff, muted
    bra ..notMuted

..muted:
    ;  then set channel vol -> 0
    mov a, #$00

    ; Mute VOL IN [A]
    mov $F2,SpcRegisterSelector     ; channel volume L
    mov $F3, a
    inc SpcRegisterSelector
    mov $F2,SpcRegisterSelector     ; channel volume R
    mov $F3, a
    bra ..end

..notMuted:
    mov a, sq0LengthCounter+x
    beq ..muted
    mov a, sq0StateFlags+x
    and a, #!ConstantVolume
    beq ..notConstant
    mov a, sq0Volume+x
    bra +
..notConstant:
    mov a, sq0EnvelopeCounter+x
+
    push x
    mov x, a
    mov a, volumeTable+x
    pop x

    ; SET VOL IN [A]
    mov $F2,SpcRegisterSelector     ; channel volume L
    mov $F3, a
    inc SpcRegisterSelector
    mov $F2,SpcRegisterSelector     ; channel volume R
    mov $F3, a

    ; Prepare spc pitch
    mov a, sq0RealPeriodLo+x
    mov PeriodLo, a
    mov a, sq0RealPeriodHi+x
    mov PeriodHi, a

    call CalcPitch
    call ._CalcSRCN

    mov a, sq0Duty+x
    asl a : asl a   ;  Shift duty into bits 0000_dd00
    or a, sq0Srcn+x    ;  a = 0000_ddff

    ; SET SRCN
    clrc : adc SpcRegisterSelector, #$03    ;  Get SRCN register
    mov $F2,SpcRegisterSelector
    mov $F3, a                   ; x0: 2kHz, x1: 1kHz, x2: 500Hz, x3: 250Hz

    dec SpcRegisterSelector     ; Get pitch high register
    mov $f2, SpcRegisterSelector
    mov $f3, PitchHi
    dec SpcRegisterSelector     ; Get pitch low register
    mov $f2, SpcRegisterSelector
    mov $f3, PitchLo
..end:
ret


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
    beq ....disable
    mov a, sq0StateFlags+x
    or a, #!LengthHalt
    bra +
....disable:
    mov a, sq0StateFlags+x
    and a, #~!LengthHalt
+
    mov sq0StateFlags+x, a

    ;  Set constant volume
...setConstantVolume:
    mov a, y
    and a, #$10
    beq ....disable
    mov a, sq0StateFlags+x
    or a, #!ConstantVolume
    bra +
....disable:
    mov a, sq0StateFlags+x
    and a, #~!ConstantVolume
+
    mov sq0StateFlags+x, a

    ;  Set volume
    mov a, y
    and a, #$0f
    mov sq0Volume+x, a

    pop y
    jmp ProcessWrites_handlerReturn

;  Tick the envelope
..Tick2:
    mov x, !Square1Offset
    bra ..Tick_Start
..Tick:
    mov x, !Square0Offset
...Start:
    mov a, sq0StateFlags+x
    and a, #!EnvelopeStart
    bne ...stopped                  ;  if not start, then
    dec sq0EnvelopeDivider+x        ;  divider--
    bpl ...end
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

    mov a, sq0EnvelopeCounter+x
    ; bmi ...counterNotPositive   ;  should not be needed
    beq ...counterNotPositive
    dec sq0EnvelopeCounter+x        ;  counter--
    bra ...end
...counterNotPositive:
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
..Tick2:
    mov x, !Square1Offset
    bra ..Tick_Start
..Tick:
    mov x, !Square0Offset
...Start:
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

;  Returns frequency-appropriate SRCN in [A]
;  Modifies PitchHi and PitchLo to account for the sample chosen
._CalcSRCN:
    mov     a, #$00              ; SRCN = 0

    cmp     PitchHi, #$20
    bcs     ..done              ; >= $2000 → SRCN 0

    inc     a                  ; SRCN = 1
    asl     PitchLo
    rol     PitchHi
    cmp     PitchHi, #$20
    bcs     ..done

    inc     a                  ; SRCN = 2
    asl     PitchLo
    rol     PitchHi
    cmp     PitchHi, #$20
    bcs     ..done

    inc     a                  ; SRCN = 3
    asl     PitchLo
    rol     PitchHi
..done:  ; A = SRCN (0–3)
    mov sq0Srcn+x, a             ; store result
ret

._UpdateTargetPeriod:
    ;  Load period heap memory
    ShiftResultLo = $00
    ShiftResultHi = $01

    mov a, sq0RealPeriodLo+x
    mov ShiftResultLo, a
    mov a, sq0RealPeriodHi+x
    mov ShiftResultHi, a

..sweepShift:
    mov a, sq0SweepShift+x
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

;  Tick the pulse channel's length counter
..Tick2:
    mov x, !Square1Offset
    bra ..Tick_Start
..Tick:
    mov x, !Square0Offset
...Start:
    mov a, sq0LengthCounter+x
    ; bmi ...end  ; should not be needed
    beq ...end
    mov a, sq0StateFlags+x
    and a, #!LengthHalt
    bne ...end                      ;  if counter > 0 && !halt, then
    dec sq0LengthCounter+x
...end:
ret

;  Load the length counter with value in [A]
..Load2:
    mov x, !Square1Offset
    bra ..Load_Start
..Load:
    mov x, !Square0Offset
...Start:
    ; 	_envelope.LengthCounter.LoadLengthCounter(value >> 3);
    push y
    mov y, a
    mov a, sq0StateFlags+x
    and a, #!LengthEnabled
    beq ...done             ; if length enabled, then
    push x
    mov a, y
    clrc : lsr a : lsr a : lsr a    ; value >> 3
    mov x, a                ; retrieve value as index
    mov a, lengthCounterTable+x
    pop x
    mov sq0LengthReloadValue+x, a

    mov a, sq0LengthCounter+x
    mov sq0LengthPreviousValue+x, a ; previous value = counter
    
    mov NeedToRun, #$01     ;  Set APU->NeedToRun

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

    ;  Follow "Set need to run" logic
    ;  TODO: Check state dp value
    mov a, NeedToRun
    beq ...skipRun
    mov NeedToRun, #$00     ;  Reset APU->NeedToRun
    push x
    call Run
    pop x

...skipRun:
    pop y
    jmp ProcessWrites_handlerReturn

;  Reload length counter
..Reload2:
    mov x, !Square1Offset
    bra ..Reload_Start
..Reload:
    mov x, !Square0Offset
...Start:
    mov a, sq0LengthReloadValue+x
    beq ...end          ; if reload value != 0, then

    mov a, sq0LengthCounter+x
    cmp a, sq0LengthPreviousValue+x
    bne ...resetReloadValue     ; if length counter == previous value, then

    mov a, sq0LengthReloadValue+x
    mov sq0LengthCounter+x, a   ; length counter = reload value
...resetReloadValue:
    mov a, #$00
    mov sq0LengthReloadValue+x, a   ; reload value = 0
...end:
    ;  TODO: 
    ; _halt = _newHaltValue;
ret



;..SetEnabled(?)
;..GetStatus(?)

.Period:

;  Set the period low byte in [A]
..SetLow2:
    mov x, !Square1Offset
    bra ..SetLow_Start
..SetLow:
    mov x, !Square0Offset
...Start:
    mov sq0RealPeriodLo+x, a
    call ._UpdateTargetPeriod

    jmp ProcessWrites_handlerReturn

;  TODO: unused?
; ..SetHigh:
;     mov x, !Square0Offset
; ...Start:
    ; ret