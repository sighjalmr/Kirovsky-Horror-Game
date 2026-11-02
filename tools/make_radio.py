#!/usr/bin/env python3
"""The night programme on the booth radio «Альпинист»: sounds/radio.wav.

A seamless loop of about a minute and a half, heard through a small
transistor set: a slow light-music waltz (our own tune, synthesised here),
the six pips of the time signal, the announcer of «Маяк» and the weather for
Sverdlovsk oblast. The announcer is spoken by Silero (ru v5, as in
make_voice.py); everything is band-limited to a 1980s pocket speaker with a
little hiss.

    pip install torch numpy
    curl -O https://models.silero.ai/models/tts/ru/v5_5_ru.pt
    python3 tools/make_radio.py v5_5_ru.pt

Writes sounds/radio.wav (44.1 kHz, 16 bit, mono) and its .import file.
"""

import os
import sys
import wave

import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "sounds")
sys.path.insert(0, os.path.join(ROOT, "tools"))
from make_sounds import IMPORT  # noqa: E402

ANNOUNCER = "kseniya"
SPEECH = [
    "Говорит «Маяк». Передаём лёгкую музыку.",
    "Погода. В Свердловской области ночью дождь, температура плюс три, плюс пять градусов. Ветер северо-западный, умеренный.",
    "Московское время ноль часов. В эфире «Маяк».",
]

# Our own waltz in A minor, 3/4 at 92 bpm: (MIDI note or None, beats).
TUNE = [
    (69, 2), (72, 1), (71, 2), (69, 1), (68, 3), (64, 3),
    (65, 2), (69, 1), (67, 2), (65, 1), (64, 6),
    (64, 2), (69, 1), (72, 2), (76, 1), (74, 3), (71, 3),
    (72, 2), (71, 1), (69, 2), (68, 1), (69, 6),
]
CHORDS = [(57, 60, 64), (52, 56, 59), (53, 57, 60), (52, 56, 59),
          (57, 60, 64), (50, 53, 57), (52, 56, 59), (57, 60, 64)]
BEAT = 60.0 / 92.0


def hz(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / attack) * np.exp(-t / decay)


def piano(n, dur, vol):
    m = int(dur * SR)
    t = np.arange(m) / SR
    f = hz(n)
    x = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in [(1, 1.0), (2, 0.35), (3, 0.12), (4, 0.06)])
    return x * env(m, 0.01, 0.9) * vol


def pad(chord, dur, vol):
    m = int(dur * SR)
    t = np.arange(m) / SR
    x = np.zeros(m)
    for n in chord:
        for det in (-0.12, 0.12):
            f = hz(n + 12) * 2 ** (det / 12)
            x += np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)
    a = np.minimum(1.0, t / 0.4) * np.minimum(1.0, (dur - t) / 0.4)
    return x * a * vol / len(chord)


def waltz(repeats=2):
    bars = sum(b for _, b in TUNE) // 3
    total = int(bars * 3 * BEAT * SR * repeats) + SR
    out = np.zeros(total)
    rng = np.random.default_rng(1988)
    pos = 0.0
    for _ in range(repeats):
        start = pos
        for n, beats in TUNE:
            if n is not None:
                p = piano(n, beats * BEAT + 0.6, 0.55)
                i = int(pos * SR)
                out[i:i + len(p)] += p[:total - i]
            pos += beats * BEAT
        for b in range(bars):
            t0 = start + b * 3 * BEAT
            ch = CHORDS[b % len(CHORDS)]
            p = pad(ch, 3 * BEAT, 0.18)
            i = int(t0 * SR)
            out[i:i + len(p)] += p[:total - i]
            bass = piano(ch[0] - 12, BEAT, 0.5)
            out[i:i + len(bass)] += bass[:total - i]
            for k in (1, 2):
                for root in ch[1:]:
                    c = piano(root, BEAT * 0.8, 0.12)
                    j = int((t0 + k * BEAT) * SR)
                    out[j:j + len(c)] += c[:total - j]
                br = rng.standard_normal(int(0.12 * SR)) * env(int(0.12 * SR), 0.002, 0.04) * 0.06
                j = int((t0 + k * BEAT) * SR)
                out[j:j + len(br)] += br[:total - j]
    return out[:int(pos * SR) + SR // 2]


def pips():
    out = []
    for k in range(6):
        d = 0.5 if k == 5 else 0.1
        t = np.arange(int(d * SR)) / SR
        out.append(np.sin(2 * np.pi * 1000 * t) * 0.5)
        if k < 5:
            out.append(np.zeros(int(0.9 * SR)))
    return np.concatenate(out)


def speak(model, text):
    import torch
    audio = model.apply_tts(text=text.replace("«", "").replace("»", ""), speaker=ANNOUNCER, sample_rate=48000)
    x = audio.numpy().astype(np.float64)
    idx = np.arange(0, len(x), 48000 / SR)
    return np.interp(idx, np.arange(len(x)), x) * 0.8


def bandpass(x, lo, hi):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    gain = 1 / np.sqrt(1 + (lo / np.maximum(f, 1)) ** 4) / np.sqrt(1 + (f / hi) ** 4)
    return np.fft.irfft(spec * gain, len(x))


def silence(s):
    return np.zeros(int(s * SR))


def main():
    import torch
    model = torch.package.PackageImporter(sys.argv[1]).load_pickle("tts_models", "model")
    music = waltz(2)
    half = len(music) // 2
    seq = [
        speak(model, SPEECH[0]), silence(0.6), music[:half], silence(0.8),
        speak(model, SPEECH[1]), silence(0.8), music[half:], silence(0.5),
        pips(), silence(0.3), speak(model, SPEECH[2]), silence(0.8),
    ]
    x = np.concatenate(seq)
    x = x / np.max(np.abs(x)) * 0.8
    # A pocket speaker: narrow band, a little breakup, hiss under it all.
    x = np.tanh(bandpass(x, 280, 3600) * 1.6)
    x += np.random.default_rng(7).standard_normal(len(x)) * 0.012
    # Crossfade the ends so the loop is seamless.
    fade = int(0.5 * SR)
    x[:fade] = x[:fade] * np.linspace(0, 1, fade) + x[-fade:] * np.linspace(1, 0, fade)
    x = x[:-fade]
    x = x / np.max(np.abs(x)) * 0.85
    path = os.path.join(OUT, "radio.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    imp = path + ".import"
    if not os.path.exists(imp):
        with open(imp, "w") as f:
            f.write(IMPORT.format(name="radio", loop=1))
    print("radio.wav", round(len(x) / SR, 1), "s")


if __name__ == "__main__":
    main()
