  .include "base.s"
  .org ORIGIN

main:
  ;; Print message!
  ldx #0
print:
  txa
  pha
  lda message,x
  beq print_end
  jsr lcd_print_char
  pla
  tax
  inx
  jmp print
print_end:
  pla

  rts


  ;; i8\sum\pi :)
message: .data "i8", %11110110, %11110111, " ", %11000010, 0
