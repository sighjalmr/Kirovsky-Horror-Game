#!/usr/bin/env python3
"""Draws the shop-equipment atlas of «Кировский: Закрытие»: textures/equip.png
and the floor decals textures/decals.png.

equip.png is 2048×1024, 4 × 4 cells of 512×256 (see Equip.CELLS in
scripts/equip.gd): the lit till-number boxes over the checkouts, the faces of
the «Ока» cash register, the dial of the ВНЦ scales, the opening-hours plate,
the complaints-book plate, the price board, printed carton sides.

decals.png is 1024×1024, 2 × 2 cells of 512 with alpha cut-outs: a dirty
puddle of melt water, a smashed jar of tomato juice, receipts and wrappers
dropped on the floor, dry boot prints.

    python3 tools/make_equip.py
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_textures import OUT, T, rgb8  # noqa: E402

W, H = 512, 256
CELLS = [
    "kassa1", "kassa2", "kassa3", "dial",
    "reg_front", "reg_keys", "reg_side", "reg_top",
    "hours", "complaints", "prices", "carton_fish",
    "carton_milk", "carton_tins", "receipt", "bottle_crate",
]


def xy(name):
    i = CELLS.index(name)
    return (i % 4) * W, (i // 4) * H


def kassa(t, n):
    """Lit box over a till: white opal glass, red lettering, a dark frame."""
    x, y = xy("kassa%d" % n)
    t.rect(x, y, W, H, (0.2, 0.18, 0.16))
    t.rect(x + 10, y + 10, W - 20, H - 20, (0.97, 0.95, 0.88))
    t.text((x + 200, y + 128), "КАССА", 74, (0.75, 0.1, 0.08), cond=True)
    t.rect(x + 360, y + 40, 120, 176, (0.75, 0.1, 0.08))
    t.text((x + 420, y + 128), str(n), 130, (0.97, 0.95, 0.88))
    t.stain(t.noise(60, 3), 0.65, (0.75, 0.7, 0.55), 0.3, (x, y, W, H))


def dial(t):
    """ВНЦ-2 dial (left half): 0–2 kg round the face, tare and price scales,
    the red needle; right half: the enamel of the head with the maker's plate."""
    x, y = xy("dial")
    t.rect(x, y, W, H, (0.86, 0.86, 0.82))
    img, d = t.layer()
    cx, cy, r = x + 128, y + 128, 120
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(242, 240, 230, 255), outline=(40, 40, 40, 255), width=4)
    for k in range(101):
        a = math.radians(-90 + k * 3.6)
        ln = 18 if k % 10 == 0 else (11 if k % 5 == 0 else 6)
        d.line([(cx + math.cos(a) * (r - 8), cy + math.sin(a) * (r - 8)),
                (cx + math.cos(a) * (r - 8 - ln), cy + math.sin(a) * (r - 8 - ln))], fill=(30, 30, 30, 255),
               width=2 if k % 10 == 0 else 1)
    d.ellipse((cx - 60, cy - 60, cx + 60, cy + 60), outline=(170, 40, 30, 255), width=2)
    a = math.radians(-90 + 37 * 3.6)
    d.line([(cx, cy), (cx + math.cos(a) * (r - 14), cy + math.sin(a) * (r - 14))], fill=(200, 30, 20, 255), width=4)
    d.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(30, 30, 30, 255))
    t.over(img)
    for k in range(10):
        a = math.radians(-90 + k * 36)
        t.text((cx + math.cos(a) * (r - 42), cy + math.sin(a) * (r - 42)), "%d00" % (k * 2) if k else "0", 12,
               (0.15, 0.15, 0.15), bold=False, cond=True)
    t.text((cx, cy + 40), "ВНЦ-2", 14, (0.2, 0.2, 0.2), cond=True)
    t.text((cx, cy - 36), "г", 14, (0.2, 0.2, 0.2), bold=False)
    t.rect(x + 300, y + 100, 170, 56, (0.7, 0.68, 0.6))
    t.text((x + 385, y + 128), "ТУЛЬСКИЙ\nЗАВОД ВЕСОВ", 14, (0.2, 0.2, 0.2), cond=True, spacing=2)


