class_name Characters
extends RefCounted

## Low-poly box people in the PS1 budget (a few hundred triangles each).
## Front is -Z. Limbs hang from pivots so they can swing.
## Returns {root, leg_l, leg_r, arm_l, arm_r, head}.


static func part(parent: Node3D, size: Vector3, pos: Vector3, tex: String, tint: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshFactory.box(size, 0.5, 10.0, MeshFactory.ALL, false)
	mi.material_override = Mats.get_mat(tex, tint)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


## Gordeev: night watchman of the vnevedomstvennaya okhrana. Grey-green
## jacket, red armband, peaked cap, moustache, dynamo flashlight on the chest.
static func build_guard() -> Dictionary:
	var root := Node3D.new()
	var trousers := Color(0.2, 0.22, 0.28)
	var coat := Color(0.3, 0.33, 0.28)
	var boots := Color(0.08, 0.08, 0.08)
	var legs: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(root, Vector3(0.11 * side, 0.86, 0))
		part(leg, Vector3(0.17, 0.86, 0.19), Vector3(0, -0.86, 0), "fabric", trousers)
		part(leg, Vector3(0.18, 0.12, 0.26), Vector3(0, -0.86, -0.03), "fabric", boots)
		legs.append(leg)
	part(root, Vector3(0.5, 0.64, 0.28), Vector3(0, 0.82, 0), "fabric", coat)
	part(root, Vector3(0.52, 0.06, 0.3), Vector3(0, 0.86, 0), "fabric", Color(0.25, 0.15, 0.08))
	part(root, Vector3(0.1, 0.12, 0.07), Vector3(0.12, 1.2, -0.16), "metal", Color(0.55, 0.75, 0.5))
	var arms: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var arm := _pivot(root, Vector3(0.32 * side, 1.42, 0))
		part(arm, Vector3(0.14, 0.62, 0.15), Vector3(0, -0.62, 0), "fabric", coat)
		part(arm, Vector3(0.11, 0.1, 0.12), Vector3(0, -0.72, 0), "skin", Color.WHITE)
		if side < 0:
			part(arm, Vector3(0.15, 0.08, 0.16), Vector3(0, -0.24, 0), "fabric", Color(0.6, 0.1, 0.08))
		arms.append(arm)
	var head := _pivot(root, Vector3(0, 1.46, 0))
	part(head, Vector3(0.22, 0.27, 0.24), Vector3(0, 0.0, 0), "skin", Color.WHITE)
	part(head, Vector3(0.27, 0.08, 0.29), Vector3(0, 0.25, 0), "fabric", Color(0.15, 0.17, 0.24))
	part(head, Vector3(0.22, 0.02, 0.1), Vector3(0, 0.25, -0.18), "fabric", Color(0.06, 0.06, 0.08))
	for side: float in [-1.0, 1.0]:
		part(head, Vector3(0.04, 0.03, 0.01), Vector3(0.05 * side, 0.16, -0.125), "fabric", Color(0.05, 0.05, 0.05))
	part(head, Vector3(0.1, 0.025, 0.01), Vector3(0, 0.08, -0.125), "fabric", Color(0.22, 0.14, 0.08))
	return {"root": root, "leg_l": legs[0], "leg_r": legs[1], "arm_l": arms[0], "arm_r": arms[1], "head": head}


## The killer: tall, long dark coat, knitted hat, rubber boots, a butcher's
## cleaver in the right hand. No face, only a dark slit, so nobody can be
## recognised before the fifth night.
static func build_killer() -> Dictionary:
	var root := Node3D.new()
	var coat := Color(0.17, 0.14, 0.12)
	var pale := Color(0.78, 0.72, 0.68)
	var legs: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(root, Vector3(0.12 * side, 0.92, 0))
		part(leg, Vector3(0.19, 0.92, 0.2), Vector3(0, -0.92, 0), "fabric", Color(0.12, 0.12, 0.13))
		part(leg, Vector3(0.2, 0.36, 0.26), Vector3(0, -0.92, -0.02), "fabric", Color(0.05, 0.06, 0.05))
		legs.append(leg)
	part(root, Vector3(0.6, 0.5, 0.32), Vector3(0, 0.5, 0), "fabric", coat)
	part(root, Vector3(0.58, 0.7, 0.32), Vector3(0, 0.95, 0), "fabric", coat)
	var arms: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var arm := _pivot(root, Vector3(0.37 * side, 1.6, 0))
		part(arm, Vector3(0.16, 0.72, 0.17), Vector3(0, -0.72, 0), "fabric", coat)
		part(arm, Vector3(0.12, 0.11, 0.13), Vector3(0, -0.82, 0), "skin", pale)
		if side > 0:
			part(arm, Vector3(0.04, 0.04, 0.24), Vector3(0, -0.86, -0.02), "wood", Color.WHITE)
			part(arm, Vector3(0.025, 0.15, 0.2), Vector3(0, -0.93, -0.24), "metal", Color(1.5, 1.2, 1.2))
		arms.append(arm)
	var head := _pivot(root, Vector3(0, 1.65, 0))
	part(head, Vector3(0.25, 0.29, 0.26), Vector3(0, 0.0, 0), "skin", pale)
	part(head, Vector3(0.28, 0.16, 0.29), Vector3(0, 0.2, 0), "fabric", Color(0.06, 0.06, 0.06))
	part(head, Vector3(0.18, 0.04, 0.01), Vector3(0, 0.15, -0.135), "fabric", Color(0.02, 0.02, 0.02))
	return {"root": root, "leg_l": legs[0], "leg_r": legs[1], "arm_l": arms[0], "arm_r": arms[1], "head": head}


## Shared walk cycle: legs and arms swing opposite each other.
static func walk(parts: Dictionary, phase: float, amount: float, swing_right_arm := true) -> void:
	var s := sin(phase) * 0.55 * amount
	(parts.leg_l as Node3D).rotation.x = s
	(parts.leg_r as Node3D).rotation.x = -s
	(parts.arm_l as Node3D).rotation.x = -s * 0.7
	if swing_right_arm:
		(parts.arm_r as Node3D).rotation.x = s * 0.7
