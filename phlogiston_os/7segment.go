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
    0b01101111, // 0
    0b00000011, // 1
    0b01110110, // 2
    0b01010111, // 3
    0b00011011, // 4
    0b01011101, // 5
    0b01111101, // 6
    0b00000111, // 7
    0b01111111, // 8
    0b00011111, // 9
    0b00111111, // a
    0b01111001, // b
    0b01101100, // c
    0b01110011, // d
    0b01111100, // e
    0b00111100, // f
}

func main() {
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
