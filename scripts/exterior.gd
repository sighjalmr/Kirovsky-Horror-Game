class_name Exterior
extends Node3D

## The square in front of универсам «Кировский» on Сиреневый бульвар, МЖК,
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
## Built into the night store as the square Gordeev can walk out onto: no
## sky or sun of its own (the store's environment serves), no lobby behind the
## glass (the real store is there), a gap in the glazing for the real doors.
var embedded := false
var zhiguli: Node3D
var volga: Node3D
var env: Environment
var sun: DirectionalLight3D
var rain: CPUParticles3D
var leaves: CPUParticles3D
var sign_mats: Array[ShaderMaterial] = []
## The phone booths' node; in the night store the right one's handset is
## left off its hook for the call of night one (see Outdoors).
var booths: Node3D
var _lit_windows: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _init(look_: String = "night", embedded_ := false) -> void:
	look = look_
	embedded = embedded_
	_rng.seed = 1988


func _ready() -> void:
	if not embedded:
		_build_env()
	_build_ground()
	_build_store()
	_build_blocks()
	if look == "day":
		_build_district()
	_build_green()
	_build_lamps()
	_build_street()
	zhiguli = Vehicles.zhiguli()
	add_child(zhiguli)
	zhiguli.visible = false
	volga = Vehicles.volga()
	add_child(volga)
	volga.position = VOLGA_SPOT
	volga.rotation.y = PI  # nose to the steps
	if embedded:
		# The store has its own «Волга» that comes and goes; Gordeev's
		# «Жигули» stands where he parked it at 22:20.
		volga.visible = false
		zhiguli.visible = true
		zhiguli.position = ZHIGULI_SPOT
		zhiguli.rotation.y = PI
		CarCabin.set_driver(zhiguli, false)
	if look == "night":
		_build_rain()
	elif Settings.graphics >= Graphics.MEDIUM:
		_build_leaves()


## The rain and the leaves keep falling round whatever camera is looking.
func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		# Built round the night store: no rain falling through the hall.
		var outside := not embedded or cam.global_position.z < -0.6
		if rain:
			rain.visible = outside
		if leaves:
			leaves.visible = outside
		if outside:
			follow(cam)


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
		env.fog_depth_begin = 30.0
		env.fog_depth_end = 300.0
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
	# Pavements both sides, 3 m of lighter, older asphalt; on the square's side
	# it runs flush across the way in. A strip of lawn behind the far one.
	for x in range(-72, 72, 8):
		var flush := x >= -8 and x < 16
		box(Vector3(x + 4, -0.1 if flush else 0.0, ROAD_Z + 6.1), Vector3(8, 0.1 if flush else 0.12, 2.8), "ext_asphalt",
			Color(1.35, 1.32, 1.28), 3.0, MeshFactory.PY | MeshFactory.NZ)
		box(Vector3(x + 4, 0.0, ROAD_Z - 6.1), Vector3(8, 0.12, 2.8), "ext_asphalt", Color(1.35, 1.32, 1.28), 3.0,
			MeshFactory.PY | MeshFactory.PZ)
		box(Vector3(x + 4, -0.06, ROAD_Z - 10.0), Vector3(8, 0.12, 5.0), "ext_grass", Color.WHITE, 3.0, MeshFactory.PY)
	# Puddles, oil where the cars stand, manhole covers.
	for p: Array in [[Vector3(-3.5, 0, -14.5), 3.2, 0.3], [Vector3(8.5, 0, -16.5), 2.6, 1.2], [Vector3(12.5, 0, -9.0), 2.2, 2.0],
			[Vector3(-1.0, 0, -19.0), 3.6, 2.6], [Vector3(-14.0, 0, ROAD_Z + 1.5), 3.0, 0.4],
			[Vector3(9.0, 0, ROAD_Z - 1.8), 3.4, 1.4], [Vector3(26.0, 0, ROAD_Z + 2.0), 2.4, 0.9],
			[Vector3(-26.0, 0, -15.0), 2.8, 2.2], [Vector3(18.0, 0, -12.0), 2.6, 0.2]]:
		var pp: Vector3 = p[0]
		if pp.z < ROAD_Z + 4.5 and pp.z > ROAD_Z - 4.5:
			pp.y = 0.02
		Street.decal(self, pp, p[1], "puddle", p[2], 0.7)
	Street.decal(self, VOLGA_SPOT + Vector3(0, 0, 0.3), 1.6, "oil", 0.5)
	Street.decal(self, ZHIGULI_SPOT + Vector3(0.2, 0, 0.6), 1.4, "oil", 2.1)
	Street.decal(self, Vector3(-6.0, 0, -9.0), 1.3, "oil", 1.0)
	for h: Vector3 in [Vector3(-3.0, 0.02, ROAD_Z + 1.2), Vector3(22.0, 0.02, ROAD_Z - 1.0), Vector3(14.0, 0, -18.0),
			Vector3(-20.0, 0.12, ROAD_Z + 6.0)]:
		Street.decal(self, h, 0.75, "hatch", _rng.randf() * TAU)


