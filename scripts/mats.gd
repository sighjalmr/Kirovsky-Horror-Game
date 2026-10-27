class_name Mats
extends RefCounted

## Shared PS1 materials, one per texture/tint/emission combination.

static var _shader: Shader
static var _cache: Dictionary = {}


static func get_mat(tex: String, tint := Color.WHITE, emission := Color.BLACK) -> ShaderMaterial:
	var key := "%s|%s|%s" % [tex, tint.to_html(), emission.to_html()]
	if not _cache.has(key):
		_cache[key] = unique(tex, tint, emission)
	return _cache[key]


## A material nobody else shares, for things that change at runtime (lamp tubes).
static func unique(tex: String, tint := Color.WHITE, emission := Color.BLACK) -> ShaderMaterial:
	if _shader == null:
		_shader = load("res://shaders/psx_material.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("albedo_tex", TexFactory.get_tex(tex))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("emission", emission)
	return m
