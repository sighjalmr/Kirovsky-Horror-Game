class_name Exterior
extends Node3D

## The square in front of универсам «Кировский» on Сиреневый бульвар, ЖБИ,
## after the 1980s photo: a red profiled-sheet box, a flat canopy on white
## posts with «КИРОВСКИЙ» in white letters on red squares along its edge,
## the arrow «УНИВЕРСАМ» above, wide steps, puddles on the asphalt, firs on
## the lawn and the nine-storey panel blocks all round. Only the cutscenes
## come here; the store you play in is Store.
##
## The front of the building is the plane z = 0, the street is towards -Z,
## the glass doors are at x = -2..2 as in Store, the porch is 0.75 m up.
## Facing the store (looking +Z) +X is on your left: the canopy with the
## letters is left of centre, the tall red block on the right, as on the photo.
## `look` is "night" (rain, sodium lamps, lit windows) or "day" (overcast).

const PORCH := 0.75
const CANOPY_Y := 4.2
## Where the cars stand.
const VOLGA_SPOT := Vector3(-0.8, 0, -10.5)
const ZHIGULI_SPOT := Vector3(4.6, 0, -11.4)
## The road along the square, and where Gordeev turns in from it.
const ROAD_Z := -27.0

var look := "night"
var zhiguli: Node3D
var volga: Node3D
var env: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
var sign_mats: Array[ShaderMaterial] = []
var _lit_windows: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _init(look_: String = "night") -> void:
	look = look_
	_rng.seed = 1988


func _ready() -> void:
	_build_env()
	_build_ground()
	_build_store()
	_build_blocks()
	_build_green()
	_build_lamps()
	zhiguli = Vehicles.zhiguli()
	add_child(zhiguli)
	zhiguli.visible = false
	volga = Vehicles.volga()
	add_child(volga)
	volga.position = VOLGA_SPOT
	volga.rotation.y = PI  # nose to the steps
	if look == "night":
		_build_rain()


# --- helpers ------------------------------------------------------------------

func box(pos: Vector3, size: Vector3, tex: String, tint := Color.WHITE, tex_m: Variant = 1.0, faces := MeshFactory.ALL,
		emission := Color.BLACK, step := 2.0, kind := Mats.SOLID) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshFactory.box(size, tex_m, step, faces, false)
	mi.extra_cull_margin = 0.5
	mi.material_override = Mats.get_mat(tex, tint, emission, kind)
	mi.position = pos
	add_child(mi)
	return mi


# --- the world ------------------------------------------------------------------

func _build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_curve = 1.4
	env.fog_sky_affect = 1.0
	sun = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-38), deg_to_rad(-140), 0)
	add_child(sun)
	if look == "night":
		env.background_color = Color(0.035, 0.04, 0.05)
		env.fog_light_color = Color(0.07, 0.075, 0.085)
		env.fog_depth_begin = 6.0
		env.fog_depth_end = 85.0
		env.ambient_light_color = Color(0.45, 0.5, 0.62)
		env.ambient_light_energy = 0.1
		env.tonemap_exposure = 1.35
		env.tonemap_white = 6.0
		# A faint moon through the cloud, just enough to show the blocks.
		sun.light_color = Color(0.55, 0.62, 0.8)
		sun.light_energy = 0.06
	else:
		env.background_color = Color(0.74, 0.76, 0.77)
		env.fog_light_color = Color(0.74, 0.76, 0.77)
		env.fog_depth_begin = 25.0
		env.fog_depth_end = 160.0
		env.ambient_light_color = Color(0.85, 0.88, 0.92)
		env.ambient_light_energy = 0.75
		env.tonemap_exposure = 1.05
		env.tonemap_white = 6.0
		sun.light_color = Color(0.95, 0.93, 0.88)
		sun.light_energy = 0.9
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 60.0
	we.environment = env
	add_child(we)


