    .include "../os/base.s"
    .org RAM_PROG_ORG
    .word main
    .word stop

main:
    ldx #0
    stx $00
print:
    ldx $00
    lda message,x
    beq print_end
    jsr lcd_print_char
    inc $00
    jmp print
print_end:
    jsr stop


message: .data "Hello, world!", 0