func _build_store() -> void:
	var red := Color(0.7, 0.62, 0.6)
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
	# Built into the store, the real doors fill x -2..2 and the glass above them.
	var panes: Array = [Vector2(gx0, gx1)] if not embedded else [Vector2(gx0, -2.0), Vector2(2.0, gx1)]
	for pn: Vector2 in panes:
		box(Vector3((pn.x + pn.y) * 0.5, PORCH, 0.05), Vector3(pn.y - pn.x, CANOPY_Y - PORCH, 0.06), "glass",
			Color(0.55, 0.62, 0.62, 0.35), Vector2(1.95, 2.4), MeshFactory.NZ, Color.BLACK, 2.0, Mats.GLASS)
	if embedded:
		box(Vector3(0, PORCH + 2.4, 0.05), Vector3(4.0, CANOPY_Y - PORCH - 2.4, 0.06), "glass",
			Color(0.55, 0.62, 0.62, 0.35), Vector2(1.95, 2.4), MeshFactory.NZ, Color.BLACK, 2.0, Mats.GLASS)
	var x := gx0
	while x <= gx1 + 0.01:
		box(Vector3(x, PORCH, 0.0), Vector3(0.08, CANOPY_Y - PORCH, 0.12), "chrome", Color(0.75, 0.75, 0.75), 1.0)
		x += 2.0
	for y: float in [PORCH + 0.05, PORCH + 2.45, CANOPY_Y - 0.1]:
		box(Vector3((gx0 + gx1) * 0.5, y, 0.0), Vector3(gx1 - gx0, 0.07, 0.12), "chrome", Color(0.75, 0.75, 0.75), 1.0)
	if not embedded:
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
	# Inside the night store this would stand across the hall: start it above the roof.
	var gy := 7.3 if embedded else 0.0
	box(Vector3(-4, gy, 26.5), Vector3(39.6, 12.5 - gy, 35), "ext_profnastil", grey, sheet_m, MeshFactory.NZ | MeshFactory.PX | MeshFactory.NX)
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
	# Drainpipes down the corners, a bend at the foot.
	for dp: Array in [[Vector3(16.05, 0, -0.1), 6.8], [Vector3(-23.75, 0, -0.1), 10.5], [Vector3(-4.35, 0, -0.1), 4.2]]:
		var kit := MeshBuilder.Kit.new()
		var pipe := kit.b("galv", Color(0.55, 0.55, 0.55))
		var base: Vector3 = dp[0]
		pipe.cylinder(Props.at(base.x, 0.35, base.z), 0.06, 0.06, float(dp[1]) - 0.35, 8)
		pipe.capsule(Transform3D.IDENTITY, base + Vector3(0, 0.36, 0), base + Vector3(0, 0.08, -0.35), 0.06, 0.07, 8)
		for y in range(1, int(dp[1]), 2):
			pipe.box(Props.at(base.x, y, base.z + 0.06), Vector3(0.16, 0.03, 0.08))
		kit.build(self)
	# On the low wing: the bottle-return door, crates stacked by it, a trodden
	# path to it across the lawn.
	box(Vector3(-16.0, 0, -0.04), Vector3(1.6, 2.3, 0.08), "metal", Color(0.42, 0.45, 0.43), Vector2(1.6, 2.3), MeshFactory.NZ)
	box(Vector3(-16.0, 0.9, -0.1), Vector3(0.8, 0.5, 0.1), "metal", Color(0.3, 0.32, 0.31), 1.0)  # the hatch they hand bottles through
	box(Vector3(-16.0, 2.3, -0.3), Vector3(2.4, 0.08, 0.7), "paint", Color(0.35, 0.35, 0.35), 1.0)
	Street.plate(self, Vector3(-14.4, 1.7, -0.012), Vector3.FORWARD, "tara", Vector2(1.0, 0.5))
	box(Vector3(-16.0, -0.04, -6.5), Vector3(1.4, 0.12, 12.0), "ext_asphalt", Color(0.75, 0.7, 0.62), 2.0, MeshFactory.PY)
	Equip.bottle_crates(self, _rng, Vector3(-17.6, 0, -0.9), 0.0, 6)
	Equip.bottle_crates(self, _rng, Vector3(-14.2, 0, -1.4), 0.3, 3)
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
		# From just behind the glass, high, so its brightest spot lands on
		# the porch outside and not on the floor right behind the doors.
		spill.position = Vector3(2.5, PORCH + 3.0, -0.2)
		spill.rotation.x = deg_to_rad(-135)
		spill.spot_range = 10.0
		spill.spot_angle = 75.0
		spill.spot_attenuation = 1.4
		spill.light_energy = 1.0
		spill.light_color = Store.TUBE_COLOR
		add_child(spill)
		# Warm light on the steps, as the glass throws it out into the rain.
		var porch := OmniLight3D.new()
		porch.position = Vector3(2.5, PORCH + 1.6, -2.0)
		porch.omni_range = 4.5
		porch.omni_attenuation = 1.6
		porch.light_energy = 1.6
		porch.light_color = Store.TUBE_COLOR.lerp(Color(1.0, 0.8, 0.55), 0.5)
		add_child(porch)


