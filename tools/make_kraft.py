"""Brown meat-counter wrapping paper: textures/kraft.png and kraft_n.png.

Fibres, a faint grain, soft wrinkles and grease blots; tileable (all noise
is built from wrapped gaussian blurs). Run: python3 tools/make_kraft.py
"""
import numpy as np
from PIL import Image
from pathlib import Path

N = 512
rng = np.random.default_rng(1988)


def blur(a, s):
    # Periodic gaussian blur through the FFT, so the texture tiles.
    f = np.fft.fftfreq(N)
    g = np.exp(-(f[:, None] ** 2 + f[None, :] ** 2) * (2 * np.pi * s) ** 2 / 2)
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def norm(a):
    return (a - a.min()) / (a.max() - a.min() + 1e-9)


grain = norm(blur(rng.normal(size=(N, N)), 1.2))
mottle = norm(blur(rng.normal(size=(N, N)), 18))
wrinkle = blur(rng.normal(size=(N, N)), 6)
ridges = 1 - np.abs(norm(blur(rng.normal(size=(N, N)), 10)) * 2 - 1)
height = norm(wrinkle) * 0.8 + ridges ** 3 * 0.3 + grain * 0.15

# Fibres: short bright and dark streaks.
fib = np.zeros((N, N))
for _ in range(2600):
    x, y = rng.integers(0, N, 2)
    ang = rng.uniform(0, np.pi)
    ln = rng.integers(4, 16)
    v = rng.uniform(-1, 1)
    for t in range(ln):
        fib[int(y + np.sin(ang) * t) % N, int(x + np.cos(ang) * t) % N] += v
fib = blur(fib, 0.6)

base = np.array([160, 132, 104], float) / 255
shade = 0.86 + (mottle - 0.5) * 0.08 + (grain - 0.5) * 0.08 + fib * 0.25 + (height - 0.5) * 0.04
blots = norm(blur(rng.normal(size=(N, N)), 24))
grease = np.clip((blots - 0.82) * 3, 0, 1) * 0.6
rgb = base[None, None, :] * shade[:, :, None]
rgb = rgb * (1 - grease[:, :, None] * np.array([0.35, 0.4, 0.45]))
Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).save("textures/kraft.png")

dy, dx = np.gradient(blur(height, 1.0))
s = 2.5
nx, ny, nz = -dx * s, -dy * s, np.ones_like(dx)
ln = np.sqrt(nx ** 2 + ny ** 2 + nz ** 2)
nrm = np.stack([nx / ln, ny / ln, nz / ln], -1) * 0.5 + 0.5
Image.fromarray((nrm * 255).astype(np.uint8)).save("textures/kraft_n.png")
print("textures/kraft.png, textures/kraft_n.png")
