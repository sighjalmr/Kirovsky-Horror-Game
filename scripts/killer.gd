class_name Killer
extends CharacterBody3D

## The maniac. An ordinary man with keys to the storage door: no powers,
## he sees only what light shows him and hears what Gordeev does.
## In the dark he notices Gordeev only at arm's length; the flashlight and
## lit rows give him away from far off. Noise (the whirr, running, lifting
## a cloth, the phone) draws him to the spot.

signal spotted
signal lost
signal caught_player

enum State { INACTIVE, PATROL, INVESTIGATE, CHASE, SEARCH, ATTACK }

const PATROL_SPEED := 1.2
const INVESTIGATE_SPEED := 1.8
const CHASE_SPEED := 3.0
const SIGHT_LIT := 14.0
const SIGHT_FLASH := 18.0
const SIGHT_DARK := 2.2
const FOV_COS := 0.42
const REACH := 1.2

var state := State.INACTIVE
var store: Store
var player: Player
var parts: Dictionary
var suspicion := 0.0

var _path := PackedVector3Array()
var _path_i := 0
var _wait := 0.0
var _last_seen := Vector3.ZERO
var _lost_t := 0.0
var _repath_t := 0.0
var _stuck_t := 0.0
var _keys_t := 6.0
var _stride := 0.0
var _anim := 0.0
var _steps: AudioStreamPlayer3D


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
	parts = Characters.build_killer()
	add_child(parts.root)
	(parts.arm_r as Node3D).rotation.x = 0.35
	visible = false
	_steps = AudioStreamPlayer3D.new()
	_steps.stream = Sfx.get_stream("heavy_step")
	_steps.max_distance = 22.0
	_steps.unit_size = 4.0
	_steps.volume_db = -3.0
	add_child(_steps)


func is_active() -> bool:
	return state != State.INACTIVE


func activate(pos: Vector3) -> void:
	global_position = pos
	visible = true
	state = State.PATROL
	_wait = 1.5
	_path.clear()


func deactivate() -> void:
	state = State.INACTIVE
	velocity = Vector3.ZERO


func hear(pos: Vector3, radius: float) -> void:
	if state in [State.INACTIVE, State.CHASE, State.ATTACK]:
		return
	if global_position.distance_to(pos) > radius:
		return
	state = State.INVESTIGATE
	_wait = 0.0
	_go_to(pos)


## Walks somewhere without being alarmed (used while Gordeev is on the phone).
func wander_to(pos: Vector3) -> void:
	if state in [State.PATROL, State.SEARCH]:
		state = State.INVESTIGATE
		_wait = 0.0
		_go_to(pos)


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE or state == State.ATTACK:
		return
	var sees := _sees_player()
	if state != State.CHASE:
		if sees:
			suspicion += delta * (3.0 if _dist_to_player() < 6.0 else 1.4)
			_face(player.global_position, delta * 3.0)
			if suspicion >= 1.0:
				_start_chase()
		else:
			suspicion = maxf(0.0, suspicion - delta * 0.4)

	var speed := 0.0
	match state:
		State.PATROL:
			if _path_done():
				_wait -= delta
				if _wait <= 0.0:
					_go_to(store.random_patrol_point())
					_wait = randf_range(1.5, 4.0)
			else:
				speed = PATROL_SPEED
		State.INVESTIGATE:
			if _path_done():
				_wait += delta
				rotation.y += sin(_wait * 1.7) * delta * 1.5
				if _wait > 3.5:
					state = State.PATROL
					_wait = 1.0
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
			elif _dist_to_player() < REACH and not player.dead:
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
			else:
				speed = INVESTIGATE_SPEED
	_move(speed, delta)


func _start_chase() -> void:
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
	if player.dead:
		return false
	var eye := global_position + Vector3(0, 1.7, 0)
	var tgt := player.global_position + Vector3(0, 1.2, 0)
	var d := eye.distance_to(tgt)
	var limit := SIGHT_DARK
	if player.flashlight_on:
		limit = SIGHT_FLASH
	elif store.is_lit(player.global_position):
		limit = SIGHT_LIT
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
	global_position.y = 0.0
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
	_anim += delta * speed * 3.0
	Characters.walk(parts, _anim, clampf(speed / PATROL_SPEED, 0.0, 1.5), false)
	_stride += speed * delta
	if _stride > 0.85:
		_stride = 0.0
		_steps.pitch_scale = randf_range(0.85, 1.0)
		_steps.play()
	_keys_t -= delta
	if _keys_t <= 0.0 and state == State.PATROL and speed > 0.0:
		_keys_t = randf_range(8.0, 16.0)
		Sfx.play_3d(get_parent(), "keys", global_position + Vector3(0, 1.0, 0), -8.0)


func _face(point: Vector3, weight: float) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), clampf(weight, 0.0, 1.0))


## Three cleaver blows. Each `hit` fires on contact.
func play_attack(hit: Callable) -> void:
	var arm: Node3D = parts.arm_r
	var tw := create_tween()
	for i in 3:
		tw.tween_property(arm, "rotation:x", 2.8, 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(arm, "rotation:x", 0.7, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_callback(hit.bind(i))
		tw.tween_interval(0.18)