def register(t):
    """«Ока» electromechanical register, cream and dark brown."""
    cream, brown = (0.84, 0.8, 0.7), (0.28, 0.2, 0.16)
    x, y = xy("reg_front")  # front: display windows over the drawer
    t.rect(x, y, W, H, cream)
    t.rect(x, y + 150, W, 106, brown)
    t.rect(x + 80, y + 30, 352, 70, (0.08, 0.08, 0.07))
    for k in range(7):
        t.rect(x + 92 + k * 48, y + 38, 40, 54, (0.92, 0.9, 0.82))
        t.text((x + 112 + k * 48, y + 65), "0" if k < 4 else "472"[k - 4], 36, (0.1, 0.1, 0.1), serif=True)
    t.text((x + 256, y + 124), "ОКА", 24, (0.45, 0.35, 0.25), cond=True)
    t.rect(x + 210, y + 196, 92, 16, (0.65, 0.6, 0.5))
    x, y = xy("reg_keys")  # keyboard: nine columns of digit keys, red and black function keys
    t.rect(x, y, W, H, (0.2, 0.17, 0.15))
    img, d = t.layer()
    for c in range(9):
        for r in range(9):
            kx, ky = x + 20 + c * 40, y + 12 + r * 27
            d.ellipse((kx, ky, kx + 30, ky + 22), fill=(225, 220, 205, 255) if c % 3 else (190, 185, 170, 255))
    for r in range(4):
        col = (190, 40, 30, 255) if r < 2 else (40, 40, 40, 255)
        d.rounded_rectangle((x + 390, y + 20 + r * 56, x + 492, y + 64 + r * 56), 6, fill=col)
    t.over(img)
    for c in range(9):
        for r in range(9):
            t.text((x + 35 + c * 40, y + 23 + r * 27), str(9 - r), 13, (0.15, 0.15, 0.15))
    for r, s in enumerate(["ИТОГ", "СБРОС", "ОТД", "ЧЕК"]):
        t.text((x + 441, y + 42 + r * 56), s, 15, (0.95, 0.95, 0.9), cond=True)
    x, y = xy("reg_side")  # side panel: louvres, the crank boss
    t.rect(x, y, W, H, cream)
    t.rect(x, y + 150, W, 106, brown)
    for k in range(6):
        t.rect(x + 60, y + 30 + k * 14, 200, 6, (0.6, 0.56, 0.48))
    img, d = t.layer()
    d.ellipse((x + 330, y + 50, x + 410, y + 130), fill=(120, 110, 95, 255))
    d.ellipse((x + 355, y + 75, x + 385, y + 105), fill=(60, 55, 50, 255))
    t.over(img)
    x, y = xy("reg_top")  # top of the display tower and the paper-roll lid
    t.rect(x, y, W, H, cream)
    t.rect(x + 40, y + 60, 200, 136, (0.75, 0.7, 0.6))
    t.rect(x + 300, y + 60, 170, 136, (0.92, 0.92, 0.88))
    t.text((x + 385, y + 128), "КОНТРОЛЬНАЯ\nЛЕНТА", 14, (0.3, 0.3, 0.3), cond=True, bold=False)
    for c in ("reg_front", "reg_side", "reg_top"):
        cx, cy = xy(c)
        t.stain(t.noise(30, 4), 0.62, (0.55, 0.5, 0.4), 0.45, (cx, cy, W, H))


