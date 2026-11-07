"""Shop equipment of «Кировский» modelled in Blender: models/kit/equip.glb.

    python3.11 tools/blender/build_equip.py

After the Ленторгмаш and Торгмаш catalogues of the 1980s:

* dairy_3250  open multi-deck dairy case (Cases.dairy_case): enamelled tub
              with a rounded edge and a chrome bumper, a louvred plinth,
              curved end panels, three stepped shelves on brackets with
              red price rails, the canopy (its strip light and the
              «МОЛОКО» card stay in the game, they change at night).
* frozen_3250 low-temperature counter (Cases.frozen_counter): enamel body,
              blue band and maker's plate, chrome frame, the front glass
              bent in one smooth curve, the flat top glass.
* chest       freezer chest with rounded corners (Props.chest): the tub,
              the inner well, chrome rim with corner pieces, two sliding
              glass lids in frames, louvres, a badge.
* checkout    the till cabin (Equip.checkout) without the register and the
              lit «КАССА» faces: cabinet with inset panels, laminate top
              with chrome edging, basket rail, bagging shelf, the drawer,
              the pole and the sign box, a swivel chair, a coin dish, a
              spare tape roll, a cup.
* abacus      wooden счёты with round beads on wires.
* bottle_crate galvanised wire crate for milk bottles, real wires.
* carton_fish/milk/tins (+_v1) printed cartons with flaps and tape.
* pallet      a used wooden pallet.
* basket      a red-coated wire shopping basket with two handles.

Frames match the procedural code they replace (see each function).
"""
import os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
from bkit import *  # noqa

ENAMEL = (0.86, 0.87, 0.83)
INSIDE = (0.62, 0.7, 0.74)
RED = (0.75, 0.2, 0.15)
CABIN = (0.66, 0.68, 0.66)
TOP = (0.92, 0.88, 0.78)
GLASS_COUNTER = "white#b8dbe64d@psx_glass"
GLASS_CHEST = "white#b3d9f233@psx_glass"

EQUIP_CELLS = [
    "kassa1", "kassa2", "kassa3", "dial",
    "reg_front", "reg_keys", "reg_side", "reg_top",
    "hours", "complaints", "prices", "carton_fish",
    "carton_milk", "carton_tins", "receipt", "bottle_crate",
]


def ecell(name):
    return grid_cell(EQUIP_CELLS.index(name), 4, 4)


