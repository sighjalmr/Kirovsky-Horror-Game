class_name Mats
extends RefCounted

## Shared PS1 materials, one per texture/tint/emission/kind combination.
## Kinds: SOLID (one-sided), DOUBLE (two-sided sheets), GLASS (see-through,
## tint.a is the opacity).

const SOLID := "psx_material"
const DOUBLE := "psx_double"
const GLASS := "psx_glass"

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
	return m
