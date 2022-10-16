    .include "../os/base.s"
    .org RAM_PROG_ORG
    .word main
    .word irq


;; 16 bit number, counting the number of ticks of 10ms since boot time
;; 1 tick is 10ms
ticks        = $00
track1_ptr   = ticks+1
track2_ptr   = track1_ptr+2
track3_ptr   = track2_ptr+2
track4_ptr   = track3_ptr+2
track1_timer = track4_ptr+2
track2_timer = track1_timer+1
track3_timer = track2_timer+1
track4_timer = track3_timer+1

main:
    lda #<track1
    sta track1_ptr
    lda #>track1
    sta track1_ptr+1
    lda #<track2
    sta track2_ptr
    lda #>track2
    sta track2_ptr+1
    lda #<track3
    sta track3_ptr
    lda #>track3
    sta track3_ptr+1
    lda #<track4
    sta track4_ptr
    lda #>track4
    sta track4_ptr+1

    ; TODO: Switch to the lower frequency so we can get more depth
    ;lda #%00000001
    lda #%00000000
    sta POKEY_AUDCTL
    lda #0
    sta POKEY_AUDC1
    sta POKEY_AUDC2
    sta POKEY_AUDC3
    sta POKEY_AUDC4
    sta track1_timer
    sta track2_timer
    sta track3_timer
    sta track4_timer

    jsr init_timer
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
    jsr next_song_data_1
    jsr next_song_data_2
    jsr next_song_data_3
    jsr next_song_data_4
    rts

next_song_data_1:
    lda track1_timer
    cmp #0
    beq .0
    dec track1_timer
    rts
.0: ldy #0             ; Begin loading
    lda (track1_ptr),y ; Duration
    sta track1_timer
    cmp #0             ; Null terminated halt
    bne .2
    lda #0
    sta POKEY_AUDF1
    sta POKEY_AUDC1
    rts
.2: ldy #1
    lda (track1_ptr),y ; CTL byte
    sta POKEY_AUDC1
    ldy #2
    lda (track1_ptr),y ; Note byte
    sta POKEY_AUDF1
    ; Increment track pointer by 3
    lda track1_ptr
    clc
    adc #3
    sta track1_ptr
    bcc .3
    inc track1_ptr+1
.3: rts


next_song_data_2:
    lda track2_timer
    cmp #0
    beq .0
    dec track2_timer
    rts
.0: ldy #0             ; Begin loading
    lda (track2_ptr),y ; Duration
    sta track2_timer
    cmp #0             ; Null terminated halt
    bne .2
    lda #0
    sta POKEY_AUDF2
    sta POKEY_AUDC2
    rts
.2: ldy #1
    lda (track2_ptr),y ; CTL byte
    sta POKEY_AUDC2
    ldy #2
    lda (track2_ptr),y ; Note byte
    sta POKEY_AUDF2
    ; Increment track pointer by 3
    lda track2_ptr
    clc
    adc #3
    sta track2_ptr
    bcc .3
    inc track2_ptr+1
.3: rts


next_song_data_3:
    lda track3_timer
    cmp #0
    beq .0
    dec track3_timer
    rts
.0: ldy #0             ; Begin loading
    lda (track3_ptr),y ; Duration
    sta track3_timer
    cmp #0             ; Null terminated halt
    bne .2
    lda #0
    sta POKEY_AUDF3
    sta POKEY_AUDC3
    rts
.2: ldy #1
    lda (track3_ptr),y ; CTL byte
    sta POKEY_AUDC3
    ldy #2
    lda (track3_ptr),y ; Note byte
    sta POKEY_AUDF3
    ; Increment track pointer by 3
    lda track3_ptr
    clc
    adc #3
    sta track3_ptr
    bcc .3
    inc track3_ptr+1
.3: rts


next_song_data_4:
    lda track4_timer
    cmp #0
    beq .0
    dec track4_timer
    rts
.0: ldy #0             ; Begin loading
    lda (track4_ptr),y ; Duration
    sta track4_timer
    cmp #0             ; Null terminated halt
    bne .2
    lda #0
    sta POKEY_AUDF4
    sta POKEY_AUDC4
    rts
.2: ldy #1
    lda (track4_ptr),y ; CTL byte
    sta POKEY_AUDC4
    ldy #2
    lda (track4_ptr),y ; Note byte
    sta POKEY_AUDF4
    ; Increment track pointer by 3
    lda track4_ptr
    clc
    adc #3
    sta track4_ptr
    bcc .3
    inc track4_ptr+1
.3: rts

; Expects the music data generator to add these lines
; tick_count_per_beat = 4
; track1: .data $ff
; track2: .data $ff
; track3: .data $ff
; track4: .data $ff
