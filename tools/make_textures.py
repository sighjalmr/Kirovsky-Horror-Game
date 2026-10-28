#!/usr/bin/env python3
"""Draws every texture of «Кировский: Закрытие» into textures/*.png.

512×512 surfaces (atlas and mapped-once textures keep their proportions),
seamless where they tile, lettering in DejaVu fonts. Each PNG is a plain
file: replace it with a photo or a hand-painted texture of the same name and
proportions and the game picks it up.

    python3 tools/make_textures.py            # all textures
    python3 tools/make_textures.py floor wall # some of them

Needs Python 3, numpy and Pillow, plus the DejaVu fonts (any Linux has them;
on Windows or macOS put DejaVuSans*.ttf next to this script).
"""

import os
import sys
import zlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "textures")
FONT_DIRS = [os.path.dirname(os.path.abspath(__file__)), "/usr/share/fonts/truetype/dejavu",
             "/usr/share/fonts/dejavu", "/Library/Fonts", "C:/Windows/Fonts"]

IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://textures/{name}.png"

[params]

compress/mode=0
mipmaps/generate=true
detect_3d/compress_to=0
process/fix_alpha_border=true
"""


def font(size, bold=True, serif=False, cond=False):
    name = "DejaVu" + ("Serif" if serif else "Sans") + ("Condensed" if cond else "") + ("-Bold" if bold else "") + ".ttf"
    for nm in (name, name.replace("Condensed", "")):
        for d in FONT_DIRS:
            p = os.path.join(d, nm)
            if os.path.exists(p):
                f = ImageFont.truetype(p, size)
                return f

    return ImageFont.load_default(size)


# --- canvas -------------------------------------------------------------------

class Tex:
    """RGBA float canvas, 0..1, rows top to bottom."""

    def __init__(self, w, h, color, seed):
        self.w, self.h = w, h
        self.a = np.zeros((h, w, 4), np.float32)
        self.a[..., :3] = color[:3]
        self.a[..., 3] = 1.0 if len(color) < 4 else color[3]
        self.rng = np.random.default_rng(seed)

    # Value noise, seamless, 0..1. `scale` is the size of the biggest blobs in px.
    def noise(self, scale, octaves=4, persist=0.5, w=None, h=None):
        w = w or self.w
        h = h or self.h
        out = np.zeros((h, w), np.float32)
        amp, tot, s = 1.0, 0.0, float(scale)
        for _ in range(octaves):
            gw, gh = max(2, round(w / s)), max(2, round(h / s))
            g = self.rng.random((gh, gw)).astype(np.float32)
            big = Image.fromarray(np.tile(g, (3, 3)), "F").resize((w * 3, h * 3), Image.BICUBIC)
            out += np.asarray(big)[h:2 * h, w:2 * w] * amp
            tot += amp
            amp *= persist
            s /= 2.0
            if s < 2:
                break
        out -= out.min()
        return out / max(out.max(), 1e-6)

    def rect(self, x, y, w, h, color, alpha=1.0):
        x0, y0, x1, y1 = max(0, int(x)), max(0, int(y)), min(self.w, int(x + w)), min(self.h, int(y + h))
        if x1 <= x0 or y1 <= y0:
            return
        c = np.array(color[:3], np.float32)
        a = alpha * (color[3] if len(color) > 3 else 1.0)
        self.a[y0:y1, x0:x1, :3] = self.a[y0:y1, x0:x1, :3] * (1 - a) + c * a
        if len(color) > 3 and color[3] == 0:
            self.a[y0:y1, x0:x1, 3] = 0

    def mul(self, k, region=None):
        k = np.asarray(k, np.float32)
        if k.ndim == 2:
            k = k[..., None]
        if region is None:
            self.a[..., :3] *= k
        else:
            x, y, w, h = region
            self.a[y:y + h, x:x + w, :3] *= k[y:y + h, x:x + w] if k.ndim == 3 and k.shape[0] == self.h else k

    def shade(self, n, lo, hi, region=None):
        self.mul(lo + (hi - lo) * n, region)

    def mix(self, color, mask, region=None):
        m = np.clip(np.asarray(mask, np.float32), 0, 1)[..., None]
        c = np.array(color[:3], np.float32)
        if region is None:
            self.a[..., :3] = self.a[..., :3] * (1 - m) + c * m
        else:
            x, y, w, h = region
            mm = m[y:y + h, x:x + w]
            self.a[y:y + h, x:x + w, :3] = self.a[y:y + h, x:x + w, :3] * (1 - mm) + c * mm

    def stain(self, n, threshold, color, strength, region=None):
        self.mix(color, np.clip((n - threshold) / (1 - threshold) * 2.0, 0, 1) * strength, region)

    def grain(self, amount):
        self.a[..., :3] += (self.rng.random((self.h, self.w, 1)).astype(np.float32) - 0.5) * 2 * amount

    def layer(self):
        """A transparent PIL layer to draw on; composite it back with over()."""
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        return img, ImageDraw.Draw(img)

    def over(self, img, opacity=1.0, blur=0.0):
        if blur > 0:
            img = img.filter(ImageFilter.GaussianBlur(blur))
        src = np.asarray(img, np.float32) / 255.0
        a = src[..., 3:4] * opacity
        self.a[..., :3] = self.a[..., :3] * (1 - a) + src[..., :3] * a

    def text(self, xy, s, size, color, anchor="mm", bold=True, serif=False, cond=False, opacity=1.0, rough=0.0,
             spacing=4, align="center"):
        img, d = self.layer()
        d.multiline_text(xy, s, font=font(size, bold, serif, cond), fill=rgb8(color), anchor=anchor, spacing=spacing,
                         align=align)
        if rough > 0:  # worn print: knock holes into the letters
            arr = np.asarray(img).copy()
            holes = self.noise(6, 3) < rough
            arr[..., 3] = (arr[..., 3] * ~holes).astype(np.uint8)
            img = Image.fromarray(arr, "RGBA")
        self.over(img, opacity)

    def bevel(self, x, y, w, h, width, light, dark, strength=0.6):
        for i in range(width):
            t = strength * (1 - i / width)
            self.rect(x + i, y + i, w - 2 * i, 1, light, t)
            self.rect(x + i, y + i, 1, h - 2 * i, light, t)
            self.rect(x + i, y + h - 1 - i, w - 2 * i, 1, dark, t)
            self.rect(x + w - 1 - i, y + i, 1, h - 2 * i, dark, t)

    def blob_mask(self, count, rmin, rmax, region=None, rough=0.4):
        """Soft irregular spots, 0..1."""
        x0, y0, w, h = region or (0, 0, self.w, self.h)
        yy, xx = np.mgrid[0:self.h, 0:self.w].astype(np.float32)
        n = self.noise(max(4, rmax), 3)
        m = np.zeros((self.h, self.w), np.float32)
        for _ in range(count):
            cx, cy = x0 + self.rng.random() * w, y0 + self.rng.random() * h
            r = rmin + self.rng.random() * (rmax - rmin)
            d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r + (n - 0.5) * rough
            m = np.maximum(m, np.clip(1 - d, 0, 1))
        return m

    def lines(self, count, length, color, width=1, opacity=0.5, region=None, angle=None, jitter=0.0):
        img, d = self.layer()
        x0, y0, w, h = region or (0, 0, self.w, self.h)
        for _ in range(count):
            px, py = x0 + self.rng.random() * w, y0 + self.rng.random() * h
            a = self.rng.random() * np.pi * 2 if angle is None else angle + (self.rng.random() - 0.5) * jitter
            ln = length * (0.4 + self.rng.random() * 0.6)
            d.line([(px, py), (px + np.cos(a) * ln, py + np.sin(a) * ln)], fill=rgb8(color), width=width)
        self.over(img, opacity)

    def cracks(self, count, steps, color, width=1, opacity=0.8):
        img, d = self.layer()
        for _ in range(count):
            p = np.array([self.rng.random() * self.w, self.rng.random() * self.h])
            a = self.rng.random() * np.pi * 2
            pts = [tuple(p)]
            for _ in range(steps):
                a += (self.rng.random() - 0.5) * 1.2
                p = p + np.array([np.cos(a), np.sin(a)]) * (2 + self.rng.random() * 4)
                pts.append(tuple(p))
                if self.rng.random() < 0.08:  # a branch
                    b = a + (self.rng.random() - 0.5) * 2
                    q = p.copy()
                    br = [tuple(q)]
                    for _ in range(steps // 4):
                        b += (self.rng.random() - 0.5) * 1.2
                        q = q + np.array([np.cos(b), np.sin(b)]) * 3
                        br.append(tuple(q))
                    d.line(br, fill=rgb8(color), width=max(1, width - 1))
            d.line(pts, fill=rgb8(color), width=width)
        self.over(img, opacity)

    def save(self, name):
        arr = np.clip(self.a, 0, 1)
        img = Image.fromarray((arr * 255 + 0.5).astype(np.uint8), "RGBA")
        if np.all(arr[..., 3] >= 0.999):
            img = img.convert("RGB")
        path = os.path.join(OUT, name + ".png")
        img.save(path, optimize=True)
        with open(path + ".import", "w") as f:
            f.write(IMPORT.format(name=name))


def rgb8(c):
    return tuple(int(max(0, min(1, v)) * 255) for v in c[:3]) + (255,)


def blurred(mask, radius):
    """Gaussian blur that wraps round the edges (keeps tiling seamless)."""
    r = int(radius * 3) + 1
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / radius) ** 2)
    k /= k.sum()
    out = mask.astype(np.float32)
    for axis in (0, 1):
        out = sum(np.roll(out, i, axis) * k[i + r] for i in range(-r, r + 1))
    return out


def T(w, h, color, name):
    return Tex(w, h, color, zlib.crc32(name.encode()))


# --- surfaces -----------------------------------------------------------------

def floor(name):
    """Soviet ceramic floor: 4×4 tiles of 30 cm in a checkerboard, terrazzo
    specks, bevelled edges, dirty grout, chipped corners, cracks, grime."""
    t = T(512, 512, (0.2, 0.19, 0.16), name)
    grout = t.noise(40, 3)
    t.shade(grout, 0.7, 1.15)
    fine = t.noise(8, 3)
    for ty in range(4):
        for tx in range(4):
            light = (tx + ty) % 2 == 0
            v = (t.rng.random() - 0.5) * 0.06
            base = np.array((0.66 + v, 0.62 + v, 0.53 + v) if light else (0.42 + v, 0.4 + v, 0.36 + v))
            x, y = tx * 128 + 3, ty * 128 + 3
            t.rect(x, y, 122, 122, base)
            t.mul(0.93 + fine * 0.12, (x, y, 122, 122))
            # Terrazzo chips: small dark and light flecks.
            for _ in range(260):
                px, py = x + t.rng.integers(2, 118), y + t.rng.integers(2, 118)
                s = t.rng.integers(1, 4)
                c = base * (0.55 + t.rng.random() * 0.25) if t.rng.random() < 0.65 else np.minimum(base * 1.3, 1)
                t.rect(px, py, s, s, c)
            t.bevel(x, y, 122, 122, 4, np.minimum(base * 1.25, 1), base * 0.55, 0.5)
            if t.rng.random() < 0.35:  # chipped corner
                cx = x + (0 if t.rng.random() < 0.5 else 110)
                cy = y + (0 if t.rng.random() < 0.5 else 110)
                img, d = t.layer()
                d.polygon([(cx, cy), (cx + 12, cy + 1), (cx + 3, cy + 10)], fill=rgb8((0.22, 0.2, 0.17)))
                t.over(img)
    t.cracks(4, 40, (0.14, 0.13, 0.11), 2, 0.7)
    t.shade(t.noise(256, 4), 0.78, 1.06)
    t.stain(t.noise(160, 4), 0.6, (0.27, 0.23, 0.17), 0.5)
    t.stain(t.noise(30, 3), 0.75, (0.22, 0.2, 0.16), 0.3)
    t.grain(0.015)
    t.save(name)


def wall(name):
    """Whitewash above, oil-painted green panel below with chips and scuffs,
    a dark dividing stripe, a brown skirting board on the floor."""
    t = T(512, 512, (0.72, 0.71, 0.65), name)
    top = (0, 0, 512, 272)
    t.shade(t.noise(200, 5), 0.82, 1.05, top)
    t.stain(t.noise(120, 4), 0.62, (0.52, 0.45, 0.32), 0.55, top)
    # Water streaks running down from the ceiling.
    img, d = t.layer()
    for _ in range(14):
        x = t.rng.random() * 512
        ln = 40 + t.rng.random() * 200
        for k in range(int(ln)):
            a = int(90 * (1 - k / ln))
            d.point((x + np.sin(k * 0.05) * 2, k), fill=(120, 105, 80, a))
    t.over(img, 1.0, 1.2)
    t.rect(0, 272, 512, 12, (0.12, 0.19, 0.15))
    t.rect(0, 284, 512, 204, (0.21, 0.36, 0.28))
    paint = (0, 284, 512, 204)
    t.shade(t.noise(90, 4), 0.85, 1.12, paint)
    # Gloss streaks of the brush.
    t.lines(220, 60, (0.3, 0.46, 0.37), 1, 0.25, paint, 0.0, 0.1)
    # Chips down to the plaster, with a dark rim.
    chips = t.blob_mask(7, 2, 9, (0, 290, 512, 190), 1.2) > 0.35
    rim = blurred(chips.astype(np.float32), 1.0) > 0.08
    t.mix((0.14, 0.2, 0.16), (rim & ~chips) * 0.6, paint)
    t.mix((0.55, 0.53, 0.46), chips * 0.85, paint)
    # Scuffs from trolleys and boots near the floor.
    t.lines(60, 50, (0.07, 0.09, 0.08), 2, 0.45, (0, 420, 480, 60), 0.0, 0.25)
    t.rect(0, 488, 512, 24, (0.28, 0.18, 0.11))
    t.rect(0, 488, 512, 3, (0.42, 0.3, 0.19))
    t.shade(t.noise(40, 3), 0.85, 1.1, (0, 488, 512, 24))
    t.grain(0.012)
    t.save(name)


def ceiling(name):
    """Suspended ceiling: fissured mineral tiles of 60 cm in a T-bar grid, a leak."""
    t = T(512, 512, (0.64, 0.63, 0.59), name)
    t.shade(t.noise(64, 4), 0.9, 1.04)
    img, d = t.layer()
    for _ in range(2600):  # fissures: short wormy dents
        x, y = t.rng.random() * 512, t.rng.random() * 512
        a = t.rng.random() * np.pi
        ln = 2 + t.rng.random() * 7
        pts = [(x, y), (x + np.cos(a) * ln * 0.5, y + np.sin(a) * ln * 0.5 + t.rng.random()),
               (x + np.cos(a) * ln, y + np.sin(a) * ln)]
        d.line(pts, fill=(95, 93, 87, 200), width=1)
    for _ in range(1500):
        x, y = t.rng.random() * 512, t.rng.random() * 512
        d.point((x, y), fill=(80, 80, 75, 220))
    t.over(img)
    for k in (0, 256):
        t.rect(k, 0, 8, 512, (0.74, 0.74, 0.72))
        t.rect(0, k, 512, 8, (0.74, 0.74, 0.72))
        t.rect(k + 8, 0, 2, 512, (0.38, 0.38, 0.36))
        t.rect(0, k + 8, 512, 2, (0.38, 0.38, 0.36))
    yy, xx = np.mgrid[0:512, 0:512]
    dd = np.sqrt((xx - 370) ** 2 + (yy - 380) ** 2) + t.noise(40, 3) * 30
    ring = np.exp(-((dd - 70) / 6) ** 2) * 0.5 + (dd < 70) * 0.18
    t.mix((0.5, 0.41, 0.26), ring)
    t.grain(0.01)
    t.save(name)


def painted_metal(name, base, rust=0.72):
    """Painted sheet steel: scratches, rubbed edges, rust spots and runs."""
    t = T(512, 512, base, name)
    t.shade(t.noise(200, 5), 0.86, 1.06)
    t.shade(t.noise(12, 3), 0.96, 1.03)
    t.lines(140, 50, np.minimum(np.array(base) * 1.5 + 0.1, 1), 1, 0.5)
    t.lines(40, 20, (0.2, 0.2, 0.2), 1, 0.4)
    r = t.noise(70, 4)
    t.stain(r, rust, (0.45, 0.25, 0.12), 0.8)
    t.stain(r, rust + 0.12, (0.25, 0.12, 0.06), 0.8)
    t.grain(0.012)
    t.save(name)


def pegboard(name):
    t = T(512, 512, (0.46, 0.47, 0.44), name)
    t.shade(t.noise(160, 4), 0.85, 1.06)
    img, d = t.layer()
    for y in range(8, 512, 16):
        for x in range(8, 512, 16):
            d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(12, 12, 12, 255))
            d.arc((x - 4, y - 4, x + 4, y + 4), 200, 340, fill=(170, 170, 160, 160))
    t.over(img)
    t.stain(t.noise(80, 4), 0.72, (0.36, 0.3, 0.22), 0.4)
    t.grain(0.01)
    t.save(name)


LABELS = [
    # background, accent, text, text colour, picture
    ((0.72, 0.13, 0.08), (0.9, 0.88, 0.8), "ТОМАТНЫЙ\nСОК", (0.7, 0.1, 0.07), "tomato"),
    ((0.2, 0.42, 0.2), (0.9, 0.88, 0.8), "ГОРОШЕК\nЗЕЛЁНЫЙ", (0.15, 0.35, 0.12), "peas"),
    ((0.35, 0.56, 0.8), (0.92, 0.92, 0.88), "МОЛОКО\nСГУЩЁННОЕ", (0.2, 0.35, 0.65), "milk"),
    ((0.75, 0.6, 0.25), (0.12, 0.1, 0.08), "ШПРОТЫ\nв масле", (0.85, 0.7, 0.3), "fish"),
    ((0.2, 0.3, 0.62), (0.92, 0.92, 0.9), "СОЛЬ\nповаренная", (0.2, 0.3, 0.62), None),
    ((0.72, 0.66, 0.2), (0.1, 0.32, 0.15), "ЧАЙ\nгрузинский", (0.9, 0.8, 0.3), "leaf"),
    ((0.88, 0.76, 0.4), (0.55, 0.15, 0.1), "МАКАРОНЫ", (0.95, 0.85, 0.55), None),
    ((0.18, 0.16, 0.14), (0.78, 0.15, 0.1), "СПИЧКИ", (0.95, 0.9, 0.8), "match"),
    ((0.85, 0.83, 0.62), (0.3, 0.46, 0.26), "СОК\nБЕРЁЗОВЫЙ", (0.92, 0.9, 0.75), "birch"),
    ((0.62, 0.08, 0.06), (0.9, 0.88, 0.8), "ТОМАТЫ\nмаринов.", (0.62, 0.08, 0.06), "tomato"),
    ((0.8, 0.5, 0.16), (0.92, 0.9, 0.8), "СОК\nЯБЛОЧНЫЙ", (0.7, 0.35, 0.1), "apple"),
    ((0.3, 0.4, 0.53), (0.84, 0.84, 0.82), "КИЛЬКА\nв томате", (0.25, 0.32, 0.45), "fish"),
    ((0.88, 0.87, 0.82), (0.2, 0.3, 0.62), "МУКА\nпшеничная", (0.9, 0.88, 0.82), None),
    ((0.9, 0.89, 0.86), (0.72, 0.12, 0.1), "САХАР-\nПЕСОК", (0.95, 0.92, 0.88), None),
    ((0.42, 0.28, 0.16), (0.86, 0.72, 0.42), "ЦИКОРИЙ", (0.42, 0.28, 0.16), None),
    ((0.88, 0.9, 0.92), (0.25, 0.4, 0.72), "МОЛОКО\n3,2%", (0.92, 0.94, 0.95), "cow"),
]


def labels(name):
    """Product label atlas, 4×4 cells of 128×128 (see Props.label_rect): the
    top 12 px of each cell is the tin lid or jar cap, the rest the label."""
    t = T(512, 512, (1, 1, 1), name)
    for i, (bg, acc, text, ink, pic) in enumerate(LABELS):
        cx, cy = (i % 4) * 128, (i // 4) * 128
        t.rect(cx, cy + 12, 128, 116, bg)
        t.rect(cx, cy + 46, 128, 50, acc)
        t.rect(cx, cy + 18, 128, 4, np.array(acc) * 0.8)
        t.rect(cx, cy + 110, 128, 4, np.array(acc) * 0.8)
        t.text((cx + 64, cy + 71), text, 15 if "\n" in text else 19, ink, cond=True, spacing=1)
        img, d = t.layer()
        px, py = cx + 64, cy + 32
        if pic == "tomato":
            d.ellipse((px - 11, py - 10, px + 11, py + 10), fill=rgb8((0.85, 0.15, 0.08)))
            d.polygon([(px - 5, py - 10), (px, py - 15), (px + 5, py - 10)], fill=rgb8((0.2, 0.5, 0.15)))
        elif pic == "peas":
            for k in range(5):
                d.ellipse((px - 22 + k * 9, py - 4, px - 14 + k * 9, py + 4), fill=rgb8((0.4, 0.75, 0.3)))
        elif pic == "fish":
            d.ellipse((px - 20, py - 6, px + 12, py + 6), fill=rgb8((0.8, 0.8, 0.82)))
            d.polygon([(px + 10, py), (px + 22, py - 8), (px + 22, py + 8)], fill=rgb8((0.8, 0.8, 0.82)))
            d.ellipse((px - 15, py - 2, px - 11, py + 2), fill=(30, 30, 30, 255))
        elif pic == "milk" or pic == "cow":
            d.rectangle((px - 14, py - 9, px + 14, py + 9), fill=rgb8((0.95, 0.95, 0.95)))
            d.ellipse((px - 6, py - 5, px + 2, py + 3), fill=(40, 40, 40, 255))
        elif pic == "leaf":
            d.ellipse((px - 14, py - 6, px + 14, py + 6), fill=rgb8((0.15, 0.45, 0.2)))
            d.line([(px - 14, py), (px + 14, py)], fill=rgb8((0.6, 0.8, 0.4)), width=1)
        elif pic == "match":
            d.rectangle((px - 18, py - 2, px + 14, py + 2), fill=rgb8((0.85, 0.7, 0.4)))
            d.ellipse((px + 12, py - 4, px + 20, py + 4), fill=rgb8((0.6, 0.1, 0.05)))
        elif pic == "birch":
            for k in range(3):
                d.rectangle((px - 16 + k * 12, py - 14, px - 12 + k * 12, py + 14), fill=(235, 235, 225, 255))
                d.rectangle((px - 16 + k * 12, py - 6 + k * 3, px - 12 + k * 12, py - 4 + k * 3), fill=(30, 30, 30, 255))
        elif pic == "apple":
            d.ellipse((px - 11, py - 10, px + 11, py + 10), fill=rgb8((0.85, 0.75, 0.2)))
            d.line([(px, py - 10), (px + 3, py - 15)], fill=(80, 50, 20, 255), width=2)
        t.over(img)
        t.text((cx + 64, cy + 103), "ГОСТ", 9, np.array(ink) * 0.5 + np.array(bg) * 0.5, bold=False)
        # Lid / cap band.
        lid = (0.66, 0.66, 0.62) if i < 8 or i == 11 else (0.8, 0.7, 0.32)
        t.rect(cx, cy, 128, 12, lid)
        t.rect(cx, cy + 4, 128, 2, np.array(lid) * 0.8)
    t.shade(t.noise(90, 4), 0.86, 1.04)
    t.grain(0.012)
    t.save(name)


def tags(name):
    """Hand-written price tags, 4×8 cells of 128×64."""
    t = T(512, 512, (0.9, 0.88, 0.78), name)
    rng = t.rng
    for i in range(32):
        cx, cy = (i % 4) * 128, (i // 4) * 64
        t.bevel(cx, cy, 128, 64, 2, (1, 1, 0.95), (0.55, 0.52, 0.45), 0.8)
        t.rect(cx + 6, cy + 6, 116, 7, (0.75, 0.2, 0.15))
        price = "%d-%02d" % (rng.integers(0, 4), rng.integers(0, 20) * 5)
        t.text((cx + 64, cy + 37), price, 30, (0.12, 0.13, 0.4), serif=True, bold=False)
        t.text((cx + 104, cy + 54), "р.-к.", 9, (0.2, 0.2, 0.3), bold=False)
    t.shade(t.noise(60, 3), 0.9, 1.03)
    t.grain(0.01)
    t.save(name)


def locker(name):
    """Left-luggage lockers, 12 columns × 4 rows, numbered 1–48 (1536×512,
    mapped once over the whole bank): louvres, number plates, lock, rust."""
    t = T(1536, 512, (0.15, 0.17, 0.16), name)
    for r in range(4):
        for c in range(12):
            x, y = c * 128, r * 128
            v = (t.rng.random() - 0.5) * 0.05
            face = np.array((0.42 + v, 0.49 + v, 0.43 + v))
            t.rect(x + 7, y + 7, 114, 114, face)
            t.bevel(x + 7, y + 7, 114, 114, 4, np.minimum(face * 1.35, 1), face * 0.45, 0.8)
            for k in range(4):
                t.rect(x + 28, y + 20 + k * 10, 72, 4, face * 0.35)
                t.rect(x + 28, y + 24 + k * 10, 72, 2, np.minimum(face * 1.3, 1))
            t.rect(x + 38, y + 64, 52, 28, (0.84, 0.82, 0.7))
            t.bevel(x + 38, y + 64, 52, 28, 2, (1, 1, 0.9), (0.4, 0.38, 0.3), 0.8)
            t.text((x + 64, y + 78), str(r * 12 + c + 1), 21, (0.12, 0.1, 0.08))
            img, d = t.layer()
            d.ellipse((x + 90, y + 96, x + 104, y + 110), fill=rgb8((0.72, 0.72, 0.7)))
            d.rectangle((x + 96, y + 99, x + 98, y + 107), fill=(15, 15, 15, 255))
            d.rectangle((x + 18, y + 98, x + 44, y + 106), fill=rgb8((0.25, 0.25, 0.25)))
            t.over(img)
            t.text((x + 31, y + 116), "15 коп", 8, (0.8, 0.8, 0.75), bold=False)
    n = t.noise(90, 4)
    t.stain(n, 0.68, (0.42, 0.24, 0.12), 0.7)
    t.stain(n, 0.8, (0.22, 0.12, 0.06), 0.7)
    t.lines(400, 30, (0.75, 0.78, 0.72), 1, 0.45)
    t.shade(t.noise(300, 4), 0.85, 1.05)
    t.grain(0.012)
    t.save(name)


def cloth(name):
    """Grey linen dust cover: weave, broad soft folds, stains."""
    t = T(512, 512, (0.6, 0.59, 0.54), name)
    yy, xx = np.mgrid[0:512, 0:512]
    weave = ((xx % 4 < 2) ^ (yy % 4 < 2)).astype(np.float32)
    t.shade(weave, 0.93, 1.03)
    warp = t.noise(256, 2)
    f = np.sin(xx * 2 * np.pi / 256 + warp * 3)
    t.mul(0.95 + 0.06 * f)
    t.shade(t.noise(30, 3), 0.95, 1.04)
    t.stain(t.noise(140, 4), 0.7, (0.38, 0.35, 0.28), 0.5)
    t.grain(0.01)
    t.save(name)


def enamel(name):
    """Freezer chest enamel: off-white, a blue band at the top, chips with
    rust halos, grime towards the floor."""
    t = T(512, 512, (0.82, 0.84, 0.82), name)
    t.shade(t.noise(200, 4), 0.92, 1.03)
    t.rect(0, 56, 512, 32, (0.2, 0.28, 0.48))
    t.rect(0, 88, 512, 3, (0.14, 0.18, 0.3))
    t.text((256, 72), "МОРОЖЕНАЯ ПРОДУКЦИЯ", 18, (0.9, 0.9, 0.88), cond=True)
    chips = t.blob_mask(26, 2, 7, (0, 240, 512, 270), 0.8)
    halo = blurred((chips > 0.1).astype(np.float32), 5)
    t.mix((0.5, 0.3, 0.14), np.clip(halo * 1.5, 0, 0.8))
    t.mix((0.07, 0.07, 0.07), chips > 0.2)
    yy = np.mgrid[0:512, 0:512][0]
    t.mix((0.45, 0.4, 0.32), np.clip((yy - 360) / 150, 0, 1) * t.noise(60, 3) * 0.7)
    t.grain(0.01)
    t.save(name)


def frozen(name):
    """Through the lid: packs of pelmeni, butter and fish in a crust of frost."""
    t = T(512, 512, (0.16, 0.2, 0.23), name)
    packs = [((0.88, 0.87, 0.82), "ПЕЛЬМЕНИ", (0.75, 0.12, 0.1)), ((0.3, 0.42, 0.72), "МИНТАЙ", (0.9, 0.9, 0.9)),
             ((0.9, 0.78, 0.4), "МАСЛО", (0.2, 0.3, 0.6)), ((0.75, 0.45, 0.42), "ФАРШ", (0.95, 0.9, 0.85)),
             ((0.58, 0.62, 0.64), "ХЕК", (0.15, 0.15, 0.2))]
    for _ in range(80):
        c, label, ink = packs[t.rng.integers(len(packs))]
        w, h = t.rng.integers(56, 90), t.rng.integers(34, 52)
        x, y = t.rng.integers(-20, 500), t.rng.integers(-20, 500)
        c = np.array(c) * (0.8 + t.rng.random() * 0.2)
        t.rect(x, y, w, h, c)
        t.bevel(x, y, w, h, 3, np.minimum(c * 1.2, 1), c * 0.45, 0.7)
        t.text((x + w / 2, y + h / 2), label, 11, ink, cond=True)
    frost = t.noise(60, 5)
    t.stain(frost, 0.4, (0.88, 0.93, 0.98), 0.9)
    img, d = t.layer()
    for _ in range(3000):
        x, y = t.rng.random() * 512, t.rng.random() * 512
        d.point((x, y), fill=(245, 250, 255, 200))
    t.over(img)
    t.save(name)


def wood(name):
    """Light oak veneer: wavy grain, pores, worn varnish."""
    t = T(512, 512, (0.46, 0.3, 0.18), name)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    warp = t.noise(200, 3)
    g = np.sin((yy + warp * 120 + np.sin(xx / 80) * 10) * 0.22) * 0.5 + 0.5
    g = g ** 3
    t.mix((0.3, 0.18, 0.1), g * 0.6)
    t.shade(t.noise(16, 3, w=512, h=512), 0.93, 1.05)
    t.lines(900, 6, (0.24, 0.14, 0.08), 1, 0.5, None, 0.0, 0.1)
    t.stain(t.noise(120, 4), 0.72, (0.6, 0.45, 0.3), 0.3)
    t.grain(0.01)
    t.save(name)


def formica(name):
    t = T(256, 256, (0.62, 0.62, 0.59), name)
    img, d = t.layer()
    for _ in range(4000):
        x, y = t.rng.random() * 256, t.rng.random() * 256
        c = (100, 100, 96, 255) if t.rng.random() < 0.6 else (200, 200, 195, 255)
        d.point((x, y), fill=c)
    t.over(img)
    t.shade(t.noise(80, 3), 0.92, 1.04)
    t.save(name)


def door(name):
    """Storage door (512×1024, mapped once): painted steel, two panels,
    rivets, stencils, rust runs, kick marks at the bottom."""
    t = T(512, 1024, (0.37, 0.26, 0.21), name)
    t.shade(t.noise(300, 5), 0.88, 1.05)
    for x, y, w, h in ((40, 48, 432, 400), (40, 512, 432, 464)):
        t.bevel(x, y, w, h, 8, (0.52, 0.4, 0.32), (0.13, 0.09, 0.07), 0.8)
    img, d = t.layer()
    for y in (20, 480, 1000):
        for x in range(24, 500, 36):
            d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=rgb8((0.55, 0.44, 0.36)))
            d.arc((x - 4, y - 4, x + 4, y + 4), 20, 160, fill=rgb8((0.15, 0.1, 0.08)), width=2)
    t.over(img)
    stencil = (0.88, 0.85, 0.78)
    t.text((256, 170), "СКЛАД", 96, stencil, rough=0.18)
    t.text((256, 330), "ПОСТОРОННИМ\nВХОД\nВОСПРЕЩЁН", 38, stencil, rough=0.18, spacing=10)
    t.rect(410, 560, 50, 16, (0.62, 0.62, 0.6))
    t.rect(424, 600, 20, 34, (0.3, 0.3, 0.3))
    img, d = t.layer()
    for _ in range(30):  # rust runs from the rivets and panel edges
        x = t.rng.random() * 512
        y0 = t.rng.choice([20, 48, 448, 480, 512])
        ln = 40 + t.rng.random() * 160
        d.line([(x, y0), (x + t.rng.random() * 3, y0 + ln)], fill=(120, 55, 20, 120), width=t.rng.integers(1, 4))
    t.over(img, 1.0, 1.0)
    t.stain(t.noise(120, 4), 0.62, (0.45, 0.22, 0.08), 0.75)
    t.lines(80, 40, (0.12, 0.1, 0.09), 3, 0.4, (0, 900, 512, 110), 0.0, 0.5)
    t.grain(0.012)
    t.save(name)


def glass(name):
    """Glass door leaf (512×1024): aluminium frame, opening-hours notice,
    the street at night reflected in the pane."""
    t = T(512, 1024, (0.04, 0.05, 0.07), name)
    yy, xx = np.mgrid[0:1024, 0:512].astype(np.float32)
    s = (xx + yy * 0.5) % 280
    t.mix((0.22, 0.26, 0.3), ((s < 20) | ((s > 56) & (s < 66))) * 0.7)
    t.mix((0.62, 0.52, 0.28), t.blob_mask(4, 20, 50, (40, 120, 420, 320)) * 0.35)
    t.mix((0.5, 0.5, 0.45), (t.noise(40, 3) > 0.75) * 0.08)  # fingerprints and smears
    for x, y, w, h in ((0, 0, 512, 32), (0, 992, 512, 32), (0, 0, 32, 1024), (480, 0, 32, 1024), (0, 528, 512, 24)):
        t.rect(x, y, w, h, (0.6, 0.62, 0.62))
        t.bevel(x, y, w, h, 4, (0.85, 0.85, 0.85), (0.3, 0.3, 0.3))
    t.rect(136, 220, 240, 200, (0.9, 0.89, 0.82))
    for x, y in ((130, 214), (360, 214), (130, 404), (360, 404)):
        t.rect(x, y, 22, 22, (0.85, 0.82, 0.6), 0.7)
    t.text((256, 320), "РЕЖИМ РАБОТЫ\n\n8.00 — 22.00\nперерыв\n13.00 — 14.00\nбез выходных", 20, (0.15, 0.15, 0.15),
           bold=False, spacing=2)
    t.grain(0.01)
    t.save(name)


def cardboard(name):
    """Kraft cardboard: flutes, packing tape, a stamp."""
    t = T(512, 512, (0.52, 0.37, 0.22), name)
    xx = np.mgrid[0:512, 0:512][1]
    t.shade((np.sin(xx * 2 * np.pi / 10) * 0.5 + 0.5), 0.94, 1.03)
    t.shade(t.noise(150, 4), 0.88, 1.06)
    t.rect(216, 0, 80, 512, (0.66, 0.55, 0.34), 0.85)
    t.rect(216, 0, 2, 512, (0.5, 0.4, 0.25))
    t.rect(294, 0, 2, 512, (0.5, 0.4, 0.25))
    t.rect(0, 0, 512, 6, (0.32, 0.22, 0.13))
    t.rect(0, 0, 6, 512, (0.32, 0.22, 0.13))
    ink = (0.25, 0.15, 0.32)
    t.text((100, 380), "ГОСТ 13516-86\nКОНСЕРВЫ\n24 шт.", 18, ink, rough=0.25, spacing=4)
    img, d = t.layer()
    d.rectangle((24, 340, 176, 424), outline=rgb8(ink), width=2)
    for k in range(2):
        x = 380 + k * 50
        d.line([(x, 420), (x, 360)], fill=rgb8(ink), width=4)
        d.polygon([(x - 12, 364), (x + 12, 364), (x, 344)], fill=rgb8(ink))
    t.over(img, 0.85)
    t.text((405, 440), "ВЕРХ", 16, ink, rough=0.25)
    t.stain(t.noise(120, 4), 0.7, (0.34, 0.23, 0.13), 0.6)
    t.grain(0.012)
    t.save(name)


def poster(name, lines, base, kind):
    """Agitprop poster (512×640, mapped once)."""
    t = T(512, 640, base, name)
    t.rect(16, 16, 480, 608, np.minimum(np.array(base) * 1.08, 1))
    t.text((256, 120), "\n".join(lines), 54, (0.96, 0.93, 0.84), spacing=8)
    img, d = t.layer()
    if kind == "tomato":
        d.polygon([(180, 300), (332, 300), (318, 580), (194, 580)], fill=(215, 220, 225, 255))
        d.polygon([(188, 340), (324, 340), (314, 570), (198, 570)], fill=rgb8((0.78, 0.12, 0.07)))
        d.rectangle((188, 340, 324, 352), fill=rgb8((0.92, 0.35, 0.22)))
        d.ellipse((340, 470, 420, 550), fill=rgb8((0.85, 0.15, 0.08)))
        d.polygon([(368, 472), (380, 452), (392, 472)], fill=rgb8((0.25, 0.5, 0.15)))
    else:
        d.ellipse((120, 400, 392, 560), fill=rgb8((0.62, 0.38, 0.15)))
        d.ellipse((140, 410, 372, 520), fill=rgb8((0.72, 0.48, 0.2)))
        for k in range(5):
            x = 170 + k * 44
            d.line([(x, 430), (x + 18, 500)], fill=rgb8((0.45, 0.25, 0.1)), width=6)
        for side in (-1, 1):  # wheat ears
            for k in range(7):
                x, y = 256 + side * (150 + k * 4), 560 - k * 28
                d.ellipse((x - 8, y - 14, x + 8, y + 14), fill=rgb8((0.95, 0.8, 0.35)))
    t.over(img)
    t.text((256, 604), "ГЛАВПЛАКАТ  1987", 14, (0.95, 0.92, 0.82), bold=False)
    t.stain(t.noise(160, 4), 0.68, (0.62, 0.56, 0.42), 0.5)
    t.lines(3, 640, (0.95, 0.95, 0.9), 2, 0.25, (0, 0, 512, 10), np.pi / 2, 0.02)  # folds
    t.grain(0.012)
    t.save(name)


def sign(name, text):
    """Hanging aisle sign: white letters on red, 512×128."""
    t = T(512, 128, (0.64, 0.12, 0.08), name)
    t.shade(t.noise(80, 3), 0.9, 1.04)
    t.bevel(0, 0, 512, 128, 6, (0.85, 0.35, 0.25), (0.3, 0.05, 0.03), 0.9)
    t.text((256, 66), text, 64 if len(text) < 9 else 56, (0.96, 0.94, 0.86))
    t.grain(0.01)
    t.save(name)


def exit_sign(name):
    t = T(256, 64, (0.16, 0.56, 0.26), name)
    t.text((128, 33), "ВЫХОД", 40, (0.96, 1.0, 0.93))
    t.save(name)


# --- small things ---------------------------------------------------------------

def keys(name):
    t = T(256, 256, (0.2, 0.2, 0.2), name)
    for r in range(7):
        for c in range(7):
            col = (0.84, 0.82, 0.72)
            if c == 6:
                col = (0.72, 0.2, 0.15)
            elif r == 6:
                col = (0.3, 0.45, 0.62)
            x, y = 8 + c * 35, 8 + r * 35
            t.rect(x, y, 30, 30, col)
            t.bevel(x, y, 30, 30, 3, np.minimum(np.array(col) * 1.25, 1), np.array(col) * 0.45, 0.8)
            if c < 6 and r < 6:
                t.text((x + 15, y + 15), str((r * 6 + c) % 10), 16, (0.15, 0.15, 0.15))
    t.grain(0.01)
    t.save(name)


def register(name):
    t = T(256, 256, (0.64, 0.62, 0.56), name)
    t.shade(t.noise(100, 4), 0.88, 1.04)
    t.rect(0, 160, 256, 6, (0.35, 0.34, 0.3))
    t.rect(96, 200, 64, 10, (0.3, 0.3, 0.3))
    t.rect(70, 20, 116, 30, (0.75, 0.72, 0.6))
    t.text((128, 35), "ОКА-4600", 18, (0.3, 0.28, 0.24))
    t.lines(30, 30, (0.85, 0.84, 0.78), 1, 0.4)
    t.grain(0.01)
    t.save(name)


def display(name):
    t = T(256, 64, (0.04, 0.07, 0.05), name)
    t.text((180, 32), "0.00", 40, (0.3, 0.95, 0.5), cond=True)
    t.save(name)


def grille(name):
    t = T(256, 256, (0.33, 0.31, 0.29), name)
    for y in range(0, 256, 16):
        t.rect(0, y, 256, 8, (0.1, 0.09, 0.08))
        t.rect(0, y + 8, 256, 2, (0.45, 0.43, 0.4))
    t.grain(0.02)
    t.save(name)


def dial(name):
    """Rotary phone dial: ten finger holes with digits under them."""
    t = T(256, 256, (0.32, 0.08, 0.06), name)
    img, d = t.layer()
    d.ellipse((12, 12, 244, 244), fill=rgb8((0.86, 0.84, 0.78)))
    d.ellipse((80, 80, 176, 176), fill=rgb8((0.78, 0.74, 0.66)))
    t.over(img)
    for i in range(10):
        a = -np.pi * 0.4 + i * 2 * np.pi / 12
        x, y = 128 + np.cos(a) * 82, 128 + np.sin(a) * 82
        t.text((x, y), str((i + 1) % 10), 20, (0.15, 0.15, 0.15))
        img, d = t.layer()
        d.ellipse((x - 17, y - 17, x + 17, y + 17), outline=rgb8((0.25, 0.25, 0.25)), width=3)
        t.over(img)
    t.save(name)


def calendar(name):
    """Wall calendar for October 1988 (256×384, mapped once): the 1st was a Saturday."""
    t = T(256, 384, (0.9, 0.89, 0.84), name)
    sky = np.linspace(0.0, 1.0, 120)[:, None]
    t.a[:120, :, 0] = 0.45 + sky * 0.3
    t.a[:120, :, 1] = 0.55 + sky * 0.25
    t.a[:120, :, 2] = 0.72 + sky * 0.1
    img, d = t.layer()
    d.polygon([(0, 120), (0, 80), (60, 50), (110, 85), (170, 40), (256, 90), (256, 120)], fill=rgb8((0.3, 0.38, 0.32)))
    d.polygon([(0, 120), (0, 100), (90, 80), (256, 105), (256, 120)], fill=rgb8((0.2, 0.3, 0.2)))
    t.over(img)
    t.text((128, 140), "1988", 24, (0.65, 0.12, 0.1))
    t.text((128, 168), "ОКТЯБРЬ", 20, (0.15, 0.15, 0.15))
    for i, wd in enumerate(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]):
        t.text((22 + i * 35, 194), wd, 11, (0.7, 0.1, 0.1) if i == 6 else (0.3, 0.3, 0.3), bold=False)
    for day in range(1, 32):
        col = (day + 4) % 7
        row = (day + 4) // 7
        t.text((22 + col * 35, 220 + row * 30), str(day), 15, (0.75, 0.1, 0.1) if col == 6 else (0.15, 0.15, 0.15),
               bold=col == 6)
    t.grain(0.01)
    t.save(name)


def clock(name):
    """Wall clock, stopped at twenty to five."""
    t = T(256, 256, (0.12, 0.12, 0.12), name)
    img, d = t.layer()
    d.ellipse((8, 8, 248, 248), fill=rgb8((0.9, 0.89, 0.84)))
    for i in range(60):
        a = i * np.pi / 30
        r0 = 100 if i % 5 else 92
        d.line([(128 + np.cos(a) * r0, 128 + np.sin(a) * r0), (128 + np.cos(a) * 108, 128 + np.sin(a) * 108)],
               fill=(30, 30, 30, 255), width=4 if i % 5 == 0 else 1)
    t.over(img)
    for h in range(1, 13):
        a = (h - 3) * np.pi / 6
        t.text((128 + np.cos(a) * 76, 128 + np.sin(a) * 76), str(h), 20, (0.1, 0.1, 0.1))
    img, d = t.layer()
    ah = (4 + 40 / 60 - 3) * np.pi / 6
    am = (40 - 15) * np.pi / 30
    d.line([(128, 128), (128 + np.cos(ah) * 52, 128 + np.sin(ah) * 52)], fill=(20, 20, 20, 255), width=7)
    d.line([(128, 128), (128 + np.cos(am) * 88, 128 + np.sin(am) * 88)], fill=(20, 20, 20, 255), width=4)
    d.ellipse((120, 120, 136, 136), fill=(20, 20, 20, 255))
    t.over(img)
    t.save(name)


# --- people -------------------------------------------------------------------

def skin(name):
    """Weathered skin of a man's hands: blotchy warm and cool patches, fine
    pores, creases across the knuckles, faint veins."""
    t = T(512, 512, (0.76, 0.58, 0.48), name)
    t.shade(t.noise(90, 4), 0.86, 1.06)
    t.mix((0.72, 0.4, 0.36), np.clip(t.noise(30, 3) - 0.35, 0, 1) * 0.6)
    t.mix((0.62, 0.6, 0.55), np.clip(t.noise(45, 3) - 0.55, 0, 1) * 0.5)
    pores = (t.rng.random((512, 512)) > 0.992).astype(np.float32)
    t.mix((0.6, 0.44, 0.37), blurred(pores, 0.6) * 0.8)
    t.lines(160, 22, (0.55, 0.38, 0.32), 1, 0.35, None, 0.0, 0.25)
    t.lines(40, 60, (0.48, 0.45, 0.55), 2, 0.12, None, 1.57, 0.6)
    t.grain(0.01)
    t.save(name)


def face(name):
    """The killer's face, mapped on the front of the head: a band of pale
    skin under the hat, eyes deep in shadowed sockets with a glint in each,
    the nose, and from there down a dark knitted scarf."""
    t = T(256, 256, (0.64, 0.54, 0.48), name)
    t.shade(t.noise(60, 4), 0.85, 1.04)
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32)
    t.mul(1 - np.clip((44 - yy) / 44, 0, 1) * 0.6)  # hat brim shadow
    for cx in (84, 172):
        sock = np.exp(-(((xx - cx) / 34) ** 2 + ((yy - 94) / 22) ** 2))
        t.mix((0.1, 0.06, 0.05), np.clip(sock * 1.3, 0, 1))
        eye = ((xx - cx) / 14) ** 2 + ((yy - 98) / 3.5) ** 2 < 1
        t.mix((0.02, 0.02, 0.02), eye)
        t.mix((0.7, 0.68, 0.62), ((xx - cx - 3) ** 2 + (yy - 97) ** 2) < 2.5)
        brow_y = 76 - 0.2 * (np.abs(xx - 128) - 44)
        brow = np.exp(-(((xx - cx) / 32) ** 2 + ((yy - brow_y) / 4) ** 2))
        t.mix((0.12, 0.08, 0.06), brow)
    t.mix((0.42, 0.32, 0.28), np.exp(-(((xx - 112) / 6) ** 2)) * ((yy > 95) & (yy < 150)) * 0.6)
    t.mix((0.42, 0.32, 0.28), np.exp(-(((xx - 144) / 6) ** 2)) * ((yy > 95) & (yy < 150)) * 0.6)
    t.mix((0.74, 0.63, 0.56), np.exp(-(((xx - 128) / 8) ** 2)) * ((yy > 90) & (yy < 150)) * 0.5)
    scarf = yy > 150 + np.sin(xx / 30) * 4
    t.mix((0.1, 0.1, 0.11), scarf)
    knit = ((xx % 12 < 4) | ((xx + (yy // 6) % 2 * 6) % 12 == 8)) & scarf
    t.mix((0.2, 0.2, 0.22), knit * 0.7)
    t.mix((0.03, 0.03, 0.03), np.abs(yy - 150 - np.sin(xx / 30) * 4) < 3)
    t.grain(0.012)
    t.save(name)


def person_face(name, skin_tone, brow, top_shadow, glasses=False, moustache=None, lips=(0.55, 0.32, 0.3),
                stubble=0.0, flush=0.0):
    """A bare face mapped on the front of the head like the killer's: the
    forehead under a hat (its shadow on top), brows, eyes with lids and
    bags, the nose, the mouth, the chin. Optional glasses, a moustache,
    stubble, a drinker's red nose."""
    t = T(256, 256, skin_tone, name)
    t.shade(t.noise(60, 4), 0.86, 1.04)
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32)
    t.mul(1 - np.clip((top_shadow - yy) / max(top_shadow, 1), 0, 1) * 0.55)
    t.mul(1 - np.clip((np.abs(xx - 128) - 96) / 32, 0, 1) * 0.3)  # cheeks turn away
    dark = np.array(skin_tone) * 0.45
    for cx in (86, 170):
        sock = np.exp(-(((xx - cx) / 30) ** 2 + ((yy - 98) / 16) ** 2))
        t.mix(tuple(dark), np.clip(sock * 0.7, 0, 1))
        bag = np.exp(-(((xx - cx) / 22) ** 2 + ((yy - 112) / 4) ** 2))
        t.mix(tuple(np.array(skin_tone) * 0.7), bag * 0.6)
        white = ((xx - cx) / 13) ** 2 + ((yy - 99) / 4.5) ** 2 < 1
        t.mix((0.78, 0.74, 0.68), white)
        t.mix((0.18, 0.14, 0.1), ((xx - cx) ** 2 + (yy - 99) ** 2) < 16)
        t.mix((0.03, 0.03, 0.03), ((xx - cx) ** 2 + (yy - 99) ** 2) < 5)
        t.mix((0.9, 0.9, 0.85), ((xx - cx - 2) ** 2 + (yy - 97) ** 2) < 1.5)
        lid = np.abs(yy - 94.5 + 0.004 * (xx - cx) ** 2) < 1.6
        t.mix(tuple(dark), lid * (np.abs(xx - cx) < 15))
        brow_y = 80 - 0.15 * (np.abs(xx - 128) - 42)
        t.mix(brow, np.exp(-(((xx - cx) / 24) ** 2 + ((yy - brow_y) / 3.2) ** 2)) * 0.95)
        if glasses:
            ring = np.abs(np.sqrt(((xx - cx) / 1.25) ** 2 + (yy - 100) ** 2) - 19) < 1.6
            t.mix((0.12, 0.1, 0.08), ring)
            t.mix((0.85, 0.88, 0.9), (((xx - cx + 8) ** 2 + (yy - 92) ** 2) < 10) * 0.35)
    if glasses:
        t.mix((0.12, 0.1, 0.08), (np.abs(yy - 98) < 1.4) & (np.abs(xx - 128) < 20))
    # Nose: a lit ridge, shaded sides, nostrils.
    ridge = np.exp(-(((xx - 128) / 6) ** 2)) * ((yy > 100) & (yy < 158))
    t.mix(tuple(np.minimum(np.array(skin_tone) * 1.12, 1)), ridge * 0.5)
    for sx in (-1, 1):
        t.mix(tuple(np.array(skin_tone) * 0.72), np.exp(-(((xx - 128 - sx * 13) / 5) ** 2)) * ((yy > 108) & (yy < 156)) * 0.5)
        t.mix((0.15, 0.08, 0.07), (((xx - 128 - sx * 9) / 4.5) ** 2 + ((yy - 160) / 2.5) ** 2) < 1)
    if flush:
        t.mix((0.72, 0.3, 0.28), np.exp(-(((xx - 128) / 14) ** 2 + ((yy - 150) / 12) ** 2)) * flush)
        t.mix((0.7, 0.36, 0.32), np.exp(-(((np.abs(xx - 128) - 52) / 18) ** 2 + ((yy - 140) / 14) ** 2)) * flush * 0.6)
    # Lines from the nose to the mouth corners.
    for sx in (-1, 1):
        fold = np.abs((xx - 128) * sx - (22 + (yy - 150) * 0.35)) < 1.8
        t.mix(tuple(np.array(skin_tone) * 0.75), fold * ((yy > 150) & (yy < 196)) * 0.7)
    mouth = np.abs(yy - 188 - 0.0025 * (xx - 128) ** 2) < 3.2
    t.mix(lips, mouth * (np.abs(xx - 128) < 26))
    t.mix((0.2, 0.1, 0.09), (np.abs(yy - 188.5 - 0.0025 * (xx - 128) ** 2) < 1.1) * (np.abs(xx - 128) < 25))
    t.mix(tuple(np.array(skin_tone) * 0.8), np.exp(-(((xx - 128) / 22) ** 2 + ((yy - 218) / 6) ** 2)) * 0.5)
    if moustache is not None:
        m = np.zeros_like(xx, bool)
        for sx in (-1, 1):
            m |= (((xx - 128 - sx * 15) / 21) ** 2 + ((yy - 175 - 0.012 * (xx - 128) ** 2) / 6.5) ** 2) < 1
        t.mix(moustache, m * 0.95)
        hair = (t.rng.random((256, 256)) > 0.6) & m
        t.mix(tuple(np.array(moustache) * 0.6), hair)
    if stubble:
        area = np.clip((yy - 160) / 25, 0, 1) * np.clip((110 - np.abs(xx - 128)) / 20, 0, 1)
        dots = blurred((t.rng.random((256, 256)) > 0.6).astype(np.float32), 0.6)
        t.mix((0.2, 0.16, 0.14), np.clip(area * dots * stubble, 0, 1))
    t.grain(0.012)
    t.save(name)


