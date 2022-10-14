  .include "../os/base.s"
  .org $4000

main:
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
  jsr stop


message: .data "Hello, world!", 0
