"""Street furniture of the МЖК square in Blender: models/kit/street.glb.

    python3.11 tools/blender/build_street.py

Replaces the box-built pieces of scripts/street.gd, same frames (yaw 0:
the front faces the road, -Z in the game, +Y here):

* kiosk          «Союзпечать»: panelled plinth, framed glazing with the papers
                 behind it, the blue sign band, the overhanging roof with a
                 drip edge, the pay hatch.
* phone_booths   two red booths: tube frame, glazing bars, kick panels,
                 the «ТЕЛЕФОН» lightbox, the payphones (no handsets);
                 phone_handset hangs on the hook separately.
* bus_stop       the concrete pavilion: chamfered walls and roof slab.
* bench_2000, bench_2600  cast-concrete side frames, slats with bolts.
* urn            the fluted concrete vase on its foot.
* bin, bin_lid   a green steel refuse bin with rolled rim and lugs.
* entrance       steps with worn noses, the canopy slab on brackets, the
                 door frame and the door (street atlas), a caged lamp.
"""
import os, sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
from bkit import *  # noqa
from build_equip import Parts  # noqa: E402

CELLS = ["soyuz", "kiosk_win", "phone", "bus_sign", "afisha", "poster_drink", "slogan", "door",
         "podezd", "house_no", "bin", "tara", "timetable", "bark", "panel_plinth", "blank"]
BLUE = (0.32, 0.42, 0.5)
CONCRETE = (0.62, 0.61, 0.58)


def scell(name):
    return grid_cell(CELLS.index(name), 4, 4).sub(0, 1, 0, 1, px=1 / 2048)


def G(x, y, z):
    return Vector((x, -z, y))


def gbox(p, at, size, tint=(1, 1, 1), material="paint", tex_m=0.6, bev=0.004, rot=None):
    c = G(at[0], at[1] + size[1] / 2, at[2])
    return p.box(tuple(c), (size[0], size[2], size[1]), tint, material, tex_m, bev, rot=rot)


def gface(p, at, size, cellname, tint=(1, 1, 1)):
    """A textured front (facing the road, -Z game = +Y here) from a street cell."""
    m = Mesh()
    c = G(at[0], at[1] + size[1] / 2, at[2])
    m.box(tuple(c), (size[0], size[2], size[1]), {"+y": scell(cellname)}, "street", tint)
    o = m.to_object("%s_f%d" % (p.name, len(p.objs)))
    p.objs.append(o)
    return o


def kiosk():
    p = Parts("kiosk")
    w, d = 2.6, 1.8
    gbox(p, (0, 0, 0), (w, 0.8, d), BLUE, bev=0.02)
    for k in range(3):  # panels on the plinth
        gbox(p, (-w / 2 + 0.45 + k * 0.85, 0.12, -d / 2 - 0.004), (0.7, 0.56, 0.01), tuple(c * 0.9 for c in BLUE), bev=0.003)
    gbox(p, (0, 0.8, d / 2 - 0.05), (w, 1.35, 0.1), BLUE, bev=0.01)
    for sx in (-w / 2 + 0.05, w / 2 - 0.05):
        gbox(p, (sx, 0.8, 0), (0.1, 1.35, d), BLUE, bev=0.01)
    gface(p, (0, 0.82, -d / 2 + 0.12), (w - 0.2, 1.3, 0.02), "kiosk_win")
    gbox(p, (0, 0.8, -d / 2 + 0.05), (w - 0.1, 1.35, 0.01), (1, 1, 1), "glass#99a8a84d@psx_glass", bev=0)
    frame = (0.25, 0.27, 0.3)
    for k in range(4):
        gbox(p, (-w / 2 + 0.05 + k * (w - 0.1) / 3, 0.8, -d / 2 + 0.04), (0.05, 1.35, 0.05), frame, "metal", bev=0.008)
    gbox(p, (0, 1.2, -d / 2 + 0.04), (w, 0.04, 0.05), frame, "metal", bev=0.006)
    gbox(p, (0, 0.78, -d / 2 + 0.04), (w, 0.05, 0.08), frame, "metal", bev=0.006)
    gbox(p, (0.4, 0.8, -d / 2 - 0.12), (0.6, 0.03, 0.26), (0.7, 0.68, 0.62), "formica", 0.5, bev=0.006)
    for sx in (0.13, 0.67):
        gbox(p, (sx, 0.7, -d / 2 - 0.05), (0.03, 0.1, 0.12), frame, "metal", bev=0.003, rot=("X", 0.6))
    gface(p, (0, 2.15, -d / 2 - 0.06), (w + 0.1, 0.45, 0.04), "soyuz")
    gbox(p, (0, 2.15, 0.02), (w + 0.1, 0.45, d - 0.04), BLUE, bev=0.01)
    gbox(p, (0, 2.6, -0.1), (w + 0.5, 0.08, d + 0.5), (0.35, 0.35, 0.35), bev=0.015)
    gbox(p, (0, 2.56, -0.1), (w + 0.52, 0.04, d + 0.52), (0.28, 0.28, 0.28), "metal", bev=0.006)  # drip edge
    return p.done()


