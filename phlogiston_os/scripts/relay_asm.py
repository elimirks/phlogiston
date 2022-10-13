#!/usr/bin/env python3
import re
import serial
import subprocess
import sys

# Yield successive n-sized chunks from l
def divide_chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]


# Returns number of bytes necessary to read from the out file
def run_vasm(asm_file, out_path):
    proc = subprocess.run([
        "vasm6502_oldstyle",
        "-Fbin",
        "-dotdir",
        asm_file,
        "-o",
        out_path,
    ], capture_output=True)

    if proc.returncode != 0:
        print(proc.stderr.decode("utf-8"))
        exit(proc.returncode)
    stdout = proc.stdout.decode("utf-8")

    for line in stdout.split('\n'):
        byteregex = re.compile(r"^seg4000.*:\s+(\d+)\s+bytes")
        match = byteregex.match(line)
        if match is not None:
            return int(match.group(1))
    print("Failed finding seg4000 in vasm output")
    exit(1)

def load_bin_from_asm(asm_file, out_path):
    prog_byte_num = run_vasm(asm_file, out_path)
    with open(bin_file, "rb") as f:
        return f.read()[:prog_byte_num]

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: " + sys.argv[0] + " [program_name].s")
        exit(1)

    asm_file = sys.argv[1]
    bin_file = "/tmp/vasm.bin"
    print(f"Assembling {asm_file}")
    data = load_bin_from_asm(asm_file, bin_file)

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
