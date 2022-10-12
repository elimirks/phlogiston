; Program to load in and display an ASCII message
; The loading is null terminated

  .include "base.s"
  .org ORIGIN

; Only enable serial input data ready interrupt
INT_MASK = %00100000

; Base address to load to
load_base = $4000

; Use zero page 00 & 01 to point to the last byte of data
; NOTE: Initially it's indexed before the first byte
load_ptr = $00


main:
  ; Set up interrupts for recieving data
  lda #INT_MASK
  sta POKEY_IRQEN

  ; TODO: No magic numbers!
  lda #$ff
  sta $00
  lda #$3f
  sta $01

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
  ; Display current pointer
  lda $01
  jsr lcd_print_hex
  lda $00
  jsr lcd_print_hex
  ; Check if the load ptr is below $3fff
  lda $01
  cmp #$3f
  bmi load_serial_data_spin
  ; Check if the final byte is a null byte
  ldx #0
  lda ($00,x)
  cmp #0
  bne load_serial_data_spin

  rts


irq:
  pha
  txa
  pha
  ; Increment load pointer
  inc $00
  bne _irq_load_ptr_inc_end
  inc $01
  ; TODO: Fail condition when we overflow the MSB!
_irq_load_ptr_inc_end:
  ; Push to the data array
  lda POKEY_SERIN
  ldx #0
  sta ($00,x) ; It's a real shame there's no zero page indirect mode...
  ; Reset the interrupt
  lda #0
  sta POKEY_IRQEN
  lda #INT_MASK
  sta POKEY_IRQEN

  pla
  tax
  pla
  rti
