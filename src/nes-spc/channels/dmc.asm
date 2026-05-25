;  Methods exposed which control the DMC
;  Zero-page variables used by the channel are also declared here


;  Variables
;  $d0->$df: DMC internal state

dmcRealPeriodLo   = $d4
dmcRealPeriodHi   = $d5
dmcOutputLevel    = $d6
dmcSampleLengthLo = $d7
dmcSampleLengthHi = $d8

dmcBytesRemainingLo = $d9
dmcBytesRemainingHi = $da
dmcReadBuffer       = $db

dmcCurrentIndex = $dc
dmcCurrentAddr  = $dd
dmcSrcn         = $de

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
; ;  ---- -d-- :
!Loop = %00000100
!dmcLoopFlag   = "dmcStateFlags.2"
;  ---- --d- :
!BufferEmpty = %00000010
!dmcBufferEmptyFlag   = "dmcStateFlags.1"
;  ---- ---d :  Unused


DMC:

;  Constants
!DMCFullVolume = #$59  ;  Matches NES output dB
!DMCLowVolume  = #$30

;  Lookups
; round(bytes_per_quarter_frame * 8)
.samplesPerQuarterFrame:
    db $11, $14, $16, $17, $1A, $1D, $21, $23
    db $27, $2F, $35, $3A, $46, $59, $68, $8A

;  Methods

.Run:  ; Cycles: 8 -> ..prevLength0; 14 -> ..turnOff; 16 -> ..end.
    ; $4015 write check; here we respond to SetEnabled(yes|no)
    ; if not lengthenabledflag
    mov1 c, !dmcPreviousLengthEnabledFlag
    bcc ..prevLength0
    mov1 c, !dmcLengthEnabledFlag
    bcc ..turnOff   ;  if LengthEnabled has done 1->0
    bra ..end       ; no change in state

..prevLength0:  ; Cycles: 8 -> ..initSample; 10 -> ..end.
    mov1 c, !dmcLengthEnabledFlag
    bcs ..initSample   ; ask if LengthEnabled has done 0->1
    bra ..end       ; no change in state

..turnOff:  ; Cycles: 28.
    ;   disabledelay -> nonzero
    ;   needtorun -> true
    mov dmcBytesRemainingLo, #$00
    mov dmcBytesRemainingHi, #$00
    set1 !dmcSilenceFlag
    mov x,!DmcFlag
    call stopVoiceInX
    bra ..updateState

    ; else if sample not currently playing
..initSample:  ; Cycles: 10 -> ..updateState while active; 18 -> ..updateState with no length;
               ;         28 -> ..turnOn; 34 -> ..updateState when sample missing.
    mov a, dmcBytesRemainingLo
    or  a, dmcBytesRemainingHi
    bne ..updateState

    mov a, dmcSampleLengthLo
    or  a, dmcSampleLengthHi
    beq ..updateState

    call ._initSample          ; select SRCN, pitch, load bytesRemaining
    bcs ..turnOn               ; carry set = sample found

    set1 !dmcSilenceFlag
    bra ..updateState

..turnOn:  ; Cycles: 14.
    ;   startdelay -> nonzero
    ;   needtorun -> true
    clr1 !dmcSilenceFlag
    mov x,!DmcFlag
    call playVoiceInX

    ; else (implied)
    ;   game tried to start a sample when one was already playing; ignore

..updateState:  ; Cycles: 14.
    ;  Manage state after acting on it above
    mov1 c, !dmcLengthEnabledFlag
    mov1 !dmcPreviousLengthEnabledFlag, c
    bra ..bye

..end:  ; Cycles: 10 -> ..bye; 12 if length flag is cleared.
    mov a, dmcBytesRemainingLo
    or a, dmcBytesRemainingHi
    bne ..bye
    clr1 !dmcLengthEnabledFlag
..bye:  ; Cycles: 5.
ret


;  Prepare loaded values for sample playback
._initSample:
    mov x, #$00

..selectSample:
    mov a, $4000+x
    cmp a, dmcCurrentAddr
    beq ..setSample

    inc x
    cmp x, #$10
    bne ..selectSample

    clrc
    ret

..setSample:
    mov dmcCurrentIndex, x

    mov a, x
    clrc : adc a, #srcn_base&$ff
    mov $F2, !DmcSRCN
    mov $F3, a

    mov a, dmcSampleLengthLo
    mov dmcBytesRemainingLo, a
    mov a, dmcSampleLengthHi
    mov dmcBytesRemainingHi, a

..selectPlaybackSpeed:
    mov a, dmcRealPeriodLo     ; masked $4010 low nibble
    cmp a, $4010+x
    !blt ..slowspeed

..normalspeed:
    mov $F2, !DmcPitchL
    mov $F3, #$06
    mov $F2, !DmcPitchH
    mov $F3, #$0b
    setc
    ret

..slowspeed:
    mov $F2, !DmcPitchL
    mov $F3, #$45
    mov $F2, !DmcPitchH
    mov $F3, #$08
    setc
    ret


.Volume:
;  Process $4011 write
;  Note that raw pcm mode is not currently supported; the $4011 value is used to select an attenuation for
;  the current dpcm sample and set the output volume accordingly
..Set:
    cmp a, dmc_attenuation_cutoff
    bcs .halfvolume         ;  If value > threshold value in dmc_attenuation_cutoff, half volume

.fullvolume:                    ;  Otherwise, full volume
    mov $F2, !DmcVolumeL
    mov $F3, !DMCFullVolume
    mov $F2, !DmcVolumeR
    mov $F3, !DMCFullVolume
    bra +
.halfvolume:
    mov $F2, !DmcVolumeL
    mov $F3, !DMCLowVolume
    mov $F2, !DmcVolumeR
    mov $F3, !DMCLowVolume
+
    jmp ProcessWrites_handlerReturn


.Length:

;  Run every quarter frame to update bytes remaining
..Tick:
    mov1 c, !dmcSilenceFlag
    bcs ...end
    mov1 c, !dmcLengthEnabledFlag
    bcc ...end
    
    mov x, dmcRealPeriodLo
    mov a, dmcBytesRemainingLo
    setc
    sbc a, .samplesPerQuarterFrame+x
    mov dmcBytesRemainingLo, a

    mov a, dmcBytesRemainingHi
    sbc a, #$00
    mov dmcBytesRemainingHi, a
    bcc ...finished
    bne ...end
    mov a, dmcBytesRemainingLo
    bne ...end

...finished:
    mov dmcBytesRemainingLo, #$00
    mov dmcBytesRemainingHi, #$00
    clr1 !dmcLengthEnabledFlag
    mov x, !DmcFlag
    call stopVoiceInX
...end:
ret

;  Process $4013 write
..Set:
    ;  _sampleLength = ((value << 4) | 0x0001) * 8;
    push y
    mov y, a
    lsr a
    mov dmcSampleLengthHi, a

    mov a, #$08
    bcc +
    or a, #$80
+
    mov dmcSampleLengthLo, a
    pop y
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
    mov BitwiseScratch, a
    and a, #$0f
    mov dmcRealPeriodLo, a

    ; _loopFlag = (value & 0x40) == 0x40;
    mov1 c, BitwiseScratch.6
    mov1 !dmcLoopFlag, c

    jmp ProcessWrites_handlerReturn
