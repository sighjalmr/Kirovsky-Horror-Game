class_name TexFactory
extends RefCounted

## Procedural textures at the Silent Hill 1 budget: mostly 128×128, 15-bit
## colour, nearest filtering. They are baked once into res://textures/*.png
## (`godot --path . -- --bake-textures`) and loaded from there, so any PNG can
## be replaced by a hand-painted or photo-sourced one under the same name.
## Ids starting with "sign:" make a hanging aisle sign with that text.
## Image row 0 is the top of a wall: the bottom rows sit on the floor.

const DIR := "res://textures/"

## Every texture id the game uses, baked by bake_all().
const IDS := [
	"floor", "wall", "ceiling", "metal", "paint", "pegboard", "labels", "tags", "locker",
	"cloth", "enamel", "frozen", "wood", "formica", "door", "glass", "cardboard",
	"poster_tomato", "poster_bread", "keys", "register", "display", "grille", "dial",
	"calendar", "clock", "skin", "face", "coat", "guard_wool", "trousers", "knit", "rubber",
	"leather", "torch", "chrome", "blood", "basket", "fabric", "white", "exit",
	"sign:БАКАЛЕЯ", "sign:КОНСЕРВЫ", "sign:МОЛОКО", "sign:ЗАМОРОЗКА",
]

static var _cache: Dictionary = {}


static func get_tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var tex: Texture2D
	var path := DIR + file_name(id) + ".png"
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		tex = ImageTexture.create_from_image(make(id))
	_cache[id] = tex
	return tex


static func file_name(id: String) -> String:
	if id.begins_with("sign:"):
		var names := {"БАКАЛЕЯ": "bakaleya", "КОНСЕРВЫ": "konservy", "МОЛОКО": "moloko", "ЗАМОРОЗКА": "zamorozka"}
		return "sign_" + names.get(id.substr(5), str(hash(id)))
	return id


## Writes every texture as a PNG with a lossless, mipmap-free import file.
static func bake_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for id: String in IDS:
		var name := file_name(id)
		var path := ProjectSettings.globalize_path(DIR + name + ".png")
		make(id).save_png(path)
		var imp := FileAccess.open(path + ".import", FileAccess.WRITE)
		imp.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[deps]\n\nsource_file=\"%s\"\n\n[params]\n\ncompress/mode=0\nmipmaps/generate=false\ndetect_3d/compress_to=0\nprocess/fix_alpha_border=true\n" % (DIR + name + ".png"))
		imp.close()
		print("baked ", name)


static func make(id: String) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var img: Image
	if id.begins_with("sign:"):
		img = _sign(rng, id.substr(5))
	else:
		match id:
			"floor": img = _floor(rng)
			"wall": img = _wall(rng)
			"ceiling": img = _ceiling(rng)
			"metal": img = _metal(rng, Color(0.36, 0.39, 0.42))
			"paint": img = _metal(rng, Color(0.5, 0.56, 0.55))
			"pegboard": img = _pegboard(rng)
			"labels": img = _labels(rng)
			"tags": img = _tags(rng)
			"locker": img = _locker(rng)
			"cloth": img = _cloth(rng)
			"enamel": img = _enamel(rng)
			"frozen": img = _frozen(rng)
			"wood": img = _wood(rng)
			"formica": img = _formica(rng)
			"door": img = _door(rng)
			"glass": img = _glass(rng)
			"cardboard": img = _cardboard(rng)
			"poster_tomato": img = _poster(rng, ["ПЕЙТЕ", "ТОМАТНЫЙ", "СОК"], Color(0.68, 0.13, 0.08), true)
			"poster_bread": img = _poster(rng, ["ХЛЕБ -", "ВСЕМУ", "ГОЛОВА"], Color(0.78, 0.6, 0.25), false)
			"keys": img = _keys(rng)
			"register": img = _register(rng)
			"display": img = _display(rng)
			"grille": img = _grille(rng)
			"dial": img = _dial(rng)
			"calendar": img = _calendar(rng)
			"clock": img = _clock(rng)
			"skin": img = _skin(rng)
			"face": img = _face(rng)
			"coat": img = _twill(rng, Color(0.2, 0.15, 0.12), 64)
			"guard_wool": img = _twill(rng, Color(0.3, 0.33, 0.27), 64)
			"trousers": img = _twill(rng, Color(0.17, 0.18, 0.22), 64)
			"knit": img = _knit(rng)
			"rubber": img = _plain(rng, Color(0.08, 0.09, 0.08), 0.03, 64)
			"leather": img = _leather(rng)
			"torch": img = _torch(rng)
			"chrome": img = _chrome(rng)
			"blood": img = _blood(rng)
			"basket": img = _basket(rng)
			"fabric": img = _plain(rng, Color(0.82, 0.82, 0.82), 0.06, 64)
			"exit": img = _exit_sign(rng)
			_: img = _plain(rng, Color(0.9, 0.9, 0.9), 0.02, 32)
	_quantize(img)
	return img


# --- helpers ------------------------------------------------------------------

