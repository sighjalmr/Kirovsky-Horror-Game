class_name TexFactory
extends RefCounted

## Procedural placeholder textures: 64×64, quantised to 15-bit colour,
## sampled with nearest filtering by the material. Hand-drawn art from
## Aseprite or Krita replaces them one by one; the ids stay the same.
## Image row 0 is the top of a wall: the bottom rows sit on the floor.

const S := 64

static var _cache: Dictionary = {}


static func get_tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var img: Image
	match id:
		"floor": img = _floor(rng)
		"wall": img = _wall(rng)
		"ceiling": img = _ceiling(rng)
		"shelf": img = _shelf(rng)
		"metal": img = _metal(rng)
		"locker": img = _locker(rng)
		"cloth": img = _cloth(rng)
		"enamel": img = _enamel(rng)
		"frozen": img = _frozen(rng)
		"wood": img = _wood(rng)
		"glass": img = _glass(rng)
		"door": img = _door(rng)
		"cardboard": img = _cardboard(rng)
		"poster": img = _poster(rng)
		"skin": img = _plain(rng, Color(0.86, 0.7, 0.6), 0.03)
		"fabric": img = _plain(rng, Color(0.82, 0.82, 0.82), 0.08)
		"blood": img = _blood(rng)
		_: img = _plain(rng, Color(0.9, 0.9, 0.9), 0.02)
	_quantize(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _new(c: Color) -> Image:
	var img := Image.create(S, S, false, Image.FORMAT_RGB8)
	img.fill(c)
	return img


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(0, 0, S, S)), c)


static func _grain(img: Image, rng: RandomNumberGenerator, amount: float) -> void:
	for y in S:
		for x in S:
			var c := img.get_pixel(x, y)
			var n := rng.randf_range(-amount, amount)
			img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n))


static func _blot(img: Image, rng: RandomNumberGenerator, count: int, radius: float, tint: Color, strength: float, y_min := 0, y_max := S) -> void:
	for i in count:
		var cx := rng.randf_range(0, S)
		var cy := rng.randf_range(y_min, y_max)
		var r := rng.randf_range(radius * 0.5, radius)
		for y in range(int(cy - r), int(cy + r) + 1):
			for x in range(int(cx - r), int(cx + r) + 1):
				var d := Vector2(x - cx, y - cy).length() / r
				if d > 1.0:
					continue
				var px := posmod(x, S)
				var py := posmod(y, S)
				var c := img.get_pixel(px, py)
				img.set_pixel(px, py, c.lerp(tint, strength * (1.0 - d)))


static func _quantize(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(
				roundf(clampf(c.r, 0, 1) * 31.0) / 31.0,
				roundf(clampf(c.g, 0, 1) * 31.0) / 31.0,
				roundf(clampf(c.b, 0, 1) * 31.0) / 31.0))


static func _plain(rng: RandomNumberGenerator, c: Color, noise: float) -> Image:
	var img := _new(c)
	_grain(img, rng, noise)
	return img


## Soviet checkerboard tile, 2×2 tiles per image, dark grout, dirt.
static func _floor(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.2, 0.19, 0.17))
	for ty in 2:
		for tx in 2:
			var light := (tx + ty) % 2 == 0
			var base := Color(0.62, 0.6, 0.53) if light else Color(0.42, 0.4, 0.36)
			_rect(img, tx * 32 + 1, ty * 32 + 1, 30, 30, base)
	_grain(img, rng, 0.035)
	_blot(img, rng, 7, 6.0, Color(0.22, 0.2, 0.16), 0.35)
	return img


## Whitewash above, oil-painted green panel below, a dark dividing line.
static func _wall(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.64, 0.64, 0.58))
	_rect(img, 0, 36, S, 28, Color(0.22, 0.34, 0.28))
	_rect(img, 0, 34, S, 2, Color(0.12, 0.18, 0.14))
	_grain(img, rng, 0.03)
	_blot(img, rng, 4, 9.0, Color(0.45, 0.4, 0.3), 0.3, 0, 30)
	_blot(img, rng, 5, 5.0, Color(0.12, 0.18, 0.14), 0.4, 40, 64)
	return img


