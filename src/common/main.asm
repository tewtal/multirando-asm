; Common code/data that's always mapped in for a set of games or other things

; Common NES code/data
sa1rom 0,0,6,7
namespace nes
org $9F8000
incsrc "nes/overlay.asm"
print "nes/overlay.asm end: ", pc
incsrc "nes/video.asm"
warnpc $9FFFFF

; FB0000-FB7FFFF (free)
; Align data to $8000 to match pointers
org $FB8000
incsrc "nes/data.asm"
incsrc "nes/items.asm"
print "nes/items.asm end: ", pc
warnpc $FC0000