def fur(name):
    """Muskrat fur of a director's hat: dense brown pile in tufts."""
    t = T(256, 256, (0.24, 0.16, 0.1), name)
    t.shade(t.noise(20, 4), 0.6, 1.3)
    t.lines(1500, 7, (0.42, 0.3, 0.2), 1, 0.5, None, 1.4, 0.4)
    t.lines(900, 6, (0.08, 0.05, 0.03), 1, 0.6, None, 1.5, 0.4)
    t.grain(0.02)
    t.save(name)


def hair(name):
    """Permed or cropped hair: tight curls as overlapping dark and lit
    rings, tinted per person in the game."""
    t = T(256, 256, (0.42, 0.4, 0.38), name)
    t.shade(t.noise(14, 3), 0.6, 1.25)
    img, d = t.layer()
    for _ in range(900):
        x, y, r = t.rng.random() * 256, t.rng.random() * 256, 2 + t.rng.random() * 4
        d.arc((x - r, y - r, x + r, y + r), 200, 360, fill=rgb8((0.75, 0.72, 0.7)), width=1)
        d.arc((x - r, y - r, x + r, y + r), 20, 180, fill=rgb8((0.12, 0.11, 0.1)), width=1)
    t.over(img, 0.6)
    t.grain(0.02)
    t.save(name)