func _build_ground() -> void:
	# Asphalt in 8 m tiles (each lamp lights only its own few tiles).
	for x in range(-72, 72, 8):
		for z in range(-72, 64, 8):
			if x >= -24 and x < 16 and z >= 0 and z < 48:
				continue  # under the store
			box(Vector3(x + 4, -0.1, z + 4), Vector3(8, 0.1, 8), "ext_asphalt", Color(0.85, 0.85, 0.85), 6.0, MeshFactory.PY)
	# The road: a darker band with a faded centre line, kerbs both sides.
	for x in range(-72, 72, 8):
		box(Vector3(x + 4, -0.08, ROAD_Z), Vector3(8, 0.1, 9), "ext_asphalt", Color(0.7, 0.7, 0.72), 3.0, MeshFactory.PY)
		box(Vector3(x + 2, 0.0, ROAD_Z), Vector3(3, 0.012, 0.12), "white", Color(0.55, 0.55, 0.5), 1.0, MeshFactory.PY)
		for kz: float in [ROAD_Z - 4.6, ROAD_Z + 4.6]:
			if kz > ROAD_Z and x >= -8 and x < 16:
				continue  # the way into the square
			box(Vector3(x + 4, 0, kz), Vector3(8, 0.14, 0.22), "concrete", Color(0.6, 0.6, 0.58), 1.0)


