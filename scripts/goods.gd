class_name Goods
extends RefCounted

## What the shelves, counters and chests of «Кировский» hold in October 1988,
## as real shapes: tins with rolled rims and lids, three-litre jars with the
## juice showing through the glass, milk bottles with foil caps, triangular
## milk packs, card packs, paper bags folded at the top, blocks of matches,
## and for the refrigerated counters butter, cheese, sausage, pelmeni, frozen
## fish and the blue Soviet chickens.
##
## Everything draws from one 2048×2048 atlas, textures/goods.png (made by
## tools/make_goods.py): 4 × 8 cells of 512×256. A round item wraps a whole
## cell once round its body; a pack shows the left half of its cell on the
## front and back, the next quarter on the sides and the last quarter on top.
## All goods share one material, so a shelf of them is one mesh.

const TEX := "goods"

## Atlas cells, left to right, top down (same order as CELLS in make_goods.py).
const CELLS := [
	"peas", "condensed", "tushonka", "kapusta",
	"kilka", "lids", "ikra", "jar_tomato",
	"jar_birch", "jar_apple", "oil", "glass_milk",
	"tetra", "salt", "tea", "macaroni",
	"matches", "flour", "sugar", "chicory",
	"barley", "grechka", "psheno", "soda",
	"butter", "cheese", "sausage", "pelmeni",
	"fish", "chicken", "plombir", "metal",
]

## Discs in the «lids» cell: the top row are tin lids, the bottom row foil caps.
enum Lid { TIN, GOLD, SPRATS, KILKA, FOIL_MILK, FOIL_KEFIR, FOIL_RYAZHENKA, FOIL_SMETANA }

## id: [shape, size (width along the shelf, height, depth), cell, lid].
## Round things have width = depth = diameter.
const ITEMS := {
	# Tins.
	"peas": ["tin", Vector3(0.1, 0.112, 0.1), "peas", Lid.TIN],
	"condensed": ["tin", Vector3(0.076, 0.084, 0.076), "condensed", Lid.TIN],
	"tushonka": ["tin", Vector3(0.1, 0.076, 0.1), "tushonka", Lid.GOLD],
	"kapusta": ["tin", Vector3(0.084, 0.1, 0.084), "kapusta", Lid.TIN],
	"kilka": ["flat", Vector3(0.105, 0.034, 0.105), "kilka", Lid.KILKA],
	"sprats": ["flat", Vector3(0.1, 0.03, 0.1), "metal", Lid.SPRATS],
	# Glass.
	"ikra": ["jar", Vector3(0.084, 0.13, 0.084), "ikra", Lid.GOLD],
	"jar_tomato": ["jar3", Vector3(0.17, 0.27, 0.17), "jar_tomato", Lid.GOLD],
	"jar_birch": ["jar3", Vector3(0.17, 0.27, 0.17), "jar_birch", Lid.GOLD],
	"jar_apple": ["jar3", Vector3(0.17, 0.27, 0.17), "jar_apple", Lid.GOLD],
	"oil": ["bottle", Vector3(0.068, 0.27, 0.068), "oil", Lid.FOIL_MILK],
	"milk": ["milk", Vector3(0.07, 0.205, 0.07), "glass_milk", Lid.FOIL_MILK],
	"kefir": ["milk", Vector3(0.07, 0.205, 0.07), "glass_milk", Lid.FOIL_KEFIR],
	"ryazhenka": ["milk", Vector3(0.07, 0.205, 0.07), "glass_milk", Lid.FOIL_RYAZHENKA],
	"smetana": ["smetana", Vector3(0.072, 0.085, 0.072), "glass_milk", Lid.FOIL_SMETANA],
	"tetra": ["tetra", Vector3(0.165, 0.135, 0.15), "tetra", 0],
	# Packs and bags.
	"salt": ["box", Vector3(0.085, 0.13, 0.055), "salt", 0],
	"tea": ["box", Vector3(0.062, 0.095, 0.036), "tea", 0],
	"macaroni": ["box", Vector3(0.09, 0.22, 0.06), "macaroni", 0],
	"matches": ["box", Vector3(0.19, 0.075, 0.052), "matches", 0],
	"chicory": ["box", Vector3(0.065, 0.12, 0.045), "chicory", 0],
	"barley": ["box", Vector3(0.085, 0.14, 0.05), "barley", 0],
	"soda": ["box", Vector3(0.07, 0.11, 0.04), "soda", 0],
	"flour": ["bag", Vector3(0.13, 0.24, 0.085), "flour", 0],
	"sugar": ["bag", Vector3(0.105, 0.17, 0.07), "sugar", 0],
	"grechka": ["bag", Vector3(0.105, 0.18, 0.07), "grechka", 0],
	"psheno": ["bag", Vector3(0.105, 0.18, 0.07), "psheno", 0],
	# Chilled and frozen.
	"butter": ["box", Vector3(0.1, 0.035, 0.065), "butter", 0],
	"pelmeni": ["box", Vector3(0.16, 0.045, 0.11), "pelmeni", 0],
	"cheese": ["wheel", Vector3(0.36, 0.11, 0.36), "cheese", 0],
	"sausage": ["sausage", Vector3(0.42, 0.075, 0.075), "sausage", 0],
	"fish": ["block", Vector3(0.38, 0.09, 0.26), "fish", 0],
	"chicken": ["chicken", Vector3(0.26, 0.1, 0.16), "chicken", 0],
	"plombir": ["cup", Vector3(0.07, 0.07, 0.07), "plombir", 0],
}


