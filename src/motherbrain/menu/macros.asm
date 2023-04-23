
macro item_index_to_vram_index()
    ; Find screen position from Y (item number)
    TYA : ASL #5
    CLC : ADC #$0146 : TAX
endmacro

macro sfxmove()
    ;LDA #$0039 : JSL !SFX_LIB1 ; item select
endmacro

macro sfxconfirm()
    ;LDA #$0038 : JSL !SFX_LIB1 ; menu confirm
endmacro

macro sfxfail()
    ;LDA #$0007 : JSL !SFX_LIB1 ; grapple end
endmacro

macro sfxreset()
    ;LDA #$001E : JSL !SFX_LIB3 ; quake
endmacro
