#!/usr/bin/env python3
"""Synthesises Valo-skin's UI sounds into assets/sounds/ (original, pure Python, no samples).

lockin  agent lock-in: sub thump, rising sweep, bright ping
plant   spike planted: two arming beeps over a low hum
defuse  spike defused: descending chime
fail    defuse failed: short low buzz
banner  kill banner: metallic double ping
tick    UI tick for selections
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def silence(sec):
    return [0.0] * int(sec * RATE)


def env(n, attack, release, shape=3.0):
    a = max(1, int(attack * RATE))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            t = (i - a) / max(1, n - a)
            out.append((1 - t) ** shape if release else 1.0)
    return out


def tone(freq, sec, amp=1.0, attack=0.004, shape=3.0, sweep_to=None, partials=((1, 1.0),)):
    n = int(sec * RATE)
    e = env(n, attack, True, shape)
    out, phase = [], [0.0] * len(partials)
    for i in range(n):
        f = freq if sweep_to is None else freq * (sweep_to / freq) ** (i / n)
        s = 0.0
        for k, (mult, gain) in enumerate(partials):
            phase[k] += 2 * math.pi * f * mult / RATE
            s += math.sin(phase[k]) * gain
        out.append(s * amp * e[i])
    return out


def noise(sec, amp=1.0, shape=6.0, seed=1):
    rnd = random.Random(seed)
    n = int(sec * RATE)
    e = env(n, 0.001, True, shape)
    out, prev = [], 0.0
    for i in range(n):
        prev = prev * 0.6 + rnd.uniform(-1, 1) * 0.4  # gentle low-pass
        out.append(prev * amp * e[i])
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * RATE) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * length
    for t, o in zip(tracks, offsets):
        start = int(o * RATE)
        for i, v in enumerate(t):
            out[start + i] += v
    return out


def write(name, samples, peak_db=-3.0):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 10 ** (peak_db / 20) / peak
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))
    print("wrote", OUT / f"{name}.wav")


def main():
    bell = ((1, 1.0), (2.76, 0.35), (5.4, 0.12))
    metal = ((1, 1.0), (1.58, 0.6), (2.31, 0.3))

    write("lockin", mix(
        tone(70, 0.45, 1.0, shape=4),                       # sub thump
        noise(0.12, 0.35, seed=3),                          # impact
        tone(380, 0.28, 0.35, sweep_to=1250, shape=1.5),    # rising sweep
        tone(1760, 0.5, 0.5, partials=bell, shape=5),       # ping
        offsets=[0, 0, 0.02, 0.24]))

    beep = tone(1046, 0.09, 0.8, attack=0.002, shape=0.6, partials=((1, 1.0), (3, 0.15)))
    write("plant", mix(
        tone(110, 0.9, 0.25, attack=0.05, shape=1.2, partials=((1, 1.0), (2, 0.4))),
        beep, beep, tone(1396, 0.16, 0.8, attack=0.002, shape=2, partials=((1, 1.0), (3, 0.15))),
        offsets=[0, 0.08, 0.3, 0.52]))

    write("defuse", mix(
        tone(1318, 0.5, 0.7, partials=bell, shape=4),
        tone(988, 0.55, 0.7, partials=bell, shape=4),
        tone(659, 0.9, 0.8, partials=bell, shape=3),
        offsets=[0, 0.11, 0.22]))

    write("fail", mix(
        tone(140, 0.28, 0.8, attack=0.004, shape=1.0, partials=((1, 1.0), (3, 0.33), (5, 0.2), (7, 0.14))),
        tone(105, 0.3, 0.6, attack=0.004, shape=1.0, partials=((1, 1.0), (3, 0.33), (5, 0.2))),
        offsets=[0, 0.12]))

    write("banner", mix(
        tone(1500, 0.22, 0.8, attack=0.001, shape=6, partials=metal),
        tone(2250, 0.3, 0.6, attack=0.001, shape=6, partials=metal),
        noise(0.03, 0.3, seed=9),
        offsets=[0, 0.07, 0]))

    write("tick", mix(tone(2600, 0.025, 0.6, attack=0.0005, shape=8), noise(0.01, 0.4, seed=5)))


if __name__ == "__main__":
    main()
