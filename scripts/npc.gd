class_name Npc
extends Node3D

## Somebody who walks through the store on a script: the director, the
## cashier, the loader. No collision and no senses; they follow the points
## they are given, turn to face whom they speak to and carry what they carry.

signal arrived

const STEP := 0.72

var parts: Dictionary
var speed := 1.25
var walking := false

var _path := PackedVector3Array()
var _i := 0
var _anim := 0.0
var _stride := 0.0
var _steps: AudioStreamPlayer3D
var _carry := false


func setup(look: Dictionary) -> Npc:
	parts = Characters.build_person(look)
	add_child(parts.root)
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = Sfx.get_stream("step")
	_steps.bus = Sfx.BUS
	_steps.max_distance = 16.0
	_steps.unit_size = 3.0
	_steps.volume_db = -8.0
	add_child(_steps)
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
	(parts.box as Node3D).visible = on
	for a: Node3D in [parts.arm_l, parts.arm_r]:
		a.rotation.x = -1.15 if on else 0.0


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
	_stride += speed * delta
	if _stride > STEP:
		_stride = 0.0
		_steps.pitch_scale = randf_range(0.9, 1.05)
		_steps.play()


func _animate(v: float, delta: float) -> void:
	_anim += delta * v * 3.4
	var amount := clampf(v / 1.2, 0.0, 1.2)
	var s := sin(_anim) * 0.5 * amount
	(parts.leg_l as Node3D).rotation.x = s
	(parts.leg_r as Node3D).rotation.x = -s
	if not _carry:
		(parts.arm_l as Node3D).rotation.x = -s * 0.6
		(parts.arm_r as Node3D).rotation.x = s * 0.6