static func _ceiling(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.5, 0.5, 0.47))
	for i in S:
		img.set_pixel(i, 0, Color(0.3, 0.3, 0.28))
		img.set_pixel(0, i, Color(0.3, 0.3, 0.28))
		img.set_pixel(i, 32, Color(0.3, 0.3, 0.28))
		img.set_pixel(32, i, Color(0.3, 0.3, 0.28))
	for i in 90:
		img.set_pixel(rng.randi_range(1, 63), rng.randi_range(1, 63), Color(0.36, 0.36, 0.34))
	_grain(img, rng, 0.02)
	_blot(img, rng, 3, 8.0, Color(0.42, 0.36, 0.25), 0.4)
	return img


## Shop shelving in 1988: four boards and many gaps between the goods.
static func _shelf(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.16, 0.19, 0.22))
	var goods := [
		Color(0.55, 0.15, 0.1),   # tomato juice
		Color(0.75, 0.72, 0.55),  # birch juice
		Color(0.25, 0.38, 0.22),  # green peas tins
		Color(0.25, 0.3, 0.5),    # salt packs
		Color(0.75, 0.62, 0.25),  # pasta
		Color(0.78, 0.78, 0.74),  # flour
		Color(0.45, 0.3, 0.18),   # chicory
	]
	var boards := [13, 28, 43, 58]
	var top := 0
	for b: int in boards:
		var x := 0
		while x < S:
			if rng.randf() < 0.5:
				x += rng.randi_range(4, 12)
				continue
			var w := rng.randi_range(4, 7)
			var h := rng.randi_range(5, b - top - 2)
			var c: Color = goods[rng.randi() % goods.size()]
			for k in rng.randi_range(1, 3):
				if x + w > S:
					break
				_rect(img, x, b - h, w - 1, h, c)
				_rect(img, x, b - h + h / 3, w - 1, maxi(1, h / 4), c.lightened(0.3))
				x += w
		_rect(img, 0, b, S, 3, Color(0.5, 0.52, 0.54))
		for t in 3:
			_rect(img, rng.randi_range(0, 58), b, 4, 2, Color(0.85, 0.82, 0.7))
		top = b + 3
	_grain(img, rng, 0.03)
	return img


static func _metal(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.32, 0.36, 0.4))
	_grain(img, rng, 0.04)
	for i in 10:
		var y := rng.randi_range(0, 63)
		var x := rng.randi_range(0, 50)
		_rect(img, x, y, rng.randi_range(4, 14), 1, Color(0.45, 0.48, 0.5))
	return img


## Left-luggage lockers: 4×4 doors per image (each door 0.5 m), number plates.
static func _locker(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.2, 0.24, 0.22))
	for r in 4:
		for c in 4:
			var shade := rng.randf_range(-0.03, 0.03)
			_rect(img, c * 16 + 1, r * 16 + 1, 14, 14, Color(0.36 + shade, 0.42 + shade, 0.38 + shade))
			_rect(img, c * 16 + 5, r * 16 + 3, 6, 3, Color(0.75, 0.72, 0.6))
			img.set_pixel(c * 16 + 11, r * 16 + 8, Color(0.08, 0.08, 0.08))
	_grain(img, rng, 0.03)
	return img


static func _cloth(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.52, 0.5, 0.44))
	var phase := rng.randf() * TAU
	for y in S:
		for x in S:
			var k := sin(x * 0.55 + phase + sin(y * 0.1) * 1.5) * 0.05
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + k, c.g + k, c.b + k))
	_grain(img, rng, 0.05)
	_blot(img, rng, 3, 7.0, Color(0.32, 0.3, 0.25), 0.35)
	return img