func _build_store() -> void:
	var red := Color(0.78, 0.66, 0.64)
	var grey := Color(0.55, 0.6, 0.62)
	var sheet_m := 2.0
	# Plinth and porch, steps down to the square along its front.
	box(Vector3(2.5, 0, -2.75), Vector3(14, PORCH, 5.5), "ext_slabs", Color(0.85, 0.85, 0.82), 1.0)
	for i in 5:
		var h := PORCH - i * 0.15
		box(Vector3(2.5, 0, -5.5 - i * 0.32 - 0.16), Vector3(14 + i * 0.2, h, 0.32), "ext_slabs", Color(0.8, 0.8, 0.78), 1.0)
	# Concrete flower boxes at the ends of the steps, as in the photo.
	for x: float in [10.6, -5.6]:
		box(Vector3(x, 0, -4.0), Vector3(1.8, 0.9, 3.5), "concrete", Color(0.7, 0.7, 0.68), 1.0)
		box(Vector3(x, 0.9, -4.0), Vector3(1.6, 0.05, 3.3), "ext_asphalt", Color(0.3, 0.25, 0.2), 1.0, MeshFactory.PY)
	# The glazed front under the canopy: the store's own doors at x -2..2.
	var gx0 := -4.5
	var gx1 := 9.5
	box(Vector3((gx0 + gx1) * 0.5, PORCH, 0.05), Vector3(gx1 - gx0, CANOPY_Y - PORCH, 0.06), "glass",
		Color(0.55, 0.62, 0.62, 0.35), Vector2(1.95, 2.4), MeshFactory.NZ, Color.BLACK, 2.0, Mats.GLASS)
	var x := gx0
	while x <= gx1 + 0.01:
		box(Vector3(x, PORCH, 0.0), Vector3(0.08, CANOPY_Y - PORCH, 0.12), "chrome", Color(0.75, 0.75, 0.75), 1.0)
		x += 2.0
	for y: float in [PORCH + 0.05, PORCH + 2.45, CANOPY_Y - 0.1]:
		box(Vector3((gx0 + gx1) * 0.5, y, 0.0), Vector3(gx1 - gx0, 0.07, 0.12), "chrome", Color(0.75, 0.75, 0.75), 1.0)
	_build_lobby()
	# Canopy: a flat slab on square white posts, fascia painted dark.
	box(Vector3(2.5, CANOPY_Y, -2.9), Vector3(15, 0.35, 6.2), "paint", Color(0.82, 0.82, 0.8), 2.0)
	box(Vector3(2.5, CANOPY_Y + 0.35, -5.95), Vector3(15, 0.25, 0.1), "paint", Color(0.3, 0.3, 0.3), 1.0)
	for px: float in [9.4, 5.5, -0.5, -4.4]:
		box(Vector3(px, PORCH, -5.4), Vector3(0.36, CANOPY_Y - PORCH, 0.36), "concrete", Color(0.92, 0.92, 0.9), 1.0)
	# Soffit lamps under the canopy.
	for px: float in [7.5, 2.5, -2.5]:
		box(Vector3(px, CANOPY_Y - 0.04, -3.0), Vector3(0.5, 0.04, 0.5), "white", Color.WHITE, 1.0, MeshFactory.NY,
			Color(1.6, 1.5, 1.2) if look == "night" else Color.BLACK)
	# «КИРОВСКИЙ»: nine boxes standing on the canopy edge.
	var letters := MeshBuilder.Kit.new()
	letters.ao = false
	var lmat := Mats.unique("ext_kirovsky", Color.WHITE, Color.BLACK)
	sign_mats.append(lmat)
	var lb := letters.custom(lmat)
	var back := letters.b("paint", Color(0.55, 0.08, 0.06))
	for i in 9:
		var cx := 6.82 - i * 1.08
		lb.box(Props.at(cx, CANOPY_Y + 0.62, -5.6), Vector3(1.0, 1.0, 0.3), Color.WHITE, Rect2(i / 9.0, 0, 1 / 9.0, 1), Vector2.ONE,
			MeshFactory.NZ)
		back.box(Props.at(cx, CANOPY_Y + 0.62, -5.6), Vector3(1.0, 1.0, 0.3), Color.WHITE, Rect2(), Vector2.ONE,
			MeshFactory.ALL & ~MeshFactory.NZ)
		back.box(Props.at(cx, CANOPY_Y + 0.35, -5.6), Vector3(0.06, 0.27, 0.06))
	letters.build(self)
	# «УНИВЕРСАМ»: the arrow on a lattice frame, tilted back a little, above
	# the left end of the canopy, pointing right at the doors.
	var arrow := Node3D.new()
	arrow.position = Vector3(6.0, CANOPY_Y + 2.15, -4.6)
	arrow.rotation.x = deg_to_rad(-8)
	add_child(arrow)
	var ak := MeshBuilder.Kit.new()
	ak.ao = false
	var amat := Mats.unique("ext_universam", Color.WHITE, Color.BLACK)
	sign_mats.append(amat)
	ak.custom(amat).box(Props.at(0, 0, 0), Vector3(6.4, 1.6, 0.04), Color.WHITE, Rect2(0, 0, 1, 1), Vector2.ONE, MeshFactory.NZ)
	var frame := ak.b("metal", Color(0.4, 0.4, 0.42))
	frame.box(Props.at(-0.4, 0.2, 0.12), Vector3(5.2, 0.06, 0.06))
	frame.box(Props.at(-0.4, 1.3, 0.12), Vector3(5.2, 0.06, 0.06))
	for k in 7:
		frame.box(Props.rot(Vector3.BACK, 0.6 if k % 2 == 0 else -0.6, Vector3(-2.8 + k * 0.8, -1.9, 0.3)), Vector3(0.04, 2.3, 0.04))
	for sx: float in [-2.4, 1.6]:
		frame.box(Props.at(sx, -2.05, 0.3), Vector3(0.08, 2.1, 0.08))
	ak.build(arrow)
	# Red profiled sheet: above the glazing, the tall block on the right, the
	# low wing on the left; a grey upper storey set back behind.
	box(Vector3(2.5, CANOPY_Y + 0.35, 0.15), Vector3(14, 8.5 - CANOPY_Y - 0.35, 0.3), "ext_profnastil", red, sheet_m, MeshFactory.NZ)
	box(Vector3(-14.2, 0, 0.15), Vector3(19.4, 10.5, 0.3), "ext_profnastil", red, sheet_m, MeshFactory.NZ | MeshFactory.NX)
	box(Vector3(-14.2, 10.5, 0.15), Vector3(19.4, 0.3, 0.5), "paint", Color(0.3, 0.3, 0.3), 1.0)
	box(Vector3(12.75, 0, 0.15), Vector3(6.5, 6.8, 0.3), "ext_profnastil", red, sheet_m, MeshFactory.NZ | MeshFactory.PX)
	box(Vector3(12.75, 6.8, 0.15), Vector3(6.5, 0.25, 0.5), "paint", Color(0.3, 0.3, 0.3), 1.0)
	box(Vector3(-4, 0, 26.5), Vector3(39.6, 12.5, 35), "ext_profnastil", grey, sheet_m, MeshFactory.NZ | MeshFactory.PX | MeshFactory.NX)
	box(Vector3(2.5, 8.5, 0.15), Vector3(14, 0.25, 0.5), "paint", Color(0.3, 0.3, 0.3), 1.0)
	# Flat roof between the front and the set-back upper storey.
	box(Vector3(-4, 8.45, 4.6), Vector3(39.6, 0.1, 8.9), "concrete", Color(0.3, 0.3, 0.3), 4.0, MeshFactory.PY)
	box(Vector3(-23.9, 0, 20), Vector3(0.3, 10.5, 40), "ext_profnastil", red, sheet_m, MeshFactory.NX)
	# A tall strip of windows on the red block, like on the photo.
	for wx: float in [-19.5, -21.0]:
		box(Vector3(wx, 2.4, -0.02), Vector3(1.2, 6.5, 0.04), "glass", Color(0.25, 0.3, 0.32, 0.9), Vector2(1.2, 2.2),
			MeshFactory.NZ, Color.BLACK, 2.0, Mats.GLASS)
		box(Vector3(wx, 2.4, -0.04), Vector3(1.3, 0.08, 0.06), "paint", Color(0.85, 0.85, 0.85), 1.0)
		box(Vector3(wx, 8.9, -0.04), Vector3(1.3, 0.08, 0.06), "paint", Color(0.85, 0.85, 0.85), 1.0)
	# TV aerials on the roof.
	for ax: float in [-8.0, -17.0]:
		box(Vector3(ax, 12.5, 6.0), Vector3(0.05, 3.0, 0.05), "metal", Color(0.4, 0.4, 0.4), 1.0)
		box(Vector3(ax, 15.2, 6.0), Vector3(2.2, 0.04, 0.04), "metal", Color(0.4, 0.4, 0.4), 1.0)


