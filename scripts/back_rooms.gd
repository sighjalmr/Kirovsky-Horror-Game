class_name BackRooms
extends Node3D

## What lies behind the back wall, built for night three only: the
## director's office (behind the door at Store.OFFICE_X) and the cellar under
## the storage room (down the stairs behind Store.CELLAR_X), with the old
## refrigerated cabinet that has not worked since August. Also the telephone
## wire that runs from the guard's phone along the walls to the office:
## the two phones are on one line.
##
##   office   x 0.15–4.65, z 28.3–31.65, on the hall floor
##   stairs   x CELLAR_X ± 0.5, z 28.45–31.45, down to FLOOR
##   cellar   x -5.4–0.9, z 31.6–36.8, floor at FLOOR, ceiling at CEIL

const FLOOR := -2.6
const CEIL := -0.35
const STAIR_Z0 := 28.45
const STAIR_Z1 := 31.45
const STEPS := 14
const CELLAR := Rect2(-5.4, 31.6, 6.3, 5.2)
const OFFICE := Rect2(0.15, 28.3, 4.5, 3.35)
## The cabinet against the cellar's back wall, its doors facing the stairs.
const FRIDGE := Vector3(-2.0, FLOOR, 36.35)
## The office phone, its handset lying off the cradle on the desk.
const HANDSET := Vector3(2.62, 0.77, 30.28)
const DESK := Vector3(2.4, 0, 30.55)
## Where the wire runs along the walls, from the post to the office: [a, b] pieces.
const WIRE := [
	[Vector3(11.1, 0.8, 1.32), Vector3(11.94, 0.8, 1.32)],
	[Vector3(11.94, 0.8, 1.32), Vector3(11.94, 2.6, 1.32)],
	[Vector3(11.94, 2.6, 1.32), Vector3(11.94, 2.6, 27.94)],
	[Vector3(11.94, 2.6, 27.94), Vector3(Store.OFFICE_X + 0.62, 2.6, 27.94)],
	[Vector3(Store.OFFICE_X + 0.62, 2.6, 27.94), Vector3(Store.OFFICE_X + 0.62, 2.25, 27.94)],
]

var store: Store
var fridge_open := false
var _fridge_doors: Array[Node3D] = []
var _bulb: OmniLight3D
var _lock_on_floor: Node3D


static func floor_y(p: Vector3) -> float:
	if absf(p.x - Store.CELLAR_X) < 0.65 and p.z < CELLAR.position.y:
		return FLOOR * clampf((p.z - STAIR_Z0) / (STAIR_Z1 - STAIR_Z0), 0.0, 1.0)
	if CELLAR.grow(0.3).has_point(Vector2(p.x, p.z)):
		return FLOOR
	return 0.0


static func in_cellar(p: Vector3) -> bool:
	return p.y < -0.5


static func in_office(p: Vector3) -> bool:
	return OFFICE.has_point(Vector2(p.x, p.z))


func _init(s: Store) -> void:
	store = s


func _ready() -> void:
	_build_wire()
	_build_office()
	_build_stairs()
	_build_cellar()
	_build_fridge()
	_build_ways()


func _box(pos: Vector3, size: Vector3, tex: String, tint := Color.WHITE, tex_m: Variant = 1.0, collide := true,
		faces := MeshFactory.ALL) -> MeshInstance3D:
	return store.box(pos, size, tex, tint, tex_m, collide, faces, self)


# --- the wire ----------------------------------------------------------------------

## A black twin cable on porcelain clips, a little sag between them.
func _build_wire() -> void:
	var kit := MeshBuilder.Kit.new()
	var cable := kit.b("rubber", Color(0.12, 0.12, 0.12))
	var clip := kit.b("white", Color(0.85, 0.83, 0.78))
	for seg: Array in WIRE:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var d := b - a
		var n := maxi(1, int(d.length() / 0.9))
		for k in n:
			var p0 := a + d * (float(k) / n)
			var p1 := a + d * (float(k + 1) / n)
			var sag := Vector3(0, -0.012, 0) if absf(d.y) < 0.01 else Vector3.ZERO
			_strand(cable, p0, (p0 + p1) * 0.5 + sag, 0.009)
			_strand(cable, (p0 + p1) * 0.5 + sag, p1, 0.009)
			clip.box(Props.at(p0.x, p0.y - 0.012, p0.z), Vector3(0.025, 0.024, 0.025))
	kit.build(store, false)


