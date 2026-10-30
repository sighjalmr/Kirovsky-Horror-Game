"""Builds Kovpak's spectacles, models/glasses/glasses.glb, in Blender.

Classic Soviet men's spectacles of the 1970s-80s: a thick horn-rim frame
of tortoiseshell plastic («под рог»), lenses shaped as rounded trapezoids
wider at the brow, a keyhole bridge, two steel rivets on each front corner
and plastic temples with a steel core that bend down behind the ears.

    pip install bpy numpy
    python3 tools/build_glasses.py

Sizes are real (metres). The frame looks along +Y in Blender, which is -Z
in Godot; the origin is between the lens centres on the front of the frame.
"""

import math
import os

import bpy  # noqa: I001  (bpy must come first: it provides bmesh)
import bmesh
import numpy as np

OUT = os.path.join(os.path.dirname(__file__), "..", "models", "glasses")

LENS_W = 0.050      # lens width
LENS_H = 0.036      # lens height
GAP = 0.020         # between the lenses at the bridge
RIM = 0.0038        # rim width round the lens
BROW = 0.0065       # the brow line is this much heavier at the top
DEPTH = 0.0048      # thickness of the front
WRAP = math.radians(11.0)   # each lens turns this far round the face
TEMPLE_LEN = 0.118  # hinge to the bend behind the ear
DROP = 0.032        # how far the ear piece runs down


def lens_outline(n=72, grow=0.0, brow=0.0):
    """Rounded trapezoid: wider at the top, the outer lower corner drawn in."""
    pts = []
    for i in range(n):
        t = i / n * 2 * math.pi
        c, s = math.cos(t), math.sin(t)
        # Superellipse for the soft rectangle.
        e = 4.2
        x = math.copysign(abs(c) ** (2 / e), c) * (LENS_W / 2)
        y = math.copysign(abs(s) ** (2 / e), s) * (LENS_H / 2)
        # Narrower towards the bottom, the outer side sloping in.
        k = 1.0 - 0.12 * max(0.0, -y / (LENS_H / 2))
        x *= k
        if x > 0 and y < 0:
            x -= 0.004 * (-y / (LENS_H / 2)) ** 2
        r = math.hypot(x, y)
        g = grow + (brow if y > 0 else 0.0) * max(0.0, s) ** 2
        if r > 0:
            x += x / r * g
            y += y / r * g
        pts.append((x, y))
    return pts


def ring(bm, inner, outer, y0, y1):
    """A rim between two outlines, front at y0 and back at y1."""
    n = len(inner)
    vi0 = [bm.verts.new((p[0], y0, p[1])) for p in inner]
    vo0 = [bm.verts.new((p[0], y0, p[1])) for p in outer]
    vi1 = [bm.verts.new((p[0], y1, p[1])) for p in inner]
    vo1 = [bm.verts.new((p[0], y1, p[1])) for p in outer]
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((vo0[i], vo0[j], vi0[j], vi0[i]))  # front
        bm.faces.new((vi1[i], vi1[j], vo1[j], vo1[i]))  # back
        bm.faces.new((vo1[i], vo1[j], vo0[j], vo0[i]))  # outer wall
        bm.faces.new((vi0[i], vi0[j], vi1[j], vi1[i]))  # inner wall


def disc(bm, outline, y0, y1, bulge):
    """A lens: two slightly domed faces and an edge."""
    cx = sum(p[0] for p in outline) / len(outline)
    cz = sum(p[1] for p in outline) / len(outline)
    f0 = bm.verts.new((cx, y0 + bulge, cz))
    f1 = bm.verts.new((cx, y1 - bulge * 0.5, cz))
    e0 = [bm.verts.new((p[0], y0, p[1])) for p in outline]
    e1 = [bm.verts.new((p[0], y1, p[1])) for p in outline]
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((f0, e0[j], e0[i]))
        bm.faces.new((f1, e1[i], e1[j]))
        bm.faces.new((e0[i], e0[j], e1[j], e1[i]))


def mesh_object(name, bm, mat):
    me = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    return ob