## The nine-storey panel blocks round the square, in 12 m sections.
func _build_blocks() -> void:
	_block(Vector3(70, 0, 2), Vector3(22, 0, 2), 9, 12.0, true)  # left of the store, as on the photo
	_block(Vector3(-36, 0, -70), Vector3(36, 0, -70), 9, 12.0)   # across the road, behind the camera
	_block(Vector3(-44, 0, 30), Vector3(-44, 0, -18), 9, 12.0)   # far right
	_block(Vector3(40, 0, -44), Vector3(64, 0, -44), 9, 12.0)


## By day the eye carries past the square (day four, the day cutscenes): the
## rest of МЖК round it. A second ring of nine-storey blocks behind the first,
## sixteen-storey towers and further blocks fading into the haze, the lawns
## and yards between them with birches and firs, a row of tin garages and a
## children's playground beside the store, ground all the way to the horizon.
func _build_district() -> void:
	# Ground out to the haze: lawn round the asphalt of the square and roads.
	for r: Array in [[Vector3(0, -0.12, -170), Vector3(560, 0.1, 196)], [Vector3(0, -0.12, 170), Vector3(560, 0.1, 196)],
			[Vector3(-176, -0.12, 0), Vector3(208, 0.1, 144)], [Vector3(176, -0.12, 0), Vector3(208, 0.1, 144)]]:
		box(r[0], r[1], "ext_grass", Color(0.92, 0.92, 0.86), 6.0, MeshFactory.PY)
	# The road runs on out of the square both ways.
	for x: float in [-160.0, 160.0]:
		box(Vector3(x, -0.07, ROAD_Z), Vector3(176, 0.1, 9), "ext_asphalt", Color(0.7, 0.7, 0.72), 3.0, MeshFactory.PY)
		box(Vector3(x, -0.06, ROAD_Z + 6.1), Vector3(176, 0.1, 2.8), "ext_asphalt", Color(1.35, 1.32, 1.28), 3.0, MeshFactory.PY)
		box(Vector3(x, -0.06, ROAD_Z - 6.1), Vector3(176, 0.1, 2.8), "ext_asphalt", Color(1.35, 1.32, 1.28), 3.0, MeshFactory.PY)
	# The second ring of nine-storey blocks, then the towers.
	_block(Vector3(-112, 0, -96), Vector3(-52, 0, -96), 9, 12.0)
	_block(Vector3(50, 0, -102), Vector3(110, 0, -102), 9, 12.0)
	_block(Vector3(-80, 0, -26), Vector3(-80, 0, -86), 9, 12.0)
	_block(Vector3(40, 0, 78), Vector3(-44, 0, 78), 9, 12.0)
	_block(Vector3(110, 0, -40), Vector3(110, 0, 22), 9, 12.0)
	_block(Vector3(-30, 0, -138), Vector3(-8, 0, -138), 16, 14.0)
	_block(Vector3(18, 0, -150), Vector3(40, 0, -150), 16, 14.0)
	_block(Vector3(-124, 0, -36), Vector3(-124, 0, -58), 16, 14.0)
	_block(Vector3(140, 0, -70), Vector3(140, 0, -48), 16, 14.0)
	# Far off in the haze, the rest of the estate.
	for f: Array in [[Vector3(-150, 0, -190), Vector3(-80, 0, -190), 9], [Vector3(-40, 0, -210), Vector3(30, 0, -210), 12],
			[Vector3(70, 0, -200), Vector3(140, 0, -200), 9], [Vector3(-200, 0, -60), Vector3(-200, 0, -140), 9],
			[Vector3(200, 0, -140), Vector3(200, 0, -60), 12], [Vector3(-190, 0, 40), Vector3(-190, 0, -20), 16],
			[Vector3(190, 0, 0), Vector3(190, 0, 60), 9], [Vector3(60, 0, 170), Vector3(-60, 0, 170), 12]]:
		_block(f[0], f[1], f[2], 12.0)
	# Birches along the far pavement and in the yards, firs by the blocks.
	for k in 14:
		_birch(Vector3(-66.0 + k * 10.0 + _rng.randf_range(-2, 2), 0, ROAD_Z - 9.0 + _rng.randf_range(-0.8, 0.8)))
	for c: Vector3 in [Vector3(-62, 0, -60), Vector3(-30, 0, -84), Vector3(70, 0, -86), Vector3(92, 0, -20),
			Vector3(-68, 0, 20), Vector3(60, 0, 40)]:
		for k in 3:
			var p := c + Vector3(_rng.randf_range(-7, 7), 0, _rng.randf_range(-7, 7))
			if k == 0:
				_fir(p, _rng.randf_range(7.0, 10.0))
			else:
				_birch(p)
	_garages(Vector3(-74, 0, -42), 8)
	_playground(Vector3(-34, 0, -1))


