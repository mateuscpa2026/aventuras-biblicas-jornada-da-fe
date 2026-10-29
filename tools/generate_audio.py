"""Gera os áudios provisórios do jogo (WAV mono 16 bits, 22.05 kHz).

São sintetizados por código, sem amostras de terceiros, e existem apenas para
que música e efeitos funcionem até a substituição pelos arquivos definitivos.
Basta rodar `python tools/generate_audio.py` na raiz do projeto.

Música: 16 s em loop, acordes que se cruzam e emendam sem clique.
Efeitos: curtos, suaves, sem sons agressivos (público infantil).
"""

import math
import os
import random
import struct
import wave

SR = 22050
random.seed(7)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

NOTE_OFFSETS = {
    "C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
    "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11,
}


def note(name):
    pitch, octave = name[:-1], int(name[-1])
    semitones = NOTE_OFFSETS[pitch] + (octave + 1) * 12
    return 440.0 * 2.0 ** ((semitones - 69) / 12.0)


def smoothstep(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3.0 - 2.0 * x)


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


def render_music(chords, total=16.0, peak=0.55):
    count = int(SR * total)
    buffer = [0.0] * count
    segment = total / len(chords)
    length = segment * 1.6
    samples = int(length * SR)
    fade = 2.2
    sin = math.sin
    for index, chord in enumerate(chords):
        base = int(index * segment * SR)
        voices = []
        for name in chord:
            voices.append((note(name), 1.0))
        voices.append((note(chord[0]) / 2.0, 0.55))
        block = [0.0] * samples
        for freq, gain in voices:
            for mult, amp in ((1.0, 1.0), (2.0, 0.3), (3.0, 0.1), (5.0, 0.03)):
                step = 2.0 * math.pi * freq * mult / SR
                level = amp * gain
                for j in range(samples):
                    block[j] += level * sin(step * j)
        for j in range(samples):
            u = j / SR
            env = smoothstep(u / fade) * (1.0 - smoothstep((u - (length - fade - 0.8)) / fade))
            buffer[(base + j) % count] += block[j] * env
    return buffer


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
    for k, f in enumerate((note("C5"), note("E5"), note("G5"))):
        bell(out, k * 0.07, f, 0.42, 0.8)
    return out


def sfx_success():
    out = render_sfx(1.1)
    for k, name in enumerate(("C5", "E5", "G5", "C6")):
        bell(out, k * 0.1, note(name), 0.9, 0.7)
    bell(out, 0.42, note("E6"), 0.6, 0.3)
    return out


def sfx_interact():
    out = render_sfx(0.22)
    play_note(out, 0.0, note("G4"), 0.16, 0.7)
    play_note(out, 0.07, note("C5"), 0.16, 0.6)
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
    play_note(out, 0.0, note("E4"), 0.3, 0.55, "soft")
    play_note(out, 0.15, note("C4"), 0.3, 0.5, "soft")
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
    bell(out, 0.0, note("A4"), 0.65, 0.7)
    bell(out, 0.12, note("E5"), 0.6, 0.6)
    return out


MUSIC = {
    "menu": [["C3", "E3", "G3"], ["A2", "C3", "E3"], ["F2", "A2", "C3"], ["G2", "B2", "D3"]],
    "eden": [["D3", "F#3", "A3"], ["B2", "D3", "F#3"], ["G2", "B2", "D3"], ["A2", "C#3", "E3"]],
    "arca": [["G2", "B2", "D3"], ["E2", "G2", "B2"], ["C3", "E3", "G3"], ["D3", "F#3", "A3"]],
    "davi": [["D3", "A3", "D4"], ["C3", "G3", "C4"], ["A2", "E3", "A3"], ["G2", "D3", "G3"]],
    "moises": [["E3", "G3", "B3"], ["C3", "E3", "G3"], ["D3", "F#3", "A3"], ["B2", "D3", "F#3"]],
    "jesus": [["F3", "A3", "C4"], ["C3", "E3", "G3"], ["D3", "F3", "A3"], ["G2", "B2", "D3"]],
}

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
    for name, chords in MUSIC.items():
        write_wav(os.path.join(music_dir, "trilha_" + name + ".wav"), render_music(chords), 0.5)
    for name, build in SFX.items():
        write_wav(os.path.join(sfx_dir, name + ".wav"), build(), 0.75)


if __name__ == "__main__":
    main()
