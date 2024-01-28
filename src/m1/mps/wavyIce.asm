; SOME CODE HAD TO BE MOVED TO MapHack.asm to be included into RAM



;===========================================
; Allow weapon combining
; ----- ------ ---------
; NOPs out the code that removes one beam
; when the play aquires another.
;===========================================
.PATCH 0F:DBD2

        NOP ; LDA $6878
        NOP
        NOP

        NOP ; AND #$3F
        NOP

        NOP ; STA $6878
        NOP
        NOP
        
        
;===========================================
; New Behavior
; --- --------
; Calls the appropriate routine to update
; beam projectiles.
;===========================================

; Hijack
; ------
.PATCH 0F:D5C5
        JMP WavyIce_NewBehavior

; New code
; --- ----
; (in MapHack.asm)



;===========================================
; New Damage
; --- ------
; Specifies damage amount for wave+ice. Also
; increases damage dealt by bombs and
; vanilla ice. Heh.
;===========================================

; Hijack
; ------
.PATCH 0F:F5EE
        JMP WavyIce_NewDamage

; New Code
; --- ----
; (in MapHack.asm)