def plates(t):
    x, y = xy("hours")
    t.rect(x, y, W, H, (0.12, 0.14, 0.18))
    t.rect(x + 8, y + 8, W - 16, H - 16, (0.95, 0.93, 0.86))
    t.text((x + 256, y + 44), "УНИВЕРСАМ «КИРОВСКИЙ»", 26, (0.12, 0.14, 0.3), cond=True)
    t.text((x + 256, y + 82), "Свердловский горпищеторг · МЖК", 15, (0.2, 0.2, 0.3), bold=False, cond=True)
    t.text((x + 256, y + 160), "РЕЖИМ РАБОТЫ\nс 8.00 до 22.00\nперерыв с 13.00 до 14.00\nбез выходных", 20,
           (0.12, 0.12, 0.2), cond=True, spacing=6)
    x, y = xy("complaints")
    t.rect(x, y, W, H, (0.5, 0.12, 0.1))
    t.rect(x + 10, y + 10, W - 20, H - 20, (0.92, 0.88, 0.76))
    t.text((x + 256, y + 90), "КНИГА ЖАЛОБ\nИ ПРЕДЛОЖЕНИЙ", 34, (0.5, 0.12, 0.1), cond=True, spacing=6)
    t.text((x + 256, y + 192), "находится у администратора", 18, (0.3, 0.2, 0.15), bold=False, cond=True)
    x, y = xy("prices")
    t.rect(x, y, W, H, (0.18, 0.2, 0.18))
    t.text((x + 256, y + 30), "ЦЕНЫ", 30, (0.95, 0.92, 0.8), cond=True)
    rows = [("Хлеб пшеничный", "0-20"), ("Молоко 3,2% 0,5 л", "0-18"), ("Сахар-песок 1 кг", "0-94"),
            ("Масло крестьянское 200 г", "0-72"), ("Колбаса докторская 1 кг", "2-20"), ("Куры 1 кг", "2-65")]
    for k, (nm, p) in enumerate(rows):
        t.text((x + 40, y + 70 + k * 30), nm, 17, (0.92, 0.9, 0.82), anchor="lm", bold=False, cond=True)
        t.text((x + 470, y + 70 + k * 30), p, 17, (0.92, 0.9, 0.82), anchor="rm", cond=True)
    t.stain(t.noise(40, 3), 0.6, (0.3, 0.3, 0.28), 0.4, (x, y, W, H))


def cartons(t):
    for name, title, sub in (("carton_fish", "МИНТАЙ\nМОРОЖЕНЫЙ", "Мурманский рыбокомбинат · 24 кг"),
                             ("carton_milk", "МОЛОКО\nСГУЩЁННОЕ", "48 банок · ГОСТ 2903-78"),
                             ("carton_tins", "ГОРОШЕК\nЗЕЛЁНЫЙ", "Молдконсервы · 24 банки")):
        x, y = xy(name)
        t.rect(x, y, W, H, (0.66, 0.5, 0.32))
        t.shade(t.noise(20, 4), 0.86, 1.05, (x, y, W, H))
        t.lines(60, 30, (0.55, 0.4, 0.25), 1, 0.4, (x, y, W, H))
        t.rect(x, y + 112, W, 30, (0.75, 0.62, 0.42))  # packing tape
        t.text((x + 256, y + 70), title, 30, (0.2, 0.15, 0.25), cond=True, spacing=2, rough=0.3, opacity=0.85)
        t.text((x + 256, y + 190), sub, 16, (0.2, 0.15, 0.25), bold=False, cond=True, rough=0.3, opacity=0.8)
        t.text((x + 440, y + 225), "↑ ↑", 26, (0.2, 0.15, 0.25), rough=0.3, opacity=0.8)


def receipt(t):
    x, y = xy("receipt")
    t.rect(x, y, W, H, (0.93, 0.92, 0.86))
    for k in range(8):
        t.text((x + 128, y + 24 + k * 26), "00%d  *%d-%02d" % (k + 1, k % 3, (k * 17) % 100), 16, (0.35, 0.25, 0.45),
               bold=False)
    t.text((x + 384, y + 128), "КИРОВСКИЙ\nСПАСИБО\nЗА ПОКУПКУ", 20, (0.35, 0.25, 0.45), bold=False, spacing=8)
    x, y = xy("bottle_crate")  # galvanised wire grid for the bottle crates (alpha holes)
    t.rect(x, y, W, H, (0, 0, 0, 0))
    for k in range(0, W, 32):
        t.rect(x + k, y, 5, H, (0.62, 0.64, 0.62))
    for k in range(0, H, 32):
        t.rect(x, y + k, W, 5, (0.62, 0.64, 0.62))
    t.a[y:y + H, x:x + W, 3] = np.where(t.a[y:y + H, x:x + W, 0] > 0.3, 1.0, 0.0)


