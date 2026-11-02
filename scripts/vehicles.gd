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
		l.shadow_enabled = sx < 0.0
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
