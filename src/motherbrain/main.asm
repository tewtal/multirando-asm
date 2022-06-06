namespace mb

sa1rom 0,0,0,7      ; Set boot configuration
incsrc "boot.asm"

sa1rom 0,0,0,7      ; Set main configuration
org $FF8000
namespace off
incsrc "../nes-spc/spc.asm"

namespace mb
org $FFE000
base $40E000
incsrc "snes.asm"
incsrc "sa1.asm"
incsrc "credits.asm"
namespace off
