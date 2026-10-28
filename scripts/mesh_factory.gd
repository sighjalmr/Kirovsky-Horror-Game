class_name MeshFactory
extends RefCounted

## Box meshes for the PS1 look. Every face is cut into small quads so the
## affine texture warp and per-vertex light behave like on the PlayStation,
## UVs are in world metres (one texture repeat per `tex_m`), and vertical
## faces get a baked darkening towards the floor.
## Boxes are bottom-centred: x and z centred on the origin, y from 0 to size.y.
## `tex_m` is a float, or a Vector2 for different horizontal and vertical
## repeats (a texture mapped exactly once over a face of that size).

const PX := 1
const NX := 2
const PY := 4
const NY := 8
const PZ := 16
const NZ := 32
const ALL := 63

static var _cache: Dictionary = {}


static func box(size: Vector3, tex_m: Variant = 1.0, step := 0.5, faces := ALL, ao := true) -> ArrayMesh:
	var key := "%s|%s|%s|%s|%s" % [size, tex_m, step, faces, ao]
	if _cache.has(key):
		return _cache[key]
	var tm: Vector2 = tex_m if tex_m is Vector2 else Vector2(tex_m, tex_m)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	# [face bit, origin corner, u edge, v edge, normal]; cross(u, v) == normal.
	var defs := [
		[PX, Vector3(hx, 0, hz), Vector3(0, 0, -size.z), Vector3(0, size.y, 0), Vector3.RIGHT],
		[NX, Vector3(-hx, 0, -hz), Vector3(0, 0, size.z), Vector3(0, size.y, 0), Vector3.LEFT],
		[PZ, Vector3(-hx, 0, hz), Vector3(size.x, 0, 0), Vector3(0, size.y, 0), Vector3.BACK],
		[NZ, Vector3(hx, 0, -hz), Vector3(-size.x, 0, 0), Vector3(0, size.y, 0), Vector3.FORWARD],
		[PY, Vector3(-hx, size.y, hz), Vector3(size.x, 0, 0), Vector3(0, 0, -size.z), Vector3.UP],
		[NY, Vector3(-hx, 0, -hz), Vector3(size.x, 0, 0), Vector3(0, 0, size.z), Vector3.DOWN],
	]
	for d in defs:
		if (faces & int(d[0])) == 0:
			continue
		_face(st, d[1], d[2], d[3], d[4], tm, step, ao)
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


static func _face(st: SurfaceTool, o: Vector3, u: Vector3, v: Vector3, n: Vector3, tex_m: Vector2, step: float, ao: bool) -> void:
	var lu := u.length()
	var lv := v.length()
	var nu := maxi(1, ceili(lu / step))
	var nv := maxi(1, ceili(lv / step))
	for i in nu:
		for j in nv:
			var a := Vector2(float(i) / nu, float(j) / nv)
			var b := Vector2(float(i + 1) / nu, float(j) / nv)
			var c := Vector2(float(i + 1) / nu, float(j + 1) / nv)
			var d := Vector2(float(i) / nu, float(j + 1) / nv)
			# Godot treats clockwise triangles as front faces.
			for k: Vector2 in [a, c, b, a, d, c]:
				var p := o + u * k.x + v * k.y
				st.set_normal(n)
				st.set_uv(Vector2(k.x * lu, -k.y * lv) / tex_m)
				st.set_color(_shade(p, n, ao))
				st.add_vertex(p)


static func _shade(p: Vector3, n: Vector3, ao: bool) -> Color:
	if not ao or n.y > 0.5:
		return Color.WHITE
	if n.y < -0.5:
		return Color(0.7, 0.7, 0.7)
	var k := lerpf(0.45, 1.0, clampf(p.y / 1.2, 0.0, 1.0))
	return Color(k, k, k)
