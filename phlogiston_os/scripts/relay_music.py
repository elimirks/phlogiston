#!/usr/bin/env python3
import re
import sys

from relay_asm import relay_asm_file


def frequency_to_pokey_byte(f):
    # Clock speed of the computer in MHz
    clock_speed = 1.0
    # Frequency of the POKEY timers (voices)
    # Must be adjusted since we have a different clock than the Atari 800
    fin = 63921.0 * (clock_speed / 1.78979)
    # From the calculation shown in the POKEY data sheet
    return round(fin/(2 * f) - 4)


def extrapolate_note(base, n):
    # https://pages.mtu.edu/~suits/NoteFreqCalcs.html
    a = 2**(1/12)
    return base * (a**n)


# Maps note names to their associated pokey bytes
note_to_pokey_byte = {}

base_frequencies = {
    #0: 16.35,
    #1: 32.70,
    2: 65.41,
    3: 130.81,
    4: 261.63,
    5: 523.25,
    6: 1046.50,
    7: 2093.00,
    #8: 4186.01,
}
notes = [
    "c",
    "c#",
    "d",
    "d#",
    "e",
    "f",
    "f#",
    "g",
    "g#",
    "a",
    "a#",
    "b",
]
for i, base in base_frequencies.items():
    for j, note in enumerate(notes):
        frequency = extrapolate_note(base, j)
        b = frequency_to_pokey_byte(frequency)
        if b < 255 and b > 0:
            note_to_pokey_byte[f"{note}{i}"] = b


def read_file(f):
    lines = []
    with open(sys.argv[1]) as f:
        commentregex = re.compile(r"(;.*)?\n$")
        for unstripped in f.readlines():
            line = re.sub(commentregex, '', unstripped).strip()
            if len(line) == 0:
                continue
            lines.append(line)
    return lines


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: " + sys.argv[0] + " [program_name].s")
        exit(1)

    lines = read_file(sys.argv[1])

    bpm = int(lines[0]) # TODO: error handling
    tracks = [
        [],
        [],
        [],
        [],
    ]
    current_track = 0

    for line in lines[1:]:
        if line[0] == 'T':
            # TODO: Error handling
            current_track = int(line[1]) - 1
            continue
        [ctl, duration, note] = line.split(" ")

        duration = int(duration)
        if duration < 0 or duration > 8:
            print(f"Invalid duration: {duration}")

        pokey_byte = note_to_pokey_byte[note]
        if pokey_byte == None:
            print(f"Invalid note: {note}")
            exit(1)
        tracks[current_track].append((ctl, duration, pokey_byte))

    output = f"tick_count_per_beat = {round(6000/(8 * bpm))}\n"

    for i in range(4):
        track_num = i + 1
        output += f"track{track_num}: .data "

        for (ctl, duration, note_byte) in tracks[i]:
            for i in range(duration):
                output += f"${ctl},{note_byte}, "
            for i in range(8 - duration):
                output += f"0,0, "

        output += "$ff\n"

    print(output)
