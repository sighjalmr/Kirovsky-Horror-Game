class_name Traffic
extends Node3D

## Cars going by on the road past the square in the daytime (day four):
## «Жигули» in the colours of 1988, now and then a «Волга», a militia
## «бобик» once in a while. Right-hand traffic, both ways, at town speed,
## each with its engine heard as it passes. The road is beyond the kerb
## Gordeev cannot cross (Outdoors), so nobody steps in front of them.

## The road in the store's world (Exterior.ROAD_Z moved like the square).
const ROAD_Z := Exterior.ROAD_Z + Outdoors.OFFSET.z
const Y := Outdoors.GROUND
## Lanes: heading +x keeps to the square's side of the road.
const LANE := 2.2
const FAR := 170.0

const PAINTS := [Color(0.85, 0.84, 0.8), Color(0.75, 0.68, 0.52), Color(0.6, 0.12, 0.1), Color(0.25, 0.36, 0.28),
	Color(0.4, 0.1, 0.14), Color(0.55, 0.66, 0.72), Color(0.82, 0.62, 0.2), Color(0.3, 0.32, 0.36)]

var _cars: Array = []
var _t := 2.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# A couple already on the road.
	_spawn(_rng.randf_range(-60.0, -10.0))
	_spawn(_rng.randf_range(10.0, 60.0))


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = _rng.randf_range(4.0, 10.0)
		if _cars.size() < 6:
			_spawn()
	for c: Array in _cars.duplicate():
		var car: Node3D = c[0]
		car.position.x += c[1] * delta
		if absf(car.position.x) > FAR + 5.0:
			_cars.erase(c)
			car.queue_free()


func _spawn(at_x := NAN) -> void:
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var car: Node3D
	var roll := _rng.randf()
	if roll < 0.1:
		car = Vehicles.bobik()
	elif roll < 0.3:
		var v := Vehicles.VOLGA.duplicate()
		v.paint = [Color(0.05, 0.05, 0.055), Color(0.85, 0.84, 0.8), Color(0.35, 0.42, 0.4)][_rng.randi() % 3]
		car = Vehicles.build(v)
	else:
		var z := Vehicles.ZHIGULI.duplicate()
		z.paint = PAINTS[_rng.randi() % PAINTS.size()]
		z.cabin = false
		car = Vehicles.build(z)
	add_child(car)
	var x := -dir * FAR if is_nan(at_x) else at_x
	car.position = Vector3(x, Y, ROAD_Z + LANE * dir)
	car.rotation.y = -PI * 0.5 * dir  # nose (-Z) along the way it goes
	var engine := AudioStreamPlayer3D.new()
	engine.stream = Sfx.get_stream("engine_drive")
	engine.bus = Sfx.BUS
	engine.unit_size = 5.0
	engine.max_distance = 70.0
	engine.volume_db = -8.0
	engine.pitch_scale = _rng.randf_range(0.9, 1.1)
	engine.position.y = 0.5
	car.add_child(engine)
	engine.play()
	_cars.append([car, dir * _rng.randf_range(9.0, 14.0)])