def phone_booths():
    p = Parts("phone_booths")
    red = (0.62, 0.14, 0.1)
    s = 0.9
    for k in range(2):
        ox = -0.48 + k * 0.96
        gbox(p, (ox, 0, 0), (s, 0.05, s), red, bev=0.01)
        gbox(p, (ox, 2.2, 0), (s + 0.04, 0.14, s + 0.04), red, bev=0.015)
        for cx in (-1, 1):
            for cz in (-1, 1):
                p.rod(G(ox + cx * (s / 2 - 0.025), 0.05, cz * (s / 2 - 0.025)),
                      G(ox + cx * (s / 2 - 0.025), 2.2, cz * (s / 2 - 0.025)), 0.025, "paint", red, 10)
        for side in range(4):
            a = side * math.pi / 2
            if side == 0:
                # The door: framed in the same tube with a handle.
                pass
            ca, sa = math.cos(a), math.sin(a)

            def L(x, y, z):  # side-local -> game
                return (ox + x * ca + z * sa, y, -x * sa + z * ca)
            inner_z = -s / 2 + 0.02
            c = L(0, 0, inner_z)
            rot = ("Z", -a)
            p.box(tuple(G(c[0], 0.6 + 0.75, c[2])), (s - 0.08, 0.01, 1.5), (1, 1, 1), "glass#8c9e9e59@psx_glass", bev=0,
                  rot=rot)
            p.box(tuple(G(c[0], 0.05 + 0.275, c[2])), (s - 0.05, 0.03, 0.55), red, bev=0.006, rot=rot)
            for y in (1.1, 1.6):
                p.box(tuple(G(c[0], y + 0.0175, c[2])), (s - 0.05, 0.035, 0.035), red, bev=0.008, rot=rot)
            p.box(tuple(G(c[0], 0.6 + 0.75, c[2])), (0.035, 0.035, 1.5), red, bev=0.008, rot=rot)
            if side == 0:
                p.rod(G(ox + 0.32, 0.95, -s / 2 - 0.02), G(ox + 0.32, 1.25, -s / 2 - 0.02), 0.012, "chrome")
        gface(p, (ox, 2.34, -s / 2 - 0.03), (s, 0.22, 0.02), "phone")
        gbox(p, (ox, 2.34, 0.01), (s, 0.22, s - 0.02), red, bev=0.01)
        # The payphone: a grey box, a coin slot, the cord's armoured hose.
        gbox(p, (ox, 1.25, s / 2 - 0.12), (0.24, 0.36, 0.14), (0.45, 0.47, 0.47), "metal", bev=0.015)
        gbox(p, (ox + 0.05, 1.5, s / 2 - 0.195), (0.06, 0.01, 0.01), (0.1, 0.1, 0.1), "rubber", bev=0)
        p.lathe([(0.0, 0.0), (0.04, 0.0), (0.04, 0.008), (0.0, 0.01)], "chrome", 16, xf=Matrix.Translation(
            G(ox + 0.04, 1.4, s / 2 - 0.19)) @ Matrix.Rotation(-math.pi / 2, 4, "X"))
        p.box(tuple(G(ox - 0.14, 1.45, s / 2 - 0.1)), (0.03, 0.03, 0.06), (0.3, 0.3, 0.3), "metal", bev=0.004)
    return p.done()


