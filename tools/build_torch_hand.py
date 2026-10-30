"""Poses Gordeev's hand round the «жучок» and bakes it into
models/torch_hand/torch_hand.glb (the game's first-person viewmodel).

Run with Blender's Python module (pip install bpy):
    python tools/build_torch_hand.py -- '{"export": "models/torch_hand/torch_hand.glb"}'
Without "export" it renders a preview from the player's eye to "out".

The torch is modelled here; the hand is models/hand/Hand_Nails_R.gltf. Each
finger closes joint by joint until its skin rests on the shell or the lever,
the thumb is laid straight along the top towards the glass, then a coat
sleeve runs from the wrist towards the elbow. Everything is exported in the
torch's own frame; player.gd turns it the same way as here (yaw, pitch,
roll -> HAND_ROT, loc -> HAND_POS).
"""
import bpy, bmesh, math, sys, json, os
from mathutils import Vector, Matrix, Quaternion

ARGS = json.loads(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else {}
P = dict(a=55, px=-0.039, py=0.04, lever_open=0.0015, pz=0.0, slide=0.02, roll=75, pitch=-3, yaw=30, arm=[0.6, -0.6, -0.5], loc=[0.17, 0.36, -0.155], cuff=-0.012, arm_mix=0.4,
         out="/tmp/torch_hand.png", res=[960, 540], samples=24, export="", sleeve_dir=[0.0, -1.0, 0.0])
P.update(ARGS)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HAND = os.path.join(ROOT, "models/hand/")

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


# ---------------------------------------------------------------- torch ----
def mat(name, color, rough=0.5, metal=0.0, emit=None, alpha=1.0, tex=None, normal=None, orm=None, nscale=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = metal
    if emit:
        bs.inputs["Emission Color"].default_value = (*emit, 1.0)
        bs.inputs["Emission Strength"].default_value = 0.0
    if alpha < 1.0:
        bs.inputs["Alpha"].default_value = alpha
        m.surface_render_method = "BLENDED"
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
        nt.links.new(sep.outputs["Blue"], bs.inputs["Metallic"])
    if normal:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(normal)
        t.image.colorspace_settings.name = "Non-Color"
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nm.inputs["Strength"].default_value = nscale
        nt.links.new(t.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bs.inputs["Normal"])
    return m


def lathe(name, prof, material, seg=48, smooth=True):
    bm = bmesh.new()
    rings = []
    for r, y in prof:
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            ring.append(bm.verts.new((r * math.cos(a), y, r * math.sin(a))))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            try:
                bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
            except ValueError:
                pass
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


bakelite = mat("torch_body", (0.045, 0.034, 0.027), rough=0.33)
chrome = mat("torch_chrome", (0.8, 0.8, 0.78), rough=0.12, metal=1.0)
glass = mat("torch_lens", (0.9, 0.9, 0.85), rough=0.02, emit=(1.0, 0.86, 0.6), alpha=0.25)
bulb = mat("torch_bulb", (1.0, 0.95, 0.8), rough=0.1, emit=(1.0, 0.85, 0.55))
reflector = mat("torch_reflector", (0.95, 0.93, 0.88), rough=0.06, metal=1.0)
steel = mat("torch_lever", (0.32, 0.32, 0.3), rough=0.5, metal=0.8)

if P.get("lit", 1) and not P["export"]:
    glass.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 3.0
    bulb.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 30.0
torch = bpy.data.objects.new("Torch", None)
sc.collection.objects.link(torch)
parts = []

# The «жучок»: a pocket dynamo torch. A bakelite shell like a flattened egg,
# the round glass in a chrome ring at the front, a steel lever along the
# underside (+x) that the fingers squeeze. Axis +y, lens forward.
HX, HZ, Y0, Y1 = P.get("hx", 0.029), P.get("hz", 0.019), -0.05, 0.05


def shell(y):
    """Half height and half thickness of the shell at y."""
    t = (y - Y0) / (Y1 - Y0)
    back = math.sqrt(max(0.0, 1 - ((0.22 - t) / 0.22) ** 2)) if t < 0.22 else 1.0
    front = 1.0 - 0.12 * max(0.0, (t - 0.6) / 0.4) ** 2
    bulge = 1.0 + 0.04 * math.sin(math.pi * t)
    k = back * front * bulge
    return HX * k, HZ * (0.25 + 0.75 * k) if t < 0.22 else HZ * k


def superellipse(hx, hz, th, n=2.5):
    c, s_ = math.cos(th), math.sin(th)
    return (hx * math.copysign(abs(c) ** (2 / n), c), hz * math.copysign(abs(s_) ** (2 / n), s_))


def loft(name, material):
    bm = bmesh.new()
    seg, rings = 64, 48
    grid = []
    for k in range(rings + 1):
        y = Y0 + (Y1 - Y0) * (1 - math.cos(math.pi * k / rings)) / 2
        hx, hz = shell(y)
        ring = []
        for i in range(seg):
            x, z = superellipse(max(hx, 1e-4), max(hz, 1e-4), 2 * math.pi * i / seg)
            ring.append(bm.verts.new((x, y, z)))
        grid.append(ring)
    for r0, r1 in zip(grid, grid[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
    # flat front face inside the bezel
    c = bm.verts.new((0, Y1, 0))
    for i in range(seg):
        bm.faces.new((grid[-1][i], grid[-1][(i + 1) % seg], c))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    for poly in me.polygons:
        poly.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    me.materials.append(material)
    return ob


body = loft("torch_body", bakelite)
parts.append(body)
LR = 0.0165  # lens radius
parts.append(lathe("torch_bezel", [(LR - 0.001, Y1 + 0.0045), (LR + 0.0015, Y1 + 0.005), (LR + 0.003, Y1 + 0.0035),
                                   (LR + 0.0032, Y1 + 0.0005), (LR + 0.002, Y1 - 0.001)], chrome))
parts.append(lathe("torch_reflector", [(LR - 0.001, Y1 + 0.004), (0.012, Y1 - 0.002), (0.006, Y1 - 0.008),
                                       (0.003, Y1 - 0.01)], reflector))
parts.append(lathe("torch_lens", [(0.0, Y1 + 0.0042), (LR - 0.0008, Y1 + 0.0038)], glass))
parts.append(lathe("torch_bulb", [(0.0, Y1 - 0.0095), (0.003, Y1 - 0.008), (0.0038, Y1 - 0.005), (0.003, Y1 - 0.002),
                                  (0.0, Y1 - 0.001)], bulb, seg=16))


def lever(name):
    """Steel lever under the shell, hinged at the front, open at the back."""
    bm = bmesh.new()
    n, w, th = 24, 0.0105, 0.0025
    rows = []
    for k in range(n + 1):
        t = k / n
        y = 0.036 - t * 0.078
        hx, hz = shell(y)
        x = hx + 0.0012 + P["lever_open"] * t ** 1.4
        row = []
        for sx, sz in ((0, -w), (0, w), (th, w), (th, -w)):
            row.append(bm.verts.new((x + sx, y, sz)))
        rows.append(row)
    for r0, r1 in zip(rows, rows[1:]):
        for i in range(4):
            j = (i + 1) % 4
            bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
    bm.faces.new(rows[0][::-1])
    bm.faces.new(rows[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    bv = ob.modifiers.new("b", "BEVEL"); bv.width = 0.0009; bv.segments = 2
    me.materials.append(steel)
    return ob


# seam where the two halves of the shell meet, round the middle (z = 0)
bm = bmesh.new()
seam = []
N = 120
for i in range(N):
    th = 2 * math.pi * i / N
    # walk round the outline in the x-y plane
    y = Y0 + (Y1 - Y0) * (0.5 - 0.5 * math.cos(th))
    hx, hz = shell(y)
    x = (hx + 0.0004) * (1 if th < math.pi else -1)
    seam.append((x, y))
me = bpy.data.meshes.new("seam")
verts = []
for x, y in seam:
    verts += [(x, y, -0.0007), (x, y, 0.0007), (x * 1.025 + math.copysign(0.0003, x), y, 0.0)]
faces = []
for i in range(N):
    j = (i + 1) % N
    for k in range(3):
        a0, a1 = 3 * i + k, 3 * i + (k + 1) % 3
        b0, b1 = 3 * j + k, 3 * j + (k + 1) % 3
        faces.append((a0, b0, b1, a1))
me.from_pydata(verts, [], faces)
for poly in me.polygons:
    poly.use_smooth = True
so_ = bpy.data.objects.new("torch_seam", me)
sc.collection.objects.link(so_)
me.materials.append(bakelite)
parts.append(so_)
lv = lever("torch_lever")
parts.append(lv)
# ring for a cord at the back
bpy.ops.mesh.primitive_torus_add(major_radius=0.006, minor_radius=0.0013, location=(0, Y0 - 0.004, 0),
                                 rotation=(0, math.pi / 2, 0))
ring = bpy.context.active_object
ring.name = "torch_ring"
ring.data.materials.append(steel)
parts.append(ring)
for p in parts:
    p.parent = torch
bpy.context.view_layer.update()
from mathutils.bvhtree import BVHTree
_dg = bpy.context.evaluated_depsgraph_get()
TREES = [BVHTree.FromObject(o, _dg) for o in (body, lv)]

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

# Torch frame expressed in the hand's rest frame: the axis runs diagonally
# across the palm (thumb side towards the lens), the back of the hand is the
# torch's +z.
a = math.radians(P["a"])
ty = Vector((0, math.sin(a), math.cos(a)))
tz = Vector((1, 0, 0))
tx = ty.cross(tz)
T_in_H = Matrix((tx, ty, tz)).transposed().to_4x4()
T_in_H.translation = Vector((P["px"], P["py"], P["pz"])) + ty * P.get("slide", 0.0)
arm.matrix_world = T_in_H.inverted()   # hand placed in torch space
arm.parent = torch
bpy.context.view_layer.update()

# Torch in view space: camera at origin looking +y.
torch.matrix_world = (Matrix.Translation(P["loc"]) @ Matrix.Rotation(math.radians(P["yaw"]), 4, "Z")
                      @ Matrix.Rotation(math.radians(P["pitch"]), 4, "X")
                      @ Matrix.Rotation(math.radians(P["roll"]), 4, "Y"))
bpy.context.view_layer.update()

# Vertex groups → which verts belong to which bone (max weight).
vg_names = {g.index: g.name for g in skin.vertex_groups}
owner = {}
for v in skin.data.vertices:
    if v.groups:
        g = max(v.groups, key=lambda g: g.weight)
        if g.weight > 0.5:
            owner.setdefault(vg_names[g.group], []).append(v.index)


def verts_of(bone_names):
    out = []
    for n in bone_names:
        out += owner.get(n, [])
    return out


def penetration(idx):
    """Smallest signed distance (m) of the given verts to the torch surface."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = skin.evaluated_get(dg)
    me = ev.to_mesh()
    inv = torch.matrix_world.inverted() @ skin.matrix_world
    best = 1.0
    for i in idx:
        p = inv @ me.vertices[i].co
        for tr in TREES:
            loc, nrm, _, dist = tr.find_nearest(p, 0.05)
            if loc is None:
                continue
            d = dist if (p - loc).dot(nrm) >= 0 else -dist
            best = min(best, d)
    ev.to_mesh_clear()
    return best


def close(bone, idx, start=-10.0, stop=110.0, step=2.0, gap=0.0006):
    pb = arm.pose.bones[bone]
    pb.rotation_mode = "XYZ"
    ang = start
    last = start
    while ang <= stop:
        pb.rotation_euler = (0, 0, math.radians(ang))
        bpy.context.view_layer.update()
        if penetration(idx) < gap:
            break
        last = ang
        ang += step
    pb.rotation_euler = (0, 0, math.radians(last))
    bpy.context.view_layer.update()
    return last


chains = {f: ["%s_%s_R" % (f, j) for j in ("Proximal", "Intermediate", "Distal")]
          for f in ("Index", "Middle", "Ring", "Little")}
chains["Thumb"] = ["Thumb_Metacarpal_R", "Thumb_Proximal_R", "Thumb_Distal_R"]
log = {}
RATIO = (1.0, 1.15, 0.75)


def set_curl(bones, angs):
    for b, g in zip(bones, angs):
        pb = arm.pose.bones[b]
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (0, 0, math.radians(g))
    bpy.context.view_layer.update()


for f, bones in chains.items():
    tip = "%s_Tip_R" % f
    allv = verts_of(bones + [tip])
    if f == "Thumb":
        angs = [0.0, 0.0, 0.0]
        log[f] = angs
        continue
    # Search the knuckle and middle joint angles (the end joint bends with
    # the middle one, about 2/3 as much, as it does in a real finger) for the
    # tightest curl at which no part of the finger is inside the shell or the
    # lever: the finger ends up wrapped round the torch, resting on it.
    tipv = verts_of([bones[2], tip])
    best, angs = -1.0, [0.0, 0.0, 0.0]
    for pa in range(0, 101, 5):
        for ia in range(0, 106, 5):
            cand = [float(pa), float(ia), ia * 0.67]
            set_curl(bones, cand)
            d = penetration(allv)
            if d < 0.0004:
                continue
            # the finger has to end resting on the torch, its last joint on
            # the shell or the lever, not curled up in the air beside it
            dd = penetration(tipv)
            score = pa + ia + (300.0 if dd < 0.003 else 0.0)
            if score > best:
                best, angs = score, cand
    set_curl(bones, angs)
    log[f] = [round(x) for x in angs]
print("POSE", json.dumps(log))


def aim(bone, target_torch):
    e = bpy.data.objects.new("aim_" + bone, None)
    sc.collection.objects.link(e)
    e.parent = torch
    e.location = target_torch
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


if P.get("thumb_top", True):
    # Thumb laid straight along the top (-x) of the shell, pointing at the lens.
    ang = math.radians(P.get("thumb_ang", 180.0))
    tr_ = P.get("thumb_r", 0.038)
    tinv = torch.matrix_world.inverted() @ arm.matrix_world
    for bone, drop in (("Thumb_Proximal_R", 0.0), ("Thumb_Distal_R", 0.004)):
        pb = arm.pose.bones[bone]
        h = tinv @ pb.head
        ln = pb.length
        rad = tr_ - drop
        q = Vector((rad * math.cos(ang), 0, rad * math.sin(ang)))
        dxz = math.hypot(q.x - h.x, q.z - h.z)
        dy = math.sqrt(max(1e-6, ln * ln - dxz * dxz))
        aim(bone, Vector((q.x, h.y + dy, q.z)))


def lay_thumb(r):
    tinv = torch.matrix_world.inverted() @ arm.matrix_world
    for bone, drop in (("Thumb_Proximal_R", 0.0), ("Thumb_Distal_R", 0.004)):
        pb = arm.pose.bones[bone]
        h = tinv @ pb.head
        rad = r - drop
        q = Vector((rad * math.cos(ang), 0, rad * math.sin(ang)))
        dxz = math.hypot(q.x - h.x, q.z - h.z)
        dy = math.sqrt(max(1e-6, pb.length ** 2 - dxz * dxz))
        aim(bone, Vector((q.x, h.y + dy, q.z)))


if P.get("thumb_top", True):
    # lift the thumb off the shell until no part of it is inside
    while penetration(verts_of(chains["Thumb"] + ["Thumb_Tip_R"])) < 0.0005 and tr_ < 0.06:
        tr_ += 0.001
        lay_thumb(tr_)
    print("THUMB_R", round(tr_, 3))

any_owner = {}
for v in skin.data.vertices:
    for g in v.groups:
        if g.weight > 0.15:
            any_owner.setdefault(vg_names[g.group], []).append(v.index)
for f, bones in chains.items():
    idx = sum((any_owner.get(b, []) for b in bones + ["%s_Tip_R" % f]), [])
    _d = penetration(idx)
    print("DIAG", f, round(_d * 1000, 2), "mm")
    _worst_all = min(globals().get("_worst_all", 1.0), _d)
print("DIAG palm", round(penetration(sum((any_owner.get(b, []) for b in ["Wrist_R", "Palm_R"] + [x + "_Metacarpal_R" for x in ("Index", "Middle", "Ring", "Little", "Thumb")]), [])) * 1000, 2), "mm")
# and the other way round: no corner of the shell or the lever inside the skin
_dg = bpy.context.evaluated_depsgraph_get()
_skin_tree = BVHTree.FromObject(skin, _dg)
_to_skin = skin.matrix_world.inverted() @ torch.matrix_world
_worst = 1.0
for o in (body, lv):
    for v in o.data.vertices:
        loc, nrm, _, dist = _skin_tree.find_nearest(_to_skin @ v.co, 0.05)
        if loc is not None and ((_to_skin @ v.co) - loc).dot(nrm) < 0:
            _worst = min(_worst, -dist)
print("DIAG torch-in-skin", round(_worst * 1000, 2), "mm")
if min(_worst, _worst_all) < 0 and P["export"]:
    sys.exit("skin and torch overlap, not exporting")
# --------------------------------------------------------------- sleeve ----
# Wool coat sleeve from the wrist towards the elbow, with soft folds bunched
# up near the cuff.
def sleeve():
    wrist = arm.matrix_world @ arm.pose.bones["Wrist_R"].head
    hb = (arm.matrix_world.to_3x3()).normalized()
    fwd = hb @ Vector((0, 1, 0))          # along the fingers
    dirv = (hb @ Vector(P["sleeve_dir"])).normalized()
    if P.get("arm"):
        dirv = Vector(P["arm"]).normalized()
        fa = -(hb @ Vector((0, 1, 0))).normalized()
        print("FOREARM_NATURAL", [round(v, 2) for v in fa])
        dirv = fa.slerp(dirv, P.get("arm_mix", 1.0))
    print("WRIST_BEND", round(math.degrees(dirv.angle(-(hb @ Vector((0, 1, 0))).normalized()))))
    up = hb @ Vector((1, 0, 0))           # back of the hand
    side = dirv.cross(up).normalized()
    up = side.cross(dirv).normalized()
    bm = bmesh.new()
    seg, rings = 40, 46
    L = 0.42
    grid = []
    import random
    random.seed(4)
    ph = [random.uniform(0, 6.28) for _ in range(8)]
    for k in range(rings):
        t = k / (rings - 1)
        s = t * L + P.get("cuff", 0.0)
        c = wrist + dirv * s
        ring = []
        for i in range(seg):
            th = 2 * math.pi * i / seg
            rx = 0.036 + 0.008 * min(1, t * 4) + 0.006 * t
            rz = 0.031 + 0.007 * min(1, t * 4) + 0.006 * t
            fold = (0.0035 * math.sin(s * 95 + 2.2 * math.sin(th + ph[0]) + ph[1]) * math.exp(-t * 2.5)
                    + 0.0016 * math.sin(th * 3 + s * 40 + ph[2])
                    + 0.0012 * math.sin(th * 5 - s * 25 + ph[3]))
            r = 1.0 + fold / 0.04
            p = c + side * (math.cos(th) * rx * r) + up * (math.sin(th) * rz * r)
            ring.append(bm.verts.new(p))
        grid.append(ring)
    for r0, r1 in zip(grid, grid[1:]):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
    # turned-back cuff edge
    inner = []
    for i in range(seg):
        th = 2 * math.pi * i / seg
        p = wrist - dirv * 0.012 + side * (math.cos(th) * 0.034) + up * (math.sin(th) * 0.029)
        inner.append(bm.verts.new(p))
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((inner[i], inner[j], grid[0][j], grid[0][i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("sleeve")
    bm.to_mesh(me)
    uv = me.uv_layers.new()
    for poly in me.polygons:
        poly.use_smooth = True
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            k, i = divmod(vi, seg)
            uv.data[li].uv = ((i / seg) * 4.0, (k / rings) * 6.0) if k < rings else ((i / seg) * 4.0, -0.1)
    ob = bpy.data.objects.new("sleeve", me)
    sc.collection.objects.link(ob)
    ob.data.materials.append(mat("coat_wool", (0.07, 0.075, 0.065), rough=0.95))
    return ob


sl = sleeve()

# --------------------------------------------------------------- render ----
if P["export"]:
    # bake the pose into the mesh, then export everything in torch space
    bpy.context.view_layer.objects.active = skin
    for o in bpy.data.objects:
        o.select_set(False)
    skin.select_set(True)
    bpy.ops.object.modifier_apply(modifier=skin.modifiers[0].name)
    mw = skin.matrix_world.copy()
    skin.parent = None
    skin.matrix_world = mw
    bpy.data.objects.remove(arm)
    for o in parts:
        for m in list(o.modifiers):
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.modifier_apply(modifier=m.name)
    inv = torch.matrix_world.inverted()
    for o in [skin, sl] + parts:
        w = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = inv @ w
    bpy.data.objects.remove(torch)
    bpy.ops.export_scene.gltf(filepath=P["export"], export_format="GLB", export_yup=True,
                              export_apply=True, export_image_format="NONE", export_skins=False,
                              export_animations=False)
    sys.exit(0)

cam_data = bpy.data.cameras.new("cam")
cam_data.sensor_fit = "VERTICAL"
cam_data.angle_y = math.radians(P.get("fov", 70))
cam_data.clip_start = 0.01
cam = bpy.data.objects.new("cam", cam_data)
sc.collection.objects.link(cam)
cam.rotation_euler = (math.radians(90), 0, 0)
sc.camera = cam
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.012, 0.014, 0.012, 1)
w.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
sc.world = w
# floor and a shelf in the distance for context
bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 5, -1.6))
bpy.context.active_object.data.materials.append(mat("floor", (0.25, 0.24, 0.2), rough=0.6))
# torch beam and the spill bouncing back on the hand
spot = bpy.data.lights.new("beam", "SPOT")
spot.energy = 60
spot.spot_size = math.radians(40)
spot.color = (1, 0.88, 0.7)
so = bpy.data.objects.new("beam", spot)
sc.collection.objects.link(so)
so.matrix_world = torch.matrix_world @ Matrix.Translation((0, 0.095, 0)) @ Matrix.Rotation(-math.pi / 2, 4, "X")
pt = bpy.data.lights.new("spill", "POINT")
pt.energy = 1.2
pt.color = (1, 0.92, 0.78)
pt.shadow_soft_size = 0.3
po = bpy.data.objects.new("spill", pt)
sc.collection.objects.link(po)
po.location = torch.matrix_world @ Vector((-0.25, 0.35, 0.25))
sc.render.engine = "CYCLES"
sc.cycles.samples = P["samples"]
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = P["res"]
sc.render.filepath = P["out"]
sc.view_settings.view_transform = "AgX"
if P.get("debug"):
    al = bpy.data.lights.new("dbg", "AREA"); al.energy = 8; al.size = 0.5
    ao = bpy.data.objects.new("dbg", al); sc.collection.objects.link(ao)
    ao.location = (0.1, 0.0, 0.25); ao.rotation_euler = (math.radians(40), 0, 0)
if P.get("orbit"):
    cam.location = torch.matrix_world @ Vector(P["orbit"])
    P["look"] = list(torch.matrix_world.translation)
    cam.data.angle_y = math.radians(30)
if P.get("look"):
    d = Vector(P["look"]) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
if P.get("view"):
    cam.location = P["view"][0]; cam.rotation_euler = [math.radians(v) for v in P["view"][1]]
bpy.ops.render.render(write_still=True)
