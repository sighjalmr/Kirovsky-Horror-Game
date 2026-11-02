#!/usr/bin/env python3
"""Draws the goods atlas of «Кировский: Закрытие»: textures/goods.png.

2048×2048, 4 columns × 8 rows of 512×256 cells (see Goods.cell in
scripts/goods.gd). A cell is either a label that wraps once round a tin, jar
or bottle (u round the body, v from the top of the label down), or the faces
of a pack: front 0..256 px, side 256..384, top 384..512.

Everything a shopper in Sverdlovsk saw in October 1988: tinned peas and
condensed milk with the plain lithographed labels of the Ministry of the food
industry, kilka and sprats, three-litre jars of juice, milk in glass bottles
with foil caps and in triangular packs, salt, Georgian tea, matches in
paper-wrapped blocks of ten, flour and sugar in paper bags; and for the
refrigerated counters butter, cheese, sausage, pelmeni, fish and the famous
blue chickens.

    python3 tools/make_goods.py

Needs Python 3, numpy and Pillow (same as make_textures.py).
"""

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_textures import IMPORT, OUT, T, blurred, font, rgb8, write_import  # noqa: E402

W, H = 512, 256
COLS = 4

# Cell order: must match Goods.CELLS in scripts/goods.gd.
CELLS = [
    "peas", "condensed", "tushonka", "kapusta",
    "kilka", "lids", "ikra", "jar_tomato",
    "jar_birch", "jar_apple", "oil", "glass_milk",
    "tetra", "salt", "tea", "macaroni",
    "matches", "flour", "sugar", "chicory",
    "barley", "grechka", "psheno", "soda",
    "butter", "cheese", "sausage", "pelmeni",
    "fish", "chicken", "plombir", "metal",
]