class Parts:
    def __init__(self, name):
        self.name = name
        self.objs = []

    def box(self, c, s, tint=(1, 1, 1), material="paint", tex_m=0.6, bev=0.003, faces=None, segs=None, rot=None):
        m = Mesh()
        if rot is not None:  # (axis, angle) about the box centre
            m.box_m((0, 0, 0), s, material, tex_m, tint, faces,
                    xf=Matrix.Translation(c) @ Matrix.Rotation(rot[1], 4, rot[0]))
        else:
            m.box_m(c, s, material, tex_m, tint, faces)
        o = m.to_object("%s_p%d" % (self.name, len(self.objs)))
        if bev > 0 and faces is None:
            bevel(o, min(bev, min(s) * 0.45), segs or (1 if bev < 0.004 else 2), 30)
        self.objs.append(o)
        return o

    def rbox(self, c, s, rect, material, tint=(1, 1, 1), bev=0.003):
        m = Mesh()
        m.box(c, s, rect, material, tint)
        o = m.to_object("%s_p%d" % (self.name, len(self.objs)))
        if bev > 0:
            bevel(o, bev, 2, 30)
        self.objs.append(o)
        return o

    def rod(self, a, b, r, material="chrome", tint=(1, 1, 1), sides=8, caps=True):
        a, b = Vector(a), Vector(b)
        d = b - a
        L = d.length
        if L < 1e-5:
            return None
        m = Mesh()
        rot = d.to_track_quat("Z", "Y").to_matrix().to_4x4()
        xf = Matrix.Translation(a) @ rot
        rect = Rect(0, 0, 1, 1)
        m.lathe([(r, 0), (r, L)], rect, material, sides, tint, xf=xf)
        if caps:
            m.disc(r, L, rect, material, sides, tint, xf=xf)
            m.disc(r, 0, rect, material, sides, tint, up=False, xf=xf)
        o = m.to_object("%s_r%d" % (self.name, len(self.objs)))
        for f in o.data.polygons:
            f.use_smooth = True
        self.objs.append(o)
        return o

    def lathe(self, prof, material, segs=20, tint=(1, 1, 1), xf=None, cap_top=None, cap_bottom=None):
        m = Mesh()
        rect = Rect(0, 0, 1, 1)
        m.lathe(prof, rect, material, segs, tint, xf=xf)
        if cap_top is not None:
            m.disc(prof[-1][0], prof[-1][1], rect, material, segs, tint, xf=xf)
        if cap_bottom is not None:
            m.disc(prof[0][0], prof[0][1], rect, material, segs, tint, up=False, xf=xf)
        o = m.to_object("%s_l%d" % (self.name, len(self.objs)))
        smooth_by_angle(o, 40)
        self.objs.append(o)
        return o

    def prism(self, pts, y0, y1, tint=(1, 1, 1), material="paint", tex_m=0.6, bev=0.006):
        """Extrudes a polygon given in the (x, z) plane from y0 to y1."""
        bm = bmesh.new()
        uvl = bm.loops.layers.uv.new("UVMap")
        coll = bm.loops.layers.float_color.new("Tint")
        a = [bm.verts.new((x, y0, z)) for x, z in pts]
        b = [bm.verts.new((x, y1, z)) for x, z in pts]
        faces = [bm.faces.new(a[::-1]), bm.faces.new(b)]
        n = len(pts)
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new([a[i], a[j], b[j], b[i]]))
        for f in faces:
            for l in f.loops:
                co = l.vert.co
                if abs(f.normal.y) > 0.5:
                    l[uvl].uv = (co.x / tex_m, co.z / tex_m)
                else:
                    l[uvl].uv = (co.y / tex_m, (co.x + co.z) / tex_m)
                l[coll] = (*tint, 1)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(self.name + "_pr")
        bm.to_mesh(me)
        bm.free()
        me.materials.append(mat(material))
        o = bpy.data.objects.new("%s_pr%d" % (self.name, len(self.objs)), me)
        link(o)
        if bev > 0:
            bevel(o, bev, 2, 30)
        self.objs.append(o)
        return o

    def sheet(self, rows, material, tint=(1, 1, 1), uv_m=1.0):
        m = Mesh()
        uvs = [[(i / max(1, len(r) - 1), j / max(1, len(rows) - 1)) for i in range(len(r))] for j, r in enumerate(rows)]
        m.grid(rows, uvs, material, tint)
        o = m.to_object("%s_s%d" % (self.name, len(self.objs)))
        self.objs.append(o)
        return o

    def done(self):
        return join(self.objs, self.name)


def louvres(p, x, y0, y1, z0, z1, n, dx=1.0, tint=(0.35, 0.36, 0.36)):
    """Ventilation louvres on a face at x (normal +x * dx): angled slats over a dark recess."""
    p.box((x - dx * 0.006, (y0 + y1) / 2, (z0 + z1) / 2), (0.004, y1 - y0, z1 - z0), (0.08, 0.08, 0.08), bev=0)
    for i in range(n):
        z = z0 + (z1 - z0) * (i + 0.5) / n
        p.box((x, (y0 + y1) / 2, z), (0.004, y1 - y0, (z1 - z0) / n * 0.75), tint, bev=0,
              rot=("Y", math.radians(-35) * dx))
    return


