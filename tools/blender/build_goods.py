"""The goods of «Кировский» modelled in Blender: models/kit/goods.glb.

Run:  /path/to/python3.11 tools/blender/build_goods.py            (export)
      ... build_goods.py -- '{"preview": "/tmp/goods.png"}'      (+ a render)

Every product of Goods.ITEMS (scripts/goods.gd) in two or three variants
(a dented tin, a crushed pack, a bag that settled differently), plus the
new range drawn in textures/goods2.png (tools/make_goods2.py): bread,
biscuits, coffee, lemonade, mineral water, eggs, …

Shapes follow the real things: a tin has its double-seamed rims, beads and
a lid with expansion rings; a three-litre jar has the rounded heel, the
shoulder, the crown neck and the seamed-on lid; a milk bottle has the wide
mouth under a crinkled foil cap; a card pack has softened edges and the
glued flap; a paper bag bellies out and is folded over at the top; the
chicken is a metaball body with legs and wings. All surfaces use one of
the two goods atlases, with ambient occlusion baked into vertex colours.
"""
import os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix, noise
from bkit import *  # noqa

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
# Second atlas (tools/make_goods2.py), same 4 × 8 layout.
CELLS2 = [
    "baton", "borodinsky", "kirpich", "bulka",
    "pryaniki", "yubileynoe", "coffee", "kakao",
    "gerkules", "vermishel", "kisel", "lavr",
    "buratino", "tarhun", "mineral", "bottles",
    "eggs", "syrki", "tomato_paste", "gorchitsa",
    "saira", "turist", "bychki", "baklazhan",
    "soap", "zubnoy", "palochki", "karamel",
    "lids2", "kraft", "yogurt", "metal2",
]


def cell(name):
    if name in CELLS:
        return grid_cell(CELLS.index(name)), "goods"
    return grid_cell(CELLS2.index(name)), "goods2"


METAL = grid_cell(CELLS.index("metal")).sub(0.0, 0.5, 0.1, 0.3)
GOLD = grid_cell(CELLS.index("metal")).sub(0.5, 1.0, 0.1, 0.3)
LIDS = ["TIN", "GOLD", "SPRATS", "KILKA", "FOIL_MILK", "FOIL_KEFIR", "FOIL_RYAZHENKA", "FOIL_SMETANA"]


