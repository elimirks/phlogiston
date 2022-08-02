  ;; This program will cause the PBx pins in the I/O chip to rotate
  
  .org $8000                    ; Set the program origin to $8000, our starting
                                ; program address
reset:
  ;; Set the data direction of register B to all outputs
  ;; #$ff is the bitmask: each set bit indicates that pin should be an output
  lda #$ff
  sta $6002

  lda #$50                      ; Put the hex value 50 in register A.
  sta $6000                     ; Move register A to I/O register B.

loop:
  ror                           ; Rotate register A right.
  sta $6000                     ; Move register A to I/O register B.
  jmp loop                      ; Ad infinitum!

  .org $fffc                    ; As per the README, this address must bo set to
  .word reset                   ; the beginning of the program.
  .word $0000                   ; Unused bytes at the end of the ROM binary.
