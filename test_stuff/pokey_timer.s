; Program to demonstrate handling IRQ interrupts from the POKEY chip

  .include "base.s"
  .org ORIGIN

; 32 bit number, counting the number of ticks of 10ms since boot time
ticks = $0200

main:
  jsr init_timer

  lda #$00
  sta POKEY_AUDCTL
  ; Set frequency to $79
  lda #$79
  sta POKEY_AUDF1
  ; Set to pure tone (a) and full volume (f)
  lda #$af ;f: V = .29
  ;lda #$ae ;f: V = .28
  ;lda #$ad ;f: V = .04
  ;lda #$aa ;f: V = ?
  ;lda #$a0 ;f: V = ?
  sta POKEY_AUDC1

loop:
  ; Jumps back to the beginning of the display
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
  jmp loop
  rts

; TODO: Test the interrupt signal line. If you can get it to turn on via IRQEN,
; that's a good sign the POKEY is reacting to write signals after all.

; Initalize T1 to "middle C"
; (it's actually inaccurate because of clock issue mentioned in README.md)
init_timer:
  lda #0
  sta ticks
  sta ticks + 1
  sta ticks + 2
  sta ticks + 3

  ; Enable interrupts for POKEY timer 1
  ;lda #%00000001
  ;sta POKEY_IRQEN

  ; sta POKEY_STIMER ; Strobe STIMER (this might not do anything)
  ; ; Set frequency to $79
  ; lda #$79
  ; sta POKEY_AUDF1
  ; ; Set to pure tone (a) and full volume (f)
  ; lda #$af
  ; sta POKEY_AUDC1

  rts


; Interrupt handler
irq:
; Testing if we even enter the IRQ handler by spinning forever
; If so, the IRQ indicator should stay dim
spin:
  jmp spin

  ; TODO: Clear the timer 1 interrupt bit
  inc ticks
  bne end_irq
  inc ticks + 1
  bne end_irq
  inc ticks + 2
  bne end_irq
  inc ticks + 3
end_irq:
  rti

