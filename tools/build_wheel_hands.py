"""Poses Gordeev's hands on the steering wheel of his ВАЗ-2106 and bakes them,
with the wheel itself, into models/wheel_hands/wheel_hands.glb (the shots
from the driver's seat in the cutscenes).

Run with Blender's Python module (pip install bpy):
    python tools/build_wheel_hands.py -- '{"export": "models/wheel_hands/wheel_hands.glb"}'
Without "export" it renders a preview from the driver's eye to "out".

The wheel is the «шестёрка»'s: a thin black rim, two spokes dropping to a
long horn bar with the chrome VAZ boat in the middle. The hand is
models/hand/Hand_Nails_R.gltf (Godot XR Tools, CC0). The right hand takes
the rim at two o'clock: the rim runs across the palm, each finger closes
joint by joint until its skin rests on the rim, the thumb lies along the
rim towards twelve, then a coat sleeve runs from the wrist towards the
elbow. The left hand is the right one mirrored to ten o'clock.

Frame (Blender, Z up): the rim lies in the XZ plane round the origin, the
driver sits on the -Y side, twelve o'clock is +Z. glTF turns that into
Godot's frame: the rim in XY, the driver on +Z, twelve o'clock +Y.
"""
import bpy, bmesh, math, sys, json, os
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

