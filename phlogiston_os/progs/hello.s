  .include "../os/base.s"
  .org $4000

main:
  jsr lcd_seek_begin
  lda #"H"
  jsr lcd_print_char
  lda #"e"
  jsr lcd_print_char
  lda #"l"
  jsr lcd_print_char
  lda #"l"
  jsr lcd_print_char
  lda #"o"
  jsr lcd_print_char
  lda #"!"
  jsr lcd_print_char

  jsr stop