static func _strand(mb: MeshBuilder, a: Vector3, b: Vector3, w: float) -> void:
	var d := b - a
	var up := Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var z := d.normalized()
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	mb.box(Transform3D(Basis(x, y, z), a + d * 0.5 - y * w * 0.5), Vector3(w, w, d.length()))


## Points along the wire, for the rings while Gordeev follows it.
static func wire_points() -> Array:
	var out: Array = []
	for seg: Array in WIRE:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var n := maxi(1, int(a.distance_to(b) / 5.0))
		for k in n:
			out.append(a.lerp(b, (k + 0.5) / n))
	return out


# --- the director's office ------------------------------------------------------------

func _build_office() -> void:
	var o := OFFICE
	var cz := o.get_center().y
	_box(Vector3(o.get_center().x, -0.1, cz), Vector3(o.size.x + 0.2, 0.1, o.size.y), "wood", Color(0.62, 0.45, 0.32), 0.8, false,
		MeshFactory.PY)
	_box(Vector3(o.get_center().x, 2.7, cz), Vector3(o.size.x + 0.2, 0.1, o.size.y), "ceiling", Color(0.8, 0.8, 0.78), 1.3, false,
		MeshFactory.NY)
	# Walls: wallpaper-ish paint over a dark panel, and the back wall with a window to the yard.
	var paint := Color(0.62, 0.66, 0.55)
	_box(Vector3(o.position.x - 0.05, 0, cz), Vector3(0.1, 2.7, o.size.y), "wall", paint, Vector2(2.0, 2.7), true, MeshFactory.PX)
	_box(Vector3(o.end.x + 0.05, 0, cz), Vector3(0.1, 2.7, o.size.y), "wall", paint, Vector2(2.0, 2.7), true, MeshFactory.NX)
	var bz := o.end.y + 0.05
	_box(Vector3(o.position.x + 0.7, 0, bz), Vector3(1.4, 2.7, 0.1), "wall", paint, Vector2(2.0, 2.7), true, MeshFactory.NZ)
	_box(Vector3(o.end.x - 0.8, 0, bz), Vector3(1.6, 2.7, 0.1), "wall", paint, Vector2(2.0, 2.7), true, MeshFactory.NZ)
	_box(Vector3(2.35, 0, bz), Vector3(1.0, 0.9, 0.1), "wall", paint, Vector2(2.0, 2.7), true, MeshFactory.NZ)
	_box(Vector3(2.35, 2.1, bz), Vector3(1.0, 0.6, 0.1), "wall", paint, Vector2(2.0, 2.7), true, MeshFactory.NZ)
	_box(Vector3(2.35, 0.9, bz + 0.02), Vector3(1.0, 1.2, 0.02), "glass", Color(0.25, 0.3, 0.35, 0.5), 1.0, true)
	var kit := MeshBuilder.Kit.new()
	var frame := kit.b("paint", Color(0.85, 0.83, 0.78))
	frame.box(Props.at(2.35, 1.48, bz - 0.02), Vector3(1.0, 0.04, 0.05))
	frame.box(Props.at(2.35, 0.88, bz - 0.06), Vector3(1.04, 0.04, 0.14))
	frame.box(Props.at(2.35, 0.9, bz - 0.02), Vector3(0.04, 1.2, 0.05))
	# Dark wooden wainscot round the room.
	var panel := kit.b("wood", Color(0.42, 0.28, 0.2))
	panel.box(Props.at(o.position.x + 0.01, 0, cz), Vector3(0.02, 0.9, o.size.y))
	panel.box(Props.at(o.end.x - 0.01, 0, cz), Vector3(0.02, 0.9, o.size.y))
	panel.box(Props.at(o.get_center().x, 0, 28.31), Vector3(o.size.x, 0.9, 0.02))
	# Desk: two pedestals and a top, a green cloth inset.
	var wood := kit.b("wood", Color(0.55, 0.36, 0.24))
	wood.box(Props.at(DESK.x, 0.71, DESK.z), Vector3(1.4, 0.04, 0.75))
	for dx: float in [-0.5, 0.5]:
		wood.box(Props.at(DESK.x + dx, 0, DESK.z), Vector3(0.4, 0.71, 0.72))
		for k in 3:
			kit.b("chrome", Color(0.9, 0.8, 0.5)).box(Props.at(DESK.x + dx, 0.15 + k * 0.22, DESK.z - 0.365), Vector3(0.08, 0.015, 0.012))
	kit.b("cloth", Color(0.18, 0.32, 0.2)).box(Props.at(DESK.x, 0.75, DESK.z), Vector3(1.1, 0.004, 0.55))
	wood.box(Props.at(DESK.x, 0.1, DESK.z + 0.3), Vector3(0.6, 0.6, 0.02))
	# His chair behind the desk and two for visitors.
	var leather := kit.b("leather", Color(0.35, 0.2, 0.14))
	leather.box(Props.at(DESK.x, 0.45, DESK.z + 0.65), Vector3(0.5, 0.08, 0.48))
	leather.box(Props.rot(Vector3.RIGHT, -0.1, Vector3(DESK.x, 0.5, DESK.z + 0.88)), Vector3(0.5, 0.6, 0.07))
	for dx: float in [-0.2, 0.2]:
		for dz: float in [0.47, 0.83]:
			kit.b("chrome").box(Props.at(DESK.x + dx, 0, DESK.z + dz), Vector3(0.025, 0.45, 0.025))
	for vx: float in [1.75, 3.05]:
		wood.box(Props.at(vx, 0.44, DESK.z - 0.85), Vector3(0.42, 0.035, 0.42))
		wood.box(Props.at(vx, 0.46, DESK.z - 1.05), Vector3(0.42, 0.42, 0.03))
		for o2: Vector2 in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
			wood.box(Props.at(vx + o2.x, 0, DESK.z - 0.85 + o2.y), Vector3(0.025, 0.44, 0.025))
	# The phone, the handset lying beside it on its cord, still turned up.
	var red := kit.b("white", Color(0.12, 0.12, 0.12))
	var ph := Vector3(2.92, 0.75, 30.35)
	red.box(Props.at(ph.x, ph.y, ph.z), Vector3(0.22, 0.07, 0.2))
	red.box(Props.rot(Vector3.RIGHT, -0.25, Vector3(ph.x, ph.y + 0.07, ph.z + 0.01)), Vector3(0.16, 0.05, 0.16))
	kit.b("dial").cylinder(Props.rot(Vector3.RIGHT, -0.45, Vector3(ph.x, ph.y + 0.105, ph.z - 0.03)), 0.06, 0.06, 0.008, 12,
		Color.WHITE, Rect2(0, 0.45, 1, 0.1), Props.FULL)
	for dx: float in [-0.09, 0.09]:
		red.box(Props.at(ph.x + dx, ph.y + 0.1, ph.z + 0.04), Vector3(0.05, 0.04, 0.06))
	red.box(Props.rot(Vector3.UP, 0.9, HANDSET), Vector3(0.22, 0.03, 0.05))
	for dx: float in [-0.1, 0.1]:
		red.box(Props.rot(Vector3.UP, 0.9, HANDSET + Vector3(dx * cos(0.9), 0, -dx * sin(0.9))), Vector3(0.06, 0.045, 0.06))
	var cord := kit.b("rubber", Color(0.1, 0.1, 0.1))
	var prev := HANDSET + Vector3(0.08, 0.0, 0.06)
	for k in 6:
		var nxt := prev.lerp(ph + Vector3(-0.08, 0.0, 0.0), 1.0 / (6 - k)) + Vector3(0, 0, 0.02 * sin(k * 2.0))
		_strand(cord, prev, nxt, 0.008)
		prev = nxt
	# Glass ashtray with fresh ash and a «Космос» end: the director does not smoke.
	kit.b("glass", Color(0.6, 0.7, 0.7, 0.5), Color.BLACK, Mats.GLASS).cylinder(Props.at(1.98, 0.75, 30.38), 0.07, 0.075, 0.03, 12)
	kit.b("white", Color(0.45, 0.44, 0.42)).cylinder(Props.at(1.98, 0.755, 30.38), 0.05, 0.05, 0.012, 10)
	kit.b("white", Color(0.95, 0.93, 0.88)).cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(2.0, 0.775, 30.38)), 0.005, 0.005, 0.045, 8)
	# Papers, a pen and the desk lamp with its green shade (off).
	var paper := kit.b("tags", Color(1.1, 1.1, 1.05))
	for k in 4:
		paper.box(Props.rot(Vector3.UP, 0.08 * k - 0.1, Vector3(2.3, 0.755 + k * 0.003, 30.42)), Vector3(0.21, 0.002, 0.3),
			Color.WHITE, Rect2(0, 0, 0.5, 0.25))
	kit.b("chrome", Color(0.2, 0.2, 0.25)).box(Props.rot(Vector3.UP, 0.4, Vector3(2.48, 0.765, 30.5)), Vector3(0.008, 0.008, 0.14))
	kit.b("metal", Color(0.3, 0.3, 0.28)).cylinder(Props.at(1.82, 0.75, 30.75), 0.07, 0.07, 0.02, 12)
	kit.b("metal", Color(0.3, 0.3, 0.28)).box(Props.rot(Vector3.RIGHT, -0.3, Vector3(1.82, 0.76, 30.78)), Vector3(0.015, 0.36, 0.015))
	kit.b("glass", Color(0.15, 0.45, 0.2, 0.9), Color.BLACK, Mats.GLASS).cylinder(
		Props.rot(Vector3.RIGHT, 1.4, Vector3(1.82, 1.08, 30.62)), 0.09, 0.03, 0.12, 12)
	# A steel safe in the corner and a cabinet of folders on the right wall.
	kit.b("metal", Color(0.25, 0.32, 0.27)).box(Props.at(4.2, 0, 31.25), Vector3(0.6, 1.0, 0.6))
	kit.b("chrome").cylinder(Props.rot(Vector3.RIGHT, -PI * 0.5, Vector3(4.2, 0.65, 30.94)), 0.04, 0.04, 0.02, 12)
	wood.box(Props.at(4.38, 0, 29.4), Vector3(0.52, 1.9, 1.2))
	kit.b("glass", Color(0.5, 0.55, 0.55, 0.35), Color.BLACK, Mats.GLASS).box(Props.at(4.115, 1.0, 29.4), Vector3(0.01, 0.85, 1.1))
	for k in 9:
		kit.b("cardboard", [Color(0.4, 0.5, 0.6), Color(0.6, 0.45, 0.3), Color(0.35, 0.45, 0.35)][k % 3]).box(
			Props.at(4.3, 1.08 + (k / 5) * 0.42, 28.9 + (k % 5) * 0.22), Vector3(0.28, 0.32, 0.07))
	# The red pennant of the socialist competition, and the wall calendar.
	kit.b("cloth", Color(0.75, 0.1, 0.08)).box(Props.at(3.6, 1.55, bz - 0.06), Vector3(0.35, 0.45, 0.01))
	kit.b("chrome", Color(1.0, 0.8, 0.4)).box(Props.at(3.6, 2.0, bz - 0.065), Vector3(0.42, 0.015, 0.015))
	kit.b("calendar").box(Props.rot(Vector3.UP, PI * 0.5, Vector3(o.position.x + 0.02, 1.3, 30.2)), Vector3(0.42, 0.6, 0.005),
		Color.WHITE, Props.FULL)
	kit.build(self)
	var pen := Label3D.new()
	pen.text = "ПОБЕДИТЕЛЮ\nСОЦ.\nСОРЕВНОВАНИЯ"
	pen.font_size = 18
	pen.pixel_size = 0.0016
	pen.modulate = Color(1.0, 0.85, 0.4)
	pen.position = Vector3(3.6, 1.82, bz - 0.07)
	pen.rotation.y = PI
	pen.shaded = true
	add_child(pen)
	# Cold light from the yard lamp through the window.
	var yard := OmniLight3D.new()
	yard.light_color = Color(0.55, 0.65, 0.85)
	yard.light_energy = 0.35
	yard.omni_range = 2.6
	yard.position = Vector3(2.35, 1.6, 31.3)
	add_child(yard)
	store.add_interactable("handset", Vector3(2.9, 0, 29.8), "Взять трубку на столе", 1.2, true, false)
	store.add_interactable("letter", Vector3(2.0, 0, 29.95), "Посмотреть бумаги на столе", 1.2, true, false)