## A row of tin garages, each with its own colour of door and a padlock.
func _garages(at: Vector3, count: int) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var tin := kit.b("corrugated", Color(0.62, 0.62, 0.58))
	var roof := kit.b("rubber", Color(0.18, 0.18, 0.18))
	var doors := [Color(0.3, 0.42, 0.32), Color(0.5, 0.22, 0.18), Color(0.3, 0.36, 0.5), Color(0.62, 0.6, 0.55),
		Color(0.45, 0.4, 0.3)]
	for i in count:
		var x := at.x + i * 3.2
		tin.box(Props.at(x, 0, at.z - 3.0), Vector3(3.1, 2.3, 6.0))
		roof.box(Props.at(x, 2.3, at.z - 3.0), Vector3(3.2, 0.06, 6.2))
		kit.b("paint", doors[_rng.randi() % doors.size()]).box(Props.at(x, 0.05, at.z + 0.01), Vector3(2.6, 2.1, 0.04))
		kit.b("metal", Color(0.2, 0.2, 0.2)).box(Props.at(x + 0.15, 1.0, at.z + 0.05), Vector3(0.08, 0.12, 0.05))
	kit.build(self)


## A yard playground of the 1980s: a steel slide, a swing on an A-frame, a
## sandpit with a wooden rim and a bench for the grandmothers.
func _playground(at: Vector3) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var red := kit.b("paint", Color(0.7, 0.2, 0.15))
	var blue := kit.b("paint", Color(0.25, 0.4, 0.62))
	var steel := kit.b("chrome", Color(0.8, 0.8, 0.78))
	var wood := kit.b("wood", Color(0.75, 0.62, 0.45))
	box(at + Vector3(0, -0.04, 0), Vector3(16, 0.1, 9), "ext_grass", Color(0.85, 0.82, 0.7), 4.0, MeshFactory.PY)
	# Slide: ladder up to a platform, the chute down to the grass.
	var sl := at + Vector3(-4, 0, 0)
	for sx: float in [-0.35, 0.35]:
		red.box(Props.at(sl.x + sx, 0, sl.z + 1.0), Vector3(0.06, 1.8, 0.06))
		red.box(Props.at(sl.x + sx, 0, sl.z + 0.4), Vector3(0.06, 1.8, 0.06))
	blue.box(Props.at(sl.x, 1.75, sl.z + 0.7), Vector3(0.8, 0.06, 0.8))
	for k in 5:
		red.box(Props.at(sl.x, 0.3 + k * 0.32, sl.z + 1.25), Vector3(0.7, 0.04, 0.06))
	steel.box(Props.rot(Vector3.RIGHT, -0.6, sl + Vector3(0, 0.95, -0.6)), Vector3(0.6, 0.03, 2.6))
	# Swing: two A-frames and a bar, a seat on chains.
	var sw := at + Vector3(2.5, 0, 0)
	for sx: float in [-1.2, 1.2]:
		for sz: float in [-0.5, 0.5]:
			blue.box(Props.rot(Vector3.RIGHT, -sz * 0.5, sw + Vector3(sx, 0, sz)), Vector3(0.07, 2.4, 0.07))
	blue.box(Props.at(sw.x, 2.3, sw.z), Vector3(2.5, 0.07, 0.07))
	for sx: float in [-0.25, 0.25]:
		steel.box(Props.at(sw.x + sx, 0.45, sw.z), Vector3(0.015, 1.85, 0.015))
	wood.box(Props.at(sw.x, 0.42, sw.z), Vector3(0.6, 0.04, 0.25))
	# Sandpit.
	var sp := at + Vector3(0, 0, 3)
	for side: Array in [[Vector3(0, 0, -1.0), Vector3(2.2, 0.25, 0.12)], [Vector3(0, 0, 1.0), Vector3(2.2, 0.25, 0.12)],
			[Vector3(-1.05, 0, 0), Vector3(0.12, 0.25, 2.1)], [Vector3(1.05, 0, 0), Vector3(0.12, 0.25, 2.1)]]:
		wood.box(Props.at(sp.x + side[0].x, 0, sp.z + side[0].z), side[1])
	kit.b("concrete", Color(0.85, 0.75, 0.55)).box(Props.at(sp.x, 0, sp.z), Vector3(2.0, 0.15, 1.9))
	kit.build(self)
	Street.bench(self, at + Vector3(5.5, 0, 3.0), PI * 0.5)


