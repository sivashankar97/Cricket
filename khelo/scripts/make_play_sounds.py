"""Generates the Play tab sound effects into assets/sounds/ (mono 16-bit WAV).

Run from khelo/: python3 scripts/make_play_sounds.py
All sounds are synthesised here, so there are no licensing questions.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.85 / peak
    with wave.open(os.path.join(OUT, name), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, s * scale)) * 32767))
            for s in samples))


def env(i, n, attack=0.005, release=None):
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    if release is None:
        return a
    return a * math.exp(-t / release)


def lowpass(samples, alpha):
    out, prev = [], 0.0
    for s in samples:
        prev = prev + alpha * (s - prev)
        out.append(prev)
    return out


rnd = random.Random(7)


def bat():
    n = int(RATE * 0.22)
    out = []
    for i in range(n):
        t = i / RATE
        knock = math.sin(2 * math.pi * 820 * t) * 0.6 + math.sin(2 * math.pi * 1430 * t) * 0.3
        wood = math.sin(2 * math.pi * 260 * t) * 0.5
        click = rnd.uniform(-1, 1) * math.exp(-t / 0.004)
        out.append((knock + wood) * env(i, n, 0.001, 0.035) + click * 0.8)
    return out


def crowd(seconds=2.2, swell=0.35):
    n = int(RATE * seconds)
    noise = lowpass([rnd.uniform(-1, 1) for _ in range(n)], 0.18)
    out = []
    for i in range(n):
        t = i / RATE
        shape = min(1.0, t / swell) * (1 if t < seconds - 0.9 else max(0.0, (seconds - t) / 0.9))
        flutter = 0.75 + 0.25 * math.sin(2 * math.pi * 5.5 * t + math.sin(2 * math.pi * 0.7 * t))
        out.append(noise[i] * shape * flutter)
    return out


def wicket():
    n = int(RATE * 0.7)
    out = [0.0] * n
    for start, freq in [(0.0, 1900), (0.05, 2300), (0.11, 1700), (0.19, 2600)]:
        s = int(start * RATE)
        for i in range(s, n):
            t = (i - s) / RATE
            out[i] += math.sin(2 * math.pi * freq * t) * math.exp(-t / 0.03) * 0.5
            out[i] += rnd.uniform(-1, 1) * math.exp(-t / 0.006) * 0.4
    for i in range(n):
        t = i / RATE
        out[i] += math.sin(2 * math.pi * 90 * t) * math.exp(-t / 0.12) * 0.6
    return out


def coin():
    n = int(RATE * 0.9)
    out = []
    for i in range(n):
        t = i / RATE
        ring = sum(math.sin(2 * math.pi * f * t) * a for f, a in [(2637, 0.6), (3520, 0.35), (5274, 0.2)])
        out.append(ring * env(i, n, 0.002, 0.25))
    return out


def tick(freq=880, length=0.12):
    n = int(RATE * length)
    return [math.sin(2 * math.pi * freq * i / RATE) * env(i, n, 0.002, 0.04) for i in range(n)]


def fanfare():
    notes = [(523.25, 0.14), (659.25, 0.14), (783.99, 0.14), (1046.5, 0.5)]
    out = []
    for freq, length in notes:
        n = int(RATE * length)
        for i in range(n):
            t = i / RATE
            tone = math.sin(2 * math.pi * freq * t) + 0.4 * math.sin(2 * math.pi * freq * 2 * t)
            out.append(tone * env(i, n, 0.01, length * 0.8))
    return out


def lose():
    notes = [(392.0, 0.22), (349.23, 0.22), (293.66, 0.6)]
    out = []
    for freq, length in notes:
        n = int(RATE * length)
        for i in range(n):
            t = i / RATE
            out.append(math.sin(2 * math.pi * freq * t) * env(i, n, 0.01, length * 0.7))
    return out


write('bat_hit.wav', bat())
write('crowd_cheer.wav', crowd())
write('crowd_roar.wav', crowd(3.0, 0.2))
write('wicket.wav', wicket())
write('coin.wav', coin())
write('countdown.wav', tick(880))
write('go.wav', tick(1320, 0.3))
write('win.wav', fanfare())
write('lose.wav', lose())
print('sounds written to', os.path.normpath(OUT))
