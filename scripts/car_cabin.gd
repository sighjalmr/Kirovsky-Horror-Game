class_name CarCabin
extends RefCounted

## The inside of Gordeev's ВАЗ-2106, for the shots from the driver's seat:
## the black padded dash with its hooded cluster (speedometer, tachometer,
## fuel, temperature), the clock and the «Урал» radio in the middle, a strip
## of wood-look trim and the glovebox on the passenger's side; the thin
## two-spoke wheel on its column with the stalks, Gordeev's hands on the rim
## at ten to two; the A-pillars, the header and the headliner, sun visors,
## the mirror, the door cards with the window cranks; the checked cloth
## seats. The body, the glass and the quarter-light posts are the car
## model's own (tools/build_cars.py).
## Car frame as in Vehicles: nose towards -Z, ground at y = 0, the driver on
## the left (-X).
## Adds to the car:
##   meta "seat"   Vector3 the driver's eye point
##   meta "steer"  Node3D the wheel and the hands; turn it about its local Z
##                 (positive turns the wheel left)
##   meta "dash"   Array: the cluster glow lights and the gauge material

const EYE := Vector3(-0.36, 1.14, 0.10)
## Centre of the wheel, and how far its top leans away from the driver.
const WHEEL := Vector3(-0.36, 0.86, -0.32)
const WHEEL_TILT := 28.0
const HANDS := "res://models/wheel_hands/wheel_hands.glb"
const GLOW := Color(0.55, 0.62, 0.42)