def cell_xy(name):
    i = CELLS.index(name)
    return (i % COLS) * W, (i // COLS) * H


# --- little drawing helpers --------------------------------------------------

def band(t, x, y, w, h, color, alpha=1.0):
    t.rect(x, y, w, h, color, alpha)


def wear(t, x, y, w, h, amount=0.5, color=(0.92, 0.9, 0.84)):
    """Scuffed print: pale specks and rubbed edges inside a region."""
    n = t.noise(5, 3)[y:y + h, x:x + w]
    m = np.clip((n - (1 - amount * 0.25)) * 8, 0, 1) * 0.7
    full = np.zeros((t.h, t.w), np.float32)
    full[y:y + h, x:x + w] = m
    t.mix(color, full)


def rust(t, x, y, w, h, count=10):
    """Rust spots creeping in from the seam and the rims of a tin."""
    m = t.blob_mask(count, 2, 7, (x, y, w, h), 0.9)
    halo = blurred((m > 0.05).astype(np.float32), 2.5)
    t.mix((0.45, 0.26, 0.12), np.clip(halo * 1.2, 0, 0.6))
    t.mix((0.3, 0.15, 0.06), np.clip(m * 1.6, 0, 0.9))


def tin_rims(t, x, y, w, h, metal=(0.72, 0.72, 0.68)):
    """Bare tinplate where the label stops short of the rims, and the seam."""
    band(t, x, y, w, 10, metal)
    band(t, x, y + h - 10, w, 10, metal)
    for k in (3, 6):
        band(t, x, y + k, w, 1, np.array(metal) * 0.75)
        band(t, x, y + h - 1 - k, w, 1, np.array(metal) * 0.75)
    band(t, x + w - 6, y, 6, h, np.array(metal) * 0.85)


def pea_pod(d, cx, cy, s):
    d.ellipse((cx - 30 * s, cy - 10 * s, cx + 30 * s, cy + 10 * s), fill=rgb8((0.32, 0.55, 0.2)))
    for k in range(5):
        px = cx - 22 * s + k * 11 * s
        d.ellipse((px - 5 * s, cy - 6 * s, px + 5 * s, cy + 4 * s), fill=rgb8((0.55, 0.8, 0.32)))
        d.ellipse((px - 2 * s, cy - 4 * s, px + 1 * s, cy - 1 * s), fill=rgb8((0.8, 0.95, 0.6)))
    d.line([(cx + 30 * s, cy), (cx + 40 * s, cy - 8 * s)], fill=rgb8((0.25, 0.4, 0.15)), width=max(1, int(2 * s)))


def cow(d, cx, cy, s, body=(0.92, 0.92, 0.9), spot=(0.15, 0.12, 0.1)):
    d.ellipse((cx - 26 * s, cy - 12 * s, cx + 18 * s, cy + 10 * s), fill=rgb8(body))
    d.ellipse((cx + 12 * s, cy - 16 * s, cx + 30 * s, cy - 2 * s), fill=rgb8(body))
    for lx in (-20, -10, 6, 14):
        d.rectangle((cx + lx * s, cy + 6 * s, cx + (lx + 4) * s, cy + 20 * s), fill=rgb8(body))
    d.ellipse((cx - 14 * s, cy - 8 * s, cx - 2 * s, cy + 2 * s), fill=rgb8(spot))
    d.ellipse((cx + 2 * s, cy - 4 * s, cx + 10 * s, cy + 4 * s), fill=rgb8(spot))
    d.polygon([(cx + 16 * s, cy - 15 * s), (cx + 14 * s, cy - 22 * s), (cx + 19 * s, cy - 16 * s)], fill=rgb8(spot))


def fish(d, cx, cy, s, color=(0.78, 0.8, 0.84), eye=True):
    d.ellipse((cx - 30 * s, cy - 8 * s, cx + 18 * s, cy + 8 * s), fill=rgb8(color))
    d.polygon([(cx + 14 * s, cy), (cx + 30 * s, cy - 10 * s), (cx + 30 * s, cy + 10 * s)], fill=rgb8(color))
    if eye:
        d.ellipse((cx - 24 * s, cy - 3 * s, cx - 19 * s, cy + 2 * s), fill=(25, 25, 30, 255))


def tomato(d, cx, cy, r):
    d.ellipse((cx - r, cy - r * 0.9, cx + r, cy + r * 0.9), fill=rgb8((0.82, 0.13, 0.07)))
    d.ellipse((cx - r * 0.5, cy - r * 0.6, cx - r * 0.1, cy - r * 0.25), fill=rgb8((0.95, 0.5, 0.4)))
    d.polygon([(cx - r * 0.4, cy - r * 0.85), (cx, cy - r * 1.2), (cx + r * 0.4, cy - r * 0.85), (cx, cy - r * 0.7)],
              fill=rgb8((0.2, 0.45, 0.15)))


def gost(t, x, y, ink, size=11, text="ГОСТ"):
    t.text((x, y), text, size, ink, bold=False, cond=True)


# --- tins ---------------------------------------------------------------------

def tin_label(t, name, bg, title, sub, ink, pic, accent=None, price="Цена 32 коп."):
    x, y = cell_xy(name)
    band(t, x, y, W, H, bg)
    if accent is not None:
        band(t, x, y + 28, W, 18, accent)
        band(t, x, y + H - 46, W, 18, accent)
    img, d = t.layer()
    # The label repeats twice round the tin so a shopper sees it from any side.
    for rep in range(2):
        cx = x + 128 + rep * 256
        if pic == "peas":
            pea_pod(d, cx, y + 92, 1.6)
        elif pic == "cow":
            cow(d, cx, y + 96, 1.4, (0.86, 0.66, 0.36), (0.35, 0.2, 0.1))
        elif pic == "kelp":
            for k in range(6):
                d.line([(cx - 40 + k * 16, y + 120), (cx - 34 + k * 16, y + 70), (cx - 44 + k * 16, y + 52)],
                       fill=rgb8((0.15, 0.4, 0.3)), width=5)
        elif pic == "fish":
            fish(d, cx - 8, y + 96, 1.2)
            fish(d, cx + 14, y + 108, 1.0, (0.7, 0.72, 0.78))
    t.over(img)
    for rep in range(2):
        cx = x + 128 + rep * 256
        t.text((cx, y + 150), title, 30 if "\n" not in title else 24, ink, cond=True, spacing=2)
        if sub:
            t.text((cx, y + 196), sub, 14, ink, bold=False, cond=True)
        gost(t, cx - 70, y + 214, np.array(ink) * 0.7 + np.array(bg) * 0.3, 10)
        t.text((cx + 64, y + 214), price, 10, np.array(ink) * 0.7 + np.array(bg) * 0.3, bold=False, cond=True)
    tin_rims(t, x, y, W, H)
    wear(t, x, y, W, H, 0.6)
    rust(t, x + W - 30, y, 30, H, 4)
    rust(t, x, y, W, 14, 6)


def condensed(t):
    """«Молоко цельное сгущённое с сахаром»: the white-and-blue label that
    every child in the country could draw from memory."""
    x, y = cell_xy("condensed")
    band(t, x, y, W, H, (0.95, 0.95, 0.93))
    blue = (0.16, 0.36, 0.72)
    band(t, x, y + 64, W, 104, blue)
    img, d = t.layer()
    for k in range(-2, 12):  # the diagonal blue wedges over the white
        x0 = x + k * 52
        d.polygon([(x0, y + 64), (x0 + 22, y + 64), (x0 + 56, y + 20), (x0 + 34, y + 20)], fill=rgb8(blue))
    t.over(img)
    band(t, x, y + 10, W, 10, blue)
    for rep in range(2):
        cx = x + 128 + rep * 256
        t.text((cx, y + 98), "МОЛОКО", 40, (0.97, 0.97, 0.95), cond=True)
        t.text((cx, y + 140), "ЦЕЛЬНОЕ СГУЩЁННОЕ\nС САХАРОМ", 14, (0.97, 0.97, 0.95), cond=True, spacing=1)
        t.text((cx, y + 195), "ГОСТ 2903-78", 12, blue, bold=False, cond=True)
        t.text((cx, y + 216), "масса нетто 400 г  · цена 55 коп.", 10, blue, bold=False, cond=True)
    tin_rims(t, x, y, W, H)
    wear(t, x, y, W, H, 0.6)
    rust(t, x, y + H - 16, W, 16, 6)


def kilka(t):
    """Low round tin: a paper band round the side, red with the title in
    white over a cream strip of fish; the lid comes from «lids»."""
    x, y = cell_xy("kilka")
    band(t, x, y, W, H, (0.66, 0.12, 0.08))
    band(t, x, y + 128, W, 44, (0.92, 0.88, 0.76))
    img, d = t.layer()
    for k in range(8):
        fish(d, x + 32 + k * 64, y + 150, 0.8, (0.62, 0.66, 0.72))
    t.over(img)
    for k in range(4):
        cx = x + 64 + k * 128
        t.text((cx, y + 84), "КИЛЬКА", 24, (0.97, 0.93, 0.82), cond=True)
        t.text((cx, y + 110), "в томате", 15, (0.97, 0.93, 0.82), bold=False, cond=True)
        t.text((cx, y + 188), "35 коп.", 12, (0.97, 0.9, 0.78), bold=False, cond=True)
    tin_rims(t, x, y, W, H)
    wear(t, x, y, W, H, 0.7)


def lids(t):
    """Discs for the tops: four 128 px discs across the top row (plain tin with
    an embossed code, gold lacquer, sprats, kilka) and foil caps below
    (silver = milk, green = kefir, raspberry = ряженка, gold = сметана)."""
    x, y = cell_xy("lids")
    band(t, x, y, W, H, (0.3, 0.3, 0.3))
    img, d = t.layer()
    def disc(cx, cy, r, col, ring=None):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgb8(col))
        if ring:
            for k in (8, 14):
                d.ellipse((cx - r + k, cy - r + k, cx + r - k, cy + r - k), outline=rgb8(ring), width=2)
    disc(x + 64, y + 64, 62, (0.74, 0.74, 0.7), (0.58, 0.58, 0.55))
    disc(x + 192, y + 64, 62, (0.78, 0.6, 0.26), (0.6, 0.44, 0.16))
    disc(x + 320, y + 64, 62, (0.82, 0.64, 0.24), (0.55, 0.38, 0.12))
    disc(x + 448, y + 64, 62, (0.7, 0.7, 0.66), (0.5, 0.5, 0.48))
    foils = [(0.82, 0.82, 0.8), (0.25, 0.6, 0.3), (0.75, 0.2, 0.38), (0.86, 0.7, 0.3)]
    for k, c in enumerate(foils):
        disc(x + 64 + k * 128, y + 192, 58, c)
    t.over(img)
    t.text((x + 64, y + 64), "1 Р 027\n08 88", 15, (0.45, 0.45, 0.42), cond=True, spacing=6)
    t.text((x + 320, y + 52), "ШПРОТЫ", 22, (0.35, 0.12, 0.05), cond=True)
    t.text((x + 320, y + 80), "в масле · Рига", 13, (0.35, 0.12, 0.05), bold=False, cond=True)
    t.text((x + 448, y + 64), "Р 112\n14 88", 15, (0.4, 0.4, 0.38), cond=True, spacing=6)
    for k, word in enumerate(["МОЛОКО", "КЕФИР", "РЯЖЕНКА", "СМЕТАНА"]):
        t.text((x + 64 + k * 128, y + 185), word, 15, (0.15, 0.15, 0.15), cond=True)
        t.text((x + 64 + k * 128, y + 206), "чт", 12, (0.15, 0.15, 0.15), bold=False)
    img, d = t.layer()
    for k in range(4):  # foil crinkles
        cx = x + 64 + k * 128
        for _ in range(16):
            a = t.rng.random() * np.pi * 2
            d.line([(cx, y + 192), (cx + np.cos(a) * 58, y + 192 + np.sin(a) * 58)], fill=(255, 255, 255, 60), width=1)
    t.over(img)


