class_name Equip
extends RefCounted

## Shop equipment of a 1980s universam: the checkout cabins with the «Ока»
## cash register, the abacus and the lit «КАССА» box on its pole; the
## customers' control scales by the entrance; plates on the walls; printed
## cartons; wire bottle crates; and the floor decals (melt water by the
## freezers, a smashed jar of juice, dropped receipts, dried boot prints).
## Textures: textures/equip.png and textures/decals.png, drawn by
## tools/make_equip.py.

const TEX := "equip"
const CELLS := [
	"kassa1", "kassa2", "kassa3", "dial",
	"reg_front", "reg_keys", "reg_side", "reg_top",
	"hours", "complaints", "prices", "carton_fish",
	"carton_milk", "carton_tins", "receipt", "bottle_crate",
]
const DECALS := {"puddle": Rect2(0, 0, 0.5, 0.5), "juice": Rect2(0.5, 0, 0.5, 0.5),
	"litter": Rect2(0, 0.5, 0.5, 0.5), "boots": Rect2(0.5, 0.5, 0.5, 0.5)}
const CABIN := Color(0.66, 0.68, 0.66)  # grey enamelled steel of the cabin
const TOP := Color(0.92, 0.88, 0.78)  # beige laminate


static func cell(name: String) -> Rect2:
	var i := CELLS.find(name)
	var px := 1.0 / 2048.0
	return Rect2((i % 4) * 0.25 + px, (i / 4) * 0.25 + px, 0.25 - 2.0 * px, 0.25 - 2.0 * px)


static func sub(r: Rect2, x0: float, x1: float, y0 := 0.0, y1 := 1.0) -> Rect2:
	return Rect2(r.position.x + r.size.x * x0, r.position.y + r.size.y * y0, r.size.x * (x1 - x0), r.size.y * (y1 - y0))


static func at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(x, y, z))


