;  Common video routines shared by the nes games

print "nes/video.asm start: ", pc
;  Initialize the SNES OAM buffer in wram to a known, blank state
initOAMBuffer:
  php
  REP #$30
  LDA #$F0F0
  LDX #$0000

  -
  STA $7E2000, X
  INX #4
  CPX #$0200
  BNE -
  plp
rtl


;  Create a black palette entry outside of $x0 that doesn't conflict
;  with other palette indexes used by nes games.
;  Currently used in z1 for a custom priority background tile.
initSpecialPaletteEntry:
  !specialPaletteIndex = #$71

  php

  %a8()
  lda !specialPaletteIndex
  sta $002121

  lda #$00      ;
  sta $002122   ;
  sta $002122   ;  Pure black
  plp
rtl