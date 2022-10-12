#!/usr/bin/env python3
import os
import serial
import sys

# Yield successive n-sized chunks from l
def divide_chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: " + sys.argv[0] + " [program_name].s")
        exit(1)

    asm_file = sys.argv[1]
    bin_file = "/tmp/vasm.bin"

    if os.system(f"vasm6502_oldstyle -Fbin -dotdir {asm_file} -o {bin_file}") != 0:
        exit(1)

    data = b''
    with open(bin_file, "rb") as f:
        data = f.read()

    ser = serial.Serial("/dev/ttyACM0", 256000)

    print("Waiting for poke byte...")
    while ser.read(1)[0] != 0x42:
        pass

    # First write the size of the program
    print("Sending data!")
    ser.write([
        len(data) & 0xff,
        (len(data) >> 8) & 0xff,
    ])
    for chunk in divide_chunks(data, 255):
        ser.write(chunk)
        print("Wrote " + str(ser.read(1)[0]) + " bytes")
    print("Upload success")

    ser.close()