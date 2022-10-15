Base on [Ben Eater's 6502 computer kit](https://eater.net/6502).

## Writing code for the phlogiston computer
For writing programs that you can upload over serial, see `progs/blink.s`.
It's shows a simple example of how to set up a program to run over serial.

How does it work?
1. The Phlogiston bootloader will send a "poke byte" to an Arduino.
2. The Arduino will then send a poke byte to your PC
3. You should be running the `relay_asm.py` script to upload your program
4. The 6502 computer will save the program data at memory address `$4000` 
5. Once the entire program is uploaded, it moves execution to the uploaded program
## Tutorials
http://6502.org/tutorials/interrupts.html
## Memory map

I modified the memory selection logic from the Eater6502.
Originally, the RAM only occupied 16k, while the ROM occupied 32k.
I plan to set up the POKEY to support dynamically reading in programs over serial, so I wanted more RAM instead.
I also added an Atari POKEY chip for sound generation and other fun IO capabilities!

Logic chip selection memory map:
```
- 0000-7fff: RAM (32k)        : (!a15)(phi2)         | !CS 
- 8000-800f: VIA chip (16)    : (a15)(!a14)(!a4)     | CS1, !CS2
- 8010-801f: POKEY chip (16)  : (a15)(!a14)(a4)      | !CS0, CS1
- c000-ffff: EEPROM (16k)     : (a15)(a14)           | !CS
```

Practically, the memory map is as follows:
```
- 0000-00ff: "Zero page". Faster access memory than the rest of the address space
- 0100-01ff: Stack
- 0200-7fff: General purpose RAM
- 8000-801f: IO chips (VIA and POKEY)
- c000-ffff: EEPROM
```

## Data sheets
- [65c02](https://eater.net/datasheets/w65c02s.pdf)
- [65c22](https://eater.net/datasheets/w65c22.pdf)
- [POKEY ASCII](http://krap.pl/mirrorz/atari/homepage.ntlworld.com/kryten_droid/Atari/800XL/atari_hw/pokey.htm)
- [POKEY PDF](http://visual6502.org/images/C012294_Pokey/pokey.pdf)
- [POKEY Pinout](https://user.xmission.com/~trevin/atari/pokey_pinout.html)
- [Another POKEY Pinout](https://console5.com/techwiki/index.php?title=POKEY&mobileaction=toggle_view_desktop)
- [Atari 800XL Service Manual](https://archive.org/details/Atari800XLServiceManual/page/n37/mode/2up)
## 6502 Assembly
See `blink.s` for an minimal example program.

Or if you want to write an actual program, see `base.s` and `i_ate_some_pie.s`

References:
- https://en.wikibooks.org/wiki/6502_Assembly
- http://www.6502.org/tutorials/6502opcodes.html
- https://skilldrick.github.io/easy6502/
- https://usermanual.wiki/Document/pokeyC012294.3349751284/view
## TODO Fix power on reset
- https://trobertson.site/6502-power-on-reset/
- http://wilsonminesco.com/6502primer/RSTreqs.html

If you use a schmitt trigger inverter, you can also use that for a reset circuit!
... orrrr use a 555 timer for the reset circuit. But then you need 1 extra IC
The nice thing about using the 555 timer is that you can probably tune how long you want the reset button depressed

## POKEY Timing
According to the POKEY AUDCTL docs, there is a formula to compute the timer
output frequencies relative to the input phi2 clock frequency.

Use that formula to figure out what notes you can make using a 1Mhz clock, and document it!

Fout = Fin / 2(AUDF + M), M=4 for AUDCTL bits 3 and 4 set to 0. So:
Fout = Fin / 2(AUDF + 4)

Fin is orignially 64kHz. But if you use a different clock, you'll have to adjust it via:
Fin = (64/1790) * Fclock

=> A = (Fin/Fout - 4)/2
## TODO: Rewire memory mapping to support 4 expansion cards
Their connectors should have the following 22 pins:
- 8 data pins
- (8?) address pins
- 1 IRQB pin
- 1 5V VCC pin
- 1 GND pin
- 1 Chip select pin
- 1 R/W pin
- 1 PHI2 pin
