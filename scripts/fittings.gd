class_name Fittings
extends RefCounted

## The building around the furniture: glazed tiles and skirting along the
## walls, square concrete columns, the air ducts under the ceiling, cast-iron
## radiators, the fire board, the customers' notice board, a fallen ceiling
## tile, the street lamp outside the shop window. Like Props, each piece
## merges its parts into one mesh per material.

const NO_RECT := Props.NO_RECT
const FULL := Props.FULL
const ALL := MeshFactory.ALL

## One repeat of the wall-tile texture (4 × 4 tiles): a tile is 1/7 m, so a
## 4 m wall section holds a whole number of them.
const TILE_M := 4.0 / 7.0
const WAINSCOT := 10.0 / 7.0  # ten rows of tiles, 1.43 m
const SKIRT := 0.1
const CAP_COLOR := Color(0.32, 0.4, 0.36)
const SKIRT_COLOR := Color(0.3, 0.2, 0.14)
const RAD_COLOR := Color(0.82, 0.8, 0.72)


## Tiles, skirting and the capping strip on a wall face. `a` and `b` are the
## ends of the run on the floor, along the face; `normal` points into the room.
static func wall_run(parent: Node3D, a: Vector3, b: Vector3, normal: Vector3) -> void:
	var x := Vector3.UP.cross(normal)  # right-handed frame: x along, y up, z out of the wall
	if (b - a).dot(x) < 0.0:
		var t := a
		a = b
		b = t
	var length := a.distance_to(b)
	# Sections of 8 tiles keep each mesh small enough for its lights.
	var step := TILE_M * 2.0 * 4.0
	var s := 0.0
	while s < length - 0.01:
		var l := minf(step, length - s)
		var kit := MeshBuilder.Kit.new()
		var xf := Transform3D(Basis(x, Vector3.UP, normal), a + x * s)
		var c := l * 0.5
		kit.b("paint", SKIRT_COLOR).box(xf * at(c, 0, 0.012), Vector3(l, SKIRT, 0.024), Color.WHITE, NO_RECT,
			Vector2(0.6, 0.6), MeshFactory.PZ | MeshFactory.PY)
		kit.b("kafel").box(xf * at(c, SKIRT, 0.0075), Vector3(l, WAINSCOT - SKIRT, 0.015), Color.WHITE, NO_RECT,
			Vector2(TILE_M, TILE_M), MeshFactory.PZ | MeshFactory.PY)
		kit.b("paint", CAP_COLOR).box(xf * at(c, WAINSCOT, 0.016), Vector3(l, 0.03, 0.032), Color.WHITE, NO_RECT,
			Vector2(0.6, 0.6), MeshFactory.PZ | MeshFactory.PY | MeshFactory.NY)
		kit.build(parent, false)
		s += l


## A square concrete column, floor to ceiling, with tiles round the bottom
## like the walls. Solid.
static func column(parent: Node3D, pos: Vector3, h: float, size := 0.5) -> void:
	var kit := MeshBuilder.Kit.new()
	var hs := size * 0.5
	kit.b("concrete").box(at(pos.x, 0, pos.z), Vector3(size, h, size), Color.WHITE, NO_RECT, Vector2(1.2, 1.2),
		Props.SIDES)
	kit.b("kafel").box(at(pos.x, SKIRT, pos.z), Vector3(size + 0.03, WAINSCOT - SKIRT, size + 0.03), Color.WHITE,
		NO_RECT, Vector2(TILE_M, TILE_M), Props.SIDES | MeshFactory.PY)
	kit.b("paint", SKIRT_COLOR).box(at(pos.x, 0, pos.z), Vector3(size + 0.05, SKIRT, size + 0.05), Color.WHITE,
		NO_RECT, Vector2(0.6, 0.6), Props.SIDES | MeshFactory.PY)
	kit.b("paint", CAP_COLOR).box(at(pos.x, WAINSCOT, pos.z), Vector3(size + 0.06, 0.03, size + 0.06), Color.WHITE,
		NO_RECT, Vector2(0.6, 0.6), ALL)
	# Chamfered corner guards of angle iron, rubbed bright by trolleys.
	for o: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		kit.b("metal", Color(0.6, 0.6, 0.6)).box(at(pos.x + o.x * (hs + 0.018), SKIRT, pos.z + o.y * (hs + 0.018)),
			Vector3(0.012, WAINSCOT - SKIRT, 0.012))
	kit.build(parent)
	Props.collider(parent, pos, Vector3(size + 0.06, h, size + 0.06))


