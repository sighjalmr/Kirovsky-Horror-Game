class_name Npc
extends Node3D

## Somebody who walks through the store on a script: the director, the
## cashier, the loader. No collision and no senses; they follow the points
## they are given, turn to face whom they speak to and carry what they carry.
## The body is a photographed, motion-captured Person (see Characters.CAST).

signal arrived

var body: Person
## What they do standing still: "idle", "talk", "sit".
var pose := "idle":
	set(v):
		pose = v
		# The captured sitting is on a chair; the cashier's stool is higher.
		body.position.y = 0.12 if v == "sit" else 0.0
		if not walking:
			body.play(v)
var speed := 1.25
var walking := false

var _path := PackedVector3Array()
var _i := 0
var _steps: AudioStreamPlayer3D
var _carry := false
var _box: Node3D


func setup(role: String) -> Npc:
	body = Characters.build(role)
	add_child(body)
	_box = Characters.carton()
	_box.visible = false
	add_child(_box)
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = Sfx.get_stream("step")
	_steps.bus = Sfx.BUS
	_steps.max_distance = 16.0
	_steps.unit_size = 3.0
	_steps.volume_db = -8.0
	add_child(_steps)
	body.footfall.connect(_on_footfall)
	return self


## Walks through `points` (floor positions) and emits `arrived` at the last.
func walk(points: PackedVector3Array) -> void:
	_path = points
	_i = 0
	walking = not _path.is_empty()
	if not walking:
		arrived.emit.call_deferred()


func look_at_point(p: Vector3) -> void:
	var d := p - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		create_tween().tween_property(self, "rotation:y",
			rotation.y + angle_difference(rotation.y, atan2(-d.x, -d.z)), 0.4)


## Both arms round a carton in front of the chest.
func carry(on: bool) -> void:
	_carry = on
	_box.visible = on
	if body.bag:
		body.bag.visible = not on
	for side: String in ["L", "R"]:
		var x := -1.0 if side == "L" else 1.0
		body.aim("Bip01 %s UpperArm" % side, Vector3(x * 0.25, -0.75, -0.6), 1.0 if on else 0.0)
		body.aim("Bip01 %s Forearm" % side, Vector3(-x * 0.35, 0.1, -1.0), 1.0 if on else 0.0)


func _process(delta: float) -> void:
	if not walking:
		_animate(0.0, delta)
		return
	var to := _path[_i] - global_position
	to.y = 0.0
	if to.length() < 0.15:
		_i += 1
		if _i >= _path.size():
			walking = false
			arrived.emit()
		return
	var dir := to.normalized()
	global_position += dir * minf(speed * delta, to.length())
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 8.0, 0.0, 1.0))
	_animate(speed, delta)


func _animate(v: float, _delta: float) -> void:
	# The captured walk plays at the rate that matches the pace, so the feet
	# stay planted; each footfall of the clip sounds a step.
	if v > 0.05:
		body.play("walk", v)
	else:
		body.play(pose)


func _on_footfall() -> void:
	if walking:
		_steps.pitch_scale = randf_range(0.96, 1.04)
		_steps.play()
