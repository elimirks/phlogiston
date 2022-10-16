    .include "../os/base.s"
    .org RAM_PROG_ORG
    .word main
    .word irq


bpm = 167 * 2
tick_count_per_beat = 6000/bpm
;; 16 bit number, counting the number of ticks of 10ms since boot time
;; 1 tick is 10ms
ticks  = $00
track1 = $04


main:
    lda #<song_data_1
    sta track1
    lda #>song_data_1
    sta track1+1

    jsr init_timer

    lda #0
    sta POKEY_AUDC1
    sta POKEY_AUDC2
    sta POKEY_AUDC3
    sta POKEY_AUDC4
    sta POKEY_AUDCTL
    ; Send a timing 
    ldx #0
    lda (track1,x)
    sta POKEY_AUDF2

    lda #%10100001
    sta POKEY_AUDC2
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
    jsr inc_song_data
.2: pla
    tax
    pla
    rti


inc_song_data:
    inc track1
    ldx #0
    lda (track1,x)
    cmp #$ff
    bne .1 
    lda #<song_data_1
    sta track1
    lda #>song_data_1
    sta track1+1
.1: lda (track1,x)
    sta POKEY_AUDF2
    rts


a3 = $4d
b3 = $44
c4 = $40
d4 = $39
e4 = $32
f4 = $2f
g4 = $2a
a4 = $25

song_data_1:
.1: .data e4, 0, d4, 0, c4, 0, d4, 0, e4, 0, e4, 0, e4, 0
.2: .data d4, 0, d4, 0, d4, 0, e4, 0, e4, 0, e4, 0
.3: .data e4, 0, d4, 0, c4, 0, d4, 0, e4, 0, e4, 0, e4, 0
.4: .data e4, 0, d4, 0, d4, 0, e4, 0, d4, 0, c4, 0
.5: .data 0, 0, 0, 0, 0, 0, 0, 0, $ff
;song_data_1: .data g4, 0, g4, 0, g4, 0, f4, 0, g4, 0, a4, 0, $ff
