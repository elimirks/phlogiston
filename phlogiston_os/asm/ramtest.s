  ;; This program tests the RAM chip by writing and reading everywhere.
  ;; As such, it can't use the stack (functions) or the zero page.

MEMOFFSET = $0000               ; Offset to start testing at
MEMLEN    = $10                 ; Amount of memory to test. At most $ff!
PORTB     = $6000
DDRB      = $6002

  .org $8000

reset:
  lda #%11111111                ; Set all pins on port B to output 
  sta DDRB


  ;; Write the addresses
  ldx #0                        ; We'll use X for the RAM pointer offset
writeloop:
  ;; Store the memory address in the memory slot
  txa
  sta MEMOFFSET,x               ; 8009
  ;; Increment and loop
  inx
  cpx #MEMLEN                   ; 800b
  bne writeloop


  ;; Read the address of every m
  ldx #0                        ; 800d
  ;; Indicate that we're done with the write loop
  lda #%00000001
  sta PORTB
readloop:
  ;; Fail if it's not as expected
  txa
  cmp MEMOFFSET,x
  bne failure
  ;; Increment and loop
  inx
  cpx #MEMLEN
  bne readloop


  ;; Success!
  lda #42
  sta PORTB
successloop:
  jmp successloop


failure:
  lda #13
  sta PORTB
failloop:
  jmp failloop
  

  .org $fffc
  .word reset
  .word $0000
