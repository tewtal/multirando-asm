;;; SPC Upload Code Borrowed from Super Metroid ;;;
;;; $8059: Send APU data ;;;
send_apu_data:
{
;; Parameters:
;;     Y: Address of data
;;     DB: Bank of data

; Data format:
;     ssss dddd [xx xx...] (data block 0)
;     ssss dddd [xx xx...] (data block 1)
;     ...
;     0000 aaaa
; Where:
;     s = data block size in bytes
;     d = destination address
;     x = data
;     a = entry address. Ignored by SPC engine after first APU transfer

; The xx data can cross bank boundaries, but the data block entries otherwise can't (i.e. s, d, a and 0000) unless they're word-aligned

; Wait until APU sets APU IO 0..1 = AAh BBh
; Kick = CCh
; For each data block:
;    APU IO 2..3 = destination address
;    APU IO 1 = 1 (arbitrary non-zero value)
;    APU IO 0 = kick
;    Wait until APU echoes kick back through APU IO 0
;    Index = 0
;    For each data byte
;       APU IO 1 = data byte
;       APU IO 0 = index
;       Wait until APU echoes index back through APU IO 0
;       Increment index
;    Increment index (and again if resulting in 0)
;    Kick = index
; Send entry address through APU IO 2..3
; APU IO 1 = 0
; APU IO 0 = kick
; (Optionally wait until APU echoes kick back through APU IO 0)

        PHP
        REP #$30
        LDA.w #$3000             ;\
        STA.l $000641               ;|
                                  ;|
.apuWait 
        LDA.w #$BBAA                ;|
        CMP.l $002140               ;|
        BEQ .apuReady                   ;} Wait until [APU IO 0..1] = AAh BBh
        LDA.l $000641               ;|
        DEC A                     ;|
        STA.l $000641               ;|
        BNE .apuWait                   ;/
.crash
        BRA .crash                   ; If exceeded 3000h attempts: crash

.apuReady
        SEP #$20
        LDA.b #$CC                  ; Kick = CCh
        BRA .processDataBlock     ; Go to BRANCH_PROCESS_DATA_BLOCK

; BRANCH_UPLOAD_DATA_BLOCK
.uploadDataBlock
        LDA.w $0000,y               ;\
        JSR .incY                 ;} Data = [[Y++]]
        XBA                       ;/
        LDA.b #$00                  ; Index = 0
        BRA .uploadData           ; Go to BRANCH_UPLOAD_DATA

; LOOP_NEXT_DATA
.loopNextData
        XBA                       ;\
        LDA.w $0000,y               ;|
        JSR .incY                 ;} Data = [[Y++]]
        XBA
-                                 ;/
        CMP.l $002140               ;\
        BNE -                     ;} Wait until APU IO 0 echoes
        INC A                     ; Increment index

; BRANCH_UPLOAD_DAT             
.uploadData
        REP #$20
        STA.l $002140               ; APU IO 0..1 = [index] [data]
        SEP #$20
        DEX                       ; Decrement X (block size)
        BNE .loopNextData                   ; If [X] != 0: go to LOOP_NEXT_DATA
-
        CMP.l $002140               ;\
        BNE -                     ;} Wait until APU IO 0 echoes

.ensureKick       
        ADC.b #$03                  ; Kick = [index] + 4
        BEQ .ensureKick                     ; Ensure kick != 0

; BRANCH_PROCESS_DATA_BLOCK
.processDataBlock
        PHA
        REP #$20
        LDA.w $0000,y               ;\
        JSR .incY2                ;} X = [[Y]] (block size)
        TAX                       ;} Y += 2
        LDA.w $0000,y               ;\
        JSR .incY2                 ;} APU IO 2..3 = [[Y]] (destination address)
        STA.l $002142               ;} Y += 2
        SEP #$20
        CPX.w #$0001                ;\
        LDA.b #$00                  ;|
        ROL A                     ;} If block size = 0: APU IO 1 = 0 (EOF), else APU IO 1 = 1 (arbitrary non-zero value)
        STA.l $002141               ;/
        ADC.b #$7F               ; Set overflow if block size != 0, else clear overflow
        PLA                    ;\
        STA.l $002140               ;} APU IO 0 = kick
        PHX
        LDX.w #$1000                ;\

-                                  ;|
        DEX                       ;} Wait until APU IO 0 echoes
        BEQ .ret                  ;} If exceeded 1000h attempts: return
        CMP.l $002140               ;|
        BNE -                     ;/
        
        PLX
        BVS .uploadDataBlock      ; If block size != 0: go to BRANCH_UPLOAD_DATA_BLOCK
        SEP #$20
        STZ.w $2141               
        STZ.w $2142               
        STZ.w $2143               
        PLP
        RTS
.ret
        SEP #$20
        STZ.w $2141
        STZ.w $2142
        STZ.w $2143
        PLX
        PLP
        RTS
}


;;; $8100: Increment Y twice, bank overflow check ;;;
.incY2
{
; Only increments Y once if overflows bank first time (which is a bug scenario)
        INY
        BEQ .next
}


;;; $8103: Increment Y, bank overflow check ;;;
.incY
{
        INY
        BEQ .next                 
        RTS
.next
        INC $02                   ; Increment $02
        PEI ($01)                 ;\
        PLB                    ;} DB = [$02]
        PLB                    ;/
        LDY.w #$8000             ; Y = 8000h
        RTS
}
