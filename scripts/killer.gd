class_name Killer
extends CharacterBody3D

## The maniac: участковый Колесников out of uniform, in a knitted hat with a
## scarf over his face (see the plot on the concept page). With women he uses
## a cord; on Gordeev he uses the cleaver from the meat counter, so that the
## blame falls on Ринат the butcher. An ordinary man with keys to the storage door: no powers,
## he sees only what light shows him and hears what Gordeev does.
## In the dark he notices Gordeev only at arm's length; the flashlight and
## lit rows give him away from far off. Noise (the whirr, running, lifting
## a cloth, the phone) draws him to the spot.

signal spotted
signal lost
signal caught_player
signal left

enum State { INACTIVE, PATROL, INVESTIGATE, CHASE, SEARCH, ATTACK, LEAVE }

const PATROL_SPEED := 1.2
const INVESTIGATE_SPEED := 1.8
const CHASE_SPEED := 3.0
const SIGHT_LIT := 14.0
const SIGHT_FLASH := 18.0
const SIGHT_DARK := 2.2
const SIGHT_DARK_LOW := 1.3
const SIGHT_LIT_LOW := 9.0
const FOV_COS := 0.42
const REACH := 1.2
## How fast he makes Gordeev out once he sees him: within 4 m, and further off.
const SUSPECT_NEAR := 2.6
const SUSPECT_FAR := 1.1

## Developer runs: he never notices Gordeev.
static var blind := false

var state := State.INACTIVE
var store: Store
var player: Player
var body: Person
var suspicion := 0.0
## Told to go: he finishes any chase, then walks out through the storage door.
var leaving := false

var _path := PackedVector3Array()
var _path_i := 0
var _wait := 0.0
var _last_seen := Vector3.ZERO
var _lost_t := 0.0
var _repath_t := 0.0
var _stuck_t := 0.0
var _keys_t := 6.0
var _steps: AudioStreamPlayer3D
## Seconds he still stands stock-still where he got to (lurk_at), staring
## down the aisle; 0 when he is not lurking.
var _lurk_t := 0.0
## The breath he catches when he first half-notices Gordeev, once per alarm.
var _alerted := false
## Night four: his own torch, a militia «фонарь» held low at the hip. Gordeev
## sees the beam coming down the aisle; anybody caught in it is seen too.
var torch: SpotLight3D
var _torch_t := 0.0
## Standing in wait he holds the torch low, at the floor in front of him:
## the beam is a pool on the tiles, the lamp a bright point in the dark.
var _torch_pitch := -6.0
const TORCH_LURK_PITCH := -40.0
const TORCH_RANGE := 12.0
const TORCH_COS := 0.93


func setup(s: Store, p: Player) -> void:
	store = s
	player = p


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	add_child(cs)
	body = Characters.build_killer()
	add_child(body)
	body.footfall.connect(_on_footfall)
	visible = false
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = Sfx.get_stream("heavy_step")
	_steps.bus = Sfx.BUS
	_steps.max_distance = 22.0
	_steps.unit_size = 4.0
	_steps.volume_db = -3.0
	add_child(_steps)


func is_active() -> bool:
	return state != State.INACTIVE


func activate(pos: Vector3) -> void:
	global_position = pos
	visible = true
	leaving = false
	body.aim("Bip01 R UpperArm", Vector3.ZERO, 0.0)
	body.aim("Bip01 R Forearm", Vector3.ZERO, 0.0)
	suspicion = 0.0
	state = State.PATROL
	_wait = 1.5
	_path.clear()


func deactivate() -> void:
	state = State.INACTIVE
	velocity = Vector3.ZERO
	set_torch(false)


