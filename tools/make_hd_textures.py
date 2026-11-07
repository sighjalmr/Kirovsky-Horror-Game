"""2K surfaces: the drawn 512 px textures (tools/make_textures.py and friends)
with real scanned detail laid into them.

The layout, colours and story details of every surface stay as they were
drawn (the cream and brown floor checks, the water streaks on the wall, the
leak in the ceiling tile); what the scans add is what a 512 px drawing cannot
have: the pores and grain of the material, its true relief for the normal
map, the smudges and wipes in its gloss, and dirt sitting in its cavities.

Scans: CC0 materials from the MatSynth collection (ambientCG, cgbookcase,
Poly Haven / texturehaven), https://huggingface.co/datasets/gvecchio/MatSynth.
Fetch them first (about 5 GB of downloads, it reads only the needed columns):

    python tools/make_hd_textures.py fetch /tmp/mat
    python tools/make_hd_textures.py build /tmp/mat [names...]

Writes textures/hd/<name>.webp, <name>_n.webp, <name>_r.webp (2048 px) and
textures/wet_mask.png (the puddles, sampled in world space by the shaders).
"""

import io
import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
ROOT = Path(__file__).resolve().parent.parent
TEX = ROOT / "textures"
OUT = TEX / "hd"
N = 2048

# target -> (scan, colour detail, relief detail, gloss detail, cavity dirt,
#            scan repeats across the texture)
PLAN = {
    "floor": ("acg_terrazzo_005", 0.22, 0.45, 0.45, 0.25, 2),
    "kafel": ("acg_plaster_001", 0.12, 0.25, 0.6, 0.15, 1),
    "concrete": ("th_concrete_wall_005", 0.45, 0.8, 0.5, 0.35, 1),
    "wall": ("th_white_rough_plaster", 0.3, 0.7, 0.3, 0.3, 1),
    "ceiling": ("acg_plaster_001", 0.25, 0.4, 0.2, 0.2, 2),
    "metal": ("acg_painted_metal_009", 0.2, 0.35, 0.6, 0.25, 1),
    "paint": ("acg_painted_metal_009", 0.18, 0.35, 0.55, 0.25, 1),
    "galv": ("cgbc_galvanized_steel_001", 0.4, 0.4, 0.7, 0.2, 1),
    "locker": ("acg_painted_metal_009", 0.12, 0.3, 0.5, 0.2, 3),
    "door": ("acg_painted_wood_004", 0.18, 0.45, 0.4, 0.25, 1),
    "enamel": ("acg_plaster_001", 0.1, 0.2, 0.5, 0.15, 1),
    "frozen": ("cgbc_galvanized_steel_001", 0.15, 0.3, 0.5, 0.15, 1),
    "wood": ("acg_painted_wood_004", 0.35, 0.6, 0.4, 0.3, 1),
    "cardboard": ("acg_cardboard_004", 0.45, 0.6, 0.3, 0.2, 1),
    "ext_asphalt": ("acg_asphalt_024_c", 0.7, 1.0, 0.7, 0.35, 1),
    "ext_slabs": ("th_concrete_wall_005", 0.5, 0.8, 0.5, 0.35, 1),
    "ext_panel": ("th_concrete_wall_005", 0.45, 0.8, 0.4, 0.4, 2),
    "ext_profnastil": ("acg_painted_metal_009", 0.3, 0.35, 0.6, 0.3, 1),
    "corrugated": ("cgbc_galvanized_steel_001", 0.3, 0.35, 0.6, 0.25, 1),
}
# Matt unless their texture says otherwise (Mats.SURFACE[0]).
BASE_ROUGH = {"floor": 0.28, "kafel": 0.15, "concrete": 0.6, "wall": 0.6, "metal": 0.5, "paint": 0.45,
              "galv": 0.4, "locker": 0.5, "door": 0.5, "enamel": 0.3, "frozen": 0.25, "wood": 0.65,
              "cardboard": 0.85, "ceiling": 0.85, "ext_profnastil": 0.5, "corrugated": 0.5, "ext_asphalt": 0.85, "ext_slabs": 0.85, "ext_panel": 0.85}