# --- the cellar stairs -------------------------------------------------------------

func _build_stairs() -> void:
	var x := Store.CELLAR_X
	var run := (STAIR_Z1 - STAIR_Z0) / STEPS
	var rise := -FLOOR / STEPS
	_box(Vector3(x, -0.2, 28.375), Vector3(1.0, 0.2, 0.15), "concrete", Color(0.6, 0.6, 0.58), 1.0, false)
	var kit := MeshBuilder.Kit.new()
	var conc := kit.b("concrete", Color(0.55, 0.55, 0.53))
	var edge := kit.b("metal", Color(0.4, 0.38, 0.35))
	for k in STEPS:
		var top := -(k + 1) * rise
		var zc := STAIR_Z0 + (k + 0.5) * run
		conc.box(Props.at(x, top - rise, zc), Vector3(1.0, rise, run + 0.01))
		edge.box(Props.at(x, top - 0.01, STAIR_Z0 + k * run + 0.02), Vector3(1.0, 0.012, 0.04))
	# A pipe handrail on the right.
	var rail := kit.b("paint", Color(0.2, 0.25, 0.2))
	_strand(rail, Vector3(x + 0.42, 0.95, STAIR_Z0), Vector3(x + 0.42, FLOOR + 0.95, STAIR_Z1), 0.035)
	kit.build(self)
	# Side walls, floor to hall ceiling height.
	for sx: float in [-0.55, 0.55]:
		_box(Vector3(x + sx, FLOOR, (28.3 + CELLAR.position.y) * 0.5), Vector3(0.1, 2.15 - FLOOR, CELLAR.position.y - 28.3),
			"concrete", Color(0.5, 0.5, 0.48), 1.5, true)
	# The ceiling slopes down with the flight, 2.2 m over every step.
	var dz := CELLAR.position.y - 28.3
	var dy := 2.15 - CEIL
	var ceil := _box(Vector3(x, 0.0, 28.3 + dz * 0.5), Vector3(1.2, 0.1, sqrt(dz * dz + dy * dy)), "concrete",
		Color(0.45, 0.45, 0.43), 1.5, true)
	ceil.position.y = (2.15 + CEIL) * 0.5
	ceil.rotation.x = atan2(dy, dz)


