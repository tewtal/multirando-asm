CountTriforcePieces:
    lda.w InvTriforce
    ldy #$00
-
    lsr
    bcc +
    iny
+
    bne -

    ; After this is a "BCC @Exit",
    tya
    cmp.l config_triforce
    rtl