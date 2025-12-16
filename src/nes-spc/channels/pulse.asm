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