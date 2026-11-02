class_name Street
extends RefCounted

## Street furniture of a Sverdlovsk housing estate in 1988, for the square
## outside «Кировский»: the «Союзпечать» kiosk, the red phone booths, a
## concrete bus-stop pavilion with its bills, benches and concrete litter
## urns, green bins, low pipe fences round the lawns, block entrances with
## their canopies, and ground decals (puddles, leaves, oil, manhole covers).
## Textures: textures/street.png, ext_decals.png, ext_grass.png, drawn by
## tools/make_street.py. Every builder takes a parent, a position on the
## ground and a yaw; at yaw 0 the front faces -Z (towards the road).

const TEX := "street"
const CELLS := [
	"soyuz", "kiosk_win", "phone", "bus_sign",
	"afisha", "poster_drink", "slogan", "door",
	"podezd", "house_no", "bin", "tara",
	"timetable", "bark", "panel_plinth", "univ_board",
]
const DECALS := {"puddle": Rect2(0, 0, 0.5, 0.5), "leaves": Rect2(0.5, 0, 0.5, 0.5),
	"oil": Rect2(0, 0.5, 0.5, 0.5), "hatch": Rect2(0.5, 0.5, 0.5, 0.5)}
const BLUE := Color(0.32, 0.42, 0.5)
const CONCRETE := Color(0.62, 0.61, 0.58)


static func _cell(name: String) -> Rect2:
	var i := CELLS.find(name)
	var px := 1.0 / 2048.0
	return Rect2((i % 4) * 0.25 + px, (i / 4) * 0.25 + px, 0.25 - 2.0 * px, 0.25 - 2.0 * px)


static func _front(kit: MeshBuilder.Kit, xf: Transform3D, size: Vector3, which: String, tint := Color.WHITE) -> void:
	kit.b(TEX).box(xf, size, tint, _cell(which), Vector2.ONE, MeshFactory.NZ)


