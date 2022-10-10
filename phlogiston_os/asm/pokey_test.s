  .include "base.s"
  .org ORIGIN

main:
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda #','
  jsr lcd_print_char
  rts
