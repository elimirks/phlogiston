; TODO: Require specifying main function & IRQ addrs at beginning of file

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


  ; Start the pointer at 3ffd, to write the program size first
  lda #$fd
  sta $00
  lda #$3f
  sta $01
  ; Zero out the size initially so we can tell when the upload has started
  lda #0
  sta $3ffe
  sta $3fff

  jsr load_serial_data
  jmp $4000


;; Expects to read a null terminated string over serial.
;; Loads a max of 255 characters into memory.
load_serial_data:
  ; Poke serial out to tell Arduino to begin transmission
  lda #$42
  sta POKEY_SEROUT
  ; Spin until data is ready
load_serial_data_spin:
  jsr lcd_seek_begin
  ; Display current pointer and expected size
  lda $01
  jsr lcd_print_hex
  lda $00
  jsr lcd_print_hex
  lda #'('
  jsr lcd_print_char
  lda $3fff
  jsr lcd_print_hex
  lda $3ffe
  jsr lcd_print_hex
  lda #')'
  jsr lcd_print_char
  ; Check if the load ptr is below $3fff
  lda $01
  cmp #$3f
  bmi load_serial_data_spin
  ; For debugging
  lda $3fff
  clc
  adc #$40
  jsr lcd_print_hex
  lda $3ffe
  jsr lcd_print_hex
  ; Calculate where to expect the pointer to end
  lda $3fff ; MSB of size
  clc
  adc #$40  ; To align with pointer offset
  tax
  ldy $3ffe ; LSB of size
  dey       ; To align with pointer offset
  ; Check if MSB of ptr is where it should be
  cpx $01
  bne load_serial_data_spin
  ; Check if LSB of ptr is where it should be
  cpy $00
  bne load_serial_data_spin
  ; If all the above checks failed, it means we're done!
  lda #'!'
  jsr lcd_print_char
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