static func build(car: Node3D, s: Dictionary) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var g: Array = s.glass
	var hw: float = s.hw
	var belt: float = s.belt
	var roof: float = s.roof
	var rw := hw - 0.12
	var vinyl := kit.b("leather", Color(0.13, 0.125, 0.12))
	var card := kit.b("leather", Color(0.27, 0.19, 0.14))
	var beige := kit.b("leather", Color(0.52, 0.47, 0.4))
	var liner := kit.b("fabric", Color(0.7, 0.68, 0.62))
	var chrome := kit.b("chrome")
	var black := kit.b("rubber", Color(0.08, 0.08, 0.08))
	var wood := kit.b("wood", Color(0.62, 0.42, 0.28))
	var carpet := kit.b("cloth", Color(0.12, 0.11, 0.1))
	var cloth := kit.b("car_seat")
	var gauge_mat := Mats.unique("car_gauges", Color.WHITE, GLOW)
	var gauges := kit.custom(gauge_mat)
	var console := kit.b("car_console", Color.WHITE, Color(0.1, 0.1, 0.09))
	var w := hw * 2.0 - 0.14
	var dz0: float = g[0]          # foot of the windscreen
	var dz1 := -0.52               # back edge of the dash

	# --- Dash: the padded top and its rounded lip either side of the
	# cluster, the face below.
	var bx := WHEEL.x
	var c0 := bx - 0.25
	var c1 := bx + 0.25
	var zc := -0.63                 # back of the cluster's recess
	vinyl.box(Props.at((-w * 0.5 + c0) * 0.5, 0.86, (dz0 + dz1) * 0.5), Vector3(c0 + w * 0.5, 0.07, dz1 - dz0))
	vinyl.box(Props.at((c1 + w * 0.5) * 0.5, 0.86, (dz0 + dz1) * 0.5), Vector3(w * 0.5 - c1, 0.07, dz1 - dz0))
	vinyl.box(Props.at(bx, 0.86, (dz0 + zc) * 0.5), Vector3(0.5, 0.07, zc - dz0))
	vinyl.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(w * 0.5, 0.895, dz1)), 0.036, 0.036, w * 0.5 - c1, 12)
	vinyl.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(c0, 0.895, dz1)), 0.036, 0.036, c0 + w * 0.5, 12)
	vinyl.box(Props.at((-w * 0.5 + c0) * 0.5, 0.56, dz1 - 0.03), Vector3(c0 + w * 0.5, 0.3, 0.05))
	vinyl.box(Props.at((c1 + w * 0.5) * 0.5, 0.56, dz1 - 0.03), Vector3(w * 0.5 - c1, 0.3, 0.05))
	vinyl.box(Props.at(bx, 0.56, dz1 - 0.03), Vector3(0.5, 0.26, 0.05))
	# Wood-look strip and the glovebox on the passenger's side.
	wood.box(Props.at(0.36, 0.76, dz1 - 0.003), Vector3(0.62, 0.06, 0.012))
	card.box(Props.at(0.38, 0.63, dz1 - 0.004), Vector3(0.42, 0.1, 0.014))
	chrome.box(Props.at(0.38, 0.715, dz1 + 0.004), Vector3(0.05, 0.012, 0.01))
	# The middle: clock, radio, heater sliders on one panel.
	var cx := 0.02
	console.quad(Transform3D.IDENTITY, [Vector3(cx - 0.15, 0.6, dz1 + 0.002), Vector3(cx + 0.15, 0.6, dz1 + 0.002),
		Vector3(cx + 0.15, 0.75, dz1 + 0.002), Vector3(cx - 0.15, 0.75, dz1 + 0.002)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE, false)
	# Air vents at both ends of the dash.
	for vx: float in [-w * 0.5 + 0.1, w * 0.5 - 0.1]:
		black.box(Props.at(vx, 0.79, dz1 - 0.002), Vector3(0.1, 0.05, 0.01))
		for k in 4:
			chrome.box(Props.at(vx, 0.797 + k * 0.011, dz1 + 0.004), Vector3(0.09, 0.003, 0.006))

	# --- The cluster in its recess under a hood, in front of the driver.
	vinyl.box(Props.at(bx, 0.955, (zc + dz1 + 0.05) * 0.5), Vector3(0.5, 0.045, dz1 + 0.05 - zc))
	vinyl.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(c1, 0.977, dz1 + 0.05)), 0.022, 0.022, 0.5, 10)
	for sx: float in [-1.0, 1.0]:
		vinyl.box(Props.at(bx + sx * 0.24, 0.82, (zc + dz1 + 0.05) * 0.5), Vector3(0.022, 0.14, dz1 + 0.05 - zc))
	vinyl.box(Props.at(bx, 0.815, (zc + dz1) * 0.5), Vector3(0.48, 0.025, dz1 - zc))
	black.box(Props.at(bx, 0.82, zc - 0.005), Vector3(0.48, 0.14, 0.01))
	var gz := zc + 0.02
	gauges.quad(Transform3D.IDENTITY, [Vector3(bx - 0.215, 0.845, gz), Vector3(bx + 0.215, 0.845, gz),
		Vector3(bx + 0.215, 0.952, gz - 0.015), Vector3(bx - 0.215, 0.952, gz - 0.015)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE, false)

	# --- The column from the wheel into the dash, and its stalks.
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-WHEEL_TILT))
	var toward := tilt * Vector3.BACK          # out of the wheel at the driver
	var col := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-WHEEL_TILT - 90.0)), WHEEL - toward * 0.07)
	vinyl.cylinder(col, 0.042, 0.05, 0.26, 14)
	for sx: float in [-1.0, 1.0]:
		var root := WHEEL - toward * 0.1 + Vector3(sx * 0.035, 0.0, 0.0)
		var tip := root + Vector3(sx * 0.15, 0.03, 0.02)
		var d := tip - root
		var st := Transform3D(Basis.looking_at(d.normalized(), Vector3.UP), (root + tip) * 0.5)
		black.box(st * Transform3D(Basis.IDENTITY, Vector3(0, -0.004, 0)), Vector3(0.008, 0.008, d.length()))
		black.box(Transform3D(st.basis, tip), Vector3(0.016, 0.016, 0.04))

	# --- Pillars, header, headliner, visors, the mirror.
	for sx: float in [-1.0, 1.0]:
		var a := Vector3(sx * (hw - 0.09), belt, g[0] + 0.02)
		var b := Vector3(sx * (rw - 0.03), roof - 0.03, g[1] + 0.02)
		var d := b - a
		var xf := Transform3D(Basis.looking_at(d.normalized(), Vector3(-sx, 0, 0)), (a + b) * 0.5)
		vinyl.box(xf * Transform3D(Basis.IDENTITY, Vector3(0, -0.03, 0)), Vector3(0.08, 0.04, d.length()))
	vinyl.box(Props.at(0, roof - 0.07, g[1] + 0.05), Vector3(rw * 2.0 - 0.04, 0.05, 0.09))
	liner.box(Props.at(0, roof - 0.04, (g[1] + g[2]) * 0.5 + 0.05), Vector3(rw * 2.0 - 0.04, 0.012, g[2] - g[1] - 0.05))
	for sx: float in [-1.0, 1.0]:
		beige.box(Props.rot(Vector3.RIGHT, -0.12, Vector3(sx * 0.36, roof - 0.085, g[1] + 0.1)), Vector3(0.36, 0.016, 0.15))
		chrome.box(Props.at(sx * 0.36 - sx * 0.19, roof - 0.07, g[1] + 0.06), Vector3(0.02, 0.02, 0.02))
	black.box(Props.at(0, roof - 0.12, g[1] + 0.06), Vector3(0.012, 0.05, 0.012))
	black.box(Props.at(0, roof - 0.17, g[1] + 0.07), Vector3(0.22, 0.06, 0.025))
	kit.b("chrome", Color(0.35, 0.37, 0.4)).quad(Transform3D.IDENTITY, [Vector3(-0.1, roof - 0.165, g[1] + 0.083),
		Vector3(0.1, roof - 0.165, g[1] + 0.083), Vector3(0.1, roof - 0.115, g[1] + 0.083), Vector3(-0.1, roof - 0.115, g[1] + 0.083)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE, false)
	# A pennant on a string from the mirror, the kind every taxi had.
	var pen := Props.rot(Vector3.UP, 0.4, Vector3(0.04, roof - 0.3, g[1] + 0.07))
	black.box(Props.at(0.04, roof - 0.27, g[1] + 0.07), Vector3(0.002, 0.1, 0.002))
	kit.b("white", Color(0.75, 0.1, 0.08), Color(0.04, 0.0, 0.0), Mats.DOUBLE).quad(pen, [Vector3(-0.04, 0.0, 0), Vector3(0.04, 0.0, 0),
		Vector3(0.04, 0.03, 0), Vector3(-0.04, 0.03, 0)], [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE, false)

	# --- Door cards, armrests, window cranks.
	for sx: float in [-1.0, 1.0]:
		var x := sx * (hw - 0.07)
		card.box(Props.at(x, 0.3, 0.02), Vector3(0.02, belt - 0.32, 1.0))
		black.box(Props.at(x - sx * 0.005, belt - 0.03, 0.02), Vector3(0.06, 0.04, 1.0))
		card.box(Props.at(x - sx * 0.04, 0.6, 0.1), Vector3(0.06, 0.05, 0.36))
		chrome.box(Props.at(x - sx * 0.02, 0.7, -0.28), Vector3(0.02, 0.025, 0.1))
		var crank := Vector3(x - sx * 0.02, 0.52, -0.12)
		chrome.cylinder(Props.rot(Vector3.BACK, sx * PI * 0.5, crank), 0.022, 0.018, 0.02, 10)
		chrome.box(Props.rot(Vector3.RIGHT, 0.6, crank + Vector3(-sx * 0.025, 0, 0)), Vector3(0.012, 0.012, 0.1))
		black.cylinder(Props.rot(Vector3.BACK, sx * PI * 0.5, crank + Vector3(-sx * 0.03, -0.03, 0.045)), 0.01, 0.01, 0.04, 8)

	# --- Seats in the checked cloth, the floor, the tunnel, the gear lever.
	for sx: float in [-0.36, 0.36]:
		cloth.box(Props.at(sx, 0.32, 0.12), Vector3(0.5, 0.16, 0.5))
		cloth.box(Props.rot(Vector3.RIGHT, -0.22, Vector3(sx, 0.46, 0.36)), Vector3(0.48, 0.6, 0.13))
		cloth.box(Props.rot(Vector3.RIGHT, -0.22, Vector3(sx, 1.05, 0.5)), Vector3(0.26, 0.17, 0.08))
	# The rear bench, its back against the parcel shelf under the rear window.
	var rz: float = g[3] - 0.1
	cloth.box(Props.at(0, 0.33, rz - 0.3), Vector3(w - 0.1, 0.15, 0.45))
	cloth.box(Props.rot(Vector3.RIGHT, -0.25, Vector3(0, 0.44, rz - 0.04)), Vector3(w - 0.1, 0.44, 0.1))
	carpet.box(Props.at(0, 0.335, 0.1), Vector3(w, 0.02, 1.9))
	carpet.box(Props.at(0, 0.335, 0.0), Vector3(0.22, 0.1, 1.4))
	black.cylinder(Props.rot(Vector3.RIGHT, 0.3, Vector3(0, 0.36, -0.28)), 0.007, 0.006, 0.3, 8)
	black.lathe(Props.at(0, 0.64, -0.2), [Vector2(0.0, -0.02), Vector2(0.02, -0.015), Vector2(0.024, 0.0), Vector2(0.02, 0.016),
		Vector2(0.0, 0.022)], 12)
	# --- The footwell: the toe board up to the dash, a rubber mat, the three
	# pendant pedals of a 2106 (clutch, brake, the narrow accelerator).
	carpet.box(Props.rot(Vector3.RIGHT, -0.9, Vector3(0, 0.345, -0.6)), Vector3(w, 0.22, 0.02))
	black.box(Props.at(-0.38, 0.355, -0.3), Vector3(0.46, 0.012, 0.56))
	var steel := kit.b("metal", Color(0.3, 0.3, 0.3))
	for p: Array in [[-0.5, 0.075], [-0.37, 0.075], [-0.25, 0.045]]:
		var px: float = p[0]
		var top := Vector3(px, 0.68, -0.62)
		var pad := Vector3(px, 0.47, -0.56)
		var arm := Transform3D(Basis.looking_at((pad - top).normalized(), Vector3.BACK), (top + pad) * 0.5)
		steel.box(arm, Vector3(0.014, 0.008, top.distance_to(pad)))
		black.box(Props.rot(Vector3.RIGHT, -0.45, pad), Vector3(p[1], 0.012, 0.07 if px > -0.3 else 0.055))
	kit.build(car, false)
	var legs := DriverLegs.make(Vector3(-0.36, 0.53, 0.24))
	car.add_child(legs)
	for mi: MeshInstance3D in legs.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The skirts of his coat over his lap.
	var lap := MeshBuilder.Kit.new()
	lap.ao = false
	var wool := lap.b("guard_wool")
	wool.ellipsoid(Props.at(-0.36, 0.6, 0.16), Vector3(0.23, 0.075, 0.2), 20, 10)
	for sx: float in [-0.12, 0.12]:
		wool.ellipsoid(Props.rot(Vector3.RIGHT, 0.12, Vector3(-0.36 + sx, 0.6, 0.0)), Vector3(0.1, 0.06, 0.16), 16, 8)
	lap.build(car, false)

	# A little of the dash's light falls into the footwell.
	var well := OmniLight3D.new()
	well.light_color = Color(0.75, 0.8, 0.7)
	well.light_energy = 0.6
	well.omni_range = 1.0
	well.position = Vector3(-0.36, 0.62, -0.3)
	car.add_child(well)

	# --- The wheel with the hands, on a pivot so it can steer.
	var pivot := Node3D.new()
	pivot.name = "Wheel"
	pivot.position = WHEEL
	pivot.basis = tilt
	car.add_child(pivot)
	var steer := Node3D.new()
	pivot.add_child(steer)
	var hands: Node3D = (load(HANDS) as PackedScene).instantiate()
	steer.add_child(hands)
	var skin := _skin()
	for mi: MeshInstance3D in hands.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.name.begins_with("hand"):
			mi.material_override = skin
		elif mi.name.begins_with("sleeve"):
			mi.material_override = Mats.get_mat("guard_wool")
		elif mi.name == "wheel_badge":
			mi.material_override = Mats.get_mat("chrome")
		else:
			mi.material_override = Mats.get_mat("leather", Color(0.09, 0.09, 0.09))

	# --- The cluster's glow on the hands and the wheel, a little street light.
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.7, 0.95, 0.65)
	glow.light_energy = 0.35
	glow.omni_range = 0.6
	glow.position = Vector3(bx, 0.93, zc + 0.12)
	car.add_child(glow)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.62, 0.68, 0.85)
	fill.light_energy = 0.14
	fill.omni_range = 1.3
	fill.position = Vector3(-0.15, 1.25, -0.15)
	car.add_child(fill)

	car.set_meta("seat", EYE)
	car.set_meta("steer", steer)
	car.set_meta("dash", [glow, fill, gauge_mat])


## Dash lights on with the ignition, off when he parks.
static func set_dash(car: Node3D, on: bool) -> void:
	if not car.has_meta("dash"):
		return
	var d: Array = car.get_meta("dash")
	(d[0] as OmniLight3D).visible = on
	(d[1] as OmniLight3D).visible = on
	(d[2] as ShaderMaterial).set_shader_parameter("emission", GLOW if on else Color.BLACK)


## The same skin as the torch hand: the photo texture graded paler and
## greyer for a man past sixty, with its own relief and roughness.
static func _skin() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://models/hand/hand_skin.png")
	m.normal_enabled = true
	m.normal_texture = load("res://models/hand/hands_normal.png")
	m.normal_scale = 0.5
	m.ao_enabled = true
	m.ao_texture = load("res://models/hand/hands_occlusionRoughnessMetallic.png")
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness_texture = m.ao_texture
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.roughness = 1.0
	m.metallic_specular = 0.35
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m
