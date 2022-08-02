  .include "base.s"
  .org ORIGIN

main:
  lda #"f"
  jsr lcd_print_char
  lda #"i"
  jsr lcd_print_char
  lda #"b"
  jsr lcd_print_char
  lda #"("
  jsr lcd_print_char
  lda VIA_PORTA
  and #$0f
  pha
  jsr lcd_print_hex_nibble
  lda #")"
  jsr lcd_print_char
  lda #"="
  jsr lcd_print_char

  ;; Iterative fibonacci
  pla
  pha
  jsr fib_itr
  jsr lcd_print_hex

  lda #" "
  jsr lcd_print_char
  lda #"{"
  jsr lcd_print_char

  ;; Recursive fibonacci
  pla
  jsr fib_rec
  jsr lcd_print_hex

  lda #"}"
  jsr lcd_print_char
  rts


  ;; Iterative fibonacci function.
  ;; Expects register A as the input. Returns via register A
  ;; Undefined behavior for $e and $f
  ;; Uses zero page addresses $0000-$0001
fib_itr:
  ;; General case
  tay       ; Store the current n value at register Y, safe and warm
  ;; Initially, $0000-$0001 = [0,1] = [n, n+1]
  ldx #0
  stx $0000 ; current number
  inx
  stx $0001 ; 1 number in the future
fib_loop:
  ;; Condition check: Have we iterated all the way through N yet?
  tya
  cmp #0
  beq fib_itr_end
  dey
  ;; Arithmetic fun
  lda $0000
  clc
  adc $0001
  tax       ; Transfer result to register X as a temporary
  lda $0001 ; Move $0001 to $0000, aka n+1 to n
  sta $0000
  stx $0001 ; Move result (n+2) to n+1
  jmp fib_loop
fib_itr_end:
  lda $0000 ; Return result
  rts


  ;; Recursive fibonacci function.
  ;; Expects register A as the input. Returns via register A.
  ;; Undefined behavior for $e and $f
fib_rec:
  cmp #2
  bmi fib_rec_end ; For the base case, fib(0)=0 and fib(1)=1
  ;; 1) fib(N-1)
  ;; SBC does the 1s compliment, add, then add borrow.
  ;; So we must set the carry bit to subtract 1 (to perform 2s compliment)
  sec
  sbc #1
  pha         ; Store N-1 on the stack
  jsr fib_rec
  ;; 2) Pull N-1 of the stack, push fib(N-1) to the stack
  tax ; X   = fib(N-1)
  pla ; A   = N-1
  tay ; Y   = N-1
  txa ; A   = fib(N-1)
  pha ; *SP = fib(N-1)
  ;; 3) Set Y = N-2, transfer to A
  dey ; Y = N-2
  tya ; A = N-2
  ;; 4) A = fib(N-2), STACK_ORG,(SP+1) = fib(N-1)
  jsr fib_rec ; A = fib(N-2)
  tsx
  inx
  clc
  adc STACK_ORG,x ; Add from the stack memory, avoiding the zero page
  txs
fib_rec_end:
  rts