## Rectangular galvanised air duct along z under the ceiling, from z0 to z1 at
## x: flanged joints every 1.5 m, hangers, a grille every 4 m underneath.
static func duct(parent: Node3D, x: float, z0: float, z1: float, ceiling: float) -> void:
	var kit := MeshBuilder.Kit.new()
	var w := 0.5
	var hgt := 0.3
	var y := ceiling - 0.12 - hgt
	var g := kit.b("galv")
	var span := z1 - z0
	g.box(at(x, y, (z0 + z1) * 0.5), Vector3(w, hgt, span), Color.WHITE, NO_RECT, Vector2(1.0, 1.0),
		ALL & ~MeshFactory.PY)
	var z := z0 + 0.75
	while z < z1 - 0.2:
		g.box(at(x, y - 0.015, z), Vector3(w + 0.04, hgt + 0.03, 0.03), Color(0.85, 0.85, 0.85))
		var rod := kit.b("metal", Color(0.5, 0.5, 0.5))
		for sx: float in [-w * 0.5 - 0.04, w * 0.5 + 0.04]:
			rod.box(at(x + sx, y - 0.03, z + 0.1), Vector3(0.01, ceiling - y + 0.03, 0.01))
		rod.box(at(x, y - 0.035, z + 0.1), Vector3(w + 0.1, 0.02, 0.03))
		z += 1.5
	var gz := z0 + 2.0
	while gz < z1 - 0.5:
		kit.b("grille").box(at(x, y - 0.006, gz), Vector3(0.36, 0.006, 0.36), Color(0.8, 0.8, 0.8), FULL,
			Vector2.ONE, MeshFactory.NY)
		kit.b("paint", Color(0.8, 0.8, 0.78)).box(at(x, y - 0.012, gz), Vector3(0.42, 0.012, 0.42), Color.WHITE,
			NO_RECT, Vector2.ONE, Props.SIDES)
		gz += 4.0
	kit.build(parent, false)


## A cross duct along x joining the long ones.
static func duct_x(parent: Node3D, z: float, x0: float, x1: float, ceiling: float) -> void:
	var kit := MeshBuilder.Kit.new()
	var y := ceiling - 0.12 - 0.3
	kit.b("galv").box(rot(Vector3.UP, PI * 0.5, Vector3((x0 + x1) * 0.5, y, z)), Vector3(0.5, 0.3, x1 - x0),
		Color.WHITE, NO_RECT, Vector2(1.0, 1.0), ALL & ~MeshFactory.PY)
	kit.build(parent, false)


## Cast-iron sectional radiator under its two pipes, against a wall.
## `normal` points into the room; `pos` is on the wall face at floor level.
static func radiator(parent: Node3D, pos: Vector3, normal: Vector3, sections := 10) -> void:
	var x := Vector3.UP.cross(normal)
	var xf := Transform3D(Basis(x, Vector3.UP, normal), pos)
	var kit := MeshBuilder.Kit.new()
	var cast := kit.b("paint", RAD_COLOR)
	var pitch := 0.09
	var w := sections * pitch
	for i in sections:
		var cx := -w * 0.5 + pitch * (i + 0.5)
		cast.box(xf * at(cx, 0.17, 0.12), Vector3(0.065, 0.5, 0.12))
		cast.box(xf * at(cx, 0.24, 0.12), Vector3(0.075, 0.36, 0.16))
	for yy: float in [0.2, 0.62]:
		cast.cylinder(xf * rot(Vector3.BACK, PI * 0.5, Vector3(-w * 0.5 - 0.02, yy, 0.12)), 0.03, 0.03, w + 0.04, 8)
	# Feed and return pipes: up from the floor at each end, then in to the hubs.
	var pipe := kit.b("paint", RAD_COLOR * Color(0.92, 0.92, 0.92))
	for side: float in [-1.0, 1.0]:
		var px := side * (w * 0.5 + 0.1)
		var hub := 0.62 if side < 0.0 else 0.2
		pipe.cylinder(xf * at(px, 0.0, 0.12), 0.016, 0.016, hub, 8)
		pipe.cylinder(xf * rot(Vector3.BACK, -PI * 0.5 * side, Vector3(px, hub, 0.12)), 0.016, 0.016, 0.1, 8)
	kit.build(parent)
	var foot := Vector3(w + 0.3, 0.7, 0.26)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = foot
	shape.shape = b
	shape.transform = Transform3D(xf.basis, xf * Vector3(0, foot.y * 0.5, 0.13))
	body.add_child(shape)
	parent.add_child(body)


