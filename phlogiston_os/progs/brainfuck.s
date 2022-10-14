    .include "../os/base.s"
    .org $4000

stack_ptr = $00
prog_ptr  = $02

main:
    ; Start the prog pointer after the initial null byte
    lda #<bfprog
    sta $02
    lda #>bfprog
    sta $03
    jsr inc_prog_ptr
    jsr init_stack
repl:
    ldx #0
    lda (prog_ptr,x)
    beq end_main ; Null terminate the program
    ;;;;;;;;;;;;;;;;;;;;
    ;; Increment Data ;;
    ;;;;;;;;;;;;;;;;;;;;
    cmp #"+"
    bne inc_dat_end
    lda (stack_ptr,x)
    clc
    adc #1
    sta (stack_ptr,x)
    jmp end_switch
inc_dat_end:
    ;;;;;;;;;;;;;;;;;;;;
    ;; Decrement Data ;;
    ;;;;;;;;;;;;;;;;;;;;
    cmp #"-"
    bne dec_dat_end
    lda (stack_ptr,x)
    sec
    sbc #1
    sta (stack_ptr,x)
    jmp end_switch
dec_dat_end:
    ;;;;;;;;;;;
    ;; Print ;;
    ;;;;;;;;;;;
    cmp #"."
    bne print_end
    lda (stack_ptr,x)
    jsr lcd_print_char
    jmp end_switch
print_end:
    ;;;;;;;;;;;;;;;;;;;;;;;
    ;; Increment Pointer ;;
    ;;;;;;;;;;;;;;;;;;;;;;;
    cmp #">"
    bne inc_ptr_end
    inc stack_ptr
    bne .1
    inc stack_ptr+1
    ; TODO Check for stack overflow
.1: jmp end_switch
inc_ptr_end:
    ;;;;;;;;;;;;;;;;;;;;;;;
    ;; Decrement Pointer ;;
    ;;;;;;;;;;;;;;;;;;;;;;;
    cmp #"<"
    bne dec_ptr_end
    lda stack_ptr
    bne .1
    dec stack_ptr+1
.1: dec stack_ptr
    ; TODO Check for stack underflow
    jmp end_switch
dec_ptr_end:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Seek Forward Operator ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp #"["
    bne seek_forward_end
    ldx #0
    lda (stack_ptr,x)
    cmp #0
    bne .1
    jsr seek_to_end_paren
.1: jmp end_switch
seek_forward_end:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Seek Backward Operator ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    cmp #"]"
    bne seek_backward_end
    ldx #0
    lda (stack_ptr,x)
    cmp #0
    beq .1
    jsr seek_to_begin_paren
.1: jmp end_switch
seek_backward_end:
    ; End of switch statement. Any other characters are ignored
end_switch:
    jsr inc_prog_ptr
    jmp repl
end_main:
    jmp stop


  ; Seeks the prog pointer to the end of a `[` operator
  ; i.e., the matching `]` operator
  ; The prog pointer will end up pointing to that character
  ; Assumes we're already on a `]` character, so starts off by seeking once
seek_to_end_paren:
    ; TODO: Check for boundary conditions
    jsr inc_prog_ptr
    ldx #0
    lda (prog_ptr,x)
    cmp #"["
    bne .1
    jsr seek_to_end_paren
    jmp seek_to_end_paren
.1: cmp #"]"
    bne seek_to_end_paren
    rts


seek_to_begin_paren:
    ; TODO: Check for boundary conditions
    jsr dec_prog_ptr
    ldx #0
    lda (prog_ptr,x)
    cmp #"]"
    bne .1
    jsr seek_to_begin_paren
    jmp seek_to_begin_paren
.1: cmp #"["
    bne seek_to_begin_paren
    rts



  ; Initialize stack pointer (address 00-01) to point at $0200
  ; it will stop zeroing out at $1000, so that's the effective stack range
init_stack:
    jsr init_stack_ptr
    ; Zero out the BF stack
    ldx #0
init_stack_zero_loop:
    lda #0
    sta (stack_ptr,x)
    inc stack_ptr
    bne .1
    inc stack_ptr+1
.1: lda stack_ptr+1
    cmp #$10
    bne init_stack_zero_loop
  ; Fall through to reset a second time
init_stack_ptr:
  ; Reset the stack back to $0200
  lda #$02
  sta stack_ptr+1
  lda #$00
  sta stack_ptr
  rts


inc_prog_ptr;
    inc prog_ptr
    bne .1
    inc prog_ptr+1
.1: rts


dec_prog_ptr;
    lda prog_ptr
    bne .1
    dec prog_ptr+1
.1: dec prog_ptr
    rts


  ; BF programs must be null terminated and initiated
  ; Null initiation is so that we can easily figure out when we hit the
  ; beginning of a program via a seek with the `]` operator
  ; Change this value to select which brainfuck program to run
bfprog = bf_hello

bf_test_stack_ptr_inc_dec: .data 0
; Expect to print the bytes 0102030201
.1: .data "+.>++.>+-+++.<.<.", 0

bf_test_condition: .data 0
; Expect to print the bytes 0300
.1: .data "[+]+++. [-].", 0

  ; Program to print out "h"
bf_h: .data 0
.1: .data "[++]+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
.2: .data "+++++++++++.", 0


bf_hello: .data 0
.1: .data "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++"
.2: .data "..+++.>>.<-.<.+++.------.--------.>>+.", 0
