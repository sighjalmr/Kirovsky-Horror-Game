class_name CameraRig
extends Camera3D

## Silent Hill 1 camera: a lagging follow camera behind Gordeev's back that
## is cut to a fixed, awkward angle in tight spots (the post, the lockers,
## the till, the storage door). From a fixed spot it only turns to track him.

var target: Node3D
var zones: Array[Dictionary] = []   # {rect: Rect2 (x, z), pos: Vector3}
var override_pos = null             # Vector3 when a scene takes the camera

var _zone := -2
var _look := Vector3.ZERO


func _ready() -> void:
	fov = 62.0
	near = 0.15
	far = 40.0


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var tp := target.global_position
	var head := tp + Vector3(0, 1.1, 0)
	if override_pos != null:
		global_position = override_pos
		_look = _look.lerp(tp + Vector3(0, 0.4, 0), 1.0 - exp(-delta * 3.0))
		look_at(_look)
		return

	var zone := _find_zone(tp)
	var cut := zone != _zone
	_zone = zone
	if zone >= 0:
		global_position = zones[zone].pos
		_look = head if cut else _look.lerp(head, 1.0 - exp(-delta * 5.0))
	else:
		var back := target.global_transform.basis.z
		var want := tp + back * 3.0 + Vector3(0, 2.1, 0)
		var eye := tp + Vector3(0, 1.6, 0)
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, want, 1))
		if not hit.is_empty():
			want = hit.position + (eye - want).normalized() * 0.25
		var look_at_pt := head - back * 1.6
		if cut:
			global_position = want
			_look = look_at_pt
		else:
			global_position = global_position.lerp(want, 1.0 - exp(-delta * 3.5))
			_look = _look.lerp(look_at_pt, 1.0 - exp(-delta * 5.0))
	if global_position.distance_to(_look) > 0.05:
		look_at(_look)


func _find_zone(p: Vector3) -> int:
	for i in zones.size():
		if (zones[i].rect as Rect2).has_point(Vector2(p.x, p.z)):
			return i
	return -1