static func cell(name: String) -> Rect2:
	var i := CELLS.find(name)
	return Rect2((i % 4) * 0.25, (i / 4) * 0.125, 0.25, 0.125)


## Part of a cell, in fractions of it (x0..x1 across, y0..y1 down).
static func sub(r: Rect2, x0: float, x1: float, y0 := 0.0, y1 := 1.0) -> Rect2:
	var px := 1.0 / 2048.0  # keep a pixel off the neighbours
	return Rect2(r.position.x + r.size.x * x0 + px, r.position.y + r.size.y * y0 + px,
		r.size.x * (x1 - x0) - 2.0 * px, r.size.y * (y1 - y0) - 2.0 * px)


static func lid_rect(lid: int) -> Rect2:
	var c := cell("lids")
	return sub(c, (lid % 4) * 0.25, (lid % 4 + 1) * 0.25, (lid / 4) * 0.5, (lid / 4 + 1) * 0.5)


static func size_of(id: String) -> Vector3:
	return ITEMS[id][1]


## One item standing at the origin of `xf` (bottom centre), its front to -z.
static func build(mb: MeshBuilder, xf: Transform3D, id: String, tint := Color.WHITE) -> void:
	var it: Array = ITEMS[id]
	var s: Vector3 = it[1]
	var c := cell(it[2])
	var lid: int = it[3]
	match it[0]:
		"tin":
			_tin(mb, xf, s.x * 0.5, s.y, c, lid, tint)
		"flat":
			_flat(mb, xf, s.x * 0.5, s.y, c, lid, tint)
		"jar":
			_jar(mb, xf, s.x * 0.5, s.y, c, lid, tint, 0.78)
		"jar3":
			_jar(mb, xf, s.x * 0.5, s.y, c, lid, tint, 0.68)
		"bottle":
			_bottle(mb, xf, s.x * 0.5, s.y, c, lid, tint, 0.45)
		"milk":
			_bottle(mb, xf, s.x * 0.5, s.y, c, lid, tint, 0.62)
		"smetana":
			_smetana(mb, xf, s.x * 0.5, s.y, c, lid, tint)
		"tetra":
			_tetra(mb, xf, s.x, c, tint)
		"box", "block":
			_box(mb, xf, s, c, tint)
		"bag":
			_bag(mb, xf, s, c, tint)
		"wheel":
			_wheel(mb, xf, s.x * 0.5, s.y, c, tint)
		"sausage":
			_sausage(mb, xf, s.x, s.y * 0.5, c, tint)
		"chicken":
			_chicken(mb, xf, s, c, tint)
		"cup":
			_cup(mb, xf, s.x * 0.5, s.y, c, tint)


# --- shapes --------------------------------------------------------------------