static func _new(w: int, h: int, c: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return img


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.has_area():
		img.fill_rect(r, c)


static func _px(img: Image, x: int, y: int, c: Color, mix := 1.0) -> void:
	var px := posmod(x, img.get_width())
	var py := posmod(y, img.get_height())
	img.set_pixel(px, py, img.get_pixel(px, py).lerp(c, mix))


## Seamless fractal noise in 0..1, sampled with n[y * w + x].
static func _noise(w: int, h: int, seed: int, freq: float, octaves := 3) -> PackedFloat32Array:
	var fn := FastNoiseLite.new()
	fn.seed = seed
	fn.frequency = freq
	fn.fractal_octaves = octaves
	var src := fn.get_seamless_image(w, h, false, false, 0.1, true)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		for x in w:
			out[y * w + x] = src.get_pixel(x, y).r
	return out


## Multiplies brightness by lerp(lo, hi, noise).
static func _shade(img: Image, n: PackedFloat32Array, lo: float, hi: float, rect := Rect2i()) -> void:
	var w := img.get_width()
	var r := rect if rect.has_area() else Rect2i(Vector2i.ZERO, img.get_size())
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var k := lerpf(lo, hi, n[y * w + x])
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k, c.a))


## Mixes towards `c` where the noise is above `threshold` (stains, rust, grime).
static func _stain(img: Image, n: PackedFloat32Array, threshold: float, c: Color, strength: float, rect := Rect2i()) -> void:
	var w := img.get_width()
	var r := rect if rect.has_area() else Rect2i(Vector2i.ZERO, img.get_size())
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var v := n[y * w + x]
			if v > threshold:
				var src := img.get_pixel(x, y)
				var mixed := src.lerp(c, clampf((v - threshold) / (1.0 - threshold) * 2.0, 0.0, 1.0) * strength)
				mixed.a = src.a
				img.set_pixel(x, y, mixed)


static func _grain(img: Image, rng: RandomNumberGenerator, amount: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var k := rng.randf_range(-amount, amount)
			img.set_pixel(x, y, Color(c.r + k, c.g + k, c.b + k, c.a))


static func _specks(img: Image, rng: RandomNumberGenerator, count: int, c: Color, mix := 1.0) -> void:
	for i in count:
		_px(img, rng.randi_range(0, img.get_width() - 1), rng.randi_range(0, img.get_height() - 1), c, mix)


static func _line(img: Image, a: Vector2i, b: Vector2i, c: Color, mix := 1.0) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var t := float(i) / maxf(1.0, n)
		_px(img, roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)), c, mix)


## Light top/left edges and dark bottom/right edges: reads as a raised panel.
static func _bevel(img: Image, r: Rect2i, light: Color, dark: Color, mix := 0.6) -> void:
	for x in range(r.position.x, r.end.x):
		_px(img, x, r.position.y, light, mix)
		_px(img, x, r.end.y - 1, dark, mix)
	for y in range(r.position.y, r.end.y):
		_px(img, r.position.x, y, light, mix)
		_px(img, r.end.x - 1, y, dark, mix)


## A crack: a short random walk.
static func _crack(img: Image, rng: RandomNumberGenerator, start: Vector2i, steps: int, c: Color) -> void:
	var p := Vector2(start)
	var dir := Vector2.from_angle(rng.randf() * TAU)
	for i in steps:
		_px(img, roundi(p.x), roundi(p.y), c, 0.8)
		dir = dir.rotated(rng.randf_range(-0.6, 0.6))
		p += dir


static func _blot(img: Image, rng: RandomNumberGenerator, count: int, radius: float, tint: Color, strength: float, area := Rect2i()) -> void:
	var r := area if area.has_area() else Rect2i(Vector2i.ZERO, img.get_size())
	for i in count:
		var cx := rng.randf_range(r.position.x, r.end.x)
		var cy := rng.randf_range(r.position.y, r.end.y)
		var rad := rng.randf_range(radius * 0.5, radius)
		for y in range(int(cy - rad), int(cy + rad) + 1):
			for x in range(int(cx - rad), int(cx + rad) + 1):
				var d := Vector2(x - cx, y - cy).length() / rad
				if d <= 1.0:
					_px(img, x, y, tint, strength * (1.0 - d * d))


static func _quantize(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				roundf(clampf(c.r, 0, 1) * 31.0) / 31.0,
				roundf(clampf(c.g, 0, 1) * 31.0) / 31.0,
				roundf(clampf(c.b, 0, 1) * 31.0) / 31.0,
				1.0 if c.a > 0.5 else 0.0))


static func _plain(rng: RandomNumberGenerator, c: Color, noise: float, size := 64) -> Image:
	var img := _new(size, size, c)
	_shade(img, _noise(size, size, rng.randi(), 0.05), 0.9, 1.08)
	_grain(img, rng, noise)
	return img


# --- surfaces -------------------------------------------------------------------