def bevel(ob, width, segments=2):
    m = ob.modifiers.new("bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(40)


def planar_uv(ob, scale=12.0):
    """Project the texture from the front so the tortoiseshell runs along the rim."""
    me = ob.data
    uv = me.uv_layers.new(name="UV")
    for loop in me.loops:
        v = me.vertices[loop.vertex_index].co
        uv.data[loop.index].uv = (v.x * scale + 0.5, (v.z + v.y * 0.5) * scale + 0.5)


def tortoiseshell(size=512):
    """Dark brown horn with amber patches and darker streaks."""
    rng = np.random.default_rng(31)
    img = np.zeros((size, size))
    for octave in range(5):
        f = 2 ** (octave + 2)
        g = rng.random((f + 1, f + 1))
        xs = np.linspace(0, f, size, endpoint=False)
        x0 = xs.astype(int)
        t = xs - x0
        t = t * t * (3 - 2 * t)
        a = g[x0][:, x0] * (1 - t)[None, :] + g[x0][:, x0 + 1] * t[None, :]
        b = g[x0 + 1][:, x0] * (1 - t)[None, :] + g[x0 + 1][:, x0 + 1] * t[None, :]
        img += (a * (1 - t)[:, None] + b * t[:, None]) / (octave + 1)
    img = (img - img.min()) / (img.max() - img.min())
    # Stretch the patches along the rim and sharpen them.
    patch = np.clip((img - 0.48) * 4.0, 0, 1)
    dark = np.array([0.045, 0.025, 0.015])
    amber = np.array([0.42, 0.2, 0.06])
    col = dark[None, None, :] * (1 - patch[..., None]) + amber[None, None, :] * patch[..., None]
    col = np.clip(col, 0, 1)
    rgba = np.concatenate([col, np.ones((size, size, 1))], axis=2)
    im = bpy.data.images.new("tortoiseshell", size, size)
    im.pixels = rgba.astype(np.float32).ravel()
    im.file_format = "PNG"
    return im


def material(name, color, rough, metal=0.0, image=None, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if image is not None:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        m.blend_method = "BLEND"
    return m


def tube(name, points, radius_x, radius_y, mat):
    """A bar of rectangular-ish section following a poly line."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    sp = cu.splines.new("BEZIER")
    sp.bezier_points.add(len(points) - 1)
    for bp, p in zip(sp.bezier_points, points):
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    cu.bevel_mode = "ROUND"
    cu.bevel_depth = radius_x
    cu.bevel_resolution = 3
    cu.resolution_u = 10
    ob = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(ob)
    ob.scale = (1, 1, 1)
    cu.materials.append(mat)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    ob.select_set(False)
    # Flatten the round section into an oval.
    if radius_y != radius_x:
        me = ob.data
        centre = np.array(points)
        for v in me.vertices:
            d = np.linalg.norm(centre - np.array(v.co), axis=1)
            c = centre[int(np.argmin(d))]
            v.co.z = c[2] + (v.co.z - c[2]) * (radius_y / radius_x)
    return ob


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    shell = material("horn", (0.2, 0.1, 0.05), 0.28, image=tortoiseshell())
    steel = material("steel", (0.75, 0.74, 0.72), 0.25, metal=1.0)
    glass = material("lens", (0.9, 0.95, 0.95), 0.03, alpha=0.12)

    inner = lens_outline()
    outer = lens_outline(grow=RIM, brow=BROW)
    parts = []
    for side in (-1, 1):
        cx = side * (GAP / 2 + LENS_W / 2)
        flip = (lambda pts: [(-p[0], p[1]) for p in pts]) if side < 0 else (lambda pts: pts)
        bm = bmesh.new()
        ring(bm, flip(inner), flip(outer), 0.0, -DEPTH)
        rim = mesh_object("rim_%d" % side, bm, shell)
        bevel(rim, 0.0012, 3)
        bm = bmesh.new()
        disc(bm, flip(inner), -DEPTH * 0.35, -DEPTH * 0.65, 0.0008)
        lens = mesh_object("lens_%d" % side, bm, glass)
        # Two steel rivets on the outer top corner of the front.
        outer_top = max(flip(outer), key=lambda p: (p[0] * side) + p[1] * 0.6)
        for k in range(2):
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.0009, depth=0.0012,
				location=(outer_top[0] - side * (0.003 + k * 0.0035), 0.0004, outer_top[1] - 0.0045),
				rotation=(math.pi / 2, 0, 0))
            rv = bpy.context.active_object
            rv.data.materials.append(steel)
            rv.parent = rim
            for p in rv.data.polygons:
                p.use_smooth = True
        for ob in (rim, lens):
            ob.location.x = cx
            ob.rotation_euler.z = side * WRAP
        parts += [rim, lens]
        # Hinge block and temple: from the outer corner straight back, then
        # bending down behind the ear.
        hx = side * (GAP / 2 + LENS_W + RIM + 0.001)
        hz = LENS_H / 2 - 0.004
        bpy.ops.mesh.primitive_cube_add(size=1, location=(hx - side * 0.001, -DEPTH - 0.003, hz))
        hinge = bpy.context.active_object
        hinge.scale = (0.004, 0.007, 0.006)
        hinge.data.materials.append(shell)
        bevel(hinge, 0.0008)
        y_end = -DEPTH - TEMPLE_LEN
        pts = [(hx, -DEPTH - 0.005, hz), (hx + side * 0.004, -DEPTH - 0.04, hz),
			(hx + side * 0.007, y_end + 0.02, hz - 0.002), (hx + side * 0.007, y_end, hz - 0.008),
			(hx + side * 0.006, y_end - 0.012, hz - DROP * 0.6), (hx + side * 0.004, y_end - 0.016, hz - DROP)]
        parts.append(tube("temple_%d" % side, pts, 0.0017, 0.0028, shell))
        parts.append(hinge)

    # Keyhole bridge across the nose, on the top half of the rims.
    bz = LENS_H / 2 - 0.006
    pts = [(-GAP / 2 - 0.002, -DEPTH * 0.5, bz), (-GAP / 4, -DEPTH * 0.5, bz + 0.0025),
		(GAP / 4, -DEPTH * 0.5, bz + 0.0025), (GAP / 2 + 0.002, -DEPTH * 0.5, bz)]
    parts.append(tube("bridge", pts, 0.0028, 0.0028, shell))

    for ob in bpy.context.scene.objects:
        if ob.type == "MESH" and ob.name.startswith("rim"):
            planar_uv(ob)
        elif ob.type == "MESH" and (ob.name.startswith("temple") or ob.name.startswith("bridge")
				or ob.name.startswith("Cube")):
            planar_uv(ob, 20.0)

    os.makedirs(OUT, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "glasses.glb"), export_format="GLB",
		export_apply=True, export_image_format="JPEG", export_yup=True)


main()