def denim(name):
    """Варёнка: stone-washed jeans, a fine blue twill with pale bleached clouds."""
    t = T(256, 256, (0.2, 0.27, 0.42), name)
    yy, xx = np.mgrid[0:256, 0:256]
    t.shade(((xx + yy) % 4 < 2).astype(np.float32), 0.8, 1.06)
    t.mix((0.62, 0.68, 0.78), np.clip(t.noise(30, 4) - 0.45, 0, 1) * 1.8)
    t.grain(0.02)
    t.save(name)


def quilted(name):
    """A loader's телогрейка: dark blue-grey cotton stitched in vertical
    channels, padding bulging between the seams, grease and wear."""
    t = T(256, 256, (0.16, 0.18, 0.2), name)
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32)
    t.shade(np.sin((xx % 32) / 32 * np.pi), 0.6, 1.1)
    t.mix((0.06, 0.06, 0.07), (xx % 32 < 2))
    t.mix((0.3, 0.3, 0.3), (xx % 32 < 2) & (yy % 10 < 5), )
    t.shade(t.noise(70, 4), 0.8, 1.1)
    t.stain(t.noise(40, 3), 0.68, (0.08, 0.08, 0.06), 0.6)
    t.grain(0.015)
    t.save(name)


def twill(name, base):
    t = T(256, 256, base, name)
    yy, xx = np.mgrid[0:256, 0:256]
    t.shade(((xx + yy) % 8 < 4).astype(np.float32), 0.82, 1.05)
    t.shade(t.noise(80, 4), 0.85, 1.08)
    img, d = t.layer()
    for _ in range(800):
        d.point((t.rng.random() * 256, t.rng.random() * 256), fill=rgb8(np.minimum(np.array(base) * 1.5, 1)))
    t.over(img, 0.5)
    t.save(name)


