#!/usr/bin/env python3
"""Draws the textures of the inside of Gordeev's ВАЗ-2106 for the shots from
the driver's seat: the instrument cluster (speedometer to 180, tachometer
with the red zone from 6, fuel and temperature), the middle of the dash
(the clock, the «Урал» radio, the heater sliders), and the seat cloth.
Writes textures/car_*.png next to the store's own.

    python3 tools/make_cabin.py            # all of them
    python3 tools/make_cabin.py car_gauges # some of them

Uses the canvas and helpers of make_textures.py (numpy, Pillow, DejaVu fonts).
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_textures as mt  # noqa: E402
from make_textures import T, font, rgb8  # noqa: E402

WHITE = (0.92, 0.92, 0.86)
RED = (0.85, 0.15, 0.08)
NEEDLE = (0.95, 0.5, 0.15)


def dial(d, cx, cy, r, a0, a1, marks, labels, title, needle_at, red_from=None, minor=0):
    """A round black dial: ticks from angle a0 to a1 (degrees, clockwise from
    up), numbers, a title, the needle at fraction `needle_at`."""
    d.ellipse((cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6), fill=(150, 150, 145, 255))  # chrome ring
    d.ellipse((cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2), fill=(30, 30, 30, 255))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(12, 12, 12, 255))
    n = (marks - 1) * (minor + 1) + 1
    for i in range(n):
        f = i / (n - 1)
        a = math.radians(a0 + (a1 - a0) * f)
        major = i % (minor + 1) == 0
        l0 = r * (0.78 if major else 0.85)
        col = rgb8(RED if red_from is not None and f >= red_from else WHITE)
        d.line([(cx + math.sin(a) * l0, cy - math.cos(a) * l0), (cx + math.sin(a) * r * 0.94, cy - math.cos(a) * r * 0.94)],
               fill=col, width=4 if major else 2)
    for i, lab in enumerate(labels):
        f = i / (len(labels) - 1)
        a = math.radians(a0 + (a1 - a0) * f)
        col = rgb8(RED if red_from is not None and f >= red_from else WHITE)
        d.text((cx + math.sin(a) * r * 0.62, cy - math.cos(a) * r * 0.62), lab, font=font(max(11, int(r * 0.15)), True, False, True),
               fill=col, anchor="mm")
    d.text((cx, cy + r * 0.3), title, font=font(max(9, int(r * 0.1)), False, False, True), fill=rgb8(WHITE), anchor="mm")
    a = math.radians(a0 + (a1 - a0) * needle_at)
    d.line([(cx - math.sin(a) * r * 0.15, cy + math.cos(a) * r * 0.15), (cx + math.sin(a) * r * 0.86, cy - math.cos(a) * r * 0.86)],
           fill=rgb8(NEEDLE), width=max(3, int(r * 0.045)))
    d.ellipse((cx - r * 0.09, cy - r * 0.09, cx + r * 0.09, cy + r * 0.09), fill=(25, 25, 25, 255))


def gauges(name):
    """The cluster (1024×256): speedometer and tachometer, between them fuel
    and coolant temperature, the warning lamps and the odometer."""
    t = T(1024, 256, (0.03, 0.03, 0.03), name)
    img, d = t.layer()
    dial(d, 150, 128, 112, -135, 135, 10, ["0", "20", "40", "60", "80", "100", "120", "140", "160", "180"], "км/ч", 0.22,
         minor=1)
    d.rectangle((120, 192, 180, 208), fill=(20, 20, 20, 255))
    d.text((150, 200), "047312", font=font(12, True, False, True), fill=rgb8(WHITE), anchor="mm")
    dial(d, 874, 128, 112, -135, 135, 9, ["0", "1", "2", "3", "4", "5", "6", "7", "8"], "об/мин x1000", 0.24,
         red_from=0.74, minor=1)
    dial(d, 390, 128, 70, -60, 60, 3, ["0", "1/2", "1"], "ТОПЛИВО", 0.3, minor=1)
    dial(d, 634, 128, 70, -60, 60, 3, ["50", "90", "130"], "°C", 0.45, red_from=0.85, minor=1)
    # Warning lamps in a row between the small dials.
    for i, c in enumerate([(0.2, 0.7, 0.2), (0.85, 0.2, 0.1), (0.9, 0.6, 0.1), (0.2, 0.35, 0.9), (0.85, 0.2, 0.1)]):
        x = 452 + i * 30
        d.ellipse((x - 9, 220, x + 9, 238), fill=rgb8(tuple(v * 0.35 for v in c)))
    t.over(img)
    t.grain(0.01)
    t.save(name)


def console(name):
    """The middle of the dash (512×256): the round clock (22:20), the radio
    «Урал-авто» with its tuning scale and two knobs, the heater sliders."""
    t = T(512, 256, (0.06, 0.06, 0.055), name)
    img, d = t.layer()
    # clock
    cx, cy, r = 80, 80, 58
    d.ellipse((cx - r - 5, cy - r - 5, cx + r + 5, cy + r + 5), fill=(150, 150, 145, 255))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(14, 14, 14, 255))
    for i in range(12):
        a = math.radians(i * 30)
        d.line([(cx + math.sin(a) * r * 0.8, cy - math.cos(a) * r * 0.8), (cx + math.sin(a) * r * 0.95, cy - math.cos(a) * r * 0.95)],
               fill=rgb8(WHITE), width=4 if i % 3 == 0 else 2)
    for a_deg, ln, w in ((22 * 30 + 20 * 0.5, 0.5, 5), (20 * 6, 0.82, 3)):
        a = math.radians(a_deg)
        d.line([(cx, cy), (cx + math.sin(a) * r * ln, cy - math.cos(a) * r * ln)], fill=rgb8(WHITE), width=w)
    d.text((cx, cy + 30), "СДЕЛАНО В СССР", font=font(8, False, False, True), fill=rgb8(WHITE), anchor="mm")
    # radio
    d.rectangle((160, 20, 500, 140), fill=(25, 25, 25, 255), outline=(140, 140, 135, 255), width=3)
    d.rectangle((210, 40, 450, 80), fill=(30, 28, 20, 255))
    for i in range(25):
        x = 215 + i * 9.6
        d.line([(x, 70), (x, 76 if i % 5 else 62)], fill=rgb8(WHITE), width=1)
    for i, f in enumerate(["ДВ", "СВ", "КВ"]):
        d.text((222 + i * 80, 50), f, font=font(12, True, False, True), fill=rgb8(WHITE), anchor="mm")
    d.line([(318, 42), (318, 78)], fill=rgb8(RED), width=2)
    d.text((330, 112), "УРАЛ-АВТО", font=font(18, True, False, True), fill=(190, 185, 170, 255), anchor="mm")
    for x in (185, 475):
        d.ellipse((x - 18, 92, x + 18, 128), fill=(10, 10, 10, 255), outline=(120, 120, 115, 255), width=2)
    # heater sliders
    d.rectangle((40, 170, 470, 236), fill=(20, 20, 20, 255), outline=(90, 90, 85, 255), width=2)
    for i, (lab, at) in enumerate([("ВОЗДУХ", 0.3), ("ТЕПЛО", 0.7)]):
        y = 188 + i * 30
        d.line([(110, y), (440, y)], fill=(60, 60, 60, 255), width=6)
        x = 110 + 330 * at
        d.rectangle((x - 10, y - 10, x + 10, y + 10), fill=(170, 165, 150, 255))
        d.text((75, y), lab, font=font(11, True, False, True), fill=rgb8(WHITE), anchor="mm")
    t.over(img)
    t.grain(0.015)
    t.save(name)


def seat(name):
    """Seat cloth (256×256): the brown-and-beige woven check of the 80s
    Zhiguli, worn shiny where the back rubs."""
    t = T(256, 256, (0.33, 0.25, 0.18), name)
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32)
    check = ((np.floor(xx / 16) + np.floor(yy / 16)) % 2).astype(np.float32)
    t.shade(check, 0.82, 1.08)
    weave = (np.sin(xx * 1.6) * np.sin(yy * 1.6) * 0.5 + 0.5)
    t.shade(weave, 0.9, 1.05)
    stripes = ((xx % 64) < 3).astype(np.float32)
    t.mix((0.55, 0.45, 0.32), stripes * 0.6)
    t.shade(t.noise(64, 3), 0.85, 1.08)
    t.relief = weave * 0.5 + check * 0.3
    t.grain(0.02)
    t.save(name)


ALL = {"car_gauges": gauges, "car_console": console, "car_seat": seat}
mt.NORMALS.update({"car_seat": (2.0, 1.0)})

if __name__ == "__main__":
    os.makedirs(mt.OUT, exist_ok=True)
    for nm in sys.argv[1:] or list(ALL):
        ALL[nm](nm)
        if nm in mt.NORMALS:
            mt.normal_map(nm)
        print("made", nm)
