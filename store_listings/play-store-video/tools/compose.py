"""An original, calm "sunrise" track for the Atlas promo video.

Pure standard library: pads, a bell arpeggio and a soft sub, written as a dry
16-bit stereo WAV. ffmpeg adds the room (echo taps) and loudness afterwards.
Usage: python compose.py out.wav [seconds]
"""

import math
import random
import struct
import sys
import wave

SR = 32000
OUT = sys.argv[1]
LENGTH = float(sys.argv[2]) if len(sys.argv) > 2 else 90.0
BPM = 72
BEAT = 60 / BPM
BAR = 4 * BEAT
N = int(LENGTH * SR)
L = [0.0] * N
R = [0.0] * N
random.seed(7)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# Two bars per chord. MIDI notes: pad voicing, bass root, arpeggio pool.
C, A, F, G = 48, 45, 41, 43
PROGRESSION = [
    ([60, 64, 67, 71, 74], C, [72, 76, 79, 83, 86]),   # Cmaj9
    ([57, 60, 64, 67, 71], A, [69, 72, 76, 79, 83]),   # Am9
    ([53, 57, 60, 64, 67], F, [69, 72, 76, 79, 84]),   # Fmaj9
    ([55, 59, 62, 64, 67], G, [71, 74, 76, 79, 83]),   # G6(add9)
]
CHORD_LEN = 2 * BAR


def add(start, dur, freq, amp, pan, attack, release, partials, detune=0.0):
    """One voice with a smooth attack/release envelope and a few partials."""
    s0 = int(start * SR)
    n = int((dur + release) * SR)
    a_n, r_start, r_n = int(attack * SR), int(dur * SR), max(1, int(release * SR))
    gl, gr = math.cos(pan * math.pi / 2), math.sin(pan * math.pi / 2)
    w = [2 * math.pi * freq * k * (1 + detune * (k - 1)) / SR for k, _ in partials]
    for i in range(n):
        j = s0 + i
        if j >= N:
            break
        if i < a_n:
            env = math.sin(0.5 * math.pi * i / a_n) ** 2
        elif i < r_start:
            env = 1.0
        else:
            env = max(0.0, 1 - (i - r_start) / r_n) ** 2
        v = 0.0
        for (k, pa), wk in zip(partials, w):
            v += pa * math.sin(wk * i)
        v *= amp * env
        L[j] += v * gl
        R[j] += v * gr


def bell(start, freq, amp, pan):
    """A soft struck bell: fast attack, exponential decay, inharmonic shimmer."""
    s0 = int(start * SR)
    n = int(3.2 * SR)
    gl, gr = math.cos(pan * math.pi / 2), math.sin(pan * math.pi / 2)
    w1, w2, w3 = (2 * math.pi * freq * m / SR for m in (1.0, 2.0, 3.01))
    for i in range(n):
        j = s0 + i
        if j >= N:
            break
        t = i / SR
        env = min(1.0, i / (0.006 * SR)) * math.exp(-t * 1.6)
        v = amp * env * (math.sin(w1 * i) + 0.32 * math.exp(-t * 2.5) * math.sin(w2 * i)
                         + 0.12 * math.exp(-t * 4) * math.sin(w3 * i))
        L[j] += v * gl
        R[j] += v * gr


PAD = [(1, 1.0), (2, 0.28), (3, 0.10)]
SUB = [(1, 1.0), (2, 0.15)]
t, idx = 0.0, 0
while t < LENGTH:
    pad, root, pool = PROGRESSION[idx % len(PROGRESSION)]
    for v, note in enumerate(pad):
        # Two slightly detuned layers per note give the pad its slow chorus.
        add(t, CHORD_LEN, hz(note), 0.030, 0.25 + 0.5 * v / (len(pad) - 1), 1.8, 2.2, PAD, 0.0)
        add(t, CHORD_LEN, hz(note) * 1.003, 0.020, 0.75 - 0.5 * v / (len(pad) - 1), 2.2, 2.2, PAD, 0.0)
    add(t, CHORD_LEN, hz(root), 0.085, 0.5, 1.2, 1.8, SUB)
    # The arpeggio enters after the first chord and thins out near the end.
    if t >= CHORD_LEN and t < LENGTH - 6:
        steps = int(CHORD_LEN / (BEAT / 2))
        for s in range(steps):
            if random.random() < 0.72:
                note = pool[(s * 2 + idx) % len(pool)] if s % 4 else pool[0]
                bell(t + s * BEAT / 2 + random.uniform(-0.008, 0.008), hz(note),
                     0.050 if s % 4 == 0 else 0.034, 0.3 + 0.4 * random.random())
    t += CHORD_LEN
    idx += 1

# Gentle fades, then normalise and write.
fade_in, fade_out = int(2.5 * SR), int(5.0 * SR)
for i in range(fade_in):
    g = (i / fade_in) ** 2
    L[i] *= g
    R[i] *= g
for i in range(fade_out):
    g = (i / fade_out) ** 2
    L[N - 1 - i] *= g
    R[N - 1 - i] *= g
peak = max(max(abs(x) for x in L), max(abs(x) for x in R)) or 1.0
scale = 0.85 / peak
with wave.open(OUT, "wb") as wf:
    wf.setnchannels(2)
    wf.setsampwidth(2)
    wf.setframerate(SR)
    frames = bytearray()
    for a, b in zip(L, R):
        frames += struct.pack("<hh", int(a * scale * 32767), int(b * scale * 32767))
    wf.writeframes(bytes(frames))
print("wrote", OUT, round(LENGTH, 1), "s")