def knit(name):
    t = T(256, 256, (0.07, 0.07, 0.07), name)
    yy, xx = np.mgrid[0:256, 0:256]
    v = np.abs(((xx % 16) - 8) - (yy % 8 - 4) * np.sign((xx % 16) - 8 + 0.1))
    t.shade(np.clip(1 - v / 8, 0, 1), 0.8, 2.2)
    t.grain(0.015)
    t.save(name)


def plain(name, color, scale, amount, size=256):
    t = T(size, size, color, name)
    t.shade(t.noise(scale, 4), 1 - amount, 1 + amount * 0.5)
    t.grain(0.01)
    t.save(name)


def leather(name):
    t = T(256, 256, (0.32, 0.18, 0.1), name)
    t.shade(t.noise(10, 3), 0.8, 1.12)
    t.shade(t.noise(90, 3), 0.85, 1.08)
    t.rect(0, 24, 256, 2, (0.62, 0.52, 0.32))
    t.save(name)


def torch(name):
    """The "zhuchok": dark olive moulded plastic, a ribbed grip band, a mould
    seam, worn shiny where the palm rubs, scuffs and the moulded name."""
    t = T(512, 512, (0.2, 0.23, 0.17), name)
    t.shade(t.noise(120, 3), 0.85, 1.08)
    for y in range(190, 380, 14):
        t.rect(0, y, 512, 5, (0.15, 0.19, 0.12))
        t.rect(0, y + 5, 512, 2, (0.36, 0.43, 0.3))
    t.rect(0, 125, 512, 2, (0.14, 0.17, 0.11))
    t.mix((0.42, 0.48, 0.36), np.clip(t.noise(40, 3) - 0.6, 0, 1) * 1.5)
    t.lines(90, 18, (0.5, 0.55, 0.45), 1, 0.4)
    t.text((256, 70), "ЖУЧОК", 46, (0.17, 0.21, 0.13))
    t.text((256, 112), "ЦЕНА 2 р. 50 к.", 18, (0.17, 0.21, 0.13), bold=False)
    t.grain(0.012)
    t.save(name)


