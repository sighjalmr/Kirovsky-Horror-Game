class_name Store
extends Node3D

## Universam «Кировский», vertical-slice layout, built from code.
## Metres; x runs left to right looking in from the street, z runs from the
## glass front doors (z = 0) to the back wall and the storage door (z = 28).
##
##   z 0–6    entrance: left-luggage lockers (left), guard post (right)
##   z 7–10   checkout line: three tills, касса № 2 in the middle
##   z 10–28  hall: four aisles. A (заморозка) and D (молочный) have covered
##            freezer chests, B (бакалея) and C (консервы) are shelves only.

class LightRow:
	var title: String
	var rect: Rect2
	var lights: Array[OmniLight3D] = []
	var tube_mat: ShaderMaterial
	var tube_on: Color
	var hum: AudioStreamPlayer3D
	var center: Vector3
	var lit := true

const H := 3.2  # ceiling height
const TUBE_COLOR := Color(0.79, 0.84, 0.65)
const WARM_COLOR := Color(1.0, 0.78, 0.5)
const CLUE_CHEST := "A3"

## Waypoints for the killer, on the floor plane (x, z).
const NODES := {
	"L": Vector2(-8, 1.6), "E1": Vector2(-5, 4.5), "E2": Vector2(0, 4.5), "E3": Vector2(4.25, 4.5),
	"PD": Vector2(6.3, 2.7), "PI": Vector2(8.6, 2.7),
	"FA1": Vector2(-10.3, 11), "FA2": Vector2(-7.4, 11), "FP1": Vector2(-5, 11), "FB": Vector2(-3, 11),
	"FP2": Vector2(0, 11), "FC": Vector2(3, 11), "FP3": Vector2(4.25, 11), "FD2": Vector2(7.4, 11), "FD1": Vector2(10.3, 11),
	"MA1": Vector2(-10.3, 18.5), "MA2": Vector2(-7.4, 18.5), "MB": Vector2(-3, 18.5),
	"MC": Vector2(3, 18.5), "MD2": Vector2(7.4, 18.5), "MD1": Vector2(10.3, 18.5),
	"BA1": Vector2(-10.3, 26.5), "BA2": Vector2(-7.4, 26.5), "BB": Vector2(-3, 26.5),
	"BC": Vector2(3, 26.5), "BD2": Vector2(7.4, 26.5), "BD1": Vector2(10.3, 26.5),
	"DOOR": Vector2(9.0, 27.3),
}
const EDGES := [
	["L", "E1"], ["E1", "E2"], ["E2", "E3"], ["E3", "PD"], ["PD", "PI"],
	["E1", "FP1"], ["E2", "FP2"], ["E3", "FP3"],
	["FA1", "FA2"], ["FA2", "FP1"], ["FP1", "FB"], ["FB", "FP2"], ["FP2", "FC"], ["FC", "FP3"], ["FP3", "FD2"], ["FD2", "FD1"],
	["FA1", "MA1"], ["MA1", "BA1"], ["FA2", "MA2"], ["MA2", "BA2"], ["FB", "MB"], ["MB", "BB"],
	["FC", "MC"], ["MC", "BC"], ["FD2", "MD2"], ["MD2", "BD2"], ["FD1", "MD1"], ["MD1", "BD1"],
	["BA1", "BA2"], ["BA2", "BB"], ["BB", "BC"], ["BC", "BD2"], ["BD2", "BD1"], ["BD2", "DOOR"], ["BD1", "DOOR"],
]

var rows: Array[LightRow] = []
var interactables: Array[Dictionary] = []
var chests: Dictionary = {}
var astar := AStar3D.new()
var booth_rect := Rect2(7.0, 0.2, 4.8, 4.6)
var duty_rect := Rect2(-2.5, 0.0, 5.0, 2.5)
var phone_pos := Vector3(11.1, 0.9, 1.2)
var killer_spawn := Vector3(9.0, 0, 27.3)

var _patrol_ids: Array[int] = []
var _storage_hinge: Node3D


func _ready() -> void:
	_build_shell()
	_build_entrance()
	_build_booth()
	_build_checkout()
	_build_hall()
	_build_rows()
	_build_waypoints()


# --- building helpers -------------------------------------------------------