# --- glass --------------------------------------------------------------------

def jar_label(t, name, juice, title, sub, label_bg, ink, pic):
    """Three-litre jar (or a half-litre one): the cell runs down the profile,
    lid rim on top, glass shoulder, contents, a paper label round the middle,
    the bottom. Glass reads by its highlights over the contents."""
    x, y = cell_xy(name)
    yy = np.mgrid[0:H, 0:W][0].astype(np.float32)
    col = np.array(juice, np.float32)
    region = np.ones((H, W, 3), np.float32) * col
    # Shoulder above the liquid shows glass over the dark inside.
    region[:30] = np.array((0.42, 0.46, 0.44))
    region[30:34] = col * 1.3
    t.a[y:y + H, x:x + W, :3] = region
    # Vertical highlight streaks (two per side so they show from any angle).
    xx = np.mgrid[0:H, 0:W][1].astype(np.float32)
    for c in (0.18, 0.68):
        s = np.exp(-((xx / W - c) ** 2) / 0.0006)
        t.a[y:y + H, x:x + W, :3] += s[..., None] * 0.35
    t.a[y:y + H, x:x + W, :3] *= (0.85 + 0.15 * np.clip(yy / H, 0, 1))[..., None]
    lx0, ly0, lw, lh = x, y + 86, W, 110
    band(t, lx0, ly0, lw, lh, label_bg)
    img, d = t.layer()
    for rep in range(2):
        cx = x + 128 + rep * 256
        if pic == "tomato":
            tomato(d, cx - 60, ly0 + 55, 22)
        elif pic == "birch":
            for k in range(3):
                bx = cx - 92 + k * 12
                d.rectangle((bx, ly0 + 18, bx + 7, ly0 + 92), fill=(238, 238, 228, 255))
                for m in range(4):
                    d.rectangle((bx, ly0 + 26 + m * 16 + k * 3, bx + 7, ly0 + 29 + m * 16 + k * 3), fill=(30, 30, 30, 255))
        elif pic == "apple":
            d.ellipse((cx - 82, ly0 + 34, cx - 38, ly0 + 78), fill=rgb8((0.85, 0.65, 0.12)))
            d.ellipse((cx - 74, ly0 + 40, cx - 62, ly0 + 52), fill=rgb8((0.95, 0.85, 0.5)))
            d.line([(cx - 60, ly0 + 36), (cx - 56, ly0 + 24)], fill=(80, 50, 20, 255), width=3)
        elif pic == "ikra":
            for k in range(3):
                d.ellipse((cx - 96 + k * 14, ly0 + 40, cx - 70 + k * 14, ly0 + 70), fill=rgb8((0.75, 0.6, 0.15)))
    t.over(img)
    for rep in range(2):
        cx = x + 128 + rep * 256
        t.text((cx + 34, ly0 + 40), title, 22 if len(title) < 10 else 16, ink, cond=True)
        t.text((cx + 34, ly0 + 76), sub, 12, ink, bold=False, cond=True)
    band(t, lx0, ly0, lw, 4, np.array(label_bg) * 0.7)
    band(t, lx0, ly0 + lh - 4, lw, 4, np.array(label_bg) * 0.7)
    wear(t, lx0, ly0, lw, lh, 0.8)
    # Lid rim at the very top of the cell: lacquered tin.
    band(t, x, y, W, 12, (0.75, 0.62, 0.3))
    band(t, x, y + 12, W, 4, (0.35, 0.3, 0.2))


