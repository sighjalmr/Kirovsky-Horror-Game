#!/usr/bin/env python3
"""Draws the textures of the street outside «Кировский» for the cutscenes:
the red profiled sheet of the facade, the white letters on red squares, the
arrow sign «УНИВЕРСАМ», the panel nine-storey blocks of ЖБИ and their lit
windows, wet asphalt with puddles, the black Soviet number plate.
Writes textures/ext_*.png (and _n / _r maps) next to the store's own.

    python3 tools/make_exterior.py            # all of them
    python3 tools/make_exterior.py ext_panel  # some of them

Uses the canvas and helpers of make_textures.py (numpy, Pillow, DejaVu fonts).
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_textures as mt  # noqa: E402
from make_textures import T, blurred, grime, smooth, font, rgb8  # noqa: E402


def profnastil(name):
    """Red profiled steel sheet of the facade, 2 m square: trapezoid ribs every
    20 cm, the paint chalky and faded to brick, rain streaks running down
    from every rib, rust at the bottom edge and round the fixings."""
    t = T(512, 512, (0.62, 0.17, 0.11), name)
    xx = np.arange(512, dtype=np.float32)
    period = 51.2
    ph = (xx % period) / period
    # Trapezoid ribs: a flat crest, sloping flanks, a wide flat trough.
    crest = np.clip((0.22 - np.abs(ph - 0.25)) / 0.05, 0, 1)
    rel = np.tile(crest[None, :], (512, 1))
    t.relief = rel * 0.9 + 0.1
    # Light falls from the left: one flank lit, the other in shade.
    flank = np.gradient(crest)
    t.mul(np.tile((1.0 + np.clip(flank * 3.0, -0.35, 0.35))[None, :], (512, 1)))
    t.mul(np.tile((0.9 + crest * 0.12)[None, :], (512, 1)))
    g = grime(t, 160)
    t.shade(g, 0.82, 1.12)
    # Chalked paint: lighter, pinker blotches.
    t.stain(t.noise(90, 4), 0.55, (0.72, 0.36, 0.3), 0.45)
    # Streaks down from the top: dirty rain water.
    streak = np.tile(t.rng.random(512).astype(np.float32)[None, :], (512, 1))
    streak = blurred(streak, 1.2)
    streak = np.clip((streak - 0.55) * 3.0, 0, 1) * (0.5 + 0.5 * t.noise(40, 3))
    t.mix((0.25, 0.12, 0.1), streak * 0.45)
    # Rust bleeding from screws in rows every metre.
    img, d = t.layer()
    for row in (128, 384):
        for k in range(10):
            x = int((k + 0.25) * period)
            r = 3
            d.ellipse((x - r, row - r, x + r, row + r), fill=(60, 40, 35, 255))
            for s in range(int(t.rng.integers(10, 40))):
                d.line([(x, row), (x + t.rng.normal(0, 1.5), row + 4 + s)], fill=(120, 55, 25, 25), width=2)
    t.over(img, 0.8, 0.8)
    t.grain(0.02)
    t.rough = 0.55 + 0.3 * g + (1 - crest[None, :]) * 0.05
    t.save(name)


LETTERS = "КИРОВСКИЙ"


def kirovsky(name):
    """«КИРОВСКИЙ»: nine white letters, each on its own red square box face,
    as on the 1980s photo (2304×256, one square per 256 px, mapped once)."""
    t = T(2304, 256, (0.72, 0.1, 0.08), name)
    t.shade(t.noise(60, 3), 0.9, 1.06)
    img, d = t.layer()
    f = font(206, True, False, True)
    for i, ch in enumerate(LETTERS):
        cx = i * 256 + 128
        # White square border of each box, then the red field.
        d.rectangle((i * 256 + 2, 2, i * 256 + 253, 253), outline=(235, 230, 220, 255), width=10)
        d.text((cx, 136), ch, font=f, fill=(244, 240, 232, 255), anchor="mm")
    t.over(img)
    # The breve of «Й» is drawn by the font; dirt in the corners.
    yy, xx = np.mgrid[0:256, 0:2304].astype(np.float32)
    lx = (xx % 256) / 256
    edge = np.minimum(np.minimum(lx, 1 - lx), np.minimum(yy / 256, 1 - yy / 256))
    t.mul(0.75 + 0.25 * smooth(edge / 0.12))
    t.grain(0.015)
    t.save(name)


def universam(name):
    """The arrow sign «УНИВЕРСАМ» (1024×256, alpha cut-out): a white board
    with dark red letters, a pointed head on the right and a notched tail."""
    t = T(1024, 256, (0.9, 0.89, 0.85, 1.0), name)
    t.shade(t.noise(80, 3), 0.86, 1.02)
    poly = [(40, 30), (850, 30), (1000, 128), (850, 226), (40, 226), (110, 128)]
    mask = Image.new("L", (1024, 256), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    m = np.asarray(mask, np.float32) / 255
    img, d = t.layer()
    d.line(poly + [poly[0]], fill=(150, 150, 145, 255), width=12, joint="curve")
    d.text((520, 130), "УНИВЕРСАМ", font=font(112, True, False, True), fill=(60, 26, 22, 255), anchor="mm")
    t.over(img)
    t.grain(0.012)
    t.a[..., 3] = m
    t.save(name)


def panel(name):
    """Nine-storey panel block of ЖБИ, 1024 px = 4 window bays × 4 floors
    (12 m × 11.2 m, tiles up and across): grey-beige panels with dark sealed
    seams, wooden double windows, glazed loggias every other bay."""
    W, H = 1024, 1024
    t = T(W, H, (0.66, 0.63, 0.57), name)
    bay, fl = W / 4, H / 4
    g = grime(t, 220)
    t.shade(g, 0.86, 1.1)
    t.shade(t.noise(14, 3), 0.95, 1.04)
    img, d = t.layer()
    for j in range(4):
        y0 = j * fl
        for i in range(4):
            x0 = i * bay
            # Panel seams (sealed with dark mastic).
            d.line([(x0, y0), (x0, y0 + fl)], fill=(40, 38, 36, 255), width=5)
            loggia = (i % 2 == 1)
            wx, wy, ww, wh = x0 + bay * 0.2, y0 + fl * 0.22, bay * 0.6, fl * 0.5
            if loggia:
                # The loggia: a recessed glazing over a ribbed parapet.
                d.rectangle((x0 + 10, y0 + fl * 0.12, x0 + bay - 10, y0 + fl - 6), fill=(70, 66, 60, 255))
                d.rectangle((x0 + 14, y0 + fl * 0.58, x0 + bay - 14, y0 + fl - 10), fill=(150, 140, 125, 255))
                for k in range(12):
                    xr = x0 + 14 + k * (bay - 28) / 12
                    d.line([(xr, y0 + fl * 0.58), (xr, y0 + fl - 10)], fill=(120, 112, 100, 255), width=2)
                wx, wy, ww, wh = x0 + 18, y0 + fl * 0.16, bay - 36, fl * 0.4
            d.rectangle((wx, wy, wx + ww, wy + wh), fill=(225, 220, 205, 255))
            d.rectangle((wx + 6, wy + 6, wx + ww - 6, wy + wh - 6), fill=(18, 22, 26, 255))
            # Casement bars: the classic three-leaf Soviet window with a fortochka.
            d.line([(wx + ww * 0.5, wy), (wx + ww * 0.5, wy + wh)], fill=(225, 220, 205, 255), width=6)
            d.line([(wx + ww * 0.25, wy), (wx + ww * 0.25, wy + wh)], fill=(225, 220, 205, 255), width=4)
            d.line([(wx, wy + wh * 0.3), (wx + ww * 0.25, wy + wh * 0.3)], fill=(225, 220, 205, 255), width=4)
            # Sky in the glass, a curtain edge.
            d.rectangle((wx + 8, wy + 8, wx + ww * 0.25 - 4, wy + wh * 0.3 - 4), fill=(40, 46, 52, 255))
            if (i + j) % 3 == 0:
                d.rectangle((wx + ww * 0.5 + 4, wy + 8, wx + ww * 0.62, wy + wh - 8), fill=(80, 70, 60, 255))
        d.line([(0, y0), (W, y0)], fill=(45, 42, 40, 255), width=6)
    t.over(img)
    # Rust and rain from the sills down the panels.
    streak = blurred(np.tile(t.rng.random(W).astype(np.float32)[None, :], (H, 1)), 1.5)
    t.mix((0.35, 0.3, 0.26), np.clip((streak - 0.5) * 2.5, 0, 1) * 0.35 * t.noise(60, 3))
    lum = t.a[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
    t.relief = np.clip(lum * 1.2, 0, 1)
    t.grain(0.02)
    t.save(name)


def windows(name):
    """Lit windows at night, a 4×2 atlas of 256×256 cells, one window each:
    orange silk lampshades, a yellow kitchen, the blue of a television, tulle
    and heavy curtains, the dark cross of the frame over all of them."""
    t = T(1024, 512, (0.0, 0.0, 0.0), name)
    looks = [((1.0, 0.62, 0.3), "tulle"), ((1.0, 0.82, 0.5), "kitchen"), ((0.45, 0.6, 0.95), "tv"),
             ((1.0, 0.55, 0.25), "curtains"), ((0.95, 0.75, 0.45), "tulle"), ((0.9, 0.5, 0.3), "curtains"),
             ((1.0, 0.85, 0.6), "bare"), ((0.55, 0.68, 0.9), "tv")]
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32) / 256
    for k, (c, kind) in enumerate(looks):
        ox, oy = (k % 4) * 256, (k // 4) * 256
        # A lamp somewhere in the room: brighter round it.
        lx, ly = 0.3 + t.rng.random() * 0.4, 0.15 + t.rng.random() * 0.3
        glow = np.clip(1.2 - np.hypot(xx - lx, yy - ly) * 1.6, 0.25, 1.0)
        if kind == "tv":
            glow = np.clip(1.0 - np.hypot(xx - lx, yy - 0.7) * 1.4, 0.15, 1.0) * 0.8
        cell = np.array(c, np.float32)[None, None, :] * glow[..., None]
        if kind == "tulle":
            folds = 0.75 + 0.25 * np.sin(xx * 70 + np.sin(yy * 9) * 2)
            cell *= folds[..., None]
        if kind == "curtains":
            side = np.clip((np.abs(xx - 0.5) - 0.22) * 8, 0, 1)
            folds = 0.6 + 0.4 * np.sin(xx * 50)
            cell = cell * (1 - side[..., None]) + cell * 0.35 * folds[..., None] * side[..., None]
        t.a[oy:oy + 256, ox:ox + 256, :3] = cell
    img, d = t.layer()
    for k in range(8):
        ox, oy = (k % 4) * 256, (k // 4) * 256
        fr = (30, 26, 22, 255)
        d.rectangle((ox, oy, ox + 255, oy + 255), outline=fr, width=14)
        d.line([(ox + 128, oy), (ox + 128, oy + 256)], fill=fr, width=10)
        d.line([(ox + 64, oy), (ox + 64, oy + 256)], fill=fr, width=7)
        d.line([(ox, oy + 80), (ox + 64, oy + 80)], fill=fr, width=7)
        # Plants and jars on the sill.
        for s in range(int(t.rng.integers(1, 4))):
            x = ox + 20 + t.rng.random() * 200
            d.rectangle((x, oy + 215, x + 18, oy + 241), fill=(20, 18, 15, 255))
            d.ellipse((x - 10, oy + 185, x + 28, oy + 222), fill=(25, 30, 20, 255))
    t.over(img)
    t.save(name)


def asphalt(name):
    """Wet asphalt of the square, 4 m square: dark aggregate, cracks filled
    with tar, patches, and puddles that are darker, flat and glossy."""
    t = T(512, 512, (0.2, 0.2, 0.2), name)
    t.shade(t.noise(3, 2), 0.7, 1.25)
    g = grime(t, 180)
    t.shade(g, 0.7, 1.15)
    t.cracks(14, 60, (0.06, 0.06, 0.06), 2, 0.8)
    pud = blurred(np.clip((t.noise(140, 4, 0.55) - 0.62) * 5.0, 0, 1), 3.0)
    t.mul(1.0 - pud * 0.3)
    t.relief = np.clip(1.0 - pud * 0.8 + (t.noise(3, 2) - 0.5) * 0.25 * (1 - pud), 0, 1)
    t.rough = np.clip(0.42 - pud * 0.36 + g * 0.12, 0.03, 1)
    t.grain(0.03)
    t.save(name)


def tiles(name):
    """Concrete slabs of the steps and the porch, 1 m: grey, worn, with dark
    joints and a rubbed path up the middle."""
    t = T(512, 512, (0.55, 0.54, 0.51), name)
    idx, dd, h = mt.tile_grid(t, 2, 2, 6, 6, 0.02)
    t.shade(t.noise(4, 2), 0.85, 1.12)
    t.shade(grime(t, 160), 0.75, 1.1)
    t.mix((0.15, 0.15, 0.15), (dd < 0).astype(np.float32) * 0.8)
    t.relief = h
    t.rough = 0.5 + 0.3 * (dd < 0)
    t.grain(0.03)
    t.save(name)


def plate(name):
    """Soviet private number plate before 1993 (256×64): white characters on
    black, «а 47-12 СВ» (Свердловская область)."""
    t = T(256, 64, (0.06, 0.06, 0.07), name)
    img, d = t.layer()
    d.rectangle((2, 2, 253, 61), outline=(200, 200, 200, 255), width=3)
    d.text((128, 34), "а 47-12 СВ", font=font(40, True, False, True), fill=(225, 225, 220, 255), anchor="mm")
    t.over(img)
    t.save(name)


def receipt(name):
    """The receipt of 7 October from the flashback (256×512): «КИРОВСКИЙ»,
    касса 2, 22:58."""
    t = T(256, 512, (0.93, 0.92, 0.86), name)
    t.shade(t.noise(40, 3), 0.92, 1.02)
    lines = "УНИВЕРСАМ\nКИРОВСКИЙ\n\nКАССА 02\n07.10.88\n\n    *14.20\n    *25.80\n    *40.00\n\nИТОГ *80.00\n\n22-58"
    t.text((128, 250), lines, 26, (0.25, 0.2, 0.35), "mm", bold=False, cond=True, opacity=0.85, rough=0.15, spacing=6)
    t.save(name)


ALL = {"ext_profnastil": profnastil, "ext_kirovsky": kirovsky, "ext_universam": universam, "ext_panel": panel,
       "ext_windows": windows, "ext_asphalt": asphalt, "ext_slabs": tiles, "ext_plate": plate,
       "ext_receipt": receipt}
mt.NORMALS.update({"ext_profnastil": (3.0, 1.0), "ext_panel": (1.5, 1.0), "ext_asphalt": (2.0, 1.2),
                   "ext_slabs": (2.0, 1.0)})


if __name__ == "__main__":
    os.makedirs(mt.OUT, exist_ok=True)
    for nm in sys.argv[1:] or list(ALL):
        ALL[nm](nm)
        if nm in mt.NORMALS:
            mt.normal_map(nm)
        print("made", nm)
