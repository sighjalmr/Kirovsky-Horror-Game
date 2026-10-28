class_name Characters
extends RefCounted

## People at the Silent Hill 1 budget (about a thousand triangles each):
## tapered limbs, clothes with their own textures, hands with fingers.
## Front is -Z. Limbs hang from pivots so they can swing.
## Returns {root, leg_l, leg_r, arm_l, arm_r, head}.

const NO_RECT := Rect2()


## A single box with the PS1 material (the viewmodel hand uses it).
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


## Flattened (elliptic) upright cylinder: depth is `flat` times the width.
static func _oval(x: Vector3, flat: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3(1, 1, flat)), x)


## A hand at the end of an arm, fingers curled round a grip or hanging loose.
## `pos` is the wrist; the hand hangs down from it.
static func hand(kit: MeshBuilder.Kit, pos: Vector3, tint: Color, side: float, grip: bool) -> void:
	var skin := kit.b("skin", tint)
	skin.box(Props.at(pos.x, pos.y - 0.1, pos.z), Vector3(0.035, 0.1, 0.085), Color.WHITE, NO_RECT, Vector2(0.3, 0.3))
	for i in 4:
		var z := pos.z - 0.03 + i * 0.02
		if grip:
			skin.box(Props.at(pos.x - side * 0.025, pos.y - 0.13, z), Vector3(0.03, 0.035, 0.017))
		else:
			skin.box(Props.rot(Vector3.FORWARD, side * 0.15, Vector3(pos.x, pos.y - 0.2 + absf(i - 1.5) * 0.01, z)),
				Vector3(0.022, 0.09, 0.017))
	skin.box(Props.rot(Vector3.RIGHT, -0.5, Vector3(pos.x - side * 0.022, pos.y - 0.11, pos.z - 0.045)),
		Vector3(0.02, 0.06, 0.02))


