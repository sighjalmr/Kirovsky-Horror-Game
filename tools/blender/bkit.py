"""Shared helpers for the Blender model kits of «Кировский» (tools/blender/build_*.py).

Every kit is built with Blender's Python module (pip install bpy, Python 3.11)
and exported to models/kit/<kit>.glb. Conventions the game relies on
(scripts/models.gd):

* One root object per model, named by its id ("tin_peas", "gondola_end", …);
  a variant has a suffix "_v1", "_v2"; the low-detail copy for distance has
  the suffix "_lod1". Godot keeps these names on the imported nodes.
* Model frame: Blender Z up, the model's FRONT faces Blender +Y, origin at
  the bottom centre. The glTF exporter turns that into the game's frame
  (y up, front towards -z).
* Material names say which game material a surface gets:
  "<texture>[#rrggbb[aa]][@kind]", e.g. "goods", "paint#9ca6a0",
  "glass#1e262e80@psx_glass". The texture is a TexFactory name (goods,
  goods2, paint, chrome, pegboard, …); kind defaults to psx_material.
* Vertex colours (attribute "Col") hold the part's tint times ambient
  occlusion baked with Cycles, so one material serves the whole model and
  the crevices (under a jar's shoulder, between the shelf and its bracket)
  darken like real ones. The game multiplies the texture by them.
* UV v is given top-down (as in Godot and the atlas drawings); helpers
  flip it for Blender.
"""
import bpy, bmesh, math, os, sys, json, random
from mathutils import Vector, Matrix, noise

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "models", "kit")
ARGS = json.loads(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
    return m


# --- atlas cells -------------------------------------------------------------

class Rect:
    """A part of the texture, x/y/w/h in 0..1, y top-down."""

    def __init__(self, x, y, w, h):
        self.x, self.y, self.w, self.h = x, y, w, h

    def sub(self, x0, x1, y0=0.0, y1=1.0, px=1.0 / 2048.0):
        return Rect(self.x + self.w * x0 + px, self.y + self.h * y0 + px,
                    self.w * (x1 - x0) - 2 * px, self.h * (y1 - y0) - 2 * px)

    def uv(self, u, v):
        """u, v in 0..1 inside the rect (v down) -> Blender uv."""
        return (self.x + self.w * u, 1.0 - (self.y + self.h * v))


def grid_cell(i, cols=4, rows=8):
    return Rect((i % cols) / cols, (i // cols) / rows, 1.0 / cols, 1.0 / rows)


# --- mesh building -----------------------------------------------------------

class Mesh:
    """Collects faces with per-corner uv, a material slot and a tint, then
    becomes one Blender object."""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.col = self.bm.loops.layers.float_color.new("Tint")
        self.mats = []

    def slot(self, name):
        if name not in self.mats:
            self.mats.append(name)
        return self.mats.index(name)

    def face(self, pts, uvs, material, tint=(1, 1, 1), smooth=True):
        vs = [self.bm.verts.new(p) for p in pts]
        try:
            f = self.bm.faces.new(vs)
        except ValueError:
            return None
        f.material_index = self.slot(material)
        f.smooth = smooth
        for l, uv in zip(f.loops, uvs):
            l[self.uv].uv = uv
            l[self.col] = (tint[0], tint[1], tint[2], 1.0)
        return f

    def grid(self, rows, uvrows, material, tint=(1, 1, 1), smooth=True, closed=False):
        """A quad strip surface from rows of points (each row a list of the
        same length) with matching uv rows. closed: the rows wrap round."""
        n = len(rows[0])
        verts = [[self.bm.verts.new(p) for p in r] for r in rows]
        slot = self.slot(material)
        for i in range(len(rows) - 1):
            for j in range(n - 1 if not closed else n):
                j1 = (j + 1) % n
                q = [verts[i][j], verts[i][j1], verts[i + 1][j1], verts[i + 1][j]]
                qu = [uvrows[i][j], uvrows[i][j + 1], uvrows[i + 1][j + 1], uvrows[i + 1][j]]
                try:
                    f = self.bm.faces.new(q)
                except ValueError:
                    continue
                f.material_index = slot
                f.smooth = smooth
                for l, uv in zip(f.loops, qu):
                    l[self.uv].uv = uv
                    l[self.col] = (tint[0], tint[1], tint[2], 1.0)

    def lathe(self, prof, rect, material, segs=24, tint=(1, 1, 1), u0=0.0, u1=1.0, v=None, xf=None, smooth=True):
        """Revolves profile points (r, z) round Z. v: per point v in the rect
        (default: by arc length, top of the profile at v=0)."""
        if v is None:
            d = [0.0]
            for a, b in zip(prof, prof[1:]):
                d.append(d[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
            v = [1.0 - x / max(d[-1], 1e-6) for x in d]
        rows, uvs = [], []
        for (r, z), vv in zip(prof, v):
            row, urow = [], []
            for k in range(segs + 1):
                a = 2 * math.pi * k / segs
                # u = 0.25 (the middle of the first of the label's two
                # repeats) faces the front, +Y; u grows to the viewer's right.
                ang = a
                p = Vector((math.cos(ang) * r, math.sin(ang) * r, z))
                if xf is not None:
                    p = xf @ p
                row.append(p)
                urow.append(rect.uv(u0 + (u1 - u0) * k / segs, vv))
            rows.append(row[:-1])
            uvs.append(urow)
        # grid() expects uv rows one longer when closed: we kept segs+1 uvs.
        self._closed_grid(rows, uvs, material, tint, smooth)

    def _closed_grid(self, rows, uvs, material, tint, smooth):
        n = len(rows[0])
        verts = [[self.bm.verts.new(p) for p in r] for r in rows]
        slot = self.slot(material)
        for i in range(len(rows) - 1):
            for j in range(n):
                j1 = (j + 1) % n
                q = [verts[i][j], verts[i][j1], verts[i + 1][j1], verts[i + 1][j]]
                qu = [uvs[i][j], uvs[i][j + 1], uvs[i + 1][j + 1], uvs[i + 1][j]]
                if q[0] is q[3] or len(set(q)) < 3:
                    continue
                try:
                    f = self.bm.faces.new(q if len(set(q)) == 4 else list(dict.fromkeys(q)))
                except ValueError:
                    continue
                f.material_index = slot
                f.smooth = smooth
                for l, uv in zip(f.loops, qu):
                    l[self.uv].uv = uv
                    l[self.col] = (tint[0], tint[1], tint[2], 1.0)

    def disc(self, r, z, rect, material, segs=24, tint=(1, 1, 1), up=True, xf=None, rings=None):
        """A flat disc facing up (or down), uv planar over the rect.
        rings: list of (radius, dz) steps from the rim inwards, for stamped lids."""
        steps = rings or []
        radii = [(r, 0.0)] + list(steps) + [(0.0, steps[-1][1] if steps else 0.0)]
        rows, uvs = [], []
        for rr, dz in radii:
            row, urow = [], []
            for k in range(segs + 1):
                a = 2 * math.pi * k / segs + math.pi * 0.5
                x, y = math.cos(a) * rr, math.sin(a) * rr
                p = Vector((x, y, z + dz))
                if xf is not None:
                    p = xf @ p
                row.append(p)
                urow.append(rect.uv(0.5 - x / (2 * r), 0.5 + y / (2 * r)))
            rows.append(row[:-1])
            uvs.append(urow)
        if not up:
            rows.reverse()
            uvs.reverse()
        self._closed_grid(rows, uvs, material, tint, True)

    FACES = {
        "+y": ((0, 1, 0), (-1, 0, 0), (0, 0, 1)),
        "-y": ((0, -1, 0), (1, 0, 0), (0, 0, 1)),
        "+x": ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
        "-x": ((-1, 0, 0), (0, -1, 0), (0, 0, 1)),
        "+z": ((0, 0, 1), (-1, 0, 0), (0, -1, 0)),
        "-z": ((0, 0, -1), (-1, 0, 0), (0, 1, 0)),
    }

    def box(self, c, s, rects, material, tint=(1, 1, 1), xf=None, smooth=False):
        """Axis box centred at c with size s. rects: a Rect for every face,
        or a dict face->Rect for '+x','-x','+y','-y','+z','-z' (missing
        faces are left open). Side faces show the image upright; the top
        shows it with its top edge at the back."""
        if not isinstance(rects, dict):
            rects = {k: rects for k in self.FACES}
        h = Vector(s) * 0.5
        c = Vector(c)
        for k, (n, u, v) in self.FACES.items():
            if k not in rects:
                continue
            r = rects[k]
            n, u, v = Vector(n), Vector(u), Vector(v)
            hn = abs(n.dot(h)); hu = abs(u.dot(h)); hv = abs(v.dot(h))
            o = c + n * hn
            ps = [o - u * hu - v * hv, o + u * hu - v * hv, o + u * hu + v * hv, o - u * hu + v * hv]
            if xf is not None:
                ps = [xf @ p for p in ps]
            uvs = [r.uv(0, 1), r.uv(1, 1), r.uv(1, 0), r.uv(0, 0)]
            self.face(ps, uvs, material, tint, smooth)

    def box_m(self, c, s, material, tex_m=1.0, tint=(1, 1, 1), faces=None, xf=None, smooth=False):
        """Axis box centred at c, size s, uv in metres (tex_m metres per
        texture repeat) like MeshFactory.box: textures tile across big parts
        without stretching."""
        h = Vector(s) * 0.5
        c = Vector(c)
        for k, (n, u, v) in self.FACES.items():
            if faces is not None and k not in faces:
                continue
            n, u, v = Vector(n), Vector(u), Vector(v)
            hn = abs(n.dot(h)); hu = abs(u.dot(h)); hv = abs(v.dot(h))
            o = c + n * hn
            ps = [o - u * hu - v * hv, o + u * hu - v * hv, o + u * hu + v * hv, o - u * hu + v * hv]
            wp = [xf @ p for p in ps] if xf is not None else ps
            uvs = [(p.dot(u) / tex_m, p.dot(v) / tex_m) for p in ps]
            self.face(wp, uvs, material, tint, smooth)

    def to_object(self, name, weld=0.0001):
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=weld)
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(mat(m))
        o = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(o)
        return o


def link(o):
    if o.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(o)
    return o


def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]


def apply_mods(o):
    select_only([o])
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def bevel(o, width, segs=2, angle=40.0, harden=True):
    m = o.modifiers.new("bevel", "BEVEL")
    m.width = width
    m.segments = segs
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    m.harden_normals = harden
    m.miter_outer = "MITER_ARC"
    apply_mods(o)


def smooth_by_angle(o, deg=35.0):
    select_only([o])
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(deg))
    except Exception:
        bpy.ops.object.shade_smooth()


def displace(o, fn):
    """Moves every vertex by fn(co) -> Vector offset."""
    for v in o.data.vertices:
        v.co = v.co + fn(v.co.copy())
    o.data.update()


def join(objs, name):
    select_only(objs)
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    o.data.name = name
    return o


# --- ambient occlusion into vertex colours --------------------------------------

def bake_ao(objs, samples=24, distance=0.1, strength=0.85):
    """Bakes each object's own AO (alone in the scene) into "Col" = Tint × AO."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.world = sc.world or bpy.data.worlds.new("w")
    sc.world.light_settings.distance = distance
    hidden = {}
    for o in sc.objects:
        hidden[o.name] = o.hide_render
    for o in objs:
        for other in sc.objects:
            other.hide_render = other is not o
        me = o.data
        if "AO" not in me.color_attributes:
            me.color_attributes.new("AO", "FLOAT_COLOR", "CORNER")
        me.color_attributes.active_color = me.color_attributes["AO"]
        select_only([o])
        sc.render.bake.target = "VERTEX_COLORS"
        sc.render.bake.use_selected_to_active = False
        try:
            bpy.ops.object.bake(type="AO")
        except Exception as e:
            print("bake failed", o.name, e)
        aod = me.color_attributes["AO"].data
        lo = min(aod[i].color[0] for i in range(len(aod))) if len(aod) else 1.0
        print("ao", o.name, "min %.2f" % lo)
        _combine(o, strength)
    for o in sc.objects:
        o.hide_render = hidden.get(o.name, False)


def _combine(o, strength):
    me = o.data
    ao = me.color_attributes.get("AO")
    tint = me.color_attributes.get("Tint")
    col = me.color_attributes.get("Col") or me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    n = len(me.loops)
    for i in range(n):
        t = tint.data[i].color if tint else (1, 1, 1, 1)
        a = ao.data[i].color[0] if ao else 1.0
        k = 1.0 - strength + strength * a
        col.data[i].color = (t[0] * k, t[1] * k, t[2] * k, 1.0)
    for nm in ("AO", "Tint"):
        if nm in me.color_attributes:
            me.color_attributes.remove(me.color_attributes[nm])
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = 0


def plain_colors(o):
    """Tint -> Col without AO (for the low-detail copies)."""
    _combine(o, 0.0)


# --- level of detail ------------------------------------------------------------

def make_lod(o, ratio, name=None):
    """A decimated copy (collapse, keeps uv seams) named <name>_lod1."""
    c = o.copy()
    c.data = o.data.copy()
    c.name = (name or o.name) + "_lod1"
    link(c)
    m = c.modifiers.new("dec", "DECIMATE")
    m.ratio = ratio
    m.use_collapse_triangulate = True
    apply_mods(c)
    return c


def tri_count(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


# --- export -------------------------------------------------------------------

def export(kit, objs):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, kit + ".glb")
    select_only(objs)
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True, export_apply=True,
        export_texcoords=True, export_normals=True, export_tangents=False,
        export_vertex_color="ACTIVE", export_all_vertex_colors=False,
        export_active_vertex_color_when_no_material=True,
        export_materials="EXPORT", export_yup=True, export_animations=False,
        export_skins=False, export_morph=False, export_cameras=False, export_lights=False,
        export_extras=False)
    tris = sum(tri_count(o) for o in objs)
    print("exported", path, len(objs), "objects", tris, "tris")
    return path


def render_preview(path, objs, cam_loc, cam_target, lens=50, size=(1200, 800)):
    """Quick Workbench look at the models (developer check)."""
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "VERTEX"
    sc.render.resolution_x, sc.render.resolution_y = size
    cam = bpy.data.cameras.new("cam")
    cam.lens = lens
    co = bpy.data.objects.new("cam", cam)
    link(co)
    co.location = cam_loc
    d = Vector(cam_target) - Vector(cam_loc)
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sc.camera = co
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