func box(pos: Vector3, size: Vector3, tex: String, tint := Color.WHITE, tex_m := 1.0, collide := true,
		faces := MeshFactory.ALL, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshFactory.box(size, tex_m, 0.5, faces)
	mi.extra_cull_margin = 0.5  # flat floor and ceiling pieces need volume for spot light culling
	mi.material_override = Mats.get_mat(tex, tint)
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = size
		shape.shape = b
		shape.position = Vector3(0, size.y * 0.5, 0)
		body.add_child(shape)
		mi.add_child(body)
	return mi


func add_interactable(id: String, pos: Vector3, prompt: String, radius := 1.4, needs_light := true, active := true) -> void:
	interactables.append({"id": id, "pos": pos, "prompt": prompt, "radius": radius, "needs_light": needs_light, "active": active})


func set_interactable(id: String, active: bool, prompt := "") -> void:
	for it in interactables:
		if it.id == id:
			it.active = active
			if prompt != "":
				it.prompt = prompt


# --- layout -------------------------------------------------------------------

func _build_shell() -> void:
	for cx in range(-12, 12, 4):
		for cz in range(0, 28, 4):
			box(Vector3(cx + 2, -0.1, cz + 2), Vector3(4, 0.1, 4), "floor", Color.WHITE, 0.8, false, MeshFactory.PY)
			box(Vector3(cx + 2, H, cz + 2), Vector3(4, 0.1, 4), "ceiling", Color.WHITE, 2.0, false, MeshFactory.NY)
	for cz in range(0, 28, 4):
		box(Vector3(-12.15, 0, cz + 2), Vector3(0.3, H, 4), "wall", Color.WHITE, H, true, MeshFactory.PX)
		box(Vector3(12.15, 0, cz + 2), Vector3(0.3, H, 4), "wall", Color.WHITE, H, true, MeshFactory.NX)
	# Back wall with the storage door gap at x 8.4–9.6.
	for span: Vector2 in [Vector2(-12, -8), Vector2(-8, -4), Vector2(-4, 0), Vector2(0, 4), Vector2(4, 8.4), Vector2(9.6, 12)]:
		box(Vector3((span.x + span.y) * 0.5, 0, 28.15), Vector3(span.y - span.x, H, 0.3), "wall", Color.WHITE, H, true, MeshFactory.NZ)
	box(Vector3(9.0, 2.2, 28.15), Vector3(1.2, H - 2.2, 0.3), "wall", Color.WHITE, H, true, MeshFactory.NZ)
	box(Vector3(9.0, 0, 30.5), Vector3(3, H, 1), "fabric", Color(0.02, 0.02, 0.02), 1.0, false, MeshFactory.NZ)
	_storage_hinge = Node3D.new()
	_storage_hinge.position = Vector3(8.4, 0, 28.0)
	add_child(_storage_hinge)
	box(Vector3(0.6, 0, 0), Vector3(1.2, 2.2, 0.06), "door", Color.WHITE, 2.2, true, MeshFactory.ALL, _storage_hinge)
	# Front wall with the glass doors at x -2..2.
	for span: Vector2 in [Vector2(-12, -8), Vector2(-8, -4), Vector2(-4, -2), Vector2(2, 4), Vector2(4, 8), Vector2(8, 12)]:
		box(Vector3((span.x + span.y) * 0.5, 0, -0.15), Vector3(span.y - span.x, H, 0.3), "wall", Color.WHITE, H, true, MeshFactory.PZ)
	box(Vector3(0, 2.4, -0.15), Vector3(4, H - 2.4, 0.3), "wall", Color.WHITE, H, true, MeshFactory.PZ)
	for x: float in [-1.0, 1.0]:
		box(Vector3(x, 0, -0.03), Vector3(1.95, 2.4, 0.06), "glass", Color.WHITE, 2.4, true, MeshFactory.PZ)
	for x: float in [-2.0, 0.0, 2.0]:
		box(Vector3(x, 0, 0.0), Vector3(0.08, 2.4, 0.12), "metal", Color.WHITE)
	box(Vector3(0, 2.5, 0.05), Vector3(0.6, 0.18, 0.05), "fabric", Color.WHITE, 1.0, false, MeshFactory.ALL).material_override = \
		Mats.get_mat("fabric", Color(0.3, 0.5, 0.3), Color(0.25, 0.6, 0.3))
	add_interactable("door_front", Vector3(0, 0, 0.4), "Подёргать дверь", 1.6, false)
	# Posters.
	box(Vector3(-6, 1.2, 27.98), Vector3(1.2, 1.6, 0.02), "poster", Color.WHITE, 1.6, false, MeshFactory.NZ)
	box(Vector3(-11.98, 1.3, 9.0), Vector3(0.02, 1.4, 1.0), "poster", Color(0.9, 1.0, 0.9), 1.4, false, MeshFactory.PX)


func _build_entrance() -> void:
	# Left-luggage lockers: 12 columns × 4 rows, numbered left to right, top down.
	box(Vector3(-8, 0, 0.3), Vector3(6, 2.0, 0.5), "locker", Color.WHITE, 2.0)
	box(Vector3(-8, 2.0, 0.3), Vector3(6.1, 0.08, 0.55), "metal", Color.WHITE)
	# Locker № 31 (row 3, column 7) stands ajar.
	var hinge := Node3D.new()
	hinge.position = Vector3(-8.0, 0.52, 0.57)
	hinge.rotation.y = deg_to_rad(-35)
	add_child(hinge)
	box(Vector3(0.24, 0, 0), Vector3(0.47, 0.47, 0.03), "metal", Color(0.9, 1.0, 0.95), 0.5, false, MeshFactory.ALL, hinge)
	add_interactable("locker31", Vector3(-7.75, 0, 0.75), "Осмотреть ячейку № 31", 1.4)
	box(Vector3(0, -0.02, 1.0), Vector3(3, 0.02, 1.4), "fabric", Color(0.15, 0.12, 0.1), 1.0, false)
	for i in 4:
		box(Vector3(-3.2, i * 0.18, 1.2), Vector3(0.5, 0.18, 0.4), "metal", Color(0.7, 0.3, 0.25))


func _build_booth() -> void:
	var r := booth_rect
	var low := Color(0.85, 0.8, 0.7)
	# Hall-facing wall with a window above, left wall with the door gap.
	box(Vector3(r.position.x + r.size.x * 0.5, 0, r.end.y), Vector3(r.size.x, 1.1, 0.1), "wood", low, 1.0)
	box(Vector3(r.position.x + r.size.x * 0.5, 2.2, r.end.y), Vector3(r.size.x, 0.1, 0.1), "wood", low, 1.0, false)
	box(Vector3(r.position.x, 0, 1.2), Vector3(0.1, 1.1, 2.0), "wood", low, 1.0)
	box(Vector3(r.position.x, 0, 4.0), Vector3(0.1, 1.1, 1.6), "wood", low, 1.0)
	box(Vector3(r.position.x, 2.2, 2.5), Vector3(0.1, 0.1, 4.6), "wood", low, 1.0, false)
	for p: Vector2 in [Vector2(7.0, 4.8), Vector2(11.8, 4.8), Vector2(7.0, 0.2), Vector2(7.0, 2.2), Vector2(7.0, 3.2)]:
		box(Vector3(p.x, 0, p.y), Vector3(0.1, 2.3, 0.1), "wood", low, 1.0, false)
	# Desk, chair, phone, radio, logbook, lamp.
	box(Vector3(11.15, 0, 2.1), Vector3(1.1, 0.78, 2.6), "wood", Color.WHITE)
	box(Vector3(10.2, 0, 2.2), Vector3(0.45, 0.45, 0.45), "wood", Color(0.7, 0.6, 0.5), 1.0, false)
	box(Vector3(10.0, 0.45, 2.2), Vector3(0.05, 0.5, 0.45), "wood", Color(0.7, 0.6, 0.5), 1.0, false)
	box(Vector3(11.1, 0.78, 1.2), Vector3(0.22, 0.1, 0.18), "fabric", Color(0.35, 0.08, 0.06), 1.0, false)
	box(Vector3(11.1, 0.88, 1.2), Vector3(0.26, 0.05, 0.07), "fabric", Color(0.3, 0.07, 0.05), 1.0, false)
	box(Vector3(11.3, 0.78, 2.2), Vector3(0.35, 0.2, 0.18), "wood", Color(0.8, 0.6, 0.45), 1.0, false)
	box(Vector3(10.9, 0.78, 2.6), Vector3(0.3, 0.03, 0.22), "fabric", Color(0.25, 0.3, 0.45), 1.0, false)
	box(Vector3(11.3, 0.78, 3.0), Vector3(0.1, 0.4, 0.1), "metal", Color.WHITE, 1.0, false)
	box(Vector3(11.3, 1.15, 3.0), Vector3(0.26, 0.14, 0.26), "metal", Color(0.3, 0.45, 0.3), 1.0, false).material_override = \
		Mats.get_mat("metal", Color(0.3, 0.45, 0.3), Color(0.4, 0.3, 0.15))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(11.0, 1.3, 2.8)
	lamp.omni_range = 4.5
	lamp.light_energy = 1.3
	lamp.light_color = WARM_COLOR
	lamp.light_specular = 0.0
	add_child(lamp)
	add_interactable("phone", Vector3(11.1, 0, 1.2), "Снять трубку", 1.3, false, false)
	add_interactable("journal", Vector3(10.9, 0, 2.6), "Журнал обходов", 1.3, false)


func _build_checkout() -> void:
	var names := ["register1", "register2", "register3"]
	var xs := [-7.5, -2.5, 2.5]
	for i in 3:
		var x: float = xs[i]
		box(Vector3(x, 0, 8.25), Vector3(1.0, 0.9, 2.5), "wood", Color.WHITE)
		box(Vector3(x + 0.2, 0.9, 8.0), Vector3(0.45, 0.32, 0.4), "metal", Color(0.55, 0.55, 0.5), 1.0, false)
		box(Vector3(x + 0.2, 1.22, 7.9), Vector3(0.3, 0.12, 0.12), "metal", Color(0.4, 0.4, 0.4), 1.0, false)
		add_interactable(names[i], Vector3(x + 0.9, 0, 8.0), "Осмотреть кассу № %d" % (i + 1), 1.3)
	box(Vector3(-10, 0, 8.25), Vector3(4, 1.0, 0.08), "metal", Color.WHITE)
	box(Vector3(8.75, 0, 8.25), Vector3(6.5, 1.0, 0.08), "metal", Color.WHITE)


func _build_hall() -> void:
	# Three gondolas and two wall shelves, cut into segments for vertex light.
	for x: float in [-6.0, 0.0, 6.0]:
		for k in 4:
			box(Vector3(x, 0, 12.0 + k * 3.25 + 1.625), Vector3(1.0, 1.9, 3.25), "shelf", Color.WHITE, 1.9)
	for x: float in [-11.6, 11.6]:
		for k in 4:
			box(Vector3(x, 0, 12.0 + k * 3.25 + 1.625), Vector3(0.8, 2.2, 3.25), "shelf", Color(0.9, 0.95, 0.9), 2.2)
	# Pyramids: three-litre juice jars in бакалея, tins in консервы.
	for i in 3:
		var s := 1.0 - i * 0.3
		box(Vector3(-1.6, i * 0.35, 16.0), Vector3(s, 0.35, s), "frozen", Color(1.6, 0.7, 0.4), 0.4, i == 0)
		box(Vector3(1.6, i * 0.3, 20.0), Vector3(s, 0.3, s), "shelf", Color(0.9, 1.1, 0.8), 0.6, i == 0)
	# Boxes by the back wall.
	box(Vector3(-3.5, 0, 27.3), Vector3(1.2, 0.8, 0.8), "cardboard", Color.WHITE)
	box(Vector3(-3.4, 0.8, 27.3), Vector3(0.8, 0.6, 0.7), "cardboard", Color(0.9, 0.9, 0.9), 1.0, false)
	box(Vector3(2.0, 0, 27.4), Vector3(0.8, 0.6, 0.7), "cardboard", Color.WHITE)
	# Freezer chests under cloths: aisle A (x -8.85) and aisle D (x 8.85).
	for side in [["A", -8.85], ["D", 8.85]]:
		for k in 4:
			var id := "%s%d" % [side[0], k + 1]
			_build_chest(id, Vector3(side[1], 0, 14.0 + k * 2.8))


func _build_chest(id: String, pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	box(Vector3.ZERO, Vector3(1.0, 0.8, 2.4), "enamel", Color.WHITE, 0.8, true, MeshFactory.ALL, root)
	box(Vector3(0, 0.8, 0), Vector3(0.96, 0.02, 2.36), "frozen", Color.WHITE, 0.6, false, MeshFactory.PY, root)
	var cloth := Node3D.new()
	root.add_child(cloth)
	box(Vector3(0, 0.81, 0), Vector3(1.08, 0.04, 2.48), "cloth", Color.WHITE, 1.0, false, MeshFactory.ALL, cloth)
	for sx: float in [-0.55, 0.55]:
		box(Vector3(sx, 0.35, 0), Vector3(0.02, 0.48, 2.48), "cloth", Color(0.9, 0.9, 0.9), 1.0, false, MeshFactory.ALL, cloth)
	var folded := box(Vector3(0, 0.8, 1.0), Vector3(0.9, 0.14, 0.36), "cloth", Color.WHITE, 0.5, false, MeshFactory.ALL, root)
	folded.visible = false
	var hum := AudioStreamPlayer3D.new()
	hum.stream = Sfx.get_stream("compressor")
	hum.volume_db = -14.0
	hum.max_distance = 9.0
	hum.unit_size = 2.0
	hum.pitch_scale = randf_range(0.9, 1.1)
	hum.autoplay = true
	root.add_child(hum)
	hum.position = Vector3(0, 0.3, 0)
	chests[id] = {"cloth": cloth, "folded": folded, "lifted": false, "hum": hum, "pos": pos}
	add_interactable("chest_" + id, pos, "Поднять покрывало", 1.8)


func _build_rows() -> void:
	var lamp_z := [13.5, 17.0, 20.5, 24.0]
	var hall := [
		["Бакалея", Rect2(-5.5, 12, 5.0, 13), -3.0],
		["Консервы", Rect2(0.5, 12, 5.0, 13), 3.0],
		["Молочный", Rect2(6.5, 12, 4.7, 13), 8.85],
		["Заморозка", Rect2(-11.2, 12, 4.7, 13), -8.85],
	]
	for h in hall:
		var pts: Array[Vector3] = []
		for z: float in lamp_z:
			pts.append(Vector3(h[2], 0, z))
		_add_row(h[0], h[1], pts, TUBE_COLOR)
	_add_row("Задний проход", Rect2(-12, 25, 24, 3),
		[Vector3(-8, 0, 26.5), Vector3(0, 0, 26.5), Vector3(8, 0, 26.5)], TUBE_COLOR)
	_add_row("Касса и вход", Rect2(-12, 0, 24, 12),
		[Vector3(-7.5, 0, 9.0), Vector3(-2.5, 0, 9.0), Vector3(3.5, 0, 9.0), Vector3(-6, 0, 3), Vector3(1.5, 0, 3)], TUBE_COLOR)
	# Duty light over the exit stays on all night.
	var duty := OmniLight3D.new()
	duty.position = Vector3(0, 2.5, 0.7)
	duty.omni_range = 4.0
	duty.light_energy = 0.6
	duty.light_color = Color(0.75, 0.9, 0.75)
	duty.light_specular = 0.0
	add_child(duty)


func _add_row(title: String, rect: Rect2, points: Array[Vector3], color: Color) -> void:
	var row := LightRow.new()
	row.title = title
	row.rect = rect
	row.tube_on = color
	row.tube_mat = Mats.unique("white", Color(0.8, 0.8, 0.8), color)
	var c := Vector3.ZERO
	for p in points:
		box(Vector3(p.x, H - 0.1, p.z), Vector3(0.3, 0.06, 1.3), "metal", Color.WHITE, 1.0, false)
		var tube := MeshInstance3D.new()
		tube.mesh = MeshFactory.box(Vector3(0.12, 0.04, 1.2), 1.0, 0.5)
		tube.material_override = row.tube_mat
		tube.position = Vector3(p.x, H - 0.14, p.z)
		add_child(tube)
		var l := OmniLight3D.new()
		l.position = Vector3(p.x, H - 0.35, p.z)
		l.omni_range = 6.5
		l.light_energy = 1.0
		l.light_color = color
		l.light_specular = 0.0
		add_child(l)
		row.lights.append(l)
		c += p
	row.center = c / points.size() + Vector3(0, H - 0.3, 0)
	row.hum = AudioStreamPlayer3D.new()
	row.hum.stream = Sfx.get_stream("hum")
	row.hum.volume_db = -16.0
	row.hum.max_distance = 14.0
	row.hum.autoplay = true
	add_child(row.hum)
	row.hum.position = row.center
	rows.append(row)


func _build_waypoints() -> void:
	var ids := {}
	var next := 0
	for key: String in NODES:
		var p: Vector2 = NODES[key]
		astar.add_point(next, Vector3(p.x, 0, p.y))
		ids[key] = next
		if key != "PI" and key != "DOOR":
			_patrol_ids.append(next)
		next += 1
	for e in EDGES:
		astar.connect_points(ids[e[0]], ids[e[1]])


# --- runtime ------------------------------------------------------------------

func is_lit(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	if booth_rect.has_point(p) or duty_rect.has_point(p):
		return true
	for row in rows:
		if row.lit and row.rect.has_point(p):
			return true
	return false


func lit_fraction() -> float:
	var n := 0
	for row in rows:
		if row.lit:
			n += 1
	return float(n) / rows.size()


## The row clicks, flickers three times and goes dark; the hum stops.
func switch_off(i: int) -> void:
	var row := rows[i]
	if not row.lit:
		return
	row.lit = false
	Sfx.play_3d(self, "click", row.center, -2.0)
	var tw := create_tween()
	for k in 3:
		tw.tween_callback(_set_row_light.bind(row, false))
		tw.tween_interval(0.05 + 0.05 * k)
		tw.tween_callback(_set_row_light.bind(row, true))
		tw.tween_interval(0.12)
	tw.tween_callback(_set_row_light.bind(row, false))
	tw.tween_callback(row.hum.stop)


func _set_row_light(row: LightRow, on: bool) -> void:
	for l in row.lights:
		l.visible = on
	row.tube_mat.set_shader_parameter("emission", row.tube_on if on else Color(0.02, 0.02, 0.02))


func open_storage_door() -> void:
	Sfx.play_3d(self, "clank", Vector3(9, 1.2, 27.8), 2.0, 0.8)
	create_tween().tween_property(_storage_hinge, "rotation:y", deg_to_rad(-100), 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func lift_cloth(id: String) -> void:
	var c: Dictionary = chests[id]
	c.lifted = true
	(c.cloth as Node3D).visible = false
	(c.folded as Node3D).visible = true
	if id == CLUE_CHEST:
		box(c.pos + Vector3(0.1, 0.83, -0.4), Vector3(0.5, 0.01, 0.9), "blood", Color(0.9, 0.7, 0.7), 0.5, false)
		box(c.pos + Vector3(-0.2, 0.84, 0.2), Vector3(0.08, 0.03, 0.05), "metal", Color(0.9, 0.3, 0.4), 1.0, false)


## "If a compressor goes quiet, somebody is standing next to it."
func update_compressors(killer_pos: Vector3, delta: float) -> void:
	for id: String in chests:
		var c: Dictionary = chests[id]
		var near := (c.pos as Vector3).distance_to(killer_pos) < 4.5
		var hum: AudioStreamPlayer3D = c.hum
		hum.volume_db = move_toward(hum.volume_db, -60.0 if near else -14.0, delta * 40.0)


func spawn_blood(pos: Vector3, size: float) -> MeshInstance3D:
	var b := box(Vector3(pos.x, 0.005, pos.z), Vector3(size, 0.01, size), "blood", Color.WHITE, 0.6, false)
	b.rotation.y = randf() * TAU
	return b


func random_patrol_point() -> Vector3:
	return astar.get_point_position(_patrol_ids[randi() % _patrol_ids.size()])


## Nearest waypoint that can be walked to in a straight line.
func closest_node(pos: Vector3) -> int:
	var best := -1
	var best_d := INF
	var flat := Vector3(pos.x, 0, pos.z)
	for id in astar.get_point_ids():
		var p := astar.get_point_position(id)
		var d := p.distance_squared_to(flat)
		if d < best_d and walkable(flat, p):
			best = id
			best_d = d
	if best == -1:
		best = astar.get_closest_point(flat)
	return best


## Knee-height ray: true when nothing solid stands between two floor points.
func walkable(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(Vector3(a.x, 0.5, a.z), Vector3(b.x, 0.5, b.z), 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func find_interactable(p: Player) -> Dictionary:
	var best := {}
	var best_d := INF
	var pos := p.global_position
	var fwd := -p.global_transform.basis.z
	for it in interactables:
		if not it.active:
			continue
		var to: Vector3 = it.pos - pos
		to.y = 0.0
		var d := to.length()
		if d > it.radius:
			continue
		if d > 0.6 and fwd.dot(to / d) < 0.25:
			continue
		if d < best_d:
			best = it
			best_d = d
	return best