## Soviet ceramic floor: 4×4 tiles of 30 cm, checkerboard, terrazzo specks,
## dirty grout, chipped corners, a couple of cracks, traffic grime.
static func _floor(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.19, 0.18, 0.15))
	for ty in 4:
		for tx in 4:
			var light := (tx + ty) % 2 == 0
			var v := rng.randf_range(-0.035, 0.035)
			var base := Color(0.62 + v, 0.58 + v, 0.5 + v) if light else Color(0.4 + v, 0.38 + v, 0.34 + v)
			var r := Rect2i(tx * 32 + 1, ty * 32 + 1, 30, 30)
			_rect(img, r.position.x, r.position.y, 30, 30, base)
			for i in 60:
				_px(img, r.position.x + rng.randi_range(0, 29), r.position.y + rng.randi_range(0, 29),
					base.darkened(0.25) if rng.randf() < 0.6 else base.lightened(0.18))
			_bevel(img, r, base.lightened(0.15), base.darkened(0.3), 0.5)
			if rng.randf() < 0.3:
				var cx := r.position.x + (0 if rng.randf() < 0.5 else 27)
				var cy := r.position.y + (0 if rng.randf() < 0.5 else 27)
				_rect(img, cx, cy, 3, 3, Color(0.22, 0.2, 0.17))
	for i in 3:
		_crack(img, rng, Vector2i(rng.randi_range(0, 127), rng.randi_range(0, 127)), rng.randi_range(8, 20), Color(0.15, 0.14, 0.12))
	_shade(img, _noise(128, 128, rng.randi(), 0.02, 4), 0.78, 1.06)
	_stain(img, _noise(128, 128, rng.randi(), 0.04, 3), 0.62, Color(0.25, 0.22, 0.17), 0.5)
	_grain(img, rng, 0.02)
	return img


## Whitewash above, oil-painted green panel below with chips and scuffs,
## a dark dividing stripe and a brown skirting board on the floor.
static func _wall(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.7, 0.69, 0.63))
	_rect(img, 0, 68, 128, 3, Color(0.13, 0.2, 0.16))
	_rect(img, 0, 71, 128, 51, Color(0.22, 0.36, 0.29))
	_rect(img, 0, 122, 128, 6, Color(0.27, 0.18, 0.11))
	_rect(img, 0, 122, 128, 1, Color(0.38, 0.27, 0.17))
	var n := _noise(128, 128, rng.randi(), 0.03, 4)
	_shade(img, n, 0.84, 1.05, Rect2i(0, 0, 128, 68))
	_stain(img, _noise(128, 128, rng.randi(), 0.05, 3), 0.66, Color(0.5, 0.43, 0.3), 0.55, Rect2i(0, 0, 128, 68))
	for i in 7:
		var x := rng.randi_range(0, 127)
		var len := rng.randi_range(10, 50)
		for y in len:
			_px(img, x, y, Color(0.48, 0.44, 0.36), 0.3 * (1.0 - float(y) / len))
	_shade(img, _noise(128, 128, rng.randi(), 0.08, 2), 0.85, 1.12, Rect2i(0, 71, 128, 51))
	_blot(img, rng, 9, 3.0, Color(0.68, 0.66, 0.58), 0.9, Rect2i(0, 72, 128, 48))
	for i in 14:
		var y := rng.randi_range(100, 120)
		var x := rng.randi_range(0, 120)
		_line(img, Vector2i(x, y), Vector2i(x + rng.randi_range(4, 16), y + rng.randi_range(-1, 1)), Color(0.08, 0.1, 0.09), 0.5)
	_grain(img, rng, 0.02)
	return img


## Suspended ceiling: 60 cm fissured mineral tiles in a T-bar grid, a leak stain.
static func _ceiling(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.62, 0.61, 0.57))
	for i in 340:
		var p := Vector2i(rng.randi_range(0, 127), rng.randi_range(0, 127))
		var q := p + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-1, 1))
		_line(img, p, q, Color(0.45, 0.44, 0.41), 0.7)
	for i in 128:
		for k: int in [0, 1, 64, 65]:
			_px(img, i, k, Color(0.5, 0.5, 0.48) if k % 2 == 0 else Color(0.36, 0.36, 0.34))
			_px(img, k, i, Color(0.5, 0.5, 0.48) if k % 2 == 0 else Color(0.36, 0.36, 0.34))
	var c := Vector2(rng.randf_range(80, 110), rng.randf_range(80, 110))
	for y in 128:
		for x in 128:
			var d := Vector2(x, y).distance_to(c)
			if d < 16:
				_px(img, x, y, Color(0.5, 0.42, 0.28), 0.35 if d > 13 else 0.15)
	_shade(img, _noise(128, 128, rng.randi(), 0.03), 0.88, 1.04)
	return img


## Painted sheet metal with scratches, rubbed edges and rust spots.
static func _metal(rng: RandomNumberGenerator, base: Color) -> Image:
	var img := _new(128, 128, base)
	_shade(img, _noise(128, 128, rng.randi(), 0.03, 3), 0.86, 1.06)
	for i in 26:
		var p := Vector2i(rng.randi_range(0, 127), rng.randi_range(0, 127))
		_line(img, p, p + Vector2i(rng.randi_range(-14, 14), rng.randi_range(-3, 3)), base.lightened(0.3), 0.6)
	_stain(img, _noise(128, 128, rng.randi(), 0.07, 2), 0.72, Color(0.42, 0.24, 0.12), 0.7)
	_grain(img, rng, 0.02)
	return img


static func _pegboard(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.44, 0.45, 0.42))
	for y in range(2, 64, 8):
		for x in range(2, 64, 8):
			_rect(img, x, y, 2, 2, Color(0.08, 0.08, 0.08))
	_shade(img, _noise(64, 64, rng.randi(), 0.05), 0.85, 1.05)
	_grain(img, rng, 0.02)
	return img