## «Союзпечать»: a glazed box on a plinth, the blue band under a flat roof
## that overhangs, the window crammed with papers.
static func kiosk(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var paint := kit.b("paint", BLUE)
	var w := 2.6
	var d := 1.8
	paint.box(Props.at(0, 0, 0), Vector3(w, 0.8, d))                               # plinth
	paint.box(Props.at(0, 0.8, d * 0.5 - 0.05), Vector3(w, 1.35, 0.1))              # back wall
	for sx: float in [-w * 0.5 + 0.05, w * 0.5 - 0.05]:
		paint.box(Props.at(sx, 0.8, 0), Vector3(0.1, 1.35, d))
	# The glazing on the front, papers pressed against it from inside.
	_front(kit, Props.at(0, 0.82, -d * 0.5 + 0.12), Vector3(w - 0.2, 1.3, 0.02), "kiosk_win")
	kit.b("glass", Color(0.6, 0.66, 0.66, 0.3), Color.BLACK, Mats.GLASS).box(Props.at(0, 0.8, -d * 0.5 + 0.05),
		Vector3(w - 0.1, 1.35, 0.02), Color.WHITE, Props.NO_RECT, Vector2.ONE, MeshFactory.NZ)
	var frame := kit.b("metal", Color(0.25, 0.27, 0.3))
	for k in 4:
		frame.box(Props.at(-w * 0.5 + 0.05 + k * (w - 0.1) / 3.0, 0.8, -d * 0.5 + 0.04), Vector3(0.05, 1.35, 0.05))
	frame.box(Props.at(0, 1.2, -d * 0.5 + 0.04), Vector3(w, 0.04, 0.05))
	# The little hatch where you pay, and its shelf.
	kit.b("formica", Color(0.7, 0.68, 0.62)).box(Props.at(0.4, 0.8, -d * 0.5 - 0.12), Vector3(0.6, 0.03, 0.26))
	# The sign band and the roof.
	_front(kit, Props.at(0, 2.15, -d * 0.5 - 0.06), Vector3(w + 0.1, 0.45, 0.04), "soyuz")
	paint.box(Props.at(0, 2.15, 0), Vector3(w + 0.1, 0.45, d), Color.WHITE, Props.NO_RECT, Vector2.ONE,
		Props.SIDES & ~MeshFactory.NZ)
	kit.b("paint", Color(0.35, 0.35, 0.35)).box(Props.at(0, 2.6, -0.1), Vector3(w + 0.5, 0.08, d + 0.5))
	kit.build(root)
	# A bill pasted on the side.
	plate(root, Vector3(-w * 0.5 - 0.006, 1.2, 0.1), Vector3.LEFT, "poster_drink", Vector2(1.2, 0.6))


## A flat bill or plate on a wall, its face out along `normal`.
static func plate(parent: Node3D, pos: Vector3, normal: Vector3, which: String, size: Vector2) -> void:
	var kit := MeshBuilder.Kit.new()
	var b := Basis.looking_at(-normal, Vector3.UP)
	kit.b(TEX).box(Transform3D(b, pos), Vector3(size.x, size.y, 0.01), Color.WHITE, _cell(which), Vector2.ONE,
		MeshFactory.PZ)
	kit.build(parent, false)


## Two red phone booths side by side: a steel frame with small panes, the
## «ТЕЛЕФОН» plate on top, the grey payphone on the back wall.
static func phone_booths(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var red := kit.b("paint", Color(0.62, 0.14, 0.1))
	var glass := kit.b("glass", Color(0.55, 0.62, 0.62, 0.35), Color.BLACK, Mats.GLASS)
	for k in 2:
		var ox := -0.48 + k * 0.96
		var s := 0.9
		red.box(Props.at(ox, 0, 0), Vector3(s, 0.05, s))
		red.box(Props.at(ox, 2.2, 0), Vector3(s + 0.04, 0.14, s + 0.04))
		for cx: float in [-1, 1]:
			for cz: float in [-1, 1]:
				red.box(Props.at(ox + cx * (s * 0.5 - 0.025), 0.05, cz * (s * 0.5 - 0.025)), Vector3(0.05, 2.15, 0.05))
		# Glazing bars and panes on three sides; the front is the door.
		for side in 4:
			var xf := Transform3D(Basis(Vector3.UP, side * PI * 0.5), Vector3(ox, 0, 0))
			var inner := xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, -s * 0.5 + 0.02))
			glass.box(inner * Props.at(0, 0.6, 0), Vector3(s - 0.08, 1.5, 0.01))
			red.box(inner * Props.at(0, 0.05, 0), Vector3(s - 0.05, 0.55, 0.03))
			for y: float in [1.1, 1.6]:
				red.box(inner * Props.at(0, y, 0), Vector3(s - 0.05, 0.035, 0.035))
			red.box(inner * Props.at(0, 0.6, 0), Vector3(0.035, 1.5, 0.035))
		_front(kit, Props.at(ox, 2.34, -s * 0.5 - 0.03), Vector3(s, 0.22, 0.02), "phone")
		red.box(Props.at(ox, 2.34, 0), Vector3(s, 0.22, s), Color.WHITE, Props.NO_RECT, Vector2.ONE,
			Props.SIDES & ~MeshFactory.NZ)
		# The payphone: a grey box with its black handset.
		var ph := kit.b("metal", Color(0.45, 0.47, 0.47))
		ph.box(Props.at(ox, 1.25, s * 0.5 - 0.12), Vector3(0.24, 0.36, 0.14))
		kit.b("rubber", Color(0.08, 0.08, 0.08)).capsule(Transform3D.IDENTITY, Vector3(ox - 0.14, 1.35, s * 0.5 - 0.1),
			Vector3(ox - 0.14, 1.55, s * 0.5 - 0.1), 0.03, 0.03, 6)
	kit.build(root)


