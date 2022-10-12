;; Program to demonstrate handling IRQ interrupts from the VIA chip

  .include "base.s"
  .org ORIGIN

;; 32 bit number, counting the number of ticks of 10ms since boot time
ticks = $0200
;; Value of the random number to display every 0x0f ticks
rando = $0210

main:

;; Init code taken from https://forums.atariage.com/topic/151841-init-of-the-pokey/
  ldx #8
  lda #0
  sta POKEY_SKCTL ; put Pokey into Init
clear:
  sta $8010,x ; clear all voices, set AUDCTL to 00
  dex
  bpl clear
  lda #3
  sta POKEY_SKCTL ; set skctl to normal value





  jsr init_timer
loop:
  ;; Jumps back to the beginning of the display
  lda #%00000010
  jsr lcd_instruction
  lda ticks + 3
  jsr lcd_print_hex
  lda ticks + 2
  jsr lcd_print_hex
  lda ticks + 1
  jsr lcd_print_hex
  lda ticks
  jsr lcd_print_hex
  lda #20 ; Space char
  jsr lcd_print_char
  lda rando
  jsr lcd_print_hex
  jmp loop


;; Initializes VIA timer to trigger every 10 ms
init_timer:
  ;; Initialize ticks to 0
  lda #0
  sta ticks
  sta ticks + 1
  sta ticks + 2
  sta ticks + 3
  ;; Set timer 1 to act an a continuously running interrupt
  lda #%01000000
  sta VIA_ACR
  lda #$0e
  sta VIA_T1CL
  lda #$27
  sta VIA_T1CH
  ;; Enable IRQ interrupts for timer 1
  lda #%11000000
  sta VIA_IER
  rts


;; Interrupt handler
irq:
  bit VIA_T1CL ; Clear the timer 1 interrupt bit
  inc ticks
  bne end_irq
  inc ticks + 1
  bne end_irq
  inc ticks + 2
  bne end_irq
  inc ticks + 3
end_irq:
  lda POKEY_RANDOM
  sta rando
  rti