## Product label atlas, 4×4 cells of 32×32. Wrapped around tins and jars or
## printed on packs. Cells (row-major): tomato juice, green peas, condensed
## milk, sprats; salt, tea, macaroni, matches; birch juice jar, tomato jar,
## apple juice jar, sprat tin "kilka"; flour, sugar, chicory, milk triangle.
static func _labels(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color.WHITE)
	var white := Color(0.88, 0.86, 0.78)
	var ink := Color(0.12, 0.1, 0.1)
	var cells := [
		[Color(0.7, 0.12, 0.08), white, "СОК"],
		[Color(0.22, 0.42, 0.2), white, "ГОР"],
		[Color(0.35, 0.55, 0.78), white, "МОЛ"],
		[Color(0.72, 0.58, 0.24), Color(0.15, 0.12, 0.1), "РЫБ"],
		[Color(0.2, 0.3, 0.62), white, "СОЛЬ"],
		[Color(0.7, 0.66, 0.2), Color(0.12, 0.3, 0.15), "ЧАЙ"],
		[Color(0.86, 0.74, 0.38), Color(0.5, 0.15, 0.1), "МАК"],
		[Color(0.18, 0.16, 0.14), Color(0.75, 0.15, 0.1), "СПИЧ"],
		[Color(0.84, 0.82, 0.6), Color(0.3, 0.45, 0.25), "БЕР"],
		[Color(0.6, 0.08, 0.06), white, "ТОМ"],
		[Color(0.78, 0.5, 0.16), white, "ЯБЛ"],
		[Color(0.3, 0.4, 0.52), Color(0.82, 0.82, 0.8), "КИЛ"],
		[Color(0.86, 0.85, 0.8), Color(0.2, 0.3, 0.6), "МУКА"],
		[Color(0.88, 0.87, 0.84), Color(0.7, 0.12, 0.1), "САХ"],
		[Color(0.42, 0.28, 0.16), Color(0.85, 0.7, 0.4), "ЦИК"],
		[Color(0.86, 0.88, 0.9), Color(0.25, 0.4, 0.7), "МОЛ"],
	]
	for i in 16:
		var cx := (i % 4) * 32
		var cy := (i / 4) * 32
		var c: Array = cells[i]
		var base: Color = c[0]
		var accent: Color = c[1]
		_rect(img, cx, cy, 32, 32, base)
		_rect(img, cx, cy + 9, 32, 14, accent)
		_rect(img, cx, cy + 3, 32, 2, accent.darkened(0.2))
		# Rows 0–2: tin lid / jar cap, used for the tops of cylinders.
		_rect(img, cx, cy, 32, 3, Color(0.6, 0.6, 0.57) if i < 8 or i == 11 else Color(0.75, 0.68, 0.3))
		_rect(img, cx, cy + 27, 32, 2, accent.darkened(0.2))
		var text: String = c[2]
		PixelFont.draw_centered(img, text, cx + 16, cy + 12, base if accent != white else ink)
		if i in [0, 9]:
			_blot(img, rng, 1, 3.0, Color(0.85, 0.15, 0.08), 1.0, Rect2i(cx + 24, cy + 23, 6, 6))
		if i == 5:
			_rect(img, cx + 2, cy + 23, 6, 4, Color(0.45, 0.4, 0.38))
	_shade(img, _noise(128, 128, rng.randi(), 0.08), 0.86, 1.04)
	_grain(img, rng, 0.02)
	return img


## Hand-written price tags, 4×8 cells of 32×16: "1-20", "0-45" and so on.
static func _tags(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.88, 0.86, 0.76))
	for i in 32:
		var cx := (i % 4) * 32
		var cy := (i / 4) * 16
		_bevel(img, Rect2i(cx, cy, 32, 16), Color(0.95, 0.94, 0.86), Color(0.5, 0.48, 0.4), 0.8)
		_rect(img, cx + 2, cy + 2, 28, 2, Color(0.75, 0.2, 0.15))
		var price := "%d-%02d" % [rng.randi_range(0, 3), rng.randi_range(0, 19) * 5]
		PixelFont.draw_small(img, price, cx + 6, cy + 7, Color(0.15, 0.15, 0.35))
	_grain(img, rng, 0.02)
	return img