## A concrete bus-stop pavilion: a back wall with the cinema bill and the
## timetable, two side walls, a flat roof, a bench, the «А» sign on a post.
static func bus_stop(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var con := kit.b("concrete", CONCRETE)
	var w := 4.2
	con.box(Props.at(0, 0, 0.75), Vector3(w, 2.4, 0.14))
	for sx: float in [-w * 0.5 + 0.07, w * 0.5 - 0.07]:
		con.box(Props.at(sx, 0, 0.2), Vector3(0.14, 2.4, 1.2))
	con.box(Props.at(0, 2.4, 0.1), Vector3(w + 0.4, 0.18, 1.8))
	con.box(Props.at(0, -0.02, 0.2), Vector3(w, 0.06, 1.4))
	kit.build(root)
	plate(root, Vector3(-0.8, 1.45, 0.675), Vector3.FORWARD, "afisha", Vector2(1.6, 0.8))
	plate(root, Vector3(0.9, 1.45, 0.675), Vector3.FORWARD, "timetable", Vector2(0.8, 0.4))
	plate(root, Vector3(0.9, 0.95, 0.675), Vector3.FORWARD, "poster_drink", Vector2(0.9, 0.45))
	bench(root, Vector3(0, 0, 0.45), 0.0, 2.6)
	var sk := MeshBuilder.Kit.new()
	sk.b("metal", Color(0.4, 0.42, 0.42)).cylinder(Props.at(w * 0.5 + 0.6, 0, -0.3), 0.04, 0.04, 2.7, 8)
	sk.b(TEX).box(Props.at(w * 0.5 + 0.6, 2.2, -0.33), Vector3(0.9, 0.45, 0.02), Color.WHITE, _cell("bus_sign"),
		Vector2.ONE, MeshFactory.NZ | MeshFactory.PZ)
	sk.build(root)


## A park bench: concrete legs, wooden slats with flaking green paint.
static func bench(parent: Node3D, pos: Vector3, yaw: float, length := 2.0) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var con := kit.b("concrete", Color(0.55, 0.55, 0.52))
	for sx: float in [-length * 0.38, length * 0.38]:
		con.box(Props.at(sx, 0, 0), Vector3(0.12, 0.42, 0.5))
		con.box(Props.rot(Vector3.RIGHT, -0.25, Vector3(sx, 0.42, 0.2)), Vector3(0.1, 0.5, 0.1))
	var slat := kit.b("wood", Color(0.42, 0.52, 0.38))
	for k in 3:
		slat.box(Props.at(0, 0.42, -0.18 + k * 0.15), Vector3(length, 0.04, 0.11))
	for k in 2:
		slat.box(Props.rot(Vector3.RIGHT, -0.25, Vector3(0, 0.62 + k * 0.17, 0.25 + k * 0.04)), Vector3(length, 0.11, 0.035))
	kit.build(root)


## A concrete litter urn, the classic flared vase on a foot.
static func urn(parent: Node3D, pos: Vector3) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.b("concrete", Color(0.68, 0.67, 0.63)).lathe(Props.at(pos.x, pos.y, pos.z), [Vector2(0.0, 0.0),
		Vector2(0.2, 0.0), Vector2(0.17, 0.08), Vector2(0.12, 0.15), Vector2(0.16, 0.35), Vector2(0.26, 0.62),
		Vector2(0.28, 0.66), Vector2(0.24, 0.66), Vector2(0.22, 0.5), Vector2(0.0, 0.5)], 14)
	kit.b("white", Color(0.8, 0.78, 0.7)).box(Props.rot(Vector3.UP, 0.6, pos + Vector3(0.03, 0.5, 0)),
		Vector3(0.12, 0.08, 0.16))
	kit.build(parent)


## Green steel bins on a concrete pad, lids ajar, a bag on the ground.
static func bins(parent: Node3D, pos: Vector3, yaw: float, count := 3) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	kit.b("concrete", Color(0.5, 0.5, 0.48)).box(Props.at(0, -0.02, 0), Vector3(count * 1.25 + 0.4, 0.1, 1.5))
	var body := kit.b(TEX)
	var lid := kit.b("paint", Color(0.2, 0.28, 0.21))
	for k in count:
		var x := (k - (count - 1) * 0.5) * 1.25
		body.box(Props.at(x, 0.08, 0), Vector3(1.1, 1.0, 0.85), Color.WHITE, _cell("bin"), Vector2.ONE,
			Props.SIDES)
		lid.box(Props.rot(Vector3.RIGHT, 0.12 * (k % 2), Vector3(x, 1.08, 0.42)) * Props.at(0, 0, -0.42),
			Vector3(1.14, 0.04, 0.9))
		lid.cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(x - 0.6, 0.85, 0)), 0.03, 0.03, 0.12, 6)
	kit.b("rubber", Color(0.12, 0.12, 0.12)).lathe(Props.at(count * 0.6 + 0.3, 0, -0.5),
		[Vector2(0, 0), Vector2(0.22, 0.02), Vector2(0.25, 0.2), Vector2(0.12, 0.42), Vector2(0, 0.45)], 8)
	kit.build(root)