# --- the cellar ----------------------------------------------------------------------

func _build_cellar() -> void:
	var c := CELLAR
	var h := CEIL - FLOOR
	_box(Vector3(c.get_center().x, FLOOR - 0.1, c.get_center().y), Vector3(c.size.x, 0.1, c.size.y), "concrete",
		Color(0.45, 0.44, 0.42), 1.2, false, MeshFactory.PY)
	# The ceiling is a real slab: nobody up in the hall sees down through the floor.
	_box(Vector3(c.get_center().x, CEIL, c.get_center().y), Vector3(c.size.x, 0.28, c.size.y), "concrete",
		Color(0.4, 0.4, 0.38), 1.2, true)
	var wall := Color(0.55, 0.55, 0.5)
	_box(Vector3(c.position.x - 0.1, FLOOR, c.get_center().y), Vector3(0.2, h, c.size.y), "concrete", wall, 1.4)
	_box(Vector3(c.end.x + 0.1, FLOOR, c.get_center().y), Vector3(0.2, h, c.size.y), "concrete", wall, 1.4)
	_box(Vector3(c.get_center().x, FLOOR, c.end.y + 0.1), Vector3(c.size.x, h, 0.2), "concrete", wall, 1.4)
	var x := Store.CELLAR_X
	var lw := x - 0.5 - c.position.x
	_box(Vector3(c.position.x + lw * 0.5, FLOOR, c.position.y - 0.05), Vector3(lw, h, 0.1), "concrete", wall, 1.4)
	var rw := c.end.x - (x + 0.5)
	_box(Vector3(c.end.x - rw * 0.5, FLOOR, c.position.y - 0.05), Vector3(rw, h, 0.1), "concrete", wall, 1.4)
	var kit := MeshBuilder.Kit.new()
	# Pipes under the ceiling, lagged in old rags; a dead bulb on a flex.
	var pipe := kit.b("galv", Color(0.6, 0.58, 0.52))
	for k in 2:
		_strand(pipe, Vector3(c.position.x, CEIL - 0.15 - k * 0.14, 32.4 + k * 0.25), Vector3(c.end.x, CEIL - 0.15 - k * 0.14,
			32.4 + k * 0.25), 0.08)
	_strand(pipe, Vector3(0.6, CEIL - 0.1, c.position.y), Vector3(0.6, CEIL - 0.1, c.end.y), 0.1)
	kit.b("cloth", Color(0.45, 0.4, 0.33)).box(Props.at(-3.8, CEIL - 0.34, 32.4), Vector3(0.6, 0.14, 0.14))
	kit.b("rubber").box(Props.at(-2.2, CEIL - 0.45, 34.0), Vector3(0.01, 0.45, 0.01))
	kit.b("glass", Color(0.8, 0.8, 0.7, 0.6), Color.BLACK, Mats.GLASS).ellipsoid(Props.at(-2.2, CEIL - 0.5, 34.0),
		Vector3(0.035, 0.05, 0.035), 10, 6)
	# Old shelves with jars and junk on the left wall; broken crates; a ladder.
	var wood := kit.b("wood", Color(0.5, 0.42, 0.34))
	for k in 3:
		wood.box(Props.at(c.position.x + 0.25, FLOOR + 0.35 + k * 0.6, 34.0), Vector3(0.45, 0.03, 2.6))
	for dz: float in [-1.25, 1.25]:
		wood.box(Props.at(c.position.x + 0.25, FLOOR, 34.0 + dz), Vector3(0.45, 1.9, 0.04))
	var jar := kit.b("glass", Color(0.55, 0.6, 0.5, 0.55), Color.BLACK, Mats.GLASS)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2010
	for k in 14:
		var shelf := k % 3
		jar.cylinder(Props.at(c.position.x + 0.2 + rng.randf_range(-0.1, 0.1), FLOOR + 0.38 + shelf * 0.6, 32.9 + rng.randf() * 2.2),
			0.05, 0.05, 0.16, 8)
	var crate := kit.b("wood", Color(0.62, 0.5, 0.36))
	for k in 4:
		var p := Vector3(0.2 - (k % 2) * 0.5, FLOOR + (k / 2) * 0.32, 33.0 + (k % 2) * 0.15)
		crate.box(Props.rot(Vector3.UP, rng.randf_range(-0.2, 0.2), p), Vector3(0.45, 0.3, 0.33))
	crate.box(Props.rot(Vector3.BACK, 1.2, Vector3(0.6, FLOOR, 35.5)), Vector3(0.05, 1.8, 0.4))
	kit.build(self)
	# Boot prints in the dust from the stairs to the cabinet, and back.
	for k in 7:
		var t := float(k) / 6.0
		var p := Vector3(x, FLOOR, 31.9).lerp(FRIDGE + Vector3(0, 0, -0.7), t) + Vector3(0.12 if k % 2 == 0 else -0.12, 0, 0)
		Equip.decal(self, p + Vector3(0, 0.003, 0), 0.32, "boots", 0.0 if k % 2 == 0 else PI)
	Equip.decal(self, Vector3(-3.6, FLOOR + 0.003, 35.0), 1.1, "puddle", 0.8)
	store.add_interactable("boots", Vector3(x - 0.1, FLOOR, 33.6), "Посмотреть следы на полу", 1.3, true, false)
	_lock_on_floor = Node3D.new()
	var lk := MeshBuilder.Kit.new()
	lk.b("chrome", Color(1.0, 0.85, 0.5)).box(Props.rot(Vector3.UP, 0.7, Vector3(x + 0.2, 0.0, 27.6)), Vector3(0.065, 0.025, 0.075))
	lk.b("chrome", Color(0.9, 0.9, 0.88)).box(Props.rot(Vector3.UP, 0.3, Vector3(x + 0.3, 0.0, 27.55)), Vector3(0.16, 0.02, 0.035))
	lk.build(_lock_on_floor, false)
	_lock_on_floor.visible = false
	add_child(_lock_on_floor)


