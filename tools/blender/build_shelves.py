"""Shop shelving of «Кировский» modelled in Blender: models/kit/shelves.glb.

    python3.11 tools/blender/build_shelves.py

The steel shelving of a Soviet универсам, the kind made by the «Торгмаш»
works: a double-sided island gondola (горка) and a one-sided wall rack, in
the lengths the store uses (Props.gondola, Props.wall_shelf). A segment is
split into bays a metre or so wide by slotted uprights; each bay has its
perforated back panels, cantilever shelves of bent sheet steel on tapered
brackets with a rolled front lip and a price-tag channel, a plinth with a
recessed kick plate, a capping rail, and a little wear: a dent in a lip, a
shelf hanging a few millimetres low, paint rubbed off along the edges (in
the "paint" texture). End panels for the ends of a run come separately.

Geometry is placed exactly where Props expects the shelves (board tops at
level + 0.02, the products' frame unchanged), so the goods stand on them.
Names: gondola_<mm>, wall_<mm>, gondola_end, wall_end.
"""
import os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
from bkit import *  # noqa

BASE = (0.55, 0.6, 0.58)
BOARD = (0.62, 0.66, 0.63)
LIP = (0.78, 0.8, 0.77)
BRACKET = (0.5, 0.52, 0.5)
UPRIGHT = (0.46, 0.5, 0.48)
KICK = (0.3, 0.33, 0.32)
TAG = (0.92, 0.92, 0.88)


class Parts:
    """Collects small parts as separate objects (so each bevels cleanly),
    joined into one model at the end."""

    def __init__(self, name):
        self.name = name
        self.objs = []

    def box(self, c, s, tint, material="paint", tex_m=0.6, bev=0.003, faces=None):
        m = Mesh()
        m.box_m(c, s, material, tex_m, tint, faces)
        o = m.to_object("%s_p%d" % (self.name, len(self.objs)))
        if bev > 0 and faces is None:
            bevel(o, min(bev, min(s) * 0.45), 1 if bev < 0.004 else 2, 30)
        self.objs.append(o)
        return o

    def obj(self, o):
        self.objs.append(o)
        return o

    def done(self):
        o = join(self.objs, self.name)
        return o


def lip_profile(p, x0, side, y, y0, y1, depth, dent=None):
    """The shelf: a sheet bent down at the front into a rolled lip, as one
    extruded profile along y (Blender) from y0 to y1. x0 = inner edge (at
    the spine), side = +1/-1 which way it reaches, y = board top level."""
    t = 0.0015
    xs = x0 + side * depth
    # Profile in the (x, z) plane, going round the sheet.
    prof = [(x0, y), (xs - side * 0.004, y), (xs, y - 0.004), (xs, y - 0.045), (xs - side * 0.006, y - 0.05),
            (xs - side * 0.01, y - 0.046), (xs - side * 0.01, y - 0.02), (xs - side * 0.014, y - t - 0.004),
            (x0, y - t - 0.004)]
    if side < 0:
        prof = prof[::-1]
    m = Mesh()
    n = max(2, int((y1 - y0) / 0.25))
    rows, uvs = [], []
    for i in range(n + 1):
        yy = y0 + (y1 - y0) * i / n
        row = []
        for (px, pz) in prof:
            dz = 0.0
            if dent is not None:
                dz = -dent[1] * math.exp(-((yy - dent[0]) / 0.06) ** 2) * (1 if abs(px - xs) < 0.02 else 0.3)
            row.append(Vector((px, yy, pz + dz)))
        rows.append(row)
        uvs.append([(yy / 0.6, k * 0.02) for k in range(len(prof))])
    m.grid(rows, uvs, "paint", BOARD, smooth=False)
    # Close the two ends.
    for yy, rev in ((y0, True), (y1, False)):
        pts = [Vector((px, yy, pz)) for (px, pz) in prof]
        if rev:
            pts = pts[::-1]
        m.face(pts, [(0, 0)] * len(pts), "paint", BOARD)
    o = m.to_object(p.name + "_board%d" % len(p.objs))
    # Front lip lighter (the paint wears there), via vertex tint.
    me = o.data
    col = me.color_attributes["Tint"]
    for poly in me.polygons:
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            if abs(co.x - xs) < 0.012:
                col.data[li].color = (*LIP, 1)
    smooth_by_angle(o, 30)
    p.obj(o)


