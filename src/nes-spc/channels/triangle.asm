;  Methods exposed which control the triangle channel
;  Zero-page variables used by the channel are also declared here


;  Sample data (TODO: rename / inline and add descriptions)

tri_samp0: incsrc "../samples/tri6_sl3.asm"     ; 125 Hz
tri_samp1: incsrc "../samples/tri6_sl2.asm"     ; 250 Hz
tri_samp2: incsrc "../samples/tri6_sl1.asm"     ; 500 Hz - used 56
tri_samp3: incsrc "../samples/tri6.asm"         ; 1 kHz - used 28
tri_samp4: incsrc "../samples/tri6_sr1.asm"     ; 2 kHz - used 14
tri_samp5: incsrc "../samples/tri6_sr2.asm"     ; 4 kHz - used 7
tri_samp6: incsrc "../samples/tri6_sr3.asm"     ; 8 kHz - used 3
tri_samp7: incsrc "../samples/tri6_sr4.asm"     ; broken(?) constant output - used 1 (TODO: REMOVE)


;  Variables
;  $b0->$bf: Triangle internal state

triRealPeriodLo = $b4
triRealPeriodHi = $b5
; triVolume     = $b6
triLinearReloadValue = $b7
triLinearCounter = $b8

triLengthCounter   = $b9
triLengthReloadValue = $ba
triLengthPreviousValue = $bb

triTargetPeriodLo = $bc
triTargetPeriodHi = $bd
triSrcn           = $be

triStateFlags = $bf  ;  Channel state boolean flags:

;  d--- ---- :
!LinearControl = %10000000
!triLinearControlFlag   = "triStateFlags.7"
;  -d-- ---- :  
!LengthEnabled = %01000000
!triLengthEnabledFlag   = "triStateFlags.6"
;  --d- ---- :
!LengthHalt   = %00100000
!triLengthHaltFlag   = "triStateFlags.5"
;  ---d ---- :  
!LengthPostReloadHalt = %00010000
!triLengthPostReloadHaltFlag   = "triStateFlags.4"
; ;  ---- d--- :  Unused
; !SweepNegate = %00001000
; !sq0SweepNegateFlag   = "sq0StateFlags.3"
; ;  ---- -d-- :  Unused
;  ---- --d- :
!LinearReload = %00000010
!triLinearReloadFlag   = "triStateFlags.1"
;  -d-- ---- :  Unused
; !LinearControl = %00000001
; !triLinearControlFlag   = "triStateFlags.0"


;  Methods
Triangle:

;.GetOutput(?)
;.GetState(?)

;  Sends current triangle channel state to spc control registers
.UpdateOutput
    mov x, !TriangleOffset
    mov SpcRegisterSelector, !TriangleOffset
..Start:
    ; if(_lengthCounter.GetStatus() && _linearCounter > 0), -> mute output
    mov a, triLengthCounter
    beq ..muted
    mov a, triLinearCounter
    bne ..notMuted

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
    mov a, #$7f  ;TODO: this is max volume; determine correct relative volume given our triangle samples and in relation to the other channels

    ; SET VOL IN [A]
    mov $F2,SpcRegisterSelector     ; channel volume L
    mov $F3, a
    inc SpcRegisterSelector
    mov $F2,SpcRegisterSelector     ; channel volume R
    mov $F3, a

    ; Prepare spc pitch
    mov a, triRealPeriodLo
    mov PeriodLo, a
    mov a, triRealPeriodHi
    mov PeriodHi, a

    call CalcPitch
    call ._CalcSRCN

    ; SET SRCN
    clrc : adc SpcRegisterSelector, #$03    ;  Get SRCN register
    mov $F2,SpcRegisterSelector
    mov $F3, a

    dec SpcRegisterSelector     ; Get pitch high register
    mov $f2, SpcRegisterSelector
    mov $f3, PitchHi
    dec SpcRegisterSelector     ; Get pitch low register
    mov $f2, SpcRegisterSelector
    mov $f3, PitchLo
..end:
ret


;  Returns frequency-appropriate SRCN in [A]
;  Modifies PitchHi and PitchLo to account for the sample chosen
._CalcSRCN:
    ;  Case statement for PeriodHi:PeriodLo
    ;   when <= 0x6e then 1kHz sample (SRCN $13)
    ;   when > 0x6e then 125Hz sample (SRCN $10)
    mov   a, PeriodHi
    bne   ..125HzRange       ; if high != 0 → $0100–$07FF → ..125HzRange

    mov   a, PeriodLo
    cmp   a, #$6f
    !blt   ..1kHzRange

..125HzRange:
    mov a, #$10
    bra ..done

..1kHzRange:
    mov a, #$13
..done
    mov sq0Srcn+x, a             ; store result
ret


.Volume:

..Get:
    ;  Just returns the length counter OR the volume if constantvolume==true (TODO:)
