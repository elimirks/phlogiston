#!/bin/bash

set -e

if [ $# != 1 ]; then
    echo "Usage: $0 [asm_file.s]"
    exit 1
fi

ASM_FILE=$1
BIN_FILE=/tmp/vasm.bin

vasm6502_oldstyle -Fbin -dotdir $ASM_FILE -o $BIN_FILE && minipro -p AT28C256 -w $BIN_FILE
#rm $BIN_FILE
