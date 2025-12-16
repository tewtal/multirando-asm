;  Internal state and methods for managing the Apu Frame Counter
    FrameCounterCycle = $81     ;  Track the 240Hz subdivision being processed, from $00 -> $03 (or $04 for 5-step mode)
    FrameCounterStepMode = $82  ;  4-step or 5-step nes apu mode

;  TODO: make into subroutine
.resetFrameCounter:
    ;  Reset frame step mode and counter
    ;  [ACCURACY TODO]: Impelement a _writeDelayCounter (https://github.com/SourMesen/Mesen2/blob/master/Core/NES/APU/ApuFrameCounter.h)
    mov FrameCounterCycle, #$00
    and a, #$80
    beq .setStepMode0
    mov FrameCounterStepMode, #$01
    bra +
.setStepMode0
    mov FrameCounterStepMode, #$00
    bra +

;  TODO: make into subroutine
.updateFrameCounter:
    ;  Update current frame counter cycle number
    inc FrameCounterCycle
    mov a, FrameCounterCycle
    setc : sbc a, FrameCounterStepMode
    cmp a, #$04
    !blt +
    mov FrameCounterCycle, #$00 ;  Start new cycle
+