def oil(t):
    """Half-litre bottle of sunflower oil: amber glass-clear oil, a narrow
    paper label, a foil cap over the neck."""
    x, y = cell_xy("oil")
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    col = np.array((0.78, 0.6, 0.12), np.float32)
    reg = np.ones((H, W, 3), np.float32) * col
    reg[:70] = (0.82, 0.68, 0.22)
    reg *= (0.8 + 0.2 * (yy / H))[..., None]
    for c in (0.2, 0.7):
        reg += (np.exp(-((xx / W - c) ** 2) / 0.0005) * 0.4)[..., None]
    t.a[y:y + H, x:x + W, :3] = reg
    band(t, x, y, W, 16, (0.82, 0.82, 0.8))
    band(t, x, y + 120, W, 80, (0.92, 0.86, 0.6))
    img, d = t.layer()
    for rep in range(2):
        cx = x + 128 + rep * 256
        d.ellipse((cx - 98, y + 132, cx - 46, y + 186), fill=rgb8((0.9, 0.7, 0.1)))
        d.ellipse((cx - 84, y + 146, cx - 60, y + 172), fill=rgb8((0.3, 0.2, 0.1)))
    t.over(img)
    for rep in range(2):
        cx = x + 128 + rep * 256
        t.text((cx + 20, y + 148), "МАСЛО", 22, (0.25, 0.4, 0.15), cond=True)
        t.text((cx + 20, y + 178), "подсолнечное", 14, (0.25, 0.4, 0.15), bold=False, cond=True)


def glass_milk(t):
    """Milk bottle glass: white milk to the shoulder, the neck clear and
    greenish, highlights. Also used for kefir and сметана jars (tinted)."""
    x, y = cell_xy("glass_milk")
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    reg = np.ones((H, W, 3), np.float32) * np.array((0.93, 0.93, 0.9), np.float32)
    reg[:44] = (0.6, 0.66, 0.62)
    reg[44:50] = (0.97, 0.97, 0.95)
    for c in (0.15, 0.65):
        reg += (np.exp(-((xx / W - c) ** 2) / 0.0005) * 0.25)[..., None]
    reg *= (0.88 + 0.12 * (yy / H))[..., None]
    t.a[y:y + H, x:x + W, :3] = np.clip(reg, 0, 1)
    # Moulded «0,5 л» and the ring at the bottom.
    for rep in range(2):
        t.text((x + 128 + rep * 256, y + 226), "0,5 л", 14, (0.82, 0.82, 0.8), bold=False)
    band(t, x, y + 244, W, 3, (0.8, 0.82, 0.8))


