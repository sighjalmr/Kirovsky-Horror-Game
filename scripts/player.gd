class_name Player
extends CharacterBody3D

## Gordeev, seen through his own eyes. Mouse or right stick looks around,
## WASD walks and strides sideways. His right hand holds the dynamo
## flashlight in view and the beam comes from its lens; it shines only while
## the lever is squeezed (held key) and its whirr is heard across the aisle.

signal noise(pos: Vector3, radius: float)

const WALK_SPEED := 1.7
const RUN_SPEED := 3.4
const BACK_SPEED := 1.1
const EYE_HEIGHT := 1.6
const CROUCH_EYE := 1.0
const SIT_EYE := 1.2
const CROUCH_SPEED := 0.8
const MOUSE_SENS := 0.0025
const STICK_SENS := 2.4
const PITCH_LIMIT := deg_to_rad(80.0)
const FLASHLIGHT_NOISE := 9.0
const RUN_NOISE := 7.0
const HAND_POS := Vector3(0.17, -0.14, -0.37)
const HAND_ROT := Vector3(deg_to_rad(-8.0), deg_to_rad(38.0), deg_to_rad(18.0))
const HAND_REACH := 0.55

var controllable := false
var busy := false
var dead := false
var flashlight_on := false
var force_flashlight := false  # dev screenshots
## C toggles: low behind a chest he is hard to see, slow and quiet.
var crouching := false
## On the chair at the post, waiting out the night.
var sitting := false
var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var hand: TorchHand

var _spill: OmniLight3D
var _sway := Vector2.ZERO
var _pull := 0.0
## 0 lowered out of sight, 1 held up in front: the hand only comes up with the torch.
var _raise := 0.0

var _whirr: AudioStreamPlayer3D
var _steps: AudioStreamPlayer3D
var _bob := 0.0
var _stride := 0.0
var _noise_t := 0.0
var _t := 0.0
var _eye := EYE_HEIGHT


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 8  # 8: the storage doorway, closed to him only
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	add_child(cs)

	head = Node3D.new()
	head.position.y = EYE_HEIGHT
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.08
	camera.far = 40.0
	head.add_child(camera)

	_build_hand()
	flashlight = SpotLight3D.new()
	flashlight.position = TorchHand.LENS
	# Aim the beam from the lens towards the middle of the view six metres ahead.
	var aim := Vector3(0, -0.4, -6.0) - hand.transform * flashlight.position
	flashlight.basis = hand.basis.inverse() * Basis.looking_at(aim)
	flashlight.spot_range = 14.0
	flashlight.spot_angle = 32.0
	flashlight.spot_attenuation = 0.8
	flashlight.light_color = Color(1.0, 0.92, 0.75)
	flashlight.light_specular = 0.9
	flashlight.shadow_enabled = true
	flashlight.visible = false
	hand.add_child(flashlight)

	_whirr = AudioStreamPlayer3D.new()
	_whirr.stream = Sfx.get_stream("whirr")
	_whirr.bus = Sfx.BUS
	_whirr.volume_db = -24.0
	_whirr.max_distance = 6.0
	_whirr.unit_size = 1.0
	add_child(_whirr)
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = Sfx.get_stream("step")
	_steps.bus = Sfx.BUS
	_steps.max_distance = 14.0
	add_child(_steps)


## Mouse look; main forwards the motion because the world lives in a SubViewport.
func look(rel: Vector2) -> void:
	if not controllable or dead:
		return
	rotation.y -= rel.x * MOUSE_SENS
	_sway += rel * 0.0004
	head.rotation.x = clampf(head.rotation.x - rel.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)


func _physics_process(delta: float) -> void:
	_t += delta
	var move := Vector2.ZERO
	var running := false
	var want_light := force_flashlight
	if controllable and not dead:
		want_light = want_light or Input.is_action_pressed("flashlight")
		var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		rotation.y -= stick.x * STICK_SENS * delta
		head.rotation.x = clampf(head.rotation.x - stick.y * STICK_SENS * delta, -PITCH_LIMIT, PITCH_LIMIT)
		if not busy:
			move = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
			if Input.is_action_just_pressed("crouch"):
				crouching = not crouching
			running = Input.is_action_pressed("run") and move.y < -0.1 and not crouching
	_set_flashlight(want_light and not dead)

	var speed := RUN_SPEED if running else (BACK_SPEED if move.y > 0.1 else WALK_SPEED)
	if crouching:
		speed = CROUCH_SPEED
	var dir := global_transform.basis * Vector3(move.x, 0, move.y)
	dir.y = 0.0
	velocity = dir.normalized() * speed * minf(move.length(), 1.0) if dir.length() > 0.01 else Vector3.ZERO
	move_and_slide()
	global_position.y = 0.0
	var moved := velocity.length()

	if not dead:
		# Head bob: small, PS1 games kept it subtle.
		_bob += delta * moved * 4.2
		var amp := clampf(moved / WALK_SPEED, 0.0, 1.5)
		var eye_to := SIT_EYE if sitting else (CROUCH_EYE if crouching else EYE_HEIGHT)
		_eye = move_toward(_eye, eye_to, delta * 2.5)
		head.position = Vector3(cos(_bob * 0.5) * 0.025 * amp, _eye + absf(sin(_bob)) * 0.035 * amp, 0)
		_update_hand(delta, amp)
	_stride += moved * delta
	if _stride > (0.95 if running else 0.7):
		_stride = 0.0
		_steps.pitch_scale = randf_range(0.92, 1.08)
		_steps.volume_db = -4.0 if running else (-19.0 if crouching else -11.0)
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
		hand.squeeze(0.5 + 0.5 * sin(_t * TAU * 6.0))


