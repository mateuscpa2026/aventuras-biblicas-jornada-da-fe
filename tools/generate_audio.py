"""Gera a trilha sonora original e os efeitos do jogo (WAV mono 16 bits, 22.05 kHz).

Tudo é sintetizado por código, sem amostras de terceiros. Cada tema tem melodia,
acompanhamento, baixo, percussão suave e cauda de reverb dobrada para o início do
loop, então a música emenda sem clique. Basta rodar `python tools/generate_audio.py`
na raiz do projeto.

Os arquivos gerados são provisórios no sentido de que podem ser substituídos por
gravações definitivas mantendo os mesmos nomes.
"""

import math
import os
import random
import struct
import wave

SR = 22050
TABLE_SIZE = 2048
TABLE_MASK = TABLE_SIZE - 1
REVERB_TAIL = 2.0
random.seed(7)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ---------------------------------------------------------------- notas

PITCH_CLASS = {
    "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5,
    "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11,
}


def note_midi(name):
    pitch, octave = name[:-1], int(name[-1])
    return (octave + 1) * 12 + PITCH_CLASS[pitch]


def midi_freq(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def smoothstep(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3.0 - 2.0 * x)


# ---------------------------------------------------------------- timbres

TIMBRES = {
    "flute": {"partials": [(1, 1.0), (2, 0.2), (3, 0.06)], "attack": 0.05, "release": 0.12, "kind": "sustain"},
    "reed": {"partials": [(1, 1.0), (3, 0.32), (5, 0.14), (2, 0.08)], "attack": 0.06, "release": 0.12, "kind": "sustain"},
    "horn": {"partials": [(1, 1.0), (2, 0.42), (3, 0.2), (4, 0.09), (5, 0.04)], "attack": 0.09, "release": 0.18, "kind": "sustain"},
    "strings": {"partials": [(1, 1.0), (2, 0.28), (3, 0.11), (4, 0.05)], "attack": 0.16, "release": 0.28, "kind": "sustain"},
    "pluck": {"partials": [(1, 1.0), (2, 0.4), (3, 0.2), (4, 0.1), (5, 0.05), (6, 0.02)], "attack": 0.004, "release": 0.04, "kind": "decay", "tau": 0.3},
    "harp": {"partials": [(1, 1.0), (2, 0.55), (3, 0.3), (4, 0.16), (5, 0.08), (6, 0.04)], "attack": 0.003, "release": 0.04, "kind": "decay", "tau": 0.55},
    "bass": {"partials": [(1, 1.0), (2, 0.3), (3, 0.1)], "attack": 0.01, "release": 0.06, "kind": "sustain"},
}


def build_table(partials):
    values = []
    for i in range(TABLE_SIZE):
        phase = 2.0 * math.pi * i / TABLE_SIZE
        value = sum(amp * math.sin(phase * mult) for mult, amp in partials)
        values.append(value)
    peak = max(abs(v) for v in values) or 1.0
    return [v / peak for v in values]


TABLES = {name: build_table(spec["partials"]) for name, spec in TIMBRES.items()}
LFO_TABLE = [math.sin(2.0 * math.pi * i / TABLE_SIZE) for i in range(TABLE_SIZE)]


def add_note(buf, start, duration, midi, timbre, gain, vibrato=0.0):
    spec = TIMBRES[timbre]
    table = TABLES[timbre]
    freq = midi_freq(midi)
    begin = int(start * SR)
    count = int(duration * SR)
    if begin >= len(buf) or count <= 0:
        return
    count = min(count, len(buf) - begin)
    increment = freq * TABLE_SIZE / SR
    vibrato_increment = 5.4 * TABLE_SIZE / SR
    attack = max(1, int(spec["attack"] * SR))
    release = max(1, int(spec["release"] * SR))
    decay = math.exp(-1.0 / (spec.get("tau", 0.3) * SR)) if spec["kind"] == "decay" else 1.0
    phase = 0.0
    lfo_phase = 0.0
    envelope = 0.0
    for i in range(count):
        if i < attack:
            envelope = i / attack
        elif spec["kind"] == "decay":
            envelope *= decay
        else:
            envelope = 1.0
            if i > count - release:
                envelope = (count - i) / release
        rate = 1.0
        if vibrato > 0.0:
            lfo_phase += vibrato_increment
            rate = 1.0 + vibrato * LFO_TABLE[int(lfo_phase) & TABLE_MASK]
        buf[begin + i] += table[int(phase) & TABLE_MASK] * envelope * gain
        phase += increment * rate


def add_bell(buf, start, midi, duration, gain):
    freq = midi_freq(midi)
    begin = int(start * SR)
    count = min(int(duration * SR), len(buf) - begin)
    if count <= 0:
        return
    attack = max(1, int(0.004 * SR))
    for i in range(count):
        t = i / SR
        envelope = min(1.0, i / attack) * math.exp(-t / (duration * 0.5))
        value = (
            math.sin(2 * math.pi * freq * t)
            + 0.45 * math.sin(2 * math.pi * freq * 2.76 * t)
            + 0.18 * math.sin(2 * math.pi * freq * 5.4 * t)
            + 0.06 * math.sin(2 * math.pi * freq * 8.9 * t)
        )
        buf[begin + i] += value * envelope * gain / 1.7


# ---------------------------------------------------------------- percussão

def add_kick(buf, start, gain=0.2):
    begin = int(start * SR)
    count = min(int(0.22 * SR), len(buf) - begin)
    if count <= 0:
        return
    phase = 0.0
    for i in range(count):
        u = i / count
        freq = 108.0 + (48.0 - 108.0) * u
        phase += 2.0 * math.pi * freq / SR
        buf[begin + i] += math.sin(phase) * math.exp(-u * 6.5) * gain


def add_frame_drum(buf, start, gain=0.16):
    begin = int(start * SR)
    count = min(int(0.4 * SR), len(buf) - begin)
    if count <= 0:
        return
    phase = 0.0
    noise = 0.0
    for i in range(count):
        u = i / count
        freq = 96.0 + (72.0 - 96.0) * u
        phase += 2.0 * math.pi * freq / SR
        noise += 0.25 * ((random.random() * 2.0 - 1.0) - noise)
        value = math.sin(phase) + noise * 0.35
        buf[begin + i] += value * math.exp(-u * 4.2) * gain


def add_shaker(buf, start, gain=0.04):
    begin = int(start * SR)
    count = min(int(0.075 * SR), len(buf) - begin)
    if count <= 0:
        return
    previous = 0.0
    for i in range(count):
        u = i / count
        sample = random.random() * 2.0 - 1.0
        high = sample - previous
        previous = sample
        envelope = min(1.0, u * 18.0) * math.exp(-u * 8.0)
        buf[begin + i] += high * envelope * gain


def add_rim(buf, start, gain=0.08):
    begin = int(start * SR)
    count = min(int(0.06 * SR), len(buf) - begin)
    if count <= 0:
        return
    for i in range(count):
        t = i / SR
        envelope = math.exp(-t / 0.014)
        value = math.sin(2 * math.pi * 1450 * t) + (random.random() * 2.0 - 1.0) * 0.4
        buf[begin + i] += value * envelope * gain


# ---------------------------------------------------------------- harmonia

def chord_tones(symbol):
    if "/" in symbol:
        body, bass_name = symbol.split("/")
    else:
        body, bass_name = symbol, None
    minor = body.endswith("m")
    root_name = body[:-1] if minor else body
    root = PITCH_CLASS[root_name]
    tones = [(3 + 1) * 12 + root, (3 + 1) * 12 + root + (3 if minor else 4), (3 + 1) * 12 + root + 7]
    bass_pc = PITCH_CLASS[bass_name] if bass_name else root
    bass = 2 * 12 + bass_pc
    return tones, bass


# ---------------------------------------------------------------- trilhas

THEMES = [
    {
        "id": "menu",
        "bpm": 96,
        "beats_per_bar": 4,
        "style": "gentle",
        "lead": "flute",
        "lead_gain": 0.18,
        "arp": "pluck",
        "prog": ["C", "G", "Am", "F", "C", "G", "F", "G",
                 "C", "Am", "F", "G", "C", "F", "G", "C"],
        "melody": [
            (0, 0, "G4", 1), (0, 1, "E4", 1), (0, 2, "G4", 1), (0, 3, "C5", 1),
            (1, 0, "B4", 1), (1, 1, "D5", 1), (1, 2, "B4", 2),
            (2, 0, "A4", 1), (2, 1, "C5", 1), (2, 2, "E5", 2),
            (3, 0, "A4", 1), (3, 1, "F4", 1), (3, 2, "A4", 2),
            (4, 0, "E5", 1.5), (4, 1.5, "D5", 0.5), (4, 2, "C5", 2),
            (5, 0, "D5", 1), (5, 1, "B4", 1), (5, 2, "D5", 2),
            (6, 0, "F5", 1.5), (6, 1.5, "E5", 0.5), (6, 2, "C5", 2),
            (7, 0, "D5", 3),
            (8, 0, "C5", 1), (8, 1, "E5", 1), (8, 2, "G5", 2),
            (9, 0, "D5", 1.5), (9, 1.5, "B4", 0.5), (9, 2, "G4", 2),
            (10, 0, "A4", 1), (10, 1, "C5", 1), (10, 2, "E5", 1), (10, 3, "A5", 1),
            (11, 0, "G5", 2), (11, 2, "F5", 1), (11, 3, "E5", 1),
            (12, 0, "E5", 1), (12, 1, "G5", 1), (12, 2, "E5", 2),
            (13, 0, "C5", 1), (13, 1, "E5", 1), (13, 2, "A5", 2),
            (14, 0, "A5", 1.5), (14, 1.5, "G5", 0.5), (14, 2, "E5", 1), (14, 3, "C5", 1),
            (15, 0, "D5", 2), (15, 2, "G4", 2),
        ],
    },
    {
        "id": "eden",
        "bpm": 126,
        "beats_per_bar": 3,
        "style": "waltz",
        "lead": "flute",
        "lead_gain": 0.17,
        "arp": "pluck",
        "prog": ["D", "A/C#", "Bm", "G", "D", "A", "G", "A",
                 "D", "A/C#", "Bm", "G", "D", "A", "G", "A"],
        "melody": [
            (0, 0, "F#5", 2), (0, 2, "E5", 1),
            (1, 0, "E5", 2), (1, 2, "C#5", 1),
            (2, 0, "D5", 1), (2, 1, "F#5", 1), (2, 2, "B5", 1),
            (3, 0, "A5", 2), (3, 2, "G5", 1),
            (4, 0, "F#5", 2), (4, 2, "E5", 1),
            (5, 0, "E5", 1), (5, 1, "C#5", 1), (5, 2, "E5", 1),
            (6, 0, "G5", 2), (6, 2, "F#5", 1),
            (7, 0, "E5", 2), (7, 2, "C#5", 1),
            (8, 0, "D5", 1), (8, 1, "F#5", 1), (8, 2, "A5", 1),
            (9, 0, "C#5", 1), (9, 1, "E5", 1), (9, 2, "A5", 1),
            (10, 0, "B4", 1), (10, 1, "D5", 1), (10, 2, "F#5", 1),
            (11, 0, "G5", 1), (11, 1, "A5", 1), (11, 2, "B5", 1),
            (12, 0, "A5", 2), (12, 2, "F#5", 1),
            (13, 0, "E5", 2), (13, 2, "C#5", 1),
            (14, 0, "D5", 1), (14, 1, "G5", 1), (14, 2, "B4", 1),
            (15, 0, "A4", 3),
        ],
    },
    {
        "id": "arca",
        "bpm": 84,
        "beats_per_bar": 4,
        "style": "rocking",
        "lead": "reed",
        "lead_gain": 0.16,
        "arp": "pluck",
        "prog": ["G", "Em", "C", "D", "G", "C", "G", "D",
                 "Em", "C", "G", "D", "C", "G", "D", "G"],
        "melody": [
            (0, 0, "D5", 1.5), (0, 1.5, "B4", 0.5), (0, 2, "G4", 2),
            (1, 0, "E5", 1.5), (1, 1.5, "B4", 0.5), (1, 2, "G4", 2),
            (2, 0, "C5", 1), (2, 1, "E5", 1), (2, 2, "G5", 2),
            (3, 0, "F#5", 2), (3, 2, "D5", 2),
            (4, 0, "B4", 1), (4, 1, "D5", 1), (4, 2, "G5", 2),
            (5, 0, "E5", 1.5), (5, 1.5, "D5", 0.5), (5, 2, "C5", 2),
            (6, 0, "B4", 2), (6, 2, "D5", 2),
            (7, 0, "F#5", 2), (7, 2, "D5", 2),
            (8, 0, "G5", 1.5), (8, 1.5, "F#5", 0.5), (8, 2, "E5", 2),
            (9, 0, "E5", 1), (9, 1, "G5", 1), (9, 2, "E5", 2),
            (10, 0, "D5", 1.5), (10, 1.5, "B4", 0.5), (10, 2, "G4", 2),
            (11, 0, "F#5", 1), (11, 1, "A5", 1), (11, 2, "D5", 2),
            (12, 0, "E5", 2), (12, 2, "G5", 2),
            (13, 0, "D5", 2), (13, 2, "B4", 2),
            (14, 0, "A4", 1), (14, 1, "B4", 1), (14, 2, "A4", 2),
            (15, 0, "G4", 4),
        ],
    },
    {
        "id": "davi",
        "bpm": 116,
        "beats_per_bar": 4,
        "style": "heroic",
        "lead": "pluck",
        "lead_gain": 0.26,
        "arp": "pluck",
        "prog": ["D", "G", "A", "D", "Bm", "G", "A", "D",
                 "D", "G", "A", "Bm", "G", "A", "D", "D"],
        "melody": [
            (0, 0, "D5", 0.5), (0, 0.5, "E5", 0.5), (0, 1, "F#5", 1), (0, 2, "A5", 2),
            (1, 0, "G5", 1), (1, 1, "F#5", 1), (1, 2, "E5", 1), (1, 3, "D5", 1),
            (2, 0, "E5", 1.5), (2, 1.5, "C#5", 0.5), (2, 2, "E5", 1), (2, 3, "A4", 1),
            (3, 0, "D5", 3),
            (4, 0, "F#5", 1), (4, 1, "D5", 1), (4, 2, "B4", 2),
            (5, 0, "G4", 1), (5, 1, "B4", 1), (5, 2, "D5", 1), (5, 3, "G5", 1),
            (6, 0, "A5", 1), (6, 1, "G5", 1), (6, 2, "E5", 2),
            (7, 0, "D5", 2), (7, 2, "A4", 2),
            (8, 0, "A5", 1), (8, 1, "F#5", 1), (8, 2, "D5", 1), (8, 3, "F#5", 1),
            (9, 0, "G5", 2), (9, 2, "B4", 1), (9, 3, "D5", 1),
            (10, 0, "C#5", 1), (10, 1, "E5", 1), (10, 2, "A5", 2),
            (11, 0, "F#5", 2), (11, 2, "D5", 1), (11, 3, "B4", 1),
            (12, 0, "G5", 1), (12, 1, "A5", 1), (12, 2, "B5", 1), (12, 3, "A5", 1),
            (13, 0, "E5", 2), (13, 2, "C#5", 1), (13, 3, "A4", 1),
            (14, 0, "D5", 1), (14, 1, "F#5", 1), (14, 2, "A5", 2),
            (15, 0, "D5", 4),
        ],
    },
    {
        "id": "moises",
        "bpm": 88,
        "beats_per_bar": 4,
        "style": "mystic",
        "lead": "horn",
        "lead_gain": 0.2,
        "arp": "harp",
        "prog": ["Am", "F", "C", "G", "Am", "Dm", "E", "Am",
                 "F", "C", "G", "Am", "F", "G", "Am", "E"],
        "melody": [
            (0, 0, "E5", 2), (0, 2, "C5", 1), (0, 3, "A4", 1),
            (1, 0, "F4", 1), (1, 1, "A4", 1), (1, 2, "C5", 2),
            (2, 0, "E5", 2), (2, 2, "G4", 1), (2, 3, "C5", 1),
            (3, 0, "D5", 2), (3, 2, "B4", 2),
            (4, 0, "A4", 1), (4, 1, "C5", 1), (4, 2, "E5", 2),
            (5, 0, "F5", 2), (5, 2, "D5", 1), (5, 3, "A4", 1),
            (6, 0, "E5", 2), (6, 2, "G#4", 1), (6, 3, "B4", 1),
            (7, 0, "A4", 3),
            (8, 0, "A4", 1), (8, 1, "C5", 1), (8, 2, "F5", 2),
            (9, 0, "G5", 1.5), (9, 1.5, "E5", 0.5), (9, 2, "C5", 2),
            (10, 0, "D5", 1), (10, 1, "B4", 1), (10, 2, "G4", 2),
            (11, 0, "C5", 1), (11, 1, "E5", 1), (11, 2, "A5", 2),
            (12, 0, "A5", 1.5), (12, 1.5, "G5", 0.5), (12, 2, "F5", 1), (12, 3, "C5", 1),
            (13, 0, "D5", 2), (13, 2, "B4", 1), (13, 3, "G4", 1),
            (14, 0, "E5", 2), (14, 2, "C5", 1), (14, 3, "A4", 1),
            (15, 0, "B4", 2), (15, 2, "G#4", 2),
        ],
    },
    {
        "id": "jesus",
        "bpm": 80,
        "beats_per_bar": 4,
        "style": "tender",
        "lead": "flute",
        "lead_gain": 0.18,
        "arp": "harp",
        "prog": ["F", "C/E", "Dm", "Bb", "F", "C", "Bb", "F",
                 "F", "C/E", "Dm", "Bb", "F", "C", "Bb", "F"],
        "melody": [
            (0, 0, "A4", 2), (0, 2, "C5", 2),
            (1, 0, "G4", 1), (1, 1, "C5", 1), (1, 2, "E5", 2),
            (2, 0, "F5", 2), (2, 2, "E5", 1), (2, 3, "D5", 1),
            (3, 0, "D5", 2), (3, 2, "Bb4", 2),
            (4, 0, "A4", 1), (4, 1, "C5", 1), (4, 2, "F5", 2),
            (5, 0, "E5", 2), (5, 2, "C5", 1), (5, 3, "G4", 1),
            (6, 0, "D5", 2), (6, 2, "F5", 2),
            (7, 0, "C5", 3),
            (8, 0, "A4", 1), (8, 1, "C5", 1), (8, 2, "F5", 1), (8, 3, "A5", 1),
            (9, 0, "G5", 1), (9, 1, "E5", 1), (9, 2, "C5", 2),
            (10, 0, "D5", 1), (10, 1, "F5", 1), (10, 2, "A5", 2),
            (11, 0, "F5", 2), (11, 2, "D5", 2),
            (12, 0, "C5", 1), (12, 1, "F5", 1), (12, 2, "A5", 2),
            (13, 0, "G5", 2), (13, 2, "E5", 1), (13, 3, "C5", 1),
            (14, 0, "D5", 1), (14, 1, "F5", 1), (14, 2, "D5", 1), (14, 3, "C5", 1),
            (15, 0, "C5", 2), (15, 2, "A4", 2),
        ],
    },
]

ARP_PATTERNS = {
    "gentle": [0, 1, 2, 1, 0, 2, 1, 2],
    "rocking": [0, 2, 1, 2, 0, 1, 2, 1],
    "mystic": [0, 1, 2, 3, 2, 1, 2, 1],
    "tender": [0, 1, 2, 1, 3, 2, 1, 2],
    "heroic": [0, 2, 1, 2, 0, 1, 2, 1],
}


def add_accompaniment(buf, theme, beat_sec, bar_sec):
    style = theme["style"]
    bpb = theme["beats_per_bar"]
    arp_timbre = theme["arp"]
    for bar, symbol in enumerate(theme["prog"]):
        t0 = bar * bar_sec
        tones, bass = chord_tones(symbol)

        if style != "heroic" or bar % 2 == 0:
            for midi in tones:
                add_note(buf, t0, bar_sec * 0.94, midi + 12, "strings", 0.028)

        if style == "heroic":
            add_note(buf, t0, beat_sec * 0.9, bass, "bass", 0.17)
            add_note(buf, t0 + beat_sec * 2.0, beat_sec * 0.9, bass, "bass", 0.14)
            add_note(buf, t0 + beat_sec * 3.5, beat_sec * 0.45, bass + 7, "bass", 0.1)
        elif style == "waltz":
            add_note(buf, t0, beat_sec * 1.4, bass, "bass", 0.15)
            add_note(buf, t0 + beat_sec * 2.0, beat_sec * 0.8, bass + 7, "bass", 0.1)
        else:
            add_note(buf, t0, bar_sec * 0.94, bass, "bass", 0.13)
            if bpb == 4:
                add_note(buf, t0 + beat_sec * 2.5, beat_sec * 0.9, bass + 7, "bass", 0.07)

        if style == "waltz":
            for beat in (1, 2):
                for midi in tones:
                    add_note(buf, t0 + beat * beat_sec, beat_sec * 0.55, midi + 12, arp_timbre, 0.05)
            if bar % 2 == 0:
                add_bell(buf, t0, tones[2] + 24, 1.1, 0.03)
        else:
            pattern = ARP_PATTERNS[style]
            pool = [tones[0], tones[1], tones[2], tones[0] + 12]
            step = bpb / 8.0
            for index, choice in enumerate(pattern):
                start = t0 + index * step * beat_sec
                velocity = 0.05 if index % 4 else 0.062
                add_note(buf, start, step * beat_sec * 0.9, pool[choice] + 12, arp_timbre, velocity)

        if style == "gentle":
            for beat in (0.5, 1.5, 2.5, 3.5):
                add_shaker(buf, t0 + beat * beat_sec, 0.045)
        elif style == "waltz":
            for beat in (0.0, 1.0, 2.0):
                add_shaker(buf, t0 + beat * beat_sec, 0.03)
            if bar % 2 == 0:
                add_frame_drum(buf, t0, 0.09)
        elif style == "rocking":
            add_frame_drum(buf, t0, 0.16)
            add_frame_drum(buf, t0 + 2.5 * beat_sec, 0.1)
            for step_index in range(8):
                add_shaker(buf, t0 + step_index * 0.5 * beat_sec, 0.028)
        elif style == "heroic":
            add_kick(buf, t0, 0.24)
            add_kick(buf, t0 + 2.0 * beat_sec, 0.22)
            add_kick(buf, t0 + 3.5 * beat_sec, 0.15)
            add_rim(buf, t0 + beat_sec, 0.09)
            add_rim(buf, t0 + 3.0 * beat_sec, 0.09)
            for step_index in range(8):
                add_shaker(buf, t0 + step_index * 0.5 * beat_sec, 0.05 if step_index % 2 else 0.032)
        elif style == "mystic":
            add_frame_drum(buf, t0, 0.18)
            add_frame_drum(buf, t0 + 3.5 * beat_sec, 0.08)
            for beat in (1.0, 2.0):
                add_shaker(buf, t0 + beat * beat_sec, 0.03)
        elif style == "tender":
            add_frame_drum(buf, t0, 0.08)
            for step_index in range(8):
                add_shaker(buf, t0 + step_index * 0.5 * beat_sec, 0.02)


def add_melody(buf, theme, beat_sec):
    lead = theme["lead"]
    vibrato = {"flute": 0.004, "reed": 0.003, "horn": 0.0025}.get(lead, 0.0)
    gain = float(theme.get("lead_gain", {"flute": 0.15, "reed": 0.15, "horn": 0.13, "pluck": 0.16}.get(lead, 0.14)))
    for bar, beat, name, duration in theme["melody"]:
        start = bar * theme["beats_per_bar"] * beat_sec + beat * beat_sec
        add_note(buf, start, duration * beat_sec * 0.96, note_midi(name), lead, gain, vibrato)


def reverb(buf, wet=0.16):
    delay_a = [0.0] * 1429
    delay_b = [0.0] * 1871
    delay_c = [0.0] * 2357
    index_a = index_b = index_c = 0
    damp_a = damp_b = damp_c = 0.0
    smoothed = 0.0
    for i in range(len(buf)):
        tap_a = delay_a[index_a]
        tap_b = delay_b[index_b]
        tap_c = delay_c[index_c]
        damp_a += 0.55 * (tap_a - damp_a)
        damp_b += 0.5 * (tap_b - damp_b)
        damp_c += 0.45 * (tap_c - damp_c)
        wet_signal = (damp_a + damp_b + damp_c) * 0.33
        smoothed += 0.4 * (wet_signal - smoothed)
        delay_a[index_a] = buf[i] + damp_a * 0.7
        delay_b[index_b] = buf[i] + damp_b * 0.66
        delay_c[index_c] = buf[i] + damp_c * 0.62
        index_a = (index_a + 1) % len(delay_a)
        index_b = (index_b + 1) % len(delay_b)
        index_c = (index_c + 1) % len(delay_c)
        buf[i] += smoothed * wet


def render_theme(theme):
    beat_sec = 60.0 / theme["bpm"]
    bar_sec = beat_sec * theme["beats_per_bar"]
    loop_sec = bar_sec * len(theme["prog"])
    total = int((loop_sec + REVERB_TAIL) * SR)
    buf = [0.0] * total
    add_accompaniment(buf, theme, beat_sec, bar_sec)
    add_melody(buf, theme, beat_sec)
    wet = 0.1 if theme["style"] == "heroic" else 0.17
    reverb(buf, wet)
    loop_samples = int(loop_sec * SR)
    tail_samples = total - loop_samples
    for i in range(tail_samples):
        buf[i] += buf[loop_samples + i]
    del buf[loop_samples:]
    return buf


# ---------------------------------------------------------------- efeitos

def write_wav(path, samples, peak):
    top = max(abs(s) for s in samples) or 1.0
    scale = peak / top
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as fh:
        fh.setnchannels(1)
        fh.setsampwidth(2)
        fh.setframerate(SR)
        fh.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
            for s in samples
        ))
    print("ok", os.path.relpath(path, ROOT), f"{len(samples) / SR:.2f}s")


