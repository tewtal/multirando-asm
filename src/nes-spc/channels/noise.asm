;  Methods exposed which control the noise channel
;  Zero-page variables used by this channel are also declared here
!DSP_FLG = #$6C     ;  DSP register: FLG (noise clock)

;  Sample data
; noise_complement: incsrc "../samples/noise-complement.asm"

;  Variables
;  $c0->$cf: Noise internal state

noiseDuty = $c0

noisePeriod = $c4
; noiseRealPeriodHi = $c5
noiseVolume     = $c6
noiseEnvelopeDivider = $c7
noiseEnvelopeCounter = $c8
noiseLengthCounter   = $c9
noiseLengthReloadValue = $ca
noiseLengthPreviousValue = $cb
; noiseTargetPeriodLo = $cc
; noiseTargetPeriodHi = $cd
; noiseSrcn           = $ce

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
.frequencyTable:
    db $3f, $3f, $3f, $3f, $3f, $3e, $3e, $3d
    db $3c, $3b, $3a, $38, $36, $35, $32, $2f 

.complementaryPitchTable:
    ; dw $04E2,$04E2,$04E2,$04E2,$04E2,$0271,$0271,$01A1    ;  orig table
    ; dw $0138,$00FA,$00D0,$007D,$0068,$003E,$001F,$0010
    dw $0138,$0138,$0138,$0138,$0138,$0271,$0271,$01A1
    dw $0138,$00FA,$00D0,$007D,$0068,$003E,$001F,$0010

; .volumeTable:
;     ; db $00, $04, $08, $0c, $11, $15, $19, $1d
;     ; db $22, $26, $2a, $2e, $13, $37, $3b, $3F

;     db $00, $06, $0c, $13, $17, $25, $2a, $22
;     db $33, $3a, $40, $45, $30, $50, $55, $5F

.complementVolumeTable:
db  0, 127, 127, 127, 127, 42, 46, 46     ;  orig table
db  46, 46, 46, 46, 46, 46, 46, 46

.volumeTable:
; db  0, 5, 6, 8, 10, 11, 12, 12
; db  12, 12, 12, 12, 12, 12, 12, 12

    db $00, $08, $11, $19, $22, $2A, $33, $3B   ; DEBUG: full values
    db $44, $4C, $55, $5D, $66, $6E, $77, $7F


;  Methods

;.GetOutput(?)
;.GetState(?)

;  Sends current noise channel state to spc control registers
.UpdateOutput
    mov x, !NoiseOffset
    mov SpcRegisterSelector, !NoiseOffset
..Start:
    ;  Noise output is only conditionally muted by a zeroed length counter;
    ;  its output is otherwise controlled by its envelope.
    mov a, sq0LengthCounter+x
    beq ..muted
    mov a, sq0StateFlags+x
    and a, #!ConstantVolume
    beq ..notConstant
    mov a, sq0Volume+x
    bra +

..muted:
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

..notConstant:
    mov a, sq0EnvelopeCounter+x
+

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

    push x
    mov x, a
    mov a, Noise_complementVolumeTable+x
    pop x

    ; SET noise complement VOL IN [A]  TODO: de-dupe
    mov $F2,!NoiseCompVolumeL     ; channel volume L
    mov $F3, a
    mov $F2,!NoiseCompVolumeR     ; channel volume R
    mov $F3, a


    call ._CalcNoiseSampleNumber

    ; SET Noise frequency (TODO:)
    ; mov $F2, !DSP_FLG

    push x
    mov $F2, !DSP_FLG
    mov x, noisePeriod
    mov a, Noise_frequencyTable+x
    mov $F3, a

	mov A, X    ;  Double noise period for 16-bit table index
	asl A
	mov X, A

    mov $f2, !NoiseCompPitchL
	mov a, Noise_complementaryPitchTable+0+X ; pitch for complementary noise sample
	mov $f3, A
    mov $f2, !NoiseCompPitchH
	mov a, Noise_complementaryPitchTable+1+X
	mov $f3, A

    pop x
..end:
ret


._CalcNoiseSampleNumber: ;TODO:
    ;  Case statement for PeriodHi:PeriodLo
    ;   when <= 0x6e then 2kHz sample (SRCN 0)
    ;   when > 0x6e then 250Hz sample (SRCN 3)
;     mov   a, PeriodHi
;     bne   ..250HzRange       ; if high != 0 → $0100–$07FF → Range 3

;     mov   a, PeriodLo
;     cmp   a, #$6f
;     !blt   ..2kHzRange

; ..250HzRange:
;     mov a, #$03
;     bra ..done

; ..2kHzRange:
;     mov a, #$00
; ..done
;     mov sq0Srcn+x, a             ; store result
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
    clr1 !noiseEnvelopeStartFlag      ;  start = false
+
    mov a, #$0f
    mov sq0EnvelopeCounter+x, a     ;  counter = 15
    mov a, sq0Volume+x
    mov sq0EnvelopeDivider+x, a     ;  divider = volume

...end:
ret


.Volume:

..Get:
    ;  Just returns the length counter OR the volume if constantvolume==true (TODO:)
ret

.LengthCounter:

;  Tick the noise channel's length counter
..Tick:
    mov x, !NoiseOffset
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
    ;  TODO: 
    ; _halt = _newHaltValue;
ret



;..SetEnabled(?)
;..GetStatus(?)

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