## A panel block whose facade runs from `a` to `b` (seen from the front, a is
## on the left) with `depth` metres behind it; lit windows at night.
func _block(a: Vector3, b: Vector3, floors: int, depth: float, slogan := false) -> void:
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
	var shade := _rng.randf_range(0.78, 0.9)
	var facade := kit.b("ext_panel", Color(shade, shade * 0.98, shade * 0.95))
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
	# The plinth: darker concrete, splashed by the rain, its basement vents.
	var plinth := kit.b(Street.TEX)
	var segs := int(ceil(length / 6.0))
	for i in segs:
		var sx := -hx + (i + 0.5) * length / segs
		plinth.box(Props.at(sx, 0, 0), Vector3(length / segs, 0.9, depth + 0.2), Color.WHITE,
			Street._cell("panel_plinth"), Vector2.ONE, MeshFactory.PZ | MeshFactory.NZ)
	plinth.box(Props.at(0, 0, 0), Vector3(length + 0.2, 0.9, depth + 0.2), Color.WHITE, Street._cell("panel_plinth"),
		Vector2.ONE, MeshFactory.PX | MeshFactory.NX)
	# On the roof: a lift-machine room over every entrance.
	var entrances := maxi(1, int(length / 16.0))
	var roof := kit.b("concrete", Color(0.55, 0.55, 0.53))
	for k in entrances:
		var ex := -hx + (k + 0.5) * length / entrances
		roof.box(Props.at(ex, h + 0.5, 0), Vector3(3.2, 2.4, 4.5))
		roof.box(Props.at(ex + 1.0, h + 2.9, -1.2), Vector3(0.6, 0.8, 0.6))
	if slogan:
		var frame := kit.b("metal", Color(0.3, 0.3, 0.3))
		for fx: float in [-4.5, -1.5, 1.5, 4.5]:
			frame.box(Props.at(fx, h + 0.5, hz - 1.4), Vector3(0.1, 4.0, 0.1))
			frame.box(Props.rot(Vector3.RIGHT, -0.5, Vector3(fx, h + 0.5, hz - 2.6)), Vector3(0.08, 3.6, 0.08))
		kit.b(Street.TEX).box(Props.at(0, h + 1.2, hz - 1.3), Vector3(10.0, 3.3, 0.06), Color.WHITE, Street._cell("slogan"),
			Vector2.ONE, MeshFactory.PZ)
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
	for k in entrances:
		Street.entrance(node, Vector3(-hx + (k + 0.5) * length / entrances, 0, hz), PI, look == "night", k + 1)


