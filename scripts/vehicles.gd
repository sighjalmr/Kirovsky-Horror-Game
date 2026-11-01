class_name Vehicles
extends RefCounted

## Cars of 1988 for the street scenes: Gordeev's ВАЗ-2106 «Жигули» (four
## round headlamps in a black grille, a chrome bumper with fangs, a pale blue
## paint gone chalky) and the director's black ГАЗ-24 «Волга». Built from
## lofted cross-sections, nose towards -Z, wheels on the ground at y = 0.
## The returned node carries:
##   meta "beams"  Array[SpotLight3D]  headlights (off: energy 0)
##   meta "lamps"  Array[ShaderMaterial] headlamp glass, for lights on/off
##   meta "tail"   ShaderMaterial red rear lamps
##   meta "wiper"  Node3D the driver's wiper, rotates about its local Z
##   meta "door"   Node3D the driver's door, hinged at the front
##   meta "seat"   Vector3 the driver's eye point (for the shot from inside)

const ZHIGULI := {
	"len": 4.17, "hw": 0.8, "paint": Color(0.55, 0.66, 0.72), "bottom": 0.26,
	"hood": [0.80, 0.86, 0.9], "trunk": [0.9, 0.86, 0.8],
	"glass": [-0.78, -0.2, 0.62, 1.15], "roof": 1.40, "belt": 0.92, "quad": true,
	"wheel_z": [-1.28, 1.15], "plate": true,
}
const VOLGA := {
	"len": 4.74, "hw": 0.9, "paint": Color(0.05, 0.05, 0.055), "bottom": 0.24,
	"hood": [0.78, 0.84, 0.88], "trunk": [0.9, 0.86, 0.78],
	"glass": [-0.75, -0.12, 0.85, 1.4], "roof": 1.45, "belt": 0.9, "quad": false,
	"wheel_z": [-1.42, 1.43], "plate": false,
}

const HEADLIGHT := 9.0


static func zhiguli() -> Node3D:
	return build(ZHIGULI)


static func volga() -> Node3D:
	return build(VOLGA)


