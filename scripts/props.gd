class_name Props
extends RefCounted

## Store furniture at the Silent Hill 1 budget: shelving with individual
## packs and tins, freezer chests with glass lids under draped cloths, tills,
## fluorescent fittings, the guard's desk. Each piece merges its parts into
## one mesh per material (see MeshBuilder.Kit). Collision is a plain box.

const NO_RECT := Rect2()
const FULL := Rect2(0, 0, 1, 1)
const ALL := MeshFactory.ALL
const SIDES := MeshFactory.PX | MeshFactory.NX | MeshFactory.PZ | MeshFactory.NZ

## What each aisle sells. Soviet shelves: long runs of one product and gaps.
## Goods are in Goods.ITEMS (scripts/goods.gd).
const RANGE := {
	"bakaleya": ["salt", "tea", "macaroni", "matches", "flour", "sugar", "chicory", "barley", "grechka", "psheno",
		"soda", "oil", "salt", "sugar", "macaroni", "gerkules", "vermishel", "kisel", "lavr", "coffee", "kakao",
		"pryaniki", "yubileynoe", "karamel", "palochki", "soap", "zubnoy"],
	"konservy": ["peas", "condensed", "tushonka", "kapusta", "kilka", "sprats", "ikra", "jar_tomato", "jar_birch",
		"jar_apple", "kilka", "kapusta", "jar_birch", "saira", "turist", "bychki", "baklazhan", "tomato_paste",
		"gorchitsa", "turist"],
	"moloko": ["milk", "milk", "kefir", "kefir", "ryazhenka", "smetana", "tetra", "tetra", "butter", "yogurt",
		"eggs", "eggs"],
	"zamorozka": ["kilka", "sprats", "kapusta", "jar_tomato", "peas", "ikra"],
	# Bread and drinks on the side of the left gondola that faces the freezers.
	"hleb": ["baton", "baton", "borodinsky", "kirpich", "kirpich", "bulka", "borodinsky", "buratino", "tarhun",
		"mineral", "mineral", "pryaniki"],
}

## Shapes that can stand on top of one another.
const STACKS := ["tin", "flat", "box", "loaf"]


static func at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(x, y, z))


static func rot(axis: Vector3, angle: float, pos: Vector3) -> Transform3D:
	return Transform3D(Basis(axis, angle), pos)


