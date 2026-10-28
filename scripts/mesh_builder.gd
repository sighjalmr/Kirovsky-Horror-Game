class_name MeshBuilder
extends RefCounted

## Merges many small parts that share one material into a single mesh: the
## packs on a shelf, the pieces of a till, the folds of a cloth. Parts are
## placed with a Transform3D. UVs either tile in world metres (`tex_m`, like
## MeshFactory) or stretch one atlas cell (`rect`, 0..1 texture space) over a
## face, image top at the top of the face.
## Vertex colours carry the part colour times a baked darkening towards the
## floor, so one material serves differently tinted parts.

const NO_RECT := Rect2()

var ao_enabled := true

var _st := SurfaceTool.new()
var _count := 0
var _nb_of := Basis()
var _nb := Basis()


func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


func is_empty() -> bool:
	return _count == 0


## Bottom-centred box, like MeshFactory.box. `step` > 0 cuts faces into
## quads of that size for the affine warp on big surfaces.
func box(xf: Transform3D, size: Vector3, color := Color.WHITE, rect := NO_RECT, tex_m := Vector2.ONE,
		faces := MeshFactory.ALL, step := 0.0, ao := true) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var defs := [
		[MeshFactory.PX, Vector3(hx, 0, hz), Vector3(0, 0, -size.z), Vector3(0, size.y, 0)],
		[MeshFactory.NX, Vector3(-hx, 0, -hz), Vector3(0, 0, size.z), Vector3(0, size.y, 0)],
		[MeshFactory.PZ, Vector3(-hx, 0, hz), Vector3(size.x, 0, 0), Vector3(0, size.y, 0)],
		[MeshFactory.NZ, Vector3(hx, 0, -hz), Vector3(-size.x, 0, 0), Vector3(0, size.y, 0)],
		[MeshFactory.PY, Vector3(-hx, size.y, hz), Vector3(size.x, 0, 0), Vector3(0, 0, -size.z)],
		[MeshFactory.NY, Vector3(-hx, 0, -hz), Vector3(size.x, 0, 0), Vector3(0, 0, size.z)],
	]
	for d in defs:
		if (faces & int(d[0])) == 0:
			continue
		var o: Vector3 = d[1]
		var u: Vector3 = d[2]
		var v: Vector3 = d[3]
		var nu := 1 if step <= 0.0 else maxi(1, ceili(u.length() / step))
		var nv := 1 if step <= 0.0 else maxi(1, ceili(v.length() / step))
		for i in nu:
			for j in nv:
				var k := [Vector2(float(i) / nu, float(j) / nv), Vector2(float(i + 1) / nu, float(j) / nv),
					Vector2(float(i + 1) / nu, float(j + 1) / nv), Vector2(float(i) / nu, float(j + 1) / nv)]
				var pts: Array[Vector3] = []
				var uvs: Array[Vector2] = []
				for q: Vector2 in k:
					pts.append(o + u * q.x + v * q.y)
					if rect.has_area():
						uvs.append(rect.position + Vector2(q.x, 1.0 - q.y) * rect.size)
					else:
						uvs.append(Vector2(q.x * u.length() / tex_m.x, -q.y * v.length() / tex_m.y))
				quad(xf, pts, uvs, color, ao)


