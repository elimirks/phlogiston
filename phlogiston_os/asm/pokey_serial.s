; Program to test out serial output for the POKEY chip
; Atari 800XL wiring diagram for help:
; https://systemembedded.eu/download/file.php?id=172&sid=0ad25e106c4c5b0b8739cf29a67e8601&mode=view
; TLDR: on all pins ACLK,BCLK,SID,SOD
; - 4.7k pullups to +5V
; - 100 ohm to outputs

; I'm only using the bidirectional clock, so that the Arduino can fully control
; when to recieve and transmit data.

  .include "base.s"
  .org ORIGIN

; Only enable serial input data ready interrupt
INT_MASK = %00100000

; Number to display & ping-pong
num = $0200
; Condition to decide if we should update the screen & send a new byte
should_update = $0201

main:
  lda #INT_MASK
  sta POKEY_IRQEN
  lda #0
  sta num
  lda #1
  sta should_update

begin:
  lda #1
  cmp should_update
  bne begin

  lda num
  sta POKEY_SEROUT ; So it begins...
  lda #0
  sta should_update

  ;; Jumps back to the beginning of the display
  lda #%00000010
  jsr lcd_instruction

  lda num
  jsr lcd_print_hex
  jmp begin

  rts


  ;http://6502.org/tutorials/interrupts.html
irq:
  pha
  ; TODO: Check IRQST to make sure it's actually the right interrupt
  lda POKEY_SERIN
  sta num

  lda #0
  sta POKEY_IRQEN
  lda #INT_MASK
  sta POKEY_IRQEN

  lda #1
  sta should_update

  pla
  rti
