; This skips the intro
org $82eeda
    db $1f

; Hijack init routine to autosave and set door flags
org $828067
    jsl introskip_doorflags

org $80d000
introskip_doorflags:
    ; Do some checks to see that we're actually starting a new game
    JSL ConstructMapFromGameStart
    ; The first SM load uses the initial ship save as its rollback anchor.
    ; A non-empty marker prevents ordinary reloads from replacing it.
    jsl sm_portal_checkpoint_create_initial
    lda #$0000
    rtl

warnpc $80D200