static func build(s: Dictionary) -> Node3D:
	var car := Node3D.new()
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var hl: float = s.len * 0.5
	var hw: float = s.hw
	var bot: float = s.bottom
	var paint := kit.b("paint", s.paint)
	var chrome := kit.b("chrome", Color(0.9, 0.9, 0.92))
	var black := kit.b("rubber", Color(0.12, 0.12, 0.12))
	var glass_kind := kit.b("glass", Color(0.12, 0.15, 0.18, 0.55), Color.BLACK, Mats.GLASS)

	# Lower body: stations front to back, each a rounded box section.
	var g: Array = s.glass
	var hood: Array = s.hood
	var trunk: Array = s.trunk
	var stations := [
		[-hl, hood[0] - 0.06, hw - 0.06], [-hl + 0.06, hood[0], hw - 0.02], [-hl + 0.5, hood[1], hw],
		[g[0], hood[2], hw], [g[3], trunk[0], hw], [hl - 0.4, trunk[1], hw],
		[hl - 0.05, trunk[2], hw - 0.02], [hl, trunk[2] - 0.06, hw - 0.06],
	]
	var rows: Array = []
	for st: Array in stations:
		var z: float = st[0]
		var top: float = st[1]
		var w: float = st[2]
		var r := PackedVector3Array()
		r.append(Vector3(w, bot, z))
		r.append(Vector3(w, top - 0.32, z))
		r.append(Vector3(w + 0.012, top - 0.2, z))
		r.append(Vector3(w, top - 0.06, z))
		r.append(Vector3(w - 0.07, top, z))
		r.append(Vector3(-w + 0.07, top, z))
		r.append(Vector3(-w, top - 0.06, z))
		r.append(Vector3(-w - 0.012, top - 0.2, z))
		r.append(Vector3(-w, top - 0.32, z))
		r.append(Vector3(-w, bot, z))
		rows.append(r)
	# Rows run front to back and each goes right to left over the top, so
	# the quads face outwards.
	rows.reverse()
	paint.sheet(Transform3D.IDENTITY, rows, Color.WHITE, 2.0, false)
	# Underside, and the end faces behind the grille and the tail panel.
	black.box(Props.at(0, bot - 0.02, 0), Vector3(hw * 2 - 0.1, 0.04, s.len - 0.1))
	var front_top: float = hood[0] - 0.06
	paint.quad(Transform3D.IDENTITY, [Vector3(hw - 0.06, bot, -hl), Vector3(-hw + 0.06, bot, -hl),
		Vector3(-hw + 0.06, front_top, -hl), Vector3(hw - 0.06, front_top, -hl)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE, false)
	var rear_top: float = trunk[2] - 0.06
	paint.quad(Transform3D.IDENTITY, [Vector3(-hw + 0.06, bot, hl), Vector3(hw - 0.06, bot, hl),
		Vector3(hw - 0.06, rear_top, hl), Vector3(-hw + 0.06, rear_top, hl)],
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE, false)
	# A chrome strip along the flank and round the wheel arches in black.
	for sx: float in [-1.0, 1.0]:
		chrome.box(Props.at(sx * (hw + 0.012), s.belt - 0.12, 0), Vector3(0.012, 0.018, s.len - 0.5))
		for wz: float in s.wheel_z:
			black.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(hw + 0.016 if sx > 0.0 else -hw - 0.006, 0.31, wz)), 0.37, 0.37, 0.008, 18)

	# Greenhouse: glass all round, then the roof and the pillars over it.
	var roof: float = s.roof
	var belt: float = s.belt
	var rw := hw - 0.12
	var gh := [
		[g[0], belt, hw - 0.04], [g[1], roof, rw], [g[2], roof, rw], [g[3], belt, hw - 0.04],
	]
	var grows: Array = []
	for st: Array in gh:
		var r := PackedVector3Array()
		r.append(Vector3(st[2], belt, st[0]))
		r.append(Vector3(rw if st[1] > belt else st[2] - 0.08, st[1], st[0]))
		r.append(Vector3(-(rw if st[1] > belt else st[2] - 0.08), st[1], st[0]))
		r.append(Vector3(-st[2], belt, st[0]))
		grows.append(r)
	grows.reverse()
	glass_kind.sheet(Transform3D.IDENTITY, grows, Color.WHITE, 2.0, false)
	paint.box(Props.at(0, roof - 0.005, (g[1] + g[2]) * 0.5), Vector3(rw * 2 + 0.03, 0.035, g[2] - g[1] + 0.04))
	for sx: float in [-1.0, 1.0]:
		# A, B and C pillars: thin painted posts along the glass.
		for k in 3:
			var z0: float = [g[0], (g[0] + g[3]) * 0.5 + 0.1, g[3]][k]
			var z1: float = [g[1], (g[1] + g[2]) * 0.5 + 0.1, g[2]][k]
			var a := Vector3(sx * (hw - 0.05), belt, z0)
			var b := Vector3(sx * (rw + 0.005), roof, z1)
			var d := b - a
			var xf := Transform3D(Basis.looking_at(d.normalized(), Vector3(sx, 0, 0)), (a + b) * 0.5)
			paint.box(xf * Transform3D(Basis.IDENTITY, Vector3(0, -0.035, 0)), Vector3(0.07 if k != 1 else 0.06, 0.07, d.length()))
		# Window frames: a chrome line under the glass.
		chrome.box(Props.at(sx * (hw - 0.035), belt - 0.01, (g[0] + g[3]) * 0.5), Vector3(0.02, 0.02, g[3] - g[0]))

	# Front: black grille, round headlamps, chrome bumper with two fangs.
	var front := -hl - 0.005
	black.box(Props.at(0, bot + 0.2, front), Vector3(hw * 2 - 0.2, front_top - bot - 0.26, 0.02))
	for i in 7:
		chrome.box(Props.at(0, bot + 0.24 + i * 0.045, front - 0.012), Vector3(hw * 0.75, 0.008, 0.01))
	var lamp_mat := Mats.unique("white", Color(0.85, 0.85, 0.8), Color.BLACK)
	var lamps := kit.custom(lamp_mat)
	var beams: Array[SpotLight3D] = []
	var lamp_x: Array = [hw - 0.17, hw - 0.4] if s.quad else [hw - 0.2]
	for sx: float in [-1.0, 1.0]:
		for lx: float in lamp_x:
			var c := Vector3(sx * lx, bot + 0.36, front - 0.01)
			chrome.cylinder(Props.rot(Vector3.RIGHT, -PI * 0.5, c), 0.095, 0.09, 0.03, 16)
			lamps.cylinder(Props.rot(Vector3.RIGHT, -PI * 0.5, c + Vector3(0, 0, -0.03)), 0.08, 0.075, 0.012, 16)
		var l := SpotLight3D.new()
		l.position = Vector3(sx * (hw - 0.3), bot + 0.36, front - 0.15)
		l.rotation.x = deg_to_rad(-5.0)
		l.spot_range = 32.0
		l.spot_angle = 30.0
		l.spot_attenuation = 0.9
		l.light_energy = 0.0
		l.light_color = Color(1.0, 0.93, 0.78)
		l.shadow_enabled = sx < 0.0
		car.add_child(l)
		beams.append(l)
		# Amber indicators under the lamps.
		kit.b("white", Color(1.0, 0.55, 0.15), Color(0.25, 0.12, 0.02)).box(Props.at(sx * (hw - 0.22), bot + 0.12, front - 0.01),
			Vector3(0.14, 0.05, 0.02))
	chrome.box(Props.at(0, bot - 0.02, front - 0.06), Vector3(hw * 2 + 0.04, 0.11, 0.08))
	for sx: float in [-0.4, 0.4]:
		chrome.box(Props.at(sx, bot - 0.06, front - 0.1), Vector3(0.05, 0.2, 0.05))
	# Rear: red lamps, bumper, plate.
	var rear := hl + 0.005
	var tail_mat := Mats.unique("white", Color(0.7, 0.08, 0.06), Color(0.35, 0.02, 0.01))
	var tail := kit.custom(tail_mat)
	for sx: float in [-1.0, 1.0]:
		tail.box(Props.at(sx * (hw - 0.2), bot + 0.32, rear), Vector3(0.26, 0.1, 0.02))
	chrome.box(Props.at(0, bot - 0.02, rear + 0.05), Vector3(hw * 2 + 0.04, 0.11, 0.08))
	if s.plate:
		for zz: float in [front - 0.105, rear + 0.095]:
			var pl := kit.b("ext_plate")
			pl.box(Transform3D(Basis.IDENTITY if zz > 0 else Basis(Vector3.UP, PI), Vector3(0, bot + 0.02, zz)),
				Vector3(0.44, 0.11, 0.004), Color.WHITE, Rect2(0, 0, 1, 1), Vector2.ONE, MeshFactory.PZ)

	# Wheels: tyre, a chrome hubcap; the arch shadow is the black disc above.
	for sx: float in [-1.0, 1.0]:
		for wz: float in s.wheel_z:
			# A cylinder turned by +90° about Z runs from its base towards -X.
			var base := hw + 0.01 if sx > 0.0 else -hw + 0.15
			black.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(base, 0.31, wz)), 0.31, 0.31, 0.16, 20,
				Color.WHITE, Rect2(0, 0, 1, 1), Rect2(), true, true)
			chrome.cylinder(Props.rot(Vector3.BACK, -sx * PI * 0.5, Vector3(sx * (hw + 0.008), 0.31, wz)), 0.17, 0.12, 0.03, 16)

	# Inside: dashboard, seats, a steering wheel, seen through the glass.
	var inside := kit.b("leather", Color(0.18, 0.15, 0.13))
	inside.box(Props.at(0, belt - 0.2, g[0] + 0.12), Vector3(hw * 2 - 0.16, 0.26, 0.3))
	for sx: float in [-0.36, 0.36]:
		inside.box(Props.at(sx, 0.35, 0.2), Vector3(0.5, 0.15, 0.5))
		inside.box(Props.rot(Vector3.RIGHT, -0.2, Vector3(sx, 0.48, 0.5)), Vector3(0.5, 0.6, 0.12))
	inside.box(Props.at(0, 0.35, 1.0), Vector3(hw * 2 - 0.2, 0.15, 0.5))
	var wheel_xf := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-62)), Vector3(-0.36, belt - 0.06, g[0] + 0.42))
	black.lathe(wheel_xf, [Vector2(0.17, -0.012), Vector2(0.19, 0.0), Vector2(0.17, 0.012), Vector2(0.15, 0.0), Vector2(0.17, -0.012)], 24)
	black.cylinder(wheel_xf * Transform3D(Basis.IDENTITY, Vector3(0, -0.1, 0)), 0.025, 0.04, 0.1, 8)
	# Dials glowing green on the dash.
	kit.b("dial", Color(0.6, 0.9, 0.6), Color(0.2, 0.45, 0.25)).box(
		Props.rot(Vector3.RIGHT, -0.5, Vector3(-0.36, belt - 0.0, g[0] + 0.22)), Vector3(0.3, 0.1, 0.01))
	kit.build(car)

	# Driver's door seam and handle (no opening door: he gets out off screen).
	var door := Node3D.new()
	door.position = Vector3(-hw - 0.004, 0, g[0] + 0.05)
	car.add_child(door)
	var dk := MeshBuilder.Kit.new()
	dk.ao = false
	dk.b("rubber", Color(0.1, 0.1, 0.1)).box(Props.at(0, bot + 0.05, 0), Vector3(0.006, belt - bot, 0.006))
	dk.b("rubber", Color(0.1, 0.1, 0.1)).box(Props.at(0, bot + 0.05, 1.0), Vector3(0.006, belt - bot, 0.006))
	dk.b("chrome").box(Props.at(-0.01, belt - 0.2, 0.85), Vector3(0.02, 0.025, 0.14))
	dk.build(door, false)

	# Wiper on the driver's side, pivoting at the bottom of the windscreen.
	var wiper := Node3D.new()
	var wy: float = hood[2] + 0.03
	wiper.position = Vector3(-0.08, wy, g[0] - 0.05)
	var slope := Vector3(0, roof - belt, g[1] - g[0]).normalized()
	wiper.basis = Basis.looking_at(slope, Vector3.UP).rotated(slope, 0.0)
	car.add_child(wiper)
	var wpiv := Node3D.new()
	wiper.add_child(wpiv)
	var wk := MeshBuilder.Kit.new()
	wk.ao = false
	wk.b("rubber", Color(0.05, 0.05, 0.05)).box(Transform3D(Basis(Vector3.FORWARD, 0.0), Vector3(-0.25, 0.0, 0.0)),
		Vector3(0.5, 0.012, 0.012))
	wk.build(wpiv, false)
	wpiv.rotation.z = 0.0

	car.set_meta("beams", beams)
	car.set_meta("lamps", [lamp_mat])
	car.set_meta("tail", tail_mat)
	car.set_meta("wiper", wpiv)
	car.set_meta("door", door)
	car.set_meta("seat", Vector3(-0.36, 1.13, 0.32))
	return car


## Lights on or off; `energy` for the beams.
static func set_lights(car: Node3D, on: bool, energy := HEADLIGHT) -> void:
	for l: SpotLight3D in car.get_meta("beams"):
		l.light_energy = energy if on else 0.0
	for m: ShaderMaterial in car.get_meta("lamps"):
		m.set_shader_parameter("emission", Color(3.0, 2.8, 2.3) if on else Color.BLACK)
	(car.get_meta("tail") as ShaderMaterial).set_shader_parameter("emission",
		Color(1.6, 0.1, 0.05) if on else Color(0.2, 0.01, 0.0))