func set_torch(on: bool) -> void:
	if on and torch == null:
		torch = SpotLight3D.new()
		torch.position = Vector3(0.24, 1.15, -0.3)
		torch.spot_range = TORCH_RANGE + 2.0
		torch.spot_angle = 19.0
		torch.spot_attenuation = 0.8
		torch.light_energy = 3.2
		torch.light_color = Color(1.0, 0.9, 0.72)
		torch.light_specular = 0.3
		torch.shadow_enabled = true
		add_child(torch)
		var lens := MeshInstance3D.new()
		var m := CylinderMesh.new()
		m.top_radius = 0.028
		m.bottom_radius = 0.022
		m.height = 0.2
		lens.mesh = m
		lens.rotation.x = PI * 0.5
		lens.position = Vector3(0, 0, 0.1)
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lens.material_override = Mats.get_mat("metal", Color(0.15, 0.15, 0.15))
		torch.add_child(lens)
		# The glass itself glows: from the front the torch is a bright point in the dark.
		var glass := MeshInstance3D.new()
		var g := SphereMesh.new()
		g.radius = 0.03
		g.height = 0.02
		glass.mesh = g
		glass.position = Vector3(0, 0, -0.005)
		glass.material_override = Mats.get_mat("white", Color(1, 0.95, 0.8), Color(6.0, 5.2, 3.8))
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		torch.add_child(glass)
	if torch:
		torch.visible = on


func torch_on() -> bool:
	return torch != null and torch.visible


## Walks back out through the storage door and is gone (emits `left`).
func leave() -> void:
	leaving = true
	if state in [State.PATROL, State.INVESTIGATE, State.SEARCH]:
		_start_leave()


func _start_leave() -> void:
	state = State.LEAVE
	_go_to(store.killer_spawn)
	_path.append(store.storage_inside)


func hear(pos: Vector3, radius: float) -> void:
	if state in [State.INACTIVE, State.CHASE, State.ATTACK, State.LEAVE]:
		return
	if global_position.distance_to(pos) > radius or Outdoors.is_out(pos):
		return  # out on the square, behind glass and rain
	if is_lurking() and global_position.distance_to(pos) > radius * 0.6:
		return  # standing in wait, he lets a small sound come closer
	state = State.INVESTIGATE
	_wait = 0.0
	_lurk_t = 0.0
	_go_to(pos)


## Gordeev tore free: he reels back with the torch in his face, then is
## after him again.
func stun(t: float) -> void:
	state = State.ATTACK
	velocity = Vector3.ZERO
	body.play("breathe")
	var away := global_position - player.global_position
	away.y = 0.0
	if away.length() > 0.01:
		var tw := create_tween()
		tw.tween_property(self, "global_position", global_position + away.normalized() * 0.9, 0.35).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(t).timeout
	if state == State.ATTACK and not player.dead:
		if player.hidden:
			state = State.SEARCH
			_wait = 0.0
			_go_to(player.global_position)
		else:
			_start_chase()


## True while he is chasing Gordeev and has him in sight right now.
func has_him_in_sight() -> bool:
	return state == State.CHASE and _lost_t < 0.3


## Walks somewhere without being alarmed (used while Gordeev is on the phone).
func wander_to(pos: Vector3) -> void:
	if state in [State.PATROL, State.SEARCH]:
		state = State.INVESTIGATE
		_wait = 0.0
		_go_to(pos)


## Walks to `pos` and stands there without moving for `t` seconds, facing
## down the aisle, like a man waiting. Sight still works: a light or a
## careless step in front of him and he comes.
func lurk_at(pos: Vector3, t: float) -> void:
	if state in [State.PATROL, State.SEARCH, State.INVESTIGATE] and not leaving:
		state = State.INVESTIGATE
		_wait = 0.0
		_lurk_t = t
		_go_to(pos)


