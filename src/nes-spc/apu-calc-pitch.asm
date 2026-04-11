t_lo        = $00
t_hi        = $01

blk_ptr_lo  = $02
blk_ptr_hi  = $03

seg_ptr_lo  = $04
seg_ptr_hi  = $05

p_out_lo    = $06
p_out_hi    = $07

tmp_lo      = $08
tmp_hi      = $09

; A = t_hi (contains bits 8–10)
MOV   A, t_hi
LSR   A          ; adjust shifts to match block count
LSR   A
AND   A, #$0F    ; block index 0–15
ASL   A          ; word index
mov x, a

MOV   A, pitchtables+X
MOV   blk_ptr_lo, A
MOV   A, pitchtables+1+X
MOV   blk_ptr_hi, A

mov y, #$00        ; entry index (0..7)

ScanLoop:
  ; load p_i
  MOV   A, [blk_ptr_lo]+Y
  MOV   tmp_lo, A
  inc y
  MOV   A, [blk_ptr_lo]+Y
  MOV   tmp_hi, A
  inc y

  ; compare tval against this segment boundary
  ; (comparison logic depends on how you mapped t→segment)
  ; assume monotonic mapping

  ; if tval < boundary → found
  CMP   t_hi, tmp_hi
  BCC   Found
  BEQ   CheckLow
  BRA   Next

CheckLow:
  CMP   t_lo, tmp_lo
  BCC   Found

Next:
  cmp y, #16       ; 8 entries × 2 bytes
  BNE   ScanLoop


Found:
  ; seg_ptr = &p_i
  MOV   seg_ptr_lo, blk_ptr_lo
  MOV   seg_ptr_hi, blk_ptr_hi
  mov a, y
  clrc : adc   a, seg_ptr_lo
  adc   seg_ptr_hi, #0

  ; load p_i
  MOV   A, [seg_ptr_lo]
  MOV   p_out_lo, A
  INC   seg_ptr_lo
  MOV   A, [seg_ptr_lo]
  MOV   p_out_hi, A

  ; load p_{i+1}
  INC   seg_ptr_lo
  MOV   A, [seg_ptr_lo]
  MOV   tmp_lo, A
  INC   seg_ptr_lo
  MOV   A, [seg_ptr_lo]
  MOV   tmp_hi, A


; delta_p = p_{i+1} - p_i
setc
MOV   A, tmp_lo
SBC   A, p_out_lo
MOV   tmp_lo, A
MOV   A, tmp_hi
SBC   A, p_out_hi
MOV   tmp_hi, A

; delta_t = tval - t_i (implicit)
; multiply delta_t * delta_p → tmp

CALL  MulSmallFixed   ; bounded small multiply

; p_out += result
clrc : adc   p_out_lo, tmp_lo
ADC   p_out_hi, tmp_hi
