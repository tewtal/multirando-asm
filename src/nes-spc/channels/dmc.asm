;  Methods exposed which control the DMC
;  Zero-page variables used by the channel are also declared here


;  Variables
;  $d0->$df: DMC internal state

; dmcNeedToRun = $d3
dmcRealPeriodLo = $d4
dmcRealPeriodHi = $d5
dmcOutputLevel     = $d6
dmcLinearReloadValue = $d7
dmcLinearCounter = $d8

dmcBytesRemainingLo  = $d9
dmcBytesRemainingHi = $da
dmcReadBuffer = $db

dmcCurrentIndex = $dc
dmcCurrentAddr = $dd
dmcSrcn           = $de

dmcStateFlags = $df  ;  Channel state boolean flags:

;  d--- ---- :
!PreviousLengthEnabled = %10000000
!dmcPreviousLengthEnabledFlag   = "dmcStateFlags.7"
;  -d-- ---- :
!LengthEnabled = %01000000
!dmcLengthEnabledFlag   = "dmcStateFlags.6"
;  --d- ---- :
!Silence   = %00100000
!dmcSilenceFlag   = "dmcStateFlags.5"
;  ---d ---- :  
!PreviousSilence = %00010000
!dmcPreviousSilenceFlag   = "dmcStateFlags.4"
; ;  ---- d--- :  Unused
; !SweepNegate = %00001000
; !sq0SweepNegateFlag   = "sq0StateFlags.3"
; ;  ---- -d-- :
!Loop = %00000100
!dmcLoopFlag   = "dmcStateFlags.2"
;  ---- --d- :
!BufferEmpty = %00000010
!dmcBufferEmptyFlag   = "dmcStateFlags.1"
;  ---- ---d :  Unused


;  Methods
DMC:

;.GetOutput(?)
;.GetState(?)

.Run:
    ; $4015 write check; here we respond to SetEnabled(yes|no)
    ; if not lengthenabledflag
    mov1 c, !dmcPreviousLengthEnabledFlag
    bcc ..prevLength0
    mov1 c, !dmcLengthEnabledFlag
    bcc ..turnOff   ;  if LengthEnabled has done 1->0
    bra ..end       ; no change in state

..prevLength0:
    mov1 c, !dmcLengthEnabledFlag
    bcs ..initSample   ; ask if LengthEnabled has done 0->1
    bra ..end       ; no change in state

..turnOff:
    ;   disabledelay -> nonzero
    ;   needtorun -> true
    set1 !dmcSilenceFlag
    mov x,!DmcFlag
    call stopVoiceInX
    bra ..updateState

    ; else if sample not currently playing
..initSample:
    mov $f2, #$7c
    mov a, $f3   ; check if dmc voice is finished playing

    and a,!DmcFlag
    beq ..updateState
..turnOn:
    ;   startdelay -> nonzero
    ;   needtorun -> true
    clr1 !dmcSilenceFlag
    mov x,!DmcFlag
    call playVoiceInX

    ; else (implied)
    ;   game tried to start a sample when one was already playing; IGNORE IT


..updateState:
    ;  Manage state after acting on it above
    mov1 c, !dmcLengthEnabledFlag
    mov1 !dmcPreviousLengthEnabledFlag, c

    ; if not silenceflag
    ;   continue outputting

    ; if no sample is playing
    ;   set1 silenceflag
    ;   
    ; else
    ;   
..end:
ret

;  TODO: Remove
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
    ; mov a, #$00

    ; ; Mute VOL IN [A]
    ; mov $F2,SpcRegisterSelector     ; channel volume L
    ; mov $F3, a
    ; inc SpcRegisterSelector
    ; mov $F2,SpcRegisterSelector     ; channel volume R
    ; mov $F3, a

    ; KOFF voice
    mov $F2, !KOFF
    mov $F3, !TriangleFlag

    set1 !triWasMutedFlag   ;  Track that output has stopped so we can KON the next note
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

    mov a, triStateFlags
    and a, #!WasMuted
    beq ..end
    ; KON voice
    mov x,!TriangleFlag
    call playVoiceInX
    clr1 !triWasMutedFlag
..end:
ret


.Volume:

..Get:
    ;  Just returns the length counter OR the volume if constantvolume==true (TODO:)
ret

;  Process $4011 write
;  Note that raw pcm mode is not currently supported; the $4011 value is used to select an attenuation for
;  the current dpcm sample and set the output volume accordingly
..Set:
    cmp a, dmc_attenuation_cutoff
    bcs .halfvolume         ;  If value > threshold value in dmc_attenuation_cutoff, half volume

.fullvolume:                    ;  Otherwise, full volume
    mov $F2,!DmcVolumeL
    mov $F3,#$7f    ;  Full volume
    mov $F2,!DmcVolumeR
    mov $F3,#$7f    ;  Full volume
    bra +
.halfvolume:
    mov $F2,!DmcVolumeL
    mov $F3,#$3f    ;  Half volume
    mov $F2,!DmcVolumeR
    mov $F3,#$3f    ;  Half volume
+
    jmp ProcessWrites_handlerReturn


.Sample:

;  Process $4012 write
..Set:
    mov dmcCurrentAddr, a

...selectSample:
        mov a, $4000+x
        cmp a, dmcCurrentAddr
        beq ...setSample
        inc x
        cmp x, #$10 ;  Stop after checking all 16 values
        beq ...notFound ;  Sample not found
        bra ...selectSample

...notFound:
    set1 !dmcSilenceFlag
    bra +

...setSample:
    ;  X now contains the index of the chosen sample
    mov dmcCurrentIndex, x

    mov a, x
    clrc : adc a,#srcn_base&$ff  ;  Calculate the SRCN

    mov $F2, !DmcSRCN
    mov $F3, a       ;  Set srcn with the selected sample from pcm_addr

+
    jmp ProcessWrites_handlerReturn


.Period:

;  Process $4010 write
;  Set the period byte in [A]
..Set:
    mov x, !DMCOffset
...Start:

    ; _loopFlag = (value & 0x40) == 0x40;
    mov BitwiseScratch, a
    mov1 c, BitwiseScratch.2
    mov1 !dmcLoopFlag, c    ;  Transfer a.2 to dmcStateFlags.2

    ; _period = period;
    mov x, dmcCurrentIndex
    cmp a,$4010+x   ;  Compare incoming value with playback speed table
    !blt .slowspeed

    mov $F2,!DmcPitchL
    mov $F3,#$06
    mov $F2,!DmcPitchH
    mov $F3,#$0b
    bra +
.slowspeed:                     
    mov $F2,!DmcPitchL
    mov $F3,#$45
    mov $F2,!DmcPitchH
    mov $F3,#$08
+

    jmp ProcessWrites_handlerReturn