def render_sfx(duration):
    return [0.0] * int(SR * duration)


def bell(samples, start, freq, duration, gain=1.0):
    begin = int(start * SR)
    total = int(duration * SR)
    for j in range(total):
        i = begin + j
        if i >= len(samples):
            break
        t = j / SR
        env = math.exp(-t / (duration * 0.32))
        value = (
            math.sin(2 * math.pi * freq * t)
            + 0.35 * math.sin(2 * math.pi * freq * 2.01 * t)
            + 0.12 * math.sin(2 * math.pi * freq * 3.02 * t)
        )
        samples[i] += gain * env * value / 1.5


def play_note(samples, start, freq, duration, gain=1.0, shape="sine"):
    begin = int(start * SR)
    total = int(duration * SR)
    for j in range(total):
        i = begin + j
        if i >= len(samples):
            break
        t = j / SR
        env = min(1.0, t / 0.012) * math.exp(-t / (duration * 0.3))
        wave_value = math.sin(2 * math.pi * freq * t)
        if shape == "soft":
            wave_value = 0.7 * wave_value + 0.3 * math.sin(4 * math.pi * freq * t)
        samples[i] += gain * env * wave_value


def sfx_click():
    out = render_sfx(0.06)
    for j in range(len(out)):
        t = j / SR
        out[j] = 0.6 * math.exp(-t / 0.008) * math.sin(2 * math.pi * 1080 * t)
        out[j] += 0.12 * math.exp(-t / 0.003) * (random.random() * 2 - 1)
    return out