## The fire board: red panel with an axe, a crowbar, a hook, a conical bucket
## and a shovel, two extinguishers on hooks beside it.
static func fire_board(parent: Node3D, pos: Vector3, normal: Vector3) -> void:
	var x := Vector3.UP.cross(normal)
	var xf := Transform3D(Basis(x, Vector3.UP, normal), pos)
	var kit := MeshBuilder.Kit.new()
	kit.b("fire_board").box(xf * at(0, 0.6, 0.012), Vector3(1.2, 1.2, 0.024), Color.WHITE, FULL, Vector2.ONE,
		MeshFactory.PZ)
	kit.b("paint", Color(0.5, 0.08, 0.06)).box(xf * at(0, 0.6, 0.012), Vector3(1.2, 1.2, 0.024), Color.WHITE,
		NO_RECT, Vector2.ONE, Props.SIDES & ~MeshFactory.PZ | MeshFactory.PY)
	var red := kit.b("paint", Color(0.85, 0.12, 0.08))
	var wood := kit.b("wood", Color(0.8, 0.6, 0.4))
	var steel := kit.b("metal", Color(0.45, 0.45, 0.45))
	# Hook (багор) and crowbar on the left outline.
	red.box(xf * at(-0.42, 0.72, 0.05), Vector3(0.03, 0.95, 0.03))
	steel.box(xf * rot(Vector3.BACK, 0.6, Vector3(-0.42, 1.66, 0.05)), Vector3(0.015, 0.1, 0.015))
	steel.box(xf * at(-0.33, 0.75, 0.045), Vector3(0.02, 0.8, 0.02))
	# Axe.
	wood.box(xf * at(0.4, 1.0, 0.05), Vector3(0.03, 0.45, 0.025))
	red.box(xf * at(0.4, 1.38, 0.05), Vector3(0.16, 0.08, 0.012))
	# Conical bucket hanging bottom up, and a shovel.
	red.cylinder(xf * rot(Vector3.RIGHT, PI, Vector3(-0.02, 1.25, 0.15)), 0.17, 0.02, 0.32, 12, Color.WHITE,
		Props.FULL, NO_RECT, true, true)
	wood.box(xf * at(0.12, 0.14, 0.05), Vector3(0.03, 0.75, 0.025))
	red.box(xf * at(0.12, 0.88, 0.05), Vector3(0.2, 0.26, 0.012))
	# Two ОХП-10 extinguishers on brackets to the right.
	for k in 2:
		var ex := Vector3(0.85 + k * 0.28, 0.75, 0.1)
		red.cylinder(xf * at(ex.x, ex.y, ex.z), 0.075, 0.075, 0.5, 12, Color.WHITE, Props.FULL, NO_RECT, true, true)
		red.cylinder(xf * at(ex.x, ex.y + 0.5, ex.z), 0.075, 0.03, 0.06, 12)
		steel.cylinder(xf * at(ex.x, ex.y + 0.56, ex.z), 0.02, 0.02, 0.07, 6)
		kit.b("rubber").box(xf * rot(Vector3.BACK, 0.4, Vector3(ex.x + 0.06, ex.y + 0.2, ex.z + 0.05)),
			Vector3(0.015, 0.4, 0.015))
		steel.box(xf * at(ex.x, ex.y + 0.3, 0.02), Vector3(0.1, 0.03, 0.06))
	kit.build(parent)


