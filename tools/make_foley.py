#!/usr/bin/env python3
"""Builds the footsteps and the attack sounds of «Кировский: Закрытие» from
real recordings in sounds/src/ (authors and licences in sounds/src/CREDITS.md):
cuts single steps out of a walking take, pitches and filters them into the
guard's walk, run and creep and the killer's heavy boots, and layers wet meat
hits, torn cloth, a cry and a falling body into the cleaver blows and the death.
Writes sounds/*.wav (44.1 kHz, 16 bit, mono) like tools/make_sounds.py.

    python3 tools/make_foley.py             # all sounds
    python3 tools/make_foley.py chop hurt   # some of them

Needs Python 3, numpy and ffmpeg (to read the .ogg sources).
"""

import os
import subprocess
import sys

import numpy as np

from make_sounds import ROOT, SR, Gen, band, env, modal, norm, place, save

SRC = os.path.join(ROOT, "sounds", "src")
_cache = {}


def load(name):
    """A source recording as mono float at SR, peak 1."""
    if name not in _cache:
        raw = subprocess.run(["ffmpeg", "-v", "error", "-i", os.path.join(SRC, name + ".ogg"),
                              "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                             capture_output=True, check=True).stdout
        _cache[name] = norm(np.frombuffer(raw, np.float32).astype(float), 1.0)
    return _cache[name]


def cut(x, a, b, fade_in=0.003, fade_out=0.03):
    y = x[int(a * SR):int(b * SR)].copy()
    n, m = int(fade_in * SR), int(fade_out * SR)
    y[:n] *= np.linspace(0, 1, n)
    y[-m:] *= np.linspace(1, 0, m)
    return y


def pitch(x, r):
    """Tape-style: r > 1 is higher and shorter, r < 1 lower and longer."""
    return np.interp(np.arange(0, len(x) - 1, r), np.arange(len(x)), x)


def pad(x, seconds):
    n = int(seconds * SR)
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]


def onsets(x, quiet=0.15, thresh=0.06):
    """Starts of separate events: the level jumps after `quiet` seconds of near silence."""
    hop = int(0.005 * SR)
    e = np.array([np.abs(x[i:i + hop]).max() for i in range(0, len(x) - hop, hop)])
    out, last = [], -1e9
    for i, v in enumerate(e):
        if v > thresh and (i - last) * 0.005 > quiet and e[max(0, i - int(quiet / 0.005)):i].max(initial=0) < thresh:
            out.append(i * 0.005)
        if v > thresh:
            last = i
    return out


def kenney_steps():
    """The twelve steps of the walking take, each heel and toe, ~0.3 s."""
    x = load("kenney_walking")
    at = [a for a in onsets(x) if a + 0.2 < len(x) / SR]  # the take ends on half a step
    steps = []
    for k, a in enumerate(at):
        b = min(at[k + 1] - 0.01 if k + 1 < len(at) else len(x) / SR, a + 0.34)
        steps.append(norm(cut(x, max(a - 0.004, 0), b), 1.0))
    return steps


# --- the guard -------------------------------------------------------------------

def step(name, i):
    """Gordeev walking in his work shoes on the hall's tile: the recorded step
    as it is, with a slight tilt so no two takes sound alike."""
    g = Gen(name)
    x = kenney_steps()[i % 12]
    x = pitch(x, g.rng.uniform(0.96, 1.03))
    x = band(x, 45, g.rng.uniform(11000, 16000))
    save(name, pad(x, 0.4), 0.85)


def run(name, i):
    """Running: the heel lands harder, the sole scuffs on the grit as it pushes off."""
    g = Gen(name)
    x = kenney_steps()[(i * 5 + 3) % 12]
    x = pitch(x, g.rng.uniform(1.02, 1.07))
    x = np.tanh(x * 1.8) / np.tanh(1.8)  # a firmer strike
    x = pad(x, 0.4)
    scuff = band(g.noise(0.07), 2500, 9000) * env(g.t(0.07), 0.012, 0.02)
    place(x, scuff * 0.25, g.rng.uniform(0.07, 0.1))
    x += modal(g.t(0.4), [(g.rng.uniform(85, 110), 0.035, 0.35)])  # body weight
    save(name, x, 0.9)


def creep(name, i):
    """Crouching: the heel barely touches, the step rolls onto the toe, the
    trousers rustle."""
    g = Gen(name)
    x = kenney_steps()[(i * 7 + 1) % 12]
    x = pitch(x, g.rng.uniform(0.97, 1.01))
    n = int(0.05 * SR)
    x[:n] *= np.linspace(0.25, 1, n)
    x = band(x, 60, 3500)
    x = pad(x, 0.5)
    rustle = band(g.noise(0.35), 600, 5000) * np.sin(np.pi * g.t(0.35) / 0.35) ** 2
    place(x, rustle * 0.06, 0.0)
    save(name, x, 0.6)


# --- the killer --------------------------------------------------------------------

def heavy_step(name, i):
    """A big man in rubber boots: the step pitched down and dulled, a concrete
    thump under it for the weight, a squeak of rubber as the sole twists."""
    g = Gen(name)
    x = pitch(kenney_steps()[(i * 5) % 12], g.rng.uniform(0.78, 0.84))
    x = band(x, 40, 5000)
    x = pad(x, 0.5)
    thump = band(load("erdie_concrete_%d" % (i % 3 + 1)), 30, 1500)
    place(x, norm(thump, 0.8), 0.0)
    sq = np.sin(2 * np.pi * np.cumsum(np.linspace(g.rng.uniform(800, 1000), 1300, int(0.05 * SR))) / SR)
    place(x, sq * env(g.t(0.05), 0.01, 0.015) * 0.05, g.rng.uniform(0.1, 0.14))
    save(name, x, 0.9)


# --- the attack ----------------------------------------------------------------------

GORE = ((0.0, 0.42), (0.95, 1.35), (1.42, 1.85))


def chop(name, i):
    """A cleaver blow landing: the blade parts the coat (torn cloth), sinks in
    with a wet heavy hit, a bone gives under it."""
    g = Gen(name)
    t = g.t(0.9)
    x = np.zeros_like(t)
    a, b = GORE[i % 3]
    place(x, cut(load("thefitzyg_goresplat"), a, b, 0.001, 0.12) * 0.9, 0.0)
    rip = load("altfuture_rip_%d" % (i % 4 + 1))
    place(x, pitch(rip, 0.9) * 0.45, 0.0)
    x += modal(t, [(g.rng.uniform(55, 70), 0.09, 1.1), (g.rng.uniform(90, 110), 0.05, 0.5)])
    crunch = np.zeros(int(0.1 * SR))
    idx = g.rng.integers(0, len(crunch), 70)
    crunch[idx] = g.rng.standard_normal(70)
    crunch = band(crunch, 400, 4000) * env(g.t(0.1), 0.001, 0.03) * 5
    place(x, crunch, 0.004)
    save(name, x, 0.97)


CRY = ((0.56, 0.84), (0.93, 1.18), (1.24, 1.48))


def hurt(name, i):
    """Gordeev, an old man, gasping as the blow lands: a short sob from the
    recording, lowered to an older voice, with the breath knocked out after it."""
    g = Gen(name)
    a, b = CRY[i % 3]
    v = pitch(cut(load("scottemoil_male_cry"), a, b, 0.01, 0.08), 0.86)
    v = band(v, 90, 7000)
    x = pad(v, 0.9)
    exhale = band(g.noise(0.4), 300, 2500) * env(g.t(0.4), 0.02, 0.12)
    place(x, exhale * 0.18, len(v) / SR - 0.03)
    save(name, x, 0.8)


def death_scream(name):
    """The last blow: the cry rises and chokes off in the throat."""
    g = Gen(name)
    v = pitch(cut(load("niron3206_scream"), 0.12, 1.25, 0.01, 0.25), 0.8)
    v = band(v, 90, 9000)
    x = pad(v, 2.0)
    gurgle = band(cut(load("thefitzyg_goresplat"), 1.9, 2.6, 0.05, 0.2), 100, 1200)
    place(x, norm(gurgle, 0.25), len(v) / SR - 0.15)
    rattle = band(g.noise(0.6), 200, 1200) * env(g.t(0.6), 0.05, 0.2)
    rattle *= 0.5 + 0.5 * np.sin(2 * np.pi * 28 * g.t(0.6))
    place(x, rattle * 0.12, len(v) / SR + 0.1)
    save(name, x, 0.9)


def bodyfall(name):
    """Gordeev going down on the tile: the body, then an arm and the torch."""
    x = np.zeros(int(1.3 * SR))
    place(x, load("rottako_heavy_drop_1"), 0.0)
    place(x, band(load("rottako_heavy_drop_2"), 60, 6000) * 0.55, 0.16)
    save(name, band(x, 35, 12000), 0.95)


ALL = {"death_scream": death_scream, "bodyfall": bodyfall}
for _i in range(12):
    ALL["step_%d" % (_i + 1)] = lambda n, i=_i: step(n, i)
for _i in range(6):
    ALL["run_%d" % (_i + 1)] = lambda n, i=_i: run(n, i)
    ALL["creep_%d" % (_i + 1)] = lambda n, i=_i: creep(n, i)
    ALL["heavy_step_%d" % (_i + 1)] = lambda n, i=_i: heavy_step(n, i)
for _i in range(3):
    ALL["chop_%d" % (_i + 1)] = lambda n, i=_i: chop(n, i)
    ALL["hurt_%d" % (_i + 1)] = lambda n, i=_i: hurt(n, i)


if __name__ == "__main__":
    want = sys.argv[1:]
    for nm, f in ALL.items():
        if not want or nm in want or nm.rsplit("_", 1)[0] in want:
            f(nm)
            print("made", nm)