SMALL_RELIEF = {"ext_panel", "door", "wood", "cardboard", "corrugated", "locker", "enamel", "frozen", "ext_profnastil"}

BASE = "https://huggingface.co/datasets/gvecchio/MatSynth/resolve/main/data/"


def fetch(dest: str) -> None:
    import pyarrow.parquet as pq
    import requests

    sess = requests.Session()
    ca = "/root/.ccr/ca-bundle.crt"
    if os.path.exists(ca):
        sess.verify = ca

    class Range(io.RawIOBase):
        def __init__(self, url):
            r = sess.get(url, headers={"Range": "bytes=0-0"})
            self.url, self.pos = r.url, 0
            self.size = int(r.headers["Content-Range"].split("/")[1])

        def seekable(self):
            return True

        def readable(self):
            return True

        def seek(self, o, w=0):
            self.pos = o if w == 0 else (self.pos + o if w == 1 else self.size + o)
            return self.pos

        def tell(self):
            return self.pos

        def readinto(self, b):
            n = min(len(b), self.size - self.pos)
            if n <= 0:
                return 0
            d = sess.get(self.url, headers={"Range": f"bytes={self.pos}-{self.pos + n - 1}"}, timeout=300).content
            b[:len(d)] = d
            self.pos += len(d)
            return len(d)

    want = {p[0] for p in PLAN.values()}
    files = [f"train-{i:05d}-of-00431.parquet" for i in range(431)] + [f"test-{i:05d}-of-00008.parquet" for i in range(8)]
    for f in files:
        if not want:
            break
        pf = pq.ParquetFile(io.BufferedReader(Range(BASE + f), 1 << 22))
        names = pf.read(columns=["name"]).column(0).to_pylist()
        for row, name in enumerate(names):
            if name not in want:
                continue
            out = Path(dest) / name
            out.mkdir(parents=True, exist_ok=True)
            for col in ("basecolor", "normal", "roughness", "height"):
                v = pf.read(columns=[col]).column(0)[row].as_py()
                im = Image.open(io.BytesIO(v["bytes"]))
                im = im.convert("F") if col == "height" else im.convert("RGB" if col != "roughness" else "L")
                im = im.resize((N, N), Image.LANCZOS)
                if col == "height":
                    a = np.asarray(im)
                    a = (a - a.min()) / max(a.max() - a.min(), 1e-9)
                    im = Image.fromarray((a * 65535).astype(np.uint16))
                im.save(out / f"{col}.png")
            want.discard(name)
            print("fetched", name)


def load(path: Path, mode: str) -> np.ndarray:
    im = Image.open(path)
    if mode == "F":
        a = np.asarray(im).astype(np.float32)
        return a / (65535.0 if a.max() > 255 else 255.0)
    return np.asarray(im.convert(mode), np.float32) / 255.0


def up(a: np.ndarray) -> np.ndarray:
    """The drawn texture at 2048, smoothly (no blocky pixels)."""
    if a.ndim == 2:
        return np.asarray(Image.fromarray(a, "F").resize((N, N), Image.BICUBIC), np.float32)
    return np.stack([up(a[..., i]) for i in range(a.shape[2])], -1)


def blur(a: np.ndarray, r: float) -> np.ndarray:
    k = int(r * 3) + 1
    w = np.exp(-0.5 * (np.arange(-k, k + 1) / r) ** 2)
    w /= w.sum()
    out = a
    for axis in (0, 1):
        out = sum(np.roll(out, i, axis) * w[i + k] for i in range(-k, k + 1))
    return out