## Left-luggage lockers, 12 columns × 4 rows numbered 1–48, one 384×128 image
## mapped once onto the whole bank: louvres, number plates, lock, handle, rust.
static func _locker(rng: RandomNumberGenerator) -> Image:
	var img := _new(384, 128, Color(0.16, 0.18, 0.17))
	for r in 4:
		for c in 12:
			var x := c * 32
			var y := r * 32
			var v := rng.randf_range(-0.03, 0.03)
			var face := Color(0.42 + v, 0.48 + v, 0.43 + v)
			var door := Rect2i(x + 2, y + 2, 28, 28)
			_rect(img, door.position.x, door.position.y, 28, 28, face)
			_bevel(img, door, face.lightened(0.25), face.darkened(0.45), 0.8)
			for k in 3:
				_rect(img, x + 7, y + 6 + k * 3, 18, 1, face.darkened(0.5))
			_rect(img, x + 10, y + 16, 12, 7, Color(0.8, 0.78, 0.66))
			PixelFont.draw_small(img, str(r * 12 + c + 1), x + 11 + (2 if r * 12 + c + 1 < 10 else 0), y + 17, Color(0.15, 0.12, 0.1))
			_rect(img, x + 23, y + 24, 3, 3, Color(0.7, 0.7, 0.68))
			img.set_pixel(x + 24, y + 25, Color(0.05, 0.05, 0.05))
			_rect(img, x + 5, y + 25, 6, 2, Color(0.25, 0.25, 0.25))
	_stain(img, _noise(384, 128, rng.randi(), 0.05, 3), 0.7, Color(0.4, 0.24, 0.12), 0.6)
	for i in 40:
		var p := Vector2i(rng.randi_range(0, 383), rng.randi_range(0, 127))
		_line(img, p, p + Vector2i(rng.randi_range(-6, 6), rng.randi_range(-2, 2)), Color(0.7, 0.72, 0.68), 0.5)
	_grain(img, rng, 0.02)
	return img


## Grey linen dust cover: fine weave, broad soft folds, a few stains.
static func _cloth(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.6, 0.59, 0.54))
	for y in 128:
		for x in 128:
			if (x + y) % 2 == 0:
				_px(img, x, y, Color(0.52, 0.5, 0.46), 0.3)
	var warp := _noise(128, 128, rng.randi(), 0.02, 2)
	for y in 128:
		for x in 128:
			var f := sin(x * TAU / 32.0 + warp[y * 128 + x] * 7.0)
			var k := 0.88 + 0.16 * f * absf(f)
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k))
	_stain(img, _noise(128, 128, rng.randi(), 0.05, 3), 0.72, Color(0.38, 0.35, 0.28), 0.5)
	_grain(img, rng, 0.012)
	return img


## Freezer chest enamel: off-white, chipped to black, rust halos, blue band.
static func _enamel(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.8, 0.82, 0.8))
	_rect(img, 0, 14, 128, 8, Color(0.2, 0.27, 0.45))
	_rect(img, 0, 22, 128, 1, Color(0.14, 0.18, 0.3))
	_shade(img, _noise(128, 128, rng.randi(), 0.04), 0.9, 1.04)
	for i in 14:
		var c := Vector2i(rng.randi_range(0, 127), rng.randi_range(60, 127))
		_blot(img, rng, 1, 5.0, Color(0.5, 0.3, 0.14), 0.7, Rect2i(c.x - 1, c.y - 1, 2, 2))
		_rect(img, c.x, c.y, 2, 2, Color(0.08, 0.08, 0.08))
	_stain(img, _noise(128, 128, rng.randi(), 0.05, 3), 0.72, Color(0.55, 0.5, 0.4), 0.4, Rect2i(0, 90, 128, 38))
	_grain(img, rng, 0.015)
	return img


## Through the lid: packs of pelmeni, butter and fish in a crust of frost.
static func _frozen(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.16, 0.2, 0.23))
	var packs := [Color(0.86, 0.85, 0.8), Color(0.3, 0.42, 0.7), Color(0.88, 0.76, 0.38), Color(0.72, 0.42, 0.4), Color(0.55, 0.6, 0.62)]
	for i in 60:
		var c: Color = packs[rng.randi() % packs.size()]
		var w := rng.randi_range(10, 18)
		var h := rng.randi_range(7, 12)
		var x := rng.randi_range(-4, 124)
		var y := rng.randi_range(-4, 124)
		_rect(img, x, y, w, h, c.darkened(rng.randf_range(0.0, 0.2)))
		_rect(img, x + 2, y + h / 2 - 1, w - 4, 2, c.darkened(0.45))
		_bevel(img, Rect2i(x, y, w, h), c.lightened(0.2), c.darkened(0.5), 0.6)
	var frost := _noise(128, 128, rng.randi(), 0.06, 3)
	_stain(img, frost, 0.45, Color(0.88, 0.93, 0.98), 0.85)
	_specks(img, rng, 500, Color(0.95, 0.97, 1.0), 0.7)
	return img


## Wood-grain veneer.
static func _wood(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.42, 0.27, 0.16))
	var warp := _noise(128, 128, rng.randi(), 0.02, 2)
	for y in 128:
		for x in 128:
			var g := sin((y + warp[y * 128 + x] * 30.0) * 0.55) * 0.5 + 0.5
			var k := lerpf(-0.06, 0.05, g)
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + k, c.g + k * 0.8, c.b + k * 0.5))
	_specks(img, rng, 120, Color(0.25, 0.15, 0.08), 0.6)
	_grain(img, rng, 0.015)
	return img


## Grey speckled counter laminate.
static func _formica(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.6, 0.6, 0.57))
	_specks(img, rng, 400, Color(0.42, 0.42, 0.4), 0.8)
	_specks(img, rng, 200, Color(0.75, 0.75, 0.72), 0.8)
	_shade(img, _noise(64, 64, rng.randi(), 0.06), 0.9, 1.04)
	return img


