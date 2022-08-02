  .include "base.s"
  .org ORIGIN

main:
  sta POKEY_POTGO ; Begin probe
loop:
  lda POKEY_POT1
  ;lda VIA_PORTA
  ;and #$0f
  jsr lcd_print_hex
  ;; Jumps back to the beginning of the display
  lda #%00000010
  jsr lcd_instruction
  jmp loop
  rts