def tetra(t):
    """Triangular half-litre milk pack: blue and white print. The cell holds
    the unfolded faces: each 256 px half is one face (drawn upright)."""
    x, y = cell_xy("tetra")
    band(t, x, y, W, H, (0.95, 0.95, 0.94))
    img, d = t.layer()
    blue = rgb8((0.18, 0.38, 0.7))
    for k in range(2):
        x0 = x + k * 256
        for j in range(0, 256, 28):  # diagonal bands of the Tetra pattern
            d.polygon([(x0 + j, y + 256), (x0 + j + 12, y + 256), (x0 + 128 + j / 2 + 6, y), (x0 + 128 + j / 2, y)],
                      fill=blue)
    t.over(img, 0.35)
    for k in range(2):
        cx = x + 128 + k * 256
        t.rect(cx - 80, y + 150, 160, 54, (0.18, 0.38, 0.7))
        t.text((cx, y + 168), "МОЛОКО", 26, (0.97, 0.97, 0.95), cond=True)
        t.text((cx, y + 194), "3,2% · 0,5 л · 18 коп.", 11, (0.97, 0.97, 0.95), bold=False, cond=True)
        img, d = t.layer()
        cow(d, cx, y + 110, 1.0)
        t.over(img)
    wear(t, x, y, W, H, 0.4)


# --- packs (front 0..256, side 256..384, top 384..512) ------------------------

def pack(t, name, bg, title, sub, ink, accent=None, pic=None, side_text=None, kraft=False, title_size=34):
    x, y = cell_xy(name)
    band(t, x, y, W, H, bg)
    if kraft:  # brown paper: fibres and creases
        n = t.noise(20, 4)
        t.shade(n, 0.88, 1.06, (x, y, W, H))
        t.lines(120, 18, np.array(bg) * 0.8, 1, 0.35, (x, y, W, H))
    if accent is not None:
        band(t, x, y + 18, 256, 34, accent)
        band(t, x + 256, y + 18, 128, 34, accent)
    img, d = t.layer()
    cx, cy = x + 128, y + 100
    if pic == "tea":
        d.ellipse((cx - 50, cy - 20, cx + 50, cy + 30), fill=rgb8((0.15, 0.4, 0.2)))
        d.ellipse((cx - 30, cy - 34, cx + 20, cy + 6), fill=rgb8((0.2, 0.5, 0.25)))
    elif pic == "salt":
        for k in range(30):
            px, py = cx - 50 + t.rng.random() * 100, cy - 18 + t.rng.random() * 36
            d.rectangle((px, py, px + 4, py + 4), fill=rgb8((0.9, 0.92, 0.96)))
    elif pic == "wheat":
        for k in range(5):
            bx = cx - 40 + k * 20
            d.line([(bx, cy + 30), (bx + 6, cy - 30)], fill=rgb8((0.75, 0.55, 0.15)), width=3)
            for m in range(5):
                d.ellipse((bx + 2 + m, cy - 28 + m * 8, bx + 10 + m, cy - 20 + m * 8), fill=rgb8((0.85, 0.65, 0.2)))
    elif pic == "macaroni":
        for k in range(14):
            px, py = cx - 60 + t.rng.random() * 120, cy - 20 + t.rng.random() * 40
            d.arc((px, py, px + 22, py + 22), 200, 340, fill=rgb8((0.9, 0.78, 0.4)), width=6)
    elif pic == "chicory":
        d.ellipse((cx - 16, cy - 30, cx + 16, cy + 2), fill=rgb8((0.4, 0.55, 0.85)))
        d.line([(cx, cy), (cx, cy + 36)], fill=rgb8((0.2, 0.5, 0.2)), width=4)
    elif pic == "cup":
        d.rectangle((cx - 28, cy - 18, cx + 24, cy + 26), fill=rgb8((0.95, 0.92, 0.85)))
        d.arc((cx + 14, cy - 10, cx + 40, cy + 14), 270, 90, fill=rgb8((0.95, 0.92, 0.85)), width=6)
        d.ellipse((cx - 26, cy - 22, cx + 22, cy - 12), fill=rgb8((0.35, 0.2, 0.1)))
    t.over(img)
    t.text((x + 128, y + 160), title, title_size if "\n" not in title else title_size - 8, ink, cond=True, spacing=2)
    if sub:
        t.text((x + 128, y + 208), sub, 14, ink, bold=False, cond=True)
    t.text((x + 128, y + 236), "ГОСТ · цена " + ("%d коп." % (8 + (sum(map(ord, name)) % 60))), 11,
           np.array(ink) * 0.7 + np.array(bg) * 0.3, bold=False, cond=True)
    # Side: the small print, the factory.
    t.text((x + 320, y + 130), side_text or "Свердловский\nпищекомбинат\n\nмасса нетто\n\nдата\nизготовления", 12,
           np.array(ink) * 0.8 + np.array(bg) * 0.2, bold=False, cond=True, spacing=3)
    # Top: plain with a fold line.
    band(t, x + 384, y + 124, 128, 4, np.array(bg) * 0.75)
    band(t, x + 254, y, 4, H, np.array(bg) * 0.8)
    band(t, x + 382, y, 4, H, np.array(bg) * 0.8)
    wear(t, x, y, W, H, 0.5 if not kraft else 0.2)