def sfx_collect():
    out = render_sfx(0.5)
    for k, name in enumerate(("C5", "E5", "G5")):
        bell(out, k * 0.07, midi_freq(note_midi(name)), 0.42, 0.8)
    return out


def sfx_success():
    out = render_sfx(1.1)
    for k, name in enumerate(("C5", "E5", "G5", "C6")):
        bell(out, k * 0.1, midi_freq(note_midi(name)), 0.9, 0.7)
    bell(out, 0.42, midi_freq(note_midi("E6")), 0.6, 0.3)
    return out


def sfx_interact():
    out = render_sfx(0.22)
    play_note(out, 0.0, midi_freq(note_midi("G4")), 0.16, 0.7)
    play_note(out, 0.07, midi_freq(note_midi("C5")), 0.16, 0.6)
    return out


def sfx_jump():
    out = render_sfx(0.26)
    for j in range(len(out)):
        t = j / SR
        freq = 300.0 + 420.0 * smoothstep(t / 0.18)
        env = min(1.0, t / 0.01) * math.exp(-t / 0.09)
        out[j] = 0.7 * env * math.sin(2 * math.pi * freq * t)
    return out


def sfx_wrong():
    out = render_sfx(0.42)
    play_note(out, 0.0, midi_freq(note_midi("E4")), 0.3, 0.55, "soft")
    play_note(out, 0.15, midi_freq(note_midi("C4")), 0.3, 0.5, "soft")
    return out


