class_name TexFactory
extends RefCounted

## Textures by id, loaded from res://textures/<id>.png. The PNGs (mostly
## 512×512) are drawn by tools/make_textures.py; any of them can be replaced
## with a photo or a hand-painted texture of the same name and proportions.
## "sign:<text>" ids name the hanging aisle signs.

const DIR := "res://textures/"
const SIGNS := {"БАКАЛЕЯ": "bakaleya", "КОНСЕРВЫ": "konservy", "МОЛОКО": "moloko", "ЗАМОРОЗКА": "zamorozka",
	"ПРОМТОВАРЫ": "promtovary", "ТКАНИ": "tkani", "ПОСУДА": "posuda", "ГАЛАНТЕРЕЯ": "galantereya"}

static var _cache: Dictionary = {}


static func get_tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var path := hd_path(file_name(id), "")
	if path == "":
		path = DIR + file_name(id) + ".png"
	var tex: Texture2D
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		push_warning("missing texture " + path)
		var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
		img.fill(Color(1, 0, 1))
		tex = ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


## The 2K version of a surface (tools/make_hd_textures.py: the drawn
## texture with scanned photo detail laid into it) if there is one and the
## player wants them; suffix "", "_n" (normal) or "_r" (roughness).
static func hd_path(base: String, suffix: String) -> String:
	if not Settings.hd_textures:
		return ""
	var p := DIR + "hd/" + base + suffix + ".webp"
	return p if ResourceLoader.exists(p) else ""


static func file_name(id: String) -> String:
	if id.begins_with("sign:"):
		return "sign_" + SIGNS.get(id.substr(5), "bakaleya")
	return id