## The hasp torn off with the crowbar: the padlock lies on the floor.
func show_broken_lock() -> void:
	_lock_on_floor.visible = true


# --- the refrigerated cabinet, and what is in it -----------------------------------------------

func _build_fridge() -> void:
	var f := FRIDGE
	var w := 1.3
	var hgt := 1.95
	var d := 0.75
	var enamel := Color(0.88, 0.86, 0.78)
	var kit := MeshBuilder.Kit.new()
	var body := kit.b("enamel", enamel)
	# A hollow box: back, sides, top, the bottom with the compressor under it.
	body.box(Props.at(f.x, f.y, f.z + d * 0.5 - 0.03), Vector3(w, hgt, 0.06))
	for sx: float in [-1.0, 1.0]:
		body.box(Props.at(f.x + sx * (w * 0.5 - 0.03), f.y, f.z), Vector3(0.06, hgt, d))
	body.box(Props.at(f.x, f.y + hgt - 0.06, f.z), Vector3(w, 0.06, d))
	body.box(Props.at(f.x, f.y, f.z), Vector3(w, 0.32, d))
	kit.b("grille").box(Props.at(f.x, f.y + 0.05, f.z - d * 0.5 - 0.005), Vector3(w - 0.2, 0.2, 0.01), Color(0.5, 0.5, 0.5), Props.FULL)
	# Inside: grey-white liner, rust streaks, a dark stain spread over the floor of it.
	var liner := kit.b("enamel", Color(0.7, 0.7, 0.66))
	liner.box(Props.at(f.x, f.y + 0.32, f.z + d * 0.5 - 0.065), Vector3(w - 0.12, hgt - 0.4, 0.01))
	kit.b("blood", Color(0.55, 0.42, 0.4)).box(Props.at(f.x, f.y + 0.321, f.z), Vector3(w - 0.14, 0.004, d - 0.12), Color.WHITE,
		Rect2(0.1, 0.1, 0.8, 0.8))
	kit.b("blood", Color(0.45, 0.3, 0.27)).box(Props.at(f.x - 0.3, f.y + 0.9, f.z + d * 0.5 - 0.07), Vector3(0.05, 0.45, 0.004),
		Color.WHITE, Rect2(0.4, 0.0, 0.2, 1.0))
	# Maker's plate.
	kit.b("chrome").box(Props.at(f.x, f.y + hgt - 0.2, f.z - d * 0.5 - 0.01), Vector3(0.3, 0.06, 0.005))
	kit.build(self)
	_build_body(f + Vector3(0, 0.32, 0.05))
	var plate := Label3D.new()
	plate.text = "ШХ-1,12"
	plate.font_size = 22
	plate.pixel_size = 0.0016
	plate.modulate = Color(0.15, 0.15, 0.15)
	plate.position = Vector3(f.x, f.y + hgt - 0.17, f.z - d * 0.5 - 0.015)
	plate.rotation.y = PI
	plate.shaded = true
	add_child(plate)
	# Two doors hinged at the outer edges, wire twisted round the handles.
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(f.x + side * w * 0.5, f.y + 0.32, f.z - d * 0.5)
		add_child(hinge)
		var dk := MeshBuilder.Kit.new()
		dk.b("enamel", enamel).box(Props.at(-side * w * 0.25, 0, -0.03), Vector3(w * 0.5 - 0.01, hgt - 0.38, 0.06))
		dk.b("chrome").box(Props.at(-side * (w * 0.5 - 0.08), 0.75, -0.08), Vector3(0.03, 0.22, 0.04))
		dk.b("metal", Color(0.4, 0.38, 0.33)).box(Props.at(-side * (w * 0.5 - 0.04), 0.85, -0.1), Vector3(0.09, 0.012, 0.012))
		dk.b("rubber", Color(0.3, 0.3, 0.3)).box(Props.at(-side * w * 0.25, 0, -0.001), Vector3(w * 0.5 - 0.04, hgt - 0.42, 0.004))
		dk.build(hinge)
		_fridge_doors.append(hinge)
	store.add_interactable("fridge", Vector3(f.x, FLOOR, f.z - 1.0), "Открыть холодильный шкаф", 1.3, true, false)
	store.add_interactable("body", Vector3(f.x, FLOOR, f.z - 0.95), "Осмотреть", 1.2, true, false)