## A checkout cabin centred on `pos`, 2.5 m along z, the cashier's side to +x.
## `sign_mat` is the emissive material of its «КАССА n» box.
static func checkout(parent: Node3D, pos: Vector3, n: int, sign_mat: Material) -> void:
	var root := Props.node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	var steel := kit.b("paint", CABIN)
	var ch := kit.b("chrome")
	var top := kit.b("formica", TOP)
	# The customer's counter: a laminate top on a steel cabinet, kick plate,
	# a chrome rail along the customer's edge to slide the basket on.
	steel.box(at(0, 0.08, 0.15), Vector3(0.7, 0.77, 2.2), Color.WHITE, Props.NO_RECT, Vector2(0.6, 0.6), Props.SIDES)
	kit.b("rubber").box(at(0, 0, 0.15), Vector3(0.66, 0.08, 2.16))
	top.box(at(0, 0.85, 0.15), Vector3(0.8, 0.03, 2.3), Color.WHITE, Props.NO_RECT, Vector2(0.5, 0.5))
	ch.box(at(-0.41, 0.84, 0.15), Vector3(0.02, 0.045, 2.3))
	ch.box(at(0.41, 0.84, 0.15), Vector3(0.02, 0.045, 2.3))
	ch.box(at(-0.45, 0.9, 0.3), Vector3(0.025, 0.025, 1.7))
	for z: float in [-0.5, 0.45, 1.12]:
		ch.box(at(-0.45, 0.86, z), Vector3(0.02, 0.06, 0.02))
	# Panels of the cabinet: darker inset sheets with a seam between.
	for z: float in [-0.6, 0.15, 0.9]:
		kit.b("paint", CABIN * 0.82).box(at(-0.352, 0.16, z), Vector3(0.004, 0.6, 0.66), Color.WHITE, Props.NO_RECT,
			Vector2(0.6, 0.6), MeshFactory.NX)
	# The register stand at the near end, the drawer under it on the cashier's side.
	steel.box(at(0.15, 0.85, -0.3), Vector3(0.5, 0.04, 0.5))
	kit.b("wood", Color(0.75, 0.6, 0.45)).box(at(0.3, 0.62, -0.3), Vector3(0.4, 0.16, 0.42), Color.WHITE, Props.NO_RECT,
		Vector2(0.5, 0.5), Props.ALL)
	ch.box(at(0.502, 0.69, -0.3), Vector3(0.012, 0.025, 0.14))
	register(kit, at(0.15, 0.89, -0.3))
	# The bagging end: a lower shelf with a lip; a stack of baskets under it.
	top.box(at(0.0, 0.7, 1.45), Vector3(0.8, 0.03, 0.5))
	ch.box(at(0.0, 0.73, 1.69), Vector3(0.8, 0.04, 0.015))
	for o: Vector2 in [Vector2(-0.38, 1.68), Vector2(0.38, 1.68)]:
		ch.box(at(o.x, 0, o.y), Vector3(0.03, 0.7, 0.03))
	# The cashier's things: an abacus, the coin dish, the spare tape roll, a cup.
	abacus(kit, Transform3D(Basis(Vector3.UP, 0.15), Vector3(0.22, 0.88, 0.45)))
	ch.cylinder(at(0.0, 0.87, -0.05), 0.09, 0.11, 0.015, 12)
	kit.b("white", Color(0.95, 0.94, 0.88)).cylinder(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.32, 0.92, 0.0)),
		0.035, 0.035, 0.06, 10)
	kit.b("enamel").cylinder(at(0.3, 0.87, 0.8), 0.04, 0.045, 0.09, 10)
	# The till number on a pole at the near corner, lit from inside.
	ch.cylinder(at(0.42, 0.86, -0.85), 0.018, 0.018, 1.45, 8)
	steel.box(at(0.42, 2.28, -0.85), Vector3(0.14, 0.34, 0.66), Color(0.3, 0.3, 0.3))
	var lit := kit.custom(sign_mat)
	var face := cell("kassa%d" % n)
	lit.box(at(0.42, 2.3, -0.85), Vector3(0.15, 0.3, 0.62), Color.WHITE, face, Vector2.ONE,
		MeshFactory.PX | MeshFactory.NX)
	# Cashier's swivel chair.
	var legs := kit.b("chrome")
	legs.cylinder(at(0.85, 0.05, -0.5), 0.025, 0.025, 0.45, 8)
	for k in 4:
		var a := k * PI * 0.5 + 0.3
		legs.box(Transform3D(Basis(Vector3.UP, a), Vector3(0.85, 0.02, -0.5)) * at(0.12, 0, 0), Vector3(0.24, 0.03, 0.03))
	kit.b("leather").cylinder(at(0.85, 0.5, -0.5), 0.2, 0.2, 0.06, 12, Color.WHITE, Props.FULL, Props.FULL)
	kit.b("leather").box(at(1.06, 0.6, -0.5), Vector3(0.03, 0.32, 0.36))
	kit.build(root)
	Props.collider(root, Vector3(0, 0, 0.15), Vector3(0.85, 0.9, 2.3))
	Props.baskets(root, Vector3(0.0, 0, 1.45), 4)


## «Ока» electromechanical register, its keyboard sloping to the cashier
## (+x), the display facing the customer (-x), the crank on the far side.
static func register(kit: MeshBuilder.Kit, xf: Transform3D) -> void:
	var mb := kit.b(TEX)
	var body := Vector3(0.4, 0.2, 0.42)
	mb.box(xf, body, Color.WHITE, cell("reg_front"), Vector2.ONE, MeshFactory.NX)
	mb.box(xf, body, Color.WHITE, cell("reg_side"), Vector2.ONE, MeshFactory.PZ | MeshFactory.NZ)
	mb.box(xf, body, Color.WHITE, cell("reg_top"), Vector2.ONE, MeshFactory.PY)
	mb.box(xf * Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0.2, 0.02, 0)), Vector3(0.02, 0.24, 0.4), Color.WHITE,
		cell("reg_keys"), Vector2.ONE, MeshFactory.PX)
	# The display tower on top, numbers both ways.
	mb.box(xf * at(-0.08, 0.2, 0), Vector3(0.12, 0.12, 0.28), Color.WHITE, sub(cell("reg_front"), 0.15, 0.85, 0.08, 0.4),
		Vector2.ONE, MeshFactory.NX | MeshFactory.PX)
	mb.box(xf * at(-0.08, 0.2, 0), Vector3(0.12, 0.12, 0.28), Color.WHITE, sub(cell("reg_side"), 0, 0.5, 0, 0.5),
		Vector2.ONE, MeshFactory.PY | MeshFactory.PZ | MeshFactory.NZ)
	# The crank handle.
	var ch := kit.b("chrome")
	ch.cylinder(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.05, 0.1, 0.21)), 0.025, 0.025, 0.04, 8)
	ch.box(xf * at(0.05, 0.06, 0.25), Vector3(0.015, 0.11, 0.015))
	kit.b("rubber").cylinder(xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.05, 0.06, 0.25)), 0.012, 0.012,
		0.06, 6)