## True while he stands still at the end of an aisle (lurk_at).
func is_lurking() -> bool:
	return state == State.INVESTIGATE and _lurk_t > 0.0 and _path_done()


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE or state == State.ATTACK:
		return
	var sees := _sees_player()
	var staring := false
	if state != State.CHASE:
		if sees:
			# Close by he is sure at once; further off he stops dead and
			# stares first, which gives Gordeev a moment to back into the dark.
			# Standing in wait (lurk_at) he takes his time: he lets the light
			# come to him.
			suspicion += delta * (SUSPECT_NEAR if _dist_to_player() < 4.0 else SUSPECT_FAR) \
				* (0.55 if is_lurking() else 1.0)
			_face(player.global_position, delta * 3.0)
			staring = suspicion > 0.12
			if suspicion > 0.3 and not _alerted:
				_alerted = true
				Sfx.play_3d(get_parent(), "killer_breath", global_position + Vector3(0, 1.7, 0), -10.0, 0.9, 14.0)
			if suspicion >= 1.0:
				_start_chase()
		else:
			suspicion = maxf(0.0, suspicion - delta * 0.35)
			if suspicion <= 0.0:
				_alerted = false

	if torch_on():
		# The beam swings a little with his step and sweeps when he looks round.
		_torch_t += delta
		_torch_pitch = move_toward(_torch_pitch, TORCH_LURK_PITCH if is_lurking() else -6.0, delta * 40.0)
		torch.rotation = Vector3(deg_to_rad(_torch_pitch) + sin(_torch_t * 1.3) * 0.05, sin(_torch_t * 0.7) * 0.12, 0)
	var speed := 0.0
	match state:
		State.LEAVE:
			if _path_done():
				deactivate()
				visible = false
				left.emit()
				return
			speed = INVESTIGATE_SPEED
		State.PATROL:
			if leaving:
				_start_leave()
			elif _path_done():
				_wait -= delta
				if _wait <= 0.0:
					_go_to(store.random_patrol_point())
					_wait = randf_range(1.5, 4.0)
			else:
				speed = PATROL_SPEED
		State.INVESTIGATE:
			if _path_done() and _lurk_t > 0.0:
				_lurk_t -= delta
				_face(player.global_position, delta * 0.6)
				if leaving:
					_lurk_t = 0.0
			elif _path_done():
				_wait += delta
				rotation.y += sin(_wait * 1.7) * delta * 1.5
				if _wait > 3.5:
					state = State.PATROL
					_wait = 1.0
					if leaving:
						_start_leave()
			else:
				speed = INVESTIGATE_SPEED
		State.CHASE:
			speed = CHASE_SPEED
			if sees:
				_last_seen = player.global_position
				_lost_t = 0.0
			else:
				_lost_t += delta
			_repath_t -= delta
			if sees and store.walkable(global_position, player.global_position):
				_path = PackedVector3Array([player.global_position])
				_path_i = 0
			elif _repath_t <= 0.0:
				_go_to(_last_seen)
				_repath_t = 0.6
			if _lost_t > 4.5:
				state = State.SEARCH
				_wait = 0.0
				_go_to(_last_seen)
				lost.emit()
			elif _dist_to_player() < REACH and not player.dead and not player.hidden:
				state = State.ATTACK
				velocity = Vector3.ZERO
				_face(player.global_position, 1.0)
				caught_player.emit()
				return
		State.SEARCH:
			if _path_done():
				_wait += delta
				rotation.y += delta * 1.2
				if _wait > 5.0:
					state = State.PATROL
					_wait = 0.5
					if leaving:
						_start_leave()
			else:
				speed = INVESTIGATE_SPEED
	if staring:
		speed = 0.0
	_move(speed, delta)


func _start_chase() -> void:
	_lurk_t = 0.0
	state = State.CHASE
	suspicion = 1.0
	_lost_t = 0.0
	_last_seen = player.global_position
	_repath_t = 0.0
	spotted.emit()


func _dist_to_player() -> float:
	var d := player.global_position - global_position
	d.y = 0.0
	return d.length()