## Nina, as he left her: folded up on the floor of the cabinet, knees to her
## chest, wrapped in the brown paper of the meat counter and tied with
## butcher's twine. Her hair has come out at the top, one bare hand at the side.
## Nina, folded up in the cabinet and wrapped in meat paper (NinaBody).
func _build_body(base: Vector3) -> void:
	var body := NinaBody.new()
	add_child(body)
	body.position = base


func open_fridge(instant := false) -> void:
	fridge_open = true
	for i in _fridge_doors.size():
		var side := -1.0 if i == 0 else 1.0
		var to := deg_to_rad(side * 115.0)
		if instant:
			_fridge_doors[i].rotation.y = to
		else:
			create_tween().tween_property(_fridge_doors[i], "rotation:y", to, 1.6 + i * 0.4) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# --- the killer's ways in ------------------------------------------------------------------

## Waypoints through the two doors (walkable only while a door is open):
## down the stairs to the cabinet, and into the office to the desk.
func _build_ways() -> void:
	var x := Store.CELLAR_X
	var ways := {
		"cellar": [Vector3(x, 0, 27.3), Vector3(x, 0, 28.6), Vector3(x, 0, 31.5), Vector3(x, 0, 33.4), Vector3(FRIDGE.x, 0, 35.3)],
		"office": [Vector3(Store.OFFICE_X, 0, 27.3), Vector3(Store.OFFICE_X, 0, 28.9), Vector3(1.6, 0, 29.8)],
	}
	var next := store.astar.get_available_point_id()
	for which: String in ways:
		var pts: Array = ways[which]
		var ids: Array[int] = []
		for p: Vector3 in pts:
			store.astar.add_point(next, p)
			ids.append(next)
			next += 1
		# From the back aisle to the door, then through.
		for key: String in ["BB", "BC"]:
			store.astar.connect_points(store.way_ids[key], ids[0])
		for k in ids.size() - 1:
			store.astar.connect_points(ids[k], ids[k + 1])
		store._back_ways[which] = ids.slice(1)
		for id in ids.slice(1):
			store.astar.set_point_disabled(id, true)