ARGS = json.loads(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else {}
P = dict(R=0.19, r=0.0125, phi=28.0, a=18.0, beta=35.0, px=-0.031, py=0.072, pz=0.0, twist=0.0,
         arm=[0.25, -0.8, -0.55], arm_mix=0.7, cuff=-0.01, thumb_ang=200.0, thumb_r=0.022,
         out="/tmp/wheel_hands.png", res=[960, 540], samples=24, export="")
P.update(ARGS)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HAND = os.path.join(ROOT, "models/hand/")
R, RT = P["R"], P["r"]

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def mat(name, color, rough=0.5, metal=0.0, tex=None, normal=None, orm=None, nscale=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = metal
    if tex:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(tex)
        nt.links.new(t.outputs["Color"], bs.inputs["Base Color"])
    if orm:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(orm)
        t.image.colorspace_settings.name = "Non-Color"
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(t.outputs["Color"], sep.inputs["Color"])
        nt.links.new(sep.outputs["Green"], bs.inputs["Roughness"])
    if normal:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(normal)
        t.image.colorspace_settings.name = "Non-Color"
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nm.inputs["Strength"].default_value = nscale
        nt.links.new(t.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bs.inputs["Normal"])
    return m


def mesh_obj(name, bm, material, smooth=True):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    for p in me.polygons:
        p.use_smooth = smooth
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    me.materials.append(material)
    return ob


# ---------------------------------------------------------------- wheel ----
bakelite = mat("wheel_black", (0.03, 0.03, 0.03), rough=0.38)
chrome = mat("wheel_chrome", (0.8, 0.8, 0.78), rough=0.15, metal=1.0)
parts = []


def rim():
    """The rim: a torus, slightly oval in section, with finger grips moulded
    on its inner side (a bump every 3.5 degrees)."""
    bm = bmesh.new()
    seg, sides = 240, 20
    grid = []
    for i in range(seg):
        u = 2 * math.pi * i / seg
        c, s_ = math.cos(u), math.sin(u)
        ring = []
        for j in range(sides):
            v = 2 * math.pi * j / sides
            # v = 0 outward, pi inward; the grips ripple the inner side
            grip = 0.0012 * max(0.0, -math.cos(v)) ** 2 * (0.5 + 0.5 * math.cos(u * 103))
            rr = RT + grip
            x = (R + rr * math.cos(v) * 0.95) * c
            z = (R + rr * math.cos(v) * 0.95) * s_
            y = rr * math.sin(v)
            ring.append(bm.verts.new((x, y, z)))
        grid.append(ring)
    for i in range(seg):
        a, b = grid[i], grid[(i + 1) % seg]
        for j in range(sides):
            k = (j + 1) % sides
            bm.faces.new((a[j], b[j], b[k], a[k]))
    return mesh_obj("wheel_rim", bm, bakelite)


def tube(name, pts, rad, material, sides=12):
    """A tube along the given points (for the spokes)."""
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        side = d.cross(Vector((0, 1, 0)))
        if side.length < 1e-4:
            side = Vector((1, 0, 0))
        side.normalize()
        up = side.cross(d).normalized()
        r_ = rad[i] if isinstance(rad, list) else rad
        ring = [bm.verts.new(p + side * math.cos(2 * math.pi * k / sides) * r_[0]
                             + up * math.sin(2 * math.pi * k / sides) * r_[1]) for k in range(sides)]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(sides):
            n = (k + 1) % sides
            bm.faces.new((a[k], b[k], b[n], a[n]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])
    return mesh_obj(name, bm, material)


parts.append(rim())
# Two spokes from the rim at about twenty past eight and twenty to four,
# dropping in towards the horn bar under the hub, flat in section.
for sx in (-1, 1):
    u = math.radians(-20 if sx > 0 else 200)
    a = Vector((math.cos(u) * (R - 0.004), 0.0, math.sin(u) * (R - 0.004)))
    b = Vector((sx * 0.07, 0.03, -0.045))
    pts = [a.lerp(b, t) + Vector((0, 0.012 * math.sin(math.pi * t), 0)) for t in [0, 0.25, 0.5, 0.75, 1.0]]
    parts.append(tube("wheel_spoke_%d" % sx, pts, [(0.016, 0.006), (0.015, 0.006), (0.015, 0.0065), (0.016, 0.007),
                                                   (0.018, 0.008)], bakelite))
# Horn bar: a long padded slab across the bottom of the hub.
bm = bmesh.new()
bmesh.ops.create_cube(bm, size=1.0)
for v in bm.verts:
    v.co = Vector((v.co.x * 0.17, v.co.y * 0.035 + 0.032, v.co.z * 0.06 - 0.04))
hb = mesh_obj("wheel_horn", bm, bakelite, smooth=False)
bv = hb.modifiers.new("b", "BEVEL")
bv.width = 0.012
bv.segments = 4
parts.append(hb)
# The boat of the VAZ badge on the horn bar, and the hub cap behind.
bm = bmesh.new()
bmesh.ops.create_cube(bm, size=1.0)
for v in bm.verts:
    v.co = Vector((v.co.x * 0.035, v.co.y * 0.004 + 0.0, v.co.z * 0.024 - 0.035))
badge = mesh_obj("wheel_badge", bm, chrome, smooth=False)
bv = badge.modifiers.new("b", "BEVEL")
bv.width = 0.004
bv.segments = 2
parts.append(badge)
bm = bmesh.new()
bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=0.03, radius2=0.026, depth=0.05)
for v in bm.verts:
    v.co = Vector((v.co.x, v.co.z + 0.06, v.co.y - 0.035))
parts.append(mesh_obj("wheel_hub", bm, bakelite))

bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
rim_ob = parts[0]
RIM_TREE = BVHTree.FromObject(rim_ob, dg)   # rim object is at the origin: local = world

# ----------------------------------------------------------------- hand ----
bpy.ops.import_scene.gltf(filepath=HAND + "Hand_Nails_R.gltf")
for o in list(bpy.data.objects):
    if o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o)
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
skin = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm][0]
skin.data.materials.clear()
skin.data.materials.append(mat("hand_skin", (1, 1, 1), tex=HAND + "hand_skin.png", normal=HAND + "hands_normal.png",
                               orm=HAND + "hands_occlusionRoughnessMetallic.png", nscale=0.6))

