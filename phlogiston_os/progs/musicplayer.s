    .include "../os/base.s"
    .org RAM_PROG_ORG
    .word main
    .word irq


;; 16 bit number, counting the number of ticks of 10ms since boot time
;; 1 tick is 10ms
ticks      = $00
track1_ptr = $04
track2_ptr = $06
track3_ptr = $08
track4_ptr = $0a


main:
    lda #<track1
    sta track1_ptr
    lda #>track1
    sta track1_ptr+1

    jsr init_timer

    lda #0
    sta POKEY_AUDC1
    sta POKEY_AUDC2
    sta POKEY_AUDC3
    sta POKEY_AUDC4
    sta POKEY_AUDCTL


    lda #$a1
    sta POKEY_AUDC1

    jsr next_song_data
loop:
    jsr lcd_seek_begin
    lda ticks
    jsr lcd_print_hex
    jmp loop
    rts


;; Initializes VIA timer to trigger every 10 ms
init_timer:
    lda #0
    sta ticks
    ;; Set timer 1 to act an a continuously running interrupt
    lda #%01000000
    sta VIA_ACR
    lda #$0e
    sta VIA_T1CL
    lda #$27
    sta VIA_T1CH
    ;; Enable IRQ interrupts for timer 1
    lda #%11000000
    sta VIA_IER
    rts


irq:
    pha
    txa
    pha
    bit VIA_T1CL ; Clear the timer 1 interrupt bit
    inc ticks
    lda ticks
    cmp #tick_count_per_beat
    bne .2
    lda #0
    sta ticks
    jsr next_song_data
.2: pla
    tax
    pla
    rti


next_song_data:
    ldy #0
    lda (track1_ptr),y
    cmp #$ff
    bne .1
    lda #0
    sta POKEY_AUDF1
    sta POKEY_AUDC1
    rts
.1: ;lda (track1_ptr),y
    ;sta POKEY_AUDC1
    ldy #1
    lda (track1_ptr),y
    sta POKEY_AUDF1

    ; Increment twice
    inc track1_ptr
    bne .3
    inc track1_ptr+1
.2: inc track1_ptr
    bne .3
    inc track1_ptr+1
.3: rts


tick_count_per_beat = 4
track1: .data $a1, 50, $a1, 50, $a1, 50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, $a1,50, 0,0, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, $a1,57, 0,0, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, $a1,64, 0,0, $ff
track2: .data $ff
track3: .data $ff
track4: .data $ff