## The killer: tall, a long dark drape coat with the collar up, a knitted
## hat pulled low and a scarf over the mouth, rubber boots, a butcher's
## cleaver in the right hand. Only the eyes show, deep in shadow, so nobody
## can be recognised before the fifth night.
static func build_killer() -> Dictionary:
	var root := Node3D.new()
	var coat := Color(1.0, 1.0, 1.0)
	var pale := Color(0.85, 0.8, 0.78)
	var body := MeshBuilder.Kit.new()
	body.ao = false
	var c := body.b("coat")
	# Coat: chest, shoulders, flared skirt to below the knee, collar turned up.
	c.cylinder(_oval(Vector3(0, 0.98, 0), 0.62), 0.25, 0.27, 0.6, 16, coat, Rect2(0, 0, 3, 1.2))
	c.box(Props.at(0, 1.5, 0), Vector3(0.62, 0.1, 0.3), coat, NO_RECT, Vector2(0.5, 0.5))
	c.cylinder(_oval(Vector3(0, 0.36, 0), 0.68), 0.36, 0.26, 0.64, 16, coat, Rect2(0, 0, 3.5, 1.3), Rect2(), false)
	c.cylinder(_oval(Vector3(0, 1.56, 0.01), 0.85), 0.14, 0.16, 0.13, 16, Color(0.85, 0.85, 0.85))
	c.box(Props.at(0, 0.98, -0.165), Vector3(0.04, 0.58, 0.01), Color(0.7, 0.7, 0.7))
	var btn := body.b("leather", Color(0.4, 0.4, 0.4))
	for i in 4:
		btn.box(Props.at(0.06, 1.0 + i * 0.13, -0.172), Vector3(0.03, 0.03, 0.008))
	body.b("leather", Color(0.6, 0.6, 0.6)).cylinder(_oval(Vector3(0, 0.95, 0), 0.63), 0.262, 0.262, 0.05, 16)
	body.build(root)

	var legs: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var leg := _pivot(root, Vector3(0.11 * side, 0.92, 0))
		var k := MeshBuilder.Kit.new()
		k.ao = false
		k.b("trousers").cylinder(Props.at(0, -0.62, 0), 0.07, 0.09, 0.62, 16)
		var boot := k.b("rubber")
		boot.cylinder(Props.at(0, -0.92, 0), 0.075, 0.08, 0.34, 16)
		boot.box(Props.at(0, -0.92, -0.06), Vector3(0.11, 0.08, 0.25))
		boot.box(Props.at(0, -0.92, -0.06), Vector3(0.12, 0.025, 0.27), Color(0.6, 0.6, 0.6))
		k.build(leg)
		legs.append(leg)

	var arms: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var arm := _pivot(root, Vector3(0.33 * side, 1.56, 0))
		var k := MeshBuilder.Kit.new()
		k.ao = false
		var sl := k.b("coat")
		sl.cylinder(Props.at(0, -0.36, 0), 0.07, 0.085, 0.38, 16)
		sl.cylinder(Props.at(0, -0.66, 0), 0.068, 0.07, 0.31, 16)
		sl.cylinder(Props.at(0, -0.7, 0), 0.075, 0.075, 0.06, 16, Color(0.8, 0.8, 0.8))
		hand(k, Vector3(0, -0.7, 0), pale, side, side > 0)
		if side > 0:
			# Cleaver: wooden grip in the fist, a wide blade pointing forward, dull and stained.
			k.b("wood").box(Props.at(0.0, -0.86, -0.05), Vector3(0.03, 0.035, 0.14))
			var blade := k.b("chrome", Color(0.85, 0.8, 0.78))
			blade.box(Props.at(0.0, -0.94, -0.26), Vector3(0.006, 0.13, 0.22))
			k.b("blood").box(Props.at(0.0, -0.94, -0.3), Vector3(0.008, 0.08, 0.13), Color(1.2, 1.0, 1.0),
				Rect2(0.3, 0.3, 0.4, 0.4))
		k.build(arm)
		arms.append(arm)

	var head := _pivot(root, Vector3(0, 1.62, 0))
	var hk := MeshBuilder.Kit.new()
	hk.ao = false
	hk.b("skin", pale).cylinder(Props.at(0, -0.04, 0), 0.06, 0.06, 0.1, 16)
	# Skull, and the face as a slightly curved mask on its front.
	hk.b("skin", pale).cylinder(_oval(Vector3(0, -0.02, 0.01), 1.1), 0.088, 0.095, 0.27, 16, Color.WHITE, Rect2(0, 0, 2, 2))
	var face := hk.b("face")
	for i in 3:
		var a0 := (i - 1.5) * 0.45
		var a1 := (i - 0.5) * 0.45
		var p0 := Vector3(sin(a0) * 0.096, 0, -cos(a0) * 0.1)
		var p1 := Vector3(sin(a1) * 0.096, 0, -cos(a1) * 0.1)
		face.quad(Props.at(0, 0.0, 0), [p1, p0, p0 + Vector3(0, 0.23, 0), p1 + Vector3(0, 0.23, 0)],
			[Vector2(1.0 - (i + 1) / 3.0, 1), Vector2(1.0 - i / 3.0, 1), Vector2(1.0 - i / 3.0, 0), Vector2(1.0 - (i + 1) / 3.0, 0)],
			Color.WHITE, false)
	# Hat pulled down to the brows, its turned-up cuff, and the scarf.
	var knit := hk.b("knit")
	knit.cylinder(_oval(Vector3(0, 0.19, 0.005), 1.08), 0.122, 0.09, 0.15, 16, Color.WHITE, Rect2(0, 0, 2, 0.5))
	knit.cylinder(_oval(Vector3(0, 0.18, 0.005), 1.08), 0.128, 0.127, 0.05, 16, Color(1.3, 1.3, 1.3))
	hk.b("knit", Color(1.6, 1.4, 1.3)).cylinder(_oval(Vector3(0, -0.05, -0.005), 1.15), 0.13, 0.12, 0.13, 16)
	hk.build(head)
	return {"root": root, "leg_l": legs[0], "leg_r": legs[1], "arm_l": arms[0], "arm_r": arms[1], "head": head}


## Shared walk cycle: legs and arms swing opposite each other.
static func walk(parts: Dictionary, phase: float, amount: float, swing_right_arm := true) -> void:
	var s := sin(phase) * 0.55 * amount
	(parts.leg_l as Node3D).rotation.x = s
	(parts.leg_r as Node3D).rotation.x = -s
	(parts.arm_l as Node3D).rotation.x = -s * 0.7
	if swing_right_arm:
		(parts.arm_r as Node3D).rotation.x = s * 0.7
