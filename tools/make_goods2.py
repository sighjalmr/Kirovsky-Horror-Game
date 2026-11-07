#!/usr/bin/env python3
"""Draws the second goods atlas of «Кировский»: textures/goods2.png.

Same layout as goods.png (4 × 8 cells of 512×256, see make_goods.py), for
the range the Blender kit added (tools/blender/build_goods.py): bread from
the Свердловский хлебозавод, пряники and «Юбилейное», coffee and cocoa,
«Геркулес», вермишель, кисель, bay leaf, lemonade «Буратино» and «Тархун»,
mineral water «Обуховская», eggs, сырки, tomato paste, mustard, сайра,
«Завтрак туриста», бычки в томате, aubergine caviar, household soap, tooth
powder, corn sticks and caramels.

    python3 tools/make_goods2.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_goods as g  # noqa: E402
from make_goods import W, H, COLS, band, wear, rust, tin_rims, pack, tin_label, jar_label, fish, tomato  # noqa
from make_textures import OUT, rgb8  # noqa: E402
from make_textures import T  # noqa: E402

CELLS = [
    "baton", "borodinsky", "kirpich", "bulka",
    "pryaniki", "yubileynoe", "coffee", "kakao",
    "gerkules", "vermishel", "kisel", "lavr",
    "buratino", "tarhun", "mineral", "bottles",
    "eggs", "syrki", "tomato_paste", "gorchitsa",
    "saira", "turist", "bychki", "baklazhan",
    "soap", "zubnoy", "palochki", "karamel",
    "lids2", "kraft", "yogurt", "metal2",
]
g.CELLS = CELLS  # the helpers of make_goods place cells by this list
cell_xy = g.cell_xy


def crust(t, name, top, side, bottom, slashes=0, seeds=False, dark=False):
    """Bread: front/back = the side crust, sides = the ends, the last
    quarter = the top crust (bursting, glossy, darker)."""
    x, y = cell_xy(name)
    n = t.noise(14, 4)[y:y + H, x:x + W]
    reg = np.ones((H, W, 3), np.float32) * np.array(side, np.float32)
    yy = np.mgrid[0:H, 0:W][0].astype(np.float32) / H
    # Top of each face darker (baked harder), the bottom pale where it sat.
    k = np.clip(1.15 - yy * 0.5, 0.6, 1.2)[..., None]
    reg = reg * k
    reg[int(H * 0.8):] = np.array(bottom)
    reg[:, 384:] = np.array(top) * (0.85 + 0.3 * n[:, 384:, None])
    reg *= (0.85 + 0.3 * n[..., None])
    t.a[y:y + H, x:x + W, :3] = np.clip(reg, 0, 1)
    img, d = t.layer()
    if slashes:
        for i in range(slashes):
            cx = x + 384 + 128 * (i + 0.5) / slashes
            d.line([(cx - 16, y + 30), (cx + 16, y + 226)], fill=rgb8(np.array(top) * 1.5 + 0.1), width=9)
    if seeds:
        for _ in range(300):
            px, py = x + t.rng.random() * W, y + t.rng.random() * H * 0.8
            d.ellipse((px, py, px + 3, py + 3), fill=rgb8((0.55, 0.42, 0.25)))
    t.over(img, 0.85)
    if dark:
        t.lines(60, 20, (0.1, 0.06, 0.04), 1, 0.4, (x, y, W, H))


def bulka(t):
    x, y = cell_xy("bulka")
    yy = np.mgrid[0:H, 0:W][0].astype(np.float32) / H
    n = t.noise(10, 4)[y:y + H, x:x + W]
    top = np.array((0.62, 0.36, 0.12))
    low = np.array((0.88, 0.72, 0.45))
    reg = top[None, None] * (1 - yy[..., None]) ** 0.6 + low[None, None] * (1 - (1 - yy[..., None]) ** 0.6)
    reg *= (0.85 + 0.3 * n[..., None])
    t.a[y:y + H, x:x + W, :3] = np.clip(reg, 0, 1)
    img, d = t.layer()
    for _ in range(140):  # poppy-free, a few sugar crumbs on the glaze
        px, py = x + t.rng.random() * W, y + t.rng.random() * H * 0.4
        d.ellipse((px, py, px + 3, py + 2), fill=(250, 240, 220, 180))
    t.over(img)


def bottle_label(t, name, liquid, glass, title, sub, label_bg, ink, neck_label=None):
    """A 0.5 l lemonade or mineral water bottle: coloured glass with the
    drink inside, a paper label round the body and a small one on the neck."""
    x, y = cell_xy(name)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    reg = np.ones((H, W, 3), np.float32) * np.array(liquid, np.float32)
    reg[:62] = np.array(glass) * 0.8  # neck: the glass over air
    reg *= (0.8 + 0.2 * (yy / H))[..., None]
    for c in (0.2, 0.7):
        reg += (np.exp(-((xx / W - c) ** 2) / 0.0005) * 0.35)[..., None]
    t.a[y:y + H, x:x + W, :3] = np.clip(reg, 0, 1)
    band(t, x, y + 124, W, 88, label_bg)
    for rep in range(2):
        cx = x + 128 + rep * 256
        t.text((cx, y + 152), title, 24 if len(title) < 10 else 18, ink, cond=True)
        t.text((cx, y + 186), sub, 12, ink, bold=False, cond=True)
    band(t, x, y + 124, W, 3, np.array(label_bg) * 0.7)
    band(t, x, y + 209, W, 3, np.array(label_bg) * 0.7)
    if neck_label:
        band(t, x, y + 70, W, 22, neck_label)
    wear(t, x, y + 124, W, 88, 0.6)


def lids2(t):
    """Crown corks (Буратино, Тархун, Обуховская) and a foil cap (простокваша)
    in the top row; plain tin, red lacquer, white enamel, blue foil below."""
    x, y = cell_xy("lids2")
    band(t, x, y, W, H, (0.3, 0.3, 0.3))
    img, d = t.layer()
    cols = [(0.8, 0.65, 0.2), (0.25, 0.5, 0.3), (0.75, 0.75, 0.72), (0.3, 0.45, 0.8),
            (0.72, 0.72, 0.68), (0.7, 0.15, 0.1), (0.9, 0.9, 0.86), (0.2, 0.35, 0.7)]
    for k, c in enumerate(cols):
        cx, cy = x + 64 + (k % 4) * 128, y + 64 + (k // 4) * 128
        d.ellipse((cx - 60, cy - 60, cx + 60, cy + 60), fill=rgb8(c))
        d.ellipse((cx - 44, cy - 44, cx + 44, cy + 44), outline=rgb8(np.array(c) * 0.7), width=3)
    t.over(img)
    for k, w in enumerate(["ЛИМОНАД", "ТАРХУН", "ОБУХОВСКАЯ", "ПРОСТОКВАША"]):
        t.text((x + 64 + k * 128, y + 64), w, 13 if len(w) < 10 else 10, (0.15, 0.12, 0.1), cond=True)


def eggs(t):
    x, y = cell_xy("eggs")
    band(t, x, y, W, H, (0.62, 0.6, 0.56))
    n = t.noise(6, 3)
    t.shade(n, 0.85, 1.08, (x, y, W, H))
    # The paper band across the lid (first three quarters).
    band(t, x, y + 80, 384, 96, (0.95, 0.93, 0.86))
    t.text((x + 192, y + 110), "ЯЙЦА КУРИНЫЕ", 26, (0.6, 0.12, 0.08), cond=True)
    t.text((x + 192, y + 146), "диетические · 1 категория · 10 шт. · 1 р. 30 к.", 13, (0.3, 0.2, 0.15), bold=False,
           cond=True)
    t.text((x + 192, y + 166), "Свердловская птицефабрика «Рефтинская»", 11, (0.3, 0.2, 0.15), bold=False, cond=True)


def soap(t):
    x, y = cell_xy("soap")
    band(t, x, y, W, H, (0.55, 0.38, 0.18))
    n = t.noise(30, 4)
    t.shade(n, 0.85, 1.1, (x, y, W, H))
    for rep in range(2):
        t.text((x + 128 + rep * 256, y + 110), "72%", 48, (0.4, 0.26, 0.1), cond=True)
        t.text((x + 128 + rep * 256, y + 164), "ХОЗЯЙСТВЕННОЕ", 18, (0.4, 0.26, 0.1), cond=True)


def syrki(t):
    x, y = cell_xy("syrki")
    band(t, x, y, W, H, (0.82, 0.82, 0.8))
    t.lines(200, 30, (1, 1, 1), 1, 0.4, (x, y, W, H))
    band(t, x + 20, y + 60, 216, 120, (0.85, 0.15, 0.2))
    t.text((x + 128, y + 104), "СЫРОК", 32, (0.98, 0.95, 0.9), cond=True)
    t.text((x + 128, y + 146), "глазированный · 15 коп.", 13, (0.98, 0.95, 0.9), bold=False, cond=True)


def kraft(t):
    x, y = cell_xy("kraft")
    band(t, x, y, W, H, (0.66, 0.5, 0.32))
    t.shade(t.noise(20, 4), 0.85, 1.08, (x, y, W, H))
    t.lines(120, 18, (0.5, 0.38, 0.24), 1, 0.35, (x, y, W, H))


def metal2(t):
    x, y = cell_xy("metal2")
    band(t, x, y, 256, H, (0.74, 0.74, 0.7))
    band(t, x + 256, y, 256, H, (0.6, 0.62, 0.66))
    t.lines(80, 60, (0.95, 0.95, 0.92), 1, 0.3, (x, y, W, H), angle=0.0, jitter=0.1)


def goods2(name):
    t = T(W * COLS, H * 8, (0.5, 0.5, 0.5), name)
    crust(t, "baton", (0.66, 0.4, 0.14), (0.78, 0.56, 0.28), (0.85, 0.72, 0.5), slashes=5)
    crust(t, "borodinsky", (0.2, 0.11, 0.06), (0.24, 0.14, 0.08), (0.32, 0.2, 0.12), seeds=True, dark=True)
    crust(t, "kirpich", (0.68, 0.42, 0.16), (0.82, 0.64, 0.38), (0.86, 0.74, 0.52))
    bulka(t)
    pack(t, "pryaniki", (0.92, 0.86, 0.7), "ПРЯНИКИ", "мятные · 500 г · 70 коп.", (0.55, 0.25, 0.1),
         accent=(0.55, 0.25, 0.1), side_text="Свердловская\nкондитерская\nфабрика")
    pack(t, "yubileynoe", (0.2, 0.32, 0.62), "ЮБИЛЕЙНОЕ", "печенье сахарное · 225 г", (0.98, 0.9, 0.5),
         accent=(0.85, 0.7, 0.2), title_size=30)
    tin_label(t, "coffee", (0.35, 0.18, 0.1), "КОФЕ\nНАТУРАЛЬНЫЙ", "молотый · высший сорт · 100 г",
              (0.95, 0.82, 0.45), None, accent=(0.85, 0.65, 0.2), price="Цена 1 р. 40 к.")
    pack(t, "kakao", (0.55, 0.28, 0.12), "КАКАО", "«Золотой ярлык» · 100 г", (0.95, 0.85, 0.4), pic="cup",
         accent=(0.85, 0.65, 0.2), title_size=40)
    pack(t, "gerkules", (0.9, 0.8, 0.55), "ГЕРКУЛЕС", "овсяные хлопья · 500 г · 36 коп.", (0.7, 0.15, 0.1),
         pic="wheat", accent=(0.7, 0.15, 0.1), title_size=34)
    pack(t, "vermishel", (0.88, 0.86, 0.8), "ВЕРМИШЕЛЬ", "высший сорт · 1 кг · 46 коп.", (0.2, 0.35, 0.6),
         pic="macaroni", title_size=32)
    pack(t, "kisel", (0.65, 0.12, 0.15), "КИСЕЛЬ", "клюквенный · брикет 250 г", (0.98, 0.92, 0.85), title_size=36)
    pack(t, "lavr", (0.25, 0.45, 0.25), "ЛИСТ\nЛАВРОВЫЙ", "10 г · 10 коп.", (0.95, 0.92, 0.75))
    bottle_label(t, "buratino", (0.95, 0.78, 0.32), (0.75, 0.82, 0.78), "БУРАТИНО", "лимонад · 0,5 л · 22 коп.",
                 (0.95, 0.6, 0.15), (0.2, 0.1, 0.05), neck_label=(0.95, 0.6, 0.15))
    bottle_label(t, "tarhun", (0.4, 0.75, 0.35), (0.6, 0.78, 0.62), "ТАРХУН", "напиток · 0,5 л · 24 коп.",
                 (0.2, 0.45, 0.2), (0.95, 0.92, 0.8), neck_label=(0.2, 0.45, 0.2))
    bottle_label(t, "mineral", (0.28, 0.42, 0.3), (0.22, 0.38, 0.26), "ОБУХОВСКАЯ", "минеральная вода · 0,5 л",
                 (0.9, 0.9, 0.85), (0.15, 0.3, 0.55))
    bottle_label(t, "bottles", (0.45, 0.55, 0.5), (0.55, 0.62, 0.58), "", "", (0.45, 0.55, 0.5), (0, 0, 0))
    eggs(t)
    syrki(t)
    jar_label(t, "tomato_paste", (0.6, 0.1, 0.06), "ТОМАТ-ПАСТА", "30% · 0,5 л · 60 коп.", (0.95, 0.9, 0.75),
              (0.65, 0.1, 0.06), "tomato")
    jar_label(t, "gorchitsa", (0.78, 0.65, 0.25), "ГОРЧИЦА", "столовая · 0,2 л", (0.95, 0.92, 0.8),
              (0.4, 0.3, 0.1), None)
    tin_label(t, "saira", (0.3, 0.45, 0.7), "САЙРА", "натуральная · 250 г", (0.98, 0.95, 0.9), "fish",
              accent=(0.15, 0.25, 0.45), price="Цена 1 р. 10 к.")
    tin_label(t, "turist", (0.85, 0.78, 0.55), "ЗАВТРАК\nТУРИСТА", "рис с говядиной · 338 г", (0.3, 0.2, 0.1),
              "cow", accent=(0.25, 0.45, 0.25), price="Цена 45 коп.")
    tin_label(t, "bychki", (0.75, 0.2, 0.1), "БЫЧКИ", "в томатном соусе · 250 г", (0.98, 0.9, 0.7), "fish",
              accent=(0.95, 0.75, 0.2), price="Цена 38 коп.")
    jar_label(t, "baklazhan", (0.35, 0.22, 0.15), "ИКРА", "баклажанная · 0,5 л", (0.9, 0.85, 0.6),
              (0.35, 0.15, 0.3), "ikra")
    soap(t)
    pack(t, "zubnoy", (0.95, 0.95, 0.95), "ЗУБНОЙ\nПОРОШОК", "«Мятный» · 8 коп.", (0.15, 0.45, 0.6),
         accent=(0.15, 0.45, 0.6), title_size=28)
    pack(t, "palochki", (0.95, 0.85, 0.3), "КУКУРУЗНЫЕ\nПАЛОЧКИ", "сладкие · 100 г · 20 коп.", (0.7, 0.2, 0.1),
         accent=(0.2, 0.4, 0.7), title_size=30)
    pack(t, "karamel", (0.9, 0.92, 0.95), "КАРАМЕЛЬ", "«Клубника со сливками» · 300 г", (0.75, 0.12, 0.2),
         accent=(0.75, 0.12, 0.2), title_size=32)
    lids2(t)
    kraft(t)
    bottle_label(t, "yogurt", (0.95, 0.94, 0.9), (0.6, 0.66, 0.62), "ПРОСТОКВАША", "0,5 л · 28 коп.",
                 (0.3, 0.45, 0.8), (0.98, 0.98, 0.95))
    metal2(t)
    t.shade(t.noise(200, 4), 0.9, 1.03)
    t.grain(0.01)
    t.save(name)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    goods2("goods2")
    print("made goods2")