def chrome(name):
    t = T(256, 256, (0.7, 0.72, 0.74), name)
    yy = np.mgrid[0:256, 0:256][0].astype(np.float32)
    t.mul(0.6 + 0.4 * np.abs(np.sin(yy * 0.07 + t.noise(120, 2) * 2)))
    t.lines(60, 30, (0.95, 0.95, 0.95), 1, 0.4)
    t.save(name)


def blood(name):
    """A splat with ragged edges and droplets; cut out by alpha."""
    t = T(512, 512, (0.33, 0.01, 0.01, 0.0), name)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    n = t.noise(90, 5)
    dd = np.sqrt((xx - 256) ** 2 + (yy - 256) ** 2) / 256 + (n - 0.5) * 0.55
    m = dd < 0.6
    for _ in range(60):
        a = t.rng.random() * np.pi * 2
        r = 170 + t.rng.random() * 80
        cx, cy = 256 + np.cos(a) * r, 256 + np.sin(a) * r
        s = 2 + t.rng.random() * 9
        m |= (xx - cx) ** 2 + (yy - cy) ** 2 < s * s
    t.a[..., 3] = m.astype(np.float32)
    dark = t.noise(40, 4)
    t.a[..., 0] = 0.36 - dark * 0.2
    t.a[..., 1] = 0.01
    t.a[..., 2] = 0.01
    t.save(name)


