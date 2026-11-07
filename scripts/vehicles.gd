class_name Vehicles
extends RefCounted

## Cars of 1988 for the street scenes: Gordeev's pale blue ВАЗ-2106
## «Жигули» and the director's black ГАЗ-24 «Волга». The bodies are modelled
## in Blender by tools/build_cars.py (models/cars/*.glb: the body with its
## arches, cabin and window openings cut out, glass, chrome, lamps, bumpers,
## wheels); here they get the game's materials, the headlight beams, the
## driver's wiper and, for the «Жигули», the whole cabin (CarCabin).
## Nose towards -Z, wheels on the ground at y = 0.
## The returned node carries:
##   meta "beams"  Array[SpotLight3D]  headlights (off: energy 0)
##   meta "lamps"  Array[ShaderMaterial] headlamp glass, for lights on/off
##   meta "tail"   ShaderMaterial red rear lamps
##   meta "wiper"  Node3D the driver's wiper, rotates about its local Z
##   meta "door"   Node3D the driver's door, hinged at the front
##   meta "seat"   Vector3 the driver's eye point (for the shot from inside)
##   meta "steer"  Node3D the wheel with the hands (the «Жигули», see CarCabin)

## The numbers the cabin, the beams and the wiper are fitted to; they match
## CARS in tools/build_cars.py. glass: z of the windscreen foot, windscreen
## top, rear window top, rear window foot.
const ZHIGULI := {
	"model": "res://models/cars/zhiguli.glb", "hw": 0.805, "paint": Color(0.55, 0.66, 0.72),
	"hood": [0.80, 0.86, 0.885], "glass": [-0.78, -0.22, 0.62, 1.15], "roof": 1.415, "belt": 0.92,
	"lamps": [0.605, 0.405], "lamp_y": 0.60, "front": -2.088, "cabin": true,
}
const VOLGA := {
	"model": "res://models/cars/volga.glb", "hw": 0.9, "paint": Color(0.05, 0.05, 0.055),
	"hood": [0.78, 0.84, 0.86], "glass": [-0.75, -0.12, 0.85, 1.4], "roof": 1.455, "belt": 0.9,
	"lamps": [0.73], "lamp_y": 0.60, "front": -2.373, "cabin": false,
}

const HEADLIGHT := 9.0


static func zhiguli() -> Node3D:
	return build(ZHIGULI)


static func volga() -> Node3D:
	return build(VOLGA)


