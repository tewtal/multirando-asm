pushpc

; Skip drawing the intro display logo
org $8cc17c
    nop #3

; Hook code that runs right after memory initialization to jump directly to the
; file select menu.
org $8cc302    
    jml $8CC2B6
    
; This is an address in a jump table that stumbles 
; through a bunch of drawing and animation for the file
; select screen. This just copies the last address to
; the first index, so it doesn't bother with any of the
; presentation and just jumps straight to the logic.
org $8ccc7a
    dl $8CCDC6

; file select screen
org $8cce2a
    jmp $ce5c ; jump straight to "action" button handler, loading the save

pullpc