## A low fence of bent pipe round a lawn, from `a` to `b`, painted green
## and white in turns, as the ЖЭУ did every spring.
static func fence(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var kit := MeshBuilder.Kit.new()
	var pipe := [kit.b("paint", Color(0.25, 0.4, 0.25)), kit.b("paint", Color(0.8, 0.8, 0.76))]
	var n := maxi(1, int(a.distance_to(b) / 1.2))
	for i in n:
		var p0 := a.lerp(b, float(i) / n)
		var p1 := a.lerp(b, float(i + 1) / n)
		var m: MeshBuilder = pipe[i % 2]
		var steps := 6
		var prev := p0
		for s in range(1, steps + 1):
			var t := float(s) / steps
			var q := p0.lerp(p1, t) + Vector3(0, sin(t * PI) * 0.45, 0)
			m.capsule(Transform3D.IDENTITY, prev, q, 0.02, 0.02, 5)
			prev = q
	kit.build(parent, false)


## The entrance of a panel block, its door in the wall plane at `pos`,
## facing `yaw` like the furniture: three steps, a concrete canopy on two
## brackets, a lamp, the entrance and house-number plates.
static func entrance(parent: Node3D, pos: Vector3, yaw: float, night: bool, number := 1) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var con := kit.b("concrete", Color(0.58, 0.57, 0.54))
	for k in 3:
		con.box(Props.at(0, 0, -0.9 + k * 0.3), Vector3(2.4 - k * 0.2, 0.15 * (k + 1), 0.3))
	con.box(Props.at(0, 0, -0.15), Vector3(2.0, 0.45, 0.3))
	con.box(Props.at(0, 2.75, -0.7), Vector3(2.6, 0.14, 1.5))
	for sx: float in [-1.15, 1.15]:
		con.box(Props.at(sx, 0.45, -1.3), Vector3(0.12, 2.3, 0.12))
	_front(kit, Props.at(0, 0.45, -0.03), Vector3(1.6, 2.2, 0.02), "door")
	kit.b("paint", Color(0.3, 0.22, 0.16)).box(Props.at(0, 0.45, -0.02), Vector3(1.7, 2.25, 0.02), Color.WHITE,
		Props.NO_RECT, Vector2.ONE, MeshFactory.NZ)
	# A bulb in a wire cage over the door.
	kit.b("white", Color.WHITE, Color(2.0, 1.6, 1.0) if night and number % 3 != 0 else Color.BLACK).cylinder(
		Props.at(0, 2.58, -0.2), 0.07, 0.07, 0.15, 8)
	kit.build(root)
	plate(root, Vector3(1.3, 2.2, -0.04), Vector3.FORWARD, "podezd", Vector2(0.5, 0.25))
	if night and number % 3 != 0:
		var l := OmniLight3D.new()
		l.position = Vector3(0, 2.4, -0.6)
		l.omni_range = 4.5
		l.light_energy = 0.8
		l.light_color = Color(1.0, 0.75, 0.45)
		root.add_child(l)


## A flat decal on the ground (puddle, leaves, oil, hatch).
static func decal(parent: Node3D, pos: Vector3, size: float, which: String, yaw: float, aspect := 1.0) -> void:
	var mi := MeshInstance3D.new()
	var mb := MeshBuilder.new()
	mb.ao_enabled = false
	var r: Rect2 = DECALS[which]
	var hx := size * 0.5
	var hz := size * 0.5 * aspect
	mb.quad(Transform3D.IDENTITY, [Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz)],
		[Vector2(r.position.x, r.end.y), r.end, Vector2(r.end.x, r.position.y), r.position], Color.WHITE, false)
	mi.mesh = mb.commit()
	mi.material_override = Mats.get_mat("ext_decals")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, 0.006, 0)
	mi.rotation.y = yaw
	parent.add_child(mi)