## A tin: a paper or lithographed body between rolled beads, a lid with
## its rings and stamped code, the same at the bottom (unseen, so left out).
static func _tin(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, lid: int, tint: Color) -> void:
	var sides := 10 if r < 0.045 else 12
	var metal := sub(cell("metal"), 0.0, 0.5, 0.1, 0.3)
	var bead := 0.006
	# Body: the label runs from just above the bottom bead to under the top one.
	mb.cylinder(xf * Transform3D(Basis.IDENTITY, Vector3(0, bead, 0)), r, r, h - 2.0 * bead, sides, tint, c,
		MeshBuilder.NO_RECT, false, false)
	mb.cylinder(xf, r * 1.03, r * 1.03, bead, sides, tint, metal, MeshBuilder.NO_RECT, false, false)
	mb.lathe(xf, [Vector2(r, h - bead), Vector2(r * 1.03, h - bead * 0.5), Vector2(r * 0.93, h)], sides, tint, metal)
	mb.disc(xf, r * 0.93, h - 0.003, sides, tint, lid_rect(lid))


## A low round tin (kilka, sprats): the lid is the label.
static func _flat(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, lid: int, tint: Color) -> void:
	var sides := 12
	var metal := sub(cell("metal"), 0.0, 0.5, 0.1, 0.3) if lid != Lid.SPRATS else sub(cell("metal"), 0.5, 1.0, 0.1, 0.3)
	var body := sub(c, 0.0, 1.0, 0.2, 0.8) if c != cell("metal") else metal
	mb.cylinder(xf, r, r, h - 0.004, sides, tint, body, MeshBuilder.NO_RECT, false, false)
	mb.lathe(xf, [Vector2(r, h - 0.004), Vector2(r * 1.03, h - 0.002), Vector2(r * 0.95, h)], sides, tint, metal)
	mb.disc(xf, r * 0.95, h - 0.001, sides, tint, lid_rect(lid))


## A glass jar: straight body, a shoulder, a short neck, the lacquered
## press-on lid. `body` is where the shoulder starts, as a fraction of h.
static func _jar(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, lid: int, tint: Color,
		body: float) -> void:
	var sides := 12 if r > 0.06 else 10
	var neck := r * 0.66
	var lid_h := h * 0.06
	var top := h - lid_h
	mb.lathe(xf, [Vector2(r * 0.88, 0), Vector2(r, h * 0.04), Vector2(r, top * body),
		Vector2(r * 0.9, top * (body + (1.0 - body) * 0.45)), Vector2(neck * 1.04, top * 0.96), Vector2(neck, top)],
		sides, tint, c)
	var metal := sub(cell("metal"), 0.5, 1.0, 0.1, 0.3)
	mb.lathe(xf, [Vector2(neck * 1.1, top), Vector2(neck * 1.1, h - 0.003), Vector2(neck * 1.05, h)], sides, tint,
		metal)
	mb.disc(xf, neck * 1.05, h - 0.001, sides, tint, lid_rect(lid))


## A bottle: body to `body` of the height, a long shoulder into the neck,
## the lip, a foil cap pressed over it.
static func _bottle(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, lid: int, tint: Color,
		body: float) -> void:
	var sides := 10
	var neck := r * 0.56
	mb.lathe(xf, [Vector2(r * 0.86, 0), Vector2(r, h * 0.03), Vector2(r, h * body),
		Vector2(r * 0.86, h * (body + 0.12)), Vector2(neck * 1.05, h * 0.86), Vector2(neck, h * 0.94),
		Vector2(neck * 1.15, h * 0.96)], sides, tint, c)
	var foil := lid_rect(lid)
	mb.cylinder(xf * Transform3D(Basis.IDENTITY, Vector3(0, h * 0.955, 0)), neck * 1.2, neck * 1.16, h * 0.045, 8,
		tint, sub(foil, 0.45, 0.55, 0.45, 0.55), foil, true, false)


