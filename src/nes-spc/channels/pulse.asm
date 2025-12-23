;  Methods exposed which control the sq0 and sq1 pulse channels
;  Zero-page variables used by these channels are also declared here

;  Sample data (TODO: rename / inline and add descriptions)

; 1 sample
pulse0: incsrc "../samples/pl1a-0.asm"
pulse1: incsrc "../samples/pl1a-1.asm"
pulse2: incsrc "../samples/pl1a-2.asm"
pulse3: incsrc "../samples/pl1a-3.asm"

; 2 samples
pulse0d: incsrc "../samples/pl1-0.asm"
pulse1d: incsrc "../samples/pl1-1.asm"
pulse2d: incsrc "../samples/pl1-2.asm"
pulse3d: incsrc "../samples/pl1-3.asm"

; 4 samples
pulse0c: incsrc "../samples/pl2-0.asm"
pulse1c: incsrc "../samples/pl2-1.asm"
pulse2c: incsrc "../samples/pl2-2.asm"
pulse3c: incsrc "../samples/pl2-3.asm"

; 8 samples
pulse0b: incsrc "../samples/pl3-0.asm"
pulse1b: incsrc "../samples/pl3-1.asm"
pulse2b: incsrc "../samples/pl3-2.asm"
pulse3b: incsrc "../samples/pl3-3.asm"


;  Variables
;  $90->$9f: Square 0 internal state
;  $a0->$af: Square 1 internal state

sq0Envelope = $90
sq0TimerTicks = $91
sq0Duty = $92
sq0SweepEnabled = $93
sq0SweepPeriod = $94
sq0SweepNegate = $95
sq0SweepShift = $96
sq0ReloadSweep = $97
sq0SweepDivider = $98
sq0SweepDividerPeriod = $99
sq0RealPeriod = $9a
sq0Volume     = $9b
sq0Halted     = $9c     ;  #$20 if set; #$00 if clear
sq0Start      = $9d
sq0EnvelopeDivider = $9e
sq0EnvelopeCounter = $9f

sq1Envelope = $a0
sq1TimerTicks = $a1
sq1Duty = $a2
sq1SweepEnabled = $a3
sq1SweepPeriod = $a4
sq1SweepNegate = $a5
sq1SweepShift = $a6
sq1ReloadSweep = $a7
sq1SweepDivider = $a8
sq1SweepDividerPeriod = $a9
sq1RealPeriod = $aa
sq1Volume     = $ab
sq1Halted     = $ac     ;  #$20 if set; #$00 if clear
sq1Start      = $ad
sq1EnvelopeDivider = $ae
sq1EnvelopeCounter = $af

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
    mov y, a

    ;  Set duty
    and a, #$c0
    rep 6 : lsr a
    mov sq0Duty+x, a

    ;  Set halted
    mov a, y
    and a, #$20
    mov sq0Halted+x, a

    ;  Set volume
    ;  TODO: constantvolume(?)
    mov a, y
    and a, #$0f
    mov sq0Volume+x, a

    jmp ProcessWrites_handlerReturn

;  Tick the envelope
..Tick:
    mov a, sq0Start+x
    beq ...stopped                  ;  if not start, then
    dec sq0EnvelopeDivider+x        ;  divider--
    bpl ...end
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

    mov a, sq0EnvelopeCounter
    beq ...counterzero
    dec sq0EnvelopeCounter+x        ;  counter--
    bra ...end
...counterzero:
    mov a, sq0Halted+x
    beq ...end                      ;  if halted, then
    mov a, #$0f
    mov sq0EnvelopeCounter+x, a     ;  counter = 15
    bra ...end

...stopped:
    mov a, #$00
    mov sq0Start+x, a               ;  start = false
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
    mov y, a

    ;  Set sweep enabled
    and a, #$80
    mov sq0SweepEnabled+x, a

    ;  Set sweep negate
    mov a, y
    and a, #$08
    mov sq0SweepNegate+x, a

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


    ;  Update target period
    ; ShiftResult
    ; TODO: calc lookup tables
    ;  old spc uses SNESTABL, a *4096* byte lookup table
    ;  we need to either burn cycles and do the 16-bit math,
    ;  or generate an 7+3-bit lookup table: 1024 bytes I guess?

    mov a, #$01
    mov sq0ReloadSweep+x, a

    nop
    nop
    jmp ProcessWrites_handlerReturn

;  Tick the sweep for the pulse channel flag in [A]
..Tick:

ret

.Volume:

..Get:
    ;  Just returns the length counter OR the volume if constantvolume==true (TODO:)
ret

.LengthCounter:

;  Tick the length counter for the pulse channel flag in [A]
..Tick:

ret

;  Reload the length counter for the pulse channel flag in [A]
..Reload:
    nop
    nop
    nop
    nop
    jmp ProcessWrites_handlerReturn

;..SetEnabled(?)
;..GetStatus(?)

.Period:

;  Set the period for the pulse channel flag in [A]
..SetLow:
    nop
    nop
    nop
    jmp ProcessWrites_handlerReturn

..SetHigh:

ret