## Behind the glass: the lobby with its lockers and the lit hall beyond, at
## 22:20 still bright, by day the same with shoppers going in and out.
func _build_lobby() -> void:
	box(Vector3(2.5, PORCH - 0.02, 4.0), Vector3(14, 0.02, 8), "floor", Color.WHITE, 4.0 / 3.0, MeshFactory.PY)
	box(Vector3(2.5, PORCH + 3.2, 4.0), Vector3(14, 0.05, 8), "ceiling", Color.WHITE, 4.0 / 3.0, MeshFactory.NY)
	box(Vector3(2.5, PORCH, 8.0), Vector3(14, 3.2, 0.1), "wall", Color(0.9, 0.9, 0.85), Vector2(2.0, 3.2), MeshFactory.NZ)
	box(Vector3(6.5, PORCH + 0.1, 7.6), Vector3(5, 2.0, 0.5), "locker", Color.WHITE, Vector2(6, 2), MeshFactory.NZ)
	box(Vector3(-2.0, PORCH, 6.5), Vector3(3.5, 1.2, 0.8), "formica", Color(0.8, 0.8, 0.75), 1.0)
	for k in 4:
		var fx := -3.0 + k * 3.6
		box(Vector3(fx, PORCH + 3.12, 4.0), Vector3(0.25, 0.06, 2.4), "white", Color.WHITE, 1.0, MeshFactory.NY,
			Color(1.5, 1.6, 1.3))
	var l := OmniLight3D.new()
	l.position = Vector3(2.5, PORCH + 2.8, 4.0)
	l.omni_range = 11.0
	l.light_energy = 1.4 if look == "night" else 0.8
	l.light_color = Store.TUBE_COLOR
	add_child(l)
	if look == "night":
		# The light falls out through the glass onto the porch.
		var spill := SpotLight3D.new()
		spill.position = Vector3(2.5, PORCH + 2.6, 1.0)
		spill.rotation.x = deg_to_rad(-150)
		spill.spot_range = 9.0
		spill.spot_angle = 60.0
		spill.light_energy = 1.2
		spill.light_color = Store.TUBE_COLOR
		add_child(spill)


## The nine-storey panel blocks round the square, in 12 m sections.
func _build_blocks() -> void:
	_block(Vector3(70, 0, 2), Vector3(22, 0, 2), 9, 12.0)        # left of the store, as on the photo
	_block(Vector3(-36, 0, -70), Vector3(36, 0, -70), 9, 12.0)   # across the road, behind the camera
	_block(Vector3(-44, 0, 30), Vector3(-44, 0, -18), 9, 12.0)   # far right
	_block(Vector3(40, 0, -44), Vector3(64, 0, -44), 9, 12.0)