def tile(a: np.ndarray, reps: int) -> np.ndarray:
    if reps == 1:
        return a
    small = np.asarray(Image.fromarray(a if a.ndim == 2 else (a * 255).astype(np.uint8)).resize(
        (N // reps, N // reps), Image.LANCZOS), np.float32)
    if a.ndim == 3:
        small /= 255.0
    out = np.tile(small, (reps, reps) + ((1,) if a.ndim == 3 else ()))
    if out.shape[0] != N:  # 2048 does not divide by every count: stretch the last pixels
        out = up(out) if out.ndim == 2 else np.stack([up(out[..., i]) for i in range(3)], -1)
    return out


def save_webp(a: np.ndarray, path: Path, quality: int) -> None:
    im = Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8))
    im.save(path, "WEBP", quality=quality, method=6)
    imp = Path(str(path) + ".import")
    if not imp.exists():
        normal = path.stem.endswith("_n")
        imp.write_text(IMPORT.format(name=path.name, nm=1 if normal else 0,
                                     mode=2, srgb=0 if (normal or path.stem.endswith("_r")) else 1))


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"
metadata={{
"vram_texture": true
}}

[deps]

source_file="res://textures/hd/{name}"

[params]

compress/mode={mode}
compress/high_quality=false
compress/lossy_quality=0.7
compress/normal_map={nm}
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/size_limit=0
detect_3d/compress_to=0
"""


def build(scans: str, only: list) -> None:
    OUT.mkdir(exist_ok=True)
    for name, (scan, c_amt, n_amt, r_amt, dirt, reps) in PLAN.items():
        if only and name not in only:
            continue
        src = Path(scans) / scan
        base = load(TEX / f"{name}.png", "RGBA")
        alpha = up(base[..., 3])
        col = up(base[..., :3])
        s_col = tile(load(src / "basecolor.png", "RGB"), reps)
        s_h = tile(load(src / "height.png", "F"), reps)
        s_n = tile(load(src / "normal.png", "RGB"), reps)
        s_r = tile(load(src / "roughness.png", "L"), reps)
        # Colour detail: the scan's own light and dark against its local
        # average, so its hue does not leak into the drawn colours.
        lum = s_col @ np.array([0.3, 0.59, 0.11], np.float32)
        detail = lum / np.maximum(blur(lum, 24.0), 1e-3)
        col = col * (1.0 + (np.clip(detail, 0.4, 1.8)[..., None] - 1.0) * c_amt)
        # Dirt in the hollows: where the scan's surface sits below its surroundings.
        cav = np.clip((blur(s_h, 6.0) - s_h) * 8.0, 0, 1)
        col = col * (1.0 - cav[..., None] * dirt * 0.6)
        out = np.concatenate([np.clip(col, 0, 1), alpha[..., None]], -1) if alpha.min() < 0.99 else np.clip(col, 0, 1)
        save_webp(out, OUT / f"{name}.webp", 90)
        # Relief: the drawn normal (tiles, grout, cracks) with the scan's
        # fine relief laid over it (reoriented normal blending).
        nb = TEX / f"{name}_n.png"
        t = up(load(nb, "RGB")) * 2 - 1 if nb.exists() else np.dstack([np.zeros((N, N)), np.zeros((N, N)), np.ones((N, N))])
        u = s_n * 2 - 1
        u[..., :2] *= n_amt
        u /= np.linalg.norm(u, axis=-1, keepdims=True)
        t = t + np.array([0, 0, 1], np.float32)
        u = u * np.array([-1, -1, 1], np.float32)
        n = t * (t * u).sum(-1, keepdims=True) / t[..., 2:3] - u
        n /= np.linalg.norm(n, axis=-1, keepdims=True)
        if name in SMALL_RELIEF:  # seen from further off: relief at 1024
            n = np.stack([np.asarray(Image.fromarray(n[..., i].astype(np.float32), "F").resize((N // 2, N // 2), Image.LANCZOS))
                          for i in range(3)], -1)
        save_webp(n * 0.5 + 0.5, OUT / f"{name}_n.webp", 92)
        # Gloss: the drawn roughness (mopped streaks, worn lanes) varied by
        # the scan's smudges and wipes around its own average.
        rb = TEX / f"{name}_r.png"
        r = up(load(rb, "L")) if rb.exists() else np.full((N, N), BASE_ROUGH.get(name, 0.8), np.float32)
        r = r + (s_r - blur(s_r, 32.0)) * r_amt + cav * dirt * 0.3
        # Gloss at 1024 (it varies slowly; keeps the game smaller).
        r = np.asarray(Image.fromarray(np.clip(r, 0.03, 1.0).astype(np.float32), "F").resize((N // 2, N // 2), Image.LANCZOS))
        save_webp(r, OUT / f"{name}_r.webp", 88)
        print("made", name, "from", scan)
    wet_mask()
    leaves()


def leaves() -> None:
    """Falling leaves for the day street (Exterior._build_leaves): a 2×2 atlas
    of a yellow birch leaf, a browner one, a poplar leaf and a curled dry one,
    with alpha."""
    from PIL import ImageDraw
    rng = np.random.default_rng(14)
    S = 256
    img = Image.new("RGBA", (S * 2, S * 2), (0, 0, 0, 0))
    kinds = [((0.86, 0.68, 0.18), 0.62, 1.0), ((0.62, 0.42, 0.14), 0.6, 0.95),
             ((0.74, 0.62, 0.2), 0.85, 0.85), ((0.45, 0.3, 0.12), 0.45, 0.7)]
    for k, (c, wide, length) in enumerate(kinds):
        layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        pts = []
        for i in range(64):
            t = i / 64 * 2 * np.pi
            r = 1.0 + 0.06 * np.sin(t * 22) * (k != 3)  # serrated edge
            x = np.sin(t) * wide * 0.42 * r * (1 - 0.35 * np.cos(t))
            y = -np.cos(t) * 0.44 * length * r
            pts.append((S / 2 + x * S, S / 2 + y * S))
        col = tuple(int(v * 255) for v in c) + (255,)
        d.polygon(pts, fill=col)
        a = np.asarray(layer, np.float32) / 255
        yy, xx = np.mgrid[0:S, 0:S] / S
        blot = np.clip(rng.random((S, S)) * 0.15 + 0.92, 0, 1)
        edge = 1 - 0.35 * np.clip(np.hypot(xx - 0.5, (yy - 0.5) * 0.8) * 2.2, 0, 1) ** 3
        a[..., :3] *= (blot * edge)[..., None]
        layer = Image.fromarray((a * 255).astype(np.uint8))
        d = ImageDraw.Draw(layer)
        vein = tuple(int(v * 255 * 0.7) for v in c) + (255,)
        d.line([(S / 2, S * 0.08), (S / 2, S * 0.97)], fill=vein, width=3)
        for j in range(5):
            y0 = S * (0.3 + j * 0.11)
            for sx in (-1, 1):
                d.line([(S / 2, y0), (S / 2 + sx * S * wide * 0.3, y0 - S * 0.09)], fill=vein, width=1)
        img.paste(layer, ((k % 2) * S, (k // 2) * S))
    img.save(TEX / "leaves.png")


def wet_mask() -> None:
    """Puddles and damp patches, 512 px tiling noise sampled by world position
    (psx_common: one repeat every 14 m): 1 = standing water, 0 = dry."""
    rng = np.random.default_rng(1988)
    a = np.zeros((512, 512), np.float32)
    for r, w in ((36.0, 0.6), (14.0, 0.28), (4.0, 0.12)):  # the blur wraps, so it tiles
        n = blur(rng.random((512, 512)).astype(np.float32), r)
        a += (n - n.mean()) / n.std() * w
    a = (a - a.min()) / (a.max() - a.min())
    Image.fromarray((a * 255).astype(np.uint8), "L").save(TEX / "wet_mask.png")


if __name__ == "__main__":
    if sys.argv[1] == "fetch":
        fetch(sys.argv[2])
    else:
        build(sys.argv[2], sys.argv[3:])
