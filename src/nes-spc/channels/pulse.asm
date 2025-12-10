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
;  $70->$7f: Square channel internal state (both sq0 and sq1)

sq0Envelope = $70
sq1Envelope = $71
sq0TimerTicks = $72
sq1TimerTicks = $73
sq0Duty = $74
sq1Duty = $75
sq0SweepEnabled = $76
sq1SweepEnabled = $77

;  Methods
Pulse:

;  Subroutine which ticks the envelope for the pulse channel flag in [A]
.TickEnvelope:

ret