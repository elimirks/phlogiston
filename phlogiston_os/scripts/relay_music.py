#!/usr/bin/env python3
import os
import re
import sys

from relay_asm import relay_asm_file


def frequency_to_pokey_byte(f):
    # Clock speed of the computer in MHz
    clock_speed = 1.0
    # Frequency of the POKEY timers (voices)
    # Must be adjusted since we have a different clock than the Atari 800
    fin = 63.9210 * 1000.0 * (clock_speed / 1.78979)
    #fin = 15.6999 * 1000.0 * (clock_speed / 1.78979)
    #fin = 15.6999 * 1000.0
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


def load_musicplayer():
    path = os.path.dirname(__file__) + "/../progs/musicplayer.s"
    with open(path) as f:
        return f.read()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: " + sys.argv[0] + " [program_name].s")
        exit(1)

    print("Loading music file")
    lines = read_file(sys.argv[1])

    bpm = float(lines[0]) # TODO: error handling
    tracks = [
        [],
        [],
        [],
        [],
    ]
    current_track = 0

    print("Compiling music data")
    for line in lines[1:]:
        if line[0] == 'T':
            # TODO: Error handling
            current_track = int(line[1]) - 1
            continue
        [ctl, duration, note, modifier] = line.split(" ")

        duration = int(duration)
        if duration < 0 or duration > 255:
            print(f"Invalid duration: {duration}")
            exit(1)

        pokey_byte = note_to_pokey_byte[note]
        if pokey_byte == None:
            print(f"Invalid note: {note}")
            exit(1)
        tracks[current_track].append((ctl, duration, pokey_byte, modifier))

    music_data = f"tick_count_per_beat = {round(6000.0/(8.0 * bpm))}\n"

    for i in range(4):
        track_num = i + 1
        music_data += f"track{track_num}: .data "

        for (ctl, duration, note_byte, modifier) in tracks[i]:
            music_data += f"{duration},${ctl},{note_byte}, "
            # Comma modifier pads with excess duration
            if modifier == ",":
                excess = 8 - duration
                if excess > 0:
                    music_data += f"{excess},0,0, "
            # Dot modifier does nothing
            elif modifier == ".":
                pass
            else:
                print(f"Unknown modifier: {modifier}")
        music_data += "0\n"

    music_player = load_musicplayer()

    out_path = os.path.dirname(__file__) + "/pokey_music.s"
    with open(out_path, "w") as f:
        f.write(music_player)
        f.write(music_data)
    relay_asm_file(out_path)