## Upright cylinder or cone, bottom-centred. The side wraps `side_rect` once
## around; caps show `cap_rect` as a disc.
func cylinder(xf: Transform3D, r_bottom: float, r_top: float, h: float, sides: int, color := Color.WHITE,
		side_rect := Rect2(0, 0, 1, 1), cap_rect := NO_RECT, top := true, bottom := false, ao := true) -> void:
	var ring_b: Array[Vector3] = []
	var ring_t: Array[Vector3] = []
	var dirs: Array[Vector2] = []
	for i in sides + 1:
		var a := -float(i) / sides * TAU
		var d := Vector2(cos(a), sin(a))
		dirs.append(d)
		ring_b.append(Vector3(d.x * r_bottom, 0, d.y * r_bottom))
		ring_t.append(Vector3(d.x * r_top, h, d.y * r_top))
	for i in sides:
		var u0 := side_rect.position.x + side_rect.size.x * float(i) / sides
		var u1 := side_rect.position.x + side_rect.size.x * float(i + 1) / sides
		var vb := side_rect.end.y
		var vt := side_rect.position.y
		var n0 := Vector3(dirs[i].x, 0, dirs[i].y)
		var n1 := Vector3(dirs[i + 1].x, 0, dirs[i + 1].y)
		quad(xf, [ring_b[i], ring_b[i + 1], ring_t[i + 1], ring_t[i]],
			[Vector2(u0, vb), Vector2(u1, vb), Vector2(u1, vt), Vector2(u0, vt)], color, ao, [n0, n1, n1, n0])
	var cr := cap_rect if cap_rect.has_area() else Rect2(side_rect.position, side_rect.size * Vector2(1, 0.1))
	var c_uv := cr.get_center()
	for cap in 2:
		if (cap == 0 and not bottom) or (cap == 1 and not top):
			continue
		var y := 0.0 if cap == 0 else h
		var r := r_bottom if cap == 0 else r_top
		var n := Vector3.DOWN if cap == 0 else Vector3.UP
		for i in sides:
			var a := dirs[i]
			var b := dirs[i + 1]
			var tri: Array = [[Vector3(0, y, 0), c_uv], [Vector3(a.x * r, y, a.y * r), c_uv + a * cr.size * 0.5],
				[Vector3(b.x * r, y, b.y * r), c_uv + b * cr.size * 0.5]]
			if cap == 1:
				tri = [tri[0], tri[2], tri[1]]
			for t: Array in tri:
				_vertex(xf, t[0], t[1], n, color, ao)


## A surface of revolution round local +Y: `profile` is a list of
## Vector2(radius, height) from bottom to top. Smooth normals; u wraps round
## `rect` once, v runs down it along the profile. Close an end with radius 0.
func lathe(xf: Transform3D, profile: Array, sides: int, color := Color.WHITE, rect := Rect2(0, 0, 1, 1),
		ao := true) -> void:
	var n := profile.size()
	var lens: Array[float] = [0.0]
	for i in range(1, n):
		lens.append(lens[i - 1] + (profile[i] as Vector2).distance_to(profile[i - 1]))
	var total := maxf(lens[n - 1], 0.0001)
	var nrm: Array[Vector2] = []
	for i in n:
		var t: Vector2 = profile[mini(i + 1, n - 1)] - profile[maxi(i - 1, 0)]
		if (profile[i] as Vector2).x < 0.00001 and (i == 0 or i == n - 1):
			nrm.append(Vector2(0, -1 if i == 0 else 1))
		else:
			nrm.append(Vector2(t.y, -t.x).normalized())
	for i in sides:
		var a0 := -float(i) / sides * TAU
		var a1 := -float(i + 1) / sides * TAU
		var u0 := rect.position.x + rect.size.x * float(i) / sides
		var u1 := rect.position.x + rect.size.x * float(i + 1) / sides
		for j in n - 1:
			var p0: Vector2 = profile[j]
			var p1: Vector2 = profile[j + 1]
			var v0 := rect.end.y - rect.size.y * lens[j] / total
			var v1 := rect.end.y - rect.size.y * lens[j + 1] / total
			var pts := [_rev(p0, a0), _rev(p0, a1), _rev(p1, a1), _rev(p1, a0)]
			var ns := [_rev(nrm[j], a0), _rev(nrm[j], a1), _rev(nrm[j + 1], a1), _rev(nrm[j + 1], a0)]
			# Skip the zero-area half of quads that meet at the axis.
			var tris := [[0, 2, 1], [0, 3, 2]]
			if p0.x < 0.00001:
				tris = [[0, 3, 2]]
			elif p1.x < 0.00001:
				tris = [[0, 2, 1]]
			var uvs := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
			for tri: Array in tris:
				for idx: int in tri:
					_vertex(xf, pts[idx], uvs[idx], ns[idx], color, ao)


static func _rev(p: Vector2, a: float) -> Vector3:
	return Vector3(cos(a) * p.x, p.y, sin(a) * p.x)


## A rounded limb from `a` to `b`: a tapered cylinder with ball ends, radius
## `ra` at a and `rb` at b. Finger bones, wrists, the killer's arms.
func capsule(xf: Transform3D, a: Vector3, b: Vector3, ra: float, rb: float, sides := 12, color := Color.WHITE,
		rect := Rect2(0, 0, 1, 1), ao := true) -> void:
	var axis := b - a
	var length := axis.length()
	var y := axis / length
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var prof: Array = []
	for k in 5:
		var t := -PI * 0.5 + PI * 0.5 * k / 4.0
		prof.append(Vector2(cos(t) * ra, sin(t) * ra))
	for k in 5:
		var t := PI * 0.5 * k / 4.0
		prof.append(Vector2(cos(t) * rb, length + sin(t) * rb))
	lathe(xf * Transform3D(Basis(x, y, z), a), prof, sides, color, rect, ao)