## A panel block whose facade runs from `a` to `b` (seen from the front, a is
## on the left) with `depth` metres behind it; lit windows at night.
func _block(a: Vector3, b: Vector3, floors: int, depth: float) -> void:
	var along := (b - a).normalized()
	var outward := along.cross(Vector3.UP)  # to the viewer's side
	var length := a.distance_to(b)
	var h := floors * 2.8 + 0.6
	var centre := (a + b) * 0.5 - outward * depth * 0.5
	var node := Node3D.new()
	node.position = centre
	node.basis = Basis(along, Vector3.UP, outward)
	add_child(node)
	# In node space: x to the viewer's right along the facade, +z towards him.
	# The sides run round anticlockwise seen from above, each from the
	# viewer's left, so the texture reads the right way on all four.
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var facade := kit.b("ext_panel", Color(0.95, 0.95, 0.95))
	var hx := length * 0.5
	var hz := depth * 0.5
	var corners := [Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz)]
	for side in 4:
		var p0: Vector3 = corners[side]
		var p1: Vector3 = corners[(side + 1) % 4]
		var w := p0.distance_to(p1)
		var n := int(ceil(w / 6.0))
		for i in n:
			var q0 := p0.lerp(p1, float(i) / n)
			var q1 := p0.lerp(p1, float(i + 1) / n)
			var s0 := float(i) / n * w
			var s1 := float(i + 1) / n * w
			var m := 6
			for j in m:
				var y0 := h * j / m
				var y1 := h * (j + 1) / m
				facade.quad(Transform3D.IDENTITY, [q0 + Vector3(0, y0, 0), q1 + Vector3(0, y0, 0), q1 + Vector3(0, y1, 0),
					q0 + Vector3(0, y1, 0)], [Vector2(s0 / 12.0, 1.0 - y0 / 11.2), Vector2(s1 / 12.0, 1.0 - y0 / 11.2),
					Vector2(s1 / 12.0, 1.0 - y1 / 11.2), Vector2(s0 / 12.0, 1.0 - y1 / 11.2)], Color.WHITE, false)
	kit.b("concrete", Color(0.45, 0.45, 0.45)).box(Props.at(0, h, 0), Vector3(length + 0.3, 0.5, depth + 0.3))
	# Lit windows on the two long sides: emissive panes just proud of the wall.
	if look == "night":
		var lit := kit.b("ext_windows", Color.WHITE, Color(1.7, 1.6, 1.5))
		for face in 2:
			var z := hz + 0.03 if face == 0 else -hz - 0.03
			var bays := int(length / 3.0)
			for f in floors:
				for bi in bays:
					if _rng.randf() > 0.3:
						continue
					var i := bi % 4
					var s := bi * 3.0
					var r: Rect2
					if i % 2 == 1:
						r = Rect2(s + 0.25, f * 2.8 + 1.25, 2.5, 1.08)
					else:
						r = Rect2(s + 0.62, f * 2.8 + 0.8, 1.76, 1.36)
					var cell := _rng.randi_range(0, 7)
					var uv := Rect2((cell % 4) / 4.0, (cell / 4) / 2.0, 0.25, 0.5)
					var xc := -hx + r.get_center().x if face == 0 else hx - r.get_center().x
					var tint := Color.WHITE * _rng.randf_range(0.5, 1.0)
					tint.a = 1.0
					lit.box(Transform3D(Basis(Vector3.UP, 0.0 if face == 0 else PI),
						Vector3(xc, r.position.y, z)), Vector3(r.size.x, r.size.y, 0.01), tint, uv,
						Vector2.ONE, MeshFactory.PZ)
	kit.build(node, false)


