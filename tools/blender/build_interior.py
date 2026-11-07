"""Interior of «Кировский» modelled in Blender: models/kit/interior.glb.

    python3.11 tools/blender/build_interior.py

* booth        the guard's post (Props.booth), in store coordinates: the
               desk with its drawer pedestal, a tube-framed chair with bent
               plywood seat and back, the red rotary telephone with its dial,
               handset, cradle and coiled cord, the «Альпинист» radio, the
               ledger's cover, the desk lamp's base and arm, a thermos, tea
               in a glass in a подстаканник, the enamel kettle, the
               fire extinguisher. (Pages, lamp shade, calendar, keys,
               newspaper and the coat stay in the game's code.)
* fixture      a ceiling strip light (Props.fixture) without its tubes:
               steel housing, angled reflectors, end caps, lamp holders,
               the louvre grid with real blades.
* radiator_10, radiator_12  cast-iron МС-140 radiators (Fittings.radiator)
               with their hubs, nipples and pipes.
* lockers      the left-luggage bank (Store._build_entrance), 12 × 4
               doors, each its own panel with a slice of the numbered
               "locker" texture, coin lock and handle; cell 31 is open.
* locker_door  the open door of cell 31 (on the hinge).
* sack, sack_v1, sack_v2  filled sacks for the back passage.
* trolley      a platform trolley with a handle and four castors.
* mop_bucket   a galvanised bucket with a mop leaning in it.
"""
import os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix, noise
from bkit import *  # noqa

from build_equip import Parts  # noqa: E402  (reuses its part helpers; main() guarded below)