def tag_channel(p, xs, side, y, y0, y1):
    """The plastic price-tag channel clipped on the lip: a thin C profile."""
    x = xs + side * 0.004
    p.box((x, (y0 + y1) / 2, y - 0.03), (0.006, y1 - y0, 0.036), TAG, bev=0.0015)


def bracket(p, x0, side, y, depth, yy):
    """A tapered cantilever bracket under a shelf, hooked into the upright."""
    m = Mesh()
    d = depth - 0.03
    pts = [(x0, y - 0.006), (x0 + side * d, y - 0.006), (x0 + side * d, y - 0.02), (x0, y - 0.12)]
    if side < 0:
        pts = pts[::-1]
    th = 0.004
    for sgn in (-1, 1):
        ps = [Vector((px, yy + sgn * th / 2, pz)) for (px, pz) in pts]
        if sgn < 0:
            ps = ps[::-1]
        m.face(ps, [(px / 0.6, pz / 0.6) for (px, pz) in pts], "paint", BRACKET)
    for i in range(4):
        a, b = pts[i], pts[(i + 1) % 4]
        ps = [Vector((a[0], yy - th / 2, a[1])), Vector((b[0], yy - th / 2, b[1])),
              Vector((b[0], yy + th / 2, b[1])), Vector((a[0], yy + th / 2, a[1]))]
        m.face(ps if side > 0 else ps[::-1], [(0, 0), (0.1, 0), (0.1, 0.01), (0, 0.01)], "paint", BRACKET)
    o = m.to_object(p.name + "_br%d" % len(p.objs))
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(o.data)
    bm.free()
    p.obj(o)


def upright(p, x, yy, z0, z1, w=0.05, d=0.06):
    """A slotted upright: a rectangular tube with a column of slots on each
    face that brackets hook into (dark insets)."""
    p.box((x, yy, (z0 + z1) / 2), (d, w, z1 - z0), UPRIGHT, bev=0.004)
    # Slots: a dark strip on each side the brackets face.
    for sx in (-1, 1):
        p.box((x + sx * (d / 2 + 0.0004), yy, (z0 + z1) / 2), (0.001, 0.012, (z1 - z0) - 0.06), (0.12, 0.12, 0.12),
              bev=0, faces=["+x" if sx > 0 else "-x"])


def back_panel(p, x, y0, y1, z0, z1, th=0.03):
    """Perforated steel back panel of one bay (pegboard texture, holes 25 mm)."""
    p.box((x, (y0 + y1) / 2, (z0 + z1) / 2), (th, y1 - y0, z1 - z0), (0.95, 0.95, 0.92), "pegboard", 1.0,
          bev=0.002)


def gondola(L, seed):
    """Double-sided island gondola of length L (along Blender y), 0.96 wide."""
    rnd = random.Random(seed)
    p = Parts("gondola_%d" % round(L * 1000))
    hl = L / 2
    bays = max(1, round(L / 1.05))
    edges = [-hl + 0.025 + (L - 0.05) * i / bays for i in range(bays + 1)]
    # Plinth with the kick plate set back under the bottom shelves.
    p.box((0, 0, 0.06), (0.96, L, 0.12), BASE, tex_m=0.6, bev=0.006)
    for sx in (-1, 1):
        p.box((sx * 0.47, 0, 0.055), (0.012, L - 0.02, 0.09), KICK, bev=0.002)
    # Spine: uprights at the bay edges, the back panels between them.
    for e in edges:
        upright(p, 0, e, 0.12, 1.85, w=0.05, d=0.08)
    for i in range(bays):
        back_panel(p, 0, edges[i] + 0.026, edges[i + 1] - 0.026, 0.13, 1.79)
    # Capping rail.
    p.box((0, 0, 1.825), (0.12, L, 0.05), BASE, bev=0.01)
    levels = [0.12, 0.52, 0.92, 1.32]
    for side in (-1, 1):
        x0 = side * 0.025
        for li, y in enumerate(levels):
            top = y + 0.02
            for i in range(bays):
                b0, b1 = edges[i] + 0.028, edges[i + 1] - 0.028
                dent = None
                sag = 0.0
                if rnd.random() < 0.18:
                    dent = (rnd.uniform(b0 + 0.1, b1 - 0.1), rnd.uniform(0.003, 0.007))
                if li > 0 and rnd.random() < 0.12:
                    sag = rnd.uniform(0.002, 0.005)
                lip_profile(p, x0, side, top - sag, b0, b1, 0.42, dent)
                tag_channel(p, x0 + side * 0.42, side, top - sag, b0, b1)
                if li > 0:
                    for yy in (b0 + 0.01, b1 - 0.01):
                        bracket(p, x0, side, top - sag, 0.42, yy)
    o = p.done()
    return o


