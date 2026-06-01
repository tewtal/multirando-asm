;  Methods exposed which control the noise channel
;  Zero-page variables used by this channel are also declared here
!DSP_FLG = #$6C     ;  DSP register: FLG (noise clock)

;  Sample data
noise_complement: incbin "../samples/noise-complement.brr"

;  Variables
;  $c0->$cf: Noise internal state

noiseComplementSampleIndex = $c0
noiseComplementLfsr        = $c1

noisePeriod = $c4
noiseVolume     = $c6
noiseEnvelopeDivider = $c7
noiseEnvelopeCounter = $c8
noiseLengthCounter   = $c9
noiseLengthReloadValue = $ca
noiseLengthPreviousValue = $cb

noiseStateFlags = $cf  ;  Channel state boolean flags:
;  d--- ---- :
!OutputMode = %10000000
!noiseOutputModeFlag = "noiseStateFlags.7"
;  -d-- ---- :  
!LengthEnabled = %01000000
!noiseLengthEnabledFlag   = "noiseStateFlags.6"
;  --d- ---- :
!LengthHalt   = %00100000
!noiseLengthHaltFlag   = "noiseStateFlags.5"
;  ---d ---- :  
!ConstantVolume = %00010000
!noiseConstantVolumeFlag   = "noiseStateFlags.4"
;  ---- d--- :  Unused
;  ---- -d-- :  Unused
;  ---- --d- :  Unused
;  ---- ---d : 
!EnvelopeStart  = %00000001
!noiseEnvelopeStartFlag   = "noiseStateFlags.0"


Noise:

;  Lookups

; nes apu noise period to spc noise clock lookup
.frequencyTable:
    db $3f, $3f, $3f, $3f, $3f, $3e, $3e, $3d
    db $3c, $3b, $3a, $38, $36, $35, $32, $2f 

; Q7 gain to apply to complement channel output
; based on current noise period $00 -> $0f
.complementAttenuationTable:
    db $03, $40, $5B, $72, $80, $40, $48, $29
    db $1D, $1D, $17, $0E, $09, $07, $05, $03

; Base volumes for noise channels
.volumeTable:
.complementVolumeTable:
    db $00, $01, $05, $07, $09, $0c, $0e, $10
    db $12, $15, $17, $19, $1c, $1f, $22, $25


;  Methods

;  Sends current noise channel state to spc control registers
.UpdateOutput  ; Cycles: 7.
    mov x, !NoiseOffset
    mov SpcRegisterSelector, !NoiseOffset
..Start:  ; Cycles: 8 -> ..muted; 16 -> ..notConstant; 22 -> volume path.
    ;  Noise output is only conditionally muted by a zeroed length counter;
    ;  its output is otherwise controlled by its envelope
    mov a, sq0LengthCounter+x
    beq ..muted
    mov a, sq0StateFlags+x
    and a, #!ConstantVolume
    beq ..notConstant
    mov a, sq0Volume+x
    bra +

..muted:  ; Cycles: 46.
    ;  then set channel vol -> 0
    mov a, #$00

    ; Mute VOL IN [A]
    mov $F2,SpcRegisterSelector     ; channel volume L
    mov $F3, a
    inc SpcRegisterSelector
    mov $F2,SpcRegisterSelector     ; channel volume R
    mov $F3, a
    ; Mute Noise complement VOL
    mov $F2,!NoiseCompVolumeL     ; channel volume L
    mov $F3, a
    mov $F2,!NoiseCompVolumeR     ; channel volume R
    mov $F3, a
    bra ..end

..notConstant:  ; Cycles: 4.
    mov a, sq0EnvelopeCounter+x
+  ; Cycles: 135.

    push a  ; preserve volume to set

    push x
    mov x, a
    mov a, Noise_volumeTable+x
    pop x

    ; SET VOL IN [A]  TODO: de-dupe
    mov $F2,SpcRegisterSelector     ; channel volume L
    mov $F3, a
    inc SpcRegisterSelector
    mov $F2,SpcRegisterSelector     ; channel volume R
    mov $F3, a

    pop a   ; restore volume to set

    GainComputeResult = $0a

    push x
    mov x, a
    mov a, Noise_complementVolumeTable+x
    mov GainComputeResult, a    ; base volume

    ;  Lookup attenuation gain for the current noise period
    mov x, noisePeriod
    mov a, Noise_complementAttenuationTable+x
    mov y, a

    mov a, GainComputeResult
    mul ya                      ; YA = base * Q7 gain
    asl a
    mov a, y
    rol a                       ; A = attenuated volume
    pop x

    ; SET noise complement VOL IN [A]
    mov $F2,!NoiseCompVolumeL     ; channel volume L
    mov $F3, a
    mov $F2,!NoiseCompVolumeR     ; channel volume R
    mov $F3, a

    push x
    mov $F2, !DSP_FLG
    mov x, noisePeriod
    mov a, Noise_frequencyTable+x
    mov $F3, a
    pop x
..end:  ; Cycles: 5.
ret


.Envelope:

;  Start a new envelope value in [A]
..Init:
    mov x, !NoiseOffset
...Start:
    push y
    mov y, a

...setNeedToRun:
    mov NeedToRun, #$01     ;  Set APU->NeedToRun

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
..Tick:
    mov x, !NoiseOffset
...Start:
    mov a, sq0StateFlags+x
    and a, #!EnvelopeStart
    bne ...stopped                  ;  if not start, then
    dec sq0EnvelopeDivider+x        ;  divider--
    bpl ...end
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

    mov a, sq0EnvelopeCounter+x
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
    clr1 !noiseEnvelopeStartFlag      ;  start = false
+
    mov a, #$0f
    mov sq0EnvelopeCounter+x, a     ;  counter = 15
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

...end:
ret


.Volume:

.LengthCounter:

;  Tick the noise channel's length counter
..Tick:
    mov x, !NoiseOffset
...Start:
    mov a, sq0LengthCounter+x
    beq ...end
    mov a, sq0StateFlags+x
    and a, #!LengthHalt
    bne ...end                      ;  if counter > 0 && !halt, then
    dec sq0LengthCounter+x
...end:
ret

;  Load the length counter with value in [A]
..Load:
    mov x, !NoiseOffset
    mov SpcRegisterSelector, !NoiseFlag
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
    ; _envelope.ResetEnvelope();
    set1 !noiseEnvelopeStartFlag

    pop y
    jmp ProcessWrites_handlerReturn

;  Reload length counter
..Reload:
    mov x, !NoiseOffset
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
ret


.Period:

;  Set the period low byte in [A]
..Set:
    mov x, !NoiseOffset
...Start:
    push y
    mov y, a    ; preserve value
    
    and a, #$0f
    mov sq0RealPeriodLo+x, a
    
    ; _modeFlag = (value & 0x80) == 0x80;
    mov a, y
    and a, #!OutputMode
    beq ...disable
    set1 !noiseOutputModeFlag
    bra +
...disable:
    clr1 !noiseOutputModeFlag
+
    pop y
    jmp ProcessWrites_handlerReturn