## Storage door, 128×256 mapped once: painted steel, two panels, rivets, rust,
## stencilled "СКЛАД" and "ПОСТОРОННИМ ВХОД ВОСПРЕЩЕН".
static func _door(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 256, Color(0.36, 0.25, 0.2))
	for r: Rect2i in [Rect2i(10, 12, 108, 100), Rect2i(10, 128, 108, 116)]:
		_bevel(img, r, Color(0.5, 0.38, 0.3), Color(0.15, 0.1, 0.08), 0.8)
	for y: int in [5, 120, 250]:
		for x in range(6, 124, 9):
			_rect(img, x, y, 2, 2, Color(0.55, 0.45, 0.38))
	PixelFont.draw_centered(img, "СКЛАД", 64, 40, Color(0.86, 0.84, 0.78), 3)
	PixelFont.draw_centered(img, "ПОСТОРОННИМ", 64, 78, Color(0.86, 0.84, 0.78))
	PixelFont.draw_centered(img, "ВХОД", 64, 88, Color(0.86, 0.84, 0.78))
	PixelFont.draw_centered(img, "ВОСПРЕЩЕН", 64, 98, Color(0.86, 0.84, 0.78))
	_rect(img, 104, 140, 10, 4, Color(0.6, 0.6, 0.58))
	_rect(img, 106, 150, 5, 8, Color(0.3, 0.3, 0.3))
	_stain(img, _noise(128, 256, rng.randi(), 0.05, 3), 0.62, Color(0.45, 0.22, 0.08), 0.75)
	_shade(img, _noise(128, 256, rng.randi(), 0.04), 0.85, 1.05)
	_grain(img, rng, 0.02)
	return img


## Glass door leaf, 128×256: aluminium frame, push bar, opening hours notice,
## night reflections of the street.
static func _glass(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 256, Color(0.04, 0.05, 0.07))
	for y in 256:
		for x in 128:
			var s := posmod(x + y / 2, 70)
			if s < 5 or (s > 14 and s < 17):
				_px(img, x, y, Color(0.2, 0.24, 0.28), 0.8)
	_blot(img, rng, 3, 10.0, Color(0.6, 0.5, 0.25), 0.25, Rect2i(10, 30, 100, 80))
	for r: Rect2i in [Rect2i(0, 0, 128, 8), Rect2i(0, 248, 128, 8), Rect2i(0, 0, 8, 256), Rect2i(120, 0, 8, 256), Rect2i(0, 132, 128, 6)]:
		_rect(img, r.position.x, r.position.y, r.size.x, r.size.y, Color(0.6, 0.62, 0.62))
		_bevel(img, r, Color(0.8, 0.8, 0.8), Color(0.3, 0.3, 0.3))
	_rect(img, 36, 60, 56, 44, Color(0.88, 0.87, 0.8))
	PixelFont.draw_centered(img, "РЕЖИМ", 64, 64, Color(0.15, 0.15, 0.15))
	PixelFont.draw_centered(img, "8-22", 64, 74, Color(0.15, 0.15, 0.15))
	PixelFont.draw_centered(img, "ПЕРЕРЫВ", 64, 84, Color(0.15, 0.15, 0.15))
	PixelFont.draw_centered(img, "13-14", 64, 94, Color(0.15, 0.15, 0.15))
	_grain(img, rng, 0.015)
	return img


## Kraft cardboard with flutes, packing tape and a GOST stamp.
static func _cardboard(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0.5, 0.36, 0.21))
	for x in range(0, 128, 3):
		for y in 128:
			_px(img, x, y, Color(0.42, 0.3, 0.17), 0.35)
	_rect(img, 54, 0, 20, 128, Color(0.62, 0.52, 0.32))
	_rect(img, 0, 0, 128, 2, Color(0.3, 0.2, 0.12))
	_rect(img, 0, 0, 2, 128, Color(0.3, 0.2, 0.12))
	PixelFont.draw(img, "ГОСТ", 10, 90, Color(0.25, 0.15, 0.3), 1)
	PixelFont.draw(img, "13516", 10, 100, Color(0.25, 0.15, 0.3), 1)
	_rect(img, 8, 86, 34, 1, Color(0.25, 0.15, 0.3))
	_stain(img, _noise(128, 128, rng.randi(), 0.05, 3), 0.7, Color(0.32, 0.22, 0.12), 0.6)
	_grain(img, rng, 0.02)
	return img


## Agitprop poster, 128×160 mapped once.
static func _poster(rng: RandomNumberGenerator, lines: Array, base: Color, glass: bool) -> Image:
	var img := _new(128, 160, base)
	_rect(img, 4, 4, 120, 152, base.lightened(0.08))
	var y := 10
	for l: String in lines:
		PixelFont.draw_centered(img, l, 64, y, Color(0.95, 0.92, 0.82), 2)
		y += 18
	if glass:
		_rect(img, 44, 76, 40, 64, Color(0.8, 0.82, 0.85))
		_rect(img, 47, 86, 34, 52, Color(0.75, 0.12, 0.07))
		_rect(img, 47, 86, 34, 3, Color(0.9, 0.3, 0.2))
		_blot(img, rng, 1, 14.0, Color(0.25, 0.45, 0.15), 1.0, Rect2i(88, 112, 6, 6))
	else:
		_blot(img, rng, 1, 26.0, Color(0.55, 0.35, 0.15), 1.0, Rect2i(62, 108, 4, 4))
		for i in 5:
			_line(img, Vector2i(44 + i * 9, 100), Vector2i(48 + i * 9, 116), Color(0.4, 0.24, 0.1))
	_stain(img, _noise(128, 160, rng.randi(), 0.04, 3), 0.7, Color(0.6, 0.55, 0.42), 0.5)
	_grain(img, rng, 0.02)
	return img


