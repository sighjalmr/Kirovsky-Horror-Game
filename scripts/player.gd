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
const MOUSE_SENS := 0.0025
const STICK_SENS := 2.4
const PITCH_LIMIT := deg_to_rad(80.0)
const FLASHLIGHT_NOISE := 9.0
const RUN_NOISE := 7.0
const HAND_POS := Vector3(0.17, -0.15, -0.38)
const HAND_REACH := 0.55

var controllable := false
var busy := false
var dead := false
var flashlight_on := false
var force_flashlight := false  # dev screenshots
var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var hand: Node3D

var _lever: Node3D
var _lens_mat: ShaderMaterial
var _spill: OmniLight3D
var _sway := Vector2.ZERO
var _pull := 0.0

var _whirr: AudioStreamPlayer3D
var _steps: AudioStreamPlayer3D
var _bob := 0.0
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
	flashlight.position = Vector3(0, 0.03, -0.14)
	# Aim the beam from the hand towards the middle of the view a few metres ahead.
	flashlight.rotation = Vector3(deg_to_rad(-4.0), deg_to_rad(2.0), 0)
	flashlight.spot_range = 14.0
	flashlight.spot_angle = 32.0
	flashlight.spot_attenuation = 0.8
	flashlight.light_color = Color(1.0, 0.92, 0.75)
	flashlight.light_specular = 0.0
	flashlight.shadow_enabled = true
	flashlight.visible = false
	hand.add_child(flashlight)

	_whirr = AudioStreamPlayer3D.new()
	_whirr.stream = Sfx.get_stream("whirr")
	_whirr.bus = Sfx.BUS
	_whirr.volume_db = -8.0
	_whirr.max_distance = 15.0
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
			running = Input.is_action_pressed("run") and move.y < -0.1
	_set_flashlight(want_light and not dead)

	var speed := RUN_SPEED if running else (BACK_SPEED if move.y > 0.1 else WALK_SPEED)
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
		head.position = Vector3(cos(_bob * 0.5) * 0.025 * amp, EYE_HEIGHT + absf(sin(_bob)) * 0.035 * amp, 0)
		_update_hand(delta, amp)
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
		_lever.rotation.x = deg_to_rad(-12.0) * (0.5 + 0.5 * sin(_t * TAU * 6.0))


func _set_flashlight(on: bool) -> void:
	if on == flashlight_on:
		return
	flashlight_on = on
	flashlight.visible = on
	_spill.visible = on
	_lens_mat.set_shader_parameter("emission", Color(1.0, 0.92, 0.7) if on else Color.BLACK)
	if not on:
		_lever.rotation.x = 0.0
	if on:
		_whirr.play()
	else:
		_whirr.stop()


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


