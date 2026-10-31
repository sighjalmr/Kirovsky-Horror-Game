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
        # Optional relief (0..1, high is raised) and roughness (0 glossy..1 matt)
        # maps. A texture that fills `relief` gets its normal map from it instead of
        # from the brightness; one that fills `rough` also gets <name>_r.png.
        self.relief = None
        self.rough = None

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
        write_import(path, IMPORT.format(name=name))
        if self.relief is not None:
            HEIGHTS[name] = self.relief
        if self.rough is not None:
            rp = os.path.join(OUT, name + "_r.png")
            Image.fromarray((np.clip(self.rough, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(rp, optimize=True)
            write_import(rp, IMPORT.format(name=name + "_r"))


HEIGHTS = {}


def write_import(path, text):
    """Import settings for a new PNG; an existing .import keeps its uid."""
    if not os.path.exists(path + ".import"):
        with open(path + ".import", "w") as f:
            f.write(text)


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

def grime(t, scale):
    """Dirt that does not look like clouds: broad noise broken up by fine
    noise, so the stain edges fray."""
    n = t.noise(scale, 6, 0.6) * 0.75 + t.noise(max(3, scale / 8), 3) * 0.25
    n -= n.min()
    return n / max(n.max(), 1e-6)


def smooth(x):
    x = np.clip(x, 0, 1)
    return x * x * (3 - 2 * x)


def tile_grid(t, cols, rows, gap, bevel, tilt=0.0, ox=0, oy=0):
    """Per-pixel tile index, distance to the tile edge (px) and a relief map:
    grout at 0, tile faces at ~1 with rounded edges and each tile sitting a
    little crooked. The grid may be offset (ox, oy px) and wraps round."""
    yy, xx = np.mgrid[0:t.h, 0:t.w].astype(np.float32)
    tw, th = t.w / cols, t.h / rows
    gx, gy = (xx - ox) % t.w, (yy - oy) % t.h
    ix, iy = (gx // tw).astype(int), (gy // th).astype(int)
    lx, ly = gx - ix * tw, gy - iy * th
    d = np.minimum(np.minimum(lx, tw - 1 - lx), np.minimum(ly, th - 1 - ly)) - gap * 0.5
    idx = iy * cols + ix
    sx = t.rng.normal(0, tilt, cols * rows).astype(np.float32)
    sy = t.rng.normal(0, tilt, cols * rows).astype(np.float32)
    lift = t.rng.normal(0, tilt * 4, cols * rows).astype(np.float32)
    face = 1.0 + sx[idx] * (lx / tw - 0.5) + sy[idx] * (ly / th - 0.5) + lift[idx]
    h = np.where(d < 0, 0.0, face * (0.55 + 0.45 * smooth(d / max(bevel, 1e-3))))
    return idx, d, h.astype(np.float32)


def scuffs(t, count, region, color, opacity, width=(1, 3), length=(6, 26), angle=None):
    """Black heel and trolley-wheel marks: short curved strokes."""
    img, d = t.layer()
    x0, y0, w, h = region
    for _ in range(count):
        px, py = x0 + t.rng.random() * w, y0 + t.rng.random() * h
        a = t.rng.random() * np.pi * 2 if angle is None else angle + (t.rng.random() - 0.5) * 0.3
        ln = length[0] + t.rng.random() * (length[1] - length[0])
        bend = (t.rng.random() - 0.5) * 0.12
        pts = []
        for k in range(8):
            pts.append((px, py))
            a += bend
            px += np.cos(a) * ln / 8
            py += np.sin(a) * ln / 8
        c = rgb8(color)[:3] + (int(60 + t.rng.random() * 195),)
        d.line(pts, fill=c, width=int(t.rng.integers(width[0], width[1] + 1)), joint="curve")
    t.over(img, opacity, 1.1)
    return np.asarray(img, np.float32)[..., 3] / 255.0


def floor(name):
    """Soviet ceramic floor, 1.2 m square: 4×4 tiles of 30 cm in a checkerboard
    of cream and dark brown-grey, grout gone black with mop water, each tile a
    shade off its neighbour and set a little crooked, terrazzo flecks, worn
    matt where people walk and glossy where it was mopped, heel marks, chipped
    corners, a cracked tile."""
    t = T(512, 512, (0.13, 0.12, 0.1), name)
    idx, d, h = tile_grid(t, 4, 4, 4.0, 5.0, 0.05)
    tiles = d >= 0
    light = ((idx % 4 + idx // 4) % 2 == 0)
    bv = t.rng.normal(0, 0.035, 16).astype(np.float32)[idx][..., None]
    cream = np.array((0.68, 0.64, 0.55), np.float32)
    dark = np.array((0.36, 0.33, 0.3), np.float32)
    col = np.where(light[..., None], cream, dark) * (1 + bv)
    # Clay body: mottled, with fine pores.
    col = col * (0.92 + 0.1 * t.noise(24, 4)[..., None]) * (0.97 + 0.05 * t.noise(4, 2)[..., None])
    grout = np.array((0.16, 0.15, 0.13), np.float32) * (0.8 + 0.4 * t.noise(16, 3)[..., None])
    t.a[..., :3] = np.where(tiles[..., None], col, grout)
    # Terrazzo flecks.
    fl = t.rng.random((512, 512)) < 0.012
    fl = blurred(fl.astype(np.float32), 0.6) > 0.18
    tone = t.noise(3, 1)
    t.mix((0.2, 0.19, 0.17), fl & tiles & (tone < 0.55), None)
    t.mix((0.85, 0.82, 0.76), (fl & tiles & (tone >= 0.55)) * 0.7, None)
    # Edges darker where dirt sits, a lighter worn rim on the light tiles.
    edge = np.clip(1 - d / 7.0, 0, 1) * tiles
    t.mul(1 - edge * 0.25)
    # Chipped corners and a cracked tile.
    chips = np.zeros((512, 512), np.float32)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    for _ in range(5):
        cx, cy = t.rng.integers(0, 4) * 128 + (2 if t.rng.random() < 0.5 else 126), t.rng.integers(0, 4) * 128 + (2 if t.rng.random() < 0.5 else 126)
        r = 5 + t.rng.random() * 7
        chips = np.maximum(chips, np.clip(1.5 - np.hypot(xx - cx, yy - cy) / r - t.noise(6, 2) * 0.6, 0, 1))
    chip = chips > 0.5
    t.mix((0.2, 0.18, 0.15), chip * 0.9)
    h = np.where(chip, h * 0.35, h)
    crack = np.zeros((512, 512), np.float32)
    # Traffic: a broad trodden lane worn matt and greyed, dirt in low spots.
    lane = t.noise(256, 3)
    wear = smooth((lane - 0.45) / 0.4)
    t.mix((0.42, 0.4, 0.36), wear * 0.18 * tiles)
    dirt = grime(t, 90)
    t.stain(dirt, 0.6, (0.25, 0.21, 0.16), 0.4)
    t.shade(t.noise(200, 4), 0.86, 1.05)
    marks = scuffs(t, 30, (0, 0, 512, 512), (0.05, 0.05, 0.05), 0.4, (2, 4), (10, 40))
    # Gloss: mopped streaks in one direction, the lane dull, grout matt.
    mop = blurred(t.noise(48, 3), 1.0).astype(np.float32)
    mop = np.asarray(Image.fromarray(mop, "F").resize((512, 64), Image.BICUBIC).resize((512, 512), Image.BICUBIC))
    r = 0.22 + 0.22 * wear + 0.18 * mop + 0.25 * (dirt > 0.62)
    r = np.where(tiles & ~chip, r, 0.85)
    r = np.clip(r + marks * 0.3 + crack * 0.4, 0.08, 1)
    t.relief = h
    t.rough = r
    t.grain(0.012)
    t.save(name)


def wall(name):
    """Upper wall over the tiles, 1.6 m square: whitewash on lumpy plaster,
    roller marks, hairline cracks, grey dust bloom and brown water streaks
    running down from the ceiling (top of the texture)."""
    t = T(512, 512, (0.74, 0.73, 0.67), name)
    lump = t.noise(64, 5)
    t.shade(lump, 0.9, 1.04)
    t.shade(t.noise(220, 4), 0.8, 1.04)
    # Roller marks: faint vertical bands.
    band = np.asarray(Image.fromarray(t.noise(40, 2, w=512, h=8), "F").resize((512, 512), Image.BICUBIC))
    t.shade(band, 0.96, 1.02)
    t.stain(grime(t, 140), 0.62, (0.5, 0.47, 0.4), 0.4)
    # Water streaks and a ceiling-line leak.
    img, d = t.layer()
    for _ in range(9):
        x = t.rng.random() * 512
        ln = 40 + t.rng.random() * 320
        w = 1 + t.rng.random() * 4
        ph = t.rng.random() * 9
        for k in range(int(ln)):
            a = int(90 * (1 - k / ln) ** 1.5 * (0.6 + 0.4 * np.sin(k * 0.11 + ph)))
            xo = x + np.sin(k * 0.03 + ph) * 3
            d.line([(xo, k), (xo + w * (1 - k / ln * 0.6), k)], fill=(115, 95, 65, a))
    t.over(img, 1.0, 1.4)
    leak = np.clip(1 - (np.mgrid[0:512, 0:512][0] / 60.0), 0, 1) * t.noise(80, 3)
    t.mix((0.5, 0.42, 0.3), leak * 0.6)
    t.cracks(1, 60, (0.42, 0.41, 0.37), 1, 0.35)
    crack = blurred((np.asarray(t.a[..., 0]) < 0.45).astype(np.float32), 0.5)
    # Flaking whitewash showing grey plaster.
    flake = t.blob_mask(10, 3, 14, None, 1.4) > 0.4
    t.mix((0.52, 0.51, 0.47), flake * 0.8)
    t.relief = lump * 0.6 + flake * -0.25 - crack * 0.4
    t.rough = np.full((512, 512), 0.9, np.float32)
    t.grain(0.012)
    t.save(name)


def kafel(name):
    """Glazed wall tiles, 15 cm, 4×4 to the texture (60 cm square): off-white
    with a green-grey cast, crazing in the glaze, grime in the grout, a few
    chipped corners, a cracked tile and one replaced in a whiter shade."""
    t = T(512, 512, (0.3, 0.3, 0.28), name)
    idx, d, h = tile_grid(t, 4, 4, 3.0, 4.0, 0.04)
    tiles = d >= 0
    v = t.rng.normal(0, 0.02, 16).astype(np.float32)
    base = np.array((0.74, 0.77, 0.7), np.float32)
    col = base * (1 + v[idx][..., None])
    odd = t.rng.integers(0, 16)
    col = np.where((idx == odd)[..., None], np.array((0.82, 0.83, 0.8), np.float32), col)
    col = col * (0.96 + 0.05 * t.noise(60, 3)[..., None])
    grout = np.array((0.55, 0.54, 0.49), np.float32) * (0.85 + 0.25 * t.noise(12, 3)[..., None])
    t.a[..., :3] = np.where(tiles[..., None], col, grout)
    t.mul(1 - np.clip(1 - d / 6.0, 0, 1) * tiles * 0.12)
    # Crazing: a web of hairlines in the glaze.
    img, dr = t.layer()
    for _ in range(260):
        x, y = t.rng.random() * 512, t.rng.random() * 512
        a = t.rng.random() * np.pi * 2
        pts = [(x, y)]
        for _ in range(5):
            a += (t.rng.random() - 0.5) * 1.4
            x, y = x + np.cos(a) * 6, y + np.sin(a) * 6
            pts.append((x, y))
        dr.line(pts, fill=(120, 118, 105, 255), width=1)
    t.over(img, 0.05)
    t.cracks(1, 30, (0.25, 0.24, 0.2), 1, 0.8)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    chip = np.zeros((512, 512), bool)
    for _ in range(4):
        cx, cy = t.rng.integers(0, 4) * 128 + 3, t.rng.integers(0, 4) * 128 + 3
        chip |= (np.hypot(xx - cx, yy - cy) + t.noise(5, 2) * 5) < 9
    t.mix((0.62, 0.58, 0.5), chip * 0.9)
    t.stain(grime(t, 100), 0.62, (0.45, 0.42, 0.33), 0.3)
    marks = scuffs(t, 10, (0, 380, 512, 132), (0.15, 0.15, 0.13), 0.25, (2, 4), (30, 90), 0.0)
    h = np.where(chip, h * 0.4, h)
    t.relief = h
    t.rough = np.where(tiles & ~chip, 0.12 + 0.12 * t.noise(80, 3) + marks * 0.3, 0.9)
    t.grain(0.01)
    t.save(name)


def concrete(name):
    """Plastered concrete of a column, 1.2 m square, painted oil-white:
    trowel waves, pinholes, a grey band rubbed by trolleys low down."""
    t = T(512, 512, (0.7, 0.7, 0.66), name)
    wave = t.noise(90, 5)
    t.shade(wave, 0.88, 1.05)
    pores = (t.rng.random((512, 512)) < 0.004)
    pores = blurred(pores.astype(np.float32), 0.7) > 0.15
    t.mix((0.35, 0.35, 0.32), pores * 0.6)
    t.stain(grime(t, 150), 0.6, (0.48, 0.45, 0.38), 0.35)
    rows = np.mgrid[0:512, 0:512][0].astype(np.float32)
    low = smooth((rows - 400) / 80) * t.noise(30, 3)
    t.mix((0.3, 0.3, 0.28), low * 0.5)
    marks = scuffs(t, 30, (0, 400, 512, 112), (0.08, 0.08, 0.08), 0.35, (2, 5), (30, 120), 0.0)
    chips = t.blob_mask(6, 2, 10, None, 1.3) > 0.4
    t.mix((0.5, 0.49, 0.45), chips * 0.8)
    t.relief = wave * 0.7 - pores * 0.4 - chips * 0.3
    t.rough = np.clip(0.55 + 0.2 * t.noise(60, 3) + chips * 0.3 + marks * 0.2, 0, 1)
    t.grain(0.012)
    t.save(name)


def galv(name):
    """Galvanised sheet steel of the air duct, dulled with age: rolling
    streaks, a folded seam, grey dust settled on top, oily fingerprints."""
    t = T(512, 512, (0.5, 0.52, 0.53), name)
    streak = np.asarray(Image.fromarray(t.noise(20, 3, w=512, h=16), "F").resize((512, 512), Image.BICUBIC))
    t.shade(streak, 0.9, 1.06)
    t.shade(t.noise(200, 4), 0.82, 1.05)
    t.shade(t.noise(6, 2), 0.97, 1.03)
    t.rect(0, 250, 512, 4, (0.36, 0.37, 0.38))
    t.rect(0, 254, 512, 2, (0.68, 0.7, 0.7))
    dust = grime(t, 80)
    t.stain(dust, 0.6, (0.5, 0.49, 0.46), 0.4)
    seam = np.zeros(512, np.float32)
    seam[250:256] = 0.8
    t.relief = streak * 0.2 + seam[:, None]
    t.rough = np.clip(0.3 + streak * 0.2 + (dust > 0.55) * 0.4, 0, 1)
    t.grain(0.01)
    t.save(name)


def ceiling(name):
    """Suspended ceiling, 1.2 m square: 2×2 fissured mineral tiles of 60 cm in
    a white T-bar grid, each tile a shade off, one sagging and water-stained
    with a brown tide line, fly specks, grey dust along the bars."""
    t = T(512, 512, (0.66, 0.65, 0.61), name)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    lx, ly = xx % 256, yy % 256
    d = np.minimum(np.minimum(lx, 255 - lx), np.minimum(ly, 255 - ly))
    idx = (yy // 256) * 2 + xx // 256
    v = t.rng.normal(0, 0.025, 4).astype(np.float32)
    t.a[..., :3] *= (1 + v[idx.astype(int)])[..., None]
    t.shade(t.noise(64, 4), 0.9, 1.04)
    img, dr = t.layer()
    for _ in range(3200):  # fissures: short wormy dents
        x, y = t.rng.random() * 512, t.rng.random() * 512
        a = t.rng.random() * np.pi
        ln = 2 + t.rng.random() * 7
        pts = [(x, y), (x + np.cos(a) * ln * 0.5, y + np.sin(a) * ln * 0.5 + t.rng.random()),
               (x + np.cos(a) * ln, y + np.sin(a) * ln)]
        dr.line(pts, fill=(255, 255, 255, 255), width=1)
    fis = np.asarray(img, np.float32)[..., 3] / 255
    t.mix((0.37, 0.36, 0.33), fis * 0.75)
    pin = t.rng.random((512, 512)) < 0.006
    t.mix((0.3, 0.3, 0.28), pin * 0.8)
    # Dust settles on the tile edges next to the bars.
    t.mix((0.45, 0.44, 0.4), np.clip(1 - (d - 5) / 10, 0, 1) * 0.35)
    bar = d < 5
    t.mix((0.78, 0.78, 0.75), bar)
    t.mix((0.35, 0.35, 0.33), (d >= 5) & (d < 6.5))
    # The leak: tide rings and a sag in the bottom-right tile.
    dd = np.sqrt((xx - 380) ** 2 + (yy - 384) ** 2) + t.noise(40, 3) * 30
    ring = np.exp(-((dd - 70) / 5) ** 2) * 0.55 + np.exp(-((dd - 48) / 4) ** 2) * 0.3 + (dd < 70) * 0.2
    t.mix((0.48, 0.38, 0.22), ring * (~bar))
    h = np.where(bar, 1.0, 0.75) - fis * 0.25 - pin * 0.3
    h = h - np.where(idx == 3, np.clip(1 - dd / 120, 0, 1) * 0.35, 0)
    t.relief = h.astype(np.float32)
    t.rough = np.where(bar, 0.4, 0.95).astype(np.float32)
    t.grain(0.01)
    t.save(name)


def painted_metal(name, base, rust=0.72):
    """Painted sheet steel: brushed paint with drips, scratches through to
    primer, rubbed edges, chips with rust, rust runs."""
    t = T(512, 512, base, name)
    brush = np.asarray(Image.fromarray(t.noise(30, 3, w=512, h=32), "F").resize((512, 512), Image.BICUBIC))
    t.shade(t.noise(200, 5), 0.86, 1.06)
    t.shade(brush, 0.95, 1.04)
    t.shade(t.noise(12, 3), 0.97, 1.02)
    img, d = t.layer()
    for _ in range(90):
        x, y = t.rng.random() * 512, t.rng.random() * 512
        a = (t.rng.random() - 0.5) * 0.6 + (0 if t.rng.random() < 0.6 else np.pi / 2)
        ln = 8 + t.rng.random() * 40
        d.line([(x, y), (x + np.cos(a) * ln, y + np.sin(a) * ln)], fill=(255, 255, 255, int(80 + t.rng.random() * 175)),
               width=1)
    scr = np.asarray(img, np.float32)[..., 3] / 255
    t.mix(np.minimum(np.array(base) * 1.15 + 0.05, 1), scr * 0.3)
    chips = t.blob_mask(22, 1.5, 6, None, 1.3) > 0.45
    rim = blurred(chips.astype(np.float32), 1.2) > 0.05
    t.mix(np.array(base) * 0.6, (rim & ~chips) * 0.5)
    t.mix((0.36, 0.2, 0.1), chips)
    r = grime(t, 50)
    t.stain(r, rust + 0.04, (0.45, 0.25, 0.12), 0.6)
    t.stain(r, rust + 0.14, (0.25, 0.12, 0.06), 0.7)
    # Rust runs down from the chips.
    run = np.zeros((512, 512), np.float32)
    ch = chips.astype(np.float32)
    for k in range(1, 40, 2):
        run = np.maximum(run, np.roll(ch, k, 0) * (1 - k / 40))
    t.mix((0.42, 0.26, 0.14), run * 0.35 * t.noise(6, 2))
    t.relief = 0.7 + brush * 0.1 - scr * 0.15 - chips * 0.45 + rim * 0.05
    t.rough = np.clip(0.42 + 0.1 * brush + scr * 0.2 + chips * 0.4 + (r > rust) * 0.35, 0, 1)
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


def notice(name):
    """«Уголок покупателя» (512×384, mapped once): a varnished board with the
    title painted on, pinned sheets of typed rules, the complaints book on a
    string, a licence under glass."""
    t = T(512, 384, (0.5, 0.33, 0.2), name)
    grain = np.asarray(Image.fromarray(t.noise(30, 4, w=512, h=24), "F").resize((512, 384), Image.BICUBIC))
    t.shade(grain, 0.8, 1.1)
    t.bevel(0, 0, 512, 384, 10, (0.7, 0.5, 0.32), (0.22, 0.13, 0.07), 0.9)
    t.rect(20, 18, 472, 54, (0.62, 0.1, 0.07))
    t.text((256, 46), "УГОЛОК ПОКУПАТЕЛЯ", 34, (0.96, 0.92, 0.78), rough=0.25)
    sheets = [(28, 92, 140, 196, "ПРАВИЛА\nторговли\nв магазинах\nсамообслуживания"),
              (182, 92, 148, 120, "РЕЖИМ РАБОТЫ\n8.00 — 21.00\nперерыв\n13.00 — 14.00"),
              (182, 224, 148, 128, "Телефоны\nвышестоящих\nорганизаций"),
              (344, 92, 140, 160, "КНИГА\nжалоб и\nпредложений\nнаходится у\nдиректора")]
    for x, y, w, h, txt in sheets:
        tone = 0.86 + t.rng.random() * 0.06
        t.rect(x + 3, y + 4, w, h, (0.12, 0.08, 0.05), 0.5)
        t.rect(x, y, w, h, (tone, tone * 0.97, tone * 0.86))
        t.text((x + w / 2, y + 16), txt.split("\n")[0], 15, (0.12, 0.1, 0.1), anchor="mt")
        img, d = t.layer()
        for k, ln in enumerate(txt.split("\n")[1:]):
            d.text((x + w / 2, y + 38 + k * 17), ln, font=font(12, False, True), fill=(40, 36, 34, 255), anchor="mt")
        for k in range(int((h - 50 - len(txt.split("\n")) * 17) / 9)):  # typed lines
            yy = y + 50 + len(txt.split("\n")) * 17 + k * 9
            if yy < y + h - 8:
                d.line([(x + 10, yy), (x + 10 + (w - 20) * (0.6 + 0.4 * t.rng.random()), yy)], fill=(70, 66, 60, 200))
        t.over(img)
        t.rect(x + w / 2 - 3, y + 3, 6, 6, (0.75, 0.72, 0.6))
        t.stain(t.noise(30, 3), 0.7, (0.6, 0.5, 0.3), 0.3, (x, y, w, h))
    # Licence in a frame.
    t.rect(344, 266, 140, 92, (0.3, 0.3, 0.3))
    t.rect(350, 272, 128, 80, (0.82, 0.8, 0.7))
    t.text((414, 290), "РАЗРЕШЕНИЕ", 12, (0.3, 0.1, 0.1))
    t.rect(370, 320, 40, 20, (0.4, 0.2, 0.55), 0.5)
    t.grain(0.01)
    t.save(name)


def fire_board(name):
    """Fire board (512×512, mapped once on a 1.2 m panel): red paint over
    plywood, white stencil «ПОЖАРНЫЙ ЩИТ», painted outlines where the tools
    hang, chips and dust."""
    t = T(512, 512, (0.58, 0.08, 0.06), name)
    t.shade(t.noise(120, 5), 0.8, 1.06)
    t.bevel(0, 0, 512, 512, 8, (0.75, 0.2, 0.15), (0.25, 0.03, 0.02), 0.8)
    t.text((256, 44), "ПОЖАРНЫЙ ЩИТ", 40, (0.92, 0.9, 0.84), rough=0.3)
    t.text((256, 486), "№ 2   тел. 01", 26, (0.92, 0.9, 0.84), rough=0.3)
    img, d = t.layer()
    d.rectangle((40, 90, 120, 460), outline=(235, 230, 215, 140), width=3)
    d.rectangle((380, 90, 470, 300), outline=(235, 230, 215, 140), width=3)
    t.over(img)
    chips = t.blob_mask(14, 2, 7, None, 1.3) > 0.4
    t.mix((0.62, 0.55, 0.42), chips)
    t.stain(grime(t, 80), 0.62, (0.3, 0.12, 0.08), 0.4)
    t.rough = np.clip(0.45 + chips * 0.4, 0, 1).astype(np.float32)
    t.grain(0.012)
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


def ornament(name):
    """Gallery parapet panels, 1.2 m square: stamped anodised aluminium in
    bronze and gold, a grid of 4×4 cells, each a diamond in a diamond with a
    boss in the middle, the late-seventies universam look."""
    t = T(512, 512, (0.55, 0.4, 0.2), name)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    cx = (xx % 128) - 64
    cy = (yy % 128) - 64
    dia = (np.abs(cx) + np.abs(cy)) / 64.0  # 0 in the middle, 1 at the cell corners' diamond
    rings = np.cos(dia * np.pi * 3.0) * 0.5 + 0.5
    boss = np.clip(1 - np.sqrt(cx ** 2 + cy ** 2) / 12.0, 0, 1)
    seam = np.minimum(np.minimum(np.abs(cx + 64), np.abs(cx - 64)), np.minimum(np.abs(cy + 64), np.abs(cy - 64)))
    seam = np.clip(seam / 3.0, 0, 1)
    h = (rings * 0.55 + boss * 0.6) * (dia < 0.95) + (dia >= 0.95) * 0.15
    h = h * seam
    t.relief = h.astype(np.float32)
    gold = np.array([0.78, 0.6, 0.3], np.float32)
    bronze = np.array([0.42, 0.27, 0.13], np.float32)
    m = np.clip(h, 0, 1)[..., None]
    t.a[..., :3] = bronze * (1 - m) + gold * m
    t.mul(0.55 + 0.45 * seam)
    t.shade(grime(t, 120), 0.82, 1.05)
    t.grain(0.012)
    t.rough = 0.35 + 0.3 * (1 - m[..., 0])
    t.save(name)


def corrugated(name):
    """Profiled steel cladding of the upper walls, 1.2 m square: vertical
    ribs every 15 cm, light so it can be tinted, streaks of dust."""
    t = T(256, 256, (0.85, 0.86, 0.84), name)
    xx = np.mgrid[0:256, 0:256][1].astype(np.float32)
    rib = np.abs(((xx % 32) / 32.0) - 0.5) * 2
    t.relief = smooth(np.clip((rib - 0.3) * 2.5, 0, 1)).astype(np.float32)
    t.mul(0.78 + 0.22 * t.relief)
    t.lines(30, 120, (0.6, 0.6, 0.58), 1, 0.15, None, np.pi / 2, 0.05)
    t.shade(grime(t, 90), 0.88, 1.03)
    t.save(name)


def kirovsky_letters(name):
    """«КИРОВСКИЙ» as on the 1980s facade: one white letter on each red
    square box, nine of them in a strip (1152×128, 128 px a letter)."""
    word = "КИРОВСКИЙ"
    t = T(128 * len(word), 128, (0.72, 0.1, 0.07), name)
    t.shade(t.noise(60, 3), 0.9, 1.05)
    for i, ch in enumerate(word):
        x = i * 128
        t.bevel(x, 0, 128, 128, 7, (0.95, 0.45, 0.35), (0.3, 0.04, 0.02), 0.8)
        t.text((x + 64, 68), ch, 98, (0.97, 0.95, 0.9))
    t.stain(grime(t, 50), 0.7, (0.35, 0.1, 0.06), 0.4)
    t.grain(0.01)
    t.save(name)


SIGNS = {"sign_bakaleya": "БАКАЛЕЯ", "sign_konservy": "КОНСЕРВЫ", "sign_moloko": "МОЛОКО", "sign_zamorozka": "ЗАМОРОЗКА",
         "sign_promtovary": "ПРОМТОВАРЫ", "sign_tkani": "ТКАНИ", "sign_posuda": "ПОСУДА", "sign_galantereya": "ГАЛАНТЕРЕЯ"}

ALL = {
    "floor": floor, "wall": wall, "ceiling": ceiling, "kafel": kafel, "concrete": concrete, "galv": galv,
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
    "exit": exit_sign, "notice": notice, "fire_board": fire_board,
    "ornament": ornament, "corrugated": corrugated, "kirovsky_letters": kirovsky_letters,
}
for _k, _v in SIGNS.items():
    ALL[_k] = (lambda text: lambda n: sign(n, text))(_v)


# Relief: each of these also gets <name>_n.png, a tangent-space normal map
# (OpenGL convention, green up) worked out from the brightness of the colour
# map: dark grout, cracks, weave and grain read as dents. The number is the
# depth; the second one blurs the height first (pixels) for soft materials.
NORMALS = {
    "floor": (6.0, 1.0), "wall": (1.2, 1.2), "ceiling": (2.0, 0.8), "metal": (2.0, 0.8), "paint": (2.0, 0.8),
    "kafel": (6.0, 0.8), "concrete": (1.5, 1.0), "galv": (1.5, 0.8),
    "pegboard": (3.0, 0.8), "locker": (1.5, 1.0), "cloth": (1.5, 0.7), "enamel": (0.8, 1.0), "frozen": (2.0, 1.5),
    "wood": (2.5, 0.8), "formica": (0.8, 1.0), "door": (1.5, 1.0), "cardboard": (1.5, 1.0), "skin": (0.8, 1.2),
    "coat": (3.0, 0.7), "guard_wool": (3.0, 0.7), "trousers": (2.5, 0.7), "knit": (4.0, 0.8),
    "rubber": (2.0, 1.0), "leather": (3.0, 1.0), "fur": (4.0, 0.8), "quilted": (3.0, 1.0),
    "dublyonka": (3.0, 0.7), "woman_coat": (3.0, 0.7), "headscarf": (2.0, 0.7), "torch": (1.0, 1.0), "chrome": (0.6, 1.0), "basket": (2.0, 1.0),
    "fabric": (2.0, 1.0), "grille": (3.0, 0.7), "hair": (4.0, 0.6), "denim": (2.5, 0.7), "smock": (2.0, 0.7),
    "jacket": (3.0, 1.0), "ornament": (5.0, 0.8), "corrugated": (3.0, 1.0),
}


def normal_map(name):
    depth, soft = NORMALS[name]
    if name in HEIGHTS:
        h = blurred(HEIGHTS[name], soft)
    else:
        img = np.asarray(Image.open(os.path.join(OUT, name + ".png")).convert("RGB"), np.float32) / 255
        h = blurred(img @ np.array([0.3, 0.59, 0.11], np.float32), soft)
    scale = h.shape[1] / 512 * depth * 4
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * scale
    drow = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * scale
    n = np.stack([-dx, drow, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    path = os.path.join(OUT, name + "_n.png")
    Image.fromarray((n * 127.5 + 127.5).clip(0, 255).astype(np.uint8), "RGB").save(path, optimize=True)
    write_import(path, IMPORT.format(name=name + "_n").replace("compress/mode=0", "compress/mode=0\ncompress/normal_map=1"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(ALL)
    for nm in names:
        ALL[nm](nm)
        if nm in NORMALS:
            normal_map(nm)
        print("made", nm)
