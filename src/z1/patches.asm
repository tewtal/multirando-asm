;  Rom patches for bugfixes and quality of life improvements

!B0 = ((!BASE_BANK)<<16)
!B1 = ((!BASE_BANK+$1)<<16)
!B7 = ((!BASE_BANK+$7)<<16)

;  Fast npc text
;;org !B1+$481d
org !B1+$881d
;arch 6502
db $02