## Wooden abacus (счёты) lying flat: frame, ten wires, beads.
static func abacus(kit: MeshBuilder.Kit, xf: Transform3D) -> void:
	var wood := kit.b("wood", Color(0.8, 0.55, 0.35))
	wood.box(xf * at(0, 0, -0.13), Vector3(0.2, 0.02, 0.015))
	wood.box(xf * at(0, 0, 0.13), Vector3(0.2, 0.02, 0.015))
	wood.box(xf * at(-0.1, 0, 0), Vector3(0.015, 0.02, 0.27))
	wood.box(xf * at(0.1, 0, 0), Vector3(0.015, 0.02, 0.27))
	var wire := kit.b("chrome")
	var beads := kit.b("wood", Color(0.45, 0.25, 0.15))
	var dark := kit.b("wood", Color(0.2, 0.12, 0.08))
	for k in 10:
		var z := -0.115 + k * 0.0255
		wire.box(xf * at(0, 0.008, z), Vector3(0.19, 0.003, 0.003))
		var pushed := (k * 7) % 5
		for b in 10:
			var x := -0.085 + b * 0.012 + (0.06 if b >= 10 - pushed else 0.0)
			var m := dark if b == 4 or b == 5 else beads
			m.box(xf * at(x, 0.002, z), Vector3(0.011, 0.014, 0.016))


## The customers' control scales by the entrance: a ВНЦ dial scale on a
## little table, a plate «КОНТРОЛЬНЫЕ ВЕСЫ».
static func control_scales(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var wood := kit.b("wood")
	wood.box(at(0, 0.72, 0), Vector3(0.6, 0.03, 0.45))
	for o: Vector2 in [Vector2(-0.27, -0.19), Vector2(0.27, -0.19), Vector2(-0.27, 0.19), Vector2(0.27, 0.19)]:
		kit.b("chrome").box(at(o.x, 0, o.y), Vector3(0.025, 0.72, 0.025))
	var en := kit.b("enamel")
	en.box(at(0, 0.75, 0), Vector3(0.4, 0.08, 0.3), Color.WHITE, Rect2(0, 0.4, 1, 0.5))
	en.box(at(0, 0.83, 0.08), Vector3(0.12, 0.2, 0.08), Color.WHITE, Rect2(0, 0.4, 1, 0.5))
	# The round head with the dial on both faces (front faces -z).
	var head := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.17, 0.12))
	en.cylinder(head * at(0, -0.04, 0), 0.17, 0.17, 0.08, 16, Color.WHITE, Rect2(0, 0.4, 1, 0.5), Props.NO_RECT, false,
		false)
	var d := sub(cell("dial"), 0.0, 0.5)
	kit.b(TEX).disc(head * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -0.041, 0)), 0.155, 0, 16, Color.WHITE, d)
	kit.b(TEX).disc(head * at(0, 0.041, 0), 0.155, 0, 16, Color.WHITE, d)
	kit.b("chrome").cylinder(at(0, 0.83, -0.06), 0.13, 0.15, 0.02, 14)
	kit.b("white", Color(0.8, 0.9, 0.95, 0.15), Color.BLACK, Mats.GLASS).disc(
		head * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -0.043, 0)), 0.16, 0, 16)
	kit.build(root)
	Props.collider(root, Vector3.ZERO, Vector3(0.6, 0.9, 0.45))


