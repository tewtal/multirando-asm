;  Rom patches for bugfixes and quality of life improvements

!B0 = ((!BASE_BANK)<<16)
!B1 = ((!BASE_BANK+$1)<<16)
!B5 = ((!BASE_BANK+$5)<<16)
!B7 = ((!BASE_BANK+$7)<<16)

;  Fast npc text
org !B1+$881d
db $02


;  Z3-speed faster heart refills
; $B1E6 [World_FillHearts]:  [original code from z1 disassembly]
; 171E6  A5 63          LDA $63
; 171E8  F0 29          BEQ $B213
; 171EA  A9 10          LDA #$10
; 171EC  8D 04 06       STA $0604
; 171EF  AD 70 06       LDA $0670
; 171F2  C9 F8          CMP #$F8    ;  Changing #$F8 to #$eb
; 171F4  B0 07          BCS $B1FD
; 171F6  18             CLC
; 171F7  69 06          ADC #$06    ;  Changing #$06 to #$14
; 171F9  8D 70 06       STA $0670
; 171FC  60             RTS
org !B5+$b1f3
db $eb
org !B5+$b1f8
db $14