## «Уголок покупателя»: a varnished notice board with a little shelf.
static func notice_board(parent: Node3D, pos: Vector3, normal: Vector3) -> void:
	var x := Vector3.UP.cross(normal)
	var xf := Transform3D(Basis(x, Vector3.UP, normal), pos)
	var kit := MeshBuilder.Kit.new()
	kit.b("notice").box(xf * at(0, 1.45, 0.015), Vector3(1.2, 0.9, 0.03), Color.WHITE, FULL, Vector2.ONE,
		MeshFactory.PZ)
	var wood := kit.b("wood", Color(0.55, 0.38, 0.25))
	wood.box(xf * at(0, 1.45, 0.015), Vector3(1.2, 0.9, 0.03), Color.WHITE, NO_RECT, Vector2.ONE,
		Props.SIDES & ~MeshFactory.PZ | MeshFactory.PY | MeshFactory.NY)
	wood.box(xf * at(0, 1.43, 0.07), Vector3(1.0, 0.02, 0.14))
	# The complaints book, tied to the board on a string.
	kit.b("white", Color(0.3, 0.12, 0.1)).box(xf * at(0.25, 1.45, 0.07), Vector3(0.22, 0.025, 0.15))
	kit.b("white", Color(0.85, 0.82, 0.7)).box(xf * at(0.25, 1.45, 0.07), Vector3(0.21, 0.02, 0.145))
	kit.b("white", Color(0.1, 0.1, 0.1)).box(xf * rot(Vector3.FORWARD, 0.3, Vector3(0.18, 1.47, 0.04)),
		Vector3(0.003, 0.2, 0.003))
	kit.build(parent)


## A ceiling tile that dropped out of its grid and hangs by one corner: a
## black hole into the void above, with a pipe and dust.
static func fallen_tile(parent: Node3D, pos: Vector3, ceiling: float) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.b("white", Color(0.01, 0.01, 0.01)).box(at(pos.x, ceiling - 0.004, pos.z), Vector3(0.6, 0.004, 0.6),
		Color.WHITE, NO_RECT, Vector2.ONE, MeshFactory.NY)
	kit.b("ceiling").box(rot(Vector3.RIGHT, 0.9, Vector3(pos.x, ceiling - 0.62, pos.z + 0.3)), Vector3(0.59, 0.015, 0.59),
		Color(0.95, 0.95, 0.95), Rect2(0.02, 0.02, 0.46, 0.46), Vector2.ONE, ALL)
	kit.b("paint", Color(0.3, 0.3, 0.28)).cylinder(rot(Vector3.RIGHT, PI * 0.5, Vector3(pos.x + 0.12, ceiling + 0.1,
		pos.z - 0.4)), 0.05, 0.05, 0.8, 8)
	kit.build(parent, false)


## Sodium street lamp on a concrete pole outside the shop window.
static func street_lamp(parent: Node3D, pos: Vector3, aim: Vector3) -> SpotLight3D:
	var kit := MeshBuilder.Kit.new()
	kit.b("concrete", Color(0.6, 0.6, 0.6)).cylinder(at(pos.x, 0, pos.z), 0.12, 0.08, 6.5, 8)
	var arm := kit.b("metal", Color(0.35, 0.35, 0.35))
	arm.box(rot(Vector3.RIGHT, 1.35, Vector3(pos.x, 6.3, pos.z)), Vector3(0.05, 1.2, 0.05))
	kit.b("white", Color.WHITE, Color(2.4, 1.3, 0.45)).box(at(pos.x, 6.38, pos.z + 1.15), Vector3(0.2, 0.06, 0.4))
	arm.box(at(pos.x, 6.44, pos.z + 1.15), Vector3(0.28, 0.08, 0.5))
	kit.build(parent, false)
	var l := SpotLight3D.new()
	l.position = Vector3(pos.x, 6.3, pos.z + 1.15)
	parent.add_child(l)
	l.look_at(aim)
	l.spot_range = 16.0
	l.spot_angle = 38.0
	l.spot_attenuation = 1.2
	l.light_energy = 6.0
	l.light_color = Color(1.0, 0.62, 0.28)
	l.shadow_enabled = true
	return l


static func at(x: float, y: float, z: float) -> Transform3D:
	return Props.at(x, y, z)


static func rot(axis: Vector3, angle: float, pos: Vector3) -> Transform3D:
	return Props.rot(axis, angle, pos)