def handset():
    """The payphone handset on its hook, in the booth's frame for booth 0
    (Street.phone_booths adds it shifted by 0.96 for booth 1)."""
    p = Parts("phone_handset")
    ox, s = -0.48, 0.9
    a, b = G(ox - 0.14, 1.36, s / 2 - 0.1), G(ox - 0.14, 1.54, s / 2 - 0.1)
    p.rod(a, b, 0.016, "rubber", (0.08, 0.08, 0.08), 10)
    for q, k in ((a, -1), (b, 1)):
        p.lathe([(0.0, 0.0), (0.03, 0.0), (0.034, 0.02), (0.0, 0.024)], "rubber", 14, (0.08, 0.08, 0.08),
                xf=Matrix.Translation(q) @ Matrix.Rotation(math.pi / 2, 4, "X"))
    return p.done()


def bus_stop():
    p = Parts("bus_stop")
    w = 4.2
    gbox(p, (0, 0, 0.75), (w, 2.4, 0.14), CONCRETE, "concrete", 1.2, bev=0.03)
    for sx in (-w / 2 + 0.07, w / 2 - 0.07):
        gbox(p, (sx, 0, 0.2), (0.14, 2.4, 1.2), CONCRETE, "concrete", 1.2, bev=0.03)
    gbox(p, (0, 2.4, 0.1), (w + 0.4, 0.18, 1.8), CONCRETE, "concrete", 1.2, bev=0.04)
    gbox(p, (0, 2.36, 0.1), (w + 0.2, 0.04, 1.6), tuple(c * 0.8 for c in CONCRETE), "concrete", 1.2, bev=0)
    gbox(p, (0, -0.02, 0.2), (w, 0.06, 1.4), CONCRETE, "concrete", 1.2, bev=0.02)
    return p.done()


def bench(length):
    p = Parts("bench_%d" % round(length * 1000))
    con = (0.55, 0.55, 0.52)
    for sx in (-length * 0.38, length * 0.38):
        # Cast side frame: a foot, the seat bearer, the raked back post.
        pts = [(-0.25, 0.0), (0.25, 0.0), (0.25, 0.06), (0.12, 0.1), (0.1, 0.38), (0.25, 0.4), (0.25, 0.44),
               (0.28, 0.86), (0.2, 0.88), (0.15, 0.46), (-0.25, 0.44), (-0.25, 0.38), (-0.08, 0.36), (-0.1, 0.1),
               (-0.25, 0.06)]
        pts = [(sx, z, y) for (z, y) in pts]
        prof = [(z, y) for (_, z, y) in pts]
        # prism() extrudes along Blender y; here the frame is a slab across x.
        bm = bmesh.new()
        a = [bm.verts.new((sx - 0.05, -z, y)) for z, y in prof]
        b = [bm.verts.new((sx + 0.05, -z, y)) for z, y in prof]
        bm.faces.new(a)
        bm.faces.new(b[::-1])
        for i in range(len(prof)):
            j = (i + 1) % len(prof)
            bm.faces.new([a[i], b[i], b[j], a[j]])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        uvl = bm.loops.layers.uv.new("UVMap")
        coll = bm.loops.layers.float_color.new("Tint")
        for f in bm.faces:
            for l in f.loops:
                l[uvl].uv = (l.vert.co.y, l.vert.co.z)
                l[coll] = (*con, 1)
        me = bpy.data.meshes.new("bf")
        bm.to_mesh(me)
        bm.free()
        me.materials.append(mat("concrete"))
        o = bpy.data.objects.new("bench_frame", me)
        link(o)
        bevel(o, 0.012, 2, 30)
        p.objs.append(o)
    slat = (0.42, 0.52, 0.38)
    for k in range(3):
        gbox(p, (0, 0.44, -0.18 + k * 0.15), (length, 0.04, 0.11), slat, "wood", 0.6, bev=0.008)
    for k in range(2):
        y, z = 0.62 + k * 0.17, 0.25 + k * 0.04
        c = G(0, y, z)
        p.box(tuple(c), (length, 0.035, 0.11), slat, "wood", 0.6, bev=0.008, rot=("X", 0.25))
    for sx in (-length * 0.38, length * 0.38):
        for k in range(3):
            p.lathe([(0.0, 0.0), (0.008, 0.0), (0.008, 0.004), (0.0, 0.006)], "metal", 8, (0.3, 0.3, 0.3),
                    xf=Matrix.Translation(G(sx, 0.48, -0.18 + k * 0.15)))
    return p.done()