def rounded_rect(w, d, r, n=4):
    """Points of a rounded rectangle in the (x, y) plane, CCW."""
    pts = []
    for cx, cy, a0 in ((w / 2 - r, d / 2 - r, 0), (-w / 2 + r, d / 2 - r, 90), (-w / 2 + r, -d / 2 + r, 180),
                       (w / 2 - r, -d / 2 + r, 270)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def ring_wall(p, outer, inner, z0, z1, material, tint, name="w"):
    """A wall between two closed outlines (same point count), z0..z1, with
    top and bottom faces: the sides of a tub, a rim."""
    m = Mesh()
    n = len(outer)
    rows_o = [[Vector((x, y, z0)) for x, y in outer] + [Vector((outer[0][0], outer[0][1], z0))],
              [Vector((x, y, z1)) for x, y in outer] + [Vector((outer[0][0], outer[0][1], z1))]]
    rows_i = [[Vector((x, y, z1)) for x, y in inner] + [Vector((inner[0][0], inner[0][1], z1))],
              [Vector((x, y, z0)) for x, y in inner] + [Vector((inner[0][0], inner[0][1], z0))]]

    def uvrow(pts, z):
        out, acc = [], 0.0
        for i, q in enumerate(pts):
            if i:
                acc += (q - pts[i - 1]).length
            out.append((acc / 0.6, z / 0.6))
        return out
    m.grid(rows_o, [uvrow(r, r[0].z) for r in rows_o], material, tint, smooth=True)
    m.grid(rows_i, [uvrow(r, r[0].z) for r in rows_i], material, tint, smooth=True)
    top = [rows_o[1], rows_i[0]]
    m.grid(top, [uvrow(r, 0) for r in top], material, tint, smooth=False)
    bot = [rows_i[1], rows_o[0]]
    m.grid(bot, [uvrow(r, 0) for r in bot], material, tint, smooth=False)
    o = m.to_object("%s_%s%d" % (p.name, name, len(p.objs)))
    smooth_by_angle(o, 50)
    p.objs.append(o)
    return o


# --- the dairy case -----------------------------------------------------------------

def dairy(L):
    """Frame of Cases.dairy_case: x out of the wall into the aisle, y along
    the wall (= -z of the game frame), z up."""
    p = Parts("dairy_%d" % round(L * 1000))
    p.box((0.02, 0, 0.05), (0.74, L - 0.02, 0.1), (0.12, 0.12, 0.12), "rubber", bev=0.004)
    p.box((0.0, 0, 0.35), (0.8, L, 0.5), ENAMEL, bev=0.02)
    louvres(p, 0.402, -L / 2 + 0.1, L / 2 - 0.1, 0.14, 0.3, 6)
    p.box((0.37, 0, 0.64), (0.06, L, 0.08), ENAMEL, bev=0.025)
    p.box((0.405, 0, 0.675), (0.025, L, 0.03), (1, 1, 1), "chrome", bev=0.01)
    # Back: the inner wall with the perforated air return low down, the outer case.
    p.box((-0.36, 0, 1.35), (0.08, L - 0.06, 1.5), INSIDE, bev=0.01)
    p.box((-0.3195, 0, 0.66), (0.002, L - 0.12, 0.1), (0.9, 0.9, 0.9), "pegboard", 0.5, bev=0)
    p.box((-0.33, 0, 1.125), (0.14, L, 2.25), ENAMEL, bev=0.015)
    # Canopy with a rounded nose; the red fascia band under the card.
    p.box((-0.05, 0, 2.15), (0.62, L, 0.2), ENAMEL, bev=0.04)
    p.box((0.265, 0, 2.15), (0.012, L - 0.04, 0.18), (0.55, 0.12, 0.1), bev=0.003)
    # End panels: the curved profile of the cabinet's side.
    prof = [(-0.4, 0.0), (0.4, 0.0), (0.4, 0.62), (0.36, 0.7), (0.2, 1.05), (0.06, 1.45), (0.0, 1.8),
            (0.04, 1.95), (0.27, 2.05), (0.27, 2.25), (-0.4, 2.25)]
    for e in (-1, 1):
        y = e * (L / 2 - 0.015)
        p.prism(prof, y - 0.015, y + 0.015, ENAMEL, bev=0.01)
    # Tub floor, shelves with their rails and brackets.
    p.box((0.0, 0, 0.51), (0.66, L - 0.06, 0.02), INSIDE, bev=0.003)
    for y, d in ((0.98, 0.5), (1.36, 0.42), (1.72, 0.36)):
        cx = -0.32 + d / 2
        p.box((cx, 0, y + 0.01), (d, L - 0.06, 0.02), INSIDE, bev=0.004)
        p.box((cx + d / 2, 0, y - 0.005), (0.012, L - 0.06, 0.05), RED, bev=0.003)
        nb = max(2, round(L / 1.0)) + 1
        for i in range(nb):
            yy = -L / 2 + 0.06 + (L - 0.12) * i / (nb - 1)
            p.prism([(-0.32, y), (-0.32 + d - 0.04, y), (-0.32, y - 0.12)], yy - 0.003, yy + 0.003, (0.5, 0.55, 0.58),
                    bev=0)
    return p.done()


# --- the low-temperature counter ---------------------------------------------------------

def frozen(L):
    p = Parts("frozen_%d" % round(L * 1000))
    p.box((0, 0, 0.05), (0.8, L - 0.02, 0.1), (0.12, 0.12, 0.12), "rubber", bev=0.004)
    p.box((0, 0, 0.41), (0.86, L, 0.62), ENAMEL, bev=0.03)
    louvres(p, 0.432, -L / 2 + 0.15, L / 2 - 0.15, 0.14, 0.28, 5)
    p.box((0.4325, 0, 0.54), (0.004, L - 0.02, 0.08), (0.2, 0.3, 0.5), bev=0)
    p.box((0.434, L * 0.35, 0.645), (0.006, 0.18, 0.05), (1, 1, 1), "chrome", bev=0.002)
    p.box((0, 0, 0.61), (0.78, L - 0.08, 0.02), INSIDE, bev=0)
    # Chrome frame: curved uprights, back posts, rails.
    g = [(0.43, 0.72), (0.415, 0.86), (0.385, 0.98), (0.34, 1.09), (0.27, 1.17), (0.18, 1.22)]
    for e in (-L / 2 + 0.02, 0.0, L / 2 - 0.02):
        for a, b in zip(g, g[1:]):
            p.rod((a[0], e, a[1]), (b[0], e, b[1]), 0.011, caps=False)
        p.rod((0.18, e, 1.22), (-0.4, e, 1.22), 0.008)
        p.rod((-0.4, e, 0.72), (-0.4, e, 1.22), 0.011)
    p.rod((0.43, -L / 2, 0.7), (0.43, L / 2, 0.7), 0.016)
    p.rod((0.18, -L / 2, 1.215), (0.18, L / 2, 1.215), 0.011)
    p.rod((-0.4, -L / 2, 1.215), (-0.4, L / 2, 1.215), 0.011)
    # Glass: the front in one curve, the top flat.
    rows = []
    for (x, z) in g:
        rows.append([Vector((x - 0.006, yy, z)) for yy in (L / 2 - 0.03, -L / 2 + 0.03)])
    p.sheet(rows, GLASS_COUNTER)
    p.sheet([[Vector((0.18, yy, 1.226)) for yy in (L / 2 - 0.03, -L / 2 + 0.03)],
             [Vector((-0.39, yy, 1.226)) for yy in (L / 2 - 0.03, -L / 2 + 0.03)]], GLASS_COUNTER)
    return p.done()


# --- the freezer chest ---------------------------------------------------------------------

def chest():
    """Props.chest: 1.0 × 2.4 (x × y), rim at 0.72-0.755, well floor 0.44."""
    p = Parts("chest")
    W, D = 1.0, 2.4
    outer = rounded_rect(W, D, 0.07, 4)
    inner = rounded_rect(W - 0.1, D - 0.1, 0.04, 4)
    ring_wall(p, outer, inner, 0.06, 0.72, "enamel", (1, 1, 1))
    # Lower body (the tub under the well), plinth recessed.
    m = Mesh()
    p.box((0, 0, 0.25), (W - 0.12, D - 0.12, 0.4), (1, 1, 1), "enamel", 1.2, bev=0)
    p.box((0, 0, 0.03), (0.94, 2.34, 0.06), (0.1, 0.1, 0.1), "rubber", bev=0.01)
    # Liner and the galvanised floor of the well.
    ring_wall(p, inner, rounded_rect(W - 0.13, D - 0.13, 0.03, 4), 0.44, 0.715, "enamel", (0.85, 0.88, 0.9))
    p.box((0, 0, 0.44), (0.88, 2.28, 0.01), (0.7, 0.72, 0.74), "galv", 1.0, bev=0)
    # Chrome rim, the middle bar, corner caps.
    ring_wall(p, rounded_rect(W + 0.02, D + 0.02, 0.08, 4), rounded_rect(W - 0.06, D - 0.06, 0.05, 4), 0.72, 0.755,
              "chrome", (1, 1, 1), "rim")
    p.box((0, 0, 0.737), (0.92, 0.03, 0.03), (1, 1, 1), "chrome", bev=0.008)
    # Two sliding lids in thin frames, one riding above the other.
    for yc, z in ((-0.6, 0.745), (0.6, 0.762)):
        p.box((0, -yc, z), (0.94, 1.18, 0.005), (1, 1, 1), GLASS_CHEST, bev=0)
        for sx in (-1, 1):
            p.box((sx * 0.468, -yc, z + 0.004), (0.012, 1.18, 0.014), (1, 1, 1), "chrome", bev=0.003)
        for sy in (-1, 1):
            p.box((0, -yc + sy * 0.584, z + 0.004), (0.94, 0.014, 0.016), (1, 1, 1), "chrome", bev=0.003)
        p.box((0.3, -yc + 0.5, z + 0.012), (0.12, 0.03, 0.012), (0.15, 0.15, 0.15), "rubber", bev=0.004)
    for sx in (-1, 1):
        louvres(p, sx * 0.504, -0.35 - 0.35, 0.35 - 0.35, 0.08, 0.22, 4, dx=sx)
    p.box((0, -1.205, 0.6), (0.16, 0.004, 0.05), (1, 1, 1), "chrome", bev=0.001)
    return p.done()


# --- the checkout -------------------------------------------------------------------------

def checkout():
    """Equip.checkout, everything but the register, the abacus and the lit
    faces of the «КАССА» box. Game z -> -y here."""
    p = Parts("checkout")
    Y = lambda z: -z
    p.box((0, Y(0.15), 0.08 + 0.385), (0.7, 2.2, 0.77), CABIN, bev=0.012)
    p.box((0, Y(0.15), 0.04), (0.66, 2.16, 0.08), (0.1, 0.1, 0.1), "rubber", bev=0.006)
    for z in (-0.6, 0.15, 0.9):  # inset panels on the customer's side with a seam round each
        p.box((-0.351, Y(z), 0.46), (0.004, 0.66, 0.6), tuple(c * 0.82 for c in CABIN), bev=0)
        p.box((-0.353, Y(z), 0.46), (0.002, 0.62, 0.56), tuple(c * 0.9 for c in CABIN), bev=0)
    p.box((0, Y(0.15), 0.865), (0.8, 2.3, 0.03), TOP, "formica", 0.5, bev=0.006)
    for sx in (-1, 1):
        p.box((sx * 0.41, Y(0.15), 0.8625), (0.02, 2.3, 0.045), (1, 1, 1), "chrome", bev=0.006)
    p.rod((-0.45, Y(-0.55), 0.9125), (-0.45, Y(1.15), 0.9125), 0.0125)
    for z in (-0.5, 0.45, 1.12):
        p.rod((-0.45, Y(z), 0.86), (-0.45, Y(z), 0.905), 0.009)
    # Register stand and the drawer.
    p.box((0.15, Y(-0.3), 0.87), (0.5, 0.5, 0.04), CABIN, bev=0.008)
    p.box((0.3, Y(-0.3), 0.7), (0.4, 0.42, 0.16), (0.75, 0.6, 0.45), "wood", 0.5, bev=0.008)
    p.box((0.505, Y(-0.3), 0.7), (0.012, 0.14, 0.025), (1, 1, 1), "chrome", bev=0.004)
    # Bagging end.
    p.box((0, Y(1.45), 0.715), (0.8, 0.5, 0.03), TOP, "formica", 0.5, bev=0.006)
    p.box((0, Y(1.69), 0.75), (0.8, 0.015, 0.04), (1, 1, 1), "chrome", bev=0.004)
    for x, z in ((-0.38, 1.68), (0.38, 1.68)):
        p.rod((x, Y(z), 0), (x, Y(z), 0.7), 0.015)
    # Coin dish, spare tape roll, a cup.
    p.lathe([(0.0, 0.0), (0.09, 0.0), (0.105, 0.012), (0.11, 0.016), (0.1, 0.016), (0.085, 0.005), (0.0, 0.005)],
            "chrome", 24, xf=Matrix.Translation((0.0, Y(-0.05), 0.88)))
    p.lathe([(0.012, 0.0), (0.035, 0.0), (0.035, 0.06), (0.012, 0.06)], "white", 20, (0.95, 0.94, 0.88),
            xf=Matrix.Translation((0.32, Y(0.0), 0.885)) @ Matrix.Rotation(math.pi / 2, 4, "Y") @
            Matrix.Translation((0, 0, -0.03)))
    p.lathe([(0.0, 0.0), (0.038, 0.0), (0.04, 0.005), (0.045, 0.085), (0.047, 0.09), (0.042, 0.09), (0.04, 0.012),
             (0.0, 0.012)], "enamel", 24, xf=Matrix.Translation((0.3, Y(0.8), 0.88)))
    p.rod((0.3 + 0.045, Y(0.8), 0.86 + 0.07), (0.3 + 0.07, Y(0.8), 0.86 + 0.05), 0.006, "enamel")
    # The pole and the box of the «КАССА» sign.
    p.rod((0.42, Y(-0.85), 0.86), (0.42, Y(-0.85), 2.29), 0.018)
    p.box((0.42, Y(-0.85), 2.45), (0.14, 0.66, 0.34), (0.3, 0.3, 0.3), bev=0.01)
    # The cashier's swivel chair: five-star base, gas column, seat and back.
    cx, cy = 0.85, Y(-0.5)
    for k in range(5):
        a = k * 2 * math.pi / 5 + 0.3
        tip = (cx + math.cos(a) * 0.26, cy + math.sin(a) * 0.26, 0.04)
        p.rod((cx, cy, 0.07), tip, 0.014)
        p.lathe([(0.0, 0.0), (0.022, 0.005), (0.025, 0.02), (0.0, 0.035)], "rubber", 10, (0.1, 0.1, 0.1),
                xf=Matrix.Translation((tip[0], tip[1], 0.0)))
    p.rod((cx, cy, 0.06), (cx, cy, 0.5), 0.022)
    p.lathe([(0.0, 0.0), (0.18, 0.0), (0.2, 0.015), (0.205, 0.04), (0.19, 0.06), (0.1, 0.065), (0.0, 0.065)],
            "leather", 24, (1, 1, 1), xf=Matrix.Translation((cx, cy, 0.5)))
    p.rod((cx + 0.17, cy, 0.52), (cx + 0.2, cy, 0.62), 0.012)
    back = p.box((cx + 0.215, cy, 0.76), (0.04, 0.36, 0.3), (1, 1, 1), "leather", 0.6, bev=0.015)
    return p.done()


def abacus():
    """счёты, 0.2 × 0.27, lying flat, top at about 0.02."""
    p = Parts("abacus")
    wood = (0.8, 0.55, 0.35)
    for sy in (-1, 1):
        p.box((0, sy * 0.13, 0.01), (0.2, 0.015, 0.02), wood, "wood", 0.3, bev=0.003)
    for sx in (-1, 1):
        p.box((sx * 0.1, 0, 0.01), (0.015, 0.27, 0.02), wood, "wood", 0.3, bev=0.003)
    for k in range(10):
        y = -0.115 + k * 0.0255
        p.rod((-0.095, y, 0.012), (0.095, y, 0.012), 0.0012, sides=4, caps=False)
        pushed = (k * 7) % 5
        for b in range(10):
            x = -0.085 + b * 0.012 + (0.06 if b >= 10 - pushed else 0.0)
            tint = (0.2, 0.12, 0.08) if b in (4, 5) else (0.45, 0.25, 0.15)
            p.lathe([(0.0015, -0.007), (0.007, -0.004), (0.008, 0.0), (0.007, 0.004), (0.0015, 0.007)], "wood", 6, tint,
                    xf=Matrix.Translation((x, y, 0.012)) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
    return p.done()


# --- crates, cartons, pallets, baskets -----------------------------------------------------------

def wire_box(p, w, d, h, r, pitch, material, tint=(1, 1, 1), taper=0.0, bands=(0.0, 0.5, 1.0), floor=True):
    """A crate of wire: verticals every `pitch` round the sides, horizontal
    bands at fractions of the height, a floor grid. taper: how much the
    bottom is smaller than the top (baskets)."""
    def at(u, v, z):  # u, v in -1..1 round the outline at height z
        k = 1.0 - taper * (1 - z / h)
        return Vector((u * w / 2 * k, v * d / 2 * k, z))
    outline = []
    nx = max(2, round(w / pitch))
    ny = max(2, round(d / pitch))
    for i in range(nx):
        outline.append((-1 + 2 * i / nx, -1))
    for j in range(ny):
        outline.append((1, -1 + 2 * j / ny))
    for i in range(nx):
        outline.append((1 - 2 * i / nx, 1))
    for j in range(ny):
        outline.append((-1, 1 - 2 * j / ny))
    for (u, v) in outline:
        p.rod(at(u, v, 0), at(u, v, h), r, material, tint, 5, caps=False)
    for f in bands:
        z = h * f
        corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
        for a, b in zip(corners, corners[1:] + corners[:1]):
            p.rod(at(*a, z), at(*b, z), r * (1.6 if f in (0.0, 1.0) else 1.0), material, tint, 6, caps=False)
    if floor:
        for i in range(1, nx):
            u = -1 + 2 * i / nx
            p.rod(at(u, -1, 0), at(u, 1, 0), r, material, tint, 5, caps=False)
        for j in range(1, ny):
            v = -1 + 2 * j / ny
            p.rod(at(-1, v, 0), at(1, v, 0), r, material, tint, 5, caps=False)


def bottle_crate():
    """Equip.bottle_crates: 0.4 × 0.6 × 0.26, galvanised wire, 4 × 6 bottles."""
    p = Parts("bottle_crate")
    wire_box(p, 0.4, 0.6, 0.26, 0.0035, 0.05, "galv", (0.85, 0.86, 0.84), bands=(0.0, 0.35, 0.7, 1.0))
    # The dividers between the bottles, a grid at 0.14.
    for i in range(1, 4):
        x = -0.2 + i * 0.1
        p.rod((x, -0.3, 0.14), (x, 0.3, 0.14), 0.0025, "galv", (0.85, 0.86, 0.84), 5, False)
    for j in range(1, 6):
        y = -0.3 + j * 0.1
        p.rod((-0.2, y, 0.14), (0.2, y, 0.14), 0.0025, "galv", (0.85, 0.86, 0.84), 5, False)
    for sy in (-1, 1):  # flat strap handles at the ends
        p.box((0, sy * 0.302, 0.22), (0.16, 0.004, 0.04), (0.8, 0.8, 0.78), "galv", 0.3, bev=0.0015)
    return p.done()


def carton(name, which, variant):
    """A corrugated carton 0.38 × 0.48 × 0.28 (Equip.carton_stack), its print
    on the sides, two top flaps with a seam, brown tape over the seam."""
    w, d, h = 0.38, 0.48, 0.28
    c = ecell(which)
    p = Parts(name)
    rects = {"+y": c, "-y": c, "+x": c, "-x": c, "-z": c.sub(0, 1, 0.42, 0.58)}
    o = p.rbox((0, 0, h / 2), (w, d, h), rects, "equip", bev=0.006)
    for sx in (-1, 1):  # the two flaps, a hair apart
        m = Mesh()
        m.box((sx * (w / 4 + 0.001), 0, h + 0.0015), (w / 2 - 0.002, d - 0.004, 0.003),
              {"+z": c.sub(0.0, 1.0, 0.42, 0.58), "+x": c.sub(0, 1, 0.42, 0.45), "-x": c.sub(0, 1, 0.42, 0.45),
               "+y": c.sub(0, 1, 0.42, 0.45), "-y": c.sub(0, 1, 0.42, 0.45)}, "equip", (0.9, 0.9, 0.9))
        p.objs.append(m.to_object(name + "_f%d" % sx))
    p.box((0, 0, h + 0.0035), (0.05, d + 0.004, 0.0008), (0.62, 0.45, 0.25), "kraft", 0.3, bev=0)
    for sy in (-1, 1):
        p.box((0, sy * (d / 2 + 0.0015), h - 0.05), (0.05, 0.0008, 0.1), (0.62, 0.45, 0.25), "kraft", 0.3, bev=0)
    o = p.done()
    if variant == 1:  # a corner pushed in, the top sagging
        def f(co):
            corner = max(0.0, 1 - math.hypot(co.x - w / 2, co.y - d / 2) / 0.25)
            sag = max(0.0, (co.z - h * 0.8) / (h * 0.2)) * (1 - (2 * co.x / w) ** 2)
            return Vector((0, 0, -0.025 * corner - 0.008 * sag))
        displace(o, f)
    return o


def pallet():
    """Equip.carton_stack's pallet: 1.2 × 1.0, deck at 0.11-0.135."""
    p = Parts("pallet")
    rnd = random.Random(5)
    for i in range(5):
        t = tuple(c * rnd.uniform(0.85, 1.05) for c in (0.9, 0.8, 0.65))
        p.box((-0.5 + i * 0.25, 0, 0.1225), (0.1, 1.0, 0.025), t, "wood", 0.5, bev=0.003,
              rot=("Z", rnd.uniform(-0.01, 0.01)))
    for sx in (-0.5, 0.0, 0.5):
        for sy in (-0.45, 0.0, 0.45):
            p.box((sx, sy, 0.065), (0.1, 0.1, 0.09), (0.8, 0.7, 0.55), "wood", 0.5, bev=0.004)
        p.box((sx, 0, 0.01), (0.1, 1.0, 0.02), (0.85, 0.75, 0.6), "wood", 0.5, bev=0.003)
    for sy in (-0.45, 0.0, 0.45):  # stringers under the deck
        p.box((0, sy, 0.1), (1.2, 0.1, 0.02), (0.86, 0.76, 0.6), "wood", 0.5, bev=0.003)
    return p.done()


def basket():
    """A shopping basket, red plastic-coated wire, 0.46 × 0.32 × 0.22, tapered."""
    p = Parts("basket")
    red = (0.75, 0.12, 0.1)
    wire_box(p, 0.46, 0.32, 0.22, 0.0028, 0.035, "paint", red, taper=0.12, bands=(0.0, 0.4, 0.75, 1.0))
    p.rod((-0.23, -0.16, 0.22), (0.23, -0.16, 0.22), 0.005, "paint", red, 6, False)
    for sx in (-1, 1):  # handles folded down along the long sides
        pts = [(sx * 0.12, -0.16), (sx * 0.12, 0.16)]
        a = Vector((sx * 0.235, -0.12, 0.22))
        b = Vector((sx * 0.235, 0.12, 0.22))
        mid = Vector((sx * 0.26, 0.0, 0.12))
        prev = a
        for k in range(1, 9):
            t = k / 8
            q = a * (1 - t) ** 2 + mid * 2 * t * (1 - t) + b * t * t
            p.rod(prev, q, 0.0045, "chrome", (0.9, 0.9, 0.9), 6, False)
            prev = q
    return p.done()


def main():
    reset()
    objs = [dairy(3.25), frozen(3.25), chest(), checkout(), abacus(), bottle_crate(), pallet(), basket()]
    for which in ("carton_fish", "carton_milk", "carton_tins"):
        for v in range(2):
            objs.append(carton(which if v == 0 else "%s_v%d" % (which, v), which, v))
    for o in objs:
        o.location = (0, 0, 0)
        o.rotation_euler = (0, 0, 0)
    if not ARGS.get("noao"):
        bake_ao(objs, samples=ARGS.get("samples", 24), distance=0.2, strength=0.75)
    else:
        for o in objs:
            plain_colors(o)
    for o in objs:
        print("%-20s %7d" % (o.name, tri_count(o)))
    export("equip", objs)


if __name__ == "__main__":
    main()