def basket(name):
    """Red plastic basket side: a grid of holes cut out with alpha."""
    t = T(256, 256, (0.64, 0.12, 0.08), name)
    t.shade(t.noise(60, 3), 0.9, 1.05)
    for y in range(24, 240, 24):
        for x in range(12, 244, 24):
            t.a[y:y + 12, x:x + 16, 3] = 0
    t.save(name)


SIGNS = {"sign_bakaleya": "БАКАЛЕЯ", "sign_konservy": "КОНСЕРВЫ", "sign_moloko": "МОЛОКО", "sign_zamorozka": "ЗАМОРОЗКА"}

ALL = {
    "floor": floor, "wall": wall, "ceiling": ceiling,
    "metal": lambda n: painted_metal(n, (0.36, 0.39, 0.42)),
    "paint": lambda n: painted_metal(n, (0.52, 0.58, 0.56), 0.76),
    "pegboard": pegboard, "labels": labels, "tags": tags, "locker": locker, "cloth": cloth,
    "enamel": enamel, "frozen": frozen, "wood": wood, "formica": formica, "door": door, "glass": glass,
    "cardboard": cardboard,
    "poster_tomato": lambda n: poster(n, ["ПЕЙТЕ", "ТОМАТНЫЙ", "СОК"], (0.7, 0.13, 0.08), "tomato"),
    "poster_bread": lambda n: poster(n, ["ХЛЕБ —", "ВСЕМУ", "ГОЛОВА"], (0.78, 0.6, 0.25), "bread"),
    "keys": keys, "register": register, "display": display, "grille": grille, "dial": dial,
    "calendar": calendar, "clock": clock, "skin": skin, "face": face,
    "coat": lambda n: twill(n, (0.2, 0.15, 0.12)),
    "guard_wool": lambda n: twill(n, (0.3, 0.33, 0.27)),
    "trousers": lambda n: twill(n, (0.17, 0.18, 0.22)),
    "knit": knit,
    "face_kovpak": lambda n: person_face(n, (0.74, 0.55, 0.47), (0.22, 0.17, 0.13), 40, glasses=True,
                                         moustache=(0.25, 0.2, 0.16), flush=0.35),
    "face_tamara": lambda n: person_face(n, (0.8, 0.64, 0.56), (0.25, 0.18, 0.14), 30, lips=(0.6, 0.18, 0.2)),
    "face_vasya": lambda n: person_face(n, (0.7, 0.5, 0.42), (0.18, 0.14, 0.11), 44, stubble=0.6, flush=0.6),
    "face_edik": lambda n: person_face(n, (0.78, 0.6, 0.52), (0.16, 0.12, 0.1), 26, moustache=(0.18, 0.13, 0.1),
                                       lips=(0.55, 0.3, 0.28)),
    "face_shopper": lambda n: person_face(n, (0.76, 0.6, 0.54), (0.3, 0.24, 0.2), 34, lips=(0.5, 0.28, 0.28),
                                          flush=0.25),
    "fur": fur, "quilted": quilted, "hair": hair, "denim": denim,
    "smock": lambda n: twill(n, (0.55, 0.66, 0.74)),
    "jacket": lambda n: plain(n, (0.12, 0.1, 0.09), 12, 0.35),
    "dublyonka": lambda n: twill(n, (0.36, 0.25, 0.16)),
    "woman_coat": lambda n: twill(n, (0.3, 0.2, 0.24)),
    "headscarf": lambda n: twill(n, (0.5, 0.12, 0.1)),
    "rubber": lambda n: plain(n, (0.08, 0.09, 0.08), 40, 0.2),
    "leather": leather, "torch": torch, "chrome": chrome, "blood": blood, "basket": basket,
    "fabric": lambda n: plain(n, (0.82, 0.82, 0.82), 60, 0.1),
    "white": lambda n: plain(n, (0.9, 0.9, 0.9), 30, 0.04, 64),
    "exit": exit_sign,
}
for _k, _v in SIGNS.items():
    ALL[_k] = (lambda text: lambda n: sign(n, text))(_v)