func _sees_player() -> bool:
	if player.dead or blind or player.hidden or Outdoors.is_out(player.global_position):
		return false
	var eye := global_position + Vector3(0, 1.7, 0)
	var tgt := player.global_position + Vector3(0, player.sight_height(), 0)
	var d := eye.distance_to(tgt)
	var low := player.crouching
	var limit := SIGHT_DARK_LOW if low else SIGHT_DARK
	if player.flashlight_on:
		limit = SIGHT_FLASH
	elif store.is_lit(player.global_position):
		limit = SIGHT_LIT_LOW if low else SIGHT_LIT
	elif torch_on() and (-torch.global_transform.basis.z).dot((tgt - torch.global_position).normalized()) > TORCH_COS:
		limit = TORCH_RANGE * (0.75 if low else 1.0)  # caught in his beam
	if d > limit:
		return false
	var to := tgt - eye
	to.y = 0.0
	if d > 1.5 and (-global_transform.basis.z).dot(to.normalized()) < FOV_COS:
		return false
	var q := PhysicsRayQueryParameters3D.create(eye, tgt, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _go_to(pos: Vector3) -> void:
	var from_id := store.closest_node(global_position)
	var to_id := store.closest_node(pos)
	_path = store.astar.get_point_path(from_id, to_id)
	_path.append(Vector3(pos.x, 0.0, pos.z))
	_path_i = 0
	# Skip the first node when the second is already in a straight line.
	if _path.size() > 1 and store.walkable(global_position, _path[1]):
		_path_i = 1


func _path_done() -> bool:
	return _path_i >= _path.size()


func _move(speed: float, delta: float) -> void:
	if speed <= 0.0 or _path_done():
		velocity = Vector3.ZERO
		_animate(0.0, delta)
		return
	var to := _path[_path_i] - global_position
	to.y = 0.0
	if to.length() < 0.3:
		_path_i += 1
		return
	var dir := to.normalized()
	velocity = dir * speed
	_face(global_position + dir, delta * 8.0)
	var before := global_position
	move_and_slide()
	# The hall floor, or the cellar stairs behind the back wall (night three).
	var g := Outdoors.ground_for(self)
	global_position.y = 0.0 if is_nan(g) else g
	if before.distance_to(global_position) < speed * delta * 0.25:
		_stuck_t += delta
		if _stuck_t > 1.0:
			_stuck_t = 0.0
			_path_i += 1
			_repath_t = 0.0
	else:
		_stuck_t = 0.0
	_animate(speed, delta)


func _animate(speed: float, delta: float) -> void:
	# Captured gaits at his pace, the feet planted: a creeping walk on
	# patrol, a brisk one when he heads for a noise, a run in a chase. The
	# boots sound on each footfall of the clip.
	if speed <= 0.05:
		body.play("breathe")
	elif speed <= PATROL_SPEED + 0.1:
		body.play("prowl", speed)
	elif speed < CHASE_SPEED - 0.4:
		body.play("walk", speed)
	else:
		body.play("run", speed)
	_keys_t -= delta
	if _keys_t <= 0.0 and state == State.PATROL and speed > 0.0:
		_keys_t = randf_range(8.0, 16.0)
		Sfx.play_3d(get_parent(), "keys", global_position + Vector3(0, 1.0, 0), -8.0)


func _face(point: Vector3, weight: float) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), clampf(weight, 0.0, 1.0))


## Three cleaver blows, his breathing heavy and close. Each `hit` fires on
## contact; the swing whooshes as the arm comes down. The captured body
## keeps breathing; the right arm is swung over it by hand: up behind the
## head, then down and forward through Gordeev.
func play_attack(hit: Callable) -> void:
	body.play("breathe")
	var breath := Sfx.play_3d(self, "killer_breath", global_position + Vector3(0, 1.7, 0), 0.0, 1.0, 10.0)
	breath.unit_size = 2.0
	var tw := create_tween()
	tw.tween_method(_swing, 1.0, 0.0, 0.3).set_trans(Tween.TRANS_QUAD)
	for i in 3:
		if i > 0:
			tw.tween_method(_swing, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			Sfx.play_3d(self, "swing", global_position + Vector3(0, 1.6, 0), -2.0, randf_range(0.93, 1.07)))
		tw.tween_method(_swing, 0.0, 1.0, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_callback(hit.bind(i))
		tw.tween_interval(0.18)
	# He stands over the body a while, getting his breath back.
	tw.tween_interval(3.0)
	tw.tween_property(breath, "volume_db", -60.0, 5.0)
	tw.tween_callback(breath.queue_free)


## 0: the cleaver raised over his head; 1: the blow landed, arm out in front.
func _swing(t: float) -> void:
	body.aim("Bip01 R UpperArm", Vector3(0.3, 1.0, 0.35).lerp(Vector3(0.1, -0.15, -1.0), t))
	body.aim("Bip01 R Forearm", Vector3(-0.1, 1.0, 0.1).lerp(Vector3(-0.15, -0.7, -1.0), t))


func _on_footfall() -> void:
	_steps.pitch_scale = randf_range(0.95, 1.03)
	_steps.play()