def G(x, y, z):
    """Game coordinates (x right, y up, z back) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def gbox(p, at, size, tint=(1, 1, 1), material="paint", tex_m=0.6, bev=0.004, rot=None):
    """Box like MeshBuilder.box: `at` is the bottom centre in game coords."""
    c = G(at[0], at[1] + size[1] / 2, at[2])
    s = (size[0], size[2], size[1])
    return p.box(tuple(c), s, tint, material, tex_m, bev, rot=rot)


WOOD = (1.0, 1.0, 1.0)
DARK = (0.7, 0.62, 0.55)
RED_PHONE = (0.42, 0.09, 0.07)


# --- the guard's post -------------------------------------------------------------

def booth():
    p = Parts("booth")
    # Desk: top with a rounded edge, the drawer pedestal, legs, modesty panel.
    gbox(p, (11.15, 0.74, 2.1), (1.1, 0.04, 2.6), WOOD, "wood", 0.8, bev=0.01)
    gbox(p, (11.15, 0.0, 1.15), (1.0, 0.74, 0.6), DARK, "wood", 0.8, bev=0.008)
    for i in range(3):
        y = 0.06 + i * 0.23
        gbox(p, (10.64, y, 1.15), (0.02, 0.2, 0.54), (0.78, 0.7, 0.62), "wood", 0.5, bev=0.004)
        gbox(p, (10.625, y + 0.09, 1.15), (0.012, 0.02, 0.12), (1, 1, 1), "chrome", bev=0.004)
        gbox(p, (10.629, y + 0.14, 1.15), (0.004, 0.02, 0.03), (0.75, 0.65, 0.35), "chrome", bev=0)
    for z in (1.5, 3.33):
        for x in (10.65, 11.65):
            # Tapered square legs.
            o = gbox(p, (x, 0.0, z), (0.05, 0.74, 0.05), DARK, "wood", 0.6, bev=0.006)
            for v in o.data.vertices:
                if v.co.z < 0.3:
                    k = 0.75 + 0.25 * v.co.z / 0.3
                    c = G(x, 0, z)
                    v.co.x = c.x + (v.co.x - c.x) * k
                    v.co.y = c.y + (v.co.y - c.y) * k
    gbox(p, (11.65, 0.3, 2.4), (0.03, 0.4, 1.8), DARK, "wood", 0.6, bev=0.004)
    chair(p, 10.2, 2.2)
    phone(p)
    radio(p)
    # Ledger: the hard cover under the pages, rounded spine.
    gbox(p, (10.9, 0.76, 2.6), (0.32, 0.012, 0.46), (0.5, 0.1, 0.07), "leather", 0.3, bev=0.003)
    sp = G(10.9, 0.776, 2.6)
    p.rod(sp + Vector((-0.15, 0, 0)), sp + Vector((0.15, 0, 0)), 0.014, "leather", (0.42, 0.08, 0.06), 10)
    # Desk lamp: weighted base, a jointed arm (the shade stays in the game).
    p.lathe([(0.0, 0.0), (0.085, 0.0), (0.088, 0.008), (0.075, 0.025), (0.03, 0.03), (0.0, 0.03)], "paint", 24,
            (0.55, 0.85, 0.6), xf=Matrix.Translation(G(11.35, 0.76, 3.05)))
    a, b, c = G(11.35, 0.79, 3.05), G(11.38, 1.0, 3.04), G(11.29, 1.12, 3.01)
    p.rod(a, b, 0.008, "chrome")
    p.rod(b, c, 0.007, "chrome")
    p.lathe([(0.0, -0.012), (0.014, -0.012), (0.014, 0.012), (0.0, 0.012)], "chrome", 12,
            xf=Matrix.Translation(b) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
    # Thermos: steel cup screwed on as the lid, a painted body.
    p.lathe([(0.0, 0.0), (0.045, 0.0), (0.05, 0.01), (0.05, 0.22), (0.045, 0.235), (0.04, 0.24), (0.042, 0.245),
             (0.046, 0.25), (0.046, 0.3), (0.0, 0.3)], "paint", 24, (0.6, 0.7, 1.0),
            xf=Matrix.Translation(G(11.45, 0.76, 1.65)))
    p.lathe([(0.0405, 0.245), (0.047, 0.248), (0.047, 0.301), (0.04, 0.302)], "chrome", 24,
            xf=Matrix.Translation(G(11.45, 0.76, 1.65)))
    # Tea glass in a подстаканник with its handle.
    base = G(11.0, 0.76, 1.7)
    p.lathe([(0.0, 0.0), (0.03, 0.0), (0.032, 0.006), (0.028, 0.012), (0.036, 0.06), (0.039, 0.064), (0.036, 0.066),
             (0.035, 0.02)], "chrome", 20, xf=Matrix.Translation(base))
    p.lathe([(0.0, 0.006), (0.033, 0.006), (0.04, 0.1), (0.041, 0.105), (0.0385, 0.105), (0.031, 0.01), (0.0, 0.01)],
            "white#8fa0a066@psx_glass", 20, xf=Matrix.Translation(base))
    p.lathe([(0.0, 0.0), (0.035, 0.0)], "white", 20, (0.32, 0.15, 0.05), xf=Matrix.Translation(base + Vector((0, 0, 0.08))))
    hp = [base + Vector((0.036 + 0.03 * math.sin(t * math.pi), 0, 0.015 + 0.045 * t)) for t in (0, 0.25, 0.5, 0.75, 1)]
    for q0, q1 in zip(hp, hp[1:]):
        p.rod(q0, q1, 0.004, "chrome", sides=6)
    # Kettle: enamel body, spout, a black handle over the top.
    kb = G(11.45, 0.76, 2.75)
    p.lathe([(0.0, 0.0), (0.07, 0.0), (0.078, 0.02), (0.08, 0.1), (0.07, 0.16), (0.05, 0.185), (0.045, 0.19),
             (0.03, 0.2), (0.012, 0.21), (0.0, 0.21)], "enamel", 28, (0.75, 0.82, 0.9), xf=Matrix.Translation(kb))
    sp = [kb + Vector((-0.07, 0, 0.05)), kb + Vector((-0.11, 0, 0.1)), kb + Vector((-0.14, 0, 0.16))]
    p.rod(sp[0], sp[1], 0.016, "enamel", (0.75, 0.82, 0.9), 10)
    p.rod(sp[1], sp[2], 0.011, "enamel", (0.75, 0.82, 0.9), 10)
    hh = [kb + Vector((0.05, 0, 0.17)), kb + Vector((0.07, 0, 0.26)), kb + Vector((0.0, 0, 0.3)),
          kb + Vector((-0.06, 0, 0.26)), kb + Vector((-0.05, 0, 0.17))]
    for q0, q1 in zip(hh, hh[1:]):
        p.rod(q0, q1, 0.01, "rubber", (0.12, 0.12, 0.12), 8)
    # ОХП-10 extinguisher in the corner.
    eb = G(11.6, 0.0, 4.5)
    p.lathe([(0.0, 0.0), (0.07, 0.0), (0.08, 0.01), (0.08, 0.44), (0.07, 0.48), (0.04, 0.5), (0.03, 0.51),
             (0.0, 0.51)], "paint", 28, (0.7, 0.1, 0.07), xf=Matrix.Translation(eb))
    p.lathe([(0.0, 0.5), (0.03, 0.5), (0.03, 0.56), (0.02, 0.58), (0.0, 0.58)], "rubber", 12, (0.15, 0.15, 0.15),
            xf=Matrix.Translation(eb))
    p.rod(eb + Vector((0.0, 0.0, 0.57)), eb + Vector((-0.06, 0.0, 0.62)), 0.008, "chrome")  # the lever
    hose = [eb + Vector((0.03, 0, 0.55)), eb + Vector((0.09, 0, 0.5)), eb + Vector((0.1, 0, 0.35)),
            eb + Vector((0.09, 0, 0.25))]
    for q0, q1 in zip(hose, hose[1:]):
        p.rod(q0, q1, 0.009, "rubber", (0.1, 0.1, 0.1), 8)
    p.lathe([(0.009, 0.0), (0.025, 0.12)], "rubber", 12, (0.1, 0.1, 0.1),
            xf=Matrix.Translation(hose[-1]) @ Matrix.Rotation(math.pi, 4, "X"))
    return p.done()


def chair(p, x, z):
    """A school/office chair: chrome tube frame, bent plywood seat and back."""
    c = G(x, 0, z)
    for ox, oz in ((-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18), (0.18, 0.18)):
        p.rod(G(x + ox, 0.0, z + oz), G(x + ox * 0.95, 0.43, z + oz * 0.95), 0.012)
        p.lathe([(0.0, 0.0), (0.014, 0.0), (0.014, 0.012), (0.0, 0.012)], "rubber", 8, (0.1, 0.1, 0.1),
                xf=Matrix.Translation(G(x + ox, 0.0, z + oz)))
    for oz in (-0.17, 0.17):  # the back's uprights from the rear legs
        p.rod(G(x - 0.17, 0.43, z + oz), G(x - 0.22, 0.92, z + oz), 0.011)
    p.rod(G(x - 0.17, 0.2, z - 0.17), G(x - 0.17, 0.2, z + 0.17), 0.008)
    # Seat: a dished plywood sheet with a rolled front edge.
    rows = []
    for j in range(7):
        u = j / 6
        row = []
        for i in range(7):
            v = i / 6
            xx = x - 0.21 + 0.42 * u
            zz = z - 0.21 + 0.42 * v
            dish = -0.012 * math.sin(math.pi * u) * math.sin(math.pi * v)
            roll = -0.02 * max(0, (u - 0.85) / 0.15) ** 2
            row.append(G(xx, 0.45 + dish + roll, zz))
        rows.append(row)
    p.sheet(rows, "wood", WOOD)
    rows2 = [[q + Vector((0, 0, -0.012)) for q in r] for r in rows[::-1]]
    p.sheet(rows2, "wood", (0.85, 0.75, 0.6))
    # Back: curved plywood.
    rows = []
    for j in range(5):
        h = 0.62 + 0.28 * j / 4
        row = []
        for i in range(7):
            v = i / 6
            zz = z - 0.19 + 0.38 * v
            curve = 0.03 * (1 - (2 * v - 1) ** 2)
            row.append(G(x - 0.2 - 0.05 * j / 4 - curve, h, zz))
        rows.append(row)
    p.sheet(rows, "wood", WOOD)
    p.sheet([[q + Vector((-0.01, 0, 0)) for q in r][::-1] for r in rows], "wood", (0.85, 0.75, 0.6))


def phone(p):
    """The red rotary telephone on the desk: body with a sloped dial face, the
    finger wheel, cradle prongs, the handset (two cups on a curved handle),
    a coiled cord to the body."""
    red = RED_PHONE
    c = G(11.1, 0.76, 1.2)
    # Body: a wedge extruded along the desk's length (game z), rounded hard.
    prof = [(-0.12, 0.0), (0.12, 0.0), (0.115, 0.06), (0.06, 0.12), (-0.07, 0.13), (-0.12, 0.05)]
    pts = [(c.x + px, c.z + pz) for px, pz in prof]
    p.prism(pts, c.y - 0.105, c.y + 0.105, red, "white", 0.3, bev=0.02)
    # Dial: the number plate (dial texture) and the finger wheel over it.
    xf = Matrix.Translation(G(11.03, 0.87, 1.2)) @ Matrix.Rotation(-0.45 - 0.2, 4, "Y")
    m = Mesh()
    m.lathe([(0.062, 0.0), (0.062, 0.006)], Rect(0, 0.45, 1, 0.1), "dial", 24, xf=xf)
    m.disc(0.062, 0.006, Rect(0, 0, 1, 1), "dial", 24, xf=xf)
    o = m.to_object("phone_dial")
    p.objs.append(o)
    p.lathe([(0.05, 0.007), (0.056, 0.009), (0.056, 0.012), (0.048, 0.013), (0.012, 0.013), (0.012, 0.009)],
            "white#ffffff4d@psx_glass", 24, (1, 1, 1), xf=xf)
    p.lathe([(0.0, 0.006), (0.013, 0.006), (0.012, 0.016), (0.0, 0.017)], "chrome", 12, xf=xf)
    # Cradle prongs.
    for dz in (-0.09, 0.09):
        p.rod(G(11.15, 0.87, 1.2 + dz), G(11.15, 0.9, 1.2 + dz * 1.15), 0.009, "white", red, 8)
    # Handset across the cradle: a bowed handle with the ear and mouth cups.
    hs = [G(11.15, 0.905, 1.2 + t) for t in (-0.11, -0.06, 0.0, 0.06, 0.11)]
    hs = [q + Vector((0, 0, 0.012 * (1 - (i / 2 - 1) ** 2))) for i, q in enumerate(hs)]
    for q0, q1 in zip(hs, hs[1:]):
        p.rod(q0, q1, 0.017, "white", red, 10)
    for q, k in ((hs[0], -1), (hs[-1], 1)):
        p.lathe([(0.0, -0.03), (0.022, -0.03), (0.03, -0.012), (0.032, 0.0), (0.0, 0.002)], "white", 16, red,
                xf=Matrix.Translation(q + Vector((0, 0, -0.006))))
    # The coiled cord from the handset down to the side of the body.
    a = hs[0] + Vector((0, 0, -0.03))
    b = G(11.1, 0.78, 1.33)
    prev = None
    n = 90
    for i in range(n + 1):
        t = i / n
        axis = a.lerp(b, t) + Vector((0.03, 0, -0.04)) * math.sin(math.pi * t)
        ang = t * 2 * math.pi * 14
        q = axis + Vector((math.cos(ang) * 0.007, 0, math.sin(ang) * 0.007))
        if prev is not None:
            p.rod(prev, q, 0.0022, "rubber", (0.12, 0.03, 0.02), 4, caps=False)
        prev = q


def radio(p):
    """«Альпинист»: a portable radio in a wood-tone case, grille to the chair."""
    gbox(p, (11.3, 0.76, 2.2), (0.16, 0.2, 0.32), (0.75, 0.55, 0.42), "wood", 0.4, bev=0.015)
    m = Mesh()
    c = G(11.219, 0.855, 2.15)
    m.box(tuple(c), (0.004, 0.2, 0.15), {"-x": Rect(0, 0, 1, 1)}, "grille", (0.9, 0.9, 0.9))
    p.objs.append(m.to_object("radio_grille"))
    gbox(p, (11.219, 0.9, 2.33), (0.006, 0.03, 0.06), (0.9, 0.85, 0.6), "white", bev=0)  # the dial window
    p.lathe([(0.0, 0.0), (0.016, 0.0), (0.017, 0.012), (0.012, 0.018), (0.0, 0.018)], "rubber", 14, (0.12, 0.1, 0.08),
            xf=Matrix.Translation(G(11.222, 0.86, 2.31)) @ Matrix.Rotation(-math.pi / 2, 4, "Y"))
    # The leather carrying strap looping over the top.
    pts = [G(11.3, 0.96, 2.06), G(11.3, 1.03, 2.12), G(11.3, 1.05, 2.2), G(11.3, 1.03, 2.28), G(11.3, 0.96, 2.34)]
    for q0, q1 in zip(pts, pts[1:]):
        p.box(tuple((q0 + q1) / 2), (0.02, (q1 - q0).length + 0.004, 0.004), (0.3, 0.18, 0.1), "leather", 0.3, bev=0,
              rot=("X", math.atan2((q1 - q0).z, -(q1 - q0).y) * -1))


# --- ceiling strip light -------------------------------------------------------------------

def fixture():
    """Props.fixture minus the tubes; origin = `pos` (top of the housing at +0.07)."""
    p = Parts("fixture")
    body = (0.86, 0.87, 0.84)
    gbox(p, (0, 0, 0), (0.3, 0.07, 1.3), body, bev=0.008)
    for sx in (-1, 1):
        gbox(p, (sx * 0.14, -0.06, 0), (0.008, 0.08, 1.28), body, bev=0.002, rot=("Y", sx * 0.5))
    for sz in (-0.635, 0.635):
        gbox(p, (0, -0.08, sz), (0.34, 0.08, 0.03), body, bev=0.006)
        gbox(p, (0, -0.05, sz * 0.97), (0.16, 0.03, 0.02), (0.75, 0.73, 0.68), "white", bev=0.004)
    lv = (0.92, 0.92, 0.9)
    for sx in (-0.165, 0.165):
        gbox(p, (sx, -0.085, 0), (0.01, 0.035, 1.24), lv, bev=0.002)
    k = -0.56
    while k < 0.57:
        # Cross blades, each a thin V so the light shows its edge.
        gbox(p, (0, -0.085, k), (0.33, 0.035, 0.004), lv, bev=0, rot=("X", 0.0))
        gbox(p, (0, -0.052, k), (0.33, 0.003, 0.012), lv, bev=0)
        k += 0.08
    gbox(p, (0, -0.085, 0), (0.004, 0.035, 1.24), lv, bev=0)
    return p.done()


# --- radiators ------------------------------------------------------------------------

def radiator(sections):
    """Frame of Fittings.radiator: x along the wall, -y (Blender) out of it, z up."""
    p = Parts("radiator_%d" % sections)
    col = (0.82, 0.8, 0.72)
    pitch = 0.09
    w = sections * pitch
    for i in range(sections):
        cx = -w / 2 + pitch * (i + 0.5)
        # Two columns per section, rounded top and bottom, the fin between.
        for dy in (-0.035, 0.035):
            p.lathe([(0.0, 0.17), (0.02, 0.175), (0.028, 0.2), (0.03, 0.25), (0.03, 0.6), (0.028, 0.64), (0.02, 0.665),
                     (0.0, 0.67)], "paint", 12, col, xf=Matrix.Translation((cx, -0.12 + dy, 0)) @ Matrix.Scale(1.0, 4))
        p.box((cx, -0.12, 0.42), (0.012, 0.13, 0.36), col, bev=0.004)
        p.box((cx, -0.195, 0.42), (0.07, 0.02, 0.36), col, bev=0.008)
    # Hubs and the nipples between sections, top and bottom.
    for zz in (0.2, 0.62):
        p.rod((-w / 2 - 0.02, -0.12, zz), (w / 2 + 0.02, -0.12, zz), 0.024, "paint", col, 12)
        p.lathe([(0.0, -0.01), (0.032, -0.01), (0.032, 0.01), (0.0, 0.01)], "paint", 12, col,
                xf=Matrix.Translation((-w / 2 - 0.02, -0.12, zz)) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
        p.lathe([(0.0, -0.01), (0.032, -0.01), (0.032, 0.01), (0.0, 0.01)], "paint", 12, col,
                xf=Matrix.Translation((w / 2 + 0.02, -0.12, zz)) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
    pc = tuple(c * 0.92 for c in col)
    for side in (-1, 1):
        px = side * (w / 2 + 0.1)
        hub = 0.62 if side < 0 else 0.2
        p.rod((px, -0.12, 0.0), (px, -0.12, hub), 0.016, "paint", pc, 10)
        p.rod((px, -0.12, hub), (side * (w / 2 + 0.02), -0.12, hub), 0.016, "paint", pc, 10)
        p.lathe([(0.0, -0.02), (0.022, -0.02), (0.022, 0.02), (0.0, 0.02)], "paint", 10, pc,
                xf=Matrix.Translation((px, -0.12, hub)))  # elbow
        if side < 0:  # the valve with its wheel
            p.lathe([(0.0, 0.0), (0.03, 0.0), (0.03, 0.008), (0.0, 0.008)], "paint", 12, (0.3, 0.08, 0.06),
                    xf=Matrix.Translation((px, -0.12, hub + 0.06)))
            p.rod((px, -0.12, hub + 0.02), (px, -0.12, hub + 0.06), 0.006, "chrome")
    return p.done()


# --- left-luggage lockers ----------------------------------------------------------------

def lockers():
    """Store._build_entrance: the bank spans x -11..-5, y 0.1..2.1, z 0.05..0.55
    (game); front at z 0.55. Doors 0.5 × 0.5, number 1 top left."""
    p = Parts("lockers")
    frame = (0.42, 0.48, 0.43)
    gbox(p, (-8, 0.1, 0.3), (6, 2.0, 0.48), frame, bev=0.01)
    gbox(p, (-8, 0, 0.32), (5.96, 0.1, 0.46), (0.12, 0.12, 0.12), "rubber", bev=0.006)
    gbox(p, (-8, 2.1, 0.3), (6.1, 0.08, 0.56), (0.35, 0.4, 0.36), bev=0.01)
    for row in range(4):
        for colm in range(12):
            n = row * 12 + colm + 1
            x0 = -11 + colm * 0.5
            y1 = 2.1 - row * 0.5
            cx, cy = x0 + 0.25, y1 - 0.25
            if n == 31:
                # Open cell: a dark box going in.
                gbox(p, (cx, cy - 0.23, 0.31), (0.46, 0.46, 0.46), (0.05, 0.05, 0.05), "paint", bev=0)
                continue
            # The door: its slice of the locker texture on the front.
            m = Mesh()
            r = Rect((x0 + 0.01 + 11) / 6, (2.1 - y1 + 0.01) / 2, 0.48 / 6, 0.48 / 2)
            c = G(cx, cy, 0.553)
            m.box(tuple(c), (0.48, 0.012, 0.48), {"-y": r}, "locker")
            m.box(tuple(c), (0.48, 0.012, 0.48), {"+x": Rect(0, 0, 0.01, 0.01), "-x": Rect(0, 0, 0.01, 0.01),
                                                  "+z": Rect(0, 0, 0.01, 0.01), "-z": Rect(0, 0, 0.01, 0.01)}, "locker",
                  (0.7, 0.7, 0.7))
            o = m.to_object("locker_%d" % n)
            bevel(o, 0.003, 1, 30)
            p.objs.append(o)
            # Coin lock and the handle.
            p.lathe([(0.0, 0.0), (0.016, 0.0), (0.016, 0.01), (0.012, 0.014), (0.0, 0.014)], "chrome", 14,
                    xf=Matrix.Translation(G(x0 + 0.42, cy + 0.05, 0.559)) @ Matrix.Rotation(math.pi / 2, 4, "X"))
            p.box(tuple(G(x0 + 0.42, cy - 0.06, 0.567)), (0.014, 0.014, 0.07), (1, 1, 1), "chrome", bev=0.004)
    return p.done()


def locker_door():
    """The open door of cell 31, in its hinge frame (hinge at the left edge)."""
    p = Parts("locker_door")
    frame = (0.42, 0.48, 0.43)
    gbox(p, (0.24, 0, 0), (0.47, 0.47, 0.03), frame, bev=0.004)
    for k in range(3):
        gbox(p, (0.24, 0.3 + k * 0.05, 0.016), (0.3, 0.012, 0.004), (0.1, 0.1, 0.1), "rubber", bev=0)
    p.lathe([(0.0, 0.0), (0.016, 0.0), (0.016, 0.01), (0.0, 0.012)], "chrome", 14,
            xf=Matrix.Translation(G(0.42, 0.3, 0.016)) @ Matrix.Rotation(math.pi / 2, 4, "X"))
    return p.done()


# --- back passage clutter -------------------------------------------------------------------

def sack(name, seed):
    """A filled sack 0.5 × 0.18 × 0.85 (game x, y, z) lying flat: a pillow of
    cloth with the tied neck at one end."""
    m = Mesh()
    w, h, d = 0.5, 0.18, 0.85
    nu, nv = 10, 16
    rnd = random.Random(seed)
    for top in (True, False):
        rows, uvs = [], []
        for j in range(nv + 1):
            v = j / nv
            row, urow = [], []
            for i in range(nu + 1):
                u = i / nu
                x = (u - 0.5) * w
                y = (v - 0.5) * d
                puff = math.sin(math.pi * u) ** 0.6 * math.sin(math.pi * v) ** 0.5
                zz = h / 2 + (h / 2 if top else -h / 2) * puff
                row.append(Vector((x, y, zz)))
                urow.append((u * w / 0.6, v * d / 0.6))
            rows.append(row)
            uvs.append(urow)
        if not top:
            rows = [r[::-1] for r in rows]
            uvs = [r[::-1] for r in uvs]
        m.grid(rows, uvs, "cloth", (1.0, 0.95, 0.8))
    o = m.to_object(name)
    off = Vector((seed * 1.3, seed * 0.7, 0))
    displace(o, lambda co: noise.noise_vector(co * 9 + off) * 0.012)
    smooth_by_angle(o, 70)
    return o


def trolley():
    p = Parts("trolley")
    gbox(p, (0, 0.12, 0), (0.6, 0.03, 0.9), (0.6, 0.62, 0.62), "metal", 0.5, bev=0.006)
    for sx in (-0.28, 0.28):  # handle frame at the back
        p.rod(G(sx, 0.15, 0.44), G(sx, 1.0, 0.46), 0.012)
    p.rod(G(-0.28, 1.0, 0.46), G(0.28, 1.0, 0.46), 0.014)
    p.rod(G(-0.28, 0.6, 0.45), G(0.28, 0.6, 0.45), 0.009)
    for ox, oz in ((-0.25, -0.38), (0.25, -0.38), (-0.25, 0.38), (0.25, 0.38)):
        hub = G(ox + 0.02, 0.05, oz)
        p.lathe([(0.0, -0.02), (0.04, -0.02), (0.05, -0.012), (0.05, 0.012), (0.04, 0.02), (0.0, 0.02)], "rubber", 16,
                (0.1, 0.1, 0.1), xf=Matrix.Translation(hub) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
        p.box(tuple(G(ox + 0.02, 0.07, oz)), (0.05, 0.03, 0.06), (0.5, 0.5, 0.5), "metal", 0.3, bev=0.004)
    return p.done()


def mop_bucket():
    p = Parts("mop_bucket")
    p.lathe([(0.0, 0.0), (0.15, 0.0), (0.152, 0.01), (0.18, 0.29), (0.185, 0.3), (0.175, 0.3), (0.145, 0.02),
             (0.0, 0.02)], "galv", 24, (0.7, 0.72, 0.75))
    for k in range(3):  # pressed rings
        z = 0.08 + k * 0.08
        r = 0.15 + 0.03 * z / 0.3 + 0.002
        p.lathe([(r, z - 0.006), (r + 0.003, z), (r, z + 0.006)], "galv", 24, (0.68, 0.7, 0.72))
    pts = [Vector((math.cos(a) * 0.19, math.sin(a) * 0.19, 0.3 + 0.12 * math.sin(a / 2 + 0.0) ** 2))
           for a in [0.0 + k * math.pi / 8 for k in range(9)]]
    for q0, q1 in zip(pts, pts[1:]):
        p.rod(q0, q1, 0.004, "galv", (0.7, 0.7, 0.7), 6)
    # The mop: a wooden handle leaning in, a grey rag at its foot.
    p.rod(G(0.0, 0.05, 0.0), G(-0.25, 1.3, 0.0), 0.014, "wood", (1.0, 0.9, 0.7), 8)
    o = sack("mop_rag", 4)
    o.scale = (0.36, 0.2, 0.8)
    o.location = (0.0, 0.0, 0.1)
    p.objs.append(o)
    return p.done()


def main():
    reset()
    objs = [booth(), fixture(), radiator(10), radiator(12), lockers(), locker_door(), trolley(), mop_bucket()]
    for i in range(3):
        objs.append(sack("sack" if i == 0 else "sack_v%d" % i, 11 + i * 5))
    for o in objs:
        o.location = (0, 0, 0)
    if not ARGS.get("noao"):
        bake_ao(objs, samples=ARGS.get("samples", 16), distance=0.15, strength=0.75)
    else:
        for o in objs:
            plain_colors(o)
    for o in objs:
        print("%-20s %7d" % (o.name, tri_count(o)))
    export("interior", objs)


if __name__ == "__main__":
    main()