## Hanging aisle sign: white letters on red, 128×32.
static func _sign(rng: RandomNumberGenerator, text: String) -> Image:
	var img := _new(128, 32, Color(0.62, 0.12, 0.08))
	_bevel(img, Rect2i(0, 0, 128, 32), Color(0.8, 0.3, 0.2), Color(0.3, 0.05, 0.03), 1.0)
	var scale := 2 if PixelFont.width(text, 2) <= 120 else 1
	PixelFont.draw_centered(img, text, 64, 16 - 7 * scale / 2, Color(0.95, 0.93, 0.85), scale)
	_shade(img, _noise(128, 32, rng.randi(), 0.06), 0.88, 1.04)
	return img


static func _exit_sign(_rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 16, Color(0.15, 0.55, 0.25))
	PixelFont.draw_centered(img, "ВЫХОД", 32, 4, Color(0.95, 1.0, 0.92))
	return img


## Cash register keyboard: rows of cream and coloured keys.
static func _keys(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.2, 0.2, 0.2))
	for r in 7:
		for c in 7:
			var col := Color(0.82, 0.8, 0.7)
			if c == 6:
				col = Color(0.7, 0.2, 0.15)
			elif r == 6:
				col = Color(0.3, 0.45, 0.6)
			_rect(img, 2 + c * 9, 2 + r * 9, 7, 7, col)
			_bevel(img, Rect2i(2 + c * 9, 2 + r * 9, 7, 7), col.lightened(0.2), col.darkened(0.5))
			if c < 6 and r < 6:
				PixelFont.draw_small(img, str((r * 6 + c) % 10), 4 + c * 9, 3 + r * 9, Color(0.2, 0.2, 0.2))
	_grain(img, rng, 0.02)
	return img


static func _register(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.62, 0.6, 0.54))
	_rect(img, 0, 40, 64, 2, Color(0.35, 0.34, 0.3))
	_rect(img, 24, 50, 16, 3, Color(0.3, 0.3, 0.3))
	PixelFont.draw_small(img, "1988", 4, 4, Color(0.4, 0.38, 0.33))
	_shade(img, _noise(64, 64, rng.randi(), 0.06), 0.88, 1.04)
	_grain(img, rng, 0.02)
	return img


static func _display(_rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 16, Color(0.05, 0.08, 0.06))
	PixelFont.draw_small(img, "0.00", 30, 6, Color(0.3, 0.9, 0.5))
	return img


static func _grille(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.32, 0.3, 0.28))
	for y in range(0, 64, 4):
		_rect(img, 0, y, 64, 2, Color(0.12, 0.11, 0.1))
	_grain(img, rng, 0.03)
	return img


## Rotary phone dial: ten finger holes on a white ring.
static func _dial(_rng: RandomNumberGenerator) -> Image:
	var img := _new(32, 32, Color(0.32, 0.08, 0.06))
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length()
			if d < 14.0:
				img.set_pixel(x, y, Color(0.85, 0.83, 0.78))
			if d < 6.0:
				img.set_pixel(x, y, Color(0.75, 0.72, 0.65))
	for i in 10:
		var p := Vector2(15.5, 15.5) + Vector2.from_angle(-PI * 0.4 + i * TAU / 12.0) * 10.0
		_rect(img, int(p.x) - 1, int(p.y) - 1, 3, 3, Color(0.1, 0.1, 0.1))
	return img


## Wall calendar, October 1988, 64×96 mapped once.
static func _calendar(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 96, Color(0.88, 0.87, 0.82))
	_rect(img, 0, 0, 64, 30, Color(0.4, 0.5, 0.65))
	_blot(img, rng, 2, 9.0, Color(0.85, 0.8, 0.55), 1.0, Rect2i(10, 6, 40, 16))
	PixelFont.draw_centered(img, "1988", 32, 33, Color(0.6, 0.12, 0.1))
	PixelFont.draw_centered(img, "ОКТЯБРЬ", 32, 43, Color(0.15, 0.15, 0.15))
	for d in 31:
		var col := (d + 5) % 7
		var row := (d + 5) / 7
		PixelFont.draw_small(img, str((d + 1) % 10), 4 + col * 8, 54 + row * 7, Color(0.7, 0.1, 0.1) if col == 6 else Color(0.2, 0.2, 0.2))
	_grain(img, rng, 0.02)
	return img


static func _clock(_rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.12, 0.12, 0.12))
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length()
			if d < 29:
				img.set_pixel(x, y, Color(0.88, 0.87, 0.82))
	for i in 12:
		var p := Vector2(31.5, 31.5) + Vector2.from_angle(i * TAU / 12.0) * 25.0
		_rect(img, int(p.x) - 1, int(p.y) - 1, 2, 2, Color(0.1, 0.1, 0.1))
	_line(img, Vector2i(32, 32), Vector2i(32, 14), Color(0.1, 0.1, 0.1))
	_line(img, Vector2i(32, 32), Vector2i(44, 38), Color(0.1, 0.1, 0.1))
	return img


