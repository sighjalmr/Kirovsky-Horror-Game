"""The militia УАЗ-469 («бобик») in Blender: models/cars/bobik.glb.

    python3.11 tools/blender/build_bobik.py

Modelled in the game's frame through G() (x right, y up, nose towards -z,
wheels on the ground at y = 0), the same numbers as Vehicles.bobik(): half
width 0.88, belt 1.1, roof 1.95, wheels at z -1.2 and 1.15, tyre r 0.38.

One mesh per material kind, named by it (see Vehicles.bobik()): body
(yellow), band (blue), top (the grey hard top), black, chrome, glass, lamp,
tail, plate, tyre, rim, inside, seat, beacon.

The body: side panels lofted from the side profile with the wheel arches cut
in, flared arch lips, the flat bonnet with its hinge line, the grille panel
with eight slots and the round lamps in bezels, the external door hinges and
handles, panel gaps, the bumpers of steel channel with tow hooks; the hard
top with its rain gutters, the framed windscreen, the spare on the tailgate;
inside a floor, the dashboard, two seats and the wheel.
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
import bkit
from bkit import *  # noqa
from build_equip import Parts  # noqa: E402

HW = 0.88
BELT = 1.1
ROOF = 1.95
WZ = (-1.2, 1.15)
TYRE_R = 0.38
FRONT = -2.12
REAR = 1.72


def G(x, y, z):
    return Vector((x, -z, y))


class Kinds:
    def __init__(self):
        self.parts = {}

    def __call__(self, kind):
        if kind not in self.parts:
            self.parts[kind] = Parts(kind)
        return self.parts[kind]

    def done(self):
        return [p.done() for p in self.parts.values() if p.objs]


K = Kinds()


def gbox(kind, at, size, bev=0.006, rot=None, tint=(1, 1, 1)):
    """Box with its bottom centre at game `at`, size in game axes."""
    p = K(kind)
    c = G(at[0], at[1] + size[1] / 2, at[2])
    return p.box(tuple(c), (size[0], size[2], size[1]), tint, "paint", 0.6, bev, rot=rot)


def side_slab(kind, prof, x0, x1, bev=0.008):
    """A slab across x0..x1 whose side outline is prof = [(z, y), ...] (game)."""
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    coll = bm.loops.layers.float_color.new("Tint")
    a = [bm.verts.new(G(x0, y, z)) for z, y in prof]
    b = [bm.verts.new(G(x1, y, z)) for z, y in prof]
    bm.faces.new(a)
    bm.faces.new(b[::-1])
    n = len(prof)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([a[i], b[i], b[j], a[j]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for f in bm.faces:
        for l in f.loops:
            l[uvl].uv = (l.vert.co.y, l.vert.co.z)
            l[coll] = (1, 1, 1, 1)
    me = bpy.data.meshes.new(kind + "_slab")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat("paint"))
    o = bpy.data.objects.new(kind + "_slab", me)
    link(o)
    if bev > 0:
        bevel(o, bev, 2, 30)
    K(kind).objs.append(o)
    return o


def arch(zc, z0, z1, y0, r, steps=10):
    """Side-profile points over a wheel arch from z0 to z1 (both at height y0)."""
    a0 = math.atan2(y0 - 0.38, z0 - zc)
    a1 = math.atan2(y0 - 0.38, z1 - zc)
    pts = []
    for k in range(steps + 1):
        a = a0 + (a1 - a0) * k / steps
        pts.append((zc + math.cos(a) * r, 0.38 + math.sin(a) * r))
    return pts


def arch_pts(zc, r, y0):
    dz = math.sqrt(max(r * r - (y0 - 0.38) ** 2, 0))
    return zc - dz, zc + dz


def body():
    r = TYRE_R + 0.08
    # The rear tub's sides: from behind the door to the tail, the arch cut in.
    a0, a1 = arch_pts(WZ[1], r, 0.5)
    prof = [(-0.78, 0.5), (a0, 0.5)] + arch(WZ[1], a0, a1, 0.5, r)[1:-1][::-1][::-1] + [(a1, 0.5), (REAR, 0.5),
                                                                                       (REAR, BELT), (-0.78, BELT)]
    # arch() runs from the front foot over the top to the back foot.
    pts = arch(WZ[1], a0, a1, 0.5, r)
    prof = [(-0.78, 0.5)] + pts + [(REAR, 0.5), (REAR, BELT), (-0.78, BELT)]
    for sx in (-1, 1):
        side_slab("body", prof, sx * (HW - 0.04), sx * HW)
    # Front wings: flat-topped, wider than the bonnet, the front arch cut in.
    f0, f1 = arch_pts(WZ[0], r, 0.55)
    pts = arch(WZ[0], f0, f1, 0.55, r)
    wing = [(FRONT + 0.04, 0.6)] + pts + [(-0.78, 0.55), (-0.78, 1.0), (FRONT + 0.06, 0.98)]
    for sx in (-1, 1):
        side_slab("body", wing, sx * 0.66, sx * HW)
        # Flared lips round both arches.
        for zc, lo, hi in ((WZ[0], f0, f1), (WZ[1], a0, a1)):
            q = arch(zc, lo, hi, 0.52, r + 0.02, 14)
            for i in range(len(q) - 1):
                K("body").rod(G(sx * (HW + 0.01), q[i][1], q[i][0]), G(sx * (HW + 0.01), q[i + 1][1], q[i + 1][0]),
                              0.025, "paint", (1, 1, 1), 6)
    # Bonnet: between the wings, a little lower at the front, the hinge line.
    gbox("body", (0, 0.55, -1.45), (1.32, 0.42, 1.34), bev=0.01)
    K("body").box(tuple(G(0, 0.99, -1.45)), (1.36, 1.36, 0.035), (1, 1, 1), "paint", 0.6, 0.012, rot=("X", 0.035))
    gbox("black", (0, 1.0, -0.8), (1.3, 0.012, 0.012), bev=0)
    # Floor, the bulkhead under the windscreen, the tail panel with its door.
    gbox("inside", (0, 0.48, 0.47), (HW * 2 - 0.08, 0.06, 2.48), bev=0)
    gbox("body", (0, 0.5, -0.79), (HW * 2 - 0.06, 0.6, 0.04), bev=0.004)
    gbox("body", (0, 0.5, REAR - 0.02), (HW * 2 - 0.02, 0.6, 0.04), bev=0.006)
    gbox("black", (0, 0.55, REAR + 0.002), (HW * 2 - 0.4, 0.008, 0.008), bev=0)
    # Blue bands, the panel gaps of the doors, the external hinges, handles.
    for sx in (-1, 1):
        x = sx * (HW + 0.004)
        gbox("band", (x, 0.71, 0.47), (0.012, 0.14, 2.5), bev=0.002)
        gbox("band", (sx * (HW - 0.0), 0.71, -1.45), (0.012, 0.14, 1.2), bev=0.002)
        for z in (-0.74, 0.02, 0.1, 0.86):
            gbox("black", (sx * (HW + 0.002), 0.58, z), (0.008, BELT - 0.6, 0.008), bev=0)
        for z in (-0.72, 0.12):
            for y in (0.68, 0.98):
                gbox("black", (sx * (HW + 0.012), y, z + 0.05), (0.02, 0.06, 0.1), bev=0.004)
        for z in (-0.12, 0.72):
            gbox("chrome", (sx * (HW + 0.02), 0.94, z), (0.02, 0.03, 0.14), bev=0.006)
    # Grille panel: eight slots, the lamps in round bezels, the sidelights.
    gbox("body", (0, 0.45, FRONT + 0.02), (1.6, 0.55, 0.05), bev=0.012)
    for k in range(8):
        gbox("black", (-0.38 + k * 0.108, 0.52, FRONT - 0.005), (0.05, 0.38, 0.02), bev=0.004)
    for sx in (-0.62, 0.62):
        c = G(sx, 0.72, FRONT - 0.005)
        K("chrome").lathe([(0.0, 0.0), (0.115, 0.0), (0.115, 0.02), (0.1, 0.035)], "chrome", 24,
                          xf=Matrix.Translation(c) @ Matrix.Rotation(-math.pi / 2, 4, "X"))
        K("lamp").lathe([(0.1, 0.0), (0.1, 0.03), (0.06, 0.05), (0.0, 0.055)], "white", 24,
                        xf=Matrix.Translation(c) @ Matrix.Rotation(-math.pi / 2, 4, "X"))
        gbox("amber", (sx * 1.0, 0.5, FRONT - 0.005), (0.08, 0.05, 0.03), bev=0.008)
    # Bumpers of steel channel, overriders and tow hooks.
    for z, s in ((FRONT - 0.13, -1), (REAR + 0.08, 1)):
        gbox("black", (0, 0.24, z), (HW * 2 + 0.1, 0.13, 0.09), bev=0.008)
        for sx in (-0.45, 0.45):
            gbox("black", (sx, 0.24, z - s * 0.01), (0.05, 0.13, 0.12), bev=0.004)
            q = G(sx * 1.5, 0.3, z - s * 0.06)
            K("black").rod(q, q + Vector((0, 0.06 * -s, -0.04)), 0.012, "metal", (1, 1, 1), 6)
    # Plates.
    for z, face in ((FRONT - 0.18, "+y"), (REAR + 0.003, "-y")):
        m = Mesh()
        m.box(tuple(G(0, 0.38 if face == "+y" else 0.62, z)), (0.52, 0.01, 0.11), {face: Rect(0, 0, 1, 1)}, "plate")
        K("plate").objs.append(m.to_object("plate_m"))
    # Tail lamps.
    for sx in (-1, 1):
        gbox("tail", (sx * 0.775, 0.62, REAR + 0.01), (0.1, 0.16, 0.03), bev=0.008)
        gbox("chrome", (sx * 0.775, 0.61, REAR + 0.003), (0.12, 0.18, 0.02), bev=0.004)


def top():
    ws0, ws1 = (-0.8, BELT), (-0.7, ROOF - 0.02)
    # Windscreen frame (it folds on the real one), the glass inside it.
    for sx in (-1, 1):
        K("top").rod(G(sx * (HW - 0.05), *ws0[::-1]), G(sx * (HW - 0.05), *ws1[::-1]), 0.03, "paint", (1, 1, 1), 8)
    for y, z in (ws0, ws1):
        gbox("top", (0, y - 0.03, z), (HW * 2 - 0.08, 0.06, 0.05), bev=0.01)
    ang = math.atan2(ws1[0] - ws0[0], ws1[1] - ws0[1])
    c = G(0, (ws0[1] + ws1[1]) / 2, (ws0[0] + ws1[0]) / 2)
    K("glass").box(tuple(c), (HW * 2 - 0.16, 0.012, ws1[1] - ws0[1] - 0.06), (1, 1, 1), "glass", 0.6, 0,
                   rot=("X", -ang))
    gbox("black", (-0.3, BELT + 0.02, ws0[0] - 0.03), (0.45, 0.012, 0.012), bev=0, rot=("Z", 0.0))
    # Hard top: roof with gutters, pillars, side and rear panes.
    gbox("top", (0, ROOF - 0.06, 0.5), (HW * 2, 0.08, 2.44), bev=0.035)
    for sx in (-1, 1):
        gbox("top", (sx * (HW + 0.01), ROOF - 0.08, 0.5), (0.02, 0.025, 2.44), bev=0.004)
        for z, w in ((0.06, 0.1), (0.9, 0.08), (REAR - 0.05, 0.1)):
            gbox("top", (sx * (HW - 0.03), BELT, z), (0.06, ROOF - BELT - 0.05, w), bev=0.01)
        gbox("top", (sx * (HW - 0.03), BELT, 1.3), (0.06, ROOF - BELT - 0.05, 0.75), bev=0.01)  # blind panel
        gbox("glass", (sx * (HW - 0.03), BELT + 0.02, -0.34), (0.012, ROOF - BELT - 0.1, 0.72), bev=0)
        gbox("glass", (sx * (HW - 0.03), BELT + 0.02, 0.48), (0.012, ROOF - BELT - 0.1, 0.74), bev=0)
        gbox("top", (sx * (HW - 0.03), BELT, -0.34), (0.05, 0.04, 0.76), bev=0.008)
        gbox("top", (sx * (HW - 0.03), BELT, 0.48), (0.05, 0.04, 0.76), bev=0.008)
        # The mirror on its arm off the windscreen post.
        a = G(sx * (HW - 0.03), BELT + 0.12, -0.78)
        b = G(sx * (HW + 0.16), BELT + 0.22, -0.82)
        K("black").rod(a, b, 0.01, "metal", (1, 1, 1), 6)
        K("black").box(tuple(b + Vector((0, 0, 0.06))), (0.04, 0.12, 0.16), (1, 1, 1), "metal", 0.6, 0.012)
    gbox("top", (0, BELT, REAR - 0.04), (HW * 2, ROOF - BELT - 0.06, 0.04), bev=0.01)
    gbox("glass", (0, BELT + 0.15, REAR - 0.065), (1.1, 0.5, 0.012), bev=0)
    # The blue beacon on its plinth.
    c = G(0, ROOF + 0.02, -0.55)
    K("black").lathe([(0.0, 0.0), (0.11, 0.0), (0.11, 0.04), (0.0, 0.04)], "rubber", 20, xf=Matrix.Translation(c))
    K("beacon").lathe([(0.0, 0.04), (0.085, 0.04), (0.085, 0.14), (0.07, 0.19), (0.0, 0.2)], "glass", 20,
                      xf=Matrix.Translation(c))
    # Spare wheel on the tailgate.
    wheel(G(0.1, 0.95, REAR + 0.16), axis="Z")


def wheel(c, axis="X", side=1):
    rot = Matrix.Rotation(side * math.pi / 2, 4, "Y") if axis == "X" else Matrix.Rotation(-math.pi / 2, 4, "X")
    xf = Matrix.Translation(c) @ rot
    w = 0.12
    prof = [(0.2, -w), (0.33, -w), (0.37, -w + 0.02), (TYRE_R, -w + 0.05), (TYRE_R, w - 0.05),
            (0.37, w - 0.02), (0.33, w), (0.2, w)]
    t = K("tyre").lathe(prof, "rubber", 32, xf=xf)
    # Lugs of the tread: bumps on every other ring vertex.
    for v in t.data.vertices:
        lc = xf.inverted() @ v.co
        rr = math.hypot(lc.x, lc.y)
        if rr > TYRE_R - 0.005:
            a = math.atan2(lc.y, lc.x)
            if int((a + math.pi) / (2 * math.pi) * 32 + 0.5) % 2 == 0:
                k = (TYRE_R + 0.012) / rr
                lc.x *= k
                lc.y *= k
                v.co = xf @ lc
    K("rim").lathe([(0.21, w - 0.02), (0.2, w - 0.04), (0.14, w - 0.03), (0.08, w), (0.05, w + 0.01),
                    (0.0, w + 0.01)], "metal", 24, xf=xf)
    for k in range(5):
        a = k * 2 * math.pi / 5
        q = xf @ Vector((math.cos(a) * 0.065, math.sin(a) * 0.065, w + 0.01))
        K("rim").rod(q, xf @ Vector((math.cos(a) * 0.065, math.sin(a) * 0.065, w + 0.03)), 0.009, "metal", (1, 1, 1), 6)


def cabin():
    gbox("inside", (0, 0.8, -0.7), (HW * 2 - 0.1, 0.32, 0.16), bev=0.01)  # dashboard
    for sx in (-0.42, 0.42):
        gbox("seat", (sx, 0.72, 0.25), (0.5, 0.12, 0.5), bev=0.03)
        K("seat").box(tuple(G(sx, 1.1, 0.53)), (0.48, 0.1, 0.6), (1, 1, 1), "leather", 0.6, 0.03, rot=("X", 0.15))
    gbox("seat", (0, 0.66, 1.0), (1.5, 0.12, 0.5), bev=0.03)
    K("seat").box(tuple(G(0, 1.04, 1.28)), (1.5, 0.1, 0.55), (1, 1, 1), "leather", 0.6, 0.03, rot=("X", 0.12))
    # The wheel on its column.
    c = G(-0.42, 1.08, -0.5)
    xf = Matrix.Translation(c) @ Matrix.Rotation(1.1, 4, "X")
    n = 16
    for k in range(n):
        a0, a1 = k * 2 * math.pi / n, (k + 1) * 2 * math.pi / n
        K("black").rod(xf @ Vector((math.cos(a0) * 0.19, math.sin(a0) * 0.19, 0)),
                       xf @ Vector((math.cos(a1) * 0.19, math.sin(a1) * 0.19, 0)), 0.014, "rubber", (1, 1, 1), 6)
    for k in range(3):
        a = k * 2 * math.pi / 3 - math.pi / 2
        K("black").rod(xf @ Vector((0, 0, 0)), xf @ Vector((math.cos(a) * 0.19, math.sin(a) * 0.19, 0)), 0.01,
                       "rubber", (1, 1, 1), 6)
    K("black").rod(xf @ Vector((0, 0, 0)), xf @ Vector((0, 0, -0.45)), 0.02, "rubber", (1, 1, 1), 8)


def main():
    reset()
    body()
    top()
    cabin()
    for sx in (-1, 1):
        for wz in WZ:
            wheel(G(sx * 0.74, TYRE_R, wz), "X", sx)
    objs = K.done()
    for o in objs:
        for p in o.data.polygons:
            pass
        print("%-10s %6d" % (o.name, tri_count(o)))
    bkit.OUT = os.path.join(bkit.ROOT, "models", "cars") if hasattr(bkit, "ROOT") else bkit.OUT.replace("kit", "cars")
    export("bobik", objs)


if __name__ == "__main__":
    main()