## An ellipsoid with the given half-axes, centred on the transform.
func ellipsoid(xf: Transform3D, radii: Vector3, sides := 16, rings := 10, color := Color.WHITE,
		rect := Rect2(0, 0, 1, 1), ao := true) -> void:
	var prof: Array = []
	for k in rings + 1:
		var t := -PI * 0.5 + PI * k / rings
		prof.append(Vector2(cos(t), sin(t)))
	lathe(xf * Transform3D(Basis.from_scale(radii), Vector3.ZERO), prof, sides, color, rect, ao)


## A sheet through a grid of points: rows[j][i], i along u, j along v (v
## pointing down the sheet). UVs tile every `tex_m` metres of rest length.
func sheet(xf: Transform3D, rows: Array, color := Color.WHITE, tex_m := 1.0, ao := true) -> void:
	for j in rows.size() - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		for i in r0.size() - 1:
			var pts: Array[Vector3] = [r1[i], r1[i + 1], r0[i + 1], r0[i]]
			var uvs: Array[Vector2] = []
			for p in [Vector2(i, j + 1), Vector2(i + 1, j + 1), Vector2(i + 1, j), Vector2(i, j)]:
				uvs.append(p * 0.12 / tex_m)
			quad(xf, pts, uvs, color, ao)


## One quad p0 p1 p2 p3 counter-clockwise seen from its front (so that
## cross(p1 - p0, p3 - p0) points out of the front).
func quad(xf: Transform3D, p: Array, uv: Array, color: Color, ao := true, normals: Array = []) -> void:
	var n: Vector3 = (p[1] - p[0]).cross(p[3] - p[0]).normalized()
	if n == Vector3.ZERO:
		n = (p[2] - p[1]).cross(p[3] - p[1]).normalized()
	# Godot treats clockwise triangles as front faces.
	for idx: int in [0, 2, 1, 0, 3, 2]:
		_vertex(xf, p[idx], uv[idx], normals[idx] if not normals.is_empty() else n, color, ao)


func _vertex(xf: Transform3D, p: Vector3, uv: Vector2, n: Vector3, color: Color, ao: bool) -> void:
	var wp := xf * p
	if xf.basis != _nb_of:
		# Normals go through the inverse transpose so squashed parts shade right.
		_nb_of = xf.basis
		_nb = xf.basis.inverse().transposed()
	var wn := (_nb * n).normalized()
	var k := 1.0
	if ao and ao_enabled:
		if wn.y < -0.5:
			k = 0.7
		elif wn.y < 0.5:
			k = lerpf(0.5, 1.0, clampf(wp.y / 1.2, 0.0, 1.0))
	_st.set_normal(wn)
	_st.set_uv(uv)
	_st.set_color(Color(color.r * k, color.g * k, color.b * k))
	_st.add_vertex(wp)
	_count += 1


func commit() -> ArrayMesh:
	_st.generate_tangents()
	return _st.commit()


## Several builders keyed by material, turned into one MeshInstance3D each.
class Kit:
	var ao := true  # false for people and the viewmodel: no floor darkening
	var _parts: Dictionary = {}

	func b(tex: String, tint := Color.WHITE, emission := Color.BLACK, kind := Mats.SOLID) -> MeshBuilder:
		var key := "%s|%s|%s|%s" % [tex, tint.to_html(), emission.to_html(), kind]
		if not _parts.has(key):
			var mb := MeshBuilder.new()
			mb.ao_enabled = ao
			_parts[key] = [mb, Mats.get_mat(tex, tint, emission, kind)]
		return _parts[key][0]

	## Adds a builder with a material made elsewhere (one that changes at runtime).
	func custom(mat: Material) -> MeshBuilder:
		var key := "custom|%d" % mat.get_instance_id()
		if not _parts.has(key):
			_parts[key] = [MeshBuilder.new(), mat]
		return _parts[key][0]

	func build(parent: Node3D, shadows := true) -> Array[MeshInstance3D]:
		var out: Array[MeshInstance3D] = []
		for key: String in _parts:
			var mb: MeshBuilder = _parts[key][0]
			if mb.is_empty():
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = mb.commit()
			mi.material_override = _parts[key][1]
			mi.extra_cull_margin = 0.3
			if not shadows or key.ends_with(Mats.GLASS):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mi)
			out.append(mi)
		return out