# The grip frame G at two o'clock: y along the rim towards twelve, z the
# way the back of the hand looks (at the driver and a little outwards).
phi = math.radians(P["phi"])
radial = Vector((math.cos(phi), 0, math.sin(phi)))
gy = Vector((-math.sin(phi), 0, math.cos(phi)))
beta = math.radians(P["beta"])
gz = (Vector((0, -1, 0)) * math.cos(beta) + radial * math.sin(beta)).normalized()
gz = (gz - gy * gz.dot(gy)).normalized()
gx = gy.cross(gz)
G = Matrix((gx, gy, gz)).transposed().to_4x4()
G.translation = radial * R
G = G @ Matrix.Rotation(math.radians(P["twist"]), 4, "Y")

# The rim in the hand's rest frame: runs across the palm (thumb side +z of
# the hand, towards twelve), lies on the palm side (-x) of the hand.
a = math.radians(P["a"])
ty = Vector((0, math.sin(a), math.cos(a)))
tz = Vector((1, 0, 0))
tx = ty.cross(tz)
T_in_H = Matrix((tx, ty, tz)).transposed().to_4x4()
T_in_H.translation = Vector((P["px"], P["py"], P["pz"]))
arm.matrix_world = G @ T_in_H.inverted()
bpy.context.view_layer.update()

vg_names = {g.index: g.name for g in skin.vertex_groups}
owner = {}
any_owner = {}
for v in skin.data.vertices:
    if v.groups:
        g = max(v.groups, key=lambda g: g.weight)
        if g.weight > 0.5:
            owner.setdefault(vg_names[g.group], []).append(v.index)
    for g in v.groups:
        if g.weight > 0.15:
            any_owner.setdefault(vg_names[g.group], []).append(v.index)


def verts_of(bone_names, table=None):
    t = table or owner
    out = []
    for n in bone_names:
        out += t.get(n, [])
    return out


def penetration(idx):
    """Smallest signed distance (m) of the given verts to the rim."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = skin.evaluated_get(dg)
    me = ev.to_mesh()
    mw = skin.matrix_world
    best = 1.0
    for i in idx:
        p = mw @ me.vertices[i].co
        loc, nrm, _, dist = RIM_TREE.find_nearest(p, 0.06)
        if loc is None:
            continue
        d = dist if (p - loc).dot(nrm) >= 0 else -dist
        best = min(best, d)
    ev.to_mesh_clear()
    return best


def set_curl(bones, angs):
    for b, g in zip(bones, angs):
        pb = arm.pose.bones[b]
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (0, 0, math.radians(g))
    bpy.context.view_layer.update()


chains = {f: ["%s_%s_R" % (f, j) for j in ("Proximal", "Intermediate", "Distal")]
          for f in ("Index", "Middle", "Ring", "Little")}
chains["Thumb"] = ["Thumb_Metacarpal_R", "Thumb_Proximal_R", "Thumb_Distal_R"]
log = {}
print("PALM", round(penetration(verts_of(["Wrist_R", "Palm_R"] + [x + "_Metacarpal_R" for x in
                                                                  ("Index", "Middle", "Ring", "Little")], any_owner)) * 1000, 2), "mm")
for f, bones in chains.items():
    if f == "Thumb":
        continue
    allv = verts_of(bones + ["%s_Tip_R" % f])
    tipv = verts_of([bones[2], "%s_Tip_R" % f])
    best, angs = -1.0, [0.0, 0.0, 0.0]
    for pa in range(0, 101, 5):
        for ia in range(0, 111, 5):
            cand = [float(pa), float(ia), ia * 0.67]
            set_curl(bones, cand)
            if penetration(allv) < 0.0004:
                continue
            dd = penetration(tipv)
            score = pa + ia + (300.0 if dd < 0.004 else 0.0)
            if score > best:
                best, angs = score, cand
    set_curl(bones, angs)
    log[f] = [round(x) for x in angs]
print("POSE", json.dumps(log))


def aim(bone, target_world):
    e = bpy.data.objects.new("aim_" + bone, None)
    sc.collection.objects.link(e)
    e.location = target_world
    bpy.context.view_layer.update()
    pb = arm.pose.bones[bone]
    c = pb.constraints.new("DAMPED_TRACK")
    c.target = e
    bpy.context.view_layer.update()
    m = pb.matrix.copy()
    pb.constraints.remove(c)
    pb.matrix = m
    bpy.context.view_layer.update()
    bpy.data.objects.remove(e)


def lay_thumb(r_):
    """Thumb along the rim towards twelve, resting on its driver's side."""
    ang = math.radians(P["thumb_ang"])
    for bone, drop in (("Thumb_Proximal_R", 0.0), ("Thumb_Distal_R", 0.003)):
        pb = arm.pose.bones[bone]
        h = G.inverted() @ (arm.matrix_world @ pb.head)
        rad = r_ - drop
        q = Vector((rad * math.cos(ang), 0, rad * math.sin(ang)))
        dxz = math.hypot(q.x - h.x, q.z - h.z)
        dy = math.sqrt(max(1e-6, pb.length ** 2 - dxz * dxz))
        aim(bone, G @ Vector((q.x, h.y + dy, q.z)))