func _set_flashlight(on: bool) -> void:
	if on == flashlight_on:
		return
	flashlight_on = on
	flashlight.visible = on
	_spill.visible = on
	hand.set_lit(on)
	if not on:
		hand.squeeze(0.0)
	if on:
		_whirr.play()
	else:
		_whirr.stop()


## Height the killer looks for: the head, lower when crouching or sitting.
func sight_height() -> float:
	return _eye - 0.35


func face(dir: Vector3) -> void:
	rotation.y = atan2(-dir.x, -dir.z)
	head.rotation.x = 0.0


## Collapses to the floor, still looking up at the man with the cleaver.
func die(killer_pos: Vector3) -> void:
	dead = true
	controllable = false
	_set_flashlight(false)
	var to := killer_pos - global_position
	var tw := create_tween().set_parallel()
	tw.tween_property(hand, "position", HAND_POS + Vector3(0.1, -0.5, 0.2), 0.4)
	tw.tween_property(head, "position", Vector3(0.2, 0.25, 0.3), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(head, "rotation", Vector3(deg_to_rad(35), 0, deg_to_rad(70)), 0.8)
	tw.tween_property(self, "rotation:y", atan2(-to.x, -to.z), 0.6)


## Staggers a little with each blow.
func hit(i: int) -> void:
	var tw := create_tween()
	tw.tween_property(head, "rotation:z", deg_to_rad(8.0 * (1 if i % 2 == 0 else -1)), 0.08)
	tw.tween_property(head, "position:y", head.position.y - 0.25, 0.15)


## Right hand round the «жучок» (scripts/torch_hand.gd), with two small
## lights of its own.
func _build_hand() -> void:
	hand = TorchHand.new()
	hand.roll = 45.0
	hand.reverse = true
	hand.slide = 0.01
	hand.position = HAND_POS
	hand.rotation = HAND_ROT
	camera.add_child(hand)
	# Light bouncing back from the beam picks out the fist and the torch.
	_spill = OmniLight3D.new()
	_spill.position = Vector3(-0.05, 0.12, 0.08)
	_spill.omni_range = 0.5
	_spill.light_energy = 0.4
	_spill.light_color = Color(1.0, 0.92, 0.75)
	_spill.visible = false
	hand.add_child(_spill)
	# A faint fill so the fist does not turn into a black blot against a lit
	# room; too short to reach the shelves.
	var fill := OmniLight3D.new()
	fill.position = Vector3(-0.15, 0.2, 0.15)
	fill.omni_range = 0.45
	fill.light_energy = 0.25
	fill.light_color = Color(0.75, 0.8, 0.75)
	fill.light_specular = 0.2
	hand.add_child(fill)


## Sway behind the mouse, bob with the steps, pull back from walls. With the
## torch off the hand drops below the frame and is hidden.
func _update_hand(delta: float, amp: float) -> void:
	var up := flashlight_on or force_flashlight
	_raise = move_toward(_raise, 1.0 if up else 0.0, delta * (7.0 if up else 3.5))
	hand.visible = _raise > 0.0
	var lift := _raise * _raise * (3.0 - 2.0 * _raise)
	_sway = _sway.lerp(Vector2.ZERO, 1.0 - exp(-delta * 8.0))
	_sway = _sway.limit_length(0.05)
	var q := PhysicsRayQueryParameters3D.create(camera.global_position,
		camera.global_position - camera.global_transform.basis.z * HAND_REACH, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var want_pull := 0.0
	if not hit.is_empty():
		want_pull = HAND_REACH - camera.global_position.distance_to(hit.position)
	_pull = lerpf(_pull, want_pull, 1.0 - exp(-delta * 12.0))
	hand.position = HAND_POS + Vector3(
		-_sway.x + sin(_bob * 0.5) * 0.012 * amp,
		_sway.y - absf(cos(_bob)) * 0.012 * amp - (1.0 - lift) * 0.32,
		_pull)
	hand.rotation.x = HAND_ROT.x - (1.0 - lift) * 0.6