def matches(t):
    """A block of ten boxes wrapped in grey paper, the labels showing at the
    ends; front shows ten box edges under the wrap."""
    x, y = cell_xy("matches")
    band(t, x, y, W, H, (0.72, 0.7, 0.62))
    for k in range(5):
        bx = x + k * 51
        t.rect(bx + 2, y + 40, 48, 176, (0.85, 0.55, 0.15))
        t.rect(bx + 2, y + 40, 48, 8, (0.35, 0.15, 0.08))
        t.rect(bx + 2, y + 208, 48, 8, (0.35, 0.15, 0.08))
        t.text((bx + 26, y + 128), "СПИЧКИ", 13, (0.25, 0.12, 0.05), cond=True)
    band(t, x, y + 104, 256, 46, (0.85, 0.84, 0.78))
    t.text((x + 128, y + 127), "СПИЧКИ · 10 коробок · 10 коп.", 15, (0.25, 0.25, 0.3), cond=True)
    # Side: the label of one box: a rocket, for the space age.
    t.rect(x + 260, y + 30, 120, 196, (0.15, 0.25, 0.5))
    img, d = t.layer()
    d.polygon([(x + 320, y + 60), (x + 334, y + 150), (x + 306, y + 150)], fill=(235, 235, 235, 255))
    d.polygon([(x + 306, y + 150), (x + 296, y + 172), (x + 310, y + 160)], fill=(200, 60, 40, 255))
    d.polygon([(x + 334, y + 150), (x + 344, y + 172), (x + 330, y + 160)], fill=(200, 60, 40, 255))
    t.over(img)
    t.text((x + 320, y + 196), "Слава\nОктябрю", 13, (0.95, 0.9, 0.7), cond=True)
    band(t, x + 384, y, 128, H, (0.72, 0.7, 0.62))
    t.lines(30, 30, (0.6, 0.58, 0.5), 1, 0.5, (x, y, W, H))


# --- refrigerated goods --------------------------------------------------------

def butter(t):
    """Brick of butter in foil-lined parchment: «Масло Крестьянское»."""
    x, y = cell_xy("butter")
    band(t, x, y, W, H, (0.93, 0.88, 0.62))
    t.rect(x, y + 60, 256, 120, (0.85, 0.18, 0.14))
    t.text((x + 128, y + 96), "МАСЛО", 36, (0.98, 0.94, 0.75), cond=True)
    t.text((x + 128, y + 140), "КРЕСТЬЯНСКОЕ", 22, (0.98, 0.94, 0.75), cond=True)
    t.text((x + 128, y + 210), "сливочное · 200 г · 72 коп.", 13, (0.4, 0.2, 0.1), bold=False, cond=True)
    t.text((x + 320, y + 128), "Ирбитский\nмолочный\nзавод", 14, (0.4, 0.2, 0.1), bold=False, cond=True)
    img, d = t.layer()
    cow(d, x + 448, y + 128, 1.3, (0.98, 0.94, 0.75), (0.85, 0.18, 0.14))
    t.over(img)
    t.lines(60, 40, (1, 1, 0.95), 1, 0.25, (x, y, W, H))


def cheese(t):
    """Cheese: waxed red rind (front/side) and the cut face (top), yellow
    with holes."""
    x, y = cell_xy("cheese")
    band(t, x, y, 384, H, (0.72, 0.14, 0.1))
    t.shade(t.noise(40, 3), 0.85, 1.08, (x, y, 384, H))
    t.text((x + 128, y + 128), "СЫР «РОССИЙСКИЙ»", 16, (0.5, 0.08, 0.06), cond=True, opacity=0.8)
    band(t, x + 384, y, 128, H, (0.95, 0.8, 0.38))
    img, d = t.layer()
    for _ in range(26):
        px, py = x + 390 + t.rng.random() * 116, y + 6 + t.rng.random() * 240
        r = 2 + t.rng.random() * 6
        d.ellipse((px - r, py - r, px + r, py + r), fill=rgb8((0.78, 0.6, 0.22)))
    t.over(img)


def sausage(t):
    """«Докторская» in its casing: pink with tied ends (side wrap), and the
    cut face (the right quarter): pink with fat specks."""
    x, y = cell_xy("sausage")
    band(t, x, y, 384, H, (0.82, 0.5, 0.48))
    t.shade(t.noise(30, 4), 0.88, 1.06, (x, y, 384, H))
    t.lines(40, 50, (0.95, 0.7, 0.66), 1, 0.4, (x, y, 384, H), angle=0.0, jitter=0.2)
    for k in range(3):
        t.text((x + 64 + k * 128, y + 128), "ДОКТОРСКАЯ", 14, (0.55, 0.25, 0.25), cond=True, opacity=0.7)
    band(t, x + 384, y, 128, H, (0.92, 0.62, 0.6))
    img, d = t.layer()
    for _ in range(60):
        px, py = x + 388 + t.rng.random() * 120, y + t.rng.random() * 250
        d.ellipse((px, py, px + 3, py + 2), fill=rgb8((0.98, 0.92, 0.88)))
    t.over(img)