func _build_green() -> void:
	# The lawn on the right of the steps with its firs, as in the photo.
	box(Vector3(-14.5, -0.05, -6.5), Vector3(18, 0.12, 12), "ext_grass", Color.WHITE, 3.0, MeshFactory.PY)
	Street.fence(self, Vector3(-23.3, 0, -12.8), Vector3(-16.9, 0, -12.8))
	Street.fence(self, Vector3(-15.1, 0, -12.8), Vector3(-5.9, 0, -12.8))
	for lp: Vector3 in [Vector3(-11.0, 0.07, -5.0), Vector3(-19.5, 0.07, -7.0), Vector3(-8.0, 0.07, -10.0)]:
		Street.decal(self, lp, 3.5, "leaves", _rng.randf() * TAU)
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
	# Drooping whorls of branches, each a ragged skirt of tilted cones: dense
	# and dark inside, the tips lighter.
	var tiers := 13
	for i in tiers:
		var t := float(i) / tiers
		var r := lerpf(h * 0.3, h * 0.04, pow(t, 0.9)) * _rng.randf_range(0.85, 1.1)
		var y := h * (0.12 + t * 0.82)
		for k in 3:
			var a := _rng.randf() * TAU
			var tilt := Basis(Vector3(cos(a), 0, sin(a)), _rng.randf_range(0.04, 0.16))
			var col := Color.WHITE * (0.75 + 0.25 * t) * _rng.randf_range(0.85, 1.1)
			col.a = 1.0
			needles.cylinder(Transform3D(tilt * Basis(Vector3.UP, a), p + Vector3(0, y - k * 0.08, 0)), r * (1.0 - k * 0.12),
				0.04, h * 0.14, 10, col, Rect2(0, 0, 3, 1))
	kit.build(self)


func _birch(p: Vector3) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var bark := kit.b(Street.TEX)
	bark.cylinder(Props.at(p.x, 0, p.z), 0.17, 0.06, 9.0, 8, Color(0.78, 0.77, 0.74), Street._cell("bark"))
	var twig := kit.b("wood", Color(0.25, 0.2, 0.18))
	for i in 30:
		var y := 2.6 + i * 0.21
		var a := _rng.randf() * TAU
		var ln := lerpf(2.2, 0.6, i / 30.0)
		var dir := Vector3(cos(a), 0.9, sin(a)).normalized()
		var root := p + Vector3(0, y, 0)
		var tip := root + dir * ln
		twig.capsule(Transform3D.IDENTITY, root, tip, 0.04, 0.012, 5)
		# Weeping twigs hanging off each branch, as on a birch.
		for k in 3:
			var q := root.lerp(tip, 0.45 + k * 0.25)
			twig.capsule(Transform3D.IDENTITY, q, q + Vector3(_rng.randf_range(-0.2, 0.2), -_rng.randf_range(0.5, 1.1),
				_rng.randf_range(-0.2, 0.2)), 0.008, 0.004, 3)
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


