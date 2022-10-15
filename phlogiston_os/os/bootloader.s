; TODO: Require specifying main function & IRQ addrs at beginning of file

; Program to load in and display an ASCII message
; The loading is null terminated

  .include "base.s"
  .org $8000 ; Necessary to fill up the entire 32K
  .org ORIGIN

; Only enable serial input data ready interrupt
INT_MASK = %00100000

; Base address to load to
load_base = RAM_PROG_ORG
; Address of where we load the size to expect
; This is actually where we start writing serial data
; Since the Arduino begins with sending the size bytes
load_size = load_base-2
; Indicates to the IRQ handler if we should jump to the app IRQ handler
mem_irq_flag = load_base-3

ram_prog_main_ptr = load_base
ram_prog_irq_ptr  = load_base+2

; Use zero page 00 & 01 to point to the last byte of data
; NOTE: Initially it's indexed before the first byte
load_ptr = $00
poke_byte = $42


bootloader_main:
    ; Initialize the stack pointer
    ; Remember, it grows down. So if you push a byte to the stack, SP := SP-1
    ; SP is the index of the NEXT stack element to push, not the most recent
    ldx #$ff
    txs
    jsr reset

    ; Set up interrupts for recieving data
    lda #INT_MASK
    sta POKEY_IRQEN

    ; Start the pointer at 3ffd, to write the program size first
    lda #<load_size-1
    sta load_ptr
    lda #>load_size
    sta load_ptr+1
    ; Zero out the size initially so we can tell when the upload has started
    lda #0
    sta load_size
    sta load_size+1
    sta mem_irq_flag

    jsr load_serial_data
    jsr lcd_clear
    lda #1
    sta mem_irq_flag
    jmp (ram_prog_main_ptr)


;; Expects to read a null terminated string over serial.
;; Loads a max of 255 characters into memory.
load_serial_data:
    ; Poke serial out to tell Arduino to begin transmission
    lda #poke_byte
    sta POKEY_SEROUT
    ; Spin until data is ready
load_serial_data_spin:
    jsr lcd_seek_begin
    ; Display current pointer and expected size
    lda load_ptr+1
    jsr lcd_print_hex
    lda load_ptr
    jsr lcd_print_hex
    lda #'('
    jsr lcd_print_char
    lda load_size+1
    jsr lcd_print_hex
    lda load_size
    jsr lcd_print_hex
    lda #')'
    jsr lcd_print_char
    ; Check if the load ptr is below $3fff
    lda load_ptr+1
    cmp #$3f
    bmi load_serial_data_spin
    ; For debugging
    lda load_size+1
    clc
    adc #$40
    jsr lcd_print_hex
    lda load_size
    jsr lcd_print_hex
    ; Calculate where to expect the pointer to end
    lda load_size+1 ; MSB of size
    clc
    adc #$40  ; To align with pointer offset
    tax
    ldy load_size ; LSB of size
    dey       ; To align with pointer offset
    ; Check if MSB of ptr is where it should be
    cpx load_ptr+1
    bne load_serial_data_spin
    ; Check if LSB of ptr is where it should be
    cpy load_ptr
    bne load_serial_data_spin
    ; If all the above checks failed, it means we're done!
    lda #'!'
    jsr lcd_print_char
    rts


bootloader_irq:
    pha
    ; Check if we should jump to the memory IRQ handler
    ; NOTE: This can be done more efficiently...
    ; ...but it's good enough for now!
    lda #0
    cmp mem_irq_flag
    beq .1
    pla
    jmp (ram_prog_irq_ptr)
.1: txa
    pha
    ; Increment load pointer
    inc load_ptr
    bne .2
    inc load_ptr+1
    ; TODO: Fail condition when we overflow the MSB!
    ; Push to the data array
.2: lda POKEY_SERIN
    ldx #0
    sta (load_ptr,x) ; It's a real shame there's no zero page indirect mode...
    ; Reset the interrupt
    lda #0
    sta POKEY_IRQEN
    lda #INT_MASK
    sta POKEY_IRQEN

    pla
    tax
    pla
    rti


    .org $fffc
    .word bootloader_main
    .word bootloader_irq
