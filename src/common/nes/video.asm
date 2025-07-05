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