static func build(s: Dictionary) -> Node3D:
	var car := Node3D.new()
	var model: Node3D = (load(s.model) as PackedScene).instantiate()
	car.add_child(model)
	var lamp_mat := Mats.unique("white", Color(0.85, 0.85, 0.8), Color.BLACK)
	var tail_mat := Mats.unique("white", Color(0.7, 0.08, 0.06), Color(0.2, 0.01, 0.0))
	var mats := {
		"body": Mats.get_mat("paint", s.paint),
		"chrome": Mats.get_mat("chrome"),
		"black": Mats.get_mat("rubber", Color(0.1, 0.1, 0.1)),
		"glass": Mats.get_mat("glass", Color(0.12, 0.15, 0.18, 0.5), Color.BLACK, Mats.GLASS),
		"lamp": lamp_mat,
		"tail": tail_mat,
		"amber": Mats.get_mat("white", Color(1.0, 0.55, 0.15), Color(0.15, 0.07, 0.01)),
		"reverse": Mats.get_mat("white", Color(0.9, 0.9, 0.88)),
		"plate": Mats.get_mat("ext_plate"),
		"tyre": Mats.get_mat("rubber", Color(0.07, 0.07, 0.07)),
		"rim": Mats.get_mat("metal", Color(0.45, 0.45, 0.45)),
		"inside": Mats.get_mat("leather", Color(0.12, 0.11, 0.1)),
		"seat": Mats.get_mat("car_seat"),
	}
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var kind := String(mi.name).get_slice("_", 0)
		if mats.has(kind):
			mi.material_override = mats[kind]
		if kind in ["glass", "lamp", "tail", "amber", "reverse", "plate"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var hw: float = s.hw
	var g: Array = s.glass
	var belt: float = s.belt
	var roof: float = s.roof
	var beams: Array[SpotLight3D] = []
	for sx: float in [-1.0, 1.0]:
		var l := SpotLight3D.new()
		l.position = Vector3(sx * (s.lamps as Array)[0], s.lamp_y, s.front - 0.12)
		l.rotation.x = deg_to_rad(-5.0)
		l.spot_range = 32.0
		l.spot_angle = 30.0
		l.spot_attenuation = 0.9
		l.light_energy = 0.0
		l.light_color = Color(1.0, 0.93, 0.78)
		l.shadow_enabled = false  # the lamp sits inside the body: its own wing would shade it
		l.set_meta("role", "beam")
		car.add_child(l)
		beams.append(l)
	if s.get("cabin", false):
		CarCabin.build(car, s)

	# The driver's door (no opening door: he gets out off screen).
	var door := Node3D.new()
	door.position = Vector3(-hw - 0.004, 0, g[0] + 0.05)
	car.add_child(door)

	# Wiper on the driver's side, pivoting at the foot of the windscreen.
	var hood: Array = s.hood
	var wiper := Node3D.new()
	wiper.position = Vector3(-0.08, hood[2] + 0.03, g[0] + 0.02)
	var slope := Vector3(0, roof - belt, g[1] - g[0]).normalized()
	wiper.basis = Basis.looking_at(slope, Vector3.UP)
	car.add_child(wiper)
	var wpiv := Node3D.new()
	wiper.add_child(wpiv)
	var wk := MeshBuilder.Kit.new()
	wk.ao = false
	wk.b("rubber", Color(0.05, 0.05, 0.05)).box(Transform3D(Basis.IDENTITY, Vector3(-0.25, 0.0, 0.0)),
		Vector3(0.5, 0.012, 0.012))
	wk.build(wpiv, false)

	car.set_meta("beams", beams)
	car.set_meta("lamps", [lamp_mat])
	car.set_meta("tail", tail_mat)
	car.set_meta("wiper", wpiv)
	car.set_meta("door", door)
	if not car.has_meta("seat"):
		car.set_meta("seat", Vector3(-0.4, 1.13, 0.15))
	return car


## Lights on or off; `energy` for the beams.
static func set_lights(car: Node3D, on: bool, energy := HEADLIGHT) -> void:
	for l: SpotLight3D in car.get_meta("beams"):
		l.light_energy = energy if on else 0.0
	for m: ShaderMaterial in car.get_meta("lamps"):
		m.set_shader_parameter("emission", Color(3.0, 2.8, 2.3) if on else Color.BLACK)
	(car.get_meta("tail") as ShaderMaterial).set_shader_parameter("emission",
		Color(1.6, 0.1, 0.05) if on else Color(0.2, 0.01, 0.0))
	CarCabin.set_dash(car, on)


## The участковый's «бобик»: a militia УАЗ-469 of 1988, built from boxes
## here rather than in Blender (it is only ever seen at night, parked).
## Yellow body with the blue band and «МИЛИЦИЯ», a hard white-grey top, the
## spare wheel on the tailgate, the blue lamp on the roof. Nose towards -Z,
## wheels on the ground at y = 0, driver on the left (-X). Same metas as the
## other cars: "beams", "lamps", "tail"; and "seat", the driver's hip point.
static func bobik() -> Node3D:
	var car := Node3D.new()
	var kit := MeshBuilder.Kit.new()
	var yellow := kit.b("paint", Color(0.78, 0.62, 0.2))
	var blue := kit.b("paint", Color(0.12, 0.2, 0.42))
	var top := kit.b("paint", Color(0.72, 0.72, 0.68))
	var black := kit.b("rubber", Color(0.06, 0.06, 0.06))
	var metal := kit.b("metal", Color(0.3, 0.31, 0.3))
	var glass := kit.b("glass", Color(0.1, 0.12, 0.14, 0.45), Color.BLACK, Mats.GLASS)
	var hw := 0.88
	# Body tub below the belt: the bonnet in front, the cab and the boot behind.
	yellow.box(Props.at(0, 0.48, 0.15), Vector3(hw * 2, 0.62, 3.1))                 # cab and boot
	yellow.box(Props.at(0, 0.5, -1.55), Vector3(hw * 2 - 0.1, 0.55, 1.2))          # bonnet
	yellow.box(Props.rot(Vector3.RIGHT, -0.05, Vector3(0, 1.05, -1.55)), Vector3(hw * 2 - 0.12, 0.04, 1.18))
	# Wings over the wheels.
	for sx: float in [-1.0, 1.0]:
		for wz: float in [-1.2, 1.15]:
			yellow.box(Props.at(sx * (hw - 0.04), 0.78, wz), Vector3(0.2, 0.16, 0.95))
	# The blue band along both sides and the word on it.
	for sx: float in [-1.0, 1.0]:
		blue.box(Props.at(sx * (hw + 0.005), 0.72, 0.15), Vector3(0.01, 0.13, 3.0))
	var word := Label3D.new()
	word.text = "МИЛИЦИЯ"
	word.font_size = 64
	word.pixel_size = 0.0028
	word.modulate = Color(0.92, 0.92, 0.88)
	word.shaded = true
	word.position = Vector3(-hw - 0.012, 0.785, 0.35)
	word.rotation.y = -PI * 0.5
	car.add_child(word)
	var word2 := word.duplicate() as Label3D
	word2.position = Vector3(hw + 0.012, 0.785, 0.35)
	word2.rotation.y = PI * 0.5
	car.add_child(word2)
	# Upper cab: pillars, the hard top, glass all round.
	var belt := 1.1
	var roof := 1.95
	var ws := -0.92   # windscreen
	for sx: float in [-1.0, 1.0]:
		top.box(Props.at(sx * (hw - 0.04), belt, ws), Vector3(0.06, roof - belt, 0.06))
		top.box(Props.at(sx * (hw - 0.04), belt, 0.05), Vector3(0.07, roof - belt, 0.08))
		top.box(Props.at(sx * (hw - 0.04), belt, 1.66), Vector3(0.08, roof - belt, 0.08))
	top.box(Props.at(0, roof, 0.38), Vector3(hw * 2, 0.06, 2.65))
	top.box(Props.at(0, belt, 1.67), Vector3(hw * 2, 0.12, 0.06))
	glass.box(Props.at(0, belt, ws), Vector3(hw * 2 - 0.1, roof - belt, 0.02))
	for sx: float in [-1.0, 1.0]:
		glass.box(Props.at(sx * (hw - 0.03), belt, -0.44), Vector3(0.02, roof - belt - 0.05, 0.88))
		glass.box(Props.at(sx * (hw - 0.03), belt, 0.86), Vector3(0.02, roof - belt - 0.1, 1.55))
	glass.box(Props.at(0, belt + 0.12, 1.68), Vector3(hw * 2 - 0.2, roof - belt - 0.2, 0.02))
	metal.box(Props.at(0, belt, ws + 0.02), Vector3(hw * 2, 0.04, 0.04))   # wiper bar
	# Seats and the wheel, just enough to read through the glass.
	var seat := kit.b("leather", Color(0.1, 0.09, 0.08))
	for sx: float in [-0.42, 0.42]:
		seat.box(Props.at(sx, 0.75, 0.25), Vector3(0.5, 0.12, 0.5))
		seat.box(Props.rot(Vector3.RIGHT, -0.15, Vector3(sx, 0.85, 0.52)), Vector3(0.5, 0.6, 0.1))
	black.cylinder(Props.rot(Vector3.RIGHT, -1.1, Vector3(-0.42, 1.08, -0.5)), 0.19, 0.19, 0.03, 16)
	# Front: the grille between round lamps, bumpers, the number plates.
	metal.box(Props.at(0, 0.45, -2.16), Vector3(hw * 2 - 0.2, 0.55, 0.04))
	for k in 7:
		black.box(Props.at(-0.48 + k * 0.16, 0.5, -2.18), Vector3(0.05, 0.42, 0.02))
	black.box(Props.at(0, 0.3, -2.25), Vector3(hw * 2 + 0.1, 0.12, 0.1))
	black.box(Props.at(0, 0.3, 1.72), Vector3(hw * 2 + 0.1, 0.12, 0.1))
	kit.b("ext_plate").box(Props.at(0, 0.38, -2.31), Vector3(0.52, 0.11, 0.01), Color.WHITE, Rect2(0, 0, 1, 1), Vector2.ONE,
		MeshFactory.NZ)
	var lamp_mat := Mats.unique("white", Color(0.85, 0.85, 0.8), Color.BLACK)
	var tail_mat := Mats.unique("white", Color(0.7, 0.08, 0.06), Color(0.2, 0.01, 0.0))
	var lamps := kit.custom(lamp_mat)
	var tails := kit.custom(tail_mat)
	for sx: float in [-0.62, 0.62]:
		lamps.cylinder(Props.rot(Vector3.RIGHT, -PI * 0.5, Vector3(sx, 0.72, -2.14)), 0.09, 0.09, 0.04, 14)
		tails.box(Props.at(sx * 1.25, 0.62, 1.71), Vector3(0.1, 0.16, 0.03))
	# Spare wheel on the tailgate, four wheels with their grey rims.
	var tyre := kit.b("rubber", Color(0.07, 0.07, 0.07))
	var rim := kit.b("metal", Color(0.45, 0.47, 0.42))
	tyre.cylinder(Props.rot(Vector3.RIGHT, PI * 0.5, Vector3(0.1, 0.95, 1.74)), 0.36, 0.36, 0.22, 16)
	for sx: float in [-1.0, 1.0]:
		for wz: float in [-1.2, 1.15]:
			tyre.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(sx * (hw - 0.0) + sx * 0.12, 0.38, wz)), 0.38, 0.38, 0.26, 18)
			rim.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(sx * (hw + 0.135), 0.38, wz)), 0.2, 0.2, 0.02, 14)
	# The blue lamp on the roof, dark tonight.
	kit.b("glass", Color(0.15, 0.3, 0.8, 0.8), Color.BLACK, Mats.GLASS).cylinder(Props.at(0, roof + 0.06, -0.55), 0.09, 0.08,
		0.16, 14)
	kit.build(car)
	var beams: Array[SpotLight3D] = []
	for sx: float in [-0.62, 0.62]:
		var l := SpotLight3D.new()
		l.position = Vector3(sx, 0.72, -2.2)
		l.rotation.x = deg_to_rad(-4.0)
		l.spot_range = 30.0
		l.spot_angle = 30.0
		l.light_energy = 0.0
		l.light_color = Color(1.0, 0.92, 0.75)
		l.shadow_enabled = false  # the lamp sits inside the body: its own wing would shade it
		l.set_meta("role", "beam")
		car.add_child(l)
		beams.append(l)
	car.set_meta("beams", beams)
	car.set_meta("lamps", [lamp_mat])
	car.set_meta("tail", tail_mat)
	car.set_meta("seat", Vector3(-0.42, 0.81, 0.25))
	return car