ret


.LinearCounter:

;  Respond to $4008 writes by initializing length and linear counter values
;  Preserves instruction index in [Y]
..Init:
    push y
    mov y, a    ; preserve value

    ; _linearControlFlag = (value & 0x80) == 0x80;  //  !LinearControl flag
    ; and _newHaltValue = _linearControlFlag;       //  !LengthPostReloadHalt flag
    ; both flags get the same value based on value & 0x80
...setLinearControl:
    and  a, !LinearControl  ;  value & 0x80
    beq ....disable
    mov a, triStateFlags
    or a, #(!LinearControl|!LengthPostReloadHalt)
    bra +
....disable:
    mov a, triStateFlags
    and a, #~(!LinearControl|!LengthPostReloadHalt)
+
    mov triStateFlags, a

    ; _linearCounterReload = value & 0x7F;
    mov a, y
    and a, #$7f
    mov triLinearReloadValue, a

    ; _lengthCounter.InitializeLengthCounter(_linearControlFlag);
        ; _console->GetApu()->SetNeedToRun();
        ; _newHaltValue = haltFlag;   -> already done above
    mov NeedToRun, #$01

...end:
    pop y
    jmp ProcessWrites_handlerReturn

;  Tick the triangle channel's linear counter
..Tick:
    mov x, !TriangleOffset
...Start:
    mov a, triStateFlags
    and a, #!LinearReload   ;  if(_linearReloadFlag)
    beq +
    ;  then: _linearCounter = _linearCounterReload;
    mov a, triLinearReloadValue
    mov triLinearCounter, a
    bra ...next
+
    mov a, triLinearCounter ;  else if(_linearCounter > 0)
    beq ...next
    ;  then: _linearCounter--;
    dec triLinearCounter


...next:
    mov a, triStateFlags
    and a, #!LinearControl  ; if(!_linearControlFlag)
    bne ...end
    ;  then: _linearReloadFlag = false;
    clr1 !triLinearReloadFlag
...end:
ret


.LengthCounter:

;  Tick the triangle channel's length counter
..Tick:
    mov x, !TriangleOffset
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
;  Note: [Y] not preserved
..Load:
    mov x, !TriangleOffset
    mov SpcRegisterSelector, !TriangleFlag
...Start:
    ; 	_envelope.LengthCounter.LoadLengthCounter(value >> 3);
    ; push y
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
;     ; SetPeriod((_realPeriod & 0xFF) | ((value & 0x07) << 8));
;     mov a, y
;     and a, #$07
;     mov sq0RealPeriodHi+x, a

;     ;  Emulate pulse sequencer restart (dutyPos = 0) by issuing a KOFF and KON
;     ;  to the current channel
;     push x
;     mov x, SpcRegisterSelector
;     call stopVoiceInX
;     call playVoiceInX
;     pop x

;     ; //The envelope is also restarted.
;     ; _envelope.ResetEnvelope();
;     ;  Set reloadSweep = true
;     mov a, sq0StateFlags+x
;     or a, #!EnvelopeStart
;     mov sq0StateFlags+x, a

;     ;  Follow "Set need to run" logic
;     ;  TODO: Check state dp value
;     mov a, NeedToRun
;     beq ...skipRun
;     mov NeedToRun, #$00     ;  Reset APU->NeedToRun
;     push x
;     call Run
;     pop x

; ...skipRun:
;     pop y
ret

; Reload length counter
..Reload:
    mov x, !TriangleOffset
...Start:
    mov a, sq0LengthReloadValue+x
    beq ...end          ; if reload value != 0, then

    mov a, sq0LengthCounter+x
    cmp a, sq0LengthPreviousValue+x
    ; TODO: Is there a BUG here?  lengthcounter off-by-1 to lengthpreviousvalue so recently-loaded length counter value gets blown away and reset to 0...
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
..SetLow:
    mov x, !TriangleOffset
...Start:
    ;_timer.SetPeriod((_timer.GetPeriod() & 0xFF00) | value);
    ;   _period = period;
    mov triRealPeriodLo, a

    jmp ProcessWrites_handlerReturn

;  Process $400b write
;  Set the period high byte in [A]
;  Preserves instruction index in [Y]
..SetHigh:
    mov x, !TriangleOffset
...Start:
    push y
    mov y, a  ; preserve value

    ; _lengthCounter.LoadLengthCounter(value >> 3);
    call .LengthCounter_Load

    ; _timer.SetPeriod((_timer.GetPeriod() & 0xFF) | ((value & 0x07) << 8));
    mov a, y
    and a, #$07
    mov triRealPeriodHi, a

    ; //Side effects 	Sets the linear counter reload flag 
    ; _linearReloadFlag = true;
    set1 !triLinearReloadFlag

    pop y
    jmp ProcessWrites_handlerReturn