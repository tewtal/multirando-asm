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
;  $70->$7f: Square 0 internal state
;  $80->$8f: Square 1 internal state

sq0Envelope = $70
sq0TimerTicks = $71
sq0Duty = $72
sq0SweepEnabled = $73
sq0SweepPeriod = $74
sq0SweepNegate = $75
sq0SweepShift = $76
sq0ReloadSweep = $77
sq0SweepDivider = $78
sq0SweepDividerPeriod = $79
sq0RealPeriod = $7a

sq1Envelope = $80
sq1TimerTicks = $81
sq1Duty = $82
sq1SweepEnabled = $83
sq1SweepPeriod = $84
sq1SweepNegate = $85
sq1SweepShift = $86
sq1ReloadSweep = $87
sq1SweepDivider = $88
sq1SweepDividerPeriod = $89
sq1RealPeriod = $8a

;  Methods
Pulse:

;.GetOutput(?)
;.GetState(?)

.Envelope:

;  Start a new envelope value for the pulse channel flag in [A]
..Init:

ret

;  Tick the envelope for the pulse channel flag in [A]
..Tick:

ret

.Sweep:
;  Start a new sweep for the pulse channel flag in [A]
..Init:

ret

;  Tick the sweep for the pulse channel flag in [A]
..Tick:

ret

.LengthCounter:

;  Tick the length counter for the pulse channel flag in [A]
..Tick:

ret

;  Reload the length counter for the pulse channel flag in [A]
..Reload:

ret

;..SetEnabled(?)
;..GetStatus(?)


;  Set the period for the pulse channel flag in [A]
.SetPeriod:

ret