# Relief: each of these also gets <name>_n.png, a tangent-space normal map
# (OpenGL convention, green up) worked out from the brightness of the colour
# map: dark grout, cracks, weave and grain read as dents. The number is the
# depth; the second one blurs the height first (pixels) for soft materials.
NORMALS = {
    "floor": (3.0, 1.0), "wall": (0.7, 1.5), "ceiling": (1.5, 1.0), "metal": (1.2, 1.0), "paint": (1.2, 1.0),
    "pegboard": (3.0, 0.8), "locker": (1.5, 1.0), "cloth": (1.5, 0.7), "enamel": (0.8, 1.0), "frozen": (2.0, 1.5),
    "wood": (2.5, 0.8), "formica": (0.8, 1.0), "door": (1.5, 1.0), "cardboard": (1.5, 1.0), "skin": (0.8, 1.2),
    "coat": (3.0, 0.7), "guard_wool": (3.0, 0.7), "trousers": (2.5, 0.7), "knit": (4.0, 0.8),
    "rubber": (2.0, 1.0), "leather": (3.0, 1.0), "fur": (4.0, 0.8), "quilted": (3.0, 1.0),
    "dublyonka": (3.0, 0.7), "woman_coat": (3.0, 0.7), "headscarf": (2.0, 0.7), "torch": (1.0, 1.0), "chrome": (0.6, 1.0), "basket": (2.0, 1.0),
    "fabric": (2.0, 1.0), "grille": (3.0, 0.7), "hair": (4.0, 0.6), "denim": (2.5, 0.7), "smock": (2.0, 0.7),
    "jacket": (3.0, 1.0),
}


def normal_map(name):
    depth, soft = NORMALS[name]
    img = np.asarray(Image.open(os.path.join(OUT, name + ".png")).convert("RGB"), np.float32) / 255
    h = blurred(img @ np.array([0.3, 0.59, 0.11], np.float32), soft)
    scale = h.shape[1] / 512 * depth * 4
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * scale
    drow = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * scale
    n = np.stack([-dx, drow, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    path = os.path.join(OUT, name + "_n.png")
    Image.fromarray((n * 127.5 + 127.5).clip(0, 255).astype(np.uint8), "RGB").save(path, optimize=True)
    with open(path + ".import", "w") as f:
        f.write(IMPORT.format(name=name + "_n").replace("compress/mode=0", "compress/mode=0\ncompress/normal_map=1"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(ALL)
    for nm in names:
        ALL[nm](nm)
        if nm in NORMALS:
            normal_map(nm)
        print("made", nm)