def urn():
    p = Parts("urn")
    prof = [(0.0, 0.0), (0.2, 0.0), (0.2, 0.03), (0.17, 0.08), (0.12, 0.15), (0.13, 0.2), (0.16, 0.35), (0.22, 0.5),
            (0.26, 0.62), (0.285, 0.64), (0.285, 0.67), (0.25, 0.67), (0.23, 0.55), (0.0, 0.5)]
    o = p.lathe(prof, "concrete", 32, (0.68, 0.67, 0.63))
    for v in o.data.vertices:  # flutes on the bowl
        if 0.2 < v.co.z < 0.62:
            a = math.atan2(v.co.y, v.co.x)
            r = math.hypot(v.co.x, v.co.y)
            if r > 0.1:
                k = 1.0 + 0.04 * math.cos(a * 16)
                v.co.x *= k
                v.co.y *= k
    p.box((0.03, 0.0, 0.53), (0.12, 0.16, 0.06), (0.8, 0.78, 0.7), "white", bev=0.01, rot=("Z", 0.6))
    return p.done()


def bin_():
    """A 0.75 m³ steel bin, 1.1 × 1.0 × 0.85 (game x, y, z), bottom at 0.08."""
    p = Parts("bin")
    m = Mesh()
    w, h, d = 1.1, 1.0, 0.85
    rect = scell("bin")
    m.box((0, 0, 0.08 + h / 2), (w, d, h), {"+y": rect, "-y": rect, "+x": rect, "-x": rect}, "street")
    o = m.to_object("bin_body")
    for v in o.data.vertices:  # tapered towards the bottom
        k = 0.9 + 0.1 * (v.co.z - 0.08) / h
        v.co.x *= k
        v.co.y *= k
    bevel(o, 0.01, 1, 30)
    p.objs.append(o)
    p.box((0, 0, 0.1), (w * 0.88, d * 0.88, 0.04), (0.2, 0.28, 0.21), bev=0.004)
    for sy in (-1, 1):  # rolled rim
        p.rod((-w / 2 - 0.005, sy * (d / 2 + 0.005), 1.07), (w / 2 + 0.005, sy * (d / 2 + 0.005), 1.07), 0.015, "paint",
              (0.2, 0.28, 0.21), 8)
    for sx in (-1, 1):
        p.rod((sx * (w / 2 + 0.005), -d / 2, 1.07), (sx * (w / 2 + 0.005), d / 2, 1.07), 0.015, "paint", (0.2, 0.28, 0.21), 8)
        p.rod((sx * (w / 2 + 0.06), 0, 0.85), (sx * (w / 2 + 0.0), 0, 0.85), 0.03, "paint", (0.2, 0.28, 0.21), 10)
    return p.done()


