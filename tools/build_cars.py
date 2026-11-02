"""Builds the two cars of the street scenes in Blender and bakes them into
models/cars/zhiguli.glb (Gordeev's pale blue ВАЗ-2106) and
models/cars/volga.glb (the director's black ГАЗ-24).

Run with Blender's Python module (pip install bpy):
    python tools/build_cars.py -- '{"export": 1}'          # both .glb
    python tools/build_cars.py -- '{"car": "zhiguli"}'     # preview render

Everything is modelled in the game's frame (x right, y up, nose towards -z,
wheels on the ground at y = 0) and turned into Blender's Z-up at the end,
so the .glb comes out in exactly that frame.

The body is a loft of cross-sections every 4 cm: flat flanks with a crisp
shoulder, a slight bulge at the waist and a tuck under the sill; the
greenhouse is a second loft (windscreen, roof, rear window) turned into a
shell. Wheel arches, the cabin and the window openings are cut with
booleans, so the inside shows through the glass. Then the details that make
it read as the real car: panel gaps, chrome window surrounds, drip rails,
side mouldings, door handles, the mirror, quad headlamps (one pair for the
«Волга») in chrome bezels, the grille, bumpers with overriders, tail-lamp
clusters, plates, the exhaust, wheels with tyres, steel rims and hubcaps.

Mesh names tell the game which material to use (see scripts/vehicles.gd):
body, chrome, black, glass, lamp, tail, amber, reverse, plate, tyre, rim,
inside, seat.
"""
import bpy, bmesh, math, sys, json, os
from mathutils import Vector, Matrix