def pelmeni(t):
    """«Пельмени Сибирские»: a cardboard box, white and red."""
    pack(t, "pelmeni", (0.94, 0.93, 0.88), "ПЕЛЬМЕНИ", "СИБИРСКИЕ · 500 г · 1 р. 12 к.", (0.72, 0.1, 0.08),
         accent=(0.72, 0.1, 0.08), side_text="Свердловский\nмясокомбинат\n\nхранить при\nт-ре не выше\n-10°С")
    x, y = cell_xy("pelmeni")
    img, d = t.layer()
    for k in range(5):
        px = x + 50 + k * 34
        d.ellipse((px, y + 84, px + 30, y + 112), fill=rgb8((0.95, 0.9, 0.76)))
        d.arc((px, y + 84, px + 30, y + 112), 180, 360, fill=rgb8((0.75, 0.68, 0.5)), width=3)
    t.over(img)
    # Frost over the whole cell.
    t.stain(t.noise(30, 5), 0.55, (0.92, 0.95, 0.98), 0.6, (x, y, W, H))


def fish_block(t):
    """A frozen block of минтай: grey-silver fish pressed together under a
    crust of ice, a paper tag stuck on top."""
    x, y = cell_xy("fish")
    band(t, x, y, W, H, (0.5, 0.55, 0.6))
    img, d = t.layer()
    for _ in range(40):
        px, py = x + t.rng.random() * W, y + t.rng.random() * H
        fish(d, px, py, 1.2 + t.rng.random() * 0.8, (0.55 + t.rng.random() * 0.2,) * 2 + (0.66,), eye=True)
    t.over(img)
    t.stain(t.noise(25, 5), 0.45, (0.85, 0.9, 0.95), 0.75, (x, y, W, H))
    t.rect(x + 400, y + 100, 90, 50, (0.9, 0.88, 0.8))
    t.text((x + 445, y + 125), "МИНТАЙ\n10 кг", 13, (0.2, 0.2, 0.3), cond=True)


def chicken(t):
    """Soviet frozen chicken, the famous «синяя птица»: pale bluish skin,
    goose pimples, yellowish fat at the folds."""
    x, y = cell_xy("chicken")
    band(t, x, y, W, H, (0.78, 0.76, 0.8))
    n = t.noise(30, 4)
    t.mix((0.62, 0.66, 0.78), n * 0.8, (x, y, W, H))
    t.stain(t.noise(60, 3), 0.6, (0.88, 0.8, 0.55), 0.45, (x, y, W, H))
    img, d = t.layer()
    for _ in range(900):
        px, py = x + t.rng.random() * W, y + t.rng.random() * H
        d.point((px, py), fill=(90, 90, 110, 160))
    t.over(img)
    t.stain(t.noise(18, 5), 0.6, (0.92, 0.95, 0.98), 0.5, (x, y, W, H))


def plombir(t):
    """Ice-cream: «Пломбир» in a waffle cup (side wrap) with a paper lid,
    blue and white."""
    x, y = cell_xy("plombir")
    band(t, x, y, W, H, (0.86, 0.66, 0.36))
    img, d = t.layer()
    for k in range(0, W, 24):  # waffle diamonds
        d.line([(x + k, y), (x + k + 128, y + H)], fill=rgb8((0.7, 0.5, 0.25)), width=3)
        d.line([(x + k, y + H), (x + k + 128, y)], fill=rgb8((0.7, 0.5, 0.25)), width=3)
    t.over(img)
    band(t, x, y, W, 40, (0.2, 0.35, 0.7))
    for k in range(4):
        t.text((x + 64 + k * 128, y + 20), "ПЛОМБИР", 16, (0.96, 0.96, 0.95), cond=True)


def metal(t):
    """Plain tinplate for rims and the edges of lids; lacquered gold in the
    right half."""
    x, y = cell_xy("metal")
    band(t, x, y, 256, H, (0.74, 0.74, 0.7))
    band(t, x + 256, y, 256, H, (0.78, 0.6, 0.28))
    t.lines(80, 60, (0.95, 0.95, 0.92), 1, 0.3, (x, y, W, H), angle=0.0, jitter=0.1)
    rust(t, x, y + 200, W, 56, 8)


# --- assembly -----------------------------------------------------------------