def bin_lid():
    """The lid, hinged at the back edge: origin on the hinge line."""
    p = Parts("bin_lid")
    gbox(p, (0, 0, -0.42), (1.14, 0.04, 0.9), (0.2, 0.28, 0.21), bev=0.012)
    gbox(p, (0, 0.04, -0.42), (0.9, 0.02, 0.6), (0.18, 0.25, 0.19), bev=0.008)
    return p.done()


def entrance():
    p = Parts("entrance")
    con = (0.58, 0.57, 0.54)
    for k in range(3):
        o = gbox(p, (0, 0, -0.9 + k * 0.3), (2.4 - k * 0.2, 0.15 * (k + 1), 0.3), con, "concrete", 1.0, bev=0.025)
    gbox(p, (0, 0, -0.15), (2.0, 0.45, 0.3), con, "concrete", 1.0, bev=0.02)
    gbox(p, (0, 2.75, -0.7), (2.6, 0.14, 1.5), con, "concrete", 1.0, bev=0.03)
    for sx in (-1.15, 1.15):
        gbox(p, (sx, 0.45, -1.3), (0.12, 2.3, 0.12), con, "concrete", 1.0, bev=0.02)
        gbox(p, (sx, 2.6, -1.0), (0.1, 0.15, 0.6), con, "concrete", 1.0, bev=0.02)  # bracket under the slab
    gface(p, (0, 0.45, -0.035), (1.6, 2.2, 0.02), "door")
    frame = (0.3, 0.22, 0.16)
    gbox(p, (0, 0.45, -0.02), (1.76, 2.3, 0.04), frame, bev=0.006)
    gbox(p, (-0.72, 0.45, -0.05), (0.08, 2.24, 0.03), frame, bev=0.006)
    gbox(p, (0.72, 0.45, -0.05), (0.08, 2.24, 0.03), frame, bev=0.006)
    gbox(p, (0, 2.6, -0.05), (1.52, 0.06, 0.03), frame, bev=0.006)
    p.rod(G(0.5, 1.4, -0.06), G(0.5, 1.4, -0.12), 0.012, "metal", (0.3, 0.3, 0.3))
    p.rod(G(0.5, 1.4, -0.12), G(0.5, 1.15, -0.12), 0.012, "metal", (0.3, 0.3, 0.3))
    # The lamp's wire cage over the bulb (the bulb itself stays in the game, lit at night).
    c = G(0, 2.58, -0.2)
    for k in range(6):
        a = k * math.pi / 3
        q0 = c + Vector((math.cos(a) * 0.09, math.sin(a) * 0.09, 0.0))
        q1 = c + Vector((math.cos(a) * 0.09, math.sin(a) * 0.09, 0.17))
        p.rod(q0, q1, 0.003, "metal", (0.2, 0.2, 0.2), 4, False)
    p.lathe([(0.09, 0.0), (0.095, 0.004), (0.09, 0.008)], "metal", 16, (0.2, 0.2, 0.2), xf=Matrix.Translation(c))
    p.lathe([(0.0, 0.17), (0.12, 0.17), (0.12, 0.18), (0.0, 0.2)], "metal", 16, (0.25, 0.25, 0.25),
            xf=Matrix.Translation(c))
    return p.done()


def main():
    reset()
    objs = [kiosk(), phone_booths(), handset(), bus_stop(), bench(2.0), bench(2.6), urn(), bin_(), bin_lid(),
            entrance()]
    for o in objs:
        o.location = (0, 0, 0)
    if not ARGS.get("noao"):
        bake_ao(objs, samples=ARGS.get("samples", 16), distance=0.3, strength=0.7)
    else:
        for o in objs:
            plain_colors(o)
    for o in objs:
        print("%-20s %7d" % (o.name, tri_count(o)))
    export("street", objs)


if __name__ == "__main__":
    main()
