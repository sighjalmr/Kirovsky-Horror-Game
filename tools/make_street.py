#!/usr/bin/env python3
"""Draws the street-furniture textures for the square outside «Кировский».

street.png is 2048×1024, 4 × 4 cells of 512×256 (see Street.CELLS in
scripts/street.gd): the blue «СОЮЗПЕЧАТЬ» band and the kiosk window full of
papers, the «ТЕЛЕФОН» plate, the bus-stop sign, a cinema bill and an
anti-drink poster for the stop, the «МИРУ — МИР!» roof slogan, a block's
entrance door, the entrance and house-number plates, the green bin, the
«ПРИЁМ СТЕКЛОТАРЫ» plate, the bus timetable, birch bark.

ext_decals.png is 1024×1024, 2 × 2 cells of 512 with alpha cut-outs: a big
puddle, fallen birch leaves, an oil stain, a cast-iron manhole cover.

ext_grass.png is a 512 px tile of October lawn: flattened, yellowing grass,
mud and leaves.

    python3 tools/make_street.py
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_textures as mt  # noqa: E402
from make_textures import T, blurred, grime  # noqa: E402

W, H = 512, 256
CELLS = [
    "soyuz", "kiosk_win", "phone", "bus_sign",
    "afisha", "poster_drink", "slogan", "door",
    "podezd", "house_no", "bin", "tara",
    "timetable", "bark", "panel_plinth", "blank",
]


def xy(name):
    i = CELLS.index(name)
    return (i % 4) * W, (i // 4) * H


def reg(name):
    x, y = xy(name)
    return (x, y, W, H)


def weather(t, name, amount=0.35):
    """Dirt, fading and rain streaks over one cell."""
    x, y, w, h = reg(name)
    g = grime(t, 70)
    t.shade(g, 1.0 - amount * 0.6, 1.0 + amount * 0.1, (x, y, w, h))
    t.lines(30, 60, (0.25, 0.22, 0.2), 2, amount * 0.35, (x, y, w, h // 2), math.pi / 2, 0.1)


def soyuz(t):
    x, y = xy("soyuz")
    t.rect(x, y, W, H, (0.13, 0.3, 0.55))
    t.rect(x, y + 14, W, 6, (0.85, 0.85, 0.8))
    t.rect(x, y + H - 20, W, 6, (0.85, 0.85, 0.8))
    t.text((x + W // 2, y + H // 2), "СОЮЗПЕЧАТЬ", 60, (0.95, 0.94, 0.88), cond=True)
    weather(t, "soyuz", 0.45)


def kiosk_win(t):
    """Behind the kiosk glass: papers and magazines pegged in rows."""
    x, y = xy("kiosk_win")
    t.rect(x, y, W, H, (0.3, 0.3, 0.28))
    rng = t.rng
    covers = [("ПРАВДА", (0.93, 0.92, 0.86), (0.7, 0.1, 0.08)), ("ОГОНЁК", (0.8, 0.15, 0.12), (0.97, 0.95, 0.9)),
              ("КРОКОДИЛ", (0.95, 0.85, 0.25), (0.75, 0.1, 0.08)), ("РАБОТНИЦА", (0.85, 0.4, 0.45), (0.97, 0.95, 0.9)),
              ("ТРУД", (0.93, 0.92, 0.86), (0.15, 0.15, 0.18)), ("ЗА РУЛЁМ", (0.2, 0.45, 0.7), (0.97, 0.95, 0.9)),
              ("ЗДОРОВЬЕ", (0.35, 0.65, 0.45), (0.97, 0.95, 0.9)), ("УРАЛЬСКИЙ\nРАБОЧИЙ", (0.93, 0.92, 0.86),
                                                                   (0.15, 0.15, 0.18))]
    for row in range(2):
        for k in range(6):
            cx = x + 12 + k * 83
            cy = y + 14 + row * 122
            name, bg, fg = covers[int(rng.integers(0, len(covers)))]
            t.rect(cx, cy, 76, 108, bg)
            t.text((cx + 38, cy + 18), name, 9 if "\n" in name else 11, fg, cond=True, spacing=0)
            t.rect(cx + 8, cy + 40, 60, 56, tuple(c * 0.75 for c in bg))
            for ln in range(5):
                t.rect(cx + 10, cy + 46 + ln * 10, 56, 2, (0.4, 0.4, 0.4), 0.5)
    # A cardboard price card in the corner.
    t.rect(x + 420, y + 200, 80, 44, (0.95, 0.95, 0.9))
    t.text((x + 460, y + 222), "5 коп.", 22, (0.2, 0.2, 0.6), bold=False)
    t.shade(t.noise(50, 3), 0.75, 1.0, reg("kiosk_win"))


def phone(t):
    x, y = xy("phone")
    t.rect(x, y, W, H, (0.75, 0.12, 0.1))
    t.rect(x + 10, y + 10, W - 20, H - 20, (0.93, 0.92, 0.86))
    t.text((x + W // 2, y + 110), "ТЕЛЕФОН", 72, (0.75, 0.12, 0.1), cond=True)
    t.text((x + W // 2, y + 196), "ГОРОДСКОЙ · 2 коп.", 34, (0.2, 0.2, 0.2), cond=True)
    weather(t, "phone", 0.5)


def bus_sign(t):
    x, y = xy("bus_sign")
    t.rect(x, y, W, H, (0.93, 0.92, 0.86))
    # Left: the yellow-bordered plate with a big «А»; right: the stop name and routes.
    t.rect(x + 16, y + 16, 224, 224, (0.9, 0.75, 0.15))
    t.rect(x + 30, y + 30, 196, 196, (0.95, 0.94, 0.9))
    t.text((x + 128, y + 128), "А", 170, (0.1, 0.1, 0.12))
    t.text((x + 376, y + 64), "СИРЕНЕВЫЙ\nБУЛЬВАР", 36, (0.1, 0.1, 0.12), cond=True, spacing=2)
    for k, r in enumerate(("23", "50", "54")):
        cx = x + 296 + k * 80
        t.rect(cx, y + 150, 64, 64, (0.15, 0.3, 0.6))
        t.text((cx + 32, y + 182), r, 40, (0.95, 0.95, 0.9))
    weather(t, "bus_sign", 0.45)


def afisha(t):
    """A hand-painted cinema bill: «Кинотеатр «Заря». Маленькая Вера»."""
    x, y = xy("afisha")
    t.rect(x, y, W, H, (0.92, 0.88, 0.75))
    t.rect(x, y, W, 44, (0.15, 0.25, 0.5))
    t.text((x + W // 2, y + 22), "КИНОТЕАТР «ЗАРЯ»", 32, (0.95, 0.92, 0.8), cond=True)
    t.text((x + W // 2, y + 100), "МАЛЕНЬКАЯ\nВЕРА", 54, (0.75, 0.12, 0.1), cond=True, spacing=0)
    t.text((x + W // 2, y + 196), "16, 18, 20, 22 ч.   Дети до 16 лет не допускаются", 18, (0.15, 0.15, 0.2),
           bold=False, cond=True)
    t.text((x + W // 2, y + 228), "ЦИРК · «КОМИССАР» · ДОМ КУЛЬТУРЫ МЖК", 16, (0.3, 0.3, 0.3), bold=False)
    weather(t, "afisha", 0.55)


def poster_drink(t):
    x, y = xy("poster_drink")
    t.rect(x, y, W, H, (0.95, 0.93, 0.85))
    t.rect(x, y, 170, H, (0.75, 0.12, 0.1))
    # A bottle crossed out.
    img, d = t.layer()
    d.rectangle((x + 65, y + 70, x + 105, y + 210), fill=(240, 235, 220, 255))
    d.rectangle((x + 76, y + 36, x + 94, y + 72), fill=(240, 235, 220, 255))
    d.line([(x + 30, y + 220), (x + 140, y + 40)], fill=(20, 20, 20, 255), width=14)
    t.over(img)
    t.text((x + 340, y + 90), "ПЬЯНСТВУ —\nБОЙ!", 42, (0.75, 0.12, 0.1), cond=True, spacing=2)
    t.text((x + 340, y + 205), "Трезвость — норма жизни", 24, (0.15, 0.15, 0.2), bold=False, cond=True)
    weather(t, "poster_drink", 0.5)


def slogan(t):
    x, y = xy("slogan")
    t.rect(x, y, W, H, (0.68, 0.1, 0.08))
    t.text((x + W // 2, y + H // 2 + 6), "МИРУ — МИР!", 60, (0.97, 0.95, 0.88), cond=True)
    weather(t, "slogan", 0.35)


def door(t):
    """Double entrance door of a panel block: brown-painted boards, wired glass
    top panes, a steel plate along the bottom, a spring handle."""
    x, y = xy("door")
    t.rect(x, y, W, H, (0.36, 0.22, 0.14))
    for k in range(2):
        dx = x + 8 + k * 252
        t.rect(dx, y + 6, 244, 244, (0.42, 0.26, 0.16))
        t.bevel(dx, y + 6, 244, 244, 5, (0.6, 0.45, 0.3), (0.15, 0.1, 0.06), 0.6)
        t.rect(dx + 26, y + 20, 192, 80, (0.18, 0.2, 0.2))
        for g in range(0, 192, 12):
            t.rect(dx + 26 + g, y + 20, 1, 80, (0.4, 0.4, 0.4), 0.4)
        t.rect(dx + 20, y + 196, 204, 46, (0.35, 0.35, 0.35))
        t.rect(dx + (210 if k == 0 else 20), y + 120, 14, 50, (0.6, 0.6, 0.58))
    t.lines(70, 30, (0.6, 0.55, 0.5), 1, 0.4, reg("door"))  # scratches
    weather(t, "door", 0.5)


def podezd(t):
    x, y = xy("podezd")
    t.rect(x, y, W, H, (0.15, 0.3, 0.55))
    t.rect(x + 8, y + 8, W - 16, H - 16, (0.93, 0.92, 0.86))
    t.text((x + W // 2, y + 90), "ПОДЪЕЗД 2", 64, (0.15, 0.3, 0.55), cond=True)
    t.text((x + W // 2, y + 180), "кв. 37 — 72", 56, (0.15, 0.15, 0.2), cond=True)
    weather(t, "podezd", 0.35)


def house_no(t):
    x, y = xy("house_no")
    t.rect(x, y, W, H, (0.93, 0.92, 0.86))
    t.rect(x + 8, y + 8, W - 16, H - 16, (0.15, 0.15, 0.18))
    t.rect(x + 16, y + 16, W - 32, H - 32, (0.93, 0.92, 0.86))
    t.text((x + 170, y + 128), "СИРЕНЕВЫЙ\nБУЛЬВАР", 40, (0.15, 0.15, 0.18), cond=True, spacing=4)
    t.text((x + 410, y + 128), "4", 160, (0.15, 0.15, 0.18))
    weather(t, "house_no", 0.4)


def bin_(t):
    x, y = xy("bin")
    t.rect(x, y, W, H, (0.22, 0.32, 0.24))
    t.shade(t.noise(30, 3), 0.8, 1.1, reg("bin"))
    t.stain(t.noise(25, 4), 0.6, (0.4, 0.22, 0.1), 0.8, reg("bin"))
    t.text((x + W // 2, y + 110), "ЖЭУ-12", 80, (0.85, 0.85, 0.8), cond=True, rough=0.25, opacity=0.8)
    t.lines(50, 50, (0.12, 0.12, 0.1), 2, 0.4, reg("bin"))
    weather(t, "bin", 0.6)


def tara(t):
    x, y = xy("tara")
    t.rect(x, y, W, H, (0.93, 0.92, 0.86))
    t.text((x + W // 2, y + 70), "ПРИЁМ\nСТЕКЛОТАРЫ", 52, (0.15, 0.3, 0.55), cond=True, spacing=0)
    t.text((x + W // 2, y + 186), "с 10 до 18 · обед 14–15\nТАРЫ НЕТ", 30, (0.75, 0.12, 0.1), cond=True)
    weather(t, "tara", 0.45)


def timetable(t):
    x, y = xy("timetable")
    t.rect(x, y, W, H, (0.93, 0.92, 0.86))
    t.text((x + W // 2, y + 26), "РАСПИСАНИЕ  · маршрут 23", 28, (0.1, 0.1, 0.12), cond=True)
    for r in range(6):
        hh = 6 + r * 3
        t.text((x + 40, y + 70 + r * 30), "%02d" % hh, 22, (0.1, 0.1, 0.12), anchor="lm")
        t.text((x + 90, y + 70 + r * 30), "  ".join("%02d" % (m % 60) for m in range(5 + r, 60, 12)), 20,
               (0.2, 0.2, 0.25), anchor="lm", bold=False)
    weather(t, "timetable", 0.5)


def bark(t):
    """Birch bark: chalk white with black lenticels and dark cracked patches
    (lower half darker, the rough base of the trunk)."""
    x, y = xy("bark")
    t.rect(x, y, W, H, (0.88, 0.87, 0.82))
    t.shade(t.noise(40, 4), 0.85, 1.05, reg("bark"))
    img, d = t.layer()
    rng = t.rng
    for _ in range(140):
        cx, cy = x + rng.uniform(0, W), y + rng.uniform(0, H)
        w = rng.uniform(3, 18)
        d.ellipse((cx - w, cy - 1.5, cx + w, cy + 1.5), fill=(25, 25, 25, int(rng.uniform(120, 255))))
    for _ in range(10):
        cx, cy = x + rng.uniform(0, W), y + rng.uniform(H * 0.5, H)
        d.ellipse((cx - rng.uniform(4, 14), cy - rng.uniform(3, 8), cx + rng.uniform(4, 14), cy + rng.uniform(3, 8)),
                  fill=(35, 32, 30, 220))
    t.over(img, 1.0, 0.6)


def panel_plinth(t):
    """Grey concrete plinth of a block with a band of dark wet splash."""
    x, y = xy("panel_plinth")
    t.rect(x, y, W, H, (0.5, 0.49, 0.46))
    t.shade(grime(t, 60), 0.75, 1.1, reg("panel_plinth"))
    ramp = np.zeros((t.h, t.w), np.float32)
    ramp[y:y + H, x:x + W] = np.linspace(0, 1, H, dtype=np.float32)[:, None] ** 2
    t.mix((0.18, 0.17, 0.15), ramp * 0.6)
    for k in range(4):
        t.rect(x + k * 128, y, 3, H, (0.2, 0.2, 0.2), 0.8)


def street(name):
    t = T(2048, 1024, (0.5, 0.5, 0.5), name)
    soyuz(t)
    kiosk_win(t)
    phone(t)
    bus_sign(t)
    afisha(t)
    poster_drink(t)
    slogan(t)
    door(t)
    podezd(t)
    house_no(t)
    bin_(t)
    tara(t)
    timetable(t)
    bark(t)
    panel_plinth(t)
    t.grain(0.015)
    t.save(name)


def decals(name):
    """Big puddle, birch leaves, oil stain, manhole cover; alpha cut-outs."""
    t = T(1024, 1024, (0, 0, 0, 0), name)
    t.a[..., 3] = 0
    yy, xx = np.mgrid[0:1024, 0:1024].astype(np.float32)
    n = t.noise(110, 5)
    rng = t.rng
    # Puddle: dark still water, a muddy rim.
    d = np.sqrt((xx - 256) ** 2 + ((yy - 256) * 1.5) ** 2) / 230 + (n - 0.5) * 1.3
    m = (d < 1.0) & (xx < 512) & (yy < 512)
    rim = (d > 0.8) & m
    t.a[m, :3] = (0.07, 0.075, 0.08)
    t.a[rim, :3] = (0.2, 0.17, 0.13)
    t.a[m, 3] = 1.0
    # Leaves: small yellow and brown birch leaves.
    img, dr = t.layer()
    for _ in range(170):
        cx, cy = 512 + rng.uniform(20, 492), rng.uniform(20, 492)
        s = rng.uniform(6, 13)
        a = rng.uniform(0, math.pi)
        col = [(205, 165, 40), (180, 120, 30), (120, 85, 35), (160, 140, 60)][int(rng.integers(0, 4))]
        pts = [(cx + math.cos(a + k * math.pi / 2) * s * (1.0 if k % 2 == 0 else 0.6),
                cy + math.sin(a + k * math.pi / 2) * s * (1.0 if k % 2 == 0 else 0.6)) for k in range(4)]
        dr.polygon(pts, fill=col + (255,))
    t.over(img)
    al = np.asarray(img)[..., 3] > 0
    t.a[al, 3] = 1.0
    # Oil stain under a parked car: dark, with a faint rainbow edge.
    d = np.sqrt((xx - 256) ** 2 + (yy - 768) ** 2) / 200 + (n - 0.5) * 1.0
    m = (d < 1.0) & (xx < 512) & (yy >= 512)
    t.a[m, :3] = (0.05, 0.05, 0.05)
    edge = m & (d > 0.75)
    t.a[edge, :3] = (0.08, 0.075, 0.09)
    t.a[m, 3] = 1.0
    # Manhole cover: cast iron, a ring of ribs, «ГТС» in the middle.
    cx, cy = 768, 768
    r = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    m = r < 240
    t.a[m, :3] = (0.2, 0.19, 0.18)
    t.a[m & (r > 225), :3] = (0.12, 0.12, 0.12)
    ang = np.arctan2(yy - cy, xx - cx)
    ribs = m & (r > 80) & (r < 215) & (np.cos(ang * 24) > 0.6)
    t.a[ribs, :3] = (0.3, 0.29, 0.27)
    t.a[m, 3] = 1.0
    t.text((cx, cy), "ГТС", 70, (0.3, 0.29, 0.27))
    rust = t.noise(30, 4)
    t.a[m & (rust > 0.78), :3] = (0.26, 0.17, 0.1)
    t.save(name)


def grass(name):
    """October lawn: flattened yellow-green grass, mud, fallen leaves."""
    t = T(512, 512, (0.27, 0.3, 0.15), name)
    t.shade(t.noise(80, 4), 0.7, 1.2)
    t.stain(t.noise(60, 5), 0.55, (0.45, 0.4, 0.2), 0.7)   # straw-yellow patches
    t.stain(t.noise(90, 5), 0.68, (0.2, 0.15, 0.1), 0.9)   # bare mud
    t.lines(5000, 10, (0.5, 0.5, 0.28), 1, 0.35)
    t.lines(3000, 8, (0.12, 0.15, 0.07), 1, 0.4)
    img, d = t.layer()
    rng = t.rng
    for _ in range(140):
        cx, cy = rng.uniform(0, 512), rng.uniform(0, 512)
        s = rng.uniform(3, 6)
        col = [(205, 165, 40), (170, 110, 30), (120, 85, 35)][int(rng.integers(0, 3))]
        d.ellipse((cx - s, cy - s * 0.6, cx + s, cy + s * 0.6), fill=col + (255,))
    t.over(img, 0.9)
    t.relief = t.noise(6, 3)
    t.rough = np.full((512, 512), 0.7, np.float32)
    t.grain(0.03)
    t.save(name)


ALL = {"street": street, "ext_decals": decals, "ext_grass": grass}
mt.NORMALS.update({"ext_grass": (1.5, 1.0)})


if __name__ == "__main__":
    for nm in sys.argv[1:] or list(ALL):
        ALL[nm](nm)
        if nm in mt.NORMALS:
            mt.normal_map(nm)
        print("made", nm)