## A 200 g glass jar of сметана under a gold foil cap.
static func _smetana(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, lid: int, tint: Color) -> void:
	var sides := 10
	mb.lathe(xf, [Vector2(r * 0.85, 0), Vector2(r * 0.95, h * 0.1), Vector2(r, h * 0.8),
		Vector2(r * 0.95, h * 0.9), Vector2(r * 1.02, h * 0.94)], sides, tint, sub(c, 0, 1, 0.2, 1.0))
	var foil := lid_rect(lid)
	mb.cylinder(xf * Transform3D(Basis.IDENTITY, Vector3(0, h * 0.94, 0)), r * 1.05, r * 1.03, h * 0.06, sides, tint,
		sub(foil, 0.45, 0.55, 0.45, 0.55), foil, true, false)


## The triangular milk pack lying on one face, its sealed seam on top.
static func _tetra(mb: MeshBuilder, xf: Transform3D, e: float, c: Rect2, tint: Color) -> void:
	var hb := e * sqrt(3.0) / 2.0
	var a := Vector3(-e * 0.5, 0, -hb / 3.0)
	var b := Vector3(e * 0.5, 0, -hb / 3.0)
	var d := Vector3(0, 0, hb * 2.0 / 3.0)
	var top := Vector3(0, e * sqrt(2.0 / 3.0), 0)
	var faces := [[b, a, top], [d, b, top], [a, d, top]]
	for k in faces.size():
		var f: Array = faces[k]
		var r := sub(c, 0.0 if k != 1 else 0.5, 0.5 if k != 1 else 1.0)
		var uv := [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2(r.get_center().x, r.position.y)]
		mb.tri(xf, f, uv, tint)


## A card pack: front and back show the main face, the sides the small
## print, the top the plain flap.
static func _box(mb: MeshBuilder, xf: Transform3D, s: Vector3, c: Rect2, tint: Color) -> void:
	mb.box(xf, s, tint, sub(c, 0.0, 0.5), Vector2.ONE, MeshFactory.NZ | MeshFactory.PZ)
	mb.box(xf, s, tint, sub(c, 0.5, 0.75), Vector2.ONE, MeshFactory.PX | MeshFactory.NX)
	mb.box(xf, s, tint, sub(c, 0.75, 1.0), Vector2.ONE, MeshFactory.PY)


## A paper bag, filled and folded over at the top: a slightly bellied body
## and a sloping folded top.
static func _bag(mb: MeshBuilder, xf: Transform3D, s: Vector3, c: Rect2, tint: Color) -> void:
	var body := s.y * 0.86
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	mb.box(xf, Vector3(s.x, body, s.z), tint, sub(c, 0.0, 0.5, 0.0, 1.0), Vector2.ONE, MeshFactory.NZ | MeshFactory.PZ)
	mb.box(xf, Vector3(s.x, body, s.z), tint, sub(c, 0.5, 0.75), Vector2.ONE, MeshFactory.PX | MeshFactory.NX)
	var t := sub(c, 0.75, 1.0)
	var uv := [Vector2(t.position.x, t.end.y), Vector2(t.end.x, t.end.y), Vector2(t.end.x, t.position.y),
		Vector2(t.position.x, t.position.y)]
	var ridge := s.y
	# Front and back slopes of the fold meeting at a ridge along x.
	mb.quad(xf, [Vector3(hx, body, -hz), Vector3(-hx, body, -hz), Vector3(-hx * 0.9, ridge, 0),
		Vector3(hx * 0.9, ridge, 0)], uv, tint)
	mb.quad(xf, [Vector3(-hx, body, hz), Vector3(hx, body, hz), Vector3(hx * 0.9, ridge, 0),
		Vector3(-hx * 0.9, ridge, 0)], uv, tint)
	var side := [Vector2(t.position.x, t.end.y), Vector2(t.end.x, t.end.y), Vector2(t.get_center().x, t.position.y)]
	mb.tri(xf, [Vector3(hx, body, hz), Vector3(hx, body, -hz), Vector3(hx * 0.9, ridge, 0)], side, tint)
	mb.tri(xf, [Vector3(-hx, body, hz), Vector3(-hx, body, -hz), Vector3(-hx * 0.9, ridge, 0)], side, tint)