static func _enamel(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.72, 0.74, 0.72))
	_rect(img, 0, 8, S, 5, Color(0.2, 0.25, 0.4))
	_grain(img, rng, 0.025)
	_blot(img, rng, 6, 5.0, Color(0.45, 0.28, 0.15), 0.6, 48, 64)
	return img


## A freezer chest seen through its lid: packs of pelmeni and butter in frost.
static func _frozen(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.2, 0.25, 0.28))
	var packs := [Color(0.85, 0.85, 0.8), Color(0.3, 0.4, 0.7), Color(0.85, 0.75, 0.4), Color(0.7, 0.45, 0.45)]
	for i in 26:
		var c: Color = packs[rng.randi() % packs.size()]
		_rect(img, rng.randi_range(0, 56), rng.randi_range(0, 58), rng.randi_range(6, 10), rng.randi_range(4, 7), c)
	for i in 300:
		var x := rng.randi_range(0, 63)
		var y := rng.randi_range(0, 63)
		img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(0.9, 0.95, 1.0), 0.6))
	return img


static func _wood(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.42, 0.27, 0.16))
	var phase := rng.randf() * TAU
	for y in S:
		for x in S:
			var k := sin(y * 0.9 + sin(x * 0.15 + phase) * 2.0) * 0.04
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + k, c.g + k * 0.8, c.b + k * 0.5))
	_grain(img, rng, 0.02)
	return img


static func _glass(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.04, 0.06, 0.09))
	for y in S:
		for x in S:
			var s := posmod(x + y, 40)
			if s < 3 or (s > 8 and s < 10):
				img.set_pixel(x, y, Color(0.16, 0.2, 0.24))
	_rect(img, 0, 0, S, 3, Color(0.4, 0.42, 0.44))
	_rect(img, 0, 61, S, 3, Color(0.4, 0.42, 0.44))
	_rect(img, 0, 0, 3, S, Color(0.4, 0.42, 0.44))
	_rect(img, 61, 0, 3, S, Color(0.4, 0.42, 0.44))
	_grain(img, rng, 0.015)
	return img


static func _door(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.3, 0.27, 0.24))
	_rect(img, 6, 6, 52, 22, Color(0.26, 0.23, 0.2))
	_rect(img, 6, 34, 52, 24, Color(0.26, 0.23, 0.2))
	for y in [3, 31, 60]:
		for x in range(4, 62, 8):
			img.set_pixel(x, y, Color(0.5, 0.48, 0.44))
	_grain(img, rng, 0.03)
	_blot(img, rng, 5, 6.0, Color(0.4, 0.22, 0.1), 0.5)
	return img


static func _cardboard(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.48, 0.34, 0.2))
	_rect(img, 28, 0, 8, S, Color(0.6, 0.5, 0.3))
	_rect(img, 0, 0, S, 1, Color(0.3, 0.2, 0.12))
	_rect(img, 0, 0, 1, S, Color(0.3, 0.2, 0.12))
	_grain(img, rng, 0.04)
	return img


## Red agitprop poster with blocky white "text" lines.
static func _poster(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.65, 0.12, 0.08))
	_rect(img, 6, 6, 52, 8, Color(0.9, 0.88, 0.8))
	_rect(img, 6, 18, 36, 4, Color(0.9, 0.88, 0.8))
	_rect(img, 18, 30, 28, 24, Color(0.85, 0.3, 0.15))
	_rect(img, 26, 26, 12, 6, Color(0.3, 0.45, 0.2))
	_rect(img, 6, 57, 40, 3, Color(0.9, 0.88, 0.8))
	_grain(img, rng, 0.04)
	return img


static func _blood(rng: RandomNumberGenerator) -> Image:
	var img := _new(Color(0.35, 0.02, 0.02))
	_blot(img, rng, 8, 10.0, Color(0.15, 0.0, 0.0), 0.7)
	_grain(img, rng, 0.05)
	return img