## A plate on a wall: `which` is a cell, size in metres, facing `normal`.
static func plate(parent: Node3D, pos: Vector3, normal: Vector3, which: String, size: Vector2) -> void:
	var kit := MeshBuilder.Kit.new()
	var b := Basis.looking_at(-normal, Vector3.UP)
	kit.b(TEX).box(Transform3D(b, pos), Vector3(size.x, size.y, 0.012), Color.WHITE, cell(which), Vector2.ONE,
		MeshFactory.PZ)
	kit.b("paint", Color(0.3, 0.3, 0.3)).box(Transform3D(b, pos - normal * 0.002), Vector3(size.x + 0.02,
		size.y + 0.02, 0.008), Color.WHITE, Props.NO_RECT, Vector2.ONE, Props.SIDES)
	kit.build(parent, false)


## A printed carton, bottom-centred, its print on all four sides.
static func carton(kit: MeshBuilder.Kit, xf: Transform3D, size: Vector3, which: String) -> void:
	var mb := kit.b(TEX)
	mb.box(xf, size, Color.WHITE, cell(which), Vector2.ONE, Props.SIDES)
	mb.box(xf, size, Color(0.9, 0.9, 0.9), sub(cell(which), 0.0, 1.0, 0.42, 0.58), Vector2.ONE, MeshFactory.PY)


## A stack of cartons on a pallet.
static func carton_stack(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, yaw: float, layers: int) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var wood := kit.b("wood", Color(0.9, 0.8, 0.65))
	for i in 5:
		wood.box(at(-0.5 + i * 0.25, 0.11, 0), Vector3(0.1, 0.025, 1.0))
	for sx: float in [-0.5, 0.0, 0.5]:
		wood.box(at(sx, 0, 0), Vector3(0.1, 0.11, 1.0))
	var kinds := ["carton_fish", "carton_milk", "carton_tins"]
	var which: String = kinds[rng.randi() % kinds.size()]
	var s := Vector3(0.38, 0.28, 0.48)
	for l in layers:
		for i in 3:
			for j in 2:
				if l == layers - 1 and rng.randf() < 0.35:
					continue
				carton(kit, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.06, 0.06)),
					Vector3(-0.4 + i * 0.4, 0.135 + l * s.y, -0.25 + j * 0.5)), s, which)
	kit.build(root)
	Props.collider(root, Vector3.ZERO, Vector3(1.2, 0.135 + layers * s.y, 1.0))


## Wire crates of empty and full milk bottles, stacked.
static func bottle_crates(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, yaw: float, count: int) -> void:
	var root := Props.node(parent, pos, yaw)
	var kit := MeshBuilder.Kit.new()
	var wire := kit.b(TEX, Color.WHITE, Color.BLACK, Mats.DOUBLE)
	var gd := kit.b(Goods.TEX)
	var s := Vector3(0.4, 0.26, 0.6)
	for c in count:
		var o := Vector3((c % 2) * 0.42 - 0.21, (c / 2) * s.y, rng.randf_range(-0.02, 0.02))
		var xf := Transform3D(Basis(Vector3.UP, rng.randf_range(-0.05, 0.05)), o)
		wire.box(xf, s, Color.WHITE, cell("bottle_crate"), Vector2.ONE, Props.SIDES | MeshFactory.NY)
		for i in 4:
			for j in 6:
				if rng.randf() < 0.3:
					continue
				Goods.build(gd, xf * at(-0.15 + i * 0.1, 0.005, -0.25 + j * 0.1),
					"milk" if rng.randf() < 0.7 else "kefir")
	kit.build(root)
	Props.collider(root, Vector3.ZERO, Vector3(0.86, s.y * ceili(count / 2.0), 0.62))


## A flat decal on the floor: "puddle", "juice", "litter" or "boots".
static func decal(parent: Node3D, pos: Vector3, size: float, which: String, yaw: float,
		tint := Color.WHITE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mb := MeshBuilder.new()
	mb.ao_enabled = false
	var r: Rect2 = DECALS[which]
	var h := size * 0.5
	mb.quad(Transform3D.IDENTITY, [Vector3(-h, 0, h), Vector3(h, 0, h), Vector3(h, 0, -h), Vector3(-h, 0, -h)],
		[Vector2(r.position.x, r.end.y), r.end, Vector2(r.end.x, r.position.y), r.position], Color.WHITE, false)
	mi.mesh = mb.commit()
	mi.material_override = Mats.get_mat("decals", tint)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, 0.004, 0)
	mi.rotation.y = yaw
	parent.add_child(mi)
	return mi