def lid_rect(lid):
    i = LIDS.index(lid)
    c = grid_cell(CELLS.index("lids"))
    return c.sub((i % 4) * 0.25, (i % 4 + 1) * 0.25, (i // 4) * 0.5, (i // 4 + 1) * 0.5)


def lid2_rect(i):
    c = grid_cell(CELLS2.index("lids2"))
    return c.sub((i % 4) * 0.25, (i % 4 + 1) * 0.25, (i // 4) * 0.5, (i // 4 + 1) * 0.5)


def segs_for(r):
    return 14 if r < 0.03 else 18 if r < 0.045 else 20 if r < 0.07 else 24


# --- dents and wear ---------------------------------------------------------------

def dent(o, seed, depth=0.006, size=0.025, zfrac=0.5, h=0.1):
    rnd = random.Random(seed)
    a = rnd.uniform(-1.0, 1.0)  # mostly to the sides, not dead front
    c = Vector((math.sin(a) * 1.0, math.cos(a) * 1.0, 0)).normalized()
    zc = h * zfrac

    def f(co):
        d = Vector((co.x, co.y, 0))
        if d.length < 1e-6:
            return Vector()
        dn = d.normalized()
        ang = math.acos(max(-1, min(1, dn.dot(c))))
        dist = math.hypot(ang * d.length, co.z - zc)
        k = math.exp(-(dist / size) ** 2)
        return -dn * depth * k
    displace(o, f)


def wobble(o, seed, amount, scale=12.0, keep_bottom=True):
    off = Vector((seed * 3.1, seed * 1.7, seed * 0.3))

    def f(co):
        n = noise.noise_vector(co * scale + off)
        k = 1.0 if not keep_bottom else min(1.0, co.z / 0.01)
        return n * amount * k
    displace(o, f)


# --- round goods -------------------------------------------------------------------

def tin(name, r, h, cname, lid, variant=0):
    rect, tex = cell(cname)
    m = Mesh()
    s = segs_for(r)
    b = 0.0065
    # Bottom double seam, then the label between beads.
    m.lathe([(r * 0.9, 0.0), (r * 1.025, 0.0015), (r * 1.035, b * 0.5), (r * 1.02, b), (r * 0.995, b + 0.0015)],
            METAL, tex, s)
    nr = 4 if variant else 1
    rows = [b + 0.0015 + (h - 2 * b - 0.003) * i / nr for i in range(nr + 1)]
    m.lathe([(r, z) for z in rows], rect, tex, s, v=[1 - i / nr for i in range(nr + 1)])
    # Top seam: a raised rim, then the lid stepped down with its rings.
    m.lathe([(r * 0.995, h - b - 0.0015), (r * 1.02, h - b), (r * 1.035, h - b * 0.5), (r * 1.03, h),
             (r * 0.985, h + 0.0005), (r * 0.95, h - 0.0005), (r * 0.935, h - 0.003)], METAL, tex, s)
    m.disc(r * 0.935, h - 0.003, lid_rect(lid), tex, s, rings=[(r * 0.8, 0.0), (r * 0.78, 0.0012)])
    m.disc(r * 0.9, 0.0, METAL, tex, s, up=False)
    o = m.to_object(name)
    if variant == 1:
        dent(o, sum(map(ord, name)) % 1000, depth=r * 0.12, size=r * 0.5, zfrac=0.45, h=h)
    elif variant == 2:
        dent(o, sum(map(ord, name)) % 997 + 5, depth=r * 0.07, size=r * 0.35, zfrac=0.92, h=h)
    return o


def flat(name, r, h, cname, lid, variant=0):
    rect, tex = cell(cname)
    body = rect.sub(0, 1, 0.2, 0.8) if cname != "metal" else METAL
    rim = METAL if lid != "SPRATS" else GOLD
    m = Mesh()
    s = 28
    m.lathe([(r * 0.92, 0), (r * 1.02, 0.001), (r * 1.03, 0.004), (r, 0.006)], rim, tex, s)
    m.lathe([(r, 0.006), (r, h - 0.006)], body, tex, s)
    m.lathe([(r, h - 0.006), (r * 1.03, h - 0.003), (r * 1.025, h), (r * 0.96, h), (r * 0.95, h - 0.0012)], rim, tex, s)
    m.disc(r * 0.95, h - 0.0012, lid_rect(lid), tex, s, rings=[(r * 0.75, 0.0), (r * 0.73, 0.001)])
    o = m.to_object(name)
    if variant == 1:
        dent(o, 17, depth=0.004, size=0.02, zfrac=0.5, h=h)
    return o


def jar(name, r, h, cname, lid, body, variant=0):
    """Glass jar: heel, body, shoulder, crown neck, seamed tin lid."""
    rect, tex = cell(cname)
    m = Mesh()
    s = segs_for(r)
    neck = r * 0.66
    lid_h = h * 0.06
    top = h - lid_h
    prof = [(r * 0.8, 0.0), (r * 0.94, 0.004), (r * 0.995, h * 0.03), (r, h * 0.06), (r, top * body),
            (r * 0.97, top * (body + (1 - body) * 0.2)), (r * 0.88, top * (body + (1 - body) * 0.5)),
            (neck * 1.12, top * 0.93), (neck * 1.02, top * 0.96), (neck * 1.06, top * 0.975), (neck * 1.02, top)]
    m.lathe(prof, rect, tex, s)
    m.disc(r * 0.8, 0.0, rect.sub(0.4, 0.6, 0.85, 0.95), tex, s, up=False)
    gold = GOLD
    m.lathe([(neck * 1.02, top), (neck * 1.12, top + 0.002), (neck * 1.13, h - 0.004), (neck * 1.1, h - 0.001),
             (neck * 1.06, h), (neck * 1.0, h - 0.0015)], gold, tex, s)
    m.disc(neck * 1.0, h - 0.0015, lid_rect(lid), tex, s, rings=[(neck * 0.85, 0.0), (neck * 0.83, 0.0015)])
    o = m.to_object(name)
    if variant == 1:  # lid on a little crooked
        for v in o.data.vertices:
            if v.co.z > top - 0.001:
                v.co.z += v.co.x * 0.06
    return o


def bottle(name, r, h, cname, lid, body, wide, variant=0, cap="foil"):
    rect, tex = cell(cname)
    m = Mesh()
    s = segs_for(r)
    neck = r * (0.68 if wide else 0.42)
    prof = [(r * 0.8, 0), (r * 0.95, 0.003), (r, h * 0.035), (r, h * body),
            (r * 0.93, h * (body + 0.06)), (r * 0.72, h * (body + 0.16)), (neck * 1.1, h * 0.84),
            (neck, h * 0.9), (neck, h * 0.935)]
    if not wide:
        prof = [(r * 0.8, 0), (r * 0.95, 0.003), (r, h * 0.035), (r, h * body), (r * 0.9, h * (body + 0.08)),
                (r * 0.62, h * (body + 0.2)), (neck * 1.15, h * 0.72), (neck, h * 0.8), (neck, h * 0.93)]
    m.lathe(prof, rect, tex, s)
    m.disc(r * 0.8, 0, rect.sub(0.4, 0.6, 0.85, 0.95), tex, s, up=False)
    if cap == "foil":
        foil = lid_rect(lid) if isinstance(lid, str) else lid2_rect(lid)
        mid = foil.sub(0.45, 0.55, 0.45, 0.55, px=0)
        cr = neck * 1.14
        rows = [h * 0.925, h * 0.95, h * 0.985]
        m.lathe([(cr * 1.03, rows[0]), (cr, rows[1]), (cr * 0.99, rows[2]), (cr * 0.93, h)], mid, tex, s * 2)
        m.disc(cr * 0.93, h, foil, tex, s)
        o = m.to_object(name)
        # Crinkle the skirt of the foil.
        for v in o.data.vertices:
            if h * 0.92 < v.co.z < h * 0.99:
                a = math.atan2(v.co.y, v.co.x)
                k = 1.0 + 0.04 * math.sin(a * 13 + v.co.z * 400) * (h * 0.99 - v.co.z) / (h * 0.07)
                v.co.x *= k
                v.co.y *= k
    else:  # crown cork
        m.lathe([(neck * 1.15, h * 0.93), (neck * 1.2, h * 0.94), (neck * 1.18, h * 0.985), (neck * 1.1, h)],
                GOLD, tex, s)
        m.disc(neck * 1.1, h, lid2_rect(cap) if isinstance(cap, int) else GOLD, tex, s)
        o = m.to_object(name)
    return o


def smetana(name, r, h, cname, lid, variant=0):
    rect, tex = cell(cname)
    m = Mesh()
    s = 20
    m.lathe([(r * 0.82, 0), (r * 0.92, 0.003), (r * 0.95, h * 0.1), (r, h * 0.8), (r * 0.95, h * 0.88),
             (r * 1.02, h * 0.92)], rect.sub(0, 1, 0.2, 1.0), tex, s)
    foil = lid_rect(lid)
    m.lathe([(r * 1.06, h * 0.91), (r * 1.05, h * 0.97), (r * 1.0, h)], foil.sub(0.45, 0.55, 0.45, 0.55, 0), tex, s * 2)
    m.disc(r * 1.0, h, foil, tex, s)
    o = m.to_object(name)
    for v in o.data.vertices:
        if v.co.z > h * 0.9 and v.co.z < h * 0.99:
            a = math.atan2(v.co.y, v.co.x)
            k = 1.0 + 0.035 * math.sin(a * 11)
            v.co.x *= k
            v.co.y *= k
    return o


def cup(name, r, h, cname, variant=0):
    """A waffle cup of пломбир with its paper lid: a ribbed cone."""
    rect, tex = cell(cname)
    m = Mesh()
    s = 24
    m.lathe([(r * 0.7, 0), (r * 0.98, h * 0.9), (r * 1.05, h * 0.93), (r * 1.04, h * 0.97)],
            rect.sub(0, 1, 0.15, 1.0), tex, s)
    m.disc(r * 1.04, h * 0.97, rect.sub(0, 0.25, 0, 0.15), tex, s, rings=[(r * 0.9, 0.0), (r * 0.88, 0.003)])
    m.disc(r * 0.7, 0, rect.sub(0, 0.25, 0, 0.15), tex, s, up=False)
    o = m.to_object(name)
    for v in o.data.vertices:  # the waffle ribs
        if 0.002 < v.co.z < h * 0.9:
            a = math.atan2(v.co.y, v.co.x)
            k = 1.0 + 0.025 * max(0, math.cos(a * 12))
            v.co.x *= k
            v.co.y *= k
    return o


# --- packs and bags -------------------------------------------------------------------

def pack(name, s, cname, variant=0, bev=None, flap=True):
    """Card pack, size (w, h, d) in game terms; front = the left half of the
    cell, sides the next quarter, top the last quarter."""
    rect, tex = cell(cname)
    w, h, d = s
    m = Mesh()
    rects = {"+y": rect.sub(0, 0.5), "-y": rect.sub(0, 0.5), "+x": rect.sub(0.5, 0.75), "-x": rect.sub(0.5, 0.75),
             "+z": rect.sub(0.75, 1.0), "-z": rect.sub(0.75, 1.0)}
    # Subdivided so dents and bulges bend smoothly.
    _sub_box(m, (w, d, h), rects, tex, n=(4, 3, 5))
    o = m.to_object(name)
    bevel(o, bev if bev is not None else min(w, d, h) * 0.06, segs=2, angle=30)
    if variant == 1:  # crushed corner
        c = Vector((w * 0.5, d * 0.5, h))
        displace(o, lambda co: Vector((0, 0, -min(w, h) * 0.12)) * max(0.0, 1 - (co - c).length / (min(w, h) * 0.5)))
    elif variant == 2:  # bulging sides
        displace(o, lambda co: Vector((0, co.y / max(d, 1e-6) * 0.1 * d, 0)) * math.sin(math.pi * min(1, max(0, co.z / h))))
    if flap and h > 0.06:
        # Glued flap lip under the top edge at the front and the back.
        fm = Mesh()
        for sy in (-1, 1):
            fm.box((0, sy * (d * 0.5 + 0.0006), h - 0.012), (w * 0.96, 0.0012, 0.018),
                   {"+y" if sy > 0 else "-y": rect.sub(0.75, 1.0, 0.0, 0.2)}, tex)
        fo = fm.to_object(name + "_flap")
        o = join([o, fo], name)
    return o


def _sub_box(m, size, rects, tex, n=(3, 3, 3)):
    """A box from subdivided grids, bottom at z=0, front +y."""
    w, d, h = size
    if not isinstance(rects, dict):
        rects = {k: rects for k in Mesh.FACES}
    for k, (nn, u, v) in Mesh.FACES.items():
        if k not in rects:
            continue
        r = rects[k]
        nn, u, v = Vector(nn), Vector(u), Vector(v)
        half = Vector((w / 2, d / 2, h / 2))
        hn = abs(nn.dot(half)); hu = abs(u.dot(half)); hv = abs(v.dot(half))
        o = Vector((0, 0, h / 2)) + nn * hn
        nu = n[0] if abs(u.x) > 0.5 else n[1] if abs(u.y) > 0.5 else n[2]
        nv = n[0] if abs(v.x) > 0.5 else n[1] if abs(v.y) > 0.5 else n[2]
        rows, uvs = [], []
        for j in range(nv + 1):
            row, urow = [], []
            for i in range(nu + 1):
                a, b = i / nu, j / nv
                row.append(o + u * hu * (2 * a - 1) + v * hv * (2 * b - 1))
                urow.append(r.uv(a, 1 - b))
            rows.append(row)
            uvs.append(urow)
        m.grid(rows, uvs, tex, smooth=False)


def bag(name, s, cname, variant=0):
    """A filled paper bag folded over at the top."""
    rect, tex = cell(cname)
    w, h, d = s
    body = h * 0.84
    m = Mesh()
    rects = {"+y": rect.sub(0, 0.5), "-y": rect.sub(0, 0.5), "+x": rect.sub(0.5, 0.75), "-x": rect.sub(0.5, 0.75),
             "-z": rect.sub(0.75, 1.0)}
    _sub_box(m, (w, d, body), rects, tex, n=(6, 4, 8))
    t = rect.sub(0.75, 1.0)
    # Fold: two slopes up to a ridge, a flap turned down over the front.
    ridge = h
    hx, hy = w / 2, d / 2
    nsl = 4
    for sy in (-1, 1):
        rows, uvs = [], []
        for j in range(nsl + 1):
            b = j / nsl
            yy = sy * hy * (1 - b)
            zz = body + (ridge - body) * math.sin(b * math.pi / 2)
            row = [Vector((hx * (2 * i / 6 - 1) * (1 - 0.08 * b), yy, zz)) for i in range(7)]
            if sy < 0:
                row = row[::-1]
            rows.append(row)
            uvs.append([t.uv(i / 6, 1 - b) for i in range(7)])
        m.grid(rows, uvs, tex, smooth=True)
    for sx in (-1, 1):
        for sy in (-1, 1):
            pts = [Vector((sx * hx, sy * hy, body)), Vector((sx * hx, 0, body)), Vector((sx * hx * 0.92, 0, ridge))]
            if sx * sy > 0:
                pts = pts[::-1]
            m.face(pts, [t.uv(0, 1), t.uv(0.5, 1), t.uv(0.5, 0)], tex)
    # The folded flap, a strip lying on the front slope.
    fl = []
    for j in range(3):
        b = j / 2
        zz = ridge - 0.002 - (ridge - body) * 0.55 * b
        yy = hy * 0.15 + hy * 0.55 * b + 0.003
        fl.append([Vector((hx * 0.9 * (2 * i / 6 - 1), yy, zz)) for i in range(7)][::-1])
    m.grid(fl, [[t.uv(i / 6, b) for i in range(7)] for b in (0, 0.5, 1)], tex)
    o = m.to_object(name)
    seed = (sum(map(ord, name)) % 100) + variant * 7

    def belly(co):
        if co.z > body:
            return Vector()
        k = math.sin(math.pi * co.z / body) ** 0.7
        ex = math.cos(math.pi * co.x / w) * k
        ey = math.cos(math.pi * co.y / d) * k
        n = noise.noise_vector(co * 40 + Vector((seed, seed * 0.3, 0))) * 0.004
        sag = Vector((0, 0, 0))
        return Vector((co.x / max(hx, 1e-6) * ey * 0.07 * w * 0.5, co.y / max(hy, 1e-6) * ex * 0.12 * d * 0.5, 0)) + n + sag
    displace(o, belly)
    if variant:
        # Settled a little to one side.
        displace(o, lambda co: Vector((co.z / h * 0.012 * (1 if variant == 1 else -1), 0, 0)))
    smooth_by_angle(o, 50)
    return o


def tetra(name, e, cname, variant=0):
    """The triangular milk pack lying on one face, crimped seams along
    two opposite edges."""
    rect, tex = cell(cname)
    hb = e * math.sqrt(3) / 2
    # Game frame (x, y=up, z=back) -> Blender (x, -z, y)
    G = lambda x, y, z: Vector((x, -z, y))
    a = G(-e / 2, 0, -hb / 3)
    b = G(e / 2, 0, -hb / 3)
    dd = G(0, 0, hb * 2 / 3)
    top = G(0, e * math.sqrt(2 / 3), 0)
    m = Mesh()
    faces = [[b, a, top], [dd, b, top], [a, dd, top]]
    for k, f in enumerate(faces):
        r = rect.sub(0.0 if k != 1 else 0.5, 0.5 if k != 1 else 1.0, 0, 1, 0)
        # Subdivide each face for a slight bulge.
        n = 4
        P = lambda i, j: f[0] + (f[1] - f[0]) * (i / n) + (f[2] - f[0]) * (j / n)
        U = lambda i, j: (r.uv(i / n + j / n * 0.5, 1 - j / n))
        for j in range(n):
            for i in range(n - j):
                m.face([P(i, j), P(i + 1, j), P(i, j + 1)], [U(i, j), U(i + 1, j), U(i, j + 1)], tex)
                if i + j + 1 < n:
                    m.face([P(i + 1, j), P(i + 1, j + 1), P(i, j + 1)], [U(i + 1, j), U(i + 1, j + 1), U(i, j + 1)], tex)
    m.face([a, b, dd], [rect.uv(0, 1), rect.uv(0.5, 1), rect.uv(0.25, 0.5)], tex)
    # Crimped fins: along the edge a-top and along b-d.
    fin = rect.sub(0.45, 0.55, 0.0, 0.05, 0)
    for p, q in ((a, top), (b, dd)):
        mid = (p + q) / 2
        cen = (a + b + dd + top) / 4
        out = (mid - cen).normalized() * 0.008
        m.face([p, q, q + out, p + out], [fin.uv(0, 1), fin.uv(1, 1), fin.uv(1, 0), fin.uv(0, 0)], tex)
        m.face([p + out, q + out, q, p], [fin.uv(0, 0), fin.uv(1, 0), fin.uv(1, 1), fin.uv(0, 1)], tex)
    o = m.to_object(name)
    cen = (a + b + dd + top) / 4
    displace(o, lambda co: (co - cen) * 0.06 * max(0.0, 1 - (co - cen).length / (e * 0.6)))
    return o


# --- refrigerated counter goods -----------------------------------------------------

def wheel(name, r, h, cname, variant=0):
    rect, tex = cell(cname)
    rind = rect.sub(0.0, 0.75)
    face = rect.sub(0.75, 1.0)
    m = Mesh()
    s = 16
    prof = [(0, 0), (r * 0.94, 0), (r * 0.99, h * 0.08), (r, h * 0.25), (r, h * 0.75), (r * 0.99, h * 0.92),
            (r * 0.94, h), (0, h)]
    # Half a lathe round the back, the cut face to the front (+y).
    rows, uvs = [], []
    for j, (pr, pz) in enumerate(prof):
        row, urow = [], []
        for i in range(s + 1):
            a = math.pi + math.pi * i / s
            row.append(Vector((math.cos(a) * pr, -math.sin(a) * pr * -1 * -1, pz)))
            urow.append(rind.uv(i / s, 1 - j / (len(prof) - 1)))
        rows.append(row)
        uvs.append(urow)
    m.grid(rows, uvs, tex)
    m.face([Vector((-r, 0, 0)), Vector((r, 0, 0)), Vector((r, 0, h)), Vector((-r, 0, h))],
           [face.uv(0, 1), face.uv(1, 1), face.uv(1, 0), face.uv(0, 0)], tex)
    o = m.to_object(name)
    me = o.data
    me.flip_normals() if False else None
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    return o


def sausage(name, length, r, cname, variant=0):
    rect, tex = cell(cname)
    m = Mesh()
    prof = [(0.0005, -0.012), (r * 0.3, 0), (r * 0.8, r * 0.25), (r, r)]
    n = 10
    for i in range(1, n):
        prof.append((r * (1 + 0.03 * math.sin(i * 2.1)), r + (length - 2 * r) * i / n))
    prof += [(r, length - r), (r * 0.8, length - r * 0.25), (r * 0.3, length), (0.0005, length + 0.012)]
    m.lathe(prof, rect.sub(0, 0.75), tex, 16)
    o = m.to_object(name)
    # Lay it along x on the ground, with a slight bow.
    bow = 0.012 if variant == 0 else -0.018
    for v in o.data.vertices:
        z = v.co.z - length / 2
        x, y = v.co.x, v.co.y
        v.co = Vector((z, y, x + r + bow * (1 - (2 * z / length) ** 2)))
    # Twine ties at both ends.
    tm = Mesh()
    for sz in (-1, 1):
        tm.lathe([(r * 0.32, 0), (r * 0.36, 0.004), (r * 0.32, 0.008)], rect.sub(0.8, 0.95, 0.4, 0.6), tex, 8,
                 xf=Matrix.Translation((sz * (length / 2 + 0.002), 0, r)) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
    t = tm.to_object(name + "_t")
    o = join([o, t], name)
    smooth_by_angle(o, 60)
    return o


def frozen_block(name, s, cname, variant=0):
    rect, tex = cell(cname)
    w, h, d = s
    m = Mesh()
    _sub_box(m, (w, d, h), rect, tex, n=(8, 6, 3))
    o = m.to_object(name)
    bevel(o, 0.008, 2, 30)
    wobble(o, 3 + variant, 0.006, 18)
    return o


def butter(name, s, cname, variant=0):
    rect, tex = cell(cname)
    w, h, d = s
    m = Mesh()
    rects = {"+y": rect.sub(0, 0.5), "-y": rect.sub(0, 0.5), "+x": rect.sub(0.5, 0.75), "-x": rect.sub(0.5, 0.75),
             "+z": rect.sub(0, 0.5), "-z": rect.sub(0.75, 1.0)}
    _sub_box(m, (w, d, h), rects, tex, n=(4, 3, 2))
    o = m.to_object(name)
    bevel(o, 0.005, 3, 30)
    wobble(o, 9 + variant, 0.0015, 30)
    return o


def chicken(name, s, cname, variant=0):
    """A frozen chicken on its back: metaball body, thighs, drumsticks, wings,
    turned into a mesh and planar-mapped onto the skin cell."""
    rect, tex = cell(cname)
    w, h, d = s  # length x, height, width
    mb = bpy.data.metaballs.new(name + "_mb")
    mb.resolution = 0.012
    mb.threshold = 0.6
    ob = bpy.data.objects.new(name + "_mbo", mb)
    link(ob)

    def ball(co, r, kind="BALL", sz=None):
        e = mb.elements.new()
        e.co = co
        e.radius = r
        if sz:
            e.type = "ELLIPSOID"
            e.size_x, e.size_y, e.size_z = sz
        return e
    ball((-w * 0.06, 0, h * 0.42), w * 0.28, sz=(1.4, 1.0, 0.75))
    ball((w * 0.12, 0, h * 0.42), w * 0.24, sz=(1.2, 1.0, 0.7))
    ball((-w * 0.32, 0, h * 0.38), w * 0.16)
    for sy in (-1, 1):
        ball((w * 0.2, sy * d * 0.22, h * 0.7), w * 0.13)
        ball((w * 0.3, sy * d * 0.2, h * 0.95), w * 0.1)
        ball((w * 0.08, sy * d * 0.12, h * 1.02), w * 0.06)
        ball((-w * 0.12, sy * d * 0.42, h * 0.32), w * 0.1, sz=(1.6, 0.6, 0.6))
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    o = bpy.data.objects.new(name, me)
    link(o)
    # Rest the lowest point on the ground.
    zmin = min(v.co.z for v in me.vertices)
    for v in me.vertices:
        v.co.z -= zmin
    me.materials.append(mat(tex))
    uv = me.uv_layers.new(name="UVMap")
    tint = me.color_attributes.new("Tint", "FLOAT_COLOR", "CORNER")
    for poly in me.polygons:
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv = rect.uv(min(1, max(0, co.x / w + 0.5)), min(1, max(0, 0.5 - co.y / d)))
            tint.data[li].color = (1, 1, 1, 1)
        poly.use_smooth = True
    wobble(o, 21 + variant, 0.003, 25, keep_bottom=False)
    return o


# --- the second atlas: bread, biscuits, drinks ------------------------------------------

def loaf(name, s, cname, kind, variant=0):
    """Bread: a батон (long, slashes), бородинский (dark brick with
    coriander), кирпич (tin loaf with a domed top), булка (round)."""
    rect, tex = cell(cname)
    w, h, d = s
    m = Mesh()
    if kind == "bulka":
        m.lathe([(0.0005, 0), (w * 0.42, 0.0), (w * 0.5, h * 0.25), (w * 0.47, h * 0.6), (w * 0.33, h * 0.88),
                 (0.0005, h)], rect, tex, 20)
        o = m.to_object(name)
        wobble(o, 31 + variant, 0.004, 20)
        smooth_by_angle(o, 70)
        return o
    _sub_box(m, (w, d, h), {"+y": rect.sub(0, 0.5), "-y": rect.sub(0, 0.5), "+x": rect.sub(0.5, 0.75),
                            "-x": rect.sub(0.5, 0.75), "+z": rect.sub(0.75, 1.0), "-z": rect.sub(0.75, 1.0)},
             tex, n=(12, 6, 5))
    o = m.to_object(name)
    if kind == "baton":
        # Round the cross-section, taper the ends, cut the slashes.
        def f(co):
            t = co.x / (w / 2)
            end = 1 - 0.35 * abs(t) ** 4
            zc = h * 0.45
            ny = co.y / (d / 2)
            nz = (co.z - zc) / (h * 0.55)
            r = math.hypot(ny, nz) or 1
            k = 1 / max(abs(ny), abs(nz), 1e-6) / r if r > 0 else 1
            ny2, nz2 = ny * k, nz * k
            y = ny2 * d / 2 * end
            z = zc + nz2 * h * 0.55 * end
            z = max(z, 0.0)
            slash = 0.0
            if co.z > h * 0.8:
                ph = (co.x / w * 5 + co.y / d * 0.6) % 1.0
                slash = -0.006 * math.exp(-((ph - 0.5) / 0.08) ** 2)
            return Vector((co.x * (1 - 0.04 * abs(t)), y, z + slash)) - co
        displace(o, f)
    elif kind in ("borodinsky", "kirpich"):
        dome = 0.25 if kind == "kirpich" else 0.06

        def f(co):
            t = co.z / h
            ex = 1 - 4 * (co.x / w) ** 2
            ey = 1 - 4 * (co.y / d) ** 2
            up = dome * h * max(0, ex) * max(0, ey) * t ** 2
            flare = 0.05 * t ** 3 if kind == "kirpich" else 0
            return Vector((co.x * flare, co.y * flare, up))
        displace(o, f)
        bevel(o, 0.008, 2, 30)
    wobble(o, 37 + variant, 0.0025, 25)
    smooth_by_angle(o, 50)
    return o


def egg_tray(name, s, cname, variant=0):
    """A grey moulded tray of ten eggs (2 × 5) under a lid made of the same pulp."""
    rect, tex = cell(cname)
    w, h, d = s
    m = Mesh()
    pulp = rect.sub(0.75, 1.0, 0.5, 1.0)
    label = rect.sub(0, 0.75)
    _sub_box(m, (w, d, h * 0.45), {"+y": pulp, "-y": pulp, "+x": pulp, "-x": pulp, "-z": pulp}, tex, n=(10, 4, 2))
    # The lid: a dome of ten bumps with the paper band.
    rows, uvs = [], []
    nx, ny = 20, 8
    for j in range(ny + 1):
        row, urow = [], []
        for i in range(nx + 1):
            x = -w / 2 + w * i / nx
            y = -d / 2 + d * j / ny
            bx = math.cos(math.pi * 5 * (i / nx)) ** 2
            by = math.cos(math.pi * 2 * (j / ny)) ** 2
            edge = min(i, nx - i, j, ny - j)
            z = h * 0.45 + (h * 0.4 + h * 0.15 * bx * by) * min(1, edge / 1.5)
            row.append(Vector((x, y, z)))
            urow.append(label.uv(i / nx, 1 - j / ny))
        rows.append(row)
        uvs.append(urow)
    m.grid(rows, uvs, tex)
    o = m.to_object(name)
    smooth_by_angle(o, 50)
    return o


def soap(name, s, cname, variant=0):
    rect, tex = cell(cname)
    w, h, d = s
    m = Mesh()
    _sub_box(m, (w, d, h), rect, tex, n=(4, 3, 2))
    o = m.to_object(name)
    bevel(o, 0.006, 3, 30)
    return o


# --- the catalogue -------------------------------------------------------------------------

# id: (shape, (w, h, d) like Goods.ITEMS, cell, lid/extra, variants)
ITEMS = {
    "peas": ("tin", (0.1, 0.112, 0.1), "peas", "TIN", 3),
    "condensed": ("tin", (0.076, 0.084, 0.076), "condensed", "TIN", 3),
    "tushonka": ("tin", (0.1, 0.076, 0.1), "tushonka", "GOLD", 3),
    "kapusta": ("tin", (0.084, 0.1, 0.084), "kapusta", "TIN", 2),
    "kilka": ("flat", (0.105, 0.034, 0.105), "kilka", "KILKA", 2),
    "sprats": ("flat", (0.1, 0.03, 0.1), "metal", "SPRATS", 2),
    "ikra": ("jar", (0.084, 0.13, 0.084), "ikra", "GOLD", 2, 0.78),
    "jar_tomato": ("jar", (0.17, 0.27, 0.17), "jar_tomato", "GOLD", 2, 0.68),
    "jar_birch": ("jar", (0.17, 0.27, 0.17), "jar_birch", "GOLD", 2, 0.68),
    "jar_apple": ("jar", (0.17, 0.27, 0.17), "jar_apple", "GOLD", 2, 0.68),
    "oil": ("bottle", (0.068, 0.27, 0.068), "oil", "FOIL_MILK", 1, 0.45, False),
    "milk": ("bottle", (0.07, 0.205, 0.07), "glass_milk", "FOIL_MILK", 1, 0.55, True),
    "kefir": ("bottle", (0.07, 0.205, 0.07), "glass_milk", "FOIL_KEFIR", 1, 0.55, True),
    "ryazhenka": ("bottle", (0.07, 0.205, 0.07), "glass_milk", "FOIL_RYAZHENKA", 1, 0.55, True),
    "smetana": ("smetana", (0.072, 0.085, 0.072), "glass_milk", "FOIL_SMETANA", 1),
    "tetra": ("tetra", (0.165, 0.135, 0.15), "tetra", None, 2),
    "salt": ("pack", (0.085, 0.13, 0.055), "salt", None, 3),
    "tea": ("pack", (0.062, 0.095, 0.036), "tea", None, 3),
    "macaroni": ("pack", (0.09, 0.22, 0.06), "macaroni", None, 3),
    "matches": ("pack", (0.19, 0.075, 0.052), "matches", None, 2),
    "chicory": ("pack", (0.065, 0.12, 0.045), "chicory", None, 3),
    "barley": ("pack", (0.085, 0.14, 0.05), "barley", None, 3),
    "soda": ("pack", (0.07, 0.11, 0.04), "soda", None, 3),
    "flour": ("bag", (0.13, 0.24, 0.085), "flour", None, 3),
    "sugar": ("bag", (0.105, 0.17, 0.07), "sugar", None, 3),
    "grechka": ("bag", (0.105, 0.18, 0.07), "grechka", None, 3),
    "psheno": ("bag", (0.105, 0.18, 0.07), "psheno", None, 3),
    "butter": ("butter", (0.1, 0.035, 0.065), "butter", None, 2),
    "pelmeni": ("pack", (0.16, 0.045, 0.11), "pelmeni", None, 2),
    "cheese": ("wheel", (0.36, 0.11, 0.36), "cheese", None, 1),
    "sausage": ("sausage", (0.42, 0.075, 0.075), "sausage", None, 2),
    "fish": ("block", (0.38, 0.09, 0.26), "fish", None, 2),
    "chicken": ("chicken", (0.26, 0.1, 0.16), "chicken", None, 2),
    "plombir": ("cup", (0.07, 0.07, 0.07), "plombir", None, 1),
    # Second atlas.
    "baton": ("loaf", (0.32, 0.075, 0.1), "baton", "baton", 2),
    "borodinsky": ("loaf", (0.2, 0.085, 0.1), "borodinsky", "borodinsky", 2),
    "kirpich": ("loaf", (0.22, 0.1, 0.1), "kirpich", "kirpich", 2),
    "bulka": ("loaf", (0.12, 0.06, 0.12), "bulka", "bulka", 2),
    "pryaniki": ("bag", (0.14, 0.18, 0.06), "pryaniki", None, 2),
    "yubileynoe": ("pack", (0.16, 0.055, 0.06), "yubileynoe", None, 2),
    "coffee": ("tin", (0.08, 0.11, 0.08), "coffee", "GOLD", 2),
    "kakao": ("pack", (0.07, 0.11, 0.05), "kakao", None, 2),
    "gerkules": ("pack", (0.12, 0.2, 0.06), "gerkules", None, 3),
    "vermishel": ("bag", (0.12, 0.2, 0.06), "vermishel", None, 3),
    "kisel": ("pack", (0.08, 0.035, 0.03), "kisel", None, 2),
    "lavr": ("pack", (0.06, 0.09, 0.012), "lavr", None, 1),
    "buratino": ("bottle", (0.068, 0.3, 0.068), "buratino", 0, 1, 0.42, False, "crown"),
    "tarhun": ("bottle", (0.068, 0.3, 0.068), "tarhun", 1, 1, 0.42, False, "crown"),
    "mineral": ("bottle", (0.068, 0.3, 0.068), "mineral", 2, 1, 0.42, False, "crown"),
    "eggs": ("eggs", (0.27, 0.075, 0.11), "eggs", None, 1),
    "syrki": ("pack", (0.045, 0.025, 0.09), "syrki", None, 1),
    "tomato_paste": ("jar", (0.075, 0.1, 0.075), "tomato_paste", "GOLD", 2, 0.74),
    "gorchitsa": ("jar", (0.06, 0.09, 0.06), "gorchitsa", "TIN", 1, 0.74),
    "saira": ("tin", (0.084, 0.06, 0.084), "saira", "TIN", 2),
    "turist": ("tin", (0.1, 0.09, 0.1), "turist", "TIN", 3),
    "bychki": ("flat", (0.105, 0.035, 0.105), "bychki", "KILKA", 2),
    "baklazhan": ("jar", (0.084, 0.13, 0.084), "baklazhan", "GOLD", 2, 0.78),
    "soap": ("soap", (0.095, 0.035, 0.06), "soap", None, 1),
    "zubnoy": ("pack", (0.06, 0.09, 0.03), "zubnoy", None, 2),
    "palochki": ("bag", (0.16, 0.26, 0.07), "palochki", None, 2),
    "karamel": ("bag", (0.14, 0.18, 0.05), "karamel", None, 2),
    "yogurt": ("bottle", (0.065, 0.16, 0.065), "yogurt", 3, 1, 0.55, True),
}

LOD_RATIO = {"tin": 0.25, "flat": 0.3, "jar": 0.25, "bottle": 0.25, "smetana": 0.3, "cup": 0.3, "pack": 0.5,
             "bag": 0.2, "tetra": 0.4, "wheel": 0.5, "sausage": 0.3, "block": 0.15, "butter": 0.3,
             "chicken": 0.06, "loaf": 0.15, "eggs": 0.2, "soap": 0.3}


def build(id, spec, variant):
    shape, (w, h, d), cname = spec[0], spec[1], spec[2]
    name = id if variant == 0 else "%s_v%d" % (id, variant)
    if shape == "tin":
        return tin(name, w / 2, h, cname, spec[3], variant)
    if shape == "flat":
        return flat(name, w / 2, h, cname, spec[3], variant)
    if shape == "jar":
        return jar(name, w / 2, h, cname, spec[3], spec[5], variant)
    if shape == "bottle":
        cap = spec[7] if len(spec) > 7 else "foil"
        if cap == "crown":
            cap = spec[3]
            return bottle(name, w / 2, h, cname, None, spec[5], spec[6], variant, cap=cap)
        return bottle(name, w / 2, h, cname, spec[3], spec[5], spec[6], variant)
    if shape == "smetana":
        return smetana(name, w / 2, h, cname, spec[3], variant)
    if shape == "cup":
        return cup(name, w / 2, h, cname, variant)
    if shape == "pack":
        return pack(name, (w, h, d), cname, variant, flap=h > 0.07 and h > w * 0.8)
    if shape == "bag":
        return bag(name, (w, h, d), cname, variant)
    if shape == "tetra":
        return tetra(name, w, cname, variant)
    if shape == "wheel":
        return wheel(name, w / 2, h, cname, variant)
    if shape == "sausage":
        return sausage(name, w, h / 2, cname, variant)
    if shape == "block":
        return frozen_block(name, (w, h, d), cname, variant)
    if shape == "butter":
        return butter(name, (w, h, d), cname, variant)
    if shape == "chicken":
        return chicken(name, (w, h, d), cname, variant)
    if shape == "loaf":
        return loaf(name, (w, h, d), cname, spec[3], variant)
    if shape == "eggs":
        return egg_tray(name, (w, h, d), cname, variant)
    if shape == "soap":
        return soap(name, (w, h, d), cname, variant)
    raise ValueError(shape)


def main():
    reset()
    only = ARGS.get("only")
    objs, lods = [], []
    for id, spec in ITEMS.items():
        if only and id not in only:
            continue
        for v in range(spec[4]):
            o = build(id, spec, v)
            # Fix winding everywhere: closed or not, normals out from the centre.
            bm = bmesh.new()
            bm.from_mesh(o.data)
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            bm.to_mesh(o.data)
            bm.free()
            objs.append(o)
    if not ARGS.get("noao"):
        bake_ao(objs, samples=ARGS.get("samples", 16), distance=0.05, strength=0.8)
    else:
        for o in objs:
            plain_colors(o)
    for o in objs:
        base = o.name.split("_v")[0] if "_v" in o.name else o.name
        shape = ITEMS.get(base, ITEMS.get(o.name, ("pack",)))[0]
        if shape in ("pack", "soap", "butter"):
            spec = ITEMS[base]
            w, h, d = spec[1]
            rect, tex = cell(spec[2])
            m = Mesh()
            rects = {"+y": rect.sub(0, 0.5), "-y": rect.sub(0, 0.5), "+x": rect.sub(0.5, 0.75),
                     "-x": rect.sub(0.5, 0.75), "+z": rect.sub(0.75, 1.0)}
            m.box((0, 0, h / 2), (w, d, h), rects, tex)
            lo = m.to_object(o.name + "_lod1")
            plain_colors(lo)
            lods.append(lo)
        else:
            lods.append(make_lod(o, LOD_RATIO.get(shape, 0.3)))
    for o in objs + lods:
        print("%-22s %6d" % (o.name, tri_count(o)))
    export("goods", objs + lods)
    if ARGS.get("preview"):
        for o in lods:
            o.hide_render = True
        x = 0.0
        for o in objs:
            o.location = (x, 0, 0)
            x += 0.3
        render_preview(ARGS["preview"], objs, (x / 2, -3.5, 1.2), (x / 2, 0, 0.1), lens=24, size=(3000, 900))


main()
