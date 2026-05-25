;  Shared macros for nes games

if not(defined("UPLOAD_DIRECTORY_ENTRY_MACRO"))
!UPLOAD_DIRECTORY_ENTRY_MACRO = 1

; Send 2 copies of a 16-bit ARAM address to audio RAM
macro uploadDirectoryEntry(entry)
    rep #$30
    lda #<entry>
    sep #$20
    jsr spc_upload_byte
    xba
    jsr spc_upload_byte
    rep #$30
    lda #<entry>
    sep #$20
    jsr spc_upload_byte
    xba
    jsr spc_upload_byte
endmacro

endif