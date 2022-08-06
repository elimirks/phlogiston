; This is the base include file for your 6502 programs.
; It sets up all necessary functionality including the LCD.
; You _must_ define a `main` label in your program, which returns with rts.
; You must also define an `irq` label, which returns with rti.
; In short, you can define the simplest program as follows, which will
; initialize then return here to spin ad infinitum:
; ```
;    .include "base.s"
;    .org ORIGIN
;  main:
;    rts
;  irq:
;    rti
; ```
; ... but that's no fun!

; VIA chip Enable, Read/Write, and Register Select pins
; https://eater.net/datasheets/w65c22.pdf
VIA_PORTB = $8000     ; I/O data register B
VIA_PORTA = $8001     ; I/O data register A
VIA_DDRB  = $8002     ; Data direction register B
VIA_DDRA  = $8003     ; Data direction register A
VIA_T1CL  = $8004     ; Timer 1 counter low
VIA_T1CH  = $8005     ; Timer 1 counter high
VIA_ACR   = $800b     ; Auxiliary control register
VIA_IFR   = $800d     ; Interrupt flag register
VIA_IER   = $800e     ; Interrupt enable register
VIA_E     = %00001000 ; Enable pin
VIA_RW    = %00000100 ; Read/Write pin
VIA_RS    = %00000010 ; Register Select pin

; http://krap.pl/mirrorz/atari/homepage.ntlworld.com/kryten_droid/Atari/800XL/atari_hw/pokey.htm
; POKEY READ addresses
POKEY_POT0   = $8010
POKEY_POT1   = $8011
POKEY_POT2   = $8012
POKEY_POT3   = $8013
POKEY_POT4   = $8014
POKEY_POT5   = $8015
POKEY_POT6   = $8016
POKEY_POT7   = $8017
POKEY_ALLPOT = $8018
POKEY_RANDOM = $801a ; Read for a random number
POKEY_IRQST  = $801e 
; POKEY WRITE addresses
POKEY_AUDF1  = $8010
POKEY_AUDC1  = $8011
POKEY_AUDF2  = $8012
POKEY_AUDC2  = $8013
POKEY_AUDF3  = $8014
POKEY_AUDC3  = $8015
POKEY_AUDF4  = $8016
POKEY_AUDC4  = $8017
POKEY_AUDCTL = $8018
POKEY_STIMER = $8019
POKEY_POTGO  = $801b
POKEY_IRQEN  = $801e  ; IRQ Enable address
POKEY_SKCTL  = $801f

ORIGIN    = $c000     ; EEPROM origin
STACK_ORG = $0100     ; Program stack origin

  .org $8000 ; Necessary to fill up the entire 32K
  .org ORIGIN


_base_reset:
  ; Initialize the stack pointer
  ; Remember, it grows down. So if you push a byte to the stack, SP := SP-1
  ; SP is the index of the NEXT stack element to push, not the most recent
  ldx #$ff
  txs

  ; Initialize POKEY
  ; @see page 20 the datasheet for details
  lda $0
  sta POKEY_SKCTL
  ; Disable all POKEY interrupts initially
  lda #0
  sta POKEY_IRQEN

  ; Clear interrupt inhibit to enable CPU interrupts
  cli

  ; Set up port A for outputs on the high bits, inputs on the low bits
  ; For now, the high bits are connected to 4 LEDs
  ; The low bits are connected to switches
  lda #%11110000
  sta VIA_DDRA

  jsr _base_lcd_init
  ; Turn on display and cursor
  lda #%00001100
  jsr lcd_instruction
  ; Character entry mode set
  lda #%00000110
  jsr lcd_instruction

  jsr main


_base_eofspin:
  jmp _base_eofspin


_base_lcd_init:
  ; Set data direction to all outputs for I/O register B
  lda #%11111111
  sta VIA_DDRB
  ; Set 4-bit operation mode
  jsr _base_lcd_wait
  lda #%00100000
  sta VIA_PORTB
  ora #VIA_E
  sta VIA_PORTB
  and #(~VIA_E)
  sta VIA_PORTB
  ; Set 4-bit 2-row mode
  lda #%00101000
  jsr lcd_instruction
  ; Clear display
  lda #%00000001
  jsr lcd_instruction
  rts


  ; Only uses the A and Y registers
_base_lcd_wait:
  lda #%00001111
  sta VIA_DDRB
_base_lcd_wait_busy:
  lda #VIA_RW
  sta VIA_PORTB
  lda #(VIA_RW | VIA_E)
  sta VIA_PORTB
  ldy VIA_PORTB
  ; Ignore the second nibble
  lda #VIA_RW
  sta VIA_PORTB
  lda #(VIA_RW | VIA_E)
  sta VIA_PORTB
  ; Check if the busy flag is set
  tya
  and #%10000000
  bne _base_lcd_wait_busy

  lda #VIA_RW
  sta VIA_PORTB
  lda #%11111111  ; Set port B to all output
  sta VIA_DDRB
  rts


  ; The A register is the instruction parameter
lcd_instruction:
  ; Wait for the busy flag
  tax
  jsr _base_lcd_wait
  ; Send MSB
  txa
  and #%11110000 ; Clear RS/RW/E bits
  sta VIA_PORTB
  ora #VIA_E     ; Set E bit to send instruction
  sta VIA_PORTB
  and #(~VIA_E)
  sta VIA_PORTB
  txa
  ; Send LSB
  rol
  rol
  rol
  rol
  and #%11110000
  sta VIA_PORTB
  ora #VIA_E
  sta VIA_PORTB
  and #(~VIA_E)
  sta VIA_PORTB
  rts


  ; The A register is the data character parameter
lcd_print_char:
  ; Wait for the busy flag
  tax
  jsr _base_lcd_wait
  ; Send MSB
  txa
  and #%11110000                ; Clear RS/RW/E bits
  sta VIA_PORTB
  ora #(VIA_RS | VIA_E)         ; Set E bit and RS to send data
  sta VIA_PORTB
  and #(~(VIA_RS | VIA_E))
  sta VIA_PORTB
  txa
  ; Send LSB
  rol
  rol
  rol
  rol
  and #%11110000
  sta VIA_PORTB
  ora #(VIA_RS | VIA_E)
  sta VIA_PORTB
  and #(~(VIA_RS | VIA_E))
  sta VIA_PORTB
  rts


  ; The A register is the value to print in hex
  ; Always outputs 2 characters
lcd_print_hex:
  ; TODO: Translate into hex characters.. one nibble at a time!
  pha
  ror
  ror
  ror
  ror
  jsr lcd_print_hex_nibble
  pla
  jmp lcd_print_hex_nibble ; No need to jsr here, we want to return after anyways
lcd_print_hex_nibble:
  and #$0f
  cmp #$a
  bpl _lcd_print_hex_over_10

  clc
  adc #"0"
  jsr lcd_print_char
  rts
_lcd_print_hex_over_10:
  clc
  adc #("A" - 10)
  jsr lcd_print_char
  rts


  .org $fffc
  .word _base_reset
  .word irq