def sfx_throw():
    out = render_sfx(0.34)
    noise = 0.0
    for j in range(len(out)):
        t = j / SR
        noise += 0.18 * ((random.random() * 2 - 1) - noise)
        env = math.sin(math.pi * min(1.0, t / 0.28)) ** 2
        out[j] = 0.9 * noise * env
    return out


def sfx_deliver():
    out = render_sfx(0.75)
    bell(out, 0.0, midi_freq(note_midi("A4")), 0.65, 0.7)
    bell(out, 0.12, midi_freq(note_midi("E5")), 0.6, 0.6)
    return out


SFX = {
    "click": sfx_click,
    "collect": sfx_collect,
    "success": sfx_success,
    "interact": sfx_interact,
    "jump": sfx_jump,
    "wrong": sfx_wrong,
    "throw": sfx_throw,
    "deliver": sfx_deliver,
}


def main():
    music_dir = os.path.join(ROOT, "assets", "audio", "music")
    sfx_dir = os.path.join(ROOT, "assets", "audio", "sfx")
    for theme in THEMES:
        samples = render_theme(theme)
        write_wav(os.path.join(music_dir, "trilha_" + theme["id"] + ".wav"), samples, 0.55)
    for name, build in SFX.items():
        write_wav(os.path.join(sfx_dir, name + ".wav"), build(), 0.75)


if __name__ == "__main__":
    main()
