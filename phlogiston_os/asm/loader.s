;TODO: Allow loading more than 255 bytes. It should support
;4000-7fff (16kB)

; Program to load in and display an ASCII message
; The loading is null terminated

  .include "base.s"
  .org ORIGIN

; Only enable serial input data ready interrupt
INT_MASK = %00100000

; Base address to load to
load_base = $4000
; Store size of the data that's been loaded
load_size = $0200

main:
  ; Set up interrupts for recieving data
  lda #INT_MASK
  sta POKEY_IRQEN

  lda #0
  sta load_size
  jsr load_serial_data

  jsr lcd_seek_begin
  ;; Print message!
  ldx #0
print:
  txa
  pha
  lda load_base,x
  beq print_end
  jsr lcd_print_char
  pla
  tax
  inx
  jmp print
print_end:
  pla
  rts


;; Expects to read a null terminated string over serial.
;; Loads a max of 255 characters into memory.
load_serial_data:
  ; Poke serial out to tell Arduino to begin transmission
  lda #$42
  sta POKEY_SEROUT

  ; Spin until data is ready
load_serial_data_spin:
  jsr lcd_seek_begin
  lda load_size
  jsr lcd_print_hex

  ; If we don't have any data yet, keep spinning!
  lda load_size
  cmp #0
  beq load_serial_data_spin
  ; Then, check for a terminal null byte
  tax
  dex
  lda load_base,x
  cmp #0
  bne load_serial_data_spin
  rts


irq:
  pha
  txa
  pha

  ; Push to the data array
  lda POKEY_SERIN
  ldx load_size
  sta load_base,x
  inc load_size

  ; Reset the interrupt
  lda #0
  sta POKEY_IRQEN
  lda #INT_MASK
  sta POKEY_IRQEN

  pla
  tax
  pla
  rti
