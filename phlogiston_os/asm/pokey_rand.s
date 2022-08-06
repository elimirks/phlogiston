; Program to demonstrate initializing and accessing the POKEY RANDOM register

  .include "base.s"
  .org ORIGIN

main:
  ; Read in and display a random number
  lda POKEY_RANDOM
  jsr lcd_print_hex
  rts


irq:
  rti