static func node(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	parent.add_child(n)
	return n


## Invisible box collider, bottom-centred.
static func collider(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	shape.shape = b
	shape.position = pos + Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	parent.add_child(body)


## One product standing on the shelf frame `xf` at local (x, y, z).
static func product(kit: MeshBuilder.Kit, xf: Transform3D, id: String, pos: Vector3, yaw: float) -> void:
	Goods.build(kit.b(Goods.TEX), xf * Transform3D(Basis(Vector3.UP, yaw), pos), id)


static func tag_rect(rng: RandomNumberGenerator) -> Rect2:
	var i := rng.randi_range(0, 31)
	return Rect2((i % 4) * 0.25, (i / 4) * 0.125, 0.25, 0.125)


## Fills a shelf board. Shelf frame: x along the board from its left end,
## y up from the board, z from the front edge towards the back.
static func fill_shelf(kit: MeshBuilder.Kit, rng: RandomNumberGenerator, xf: Transform3D, length: float,
		depth: float, clear: float, range_id: String) -> void:
	var choices: Array = RANGE[range_id]
	var x := 0.03
	while x < length - 0.08:
		if rng.randf() < 0.24:
			x += rng.randf_range(0.25, 0.9)
			continue
		var id: String = choices[rng.randi() % choices.size()]
		var size := Goods.size_of(id)
		var w := size.x
		var d := size.z
		var h := size.y
		var stacks: bool = Goods.ITEMS[id][0] in STACKS
		if h > clear:
			x += 0.1
			continue
		var end := minf(x + rng.randf_range(0.35, 1.3), length - 0.03)
		kit.b("tags").box(xf * at(x + 0.06, -0.05, -0.012), Vector3(0.1, 0.045, 0.004), Color.WHITE, tag_rect(rng),
			Vector2.ONE, MeshFactory.NZ)
		var rows := mini(int(depth / (d + 0.01)), 3)
		var stack := 1
		if stacks and h < 0.06:
			stack = mini(3, int(clear / h))
		elif stacks and h < 0.13 and clear > h * 2.0 + 0.03 and rng.randf() < 0.4:
			stack = 2
		var sold := rng.randf() < 0.3  # front row bought out
		while x + w <= end:
			for r in rows:
				if r == 0 and sold:
					continue
				var z := 0.02 + d * 0.5 + r * (d + 0.01)
				for s in stack:
					if s > 0 and rng.randf() < 0.2:
						break
					product(kit, xf, id, Vector3(x + w * 0.5 + rng.randf_range(-0.004, 0.004), s * h, z),
						rng.randf_range(-0.12, 0.12) if stacks or Goods.ITEMS[id][0] != "tetra" else rng.randf_range(-0.3, 0.3))
			x += w + 0.008
		x = end + 0.03


## A double-sided gondola segment, centred on `pos`, running along z.
## ranges = [what the -x side sells, what the +x side sells].
static func gondola(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, length: float, ranges: Array,
		end_front := false, end_back := false) -> void:
	var root := node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	var paint := kit.b("paint")
	var model := "gondola_%d" % roundi(length * 1000.0)
	var blender := Models.add(kit, "shelves", model, Transform3D.IDENTITY)
	if not blender:
		paint.box(at(0, 0, 0), Vector3(0.96, 0.12, length), Color(0.55, 0.6, 0.58), NO_RECT, Vector2(0.6, 0.6),
			ALL & ~MeshFactory.NY, 1.0)
		kit.b("pegboard").box(at(0, 0.12, 0), Vector3(0.05, 1.68, length), Color.WHITE, NO_RECT, Vector2(1.0, 1.0),
			SIDES, 0.6)
		for z: float in [-length * 0.5 + 0.025, length * 0.5 - 0.025]:
			paint.box(at(0, 0, z), Vector3(0.08, 1.85, 0.05))
		paint.box(at(0, 1.8, 0), Vector3(0.12, 0.05, length))
	var levels := [0.12, 0.52, 0.92, 1.32]
	for si in 2:
		var side := -1.0 if si == 0 else 1.0
		for li in levels.size():
			var y: float = levels[li]
			if not blender:
				_shelf_board(paint, Vector3(side * 0.235, y, 0), side, 0.42, length - 0.06)
			var top: float = levels[li + 1] if li + 1 < levels.size() else 1.82
			var xf := Transform3D(Basis(Vector3(0, 0, side), Vector3.UP, Vector3(-side, 0, 0)),
				Vector3(side * 0.445, y + 0.02, -side * (length * 0.5 - 0.04)))
			fill_shelf(kit, rng, xf, length - 0.08, 0.4, top - y - 0.05, ranges[si])
	for e in 2:
		if (e == 0 and end_front) or (e == 1 and end_back):
			var z := (-length * 0.5 - 0.02) if e == 0 else (length * 0.5 + 0.02)
			if not Models.add(kit, "shelves", "gondola_end", Transform3D(Basis(Vector3.UP, PI * e), Vector3(0, 0, z))):
				paint.box(at(0, 0, z), Vector3(1.0, 1.86, 0.04), Color(0.62, 0.66, 0.63), NO_RECT, Vector2(0.6, 0.6),
					ALL, 0.6)
	kit.build(root)
	collider(root, Vector3.ZERO, Vector3(1.0, 1.9, length))


## Shelf board with its front lip and end brackets, centred at `c`.
static func _shelf_board(paint: MeshBuilder, c: Vector3, side: float, depth: float, length: float) -> void:
	paint.box(at(c.x, c.y, c.z), Vector3(depth, 0.02, length), Color(0.62, 0.66, 0.63))
	paint.box(at(c.x + side * (depth * 0.5 + 0.006), c.y - 0.03, c.z), Vector3(0.012, 0.05, length), Color(0.78, 0.8, 0.77))
	for z: float in [-length * 0.5 + 0.02, length * 0.5 - 0.02]:
		paint.box(at(c.x, c.y - 0.07, z), Vector3(depth - 0.04, 0.07, 0.012), Color(0.5, 0.52, 0.5))


## Wall shelving, one-sided, its back against the wall; `side` is the
## direction it faces (+1 towards +x).
static func wall_shelf(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, length: float, side: float,
		range_id: String) -> void:
	var root := node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	var paint := kit.b("paint")
	var blender := Models.add(kit, "shelves", "wall_%d" % roundi(length * 1000.0),
		Transform3D(Basis(Vector3.UP, 0.0 if side > 0.0 else PI), Vector3.ZERO))
	if not blender:
		paint.box(at(side * 0.03, 0, 0), Vector3(0.74, 0.12, length), Color(0.5, 0.55, 0.53), NO_RECT, Vector2(0.6, 0.6),
			ALL & ~MeshFactory.NY, 1.0)
		kit.b("pegboard").box(at(-side * 0.37, 0.12, 0), Vector3(0.05, 2.0, length), Color(0.95, 0.95, 0.9), NO_RECT,
			Vector2(1.0, 1.0), SIDES, 0.6)
		for z: float in [-length * 0.5 + 0.02, length * 0.5 - 0.02]:
			paint.box(at(0, 0, z), Vector3(0.8, 2.2, 0.04), Color(0.6, 0.64, 0.61), NO_RECT, Vector2(0.6, 0.6), ALL, 0.6)
		paint.box(at(0, 2.15, 0), Vector3(0.8, 0.05, length))
	var levels := [0.12, 0.52, 0.92, 1.32, 1.72]
	for li in levels.size():
		var y: float = levels[li]
		if not blender:
			_shelf_board(paint, Vector3(side * 0.03, y, 0), side, 0.72, length - 0.08)
		var top: float = levels[li + 1] if li + 1 < levels.size() else 2.15
		var xf := Transform3D(Basis(Vector3(0, 0, side), Vector3.UP, Vector3(-side, 0, 0)),
			Vector3(side * 0.39, y + 0.02, -side * (length * 0.5 - 0.05)))
		fill_shelf(kit, rng, xf, length - 0.1, 0.62, top - y - 0.05, range_id)
	kit.build(root)
	collider(root, Vector3.ZERO, Vector3(0.8, 2.2, length))


## A stepped pyramid of one product on a low stand, the shop-window trick
## for whatever arrived in bulk.
static func pyramid(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, id: String, base: int) -> void:
	var root := node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	var size := Goods.size_of(id)
	var w := size.x + 0.006
	var span := base * w
	kit.b("cardboard").box(at(0, 0, 0), Vector3(span + 0.1, 0.12, span + 0.1), Color(0.8, 0.8, 0.8), NO_RECT,
		Vector2(0.6, 0.6))
	for lvl in base:
		var n := base - lvl
		for i in n:
			for j in n:
				var off := Vector3((i - (n - 1) * 0.5) * w, 0.12 + lvl * size.y, (j - (n - 1) * 0.5) * w)
				product(kit, Transform3D.IDENTITY, id, off, rng.randf_range(-0.3, 0.3))
	kit.build(root)
	collider(root, Vector3.ZERO, Vector3(span, 0.12 + base * size.y, span))


## Red-on-white aisle sign hanging from the ceiling on two wires.
static func aisle_sign(parent: Node3D, pos: Vector3, text: String, ceiling: float) -> void:
	var kit := MeshBuilder.Kit.new()
	kit.b("sign:" + text).box(at(pos.x, pos.y, pos.z), Vector3(1.3, 0.32, 0.02), Color.WHITE, FULL, Vector2.ONE,
		MeshFactory.PZ | MeshFactory.NZ)
	kit.b("paint", Color(0.4, 0.1, 0.07)).box(at(pos.x, pos.y - 0.02, pos.z), Vector3(1.34, 0.02, 0.03))
	for dx: float in [-0.5, 0.5]:
		kit.b("chrome").box(at(pos.x + dx, pos.y + 0.32, pos.z), Vector3(0.008, ceiling - pos.y - 0.32, 0.008))
	kit.build(parent, false)


## Two-tube fluorescent fitting (ЛПО) under the ceiling: a sheet-steel
## body with sloped reflector sides, end caps with the tube holders, a grid of
## white louvres under the tubes, dead flies in it. The tubes use the row's
## shared material so the whole row switches together.
static func fixture(parent: Node3D, pos: Vector3, tube_mat: Material) -> void:
	var kit := MeshBuilder.Kit.new()
	var body := kit.b("paint", Color(0.86, 0.87, 0.84))
	body.box(at(pos.x, pos.y, pos.z), Vector3(0.3, 0.07, 1.3))
	for sx: float in [-1.0, 1.0]:
		body.box(rot(Vector3.BACK, -sx * 0.5, Vector3(pos.x + sx * 0.14, pos.y - 0.06, pos.z)), Vector3(0.008, 0.08, 1.28))
	for sz: float in [-0.635, 0.635]:
		body.box(at(pos.x, pos.y - 0.08, pos.z + sz), Vector3(0.34, 0.08, 0.03))
		kit.b("white", Color(0.75, 0.73, 0.68)).box(at(pos.x, pos.y - 0.05, pos.z + sz * 0.97), Vector3(0.16, 0.03, 0.02))
	var louvre := kit.b("paint", Color(0.92, 0.92, 0.9))
	for sx: float in [-0.165, 0.165]:
		louvre.box(at(pos.x + sx, pos.y - 0.085, pos.z), Vector3(0.01, 0.035, 1.24))
	var k := -0.56
	while k < 0.57:
		louvre.box(at(pos.x, pos.y - 0.085, pos.z + k), Vector3(0.33, 0.035, 0.006))
		k += 0.08
	var flies := kit.b("white", Color(0.05, 0.04, 0.03))
	for f in 5:
		var h := float((int(pos.x * 13.0 + pos.z * 7.0) + f * 37) % 100) / 100.0
		flies.box(at(pos.x - 0.1 + h * 0.2, pos.y - 0.088, pos.z - 0.5 + fmod(h * 7.3, 1.0)), Vector3(0.01, 0.003, 0.006))
	var tubes := kit.custom(tube_mat)
	for sx: float in [-0.06, 0.06]:
		tubes.cylinder(rot(Vector3.RIGHT, PI * 0.5, pos + Vector3(sx, -0.035, -0.6)), 0.013, 0.013, 1.2, 8,
			Color.WHITE, FULL, NO_RECT, false, false, false)
	kit.build(parent, false)


## The frost and the goods in a freezer chest, as one node (root's meta
## "contents"); by day the store rebuilds them as a shop's ordinary stock.
static func chest_contents(root: Node3D, rng: RandomNumberGenerator, id := "") -> Node3D:
	var inside := MeshBuilder.Kit.new()
	if id == "":
		inside.b("frozen").box(at(0, 0.45, 0), Vector3(0.88, 0.02, 2.28), Color.WHITE, NO_RECT, Vector2(0.5, 0.5),
			MeshFactory.PY, 0.6)
	else:
		# Plain white frost: the «frozen» picture is packs of goods itself, and
		# these chests hold only what Gordeev says is in them.
		inside.b("white", Color(0.86, 0.9, 0.93)).box(at(0, 0.45, 0), Vector3(0.88, 0.02, 2.28), Color.WHITE,
			NO_RECT, Vector2.ONE, MeshFactory.PY)
		if id == "A4":
			# Frost wiped off the bottom by a broad palm.
			var wipe := inside.b("galv", Color(0.74, 0.77, 0.8))
			for k in 4:
				wipe.box(rot(Vector3.UP, 0.08 * k - 0.12, Vector3(-0.1 + 0.075 * k, 0.471, 0.1 * k - 0.1)),
					Vector3(0.065, 0.002, 0.5), Color.WHITE, NO_RECT, Vector2.ONE, MeshFactory.PY)
	Cases.chest_goods(inside, rng, id)
	var contents := Node3D.new()
	contents.name = "Contents"
	root.add_child(contents)
	inside.build(contents, false)
	root.set_meta("contents", contents)
	return contents


## Enamel freezer chest with a chrome rim and two sliding glass lids over the
## frozen goods. Returns the draped cloth node (hidden when lifted). The frost
## and what lies on it (Cases.chest_goods, by the chest's id, so it is what
## Gordeev says he sees) are their own node, root's meta "contents".
static func chest(root: Node3D, rng: RandomNumberGenerator, id := "") -> Node3D:
	var kit := MeshBuilder.Kit.new()
	kit.b("enamel").box(at(0, 0, 0), Vector3(1.0, 0.72, 2.4), Color.WHITE, NO_RECT, Vector2(1.2, 0.72), SIDES, 0.5)
	kit.b("rubber").box(at(0, 0, 0), Vector3(0.94, 0.06, 2.34), Color.WHITE, NO_RECT, Vector2.ONE, SIDES)
	var liner := kit.b("enamel", Color(0.85, 0.88, 0.9))
	for x: float in [-0.47, 0.47]:
		liner.box(at(x, 0.45, 0), Vector3(0.06, 0.27, 2.34), Color.WHITE, Rect2(0, 0.5, 1, 0.4))
	for z: float in [-1.17, 1.17]:
		liner.box(at(0, 0.45, z), Vector3(0.88, 0.27, 0.06), Color.WHITE, Rect2(0, 0.5, 1, 0.4))
	# The metal tub under the frost (seen when it is scraped clean).
	kit.b("galv", Color(0.7, 0.72, 0.74)).box(at(0, 0.44, 0), Vector3(0.88, 0.01, 2.28), Color.WHITE, NO_RECT,
		Vector2.ONE, MeshFactory.PY)
	chest_contents(root, rng, id)
	var ch := kit.b("chrome")
	for x: float in [-0.49, 0.49]:
		ch.box(at(x, 0.72, 0), Vector3(0.04, 0.035, 2.42))
	for z: float in [-1.19, 1.19]:
		ch.box(at(0, 0.72, z), Vector3(1.02, 0.035, 0.04))
	ch.box(at(0, 0.72, 0), Vector3(0.9, 0.03, 0.03))
	var glass := kit.b("white", Color(0.7, 0.85, 0.95, 0.2), Color.BLACK, Mats.GLASS)
	glass.box(at(0, 0.745, -0.6), Vector3(0.94, 0.005, 1.18), Color.WHITE, NO_RECT, Vector2.ONE, MeshFactory.PY)
	glass.box(at(0, 0.76, 0.6), Vector3(0.94, 0.005, 1.18), Color.WHITE, NO_RECT, Vector2.ONE, MeshFactory.PY)
	for x: float in [-0.505, 0.505]:
		kit.b("grille").box(at(x, 0.08, 0.7), Vector3(0.01, 0.14, 0.7), Color.WHITE, FULL, Vector2.ONE,
			MeshFactory.PX | MeshFactory.NX)
	kit.build(root)

	var cloth := Node3D.new()
	root.add_child(cloth)
	var ck := MeshBuilder.Kit.new()
	ck.ao = false
	var mb := ck.b("cloth", Color.WHITE, Color.BLACK, Mats.DOUBLE)
	var hx := 0.54
	var hz := 1.24
	var top := 0.8
	var rows: Array = []
	var nx := 9
	var nz := 20
	for j in nz + 1:
		var row := PackedVector3Array()
		var z := lerpf(-hz, hz, float(j) / nz)
		for i in nx + 1:
			var x := lerpf(-hx, hx, float(i) / nx)
			var edge := maxf(absf(x) / hx, absf(z) / hz)
			var y := top - pow(edge, 6.0) * 0.02 + sin(z * 5.0 + x * 3.0) * 0.006 + rng.randf_range(-0.004, 0.004)
			row.append(Vector3(x, y, z))
		rows.append(row)
	mb.sheet(Transform3D.IDENTITY, rows, Color.WHITE, 0.5)
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for e in 4:
		var a: Vector3 = corners[e]
		var b: Vector3 = corners[(e + 1) % 4]
		var out := (a + b).normalized() * Vector3(1, 0, 1)
		out = Vector3(signf(out.x) if absf(a.x - b.x) < 0.01 else 0.0, 0, signf(out.z) if absf(a.z - b.z) < 0.01 else 0.0)
		var along := (b - a).normalized()
		_skirt(mb, rng, a - along * 0.02, b + along * 0.02, out, top - 0.02, rng.randf_range(0.28, 0.4))
	ck.build(cloth)
	return cloth


static func _skirt(mb: MeshBuilder, rng: RandomNumberGenerator, a: Vector3, b: Vector3, out: Vector3, top_y: float,
		hem_y: float) -> void:
	var length := a.distance_to(b)
	var n := maxi(2, ceili(length / 0.1))
	var phase := rng.randf() * TAU
	var freq := rng.randf_range(10.0, 16.0)
	var rows: Array = []
	for j in 6:
		var t := j / 5.0
		var row := PackedVector3Array()
		for i in n + 1:
			var s := float(i) / n
			var p := a.lerp(b, s)
			var hem := hem_y + sin(s * 6.0 + phase) * 0.05 + sin(s * 19.0) * 0.015
			var fold := sin(s * length * freq + phase) * 0.025 * t
			p += out * (0.015 + t * t * 0.06 + fold)
			p.y = lerpf(top_y, hem, t)
			row.append(p)
		rows.append(row)
	mb.sheet(Transform3D.IDENTITY, rows, Color(0.92, 0.92, 0.92), 0.5)


## Checkout counter with a Soviet electromechanical till and dial scales.
## The cashier's side (with the keys) faces +x.
static func checkout(parent: Node3D, pos: Vector3) -> void:
	var root := node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	kit.b("wood").box(at(0, 0.1, 0), Vector3(0.96, 0.75, 2.5), Color.WHITE, NO_RECT, Vector2(1.0, 0.75), SIDES, 0.5)
	kit.b("rubber").box(at(0, 0, 0), Vector3(0.9, 0.1, 2.44), Color.WHITE, NO_RECT, Vector2.ONE, SIDES)
	kit.b("formica").box(at(0, 0.85, 0), Vector3(1.04, 0.04, 2.56), Color.WHITE, NO_RECT, Vector2(0.5, 0.5))
	var ch := kit.b("chrome")
	for sx: float in [-0.525, 0.525]:
		ch.box(at(sx, 0.84, 0), Vector3(0.015, 0.06, 2.56))
	ch.box(at(-0.52, 0.89, 0.3), Vector3(0.02, 0.02, 1.6))
	for sz: float in [-0.48, 1.08]:
		ch.box(at(-0.52, 0.89, sz), Vector3(0.02, 0.1, 0.02))
	# Till: body, sloping keyboard towards the cashier, display tower, drawer.
	var till := kit.b("register")
	till.box(at(0.15, 0.89, -0.3), Vector3(0.42, 0.17, 0.42), Color.WHITE, FULL)
	till.box(at(0.08, 1.06, -0.3), Vector3(0.12, 0.17, 0.3), Color(0.9, 0.9, 0.9), FULL)
	kit.b("keys").box(rot(Vector3.BACK, -0.45, Vector3(0.3, 1.0, -0.3)), Vector3(0.14, 0.03, 0.34), Color.WHITE, FULL,
		Vector2.ONE, MeshFactory.PY)
	var disp := kit.b("display", Color.WHITE, Color(0.25, 0.7, 0.4))
	disp.box(at(0.143, 1.11, -0.3), Vector3(0.005, 0.07, 0.24), Color.WHITE, FULL, Vector2.ONE, MeshFactory.PX)
	disp.box(at(0.017, 1.11, -0.3), Vector3(0.005, 0.07, 0.24), Color.WHITE, FULL, Vector2.ONE, MeshFactory.NX)
	kit.b("register", Color(0.7, 0.7, 0.68)).box(at(0.37, 0.9, -0.3), Vector3(0.02, 0.08, 0.36), Color.WHITE, FULL)
	# Scales: enamel body, chrome pan, round dial facing the customer.
	var en := kit.b("enamel")
	en.box(at(0.05, 0.89, 0.65), Vector3(0.3, 0.07, 0.34), Color.WHITE, Rect2(0, 0.4, 1, 0.5))
	en.box(at(-0.08, 0.89, 0.65), Vector3(0.07, 0.3, 0.26), Color.WHITE, Rect2(0, 0.4, 1, 0.5))
	ch.cylinder(at(0.08, 0.96, 0.65), 0.14, 0.15, 0.015, 10, Color.WHITE)
	kit.b("clock").cylinder(rot(Vector3.BACK, PI * 0.5, Vector3(-0.115, 1.07, 0.65)), 0.11, 0.11, 0.01, 12,
		Color(0.4, 0.4, 0.4), FULL, FULL, true, false, false)
	# Cashier's stool on the +x side.
	var legs := kit.b("chrome")
	for o: Vector2 in [Vector2(-0.14, -0.14), Vector2(0.14, -0.14), Vector2(-0.14, 0.14), Vector2(0.14, 0.14)]:
		legs.box(at(0.85 + o.x, 0, -0.5 + o.y), Vector3(0.025, 0.55, 0.025))
	kit.b("leather").cylinder(at(0.85, 0.55, -0.5), 0.19, 0.19, 0.05, 10, Color.WHITE, FULL, FULL)
	kit.build(root)
	collider(root, Vector3.ZERO, Vector3(1.0, 0.9, 2.5))


## Guard booth furniture: desk with drawers, chair, rotary phone, radio,
## logbook, desk lamp, thermos, a wall calendar, glazing.
static func booth(parent: Node3D, rect: Rect2) -> void:
	var kit := MeshBuilder.Kit.new()
	var wood := kit.b("wood")
	var dark := kit.b("wood", Color(0.7, 0.62, 0.55))
	var ch := kit.b("chrome")
	# Desk along the right wall: top, drawer pedestal at the near end, legs.
	wood.box(at(11.15, 0.74, 2.1), Vector3(1.1, 0.04, 2.6), Color.WHITE, NO_RECT, Vector2(0.8, 0.8))
	dark.box(at(11.15, 0, 1.15), Vector3(1.0, 0.74, 0.6), Color.WHITE, NO_RECT, Vector2(0.8, 0.8), ALL, 0.5)
	for i in 3:
		var y := 0.06 + i * 0.23
		dark.box(at(10.645, y, 1.15), Vector3(0.012, 0.2, 0.54), Color(1.1, 1.05, 1.0), NO_RECT, Vector2(0.5, 0.5),
			MeshFactory.NX | MeshFactory.PY | MeshFactory.NY | MeshFactory.PZ | MeshFactory.NZ)
		ch.box(at(10.632, y + 0.1, 1.15), Vector3(0.015, 0.02, 0.12))
	for z: float in [1.5, 3.33]:
		dark.box(at(10.65, 0, z), Vector3(0.05, 0.74, 0.05))
		dark.box(at(11.65, 0, z), Vector3(0.05, 0.74, 0.05))
	dark.box(at(11.65, 0.3, 2.4), Vector3(0.03, 0.4, 1.8))
	# Chair.
	wood.box(at(10.2, 0.44, 2.2), Vector3(0.42, 0.035, 0.42))
	wood.box(at(9.98, 0.5, 2.2), Vector3(0.03, 0.42, 0.38))
	for o: Vector2 in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
		ch.box(at(10.2 + o.x, 0, 2.2 + o.y), Vector3(0.025, 0.44, 0.025))
	# Rotary phone: dark red body, tilted dial towards the chair, handset on the cradle.
	var red := kit.b("white", Color(0.42, 0.09, 0.07))
	red.box(at(11.1, 0.76, 1.2), Vector3(0.24, 0.07, 0.21))
	red.box(rot(Vector3.BACK, 0.25, Vector3(11.09, 0.83, 1.2)), Vector3(0.17, 0.05, 0.17))
	kit.b("dial").cylinder(rot(Vector3.BACK, 0.45, Vector3(11.03, 0.865, 1.2)), 0.06, 0.06, 0.008, 12, Color.WHITE,
		Rect2(0, 0.45, 1, 0.1), FULL)
	red.box(at(11.14, 0.9, 1.2), Vector3(0.05, 0.03, 0.24))
	for z: float in [1.09, 1.31]:
		red.box(at(11.14, 0.875, z), Vector3(0.07, 0.04, 0.06))
	# Radio "Альпинист" with a grille facing the chair.
	wood.box(at(11.3, 0.76, 2.2), Vector3(0.16, 0.2, 0.32), Color(0.75, 0.55, 0.42))
	kit.b("grille").box(at(11.218, 0.78, 2.15), Vector3(0.005, 0.15, 0.2), Color.WHITE, FULL, Vector2.ONE, MeshFactory.NX)
	ch.cylinder(rot(Vector3.BACK, PI * 0.5, Vector3(11.222, 0.86, 2.31)), 0.018, 0.018, 0.02, 6, Color.WHITE)
	# Logbook, open: a thick ledger in a dark red cover on the desk, its white
	# pages a little lit by the lamp so it stands out from the wood.
	var cover := kit.b("white", Color(0.5, 0.1, 0.07))
	cover.box(at(10.9, 0.76, 2.6), Vector3(0.32, 0.016, 0.46))
	cover.box(at(10.9, 0.76, 2.6), Vector3(0.3, 0.034, 0.03))  # the spine
	var pages := kit.b("tags", Color(1.1, 1.1, 1.05), Color(0.1, 0.1, 0.09))
	pages.box(rot(Vector3.UP, 0.02, Vector3(10.9, 0.776, 2.49)), Vector3(0.29, 0.024, 0.2), Color.WHITE,
		Rect2(0, 0, 1, 0.5), Vector2.ONE, MeshFactory.PY | MeshFactory.NX | MeshFactory.PX | MeshFactory.NZ)
	pages.box(rot(Vector3.UP, -0.02, Vector3(10.9, 0.776, 2.71)), Vector3(0.29, 0.024, 0.2), Color.WHITE,
		Rect2(0, 0.5, 1, 0.5), Vector2.ONE, MeshFactory.PY | MeshFactory.NX | MeshFactory.PX | MeshFactory.PZ)
	kit.b("white", Color(0.1, 0.1, 0.3)).box(rot(Vector3.UP, 0.6, Vector3(10.95, 0.802, 2.79)), Vector3(0.01, 0.008, 0.14))
	# Desk lamp: base, stem, green cone shade lit from inside.
	var green := kit.b("paint", Color(0.55, 0.85, 0.6))
	green.cylinder(at(11.35, 0.76, 3.05), 0.08, 0.07, 0.025, 10, Color.WHITE)
	ch.box(rot(Vector3.BACK, 0.25, Vector3(11.35, 0.78, 3.05)), Vector3(0.015, 0.4, 0.015))
	kit.b("paint", Color(0.55, 0.85, 0.6), Color(0.25, 0.18, 0.08), Mats.DOUBLE).cylinder(
		at(11.25, 1.04, 3.0), 0.13, 0.05, 0.14, 10, Color.WHITE, Rect2(0, 0, 1, 1), NO_RECT, true)
	# Thermos and a glass in a podstakannik.
	green.cylinder(at(11.45, 0.76, 1.65), 0.05, 0.045, 0.3, 8, Color(0.6, 0.7, 1.0))
	ch.cylinder(at(11.0, 0.76, 1.7), 0.035, 0.04, 0.1, 8, Color.WHITE)
	# Calendar on the wall and a shelf of key boards.
	kit.b("calendar").box(at(11.96, 1.25, 3.7), Vector3(0.008, 0.6, 0.4), Color.WHITE, FULL, Vector2.ONE, MeshFactory.NX)
	# Key board: a varnished plank with two rows of hooks, keys with
	# numbered plywood tags, two hooks empty.
	dark.box(at(11.975, 1.3, 1.3), Vector3(0.03, 0.5, 0.75))
	var tags := kit.b("wood", Color(1.1, 1.0, 0.85))
	for i in 10:
		var kz := 1.0 + (i % 5) * 0.15
		var ky := 1.72 - (i / 5) * 0.22
		ch.box(at(11.955, ky, kz), Vector3(0.03, 0.008, 0.008))
		if i == 3 or i == 7:
			continue
		ch.box(at(11.945, ky - 0.08, kz), Vector3(0.004, 0.07, 0.018))
		tags.box(at(11.948, ky - 0.13, kz), Vector3(0.006, 0.05, 0.035))
	# Electric kettle, a newspaper, a fire extinguisher in the corner, the
	# guard's coat on a hook.
	var en := kit.b("enamel", Color(0.75, 0.82, 0.9))
	en.cylinder(at(11.45, 0.76, 2.75), 0.075, 0.065, 0.19, 10)
	en.box(rot(Vector3.BACK, 0.6, Vector3(11.37, 0.86, 2.75)), Vector3(0.02, 0.09, 0.02))
	kit.b("rubber").box(at(11.53, 0.84, 2.75), Vector3(0.02, 0.11, 0.025))
	kit.b("white", Color(0.86, 0.84, 0.76)).box(rot(Vector3.UP, 0.3, Vector3(10.95, 0.762, 3.25)),
		Vector3(0.3, 0.006, 0.42))
	kit.b("paint", Color(0.7, 0.1, 0.07)).cylinder(at(11.6, 0.0, 4.5), 0.08, 0.08, 0.5, 10)
	kit.b("rubber").cylinder(at(11.6, 0.5, 4.5), 0.03, 0.02, 0.08, 8)
	kit.b("rubber").box(rot(Vector3.BACK, 0.4, Vector3(11.52, 0.52, 4.5)), Vector3(0.018, 0.25, 0.018))
	ch.box(at(11.97, 1.75, 4.2), Vector3(0.06, 0.015, 0.015))
	var coat := kit.b("quilted", Color(0.55, 0.52, 0.45))
	coat.box(at(11.9, 0.95, 4.2), Vector3(0.12, 0.72, 0.42), Color.WHITE, NO_RECT, Vector2(0.6, 0.6))
	coat.box(rot(Vector3.RIGHT, 0.5, Vector3(11.9, 1.62, 4.02)), Vector3(0.1, 0.12, 0.08))
	coat.box(rot(Vector3.RIGHT, -0.5, Vector3(11.9, 1.62, 4.38)), Vector3(0.1, 0.12, 0.08))
	coat.box(at(11.9, 1.6, 4.2), Vector3(0.1, 0.14, 0.3))
	# Glazing above the low walls.
	var glass := kit.b("white", Color(0.65, 0.75, 0.8, 0.16), Color.BLACK, Mats.GLASS)
	glass.box(at(rect.position.x + rect.size.x * 0.5, 1.1, rect.end.y), Vector3(rect.size.x, 1.1, 0.01), Color.WHITE,
		NO_RECT, Vector2.ONE, MeshFactory.PZ)
	glass.box(at(rect.position.x, 1.1, 1.2), Vector3(0.01, 1.1, 2.0), Color.WHITE, NO_RECT, Vector2.ONE, MeshFactory.NX)
	glass.box(at(rect.position.x, 1.1, 4.0), Vector3(0.01, 1.1, 1.6), Color.WHITE, NO_RECT, Vector2.ONE, MeshFactory.NX)
	kit.build(parent)
	collider(parent, Vector3(11.15, 0, 2.1), Vector3(1.1, 0.78, 2.6))


## Stack of red plastic baskets by the entrance.
static func baskets(parent: Node3D, pos: Vector3, count: int) -> void:
	var kit := MeshBuilder.Kit.new()
	var red := kit.b("basket", Color.WHITE, Color.BLACK, Mats.DOUBLE)
	for i in count:
		var y := pos.y + i * 0.07
		red.box(at(pos.x, y, pos.z), Vector3(0.46 + i * 0.002, 0.22, 0.32 + i * 0.002), Color.WHITE, NO_RECT,
			Vector2(0.46, 0.22), SIDES | MeshFactory.NY)
	var ch := kit.b("chrome")
	for sx: float in [-0.12, 0.12]:
		ch.box(rot(Vector3.BACK, sx * 2.0, Vector3(pos.x + sx, pos.y + count * 0.07 + 0.15, pos.z)), Vector3(0.012, 0.12, 0.3))
	kit.build(parent)
	collider(parent, pos, Vector3(0.5, 0.22 + count * 0.07, 0.36))


## Back-of-store clutter: a pallet of sacks, a trolley of boxes, a mop bucket.
static func clutter(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var kit := MeshBuilder.Kit.new()
	var wood := kit.b("wood", Color(0.9, 0.8, 0.65))
	var p := Vector3(-8.0, 0, 27.1)
	for i in 5:
		wood.box(at(p.x - 0.5 + i * 0.25, 0.1, p.z), Vector3(0.1, 0.03, 1.0))
	for sx: float in [-0.55, 0.0, 0.55]:
		wood.box(at(p.x + sx, 0, p.z), Vector3(0.1, 0.1, 1.0))
	var sack := kit.b("cloth", Color(1.0, 0.95, 0.8))
	for i in 6:
		var o := Vector3((i % 2) * 0.55 - 0.27, 0.13 + (i / 2) * 0.18, rng.randf_range(-0.05, 0.05))
		sack.box(rot(Vector3.UP, rng.randf_range(-0.15, 0.15), p + o), Vector3(0.5, 0.18, 0.85), Color.WHITE, NO_RECT,
			Vector2(0.6, 0.6))
	collider(parent, p, Vector3(1.2, 0.7, 1.0))
	# Trolley with boxes.
	var t := Vector3(2.0, 0, 27.2)
	var ch := kit.b("chrome")
	ch.box(at(t.x, 0.12, t.z), Vector3(0.6, 0.03, 0.9))
	ch.box(at(t.x, 0.12, t.z + 0.45), Vector3(0.6, 0.9, 0.03))
	for o: Vector2 in [Vector2(-0.25, -0.38), Vector2(0.25, -0.38), Vector2(-0.25, 0.38), Vector2(0.25, 0.38)]:
		kit.b("rubber").cylinder(rot(Vector3.BACK, PI * 0.5, Vector3(t.x + o.x + 0.02, 0.05, t.z + o.y)), 0.05, 0.05, 0.04,
			6, Color.WHITE)
	var card := kit.b("cardboard")
	card.box(at(t.x, 0.15, t.z), Vector3(0.55, 0.4, 0.6), Color.WHITE, NO_RECT, Vector2(0.6, 0.6))
	card.box(rot(Vector3.UP, 0.2, Vector3(t.x, 0.55, t.z + 0.05)), Vector3(0.45, 0.3, 0.5), Color(0.9, 0.9, 0.9), NO_RECT,
		Vector2(0.6, 0.6))
	collider(parent, t, Vector3(0.6, 0.85, 0.9))
	# Boxes and a mop bucket.
	card.box(at(-3.5, 0, 27.3), Vector3(1.2, 0.8, 0.8), Color.WHITE, NO_RECT, Vector2(0.8, 0.8), ALL, 0.5)
	card.box(rot(Vector3.UP, -0.15, Vector3(-3.4, 0.8, 27.3)), Vector3(0.8, 0.5, 0.7), Color(0.9, 0.9, 0.9), NO_RECT,
		Vector2(0.8, 0.8))
	collider(parent, Vector3(-3.5, 0, 27.3), Vector3(1.2, 1.3, 0.8))
	var b := Vector3(5.2, 0, 27.5)
	kit.b("paint", Color(0.6, 0.65, 0.9)).cylinder(at(b.x, 0, b.z), 0.15, 0.18, 0.3, 10, Color.WHITE)
	kit.b("wood", Color(1.0, 0.9, 0.7)).box(rot(Vector3.BACK, 0.2, Vector3(b.x, 0.05, b.z)), Vector3(0.03, 1.3, 0.03))
	kit.b("cloth", Color(0.6, 0.55, 0.45)).box(at(b.x, 0.12, b.z), Vector3(0.18, 0.15, 0.18))
	kit.build(parent)