## Kiosk, bus stop, phone booths, benches, urns and bins round the square.
func _build_street() -> void:
	Street.kiosk(self, Vector3(-15.5, 0, -16.8), 0.0)
	Street.bus_stop(self, Vector3(-38.0, 0.12, ROAD_Z + 6.4), 0.0)
	booths = Street.phone_booths(self, Vector3(14.3, 0, -2.0), 0.0, 1 if embedded else -1)
	for u: Vector3 in [Vector3(-4.6, 0, -7.7), Vector3(9.6, 0, -7.7), Vector3(-13.5, 0, -13.4), Vector3(-37.0, 0.12, ROAD_Z + 4.9)]:
		Street.urn(self, u)
	Street.bench(self, Vector3(-10.5, 0, -13.5), 0.0)
	Street.bench(self, Vector3(-19.5, 0, -13.5), 0.0)
	Street.bins(self, Vector3(20.5, 0, -3.0), -0.15)
	for lp: Vector3 in [Vector3(-18.0, 0.12, ROAD_Z + 6.0), Vector3(-6.0, 0.0, ROAD_Z + 6.2), Vector3(18.0, 0.12, ROAD_Z + 6.0),
			Vector3(30.0, 0.12, ROAD_Z + 5.8)]:
		Street.decal(self, lp, 3.0, "leaves", _rng.randf() * TAU)


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
	# Lit drops: they flash in the lamplight and the headlights and all but
	# vanish in the dark between the lamps, as rain does.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if Settings.graphics >= Graphics.MEDIUM \
		else BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.75, 0.8, 0.22)
	if m.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		m.albedo_color = Color(0.9, 0.93, 1.0, 0.35)
		m.emission_enabled = true
		m.emission = Color(0.05, 0.055, 0.065)
		m.roughness = 0.1
		m.metallic_specular = 1.0
		m.backlight_enabled = true
		m.backlight = Color(0.6, 0.6, 0.65)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	# No drops right at the lens (nor inside the car in the shots from the seat).
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = 1.3
	m.distance_fade_max_distance = 2.6
	q.material = m
	rain.mesh = q
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)


## Day: the last birch and poplar leaves coming down off the trees round the
## square, tumbling, drifting with the wind.
func _build_leaves() -> void:
	leaves = CPUParticles3D.new()
	leaves.amount = 420
	leaves.lifetime = 9.0
	leaves.preprocess = 9.0
	leaves.local_coords = false
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(22, 1.5, 22)
	leaves.direction = Vector3(1, -0.3, 0.4)
	leaves.spread = 40.0
	leaves.gravity = Vector3(0.25, -0.55, 0.1)
	leaves.initial_velocity_min = 0.2
	leaves.initial_velocity_max = 0.9
	leaves.angle_min = 0.0
	leaves.angle_max = 360.0
	leaves.angular_velocity_min = -160.0
	leaves.angular_velocity_max = 160.0
	leaves.scale_amount_min = 0.6
	leaves.scale_amount_max = 1.2
	leaves.damping_min = 0.2
	leaves.damping_max = 0.5
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.1)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://textures/leaves.png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.particles_anim_h_frames = 2
	m.particles_anim_v_frames = 2
	m.backlight_enabled = true
	m.backlight = Color(0.5, 0.4, 0.1)
	m.roughness = 0.7
	q.material = m
	leaves.mesh = q
	leaves.anim_offset_min = 0.0
	leaves.anim_offset_max = 1.0
	leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(leaves)


## Keeps the rain falling round the camera.
func follow(cam: Camera3D) -> void:
	if rain:
		rain.global_position = cam.global_position + Vector3(0, 9, 0) - cam.global_basis.z * 6.0
	if leaves:
		leaves.global_position = cam.global_position + Vector3(0, 7, 0) - cam.global_basis.z * 8.0


## Signs lit (night) or dark (day).
func light_signs(on: bool) -> void:
	for m in sign_mats:
		m.set_shader_parameter("emission", Color(0.9, 0.85, 0.8) if on else Color.BLACK)