tr_ = P["thumb_r"]
lay_thumb(tr_)
while penetration(verts_of(chains["Thumb"] + ["Thumb_Tip_R"])) < 0.0005 and tr_ < 0.06:
    tr_ += 0.001
    lay_thumb(tr_)
print("THUMB_R", round(tr_, 3))

worst = 1.0
for f, bones in chains.items():
    d = penetration(verts_of(bones + ["%s_Tip_R" % f], any_owner))
    print("DIAG", f, round(d * 1000, 2), "mm")
    worst = min(worst, d)
_dg = bpy.context.evaluated_depsgraph_get()
skin_tree = BVHTree.FromObject(skin, _dg)
to_skin = skin.matrix_world.inverted()
rim_in = 1.0
for v in rim_ob.data.vertices:
    loc, nrm, _, dist = skin_tree.find_nearest(to_skin @ v.co, 0.05)
    if loc is not None and ((to_skin @ v.co) - loc).dot(nrm) < 0:
        rim_in = min(rim_in, -dist)
print("DIAG rim-in-skin", round(rim_in * 1000, 2), "mm")


# --------------------------------------------------------------- sleeve ----
def sleeve(name):
    wrist = arm.matrix_world @ arm.pose.bones["Wrist_R"].head
    hb_ = arm.matrix_world.to_3x3().normalized()
    fa = -(hb_ @ Vector((0, 1, 0))).normalized()
    dirv = fa.slerp(Vector(P["arm"]).normalized(), P["arm_mix"])
    print("WRIST_BEND", round(math.degrees(dirv.angle(fa))))
    up = hb_ @ Vector((1, 0, 0))
    side = dirv.cross(up).normalized()
    up = side.cross(dirv).normalized()
    bm = bmesh.new()
    seg, rings = 40, 46
    L = 0.45
    grid = []
    import random
    random.seed(7)
    ph = [random.uniform(0, 6.28) for _ in range(8)]
    for k in range(rings):
        t = k / (rings - 1)
        s = t * L + P["cuff"]
        c = wrist + dirv * s
        ring = []
        for i in range(seg):
            th = 2 * math.pi * i / seg
            rx = 0.037 + 0.009 * min(1, t * 4) + 0.008 * t
            rz = 0.032 + 0.008 * min(1, t * 4) + 0.008 * t
            fold = (0.0035 * math.sin(s * 95 + 2.2 * math.sin(th + ph[0]) + ph[1]) * math.exp(-t * 2.5)
                    + 0.0016 * math.sin(th * 3 + s * 40 + ph[2])
                    + 0.0012 * math.sin(th * 5 - s * 25 + ph[3]))
            rr = 1.0 + fold / 0.04
            ring.append(bm.verts.new(c + side * (math.cos(th) * rx * rr) + up * (math.sin(th) * rz * rr)))
        grid.append(ring)
    for r0, r1 in zip(grid, grid[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
    inner = []
    for i in range(seg):
        th = 2 * math.pi * i / seg
        inner.append(bm.verts.new(wrist - dirv * 0.012 + side * (math.cos(th) * 0.035) + up * (math.sin(th) * 0.03)))
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((inner[i], inner[j], grid[0][j], grid[0][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    uv = me.uv_layers.new()
    for poly in me.polygons:
        poly.use_smooth = True
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            k, i = divmod(vi, seg)
            uv.data[li].uv = ((i / seg) * 4.0, (k / rings) * 6.0) if k < rings else ((i / seg) * 4.0, -0.1)
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    ob.data.materials.append(mat("coat_wool", (0.07, 0.075, 0.065), rough=0.95))
    return ob


sl = sleeve("sleeve_R")

# Bake the pose into the mesh and make the left hand: the right one
# mirrored across x = 0, so it holds ten o'clock.
bpy.context.view_layer.objects.active = skin
for o in bpy.data.objects:
    o.select_set(False)
skin.select_set(True)
bpy.ops.object.modifier_apply(modifier=skin.modifiers[0].name)
mw = skin.matrix_world.copy()
skin.parent = None
skin.matrix_world = mw
bpy.data.objects.remove(arm)
skin.name = "hand_R"
skin.data.name = "hand_R"
for o in parts:
    for m in list(o.modifiers):
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=m.name)


def mirrored(ob, name):
    c = ob.copy()
    c.data = ob.data.copy()
    c.name = name
    c.data.name = name
    sc.collection.objects.link(c)
    c.matrix_world = Matrix.Scale(-1, 4, Vector((1, 0, 0))) @ ob.matrix_world
    for o in bpy.data.objects:
        o.select_set(False)
    c.select_set(True)
    bpy.context.view_layer.objects.active = c
    # Applying the negative scale turns the faces the right way out itself.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return c


for o in (skin, sl):
    for oo in bpy.data.objects:
        oo.select_set(False)
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
hand_l = mirrored(skin, "hand_L")
sleeve_l = mirrored(sl, "sleeve_L")

if P["export"]:
    os.makedirs(os.path.dirname(os.path.join(ROOT, P["export"])), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, P["export"]), export_format="GLB", export_yup=True,
                              export_apply=True, export_image_format="NONE", export_skins=False,
                              export_animations=False)
    sys.exit(0)

# --------------------------------------------------------------- render ----
cam_data = bpy.data.cameras.new("cam")
cam_data.sensor_fit = "VERTICAL"
cam_data.angle_y = math.radians(P.get("fov", 62))
cam_data.clip_start = 0.01
cam = bpy.data.objects.new("cam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
# The driver's eye in wheel space: the wheel leans back about 28 degrees
# from upright, the eye is 0.55 m behind its centre and 0.3 m above.
eye = Vector(P.get("eye", [0.0, -0.5, 0.38]))
look = Vector(P.get("look", [0.0, 0.3, 0.05]))
if P.get("orbit"):
    eye = Vector(P["orbit"])
    look = radial * R
    cam_data.angle_y = math.radians(30)
cam.location = eye
cam.rotation_euler = (look - eye).to_track_quat("-Z", "Z").to_euler()
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.05, 0.055, 0.06, 1)
sc.world = w
al = bpy.data.lights.new("key", "AREA")
al.energy = 6
al.size = 0.6
ao = bpy.data.objects.new("key", al)
sc.collection.objects.link(ao)
ao.location = (0.3, -0.6, 0.6)
ao.rotation_euler = (look - ao.location).to_track_quat("-Z", "Z").to_euler()
sc.render.engine = "CYCLES"
sc.cycles.samples = P["samples"]
sc.cycles.use_denoising = False
sc.render.resolution_x, sc.render.resolution_y = P["res"]
sc.render.filepath = P["out"]
sc.view_settings.view_transform = "AgX"
bpy.ops.render.render(write_still=True)