# --- people -------------------------------------------------------------------

static func _skin(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.78, 0.6, 0.5))
	_shade(img, _noise(64, 64, rng.randi(), 0.08), 0.88, 1.05)
	for y in range(6, 64, 16):
		for x in range(0, 64, 16):
			_line(img, Vector2i(x + 3, y), Vector2i(x + 11, y), Color(0.6, 0.42, 0.35), 0.6)
	_grain(img, rng, 0.02)
	return img


## The killer's face, mapped once on the front of the head: under the hat
## brim only a band of pale skin with deep, shadowed eye sockets and a
## glint in each; from the nose down a dark knitted scarf.
static func _face(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.66, 0.56, 0.5))
	_shade(img, _noise(64, 64, rng.randi(), 0.08), 0.8, 1.04)
	_rect(img, 0, 0, 64, 12, Color(0.3, 0.25, 0.22))
	for x: int in [10, 36]:
		_blot(img, rng, 1, 11.0, Color(0.12, 0.08, 0.07), 0.9, Rect2i(x + 8, 22, 2, 2))
		_rect(img, x + 4, 21, 10, 4, Color(0.04, 0.03, 0.03))
		img.set_pixel(x + 9, 22, Color(0.75, 0.72, 0.65))
		_rect(img, x + 1, 15, 16, 2, Color(0.18, 0.13, 0.1))
	_rect(img, 29, 22, 6, 12, Color(0.55, 0.44, 0.38))
	_rect(img, 0, 34, 64, 30, Color(0.1, 0.1, 0.11))
	for y in range(34, 64):
		for x in 64:
			if posmod(x, 4) == 0 or posmod(x + (y % 2), 4) == 2:
				_px(img, x, y, Color(0.18, 0.18, 0.2), 0.7)
	_rect(img, 0, 34, 64, 1, Color(0.04, 0.04, 0.05))
	_grain(img, rng, 0.02)
	return img


## Wool twill coat cloth: diagonal ribs and wear.
static func _twill(rng: RandomNumberGenerator, base: Color, size: int) -> Image:
	var img := _new(size, size, base)
	for y in size:
		for x in size:
			if posmod(x + y, 4) < 2:
				_px(img, x, y, base.darkened(0.25), 0.5)
	_shade(img, _noise(size, size, rng.randi(), 0.05), 0.85, 1.08)
	_specks(img, rng, size * 3, base.lightened(0.25), 0.5)
	return img


static func _knit(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.07, 0.07, 0.07))
	for y in 64:
		for x in 64:
			if posmod(x, 4) == 0 or posmod(x + (y % 2), 4) == 2:
				_px(img, x, y, Color(0.16, 0.16, 0.16), 0.8)
	_grain(img, rng, 0.02)
	return img


static func _leather(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.32, 0.18, 0.1))
	_shade(img, _noise(64, 64, rng.randi(), 0.12, 2), 0.8, 1.1)
	_specks(img, rng, 200, Color(0.2, 0.1, 0.06), 0.6)
	_rect(img, 0, 6, 64, 1, Color(0.6, 0.5, 0.3))
	return img


## The "zhuchok": ribbed green plastic body with a grip pattern.
static func _torch(rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.4, 0.55, 0.36))
	for y in range(20, 64, 6):
		_rect(img, 0, y, 64, 1, Color(0.32, 0.45, 0.29))
	_rect(img, 0, 0, 64, 4, Color(0.55, 0.68, 0.5))
	_shade(img, _noise(64, 64, rng.randi(), 0.08), 0.88, 1.06)
	_grain(img, rng, 0.02)
	return img


static func _chrome(rng: RandomNumberGenerator) -> Image:
	var img := _new(32, 32, Color(0.7, 0.72, 0.74))
	for y in 32:
		_rect(img, 0, y, 32, 1, Color(0.7, 0.72, 0.74).darkened(0.4 * absf(sin(y * 0.3))))
	_grain(img, rng, 0.02)
	return img


## A splat with ragged edges and droplets; alpha-cut on the floor.
static func _blood(rng: RandomNumberGenerator) -> Image:
	var img := _new(128, 128, Color(0, 0, 0, 0))
	var n := _noise(128, 128, rng.randi(), 0.05, 3)
	for y in 128:
		for x in 128:
			var d := Vector2(x - 63.5, y - 63.5).length() / 64.0
			if d + (n[y * 128 + x] - 0.5) * 0.5 < 0.62:
				img.set_pixel(x, y, Color(0.33, 0.01, 0.01).darkened(n[y * 128 + x] * 0.5))
	for i in 30:
		var p := Vector2(63.5, 63.5) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(42, 62)
		_rect(img, int(p.x), int(p.y), rng.randi_range(1, 3), rng.randi_range(1, 3), Color(0.3, 0.0, 0.0))
	return img


## Red plastic shopping basket side: a grid of holes cut out with alpha.
static func _basket(_rng: RandomNumberGenerator) -> Image:
	var img := _new(64, 64, Color(0.62, 0.12, 0.08))
	for y in range(6, 60, 6):
		for x in range(3, 61, 6):
			_rect(img, x, y, 4, 3, Color(0, 0, 0, 0))
	return img
