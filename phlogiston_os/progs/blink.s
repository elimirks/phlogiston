  .org $4000                    ; Necessary to fill up the entire 32K
  ; TODO: Require specifying main function & IRQ?

reset:
  ;; Set the data direction of register B to all outputs
  ;; #$ff is the bitmask: each set bit indicates that pin should be an output
  lda #$f0
  sta $8003

  lda #$01                      ; Put the hex value 50 in register A.
  sta $8001                     ; Move register A to I/O VIA register A.

  lda #$c0
loop:
  ror                           ; Rotate register A right.
  sta $8001                     ; Move register A to I/O VIA register A.
  jmp loop                      ; Ad infinitum!
