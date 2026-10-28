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
const HAND_POS := Vector3(0.17, -0.16, -0.41)
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
var hand: Node3D

var _lever: Node3D
var _lens_mat: ShaderMaterial
var _bulb_mat: ShaderMaterial
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
	flashlight.position = Vector3(0, 0.02, -0.065)
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
		_lever.rotation.x = deg_to_rad(-7.0) * (0.5 + 0.5 * sin(_t * TAU * 6.0))


func _set_flashlight(on: bool) -> void:
	if on == flashlight_on:
		return
	flashlight_on = on
	flashlight.visible = on
	_spill.visible = on
	_lens_mat.set_shader_parameter("emission", Color(0.9, 0.8, 0.6) if on else Color.BLACK)
	_bulb_mat.set_shader_parameter("emission", Color(3.0, 2.6, 1.8) if on else Color.BLACK)
	if not on:
		_lever.rotation.x = 0.0
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


## Right forearm in the wool sleeve, and the "zhuchok": an olive dynamo
## torch with a chrome bezel, reflector, glass and bulb. A hand built bone by
## bone: back of the hand, knuckles, three phalanges per finger, the thumb
## along the top with its nail. The fingers curl round the squeeze lever
## underneath and pump with it.
func _build_hand() -> void:
	hand = Node3D.new()
	hand.position = HAND_POS
	hand.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(2.0), deg_to_rad(45.0))
	camera.add_child(hand)
	_lens_mat = Mats.unique("glass", Color(0.85, 0.9, 0.85, 0.45), Color.BLACK, Mats.GLASS)
	_bulb_mat = Mats.unique("white", Color(0.7, 0.68, 0.6))
	var fwd := Basis(Vector3.RIGHT, -PI * 0.5)  # lathes pointing ahead (-z)
	var kit := MeshBuilder.Kit.new()
	kit.ao = false

	# The «жучок»: an oval moulded body, rounded at the back, a chrome bezel
	# with a polished reflector, a domed glass and the bulb behind it.
	var c := Vector3(0, 0.02, 0)
	var flat := fwd * Basis.from_scale(Vector3(1.2, 1.0, 0.9))
	kit.b("torch").lathe(Transform3D(flat, c), [Vector2(0, -0.066), Vector2(0.012, -0.065), Vector2(0.021, -0.061),
		Vector2(0.027, -0.054), Vector2(0.03, -0.042), Vector2(0.031, -0.02), Vector2(0.031, 0.015), Vector2(0.03, 0.035),
		Vector2(0.028, 0.046)], 28, Color.WHITE, Rect2(0, 0, 2, 1))
	var chrome := kit.b("chrome")
	chrome.lathe(Transform3D(fwd, c), [Vector2(0.025, 0.043), Vector2(0.031, 0.046), Vector2(0.0325, 0.05),
		Vector2(0.0325, 0.056), Vector2(0.031, 0.059), Vector2(0.026, 0.0595)], 28, Color.WHITE, Rect2(0, 0, 3, 0.3))
	chrome.lathe(Transform3D(fwd, c), [Vector2(0.026, 0.0595), Vector2(0.018, 0.055), Vector2(0.009, 0.05),
		Vector2(0.0, 0.048)], 28, Color(1.2, 1.18, 1.1), Rect2(0, 0.3, 3, 0.4))
	kit.custom(_bulb_mat).ellipsoid(Transform3D(fwd, c + Vector3(0, 0, -0.052)), Vector3(0.0045, 0.006, 0.0045), 10, 6)
	kit.custom(_lens_mat).lathe(Transform3D(fwd, c), [Vector2(0.0255, 0.0585), Vector2(0.018, 0.0605),
		Vector2(0.009, 0.0615), Vector2(0.0, 0.0618)], 28, Color.WHITE, Rect2(0.3, 0.3, 0.4, 0.4))

	var skin := kit.b("skin", Color(0.9, 0.86, 0.84))
	var nail := kit.b("skin", Color(1.15, 0.95, 0.9))
	# Back of the hand on the right of the torch, the ball of the thumb under
	# it, the wrist going into the cuff.
	skin.ellipsoid(Transform3D(Basis(Vector3.BACK, 0.35), Vector3(0.05, 0.004, 0.056)), Vector3(0.019, 0.037, 0.052), 18, 10)
	skin.ellipsoid(Transform3D(Basis(Vector3.BACK, -0.5), Vector3(0.03, 0.024, 0.07)), Vector3(0.02, 0.019, 0.034), 14, 8)
	skin.ellipsoid(Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.022, -0.022, 0.085)), Vector3(0.03, 0.022, 0.035), 14, 8)
	skin.capsule(Transform3D.IDENTITY, Vector3(0.042, -0.006, 0.095), Vector3(0.04, -0.018, 0.17), 0.027, 0.029, 18)
	# Thumb over the top of the torch: metacarpal, two phalanges, the nail.
	var th := [Vector3(0.036, 0.028, 0.08), Vector3(0.017, 0.052, 0.036), Vector3(0.002, 0.058, 0.006),
		Vector3(-0.007, 0.056, -0.016)]
	var thr := [0.014, 0.0115, 0.0108, 0.0085]
	for i in 3:
		skin.capsule(Transform3D.IDENTITY, th[i], th[i + 1], thr[i], thr[i + 1], 14)
	nail.ellipsoid(Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3(-0.0045, 0.0645, -0.01)), Vector3(0.0068, 0.0022, 0.009), 12, 6)
	# Wool sleeve with a turned cuff.
	var wool := kit.b("guard_wool")
	wool.lathe(Transform3D(fwd, Vector3(0.04, -0.022, 0.025)), [Vector2(0.056, -0.46), Vector2(0.05, -0.2),
		Vector2(0.047, -0.15), Vector2(0.044, -0.13)], 24, Color.WHITE, Rect2(0, 0, 3, 2))
	wool.lathe(Transform3D(fwd, Vector3(0.04, -0.022, 0.025)), [Vector2(0.0, -0.14), Vector2(0.035, -0.135),
		Vector2(0.047, -0.13), Vector2(0.05, -0.125), Vector2(0.05, -0.112), Vector2(0.046, -0.108), Vector2(0.038, -0.11)],
		24, Color(0.75, 0.75, 0.72), Rect2(0, 0, 3, 0.3))
	kit.build(hand, false)

	# The squeeze lever under the body, hinged at the front, and the four
	# fingers curled round body and lever, pumping with it.
	var hinge := Vector3(0, -0.006, -0.042)
	_lever = Node3D.new()
	_lever.position = hinge
	hand.add_child(_lever)
	var lk := MeshBuilder.Kit.new()
	lk.ao = false
	var lever := lk.b("metal", Color(0.55, 0.55, 0.5))
	for i in 7:
		var p := Vector3(0, -0.012 - i * 0.0012, -0.036 + i * 0.012) - hinge
		lever.box(Props.rot(Vector3.RIGHT, -0.1, p), Vector3(0.03 - i * 0.0008, 0.005, 0.013))
		lever.box(Props.at(p.x, p.y - 0.0012, p.z), Vector3(0.031 - i * 0.0008, 0.0015, 0.004), Color(0.75, 0.75, 0.7))
	lk.b("chrome").cylinder(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.018, -0.009, -0.04) - hinge), 0.004, 0.004,
		0.036, 10)
	var fing := lk.b("skin", Color(0.88, 0.83, 0.81))
	var fnail := lk.b("skin", Color(1.12, 0.93, 0.88))
	# Each finger follows an oval round the grip: knuckle above on the right,
	# under the lever, tip up on the left. Angles of the joints in degrees.
	var joints := [-28.0, 50.0, 112.0, 158.0]
	var widths := [0.0098, 0.0103, 0.0097, 0.0083]
	for f in 4:
		var z := -0.012 + f * 0.021
		var r: float = widths[f]
		var rx := 0.049 - f * 0.001
		var ry := 0.043 - f * 0.0015
		var pts: Array[Vector3] = []
		for j in 4:
			var a := deg_to_rad(joints[j] - (6.0 if f == 3 and j > 0 else 0.0))
			pts.append(Vector3(rx * cos(a), 0.012 - ry * sin(a), z) - hinge)
		var rs := [r * 1.12, r, r * 0.92, r * 0.78]
		fing.ellipsoid(Transform3D(Basis.IDENTITY, pts[0]), Vector3(r * 1.2, r * 1.15, r * 1.05), 12, 6)
		for j in 3:
			fing.capsule(Transform3D.IDENTITY, pts[j], pts[j + 1], rs[j], rs[j + 1], 12)
		var tip := pts[3]
		fnail.ellipsoid(Transform3D(Basis(Vector3.BACK, deg_to_rad(158.0 - 90.0)), tip + Vector3(-r * 0.55, -r * 0.1, 0)),
			Vector3(r * 0.35, r * 0.8, r * 0.7), 10, 6)
	lk.build(_lever, false)
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
	hand.rotation.x = deg_to_rad(-6.0) - (1.0 - lift) * 0.6