ARGS = json.loads(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else {}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Dimensions after the factory drawings (m). glass: z of the windscreen foot,
# windscreen top, rear window top, rear window foot.
CARS = {
    "zhiguli": dict(
        length=4.166, hw=0.805, belt=0.92, roof=1.415, sill=0.22, glass=[-0.78, -0.22, 0.62, 1.15],
        hood=[0.80, 0.885], trunk=[0.905, 0.875], wheel_z=[-1.255, 1.169], track=1.365, tyre_r=0.29, tyre_w=0.165,
        rim_r=0.165, b_pillar=0.29, quad=True, paint=(0.55, 0.66, 0.72), tumble=0.24, front_panel=0.78,
        tail="wide",
    ),
    "volga": dict(
        length=4.735, hw=0.90, belt=0.90, roof=1.455, sill=0.21, glass=[-0.75, -0.12, 0.85, 1.4],
        hood=[0.78, 0.86], trunk=[0.88, 0.85], wheel_z=[-1.40, 1.40], track=1.47, tyre_r=0.33, tyre_w=0.185,
        rim_r=0.18, b_pillar=0.37, quad=False, paint=(0.04, 0.04, 0.045), tumble=0.26, front_panel=0.76,
        tail="corner",
    ),
}

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
OBJS = []


def mat(name, color, rough=0.5, metal=0.0, alpha=1.0, emit=0.0):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = metal
    if emit:
        bs.inputs["Emission Color"].default_value = (*color, 1.0)
        bs.inputs["Emission Strength"].default_value = emit
    if alpha < 1.0:
        bs.inputs["Alpha"].default_value = alpha
    return m


def finish(name, bm, material, smooth=True, angle=40.0, recalc=True):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    if recalc:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    me.materials.append(material)
    for p in me.polygons:
        p.use_smooth = smooth
    if smooth:
        me.set_sharp_from_angle(angle=math.radians(angle))
    OBJS.append(ob)
    return ob


def apply_mods(ob):
    for o in bpy.data.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def boolean(ob, cutter, op="DIFFERENCE"):
    m = ob.modifiers.new("bool", "BOOLEAN")
    m.operation = op
    m.solver = "EXACT"
    m.object = cutter
    keep = ob.data.materials[0]
    apply_mods(ob)
    # the cut faces come in with the cutter's material: give them the body's
    ob.data.materials.clear()
    ob.data.materials.append(keep)
    for p in ob.data.polygons:
        p.material_index = 0


def remove(ob):
    if ob in OBJS:
        OBJS.remove(ob)
    bpy.data.objects.remove(ob, do_unlink=True)


def loft(name, rings, material, closed=True, cap=True, smooth=True, angle=40.0):
    """Faces between consecutive rings (lists of Vectors, same length)."""
    bm = bmesh.new()
    vr = [[bm.verts.new(p) for p in r] for r in rings]
    n = len(rings[0])
    for a, b in zip(vr, vr[1:]):
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if cap:
        bm.faces.new(vr[0][::-1])
        bm.faces.new(vr[-1])
    return finish(name, bm, material, smooth, angle)


def box(name, center, size, material, rot=None, bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    m = Matrix.Diagonal((*size, 1.0))
    if rot is not None:
        m = rot.to_4x4() @ m
    m.translation = Vector(center)
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
    ob = finish(name, bm, material, smooth=False)
    if bevel > 0:
        b = ob.modifiers.new("b", "BEVEL")
        b.width = bevel
        b.segments = 3
        b.limit_method = "ANGLE"
        apply_mods(ob)
        for p in ob.data.polygons:
            p.use_smooth = True
        ob.data.set_sharp_from_angle(angle=math.radians(50))
    return ob


def lathe(name, prof, material, xf, seg=32, smooth=True, angle=50.0):
    """Surface of revolution round local +y; prof = [(r, y), ...]."""
    bm = bmesh.new()
    rings = []
    for r, y in prof:
        rings.append([bm.verts.new(xf @ Vector((r * math.cos(2 * math.pi * i / seg), y, r * math.sin(2 * math.pi * i / seg))))
                      for i in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            try:
                bm.faces.new((a[i], a[j], b[j], b[i]))
            except ValueError:
                pass
    return finish(name, bm, material, smooth, angle)


def tube(name, pts, r, material, sides=8, closed=False):
    """A round tube along points (for chrome strips and frames)."""
    rings = []
    n = len(pts)
    for i, p in enumerate(pts):
        if closed:
            d = (pts[(i + 1) % n] - pts[i - 1]).normalized()
        else:
            d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        a = d.cross(Vector((0, 1, 0)))
        if a.length < 1e-3:
            a = d.cross(Vector((1, 0, 0)))
        a.normalize()
        b = d.cross(a).normalized()
        rings.append([p + (a * math.cos(2 * math.pi * k / sides) + b * math.sin(2 * math.pi * k / sides)) * r
                      for k in range(sides)])
    if closed:
        rings.append(rings[0])
    return loft(name, rings, material, closed=True, cap=not closed, smooth=True, angle=80)


def prism(name, poly, axis_from, axis_to):
    """A cutter: the polygon (list of Vectors, in a plane) swept from
    axis_from to axis_to (offsets added to every point)."""
    bm = bmesh.new()
    a = [bm.verts.new(p + axis_from) for p in poly]
    b = [bm.verts.new(p + axis_to) for p in poly]
    n = len(poly)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.faces.new(a[::-1])
    bm.faces.new(b)
    return finish(name, bm, mat("cutter", (1, 0, 1)), smooth=False)


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def build(key):
    s = CARS[key]
    L, hw, belt, roof = s["length"], s["hw"], s["belt"], s["roof"]
    g0, g1, g2, g3 = s["glass"]
    zf, zr = -L / 2, L / 2
    paint = mat("body", s["paint"], rough=0.3)
    chrome = mat("chrome", (0.85, 0.85, 0.85), rough=0.12, metal=1.0)
    black = mat("black", (0.03, 0.03, 0.03), rough=0.6)
    glass = mat("glass", (0.1, 0.12, 0.13), rough=0.05, alpha=0.4)
    lamp = mat("lamp", (0.9, 0.9, 0.85), rough=0.05)
    tail = mat("tail", (0.6, 0.03, 0.02), rough=0.15)
    amber = mat("amber", (0.9, 0.45, 0.05), rough=0.15)
    reverse = mat("reverse", (0.9, 0.9, 0.9), rough=0.15)
    plate = mat("plate", (1, 1, 1), rough=0.5)
    tyre = mat("tyre", (0.025, 0.025, 0.025), rough=0.85)
    rim = mat("rim", (0.35, 0.35, 0.35), rough=0.4, metal=0.5)
    inside = mat("inside", (0.08, 0.07, 0.065), rough=0.7)
    seatm = mat("seat", (0.3, 0.22, 0.16), rough=0.9)
    hl = L / 2

    # ---------------------------------------------------------- lower body --
    def width(z):
        # plan view: the flanks nearly straight, rounding in at both ends
        e = max(0.0, (abs(z) - (hl - 0.35)) / 0.35)
        return hw - 0.035 * e * e

    def top(z):
        if z < g0:      # bonnet: rising gently from the nose to the scuttle
            t = (z - zf) / (g0 - zf)
            return s["hood"][0] + (s["hood"][1] - s["hood"][0]) * (1 - (1 - t) ** 2)
        if z > g3:      # boot lid, flat, falling a touch to the tail
            t = (z - g3) / (zr - g3)
            return s["trunk"][0] + (s["trunk"][1] - s["trunk"][0]) * t
        return belt

    def bottom(z):
        e = max(0.0, (abs(z) - (hl - 0.3)) / 0.3)
        return s["sill"] + 0.14 * e

    def section(z, w, t, b, nose=1.0):
        """Right half from the bottom centre round to the top centre, then
        the left half back down: flat flank, crisp shoulder, sill tuck."""
        h = t - b
        right = [
            (0.0, b), (w - 0.12, b), (w - 0.05, b + 0.015), (w - 0.015, b + 0.06), (w - 0.002, b + 0.13),
            (w + 0.006, b + h * 0.45), (w + 0.009, b + h * 0.62),           # the waist bulge
            (w + 0.004, t - 0.13), (w + 0.006, t - 0.12),                     # character line
            (w, t - 0.05), (w - 0.006, t - 0.022), (w - 0.022, t - 0.006), (w - 0.05, t),
            (w * 0.5, t + 0.006 * nose), (0.0, t + 0.008 * nose),
        ]
        left = [(-x, y) for x, y in reversed(right[1:-1])]
        return [Vector((x, y, z)) for x, y in right + left]

    zs = []
    z = zf
    while z < zr:
        zs.append(z)
        z += 0.04
    zs.append(zr)
    rings = []
    for z in zs:
        rings.append(section(z, width(z), top(z), bottom(z)))
    # Round the nose and the tail in side view: the last rings shrink.
    for k, f in enumerate([0.985, 0.995]):
        for r_, z0 in ((rings[k], zs[k]), (rings[-1 - k], zs[-1 - k])):
            cy = sum(p.y for p in r_) / len(r_)
            for p in r_:
                p.y = cy + (p.y - cy) * f
                p.x *= f
    body = loft("body", rings, paint)

    # Wheel arches: cut, then a black liner inside each.
    for wz in s["wheel_z"]:
        c = lathe("arch_cut", [(0.0, -1.2), (s["tyre_r"] + 0.05, -1.2), (s["tyre_r"] + 0.05, 1.2), (0.0, 1.2)], paint,
                  Matrix.Translation((0, s["tyre_r"], wz)) @ Matrix.Rotation(math.radians(90), 4, "Z"), seg=48)
        boolean(body, c)
        remove(c)
        for sx in (-1, 1):
            r0 = s["tyre_r"] + 0.045
            xf = Matrix.Translation((sx * (hw - 0.14), s["tyre_r"], wz)) @ Matrix.Rotation(math.radians(90), 4, "Z")
            pts = []
            for i in range(25):
                a = math.radians(-10 + 200 * i / 24)
                pts.append(Vector((r0 * math.cos(a), 0, r0 * math.sin(a))))
            bm = bmesh.new()
            v0 = [bm.verts.new(xf @ (p + Vector((0, -0.14, 0)))) for p in pts]
            v1 = [bm.verts.new(xf @ (p + Vector((0, 0.14, 0)))) for p in pts]
            for i in range(24):
                bm.faces.new((v0[i], v0[i + 1], v1[i + 1], v1[i]))
            finish("black_liner", bm, black)
    # The cabin: hollowed out between the scuttle and the rear seat.
    cab = box("cab_cut", (0, (0.33 + 1.3) / 2, (g0 + 0.03 + g3 - 0.03) / 2), (2 * (hw - 0.045), 1.3 - 0.33, g3 - g0 - 0.06), paint)
    boolean(body, cab)
    remove(cab)

    # ----------------------------------------------------------- greenhouse --
    def roof_y(z):
        """Side-view outline of the glasshouse top."""
        if z <= g1:
            t = (z - g0) / (g1 - g0)
            y = belt + (roof - belt) * t
            # round over into the roof
            k = smoothstep(g1 - 0.12, g1 + 0.06, z)
            return y * (1 - k) + roof * k if k > 0 else y
        if z >= g2:
            t = (z - g2) / (g3 - g2)
            y = roof + (belt - roof) * t
            k = 1 - smoothstep(g2 - 0.06, g2 + 0.14, z)
            return y * (1 - k) + roof * k if k > 0 else y
        m = (g1 + g2) / 2
        return roof + 0.012 * (1 - ((z - m) / ((g2 - g1) / 2)) ** 2)

    def ws_z(y, rear=False):
        """z of the windscreen (or rear window) line at height y."""
        if rear:
            return g3 + (g2 - g3) * (y - belt) / (roof - belt)
        return g0 + (g1 - g0) * (y - belt) / (roof - belt)

    tumble = s["tumble"]

    def gsec(z, inset=0.0):
        wb = width(z) - 0.03 - inset
        ty = max(roof_y(z) - inset, belt + 0.004)
        h = ty - belt
        wt = wb - h * tumble
        right = [(wb, belt - 0.02), (wb, belt), (wb - (h - 0.04) * tumble if h > 0.04 else wb, max(ty - 0.04, belt + 0.002)),
                 (wt + 0.012, ty - 0.012), (wt - 0.02, ty), (wt * 0.5, ty + 0.01 * min(1, h / 0.3)),
                 (0.0, ty + 0.012 * min(1, h / 0.3))]
        left = [(-x, y) for x, y in reversed(right[:-1])]
        return [Vector((x, y, z)) for x, y in right + left]

    gzs = []
    z = g0
    while z < g3:
        gzs.append(z)
        z += 0.03
    gzs.append(g3)
    gh = loft("gh", [gsec(z) for z in gzs], paint, closed=False, cap=False)
    sol = gh.modifiers.new("s", "SOLIDIFY")
    sol.thickness = 0.03
    sol.offset = -1.0
    apply_mods(gh)
    glass_ob = loft("glass", [gsec(z, 0.012) for z in gzs], glass, closed=False, cap=False)

    # Side windows: the front door glass from the A-pillar to the B-pillar,
    # the rear one from there to the C-pillar.
    def side_poly(z0, z1, front_pillar, rear_pillar, top_in=0.055):
        pts = []
        N = 24
        # bottom edge, front to back
        yb = belt + 0.02
        za = ws_z(yb) + front_pillar if front_pillar is not None else z0
        zb = ws_z(yb, True) - rear_pillar if rear_pillar is not None else z1
        pts.append(Vector((0, yb, za)))
        pts.append(Vector((0, yb, zb)))
        # up the back edge
        if rear_pillar is not None:
            for i in range(1, N):
                y = yb + (roof - top_in - yb) * i / N
                zz = ws_z(y, True) - rear_pillar
                if roof_y(zz) - top_in < y:
                    break
                pts.append(Vector((0, y, zz)))
        else:
            pts.append(Vector((0, roof_y(z1) - top_in, z1)))
        # along the top, back to front
        zt0 = pts[-1].z
        if front_pillar is not None:
            for i in range(N + 1):
                y = yb + (roof - top_in - yb) * i / N
                zz = ws_z(y) + front_pillar
                if roof_y(zz) - top_in < y:
                    break
            zt1 = zz
        else:
            zt1 = z0
        for i in range(1, N):
            zz = zt0 + (zt1 - zt0) * i / N
            pts.append(Vector((0, roof_y(zz) - top_in, zz)))
        if front_pillar is not None:
            for i in range(N, -1, -1):
                y = yb + (roof - top_in - yb) * i / N
                zz = ws_z(y) + front_pillar
                if zz >= zt1 - 1e-4 and roof_y(zz) - top_in < y:
                    continue
                if zz < pts[-1].z - 1e-4 or y < pts[-1].y - 1e-4:
                    pts.append(Vector((0, y, zz)))
        else:
            pts.append(Vector((0, roof_y(z0) - top_in, z0)))
        return pts

    bp = s["b_pillar"]
    polys = [side_poly(None, bp - 0.035, 0.09, None), side_poly(bp + 0.035, None, None, 0.13)]
    frames = []
    for poly in polys:
        c = prism("win_cut", poly, Vector((-1.2, 0, 0)), Vector((1.2, 0, 0)))
        boolean(gh, c)
        remove(c)
        frames.append(poly)
    # Windscreen and rear window: cut along their own normals.
    for rear in (False, True):
        za, zb = (g0, g1) if not rear else (g3, g2)
        up = Vector((0, roof - belt, zb - za)).normalized()
        nrm = Vector((1, 0, 0)).cross(up).normalized()
        if rear:
            nrm = -nrm
        foot = Vector((0, belt, za))
        ln = (Vector((0, roof, zb)) - foot).length
        poly = []
        for i in range(17):
            v = 0.05 + (ln - 0.12) * i / 16
            p = foot + up * v
            w_ = width(p.z) - 0.03 - (p.y - belt) * tumble - 0.075
            poly.append(p + Vector((w_, 0, 0)))
        for i in range(16, -1, -1):
            v = 0.05 + (ln - 0.12) * i / 16
            p = foot + up * v
            w_ = width(p.z) - 0.03 - (p.y - belt) * tumble - 0.075
            poly.append(p + Vector((-w_, 0, 0)))
        c = prism("ws_cut", poly, -nrm * 0.3, nrm * 0.3)
        boolean(gh, c)
        remove(c)
        # chrome surround of the windscreen / rear window
        frame = [p + nrm * 0.004 for p in poly]
        tube("chrome_ws", frame, 0.007, chrome, closed=True)
    gh.name = "body_gh"

    # --------------------------------------------------------- side details --
    def surf_x(z, y):
        """x of the right flank (or glasshouse side) at (z, y)."""
        if y > belt:
            h = y - belt
            return width(z) - 0.03 - h * tumble
        t_, b_ = top(z), bottom(z)
        return width(z) + 0.006 * math.sin(math.pi * max(0.0, min(1.0, (y - b_) / max(t_ - b_, 0.1))))

    for poly in frames:
        for sx in (-1, 1):
            pts = [Vector((sx * (surf_x(p.z, p.y) + 0.004), p.y, p.z)) for p in poly]
            tube("chrome_win", pts, 0.006, chrome, closed=True)
    for sx in (-1, 1):
        # drip rail along the roof edge
        pts = []
        z = ws_z(roof - 0.05) + 0.05
        while z < ws_z(roof - 0.05, True) - 0.05:
            y = roof_y(z) - 0.01
            pts.append(Vector((sx * (surf_x(z, y) - 0.0), y, z)))
            z += 0.05
        tube("chrome_drip", pts, 0.008, chrome)
        # belt moulding and the side moulding with its black insert
        tube("chrome_belt", [Vector((sx * (width(z) - 0.022), belt + 0.006, z)) for z in
                             [g0 + 0.02 + (g3 - g0 - 0.04) * i / 20 for i in range(21)]], 0.006, chrome)
        f_end = s["wheel_z"][0] + s["tyre_r"] + 0.07
        r_start = s["wheel_z"][1] - s["tyre_r"] - 0.07
        my = 0.60
        for za, zb in ((f_end, r_start), (zf + 0.25, s["wheel_z"][0] - s["tyre_r"] - 0.07), (s["wheel_z"][1] + s["tyre_r"] + 0.07, zr - 0.25)):
            pts = [Vector((sx * (surf_x(z, my) + 0.004), my, z)) for z in [za + (zb - za) * i / 20 for i in range(21)]]
            tube("chrome_side", pts, 0.009, chrome)
            pts = [Vector((sx * (surf_x(z, my) + 0.011), my, z)) for z in [za + (zb - za) * i / 20 for i in range(21)]]
            tube("black_side", pts, 0.005, black)
        # panel gaps: door edges, B-pillar
        dz = [g0 + 0.06, bp - 0.04, bp + 0.04, s["wheel_z"][1] - s["tyre_r"] - 0.1]
        for k, z in enumerate(dz):
            y0 = s["sill"] + 0.06
            y1 = belt - 0.005
            if k == 3:
                y0 = s["tyre_r"] * 2 + 0.06
            pts = [Vector((sx * (surf_x(z, y) + 0.0015), y, z)) for y in [y0 + (y1 - y0) * i / 12 for i in range(13)]]
            tube("black_gap", pts, 0.0025, black, sides=6)
        # bottom of the doors
        pts = [Vector((sx * (surf_x(z, s["sill"] + 0.06) + 0.0015), s["sill"] + 0.06, z)) for z in
               [dz[0] + (dz[3] - dz[0]) * i / 16 for i in range(17)]]
        tube("black_gap", pts, 0.0025, black, sides=6)
        # rear door's back edge down round the arch
        # door handles
        for z in (bp - 0.16, dz[3] - 0.12):
            box("chrome_handle", (sx * (width(z) + 0.02), belt - 0.11, z), (0.025, 0.022, 0.13), chrome, bevel=0.006)
            box("black_handle", (sx * (width(z) + 0.008), belt - 0.11, z), (0.012, 0.03, 0.15), black)
        # the quarter light's post
        z = ws_z(belt + 0.02) + 0.09 + 0.33
        pts = [Vector((sx * (surf_x(z, y) - 0.005), y, z)) for y in [belt + 0.02, roof_y(z) - 0.06]]
        tube("chrome_vent", pts, 0.007, chrome)
        # fuel filler on the right rear wing
    box("chrome_filler", (hw + 0.004, top(zr - 0.6) - 0.16, zr - 0.6), (0.01, 0.09, 0.09), chrome, bevel=0.01)
    # mirror on the driver's door
    mz = g0 + 0.18
    base = Vector((-(width(mz) + 0.01), belt + 0.02, mz))
    tube("chrome_mirror", [base, base + Vector((-0.06, 0.07, 0.01))], 0.008, chrome)
    lathe("chrome_mirror", [(0.0, -0.03), (0.055, -0.02), (0.06, 0.0), (0.0, 0.002)], chrome,
          Matrix.Translation(base + Vector((-0.09, 0.1, 0.02))) @ Matrix.Rotation(math.radians(90), 4, "X"), seg=24)
    lathe("glass_mirror", [(0.0, 0.003), (0.054, 0.003)], glass,
          Matrix.Translation(base + Vector((-0.09, 0.1, 0.02))) @ Matrix.Rotation(math.radians(90), 4, "X"), seg=24)
    # bonnet and boot lid gaps
    for z0, z1, yy in ((zf + 0.06, g0 - 0.03, None), (g3 + 0.03, zr - 0.06, None)):
        for sx in (-1, 1):
            pts = [Vector((sx * (width(z) - 0.06), top(z) + 0.004, z)) for z in [z0 + (z1 - z0) * i / 24 for i in range(25)]]
            tube("black_gap", pts, 0.0025, black, sides=6)
        for z in (z0, z1):
            pts = [Vector((x, top(z) + 0.004, z)) for x in [-(width(z) - 0.06) + 2 * (width(z) - 0.06) * i / 16 for i in range(17)]]
            tube("black_gap", pts, 0.0025, black, sides=6)
    # wipers parked at the foot of the windscreen (the driver's one is the
    # game's own, so it can sweep)
    for x0 in (0.18,):
        p0 = Vector((x0, s["hood"][1] + 0.03, g0 + 0.02))
        tube("black_wiper", [p0, p0 + Vector((-0.45, 0.02, 0.02))], 0.006, black)

    # ---------------------------------------------------------------- front --
    fz = zf - 0.005
    fp = s["front_panel"]
    box("black_grille", (0, (0.42 + fp) / 2, fz + 0.012), (2 * (hw - 0.08), fp - 0.42, 0.03), black)
    lamp_y = 0.60
    if s["quad"]:
        lx = [hw - 0.2, hw - 0.4]
        lr = 0.075
        for i in range(7):
            box("chrome_bar", (0, 0.47 + i * 0.04, fz - 0.006), (2 * (hw - 0.52), 0.008, 0.01), chrome)
        box("chrome_grille", (0, fp - 0.012, fz - 0.004), (2 * (hw - 0.08), 0.016, 0.014), chrome)
        box("chrome_grille", (0, 0.43, fz - 0.004), (2 * (hw - 0.08), 0.012, 0.014), chrome)
    else:
        lx = [hw - 0.17]
        lr = 0.09
        for i in range(17):
            box("chrome_bar", (-0.5 + i * 1.0 / 16, (0.45 + 0.72) / 2, fz - 0.01), (0.012, 0.27, 0.02), chrome)
        tube("chrome_grille", [Vector((x, y, fz - 0.015)) for x, y in [(-0.53, 0.44), (0.53, 0.44), (0.53, 0.73), (-0.53, 0.73)]],
             0.012, chrome, closed=True)
    for sx in (-1, 1):
        for x in lx:
            c = Vector((sx * x, lamp_y, fz - 0.005))
            xf = Matrix.Translation(c) @ Matrix.Rotation(math.radians(-90), 4, "X")
            lathe("chrome_bezel", [(lr - 0.005, -0.012), (lr + 0.012, -0.004), (lr + 0.016, 0.006), (lr + 0.008, 0.016), (lr - 0.004, 0.01)], chrome, xf)
            lathe("lamp", [(0.0, 0.022), (lr * 0.5, 0.019), (lr - 0.004, 0.006)], lamp, xf)
        # indicators under the lamps
        box("amber_front", (sx * (hw - 0.3), 0.36, fz + 0.02), (0.16, 0.05, 0.02), amber)
    box("chrome_badge", (0, fp - 0.05, fz - 0.016), (0.07, 0.04, 0.008), chrome, bevel=0.004)

    # bumpers: chrome, wrapping round the corners, a black rubber strip, two
    # overriders
    def bumper(zc, sgn, yb):
        rows = []
        for i in range(33):
            x = -hw - 0.01 + (2 * hw + 0.02) * i / 32
            e = max(0.0, (abs(x) - (hw - 0.25)) / 0.26)
            z = zc + sgn * (0.17 * e * e)
            rows.append((x, z))
        prof = [(0.0, 0.0), (-0.04, 0.0), (-0.055, 0.03), (-0.058, 0.065), (-0.05, 0.1), (-0.03, 0.115), (0.0, 0.115)]
        rings = []
        for x, z in rows:
            rings.append([Vector((x, yb + py, z + sgn * pz)) for pz, py in prof])
        ob = loft("chrome_bumper", list(map(list, zip(*rings))), chrome, closed=False, cap=False, angle=60)
        pts = [Vector((x, yb + 0.058, z + sgn * 0.06)) for x, z in rows[3:-3]]
        tube("black_bumper", pts, 0.012, black)
        for sx in (-0.38, 0.38):
            box("chrome_overrider", (sx, yb + 0.05, zc + sgn * 0.065), (0.06, 0.2, 0.05), chrome, bevel=0.018)
            box("black_overrider", (sx, yb + 0.07, zc + sgn * 0.09), (0.03, 0.12, 0.02), black, bevel=0.006)
        return ob

    bumper(zf - 0.02, 1, 0.27)
    bumper(zr + 0.02, -1, 0.27)
    # plates
    for zz, yy, flip in ((zf - 0.085, 0.24, True), (zr + 0.004, 0.53, False)):
        bm = bmesh.new()
        w_, h_ = 0.26, 0.06
        q = [Vector((-w_, yy - h_, zz)), Vector((w_, yy - h_, zz)), Vector((w_, yy + h_, zz)), Vector((-w_, yy + h_, zz))]
        if flip:
            q = [Vector((-p.x, p.y, p.z)) for p in q]
        vs = [bm.verts.new(p) for p in q]
        # bottom left, bottom right, top right, top left as seen from outside
        f = bm.faces.new(vs)
        uvl = bm.loops.layers.uv.new()
        for lp, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
            lp[uvl].uv = uv
        pob = finish("plate", bm, plate, smooth=False, recalc=False)
        box("black_plate", (0, yy, zz + (0.006 if flip else -0.006)), (0.54, 0.13, 0.008), black)

    # ----------------------------------------------------------------- rear --
    rz = zr + 0.004
    ty0, ty1 = (0.58, 0.72)
    for sx in (-1, 1):
        if s["tail"] == "wide":
            x0, x1 = 0.24, hw - 0.06
            box("chrome_tailframe", (sx * (x0 + x1) / 2, (ty0 + ty1) / 2, rz - 0.002), (x1 - x0 + 0.03, ty1 - ty0 + 0.03, 0.012), chrome)
            seg = [(x0, x0 + 0.1, "reverse"), (x0 + 0.1, x0 + 0.22, "amber"), (x0 + 0.22, x1, "tail")]
            for a, b, kind in seg:
                box(kind + "_rear", (sx * (a + b) / 2, (ty0 + ty1) / 2, rz + 0.006), (b - a - 0.008, ty1 - ty0 - 0.01, 0.012),
                    {"reverse": reverse, "amber": amber, "tail": tail}[kind])
        else:
            x0, x1 = hw - 0.32, hw - 0.05
            box("chrome_tailframe", (sx * (x0 + x1) / 2, (ty0 + ty1) / 2, rz - 0.002), (x1 - x0 + 0.03, ty1 - ty0 + 0.03, 0.012), chrome)
            box("tail_rear", (sx * (x0 + x1 + 0.08) / 2, (ty0 + ty1) / 2, rz + 0.006), (x1 - x0 - 0.09, ty1 - ty0 - 0.01, 0.012), tail)
            box("amber_rear", (sx * (x0 + 0.04), (ty0 + ty1) / 2, rz + 0.006), (0.07, ty1 - ty0 - 0.01, 0.012), amber)
    box("chrome_trim", (0, ty1 - 0.01, rz + 0.004), (0.46, 0.02, 0.012), chrome)
    tube("black_exhaust", [Vector((0.45, 0.22, zr - 0.2)), Vector((0.45, 0.22, zr + 0.06))], 0.025, black)

    # --------------------------------------------------------------- wheels --
    R, W, rr = s["tyre_r"], s["tyre_w"], s["rim_r"]
    for wz in s["wheel_z"]:
        for sx in (-1, 1):
            xf = Matrix.Translation((sx * s["track"] / 2, R, wz)) @ Matrix.Rotation(math.radians(-90 * sx), 4, "Z")
            # tyre: tread with grooves, rounded shoulders, bulging sidewalls
            prof = [(rr + 0.01, -W / 2 + 0.01)]
            for i in range(9):
                a = math.pi * (i / 8)
                prof.append((rr + 0.02 + (R - rr - 0.03) * (0.5 - 0.5 * math.cos(a)), -W / 2 - 0.005 * math.sin(a)))
            for i in range(11):
                yy = -W / 2 + 0.01 + (W - 0.02) * i / 10
                prof.append((R - (0.004 if i % 2 else 0.0), yy))
            for i in range(9):
                a = math.pi * (i / 8)
                prof.append((R - 0.01 - (R - rr - 0.03) * (0.5 - 0.5 * math.cos(a)), W / 2 + 0.005 * math.sin(a)))
            prof.append((rr + 0.01, W / 2 - 0.01))
            lathe("tyre", prof, tyre, xf, seg=48, angle=35)
            # steel rim, dished, with a chrome trim ring and the hubcap
            lathe("rim", [(rr + 0.012, W / 2 - 0.01), (rr, W / 2 - 0.02), (rr - 0.02, W / 2 - 0.05), (0.06, W / 2 - 0.06),
                          (0.0, W / 2 - 0.06)], rim, xf, seg=32)
            lathe("chrome_ring", [(rr + 0.012, W / 2 - 0.006), (rr - 0.005, W / 2 - 0.004), (rr - 0.03, W / 2 - 0.022)], chrome, xf, seg=32)
            lathe("chrome_cap", [(0.11 if s["quad"] else 0.14, W / 2 - 0.05), (0.1 if s["quad"] else 0.13, W / 2 - 0.03),
                                 (0.06, W / 2 - 0.012), (0.0, W / 2 - 0.008)], chrome, xf, seg=32)

    # ---------------------------------------------- inside (the «Волга» only) --
    if key == "volga":
        box("inside_dash", (0, belt - 0.08, g0 + 0.2), (2 * (hw - 0.08), 0.2, 0.35), inside, bevel=0.03)
        for sx in (-0.4, 0.4):
            box("seat_cushion", (sx, 0.45, 0.25), (0.55, 0.14, 0.5), seatm, bevel=0.03)
            box("seat_back", (sx, 0.75, 0.5), (0.55, 0.6, 0.12), seatm, rot=Matrix.Rotation(-0.2, 3, "X"), bevel=0.03)
        box("seat_rear", (0, 0.45, 1.05), (2 * (hw - 0.12), 0.14, 0.5), seatm, bevel=0.03)
        box("seat_rearback", (0, 0.72, 1.25), (2 * (hw - 0.12), 0.5, 0.12), seatm, rot=Matrix.Rotation(-0.25, 3, "X"), bevel=0.03)
        lathe("inside_wheel", [(0.19, -0.01), (0.2, 0.0), (0.19, 0.01), (0.18, 0.0), (0.19, -0.01)], inside,
              Matrix.Translation((-0.4, belt - 0.02, g0 + 0.45)) @ Matrix.Rotation(math.radians(-62), 4, "X"), seg=24)


def uv_box(ob, scale=0.5):
    """World-space box projection, so the paint wear keeps its size."""
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new()
    uv = me.uv_layers.active
    for p in me.polygons:
        n = p.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for li in p.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            if ax == 0:
                u, v = co.z, co.y
            elif ax == 1:
                u, v = co.x, co.z
            else:
                u, v = co.x, co.y
            uv.data[li].uv = (u * scale, v * scale)


def export(key, path):
    # join everything by name prefix into one object per material kind
    groups = {}
    for ob in list(OBJS):
        if ob.name.startswith("cutter"):
            continue
        kind = ob.name.split("_")[0].split(".")[0]
        groups.setdefault(kind, []).append(ob)
    for kind, obs in groups.items():
        for o in bpy.data.objects:
            o.select_set(False)
        for o in obs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = obs[0]
        if len(obs) > 1:
            bpy.ops.object.join()
        ob = bpy.context.view_layer.objects.active
        ob.name = kind
        ob.data.name = kind
        if kind != "plate":
            uv_box(ob, 0.5 if kind != "seat" else 2.0)
    # game frame (y up, -z forward) to Blender's Z-up: +90 deg about X
    rot = Matrix.Rotation(math.radians(90), 4, "X")
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            ob.data.transform(rot)
            ob.data.update()
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True,
                              export_image_format="NONE", export_skins=False, export_animations=False)


def preview(key, out):
    rot = Matrix.Rotation(math.radians(90), 4, "X")
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            ob.data.transform(rot)
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens = ARGS.get("lens", 50)
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    eye = Vector(ARGS.get("eye", [-4.5, -5.5, 1.6]))   # Blender frame: +y is the nose
    look = Vector(ARGS.get("look", [0, 0, 0.6]))
    cam.location = eye
    cam.rotation_euler = (look - eye).to_track_quat("-Z", "Y").to_euler()
    w = bpy.data.worlds.new("w")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.55, 0.6, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    sc.world = w
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 3.0
    so = bpy.data.objects.new("sun", sun)
    sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(50), 0, math.radians(30))
    bpy.ops.mesh.primitive_plane_add(size=30)
    bpy.context.active_object.data.materials.append(mat("ground", (0.15, 0.15, 0.15), rough=0.8))
    sc.render.engine = "CYCLES"
    sc.cycles.samples = ARGS.get("samples", 16)
    sc.render.resolution_x, sc.render.resolution_y = ARGS.get("res", [1280, 720])
    sc.render.filepath = out
    sc.view_settings.view_transform = "AgX"
    bpy.ops.render.render(write_still=True)


if ARGS.get("export"):
    for key in ARGS.get("cars", list(CARS)):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        sc = bpy.context.scene
        OBJS.clear()
        build(key)
        os.makedirs(os.path.join(ROOT, "models/cars"), exist_ok=True)
        export(key, os.path.join(ROOT, "models/cars/%s.glb" % key))
        print("exported", key)
else:
    key = ARGS.get("car", "zhiguli")
    build(key)
    preview(key, ARGS.get("out", "/tmp/car.png"))