func _build_green() -> void:
	# The lawn on the right of the steps with its firs, as in the photo.
	box(Vector3(-14.5, -0.05, -6.5), Vector3(18, 0.12, 12), "cloth", Color(0.28, 0.32, 0.18), 3.0, MeshFactory.PY)
	box(Vector3(-14.5, 0, -12.5), Vector3(18, 0.14, 0.2), "concrete", Color(0.6, 0.6, 0.58), 1.0)
	for p: Vector3 in [Vector3(-9.5, 0, -3.5), Vector3(-13.0, 0, -8.0), Vector3(-17.5, 0, -4.0), Vector3(-21.5, 0, -9.5),
			Vector3(15.5, 0, -7.0), Vector3(19.0, 0, -3.5)]:
		_fir(p, _rng.randf_range(5.0, 8.5))
	# Bare birches along the road: October, the leaves are down.
	for bx: float in [-30.0, -18.0, -6.0, 18.0, 30.0]:
		_birch(Vector3(bx + _rng.randf_range(-1, 1), 0, ROAD_Z + 6.0))


func _fir(p: Vector3, h: float) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	kit.b("wood", Color(0.35, 0.25, 0.2)).cylinder(Props.at(p.x, 0, p.z), 0.14, 0.08, h * 0.3, 8)
	var needles := kit.b("fur", Color(0.3, 0.42, 0.28))
	var tiers := 7
	for i in tiers:
		var t := float(i) / tiers
		var r := lerpf(h * 0.32, h * 0.06, t)
		var y := h * (0.15 + t * 0.75)
		needles.cylinder(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), p + Vector3(0, y, 0)), r, 0.05, h * 0.22, 12,
			Color.WHITE * _rng.randf_range(0.8, 1.1), Rect2(0, 0, 3, 1))
	kit.build(self)


func _birch(p: Vector3) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var bark := kit.b("concrete", Color(0.85, 0.85, 0.82))
	bark.cylinder(Props.at(p.x, 0, p.z), 0.16, 0.07, 9.0, 8)
	var twig := kit.b("wood", Color(0.25, 0.2, 0.18))
	for i in 30:
		var y := 2.6 + i * 0.21
		var a := _rng.randf() * TAU
		var ln := lerpf(2.2, 0.6, i / 30.0)
		var dir := Vector3(cos(a), 0.9, sin(a)).normalized()
		twig.capsule(Transform3D.IDENTITY, p + Vector3(0, y, 0), p + Vector3(0, y, 0) + dir * ln, 0.04, 0.012, 5)
	kit.build(self)


func _build_lamps() -> void:
	var lamps := [
		[Vector3(-12, 0, ROAD_Z + 5.4), Vector3(-12, 0, ROAD_Z - 1)],
		[Vector3(13, 0, ROAD_Z + 5.4), Vector3(13, 0, ROAD_Z - 1)],
		[Vector3(28, 0, ROAD_Z + 5.4), Vector3(28, 0, ROAD_Z - 1)],
		[Vector3(-32, 0, ROAD_Z + 5.4), Vector3(-32, 0, ROAD_Z - 1)],
		[Vector3(-8, 0, -14.0), Vector3(-4, 0, -8.0)],
		[Vector3(9, 0, -15.0), Vector3(5, 0, -10.0)],
	]
	for l: Array in lamps:
		var s := Fittings.street_lamp(self, l[0], l[1])
		s.spot_range = 22.0
		s.spot_angle = 50.0
		s.light_energy = 9.0 if look == "night" else 0.0
		# Only the two lamps by the steps throw shadows (cars, posts, people).
		s.shadow_enabled = look == "night" and absf((l[0] as Vector3).z) < 20.0


func _build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 6000
	rain.lifetime = 1.1
	rain.preprocess = 1.2
	rain.local_coords = false
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(16, 0.5, 16)
	rain.direction = Vector3(0.12, -1, 0.05)
	rain.spread = 2.0
	rain.gravity = Vector3(0, -2, 0)
	rain.initial_velocity_min = 11.0
	rain.initial_velocity_max = 13.0
	var q := QuadMesh.new()
	q.size = Vector2(0.008, 0.45)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.75, 0.8, 0.22)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	q.material = m
	rain.mesh = q
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)


## Keeps the rain falling round the camera.
func follow(cam: Camera3D) -> void:
	if rain:
		rain.global_position = cam.global_position + Vector3(0, 9, 0) - cam.global_basis.z * 6.0


## Signs lit (night) or dark (day).
func light_signs(on: bool) -> void:
	for m in sign_mats:
		m.set_shader_parameter("emission", Color(0.9, 0.85, 0.8) if on else Color.BLACK)
