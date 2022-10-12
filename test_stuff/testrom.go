package main
/*
 * This program will upload a ROM for decoding a nibble for a 7 segment display
 */
import (
	"log"
	"os/exec"
	"os"
)

var program = [32768]byte{
    0xa9, 0xff,         // lda #$ff
    0x8d, 0x02, 0x60,   // sta $6002

    0xa9, 0x55,         // lda #$55
    0x8d, 0x00, 0x60,   // sta $6000

    0xa9, 0xaa,         // lda #$aa
    0x8d, 0x00, 0x60,   // sta $6000

    0x4c, 0x05, 0x80,   // jmp $8005
}

func main() {
	program[0x7ffc] = 0x00
	program[0x7ffd] = 0x80

    cmd := exec.Command("minipro", "-p", "AT28C256", "-w-")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
    programPipe, err := cmd.StdinPipe()
    if err != nil {
        log.Fatal(err)
    }
    go func() {
        defer programPipe.Close()
		programPipe.Write(program[:])
    }()

    if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
}
