;  Internal state and methods for managing the Apu Frame Counter
FrameCounterCycle = $81     ;  Track the 240Hz subdivision being processed, from $00 -> $05 (or $04 for 5-step mode)
FrameCounterStepMode = $82  ;  4-step or 5-step nes apu mode
FrameCounterTickBlockCounter =  $8b     ;  Tracks how the apu prevents ticks after running FrameCount_Tick
FrameCounterNewValue = $8c  ;  Has a new value written to $4017 for processing 

FrameCountFlags = $8f  ;  Channel state boolean flags:

;  ---- -d-- :
!HasNewValue = %00000100
!vcHasNewValueFlag   = "FrameCountFlags.2"
;  ---- --d- :
!TickLengthCounters = %00000010
!vcTickLengthCountersFlag   = "FrameCountFlags.1"
;  ---- ---d :
!TickEnvelopes = %00000001
!vcTickEnvelopesFlag   = "FrameCountFlags.0"


FrameCount:

;  Lookups

;  Represents which objects get Tick methods called for each FrameCounterCycle
;  Bytes are ---- --Le, where L is length counters/sweeps and e is envelopes/linear counter.
;  Note that the added 0th indexes account for the difference between the SPC timer counter
;  and the "step" as documented in the NES APU.  APU's first step occurs 3,728 cycles after the start (index 1 here)
.tickUnit4StepTable:
    db %00000000, %00000001, %00000011, %00000001, %00000011
.tickUnit5StepTable:
    db %00000000, %00000001, %00000011, %00000001, %00000000, %00000011


;  Methods

;  Params:
;   [A]: New value
.Set:
    mov FrameCounterNewValue, a ;  store new $4017 value
    set1 !vcHasNewValueFlag

    push y
    call Run
    pop y

    jmp ProcessWrites_handlerReturn


.Run:
    ;  Immediate exit if FrameCounterTickBlockCounter is set
    mov a, FrameCounterTickBlockCounter
    beq ..continue
    mov FrameCounterTickBlockCounter, #$00  ;  reset
    bra ..end

..continue:
    mov a, FrameCounterStepMode
    beq ..4step
..5step:
    mov x, FrameCounterCycle
    mov a, .tickUnit5StepTable+x     ;  Get current frame type
    bra +
..4step
    mov x, FrameCounterCycle
    mov a, .tickUnit4StepTable+x     ;  Get current frame type
+

    mov x, a ; preserve frame type value

    beq ..updateStep  ; skip if frame type is none
    ; mov a, FrameCounterTickBlockCounter
    ; bne ..updateStep  ; skip if tick block counter is nonzero
    mov a, FrameCountFlags
    and a, #!HasNewValue
    bne ..updateStep  ; skip if $4017 was just set (we run .HalfTick at the end of the method in this special case)

    mov a, x ; restore frame type value

..runTick:
    and a, #$02
    beq ..quarterTick
    call .HalfTick
    bra +
..quarterTick:
    call .QuarterTick
+
..updateStep:
    ;  Update current frame counter step
    inc FrameCounterCycle
    mov a, FrameCounterCycle
    setc : sbc a, FrameCounterStepMode
    cmp a, #$04
    !blt +
    mov FrameCounterCycle, #$00 ;  Start new cycle
+

    ;  if _newValue
    mov a, FrameCountFlags
    and a, #!HasNewValue
    beq ..end

    mov FrameCounterTickBlockCounter, #$01  ;  Prevent another immediate Apu.Run from ticking the frame count

    ;  [ACCURACY TODO]: Impelement a _writeDelayCounter (https://github.com/SourMesen/Mesen2/blob/master/Core/NES/APU/ApuFrameCounter.h)
    ;  _stepMode = ((_newValue & 0x80) == 0x80) ? 1 : 0;
    mov a, FrameCounterNewValue
    and a, #$80
    beq ..setStepMode0
    mov FrameCounterStepMode, #$01
    bra +
..setStepMode0
    mov FrameCounterStepMode, #$00
+

    ;  _currentStep = 0;
    mov FrameCounterCycle, #$00

    ;  _newValue = -1;
    clr1 !vcHasNewValueFlag

    ;  Restart Timer0 (TODO: de-dupe)
    mov TimerLatchIndex, #$00
    mov $f1, #$00                  ; stop timers before latch write
    mov a, #33
    mov $FA, a                  ; Timer0 latch
    mov a, #$01
    mov $f1, a                   ; start Timer0 (ST0=1)

    ; if(_stepMode && !_blockFrameCounterTick) {
    ; 	_console->GetApu()->FrameCounterTick(FrameType::HalfFrame);
    mov a, FrameCounterStepMode
    beq ..end
    call .HalfTick

..end:
    ret

;  TODO: Ensure .HalfTick -> .QuarterTick ordering has no side effects (mesen2 does it the other way which may be meaningful)
.HalfTick:
    ;  Process all length counters and sweeps
    call Pulse_LengthCounter_Tick
    call Pulse_LengthCounter_Tick2
    call Triangle_LengthCounter_Tick
    call Noise_LengthCounter_Tick

    call Pulse_Sweep_Tick
    call Pulse_Sweep_Tick2
    ;  Fall-through to .QuarterTick

.QuarterTick:
        ;  Process all envelopes and triangle linear counter
    call Pulse_Envelope_Tick
    call Pulse_Envelope_Tick2
    call Triangle_LinearCounter_Tick
    call Noise_Envelope_Tick
ret

; .Tick:
;  Task lists for the current frame count:
;  fc == 0 ?  envelopes
;  fc == 1 ?  length counters; sweeps; envelopes
;  fc == 2 ?  envelopes
;  fc == 3 ?  mode == 0 ? length counters; sweeps; envelopes : (none)
;  fc == 4 ?  length counters; sweeps; envelopes

;  "Process envelopes" = !(mode == 1 && fc == 3)
;   reduces nicely to mode + fc != 4

;     mov a, FrameCounterStepMode
;     clrc : adc a, FrameCounterCycle
;     cmp a, #$04     ;  Only way to have 4 here is 3+1 (can never have 4+0)
;     beq .endHandler

; .processEnvelopes:


; ;  "Process length counters & sweeps" = fc==1 || fc==4 || (fc==3 && mode==0) 
; ;   already in simplest form

;     mov a, FrameCounterCycle
;     cmp a, #$01
;     beq .processLCs
;     cmp a, #$04
;     beq .processLCs
;     cmp a, #$03
;     bne .endHandler
;     cmp FrameCounterStepMode, #$00
;     bne .endHandler

; .processLCs:
;     ;  Process all length counters and sweeps
;     call Pulse_LengthCounter_Tick
;     call Pulse_LengthCounter_Tick2
;     call Triangle_LengthCounter_Tick
;     call Noise_LengthCounter_Tick

;     call Pulse_Sweep_Tick
;     call Pulse_Sweep_Tick2
; .endHandler:
; ret