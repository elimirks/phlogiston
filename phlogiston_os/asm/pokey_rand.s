; Program to demonstrate initializing and accessing the POKEY RANDOM register

  .include "base.s"
  .org ORIGIN

main:
  ; Read in and display some random numbers
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  lda POKEY_RANDOM
  jsr lcd_print_hex
  rts


irq:
  rti