## Right forearm in the wool sleeve, and the "zhuchok": a green dynamo
## torch with a chrome bezel. The thumb lies along the top, the fingers are
## curled round the squeeze lever underneath and pump with it. Drawn with the
## same PS1 material as the world.
func _build_hand() -> void:
	hand = Node3D.new()
	hand.position = HAND_POS
	hand.rotation = Vector3(deg_to_rad(4.0), deg_to_rad(6.0), 0)
	camera.add_child(hand)
	_lens_mat = Mats.unique("white", Color(0.6, 0.6, 0.55))
	var fwd := Basis(Vector3.RIGHT, -PI * 0.5)  # cylinders pointing ahead (-z)
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var wool := kit.b("guard_wool")
	wool.cylinder(Transform3D(fwd, Vector3(0.02, -0.06, 0.42)), 0.056, 0.048, 0.33, 8, Color.WHITE, Rect2(0, 0, 2, 2))
	wool.cylinder(Transform3D(fwd, Vector3(0.02, -0.06, 0.11)), 0.052, 0.052, 0.035, 8, Color(0.7, 0.7, 0.7))
	var torch := kit.b("torch")
	torch.cylinder(Transform3D(fwd * Basis.from_scale(Vector3(0.85, 1.0, 1.15)), Vector3(0, 0.025, -0.015)), 0.048,
		0.045, 0.12, 20, Color.WHITE, Rect2(0, 0.2, 1, 0.8), Rect2(0, 0, 1, 0.05), true, true)
	kit.b("torch", Color(0.55, 0.6, 0.55)).cylinder(Transform3D(fwd * Basis.from_scale(Vector3(0.85, 1.0, 1.15)),
		Vector3(0, 0.025, 0.0)), 0.04, 0.046, 0.016, 20, Color.WHITE, Rect2(0, 0.2, 1, 0.8), Rect2(0.3, 0.5, 0.4, 0.4),
		false, true)
	var chrome := kit.b("chrome")
	chrome.cylinder(Transform3D(fwd, Vector3(0, 0.03, -0.134)), 0.035, 0.033, 0.012, 20)
	kit.custom(_lens_mat).cylinder(Transform3D(fwd, Vector3(0, 0.03, -0.145)), 0.027, 0.027, 0.002, 20, Color.WHITE,
		Props.FULL, Rect2(0.4, 0.4, 0.2, 0.2))
	# Back of the hand along the right of the torch, wrist into the cuff, thumb on top.
	var skin := kit.b("skin", Color(0.85, 0.82, 0.8))
	skin.cylinder(Transform3D(fwd * Basis.from_scale(Vector3(0.55, 1.0, 1.0)), Vector3(0.045, -0.035, 0.0)), 0.04,
		0.036, 0.1, 16)
	skin.cylinder(Transform3D(fwd, Vector3(0.025, -0.065, 0.09)), 0.036, 0.04, 0.1, 16)
	skin.cylinder(Transform3D(fwd * Basis(Vector3.FORWARD, 0.25), Vector3(0.03, 0.068, -0.01)), 0.012, 0.01, 0.075, 12,
		Color.WHITE, Props.FULL, Rect2(0.4, 0.4, 0.2, 0.2), true)
	kit.build(hand, false)

	_lever = Node3D.new()
	_lever.position = Vector3(0.0, -0.03, -0.03)
	hand.add_child(_lever)
	var lk := MeshBuilder.Kit.new()
	lk.ao = false
	lk.b("chrome", Color(0.7, 0.7, 0.7)).box(Props.at(0.0, -0.012, -0.05), Vector3(0.02, 0.012, 0.1))
	# Four fingers curled under the torch round the lever, tips up its left side.
	var fingers := lk.b("skin", Color(0.82, 0.78, 0.76))
	var across := Basis(Vector3.BACK, PI * 0.5)  # cylinders pointing to -x
	for i in 4:
		var z := -0.088 + i * 0.022
		var r := 0.0105 - absf(i - 1.0) * 0.0008
		fingers.cylinder(Transform3D(across, Vector3(0.045, -0.03, z)), r, r * 0.95, 0.088, 12, Color.WHITE,
			Props.FULL, Rect2(0.4, 0.4, 0.2, 0.2), true, true)
		fingers.cylinder(Transform3D(Basis.IDENTITY, Vector3(-0.045, -0.03, z)), r * 0.95, r * 0.85, 0.045, 12,
			Color.WHITE, Props.FULL, Rect2(0.4, 0.4, 0.2, 0.2), true)
	lk.build(_lever, false)
	# Light bouncing back from the beam picks out the fist and the torch.
	_spill = OmniLight3D.new()
	_spill.position = Vector3(-0.05, 0.12, 0.08)
	_spill.omni_range = 0.5
	_spill.light_energy = 0.4
	_spill.light_color = Color(1.0, 0.92, 0.75)
	_spill.visible = false
	hand.add_child(_spill)


## Sway behind the mouse, bob with the steps, pull back from walls.
func _update_hand(delta: float, amp: float) -> void:
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
		_sway.y - absf(cos(_bob)) * 0.012 * amp,
		_pull)
