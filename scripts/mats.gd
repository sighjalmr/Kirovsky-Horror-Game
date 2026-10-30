class_name Mats
extends RefCounted

## Shared materials, one per texture/tint/emission/kind combination.
## Kinds: SOLID (one-sided), DOUBLE (two-sided sheets), GLASS (see-through,
## tint.a is the opacity).

const SOLID := "psx_material"
const DOUBLE := "psx_double"
const GLASS := "psx_glass"

## How each surface takes light: [roughness, specular, metallic]. Low
## roughness makes a tight highlight; the floor is freshly mopped, so the torch
## and the lamps glint on it. Anything not listed is matt.
const SURFACE := {
	"floor": [0.28, 0.5, 0.0], "chrome": [0.18, 0.5, 0.85], "glass": [0.05, 0.6, 0.0],
	"enamel": [0.3, 0.45, 0.0], "frozen": [0.25, 0.5, 0.0], "formica": [0.35, 0.4, 0.0],
	"metal": [0.5, 0.4, 0.4], "paint": [0.45, 0.4, 0.0], "locker": [0.5, 0.4, 0.2], "door": [0.5, 0.4, 0.2],
	"wall": [0.6, 0.35, 0.0], "rubber": [0.45, 0.4, 0.0], "leather": [0.5, 0.35, 0.0], "torch": [0.35, 0.45, 0.0],
	"blood": [0.15, 0.55, 0.0], "skin": [0.6, 0.3, 0.0], "face": [0.6, 0.3, 0.0], "register": [0.45, 0.4, 0.1],
	"labels": [0.4, 0.4, 0.0], "basket": [0.4, 0.4, 0.3], "display": [0.1, 0.6, 0.0], "grille": [0.5, 0.4, 0.5],
	"wood": [0.65, 0.3, 0.0], "kafel": [0.15, 0.55, 0.0], "concrete": [0.6, 0.35, 0.0], "galv": [0.4, 0.5, 0.6],
}

static var _shaders: Dictionary = {}
static var _cache: Dictionary = {}


static func get_mat(tex: String, tint := Color.WHITE, emission := Color.BLACK, kind := SOLID) -> ShaderMaterial:
	var key := "%s|%s|%s|%s" % [tex, tint.to_html(), emission.to_html(), kind]
	if not _cache.has(key):
		_cache[key] = unique(tex, tint, emission, kind)
	return _cache[key]


## A material nobody else shares, for things that change at runtime (lamp tubes).
static func unique(tex: String, tint := Color.WHITE, emission := Color.BLACK, kind := SOLID) -> ShaderMaterial:
	if not _shaders.has(kind):
		_shaders[kind] = load("res://shaders/%s.gdshader" % kind)
	var m := ShaderMaterial.new()
	m.shader = _shaders[kind]
	m.set_shader_parameter("albedo_tex", TexFactory.get_tex(tex))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("emission", emission)
	var base := TexFactory.file_name(tex)
	var normal := TexFactory.DIR + base + "_n.png"
	if ResourceLoader.exists(normal):
		m.set_shader_parameter("normal_tex", load(normal))
	var surf: Array = SURFACE.get(base, [0.85, 0.25, 0.0])
	m.set_shader_parameter("roughness", surf[0])
	var rough := TexFactory.DIR + base + "_r.png"
	if ResourceLoader.exists(rough):  # the map is absolute; SURFACE then only scales it (0.5 = as drawn)
		m.set_shader_parameter("rough_tex", load(rough))
		m.set_shader_parameter("rough_map", 1.0)
		m.set_shader_parameter("roughness", 0.5)
	m.set_shader_parameter("specular", surf[1])
	m.set_shader_parameter("metallic", surf[2])
	return m
