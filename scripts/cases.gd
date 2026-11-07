class_name Cases
extends RefCounted

## Refrigerated equipment of a 1980s universam, after the Ленторгмаш
## catalogue: the open dairy «горка» along the right wall (an enamelled
## cabinet with a tub at the bottom, three shelves, a canopy with a strip
## light and a fascia), the low-temperature glass counter along the left
## wall (sloped curved glass over frozen chickens, fish blocks, pelmeni and
## ice-cream) and what lies under the glass lids of the freezer chests.
## Goods come from Goods (scripts/goods.gd).

const ENAMEL := Color(0.86, 0.87, 0.83)
const INSIDE := Color(0.62, 0.7, 0.74)
const PRICE_RAIL := Color(0.75, 0.2, 0.15)


static func _xf(side: float, pos: Vector3) -> Transform3D:
	## Local frame of a wall unit: +x out of the wall into the aisle (`side`),
	## z along the wall.
	return Transform3D(Basis(Vector3(side, 0, 0), Vector3.UP, Vector3(0, 0, side)), pos)


## Open multi-deck dairy case, its back to the wall, facing `side` (+1 = +x).
## `light` is the row's tube material: the canopy strip goes out with the row.
static func dairy_case(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, length: float, side: float,
		light: Material) -> void:
	var root := Props.node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	var f := _xf(side, Vector3.ZERO)
	var en := kit.b("paint", ENAMEL)
	var inside := kit.b("paint", INSIDE)
	var ch := kit.b("chrome")
	var L := length
	var blender := Models.add(kit, "equip", "dairy_%d" % roundi(L * 1000.0), f)
	if not blender:
		# Plinth with the ventilation grille, the front of the tub.
		kit.b("rubber").box(f * Props.at(0.02, 0, 0), Vector3(0.74, 0.1, L - 0.02))
		en.box(f * Props.at(0.0, 0.1, 0), Vector3(0.8, 0.5, L), Color.WHITE, Props.NO_RECT, Vector2(0.6, 0.6),
			Props.ALL & ~MeshFactory.NY)
		kit.b("grille").box(f * Props.at(0.401, 0.14, 0), Vector3(0.004, 0.16, L - 0.2), Color(0.6, 0.6, 0.6), Props.FULL,
			Vector2.ONE, MeshFactory.PX)
		en.box(f * Props.at(0.37, 0.6, 0), Vector3(0.06, 0.08, L))
		ch.box(f * Props.at(0.4, 0.66, 0), Vector3(0.025, 0.03, L))
		# Back wall and the canopy over the top shelf.
		inside.box(f * Props.at(-0.36, 0.6, 0), Vector3(0.08, 1.5, L))
		en.box(f * Props.at(-0.33, 0.0, 0), Vector3(0.14, 2.25, L), Color.WHITE, Props.NO_RECT, Vector2(0.6, 0.6),
			MeshFactory.NX | MeshFactory.PY)
		en.box(f * Props.at(-0.05, 2.05, 0), Vector3(0.62, 0.2, L), Color.WHITE, Props.NO_RECT, Vector2(0.6, 0.6),
			Props.ALL)
		kit.b("paint", Color(0.55, 0.12, 0.1)).box(f * Props.at(0.265, 2.06, 0), Vector3(0.012, 0.18, L - 0.04))
	kit.b("sign:МОЛОКО").box(f * Props.at(0.275, 2.07, 0), Vector3(0.006, 0.16, minf(1.2, L * 0.4)), Color.WHITE,
		Props.FULL, Vector2.ONE, MeshFactory.PX)
	# The strip light under the canopy, behind an opal diffuser.
	kit.custom(light).box(f * Props.at(0.12, 2.03, 0), Vector3(0.1, 0.02, L - 0.1), Color.WHITE, Props.FULL,
		Vector2.ONE, MeshFactory.NY)
	if not blender:
		# End panels.
		for e: float in [-1.0, 1.0]:
			en.box(f * Props.at(-0.02, 0.0, e * (L * 0.5 - 0.015)), Vector3(0.78, 2.25, 0.03), Color.WHITE, Props.NO_RECT,
				Vector2(0.6, 0.6), Props.ALL)
		# The tub: crates of bottles and milk packs lying in wire baskets.
		inside.box(f * Props.at(0.0, 0.5, 0), Vector3(0.66, 0.02, L - 0.06))
	var gd := kit.b(Goods.TEX)
	var z := -L * 0.5 + 0.12
	while z < L * 0.5 - 0.3:
		var what: String = ["milk", "kefir", "tetra", "milk", "ryazhenka"][rng.randi() % 5]
		var s := Goods.size_of(what)
		var n_x := int(0.6 / (s.z + 0.01))
		var n_z := int(rng.randf_range(0.35, 0.75) / (s.x + 0.01))
		for i in n_x:
			for k in n_z:
				if rng.randf() < 0.18:
					continue
				var p := Vector3(-0.27 + i * (s.z + 0.01), 0.52, z + k * (s.x + 0.01) + s.x * 0.5)
				Goods.build(gd, f * Transform3D(Basis(Vector3.UP, PI * 0.5 + rng.randf_range(-0.2, 0.2)), p), what)
		z += n_z * (s.x + 0.01) + rng.randf_range(0.05, 0.3)
	# Three shelves stepping back towards the top, each with a price rail.
	var shelves := [[0.98, 0.5], [1.36, 0.42], [1.72, 0.36]]
	for sh: Array in shelves:
		var y: float = sh[0]
		var d: float = sh[1]
		var cx := -0.32 + d * 0.5
		if not blender:
			inside.box(f * Props.at(cx, y, 0), Vector3(d, 0.02, L - 0.06))
			kit.b("paint", PRICE_RAIL).box(f * Props.at(cx + d * 0.5, y - 0.03, 0), Vector3(0.012, 0.05, L - 0.06))
		var shelf := f * Transform3D(Basis(Vector3(0, 0, 1), Vector3.UP, Vector3(-1, 0, 0)),
			Vector3(cx + d * 0.5 - 0.01, y + 0.02, -(L * 0.5 - 0.05)))
		Props.fill_shelf(kit, rng, shelf, L - 0.1, d - 0.04, 0.32, "moloko")
	kit.build(root)
	Props.collider(root, Vector3.ZERO, Vector3(0.8, 2.25, L))