def goods(name):
    t = T(W * COLS, H * 8, (0.5, 0.5, 0.5), name)
    tin_label(t, "peas", (0.9, 0.86, 0.6), "ГОРОШЕК\nЗЕЛЁНЫЙ", "консервированный · 560 г", (0.2, 0.38, 0.14),
              "peas", accent=(0.2, 0.45, 0.18), price="Цена 30 коп.")
    condensed(t)
    tin_label(t, "tushonka", (0.92, 0.82, 0.46), "ГОВЯДИНА\nТУШЁНАЯ", "высший сорт · 338 г", (0.38, 0.18, 0.08),
              "cow", accent=(0.6, 0.2, 0.1), price="Цена 1 р. 10 к.")
    tin_label(t, "kapusta", (0.32, 0.55, 0.58), "МОРСКАЯ\nКАПУСТА", "салат дальневосточный", (0.95, 0.95, 0.88),
              "kelp", accent=(0.2, 0.35, 0.4), price="Цена 25 коп.")
    kilka(t)
    lids(t)
    jar_label(t, "ikra", (0.78, 0.45, 0.16), "ИКРА", "кабачковая · 0,5 л", (0.95, 0.92, 0.8), (0.5, 0.2, 0.1), "ikra")
    jar_label(t, "jar_tomato", (0.62, 0.08, 0.05), "СОК ТОМАТНЫЙ", "с солью · 3 л · 1 р. 50 к.", (0.95, 0.9, 0.75),
              (0.65, 0.1, 0.06), "tomato")
    jar_label(t, "jar_birch", (0.86, 0.85, 0.75), "СОК БЕРЁЗОВЫЙ", "натуральный · 3 л · 90 коп.", (0.85, 0.92, 0.82),
              (0.15, 0.4, 0.2), "birch")
    jar_label(t, "jar_apple", (0.78, 0.55, 0.12), "СОК ЯБЛОЧНЫЙ", "с мякотью · 3 л · 1 р. 80 к.", (0.95, 0.9, 0.7),
              (0.5, 0.3, 0.05), "apple")
    oil(t)
    glass_milk(t)
    tetra(t)
    pack(t, "salt", (0.95, 0.95, 0.94), "СОЛЬ\n«ЭКСТРА»", "поваренная пищевая · 1 кг", (0.15, 0.3, 0.6),
         accent=(0.15, 0.3, 0.6), pic="salt", side_text="Артёмовский\nсолекомбинат\n\nмасса нетто\n1000 г")
    pack(t, "tea", (0.2, 0.42, 0.25), "ЧАЙ\nГРУЗИНСКИЙ", "байховый чёрный · № 36 · 50 г", (0.95, 0.85, 0.35),
         accent=(0.75, 0.6, 0.15), pic="tea", side_text="Грузчайпром\n\nсорт первый\n\nцена 38 коп.")
    pack(t, "macaroni", (0.9, 0.88, 0.8), "МАКАРОНЫ", "трубчатые · высший сорт · 1 кг", (0.15, 0.25, 0.55),
         accent=(0.15, 0.25, 0.55), pic="macaroni")
    matches(t)
    pack(t, "flour", (0.86, 0.84, 0.78), "МУКА\nПШЕНИЧНАЯ", "высший сорт · 2 кг", (0.15, 0.3, 0.62), pic="wheat",
         side_text="Свердловский\nмелькомбинат\n\nмасса нетто\n2 кг")
    pack(t, "sugar", (0.94, 0.94, 0.92), "САХАР-\nПЕСОК", "1 кг · 94 коп.", (0.72, 0.12, 0.1), accent=(0.72, 0.12, 0.1))
    pack(t, "chicory", (0.45, 0.3, 0.18), "ЦИКОРИЙ", "растворимый · 100 г", (0.95, 0.85, 0.6), pic="chicory",
         accent=(0.25, 0.4, 0.7))
    pack(t, "barley", (0.82, 0.68, 0.42), "ЯЧМЕННЫЙ\nКОЛОС", "кофейный напиток · 200 г", (0.35, 0.18, 0.08),
         pic="cup", accent=(0.35, 0.18, 0.08))
    pack(t, "grechka", (0.66, 0.52, 0.34), "КРУПА\nГРЕЧНЕВАЯ", "ядрица · 1 кг · 52 коп.", (0.2, 0.15, 0.1),
         kraft=True)
    pack(t, "psheno", (0.7, 0.56, 0.36), "ПШЕНО", "шлифованное · 1 кг · 40 коп.", (0.2, 0.15, 0.1), kraft=True,
         title_size=40)
    pack(t, "soda", (0.94, 0.94, 0.94), "СОДА", "питьевая · 500 г · 18 коп.", (0.6, 0.1, 0.1), accent=(0.2, 0.4, 0.75),
         title_size=44)
    butter(t)
    cheese(t)
    sausage(t)
    pelmeni(t)
    fish_block(t)
    chicken(t)
    plombir(t)
    metal(t)
    # Shop light: everything has been handled, a little faded.
    t.shade(t.noise(200, 4), 0.9, 1.03)
    t.grain(0.01)
    t.save(name)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    goods("goods")
    print("made goods")
