class_name Player
extends CharacterBody3D

## Gordeev. Tank controls as in Silent Hill 1: forward/back move along the
## facing, left/right turn on the spot, whatever the camera does.
## The dynamo flashlight shines only while the lever is squeezed (held key)
## and its whirr is heard across the aisle.

signal noise(pos: Vector3, radius: float)

const WALK_SPEED := 1.7
const RUN_SPEED := 3.4
const BACK_SPEED := 1.0
const TURN_SPEED := 2.6
const FLASHLIGHT_NOISE := 9.0
const RUN_NOISE := 7.0

var controllable := false
var busy := false
var dead := false
var flashlight_on := false
var force_flashlight := false  # dev screenshots
var parts: Dictionary
var flashlight: SpotLight3D

var _whirr: AudioStreamPlayer3D
var _steps: AudioStreamPlayer3D
var _anim := 0.0
var _stride := 0.0
var _noise_t := 0.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	add_child(cs)
	parts = Characters.build_guard()
	add_child(parts.root)

	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0.12, 1.25, -0.25)
	flashlight.rotation.x = deg_to_rad(-18.0)
	flashlight.spot_range = 14.0
	flashlight.spot_angle = 40.0
	flashlight.spot_attenuation = 0.8
	flashlight.light_color = Color(1.0, 0.92, 0.75)
	flashlight.light_specular = 0.0
	flashlight.shadow_enabled = true
	flashlight.visible = false
	add_child(flashlight)

	_whirr = AudioStreamPlayer3D.new()
	_whirr.stream = Sfx.get_stream("whirr")
	_whirr.volume_db = -8.0
	_whirr.max_distance = 15.0
	add_child(_whirr)
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = Sfx.get_stream("step")
	_steps.max_distance = 14.0
	add_child(_steps)


func _physics_process(delta: float) -> void:
	_t += delta
	var fwd := 0.0
	var turn := 0.0
	var running := false
	var want_light := force_flashlight
	if controllable and not dead:
		want_light = want_light or Input.is_action_pressed("flashlight")
		if not busy:
			fwd = Input.get_axis("move_back", "move_forward")
			turn = Input.get_axis("turn_right", "turn_left")
			running = Input.is_action_pressed("run") and fwd > 0.1
	_set_flashlight(want_light and not dead)

	rotation.y += turn * TURN_SPEED * delta
	var speed := BACK_SPEED
	if fwd > 0.0:
		speed = RUN_SPEED if running else WALK_SPEED
	velocity = -global_transform.basis.z * fwd * speed
	move_and_slide()
	global_position.y = 0.0
	var moved := velocity.length()

	if not dead:
		_anim += delta * moved * 3.4
		Characters.walk(parts, _anim, clampf(moved / WALK_SPEED, 0.0, 1.4) + absf(turn) * 0.3)
	_stride += moved * delta
	if _stride > (0.95 if running else 0.7):
		_stride = 0.0
		_steps.pitch_scale = randf_range(0.92, 1.08)
		_steps.volume_db = -4.0 if running else -11.0
		_steps.play()

	_noise_t -= delta
	if _noise_t <= 0.0:
		if flashlight_on:
			noise.emit(global_position, FLASHLIGHT_NOISE)
			_noise_t = 0.5
		elif running and moved > 0.5:
			noise.emit(global_position, RUN_NOISE)
			_noise_t = 0.4
	if flashlight_on:
		# The dynamo pulses with each squeeze of the lever.
		flashlight.light_energy = 9.0 + sin(_t * 37.0) * 0.6 + sin(_t * 6.0) * 0.9


func _set_flashlight(on: bool) -> void:
	if on == flashlight_on:
		return
	flashlight_on = on
	flashlight.visible = on
	if on:
		_whirr.play()
	else:
		_whirr.stop()


func face(dir: Vector3) -> void:
	rotation.y = atan2(-dir.x, -dir.z)


## Falls on his back. The killer keeps going.
func die() -> void:
	dead = true
	controllable = false
	_set_flashlight(false)
	var root: Node3D = parts.root
	var tw := create_tween().set_parallel()
	tw.tween_property(root, "rotation:x", PI * 0.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(root, "position:y", 0.14, 0.5)
	tw.tween_property(parts.arm_l, "rotation:z", -1.2, 0.6)
	tw.tween_property(parts.arm_r, "rotation:z", 1.0, 0.6)
	tw.tween_property(parts.head, "rotation:y", 0.7, 0.7)