def equip(name):
    t = T(W * 4, H * 4, (0.5, 0.5, 0.5), name)
    for n in (1, 2, 3):
        kassa(t, n)
    dial(t)
    register(t)
    plates(t)
    cartons(t)
    receipt(t)
    t.grain(0.008)
    t.save(name)


def decals(name):
    """Four 512 px decals with alpha: puddle, smashed juice jar, litter,
    boot prints."""
    t = T(1024, 1024, (0, 0, 0, 0), name)
    t.a[..., 3] = 0
    yy, xx = np.mgrid[0:1024, 0:1024].astype(np.float32)
    n = t.noise(90, 5)

    def blob(cx, cy, r, warp):
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r + (n - 0.5) * warp
        return d < 1.0

    # Puddle: grey-brown water with a darker rim.
    m = blob(256, 256, 200, 1.2)
    t.a[m, :3] = np.array((0.22, 0.21, 0.19))
    t.a[m, 3] = 1.0
    # Smashed jar of tomato juice: a red pool, glass shards, the lid.
    m = blob(768, 256, 170, 1.4)
    shade = (0.55 + 0.45 * t.noise(40, 4))[..., None]
    t.a[m, :3] = (np.array((0.3, 0.035, 0.025)) * shade)[m]
    t.a[m, 3] = 1.0
    img, d = t.layer()
    rng = t.rng
    for _ in range(18):
        cx, cy = 768 + rng.normal(0, 120), 256 + rng.normal(0, 110)
        s = rng.uniform(5, 14)
        pts = [(cx + math.cos(a) * s * rng.uniform(0.4, 1), cy + math.sin(a) * s * rng.uniform(0.4, 1))
               for a in np.linspace(0, 2 * math.pi, 4, endpoint=False) + rng.uniform(0, 1)]
        d.polygon(pts, fill=(150, 165, 160, 255))
    d.ellipse((700, 300, 760, 360), fill=(200, 160, 70, 255))
    t.over(img)
    t.a[0:512, 512:1024, 3] = np.where(np.asarray(img)[0:512, 512:1024, 3] > 0, 1.0, t.a[0:512, 512:1024, 3])
    # Litter: receipts, a sweet wrapper, a crumpled bag.
    img, d = t.layer()
    for _ in range(9):
        cx, cy = rng.uniform(60, 450), 512 + rng.uniform(60, 450)
        a = rng.uniform(0, math.pi)
        w, h = rng.uniform(30, 60), rng.uniform(70, 130)
        pts = [(cx + math.cos(a) * dx - math.sin(a) * dy, cy + math.sin(a) * dx + math.cos(a) * dy)
               for dx, dy in ((-w, -h), (w, -h), (w, h), (-w, h))]
        d.polygon(pts, fill=(235, 232, 220, 255))
        for k in range(5):
            f = -0.7 + k * 0.3
            d.line([(cx + math.cos(a) * -w * 0.7 - math.sin(a) * h * f, cy + math.sin(a) * -w * 0.7 + math.cos(a) * h * f),
                    (cx + math.cos(a) * w * 0.7 - math.sin(a) * h * f, cy + math.sin(a) * w * 0.7 + math.cos(a) * h * f)],
                   fill=(110, 90, 140, 255), width=2)
    d.rectangle((300, 800, 360, 830), fill=(200, 40, 40, 255))
    d.rectangle((310, 805, 350, 825), fill=(240, 200, 60, 255))
    t.over(img)
    t.a[512:1024, 0:512, 3] = (np.asarray(img)[512:1024, 0:512, 3] > 0).astype(np.float32)
    # Boot prints: dried dirt, heading across the cell.
    img, d = t.layer()
    for k in range(6):
        cx = 600 + k * 70
        cy = 768 + (40 if k % 2 else -40)
        d.ellipse((cx - 22, cy - 14, cx + 30, cy + 14), fill=(70, 60, 50, 200))
        d.ellipse((cx - 50, cy - 11, cx - 30, cy + 11), fill=(70, 60, 50, 200))
    t.over(img, blur=1.0)
    t.a[512:1024, 512:1024, 3] = (np.asarray(img)[512:1024, 512:1024, 3] > 60).astype(np.float32)
    t.save(name)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    equip("equip")
    decals("decals")
    print("made equip decals")
