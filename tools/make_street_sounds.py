#!/usr/bin/env python3
"""Sounds of the street scenes (the cutscenes) into sounds/*.wav: rain on the
square, rain drumming on a car roof, a Zhiguli engine pulling, its wiper, the
door slamming, and the till printing the receipt of 7 October.
Same format and helpers as make_sounds.py.

    python3 tools/make_street_sounds.py
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_sounds as ms  # noqa: E402
from make_sounds import SR, band, env, modal, place, save, Gen  # noqa: E402

ms.LOOPS |= {"rain", "rain_car", "engine_drive"}


def drops(g, seconds, rate, lo, hi, decay=0.004, loop=True):
    """Single drops: short filtered clicks at random times."""
    n = int(seconds * SR)
    x = np.zeros(n)
    count = int(seconds * rate)
    clip_t = np.arange(int(0.03 * SR)) / SR
    for _ in range(count):
        at = g.rng.random() * seconds
        c = band(g.rng.standard_normal(len(clip_t)), lo * (0.7 + g.rng.random() * 0.6), hi) * env(clip_t, 0.0005, decay)
        c *= 0.3 + g.rng.random() ** 2
        i = int(at * SR)
        j = min(n, i + len(c))
        x[i:j] += c[:j - i]
        if loop and i + len(c) > n:
            x[:i + len(c) - n] += c[n - i:]
    return x


def rain(name):
    """Steady autumn rain on asphalt and puddles: a wide hiss, a low wash,
    thousands of small drops, now and then a fat one off a gutter. Loops."""
    g = Gen(name)
    t = g.t(8.0)
    x = band(g.noise(8.0), 900, 9000, True) * 0.5
    x += band(g.noise(8.0), 120, 700, True) * 0.25 * (1 + 0.15 * np.sin(2 * np.pi * t / 8.0))
    x += drops(g, 8.0, 900, 1500, 7000) * 0.6
    x += drops(g, 8.0, 3, 300, 1600, 0.02) * 1.5
    save(name, x, 0.6)


def rain_car(name):
    """Inside the car: rain drumming on the roof and the windscreen, the
    engine low under it. Loops."""
    g = Gen(name)
    t = g.t(6.0)
    x = drops(g, 6.0, 500, 250, 2200, 0.012) * 1.2
    x += band(g.noise(6.0), 200, 1800, True) * 0.25
    f = 30.0
    ph = 2 * np.pi * f * t
    for k, a in ((1, 0.5), (2, 0.35), (4, 0.12)):
        x += a * np.sin(k * ph) * 0.4
    save(name, x, 0.55)


def engine_drive(name):
    """The 2106 in second gear across the square: a faster, rougher firing
    (~45 Hz), the gearbox whine, tyres hissing through water. Loops."""
    g = Gen(name)
    t = g.t(4.0)
    f = 45.0
    ph = 2 * np.pi * f * np.cumsum(1 + 0.015 * np.sin(2 * np.pi * 0.5 * t)) / SR
    x = np.zeros_like(t)
    for k, a in ((1, 1.0), (2, 0.7), (3, 0.35), (4, 0.3), (6, 0.12)):
        x += a * np.sin(k * ph + k)
    x += band(g.noise(4.0), 60, 500, True) * (0.5 + 0.5 * np.sin(ph)) ** 4
    x += np.sin(2 * np.pi * 520 * t) * 0.03
    x += band(g.noise(4.0), 2000, 9000, True) * 0.35  # wet tyres
    x = band(x, 25, 9000, True)
    save(name, x, 0.7)


def wiper(name):
    """One sweep of the wiper: rubber dragging on wet glass and the soft knock
    of the arm at the end."""
    g = Gen(name)
    t = g.t(0.9)
    squeak = np.sin(2 * np.pi * (700 + 200 * np.sin(2 * np.pi * 1.1 * t)) * t) * 0.15
    drag = band(g.noise(0.9), 400, 3000) * 0.6 + squeak
    drag *= np.sin(np.pi * np.clip(t / 0.75, 0, 1)) ** 0.7
    x = drag + modal(t, [(120, 0.04, 0.8), (340, 0.03, 0.3)], 0.78)
    save(name, x, 0.6)


def car_door(name):
    """The Zhiguli's door slammed: a hollow tinny thud, the latch, glass
    rattling in the frame."""
    g = Gen(name)
    t = g.t(0.8)
    x = modal(t, [(85, 0.09, 1.0), (160, 0.07, 0.7), (410, 0.05, 0.35), (980, 0.03, 0.2)])
    x += band(g.noise(0.8), 200, 3000) * env(t, 0.001, 0.02) * 1.2
    place(x, modal(g.t(0.1), [(2600, 0.01, 0.5), (4100, 0.008, 0.3)]), 0.012)
    x += band(g.noise(0.8), 2500, 7000) * env(t - 0.02, 0.003, 0.08) * 0.15 * (t > 0.02)
    save(name, x, 0.85)


def printer(name):
    """The cash register printing the receipt: the motor, fast hammering of
    the print wheel in bursts line by line, the paper torn off."""
    g = Gen(name)
    t = g.t(2.2)
    x = np.zeros_like(t)
    x += band(g.noise(2.2), 300, 1500) * 0.05 * (t < 1.7)
    for line in range(6):
        t0 = 0.12 + line * 0.24
        for k in range(10):
            at = t0 + k * 0.013 + g.rng.random() * 0.002
            place(x, modal(g.t(0.03), [(1800 + g.rng.random() * 400, 0.004, 0.6), (3900, 0.003, 0.3)]), at)
        place(x, modal(g.t(0.1), [(220, 0.03, 0.6), (700, 0.02, 0.2)]), t0 + 0.17)  # line feed
    tear = band(g.noise(0.25), 1200, 8000) * env(g.t(0.25), 0.01, 0.07)
    place(x, tear, 1.85)
    save(name, x, 0.7)


ALL = {"rain": rain, "rain_car": rain_car, "engine_drive": engine_drive, "wiper": wiper, "car_door": car_door,
       "printer": printer}

if __name__ == "__main__":
    for nm in sys.argv[1:] or list(ALL):
        ALL[nm](nm)
        print("made", nm)