## A cheese wheel cut in half: the red rind round, the yellow face on the cut.
static func _wheel(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, tint: Color) -> void:
	var sides := 16
	var rind := sub(c, 0.0, 0.75)
	var face := sub(c, 0.75, 1.0)
	var prof := [Vector2(0, 0), Vector2(r * 0.94, 0), Vector2(r, h * 0.2), Vector2(r, h * 0.8), Vector2(r * 0.94, h),
		Vector2(0, h)]
	# Half a lathe, round the +z side; the cut face looks to -z.
	for i in sides / 2:
		var a0 := PI * float(i) / (sides / 2)
		var a1 := PI * float(i + 1) / (sides / 2)
		for j in prof.size() - 1:
			var p0: Vector2 = prof[j]
			var p1: Vector2 = prof[j + 1]
			var q := [Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x), Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x),
				Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x), Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)]
			var u0 := rind.position.x + rind.size.x * float(i) / (sides / 2)
			var u1 := rind.position.x + rind.size.x * float(i + 1) / (sides / 2)
			var v0 := rind.end.y - rind.size.y * float(j) / (prof.size() - 1)
			var v1 := rind.end.y - rind.size.y * float(j + 1) / (prof.size() - 1)
			mb.quad(xf, [q[1], q[0], q[3], q[2]], [Vector2(u1, v0), Vector2(u0, v0), Vector2(u0, v1),
				Vector2(u1, v1)], tint)
	# The cut face, facing -z.
	mb.quad(xf, [Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(-r, h, 0), Vector3(r, h, 0)],
		[Vector2(face.position.x, face.end.y), Vector2(face.end.x, face.end.y), Vector2(face.end.x, face.position.y),
		face.position], tint)


## A stick of sausage lying along x, its ends tied off.
static func _sausage(mb: MeshBuilder, xf: Transform3D, length: float, r: float, c: Rect2, tint: Color) -> void:
	var lay := xf * Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(-length * 0.5, r, 0))
	var prof := [Vector2(0, -0.012), Vector2(r * 0.25, 0), Vector2(r * 0.8, r * 0.25), Vector2(r, r),
		Vector2(r, length - r), Vector2(r * 0.8, length - r * 0.25), Vector2(r * 0.25, length), Vector2(0, length + 0.012)]
	mb.lathe(lay, prof, 10, tint, sub(c, 0.0, 0.75))


## A frozen chicken lying on its back as they were sold: a long plump
## body, the drumsticks sticking up at the rear, the wings tucked in.
static func _chicken(mb: MeshBuilder, xf: Transform3D, s: Vector3, c: Rect2, tint: Color) -> void:
	var skin := sub(c, 0.0, 1.0)
	mb.ellipsoid(xf * Transform3D(Basis.IDENTITY, Vector3(-s.x * 0.05, s.y * 0.4, 0)),
		Vector3(s.x * 0.4, s.y * 0.42, s.z * 0.46), 10, 6, tint, skin)
	for sz: float in [-1.0, 1.0]:
		# Thigh up from the rear of the body, the drumstick bent forward.
		var hip := Vector3(s.x * 0.18, s.y * 0.6, sz * s.z * 0.2)
		var knee := Vector3(s.x * 0.3, s.y * 1.0, sz * s.z * 0.22)
		mb.capsule(xf, hip, knee, s.y * 0.22, s.y * 0.17, 6, tint, skin)
		mb.capsule(xf, knee, Vector3(s.x * 0.05, s.y * 1.05, sz * s.z * 0.12), s.y * 0.15, s.y * 0.06, 6, tint, skin)
		# Wing folded along the side.
		mb.capsule(xf, Vector3(-s.x * 0.3, s.y * 0.35, sz * s.z * 0.42), Vector3(0.0, s.y * 0.3, sz * s.z * 0.44),
			s.y * 0.1, s.y * 0.08, 6, tint, skin)


## A waffle cup of пломбир with its paper lid.
static func _cup(mb: MeshBuilder, xf: Transform3D, r: float, h: float, c: Rect2, tint: Color) -> void:
	mb.cylinder(xf, r * 0.72, r, h, 10, tint, sub(c, 0.0, 1.0, 0.15, 1.0), sub(c, 0.0, 0.25, 0.0, 0.15), true, false)