## Low-temperature counter with curved glass, its back to the wall, facing
## `side`. `stock` picks what lies inside.
static func frozen_counter(parent: Node3D, rng: RandomNumberGenerator, pos: Vector3, length: float, side: float,
		stock: Array) -> void:
	var root := Props.node(parent, pos)
	var kit := MeshBuilder.Kit.new()
	var f := _xf(side, Vector3.ZERO)
	var en := kit.b("paint", ENAMEL)
	var ch := kit.b("chrome")
	var L := length
	var blender := Models.add(kit, "equip", "frozen_%d" % roundi(L * 1000.0), f)
	if not blender:
		kit.b("rubber").box(f * Props.at(0.0, 0, 0), Vector3(0.8, 0.1, L - 0.02))
		en.box(f * Props.at(0.0, 0.1, 0), Vector3(0.86, 0.62, L), Color.WHITE, Props.NO_RECT, Vector2(0.6, 0.6),
			Props.ALL & ~MeshFactory.NY)
		kit.b("grille").box(f * Props.at(0.431, 0.14, 0), Vector3(0.004, 0.14, L - 0.3), Color(0.6, 0.6, 0.6), Props.FULL,
			Vector2.ONE, MeshFactory.PX)
		# A blue band with the maker's plate along the front.
		kit.b("paint", Color(0.2, 0.3, 0.5)).box(f * Props.at(0.431, 0.5, 0), Vector3(0.004, 0.08, L), Color.WHITE,
			Props.NO_RECT, Vector2.ONE, MeshFactory.PX)
		ch.box(f * Props.at(0.432, 0.62, -L * 0.35), Vector3(0.006, 0.05, 0.18))
		# The well: liner, frost on the floor, the goods.
		kit.b("paint", INSIDE).box(f * Props.at(0.0, 0.6, 0), Vector3(0.78, 0.02, L - 0.08), Color.WHITE, Props.NO_RECT,
			Vector2.ONE, MeshFactory.PY)
	var gd := kit.b(Goods.TEX)
	_pile(gd, rng, f, Vector3(-0.04, 0.62, 0), Vector2(0.66, L - 0.16), stock, 2)
	if not blender:
		# Frame of the glass: chrome uprights at the ends and the middle, the
		# front rail, the back rail.
		var g0 := Vector2(0.43, 0.72)  # front foot of the glass
		var g1 := Vector2(0.18, 1.22)  # top front edge
		var g2 := Vector2(-0.4, 1.22)  # top back edge
		for e: float in [-L * 0.5 + 0.02, 0.0, L * 0.5 - 0.02]:
			ch.box(f * Props.rot(Vector3.BACK, atan2(g1.x - g0.x, g1.y - g0.y) * -1.0,
				Vector3(g0.x, g0.y, e)), Vector3(0.02, g0.distance_to(g1), 0.02))
			ch.box(f * Props.at(-0.4, 0.72, e), Vector3(0.02, 0.5, 0.02))
		ch.box(f * Props.at(g0.x, g0.y - 0.02, 0), Vector3(0.03, 0.03, L))
		ch.box(f * Props.at((g1.x + g2.x) * 0.5, g1.y, 0), Vector3(g1.x - g2.x, 0.015, 0.02))
		ch.box(f * Props.at(g1.x, g1.y - 0.01, 0), Vector3(0.02, 0.02, L))
		ch.box(f * Props.at(-0.4, g2.y - 0.01, 0), Vector3(0.02, 0.02, L))
		# The glass: the sloped front bent in three facets, the flat top, the
		# sliding doors at the back.
		var glass := kit.b("white", Color(0.72, 0.86, 0.9, 0.3), Color.BLACK, Mats.GLASS)
		var bend := [g0, Vector2(0.4, 0.92), Vector2(0.32, 1.1), g1]
		for k in bend.size() - 1:
			var a: Vector2 = bend[k]
			var b: Vector2 = bend[k + 1]
			glass.quad(f, [Vector3(a.x, a.y, L * 0.5), Vector3(a.x, a.y, -L * 0.5), Vector3(b.x, b.y, -L * 0.5),
				Vector3(b.x, b.y, L * 0.5)], [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE)
		glass.quad(f, [Vector3(g1.x, g1.y, L * 0.5), Vector3(g1.x, g1.y, -L * 0.5), Vector3(g2.x, g2.y, -L * 0.5),
			Vector3(g2.x, g2.y, L * 0.5)], [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], Color.WHITE)
	# Price tags stuck inside the glass foot.
	var z := -L * 0.5 + 0.3
	while z < L * 0.5 - 0.2:
		kit.b("tags").box(f * Props.at(0.38, 0.66, z), Vector3(0.004, 0.045, 0.1), Color.WHITE, Props.tag_rect(rng),
			Vector2.ONE, MeshFactory.PX)
		z += rng.randf_range(0.5, 0.9)
	kit.build(root)
	Props.collider(root, Vector3.ZERO, Vector3(0.86, 1.25, L))


## Heaps goods on the floor of a well `area` (x across, y along z) centred
## on `c` in frame `f`, in loose rows, up to `layers` deep.
static func _pile(mb: MeshBuilder, rng: RandomNumberGenerator, f: Transform3D, c: Vector3, area: Vector2,
		stock: Array, layers: int) -> void:
	var z := -area.y * 0.5
	while z < area.y * 0.5 - 0.1:
		var what: String = stock[rng.randi() % stock.size()]
		var s := Goods.size_of(what)
		var run := minf(rng.randf_range(0.4, 1.0), area.y * 0.5 - z)
		var flat: bool = Goods.ITEMS[what][0] in ["box", "block"]
		var across := s.x if flat else s.z
		var along := s.z if flat else s.x
		var nx := maxi(1, int(area.x / (across + 0.015)))
		var nz := maxi(1, int(run / (along + 0.015)))
		for layer in layers:
			for i in nx:
				for k in nz:
					if layer > 0 and rng.randf() < 0.45:
						continue
					var p := c + Vector3(-area.x * 0.5 + (i + 0.5) * (across + 0.015) + rng.randf_range(-0.02, 0.02),
						layer * s.y * 0.85, z + (k + 0.5) * (along + 0.015))
					var yaw := (0.0 if flat else PI * 0.5) + rng.randf_range(-0.25, 0.25)
					var tilt := Basis(Vector3.RIGHT, rng.randf_range(-0.08, 0.08) * layer)
					Goods.build(mb, f * Transform3D(Basis(Vector3.UP, yaw) * tilt, p), what)
		z += nz * (along + 0.015) + 0.04


## What a freezer chest holds under its glass lids, for Props.chest.
const CHEST_STOCK := [
	["pelmeni", "pelmeni", "fish"],
	["chicken", "chicken"],
	["fish", "fish", "pelmeni"],
	["plombir", "plombir", "pelmeni"],
	["chicken", "fish"],
]
## The store's eight chests hold just what Gordeev finds in them on night
## one (NightOne.CHEST_TEXT, CLUE_CLIP): [goods, length of the chest they
## take from the far end, layers, width (whole width if left out)]. A4 is empty; D2 and D3 are built apart.
const CHEST_BY_ID := {
	"A1": [["butter"], 0.33, 1, 0.36],  # twelve packs (3 × 4) where there should be forty
	"A2": [["pelmeni"], 2.22, 2],
	"A3": [["pelmeni"], 2.22, 2],  # the clip goes between them (Store.lift_cloth)
	"A4": [[], 0.0, 0],
	"D1": [["fish"], 2.22, 1],  # cod in plain boxes
	"D4": [["plombir"], 1.1, 2],  # half the chest empty
}


static func chest_goods(kit: MeshBuilder.Kit, rng: RandomNumberGenerator, id := "") -> void:
	match id:
		"D2":
			_syrki(kit, rng)
			return
		"D3":
			_beef(kit, rng)
			return
	if id in CHEST_BY_ID:
		var spec: Array = CHEST_BY_ID[id]
		var length: float = spec[1]
		if length <= 0.0:
			return
		var width: float = spec[3] if spec.size() > 3 else 0.84
		_pile(kit.b(Goods.TEX), rng, Transform3D.IDENTITY, Vector3(0, 0.46, -1.11 + length * 0.5),
			Vector2(width, length), spec[0], spec[2])
		return
	var stock: Array = CHEST_STOCK[rng.randi() % CHEST_STOCK.size()]
	_pile(kit.b(Goods.TEX), rng, Transform3D.IDENTITY, Vector3(0, 0.46, 0), Vector2(0.84, 2.22), stock, 2)


## D2: curd snacks in foil, laid out in neat rows as on a counter.
static func _syrki(kit: MeshBuilder.Kit, rng: RandomNumberGenerator) -> void:
	var foil := kit.b("white", Color(0.78, 0.8, 0.84))
	var band := kit.b("white", Color(0.75, 0.15, 0.12))
	for i in 8:
		for k in 22:
			var p := Vector3(-0.36 + i * 0.103, 0.475, -1.05 + k * 0.1)
			var xf := Transform3D(Basis(Vector3.UP, rng.randf_range(-0.02, 0.02)), p)
			foil.box(xf, Vector3(0.085, 0.03, 0.045))
			band.box(xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.0155, 0)), Vector3(0.087, 0.002, 0.012))


## D3: four pieces of beef wrapped in brown paper, one with «Р.» in pencil
## (the mark is too small to see; it is in the line).
static func _beef(kit: MeshBuilder.Kit, rng: RandomNumberGenerator) -> void:
	var paper := kit.b("kraft", Color(0.72, 0.58, 0.42))
	for k in 4:
		var c := Vector3(rng.randf_range(-0.12, 0.12), 0.54, -0.8 + k * 0.52)
		paper.ellipsoid(Transform3D(Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)), c),
			Vector3(rng.randf_range(0.2, 0.26), 0.08, rng.randf_range(0.16, 0.2)), 14, 8)