def wall(L, seed):
    """One-sided wall rack, depth 0.8, back at -x (Props: side = +1 faces +x)."""
    rnd = random.Random(seed)
    p = Parts("wall_%d" % round(L * 1000))
    hl = L / 2
    bays = max(1, round(L / 1.05))
    edges = [-hl + 0.04 + (L - 0.08) * i / bays for i in range(bays + 1)]
    p.box((0.03, 0, 0.06), (0.74, L, 0.12), BASE, bev=0.006)
    p.box((0.395, 0, 0.055), (0.012, L - 0.04, 0.09), KICK, bev=0.002)
    for e in edges:
        upright(p, -0.36, e, 0.12, 2.17, w=0.05, d=0.07)
    for i in range(bays):
        back_panel(p, -0.37, edges[i] + 0.026, edges[i + 1] - 0.026, 0.13, 2.12, th=0.04)
    for sy in (-1, 1):  # side panels at the ends
        p.box((0, sy * (hl - 0.02), 1.1), (0.8, 0.04, 2.2), (0.6, 0.64, 0.61), bev=0.008)
    p.box((0, 0, 2.175), (0.8, L, 0.05), BASE, bev=0.008)
    levels = [0.12, 0.52, 0.92, 1.32, 1.72]
    x0 = -0.33
    for li, y in enumerate(levels):
        top = y + 0.02
        for i in range(bays):
            b0, b1 = edges[i] + 0.028, edges[i + 1] - 0.028
            if i == 0:
                b0 = max(b0, -hl + 0.045)
            if i == bays - 1:
                b1 = min(b1, hl - 0.045)
            dent = (rnd.uniform(b0 + 0.1, b1 - 0.1), rnd.uniform(0.003, 0.006)) if rnd.random() < 0.18 else None
            sag = rnd.uniform(0.002, 0.004) if li > 0 and rnd.random() < 0.12 else 0.0
            lip_profile(p, x0, 1, top - sag, b0, b1, 0.72, dent)
            tag_channel(p, x0 + 0.72, 1, top - sag, b0, b1)
            if li > 0:
                for yy in (b0 + 0.01, b1 - 0.01):
                    bracket(p, x0, 1, top - sag, 0.72, yy)
    return p.done()


def end_panel(name, w, h, d=0.04):
    """End panel of a run: a framed steel sheet with a rounded top edge and
    a slot for the department card."""
    p = Parts(name)
    p.box((0, 0, h / 2), (w, d, h), (0.62, 0.66, 0.63), bev=0.012)
    p.box((0, d / 2 + 0.002, h * 0.78), (w * 0.6, 0.004, 0.16), (0.85, 0.85, 0.8), bev=0.002)
    p.box((0, d / 2 + 0.004, 0.06), (w - 0.02, 0.006, 0.1), KICK, bev=0.002)
    return p.done()


def main():
    reset()
    objs = []
    for i, L in enumerate([3.125, 3.5]):
        objs.append(gondola(L, 11 + i))
    for i, L in enumerate([3.0, 3.6]):
        objs.append(wall(L, 31 + i))
    objs.append(end_panel("gondola_end", 1.0, 1.86))
    for o in objs:
        o.location = (0, 0, 0)
    if not ARGS.get("noao"):
        bake_ao(objs, samples=ARGS.get("samples", 24), distance=0.25, strength=0.75)
    else:
        for o in objs:
            plain_colors(o)
    for o in objs:
        print("%-20s %7d" % (o.name, tri_count(o)))
    export("shelves", objs)


if __name__ == "__main__":
    main()
