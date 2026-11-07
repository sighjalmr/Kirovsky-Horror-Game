class_name Models
extends RefCounted

## Models built in Blender (tools/blender/build_*.py → models/kit/<kit>.glb).
## Each model is a root node of the .glb named by its id ("peas",
## "peas_v1", …) with an optional "<id>_lod1" low-detail copy. Material
## names say which game material each surface gets
## ("<texture>[#rrggbb[aa]][@kind]", see tools/blender/bkit.py); vertex
## colours carry the baked ambient occlusion.
##
## Models are merged into a MeshBuilder.Kit like the procedural parts, so a
## shelf of goods stays one mesh per material. The detailed meshes go into
## builders that are drawn near the camera only, the _lod1 copies into
## builders drawn beyond that (Kit.build sets the visibility ranges from
## Models.lod_distance, which Graphics sets by quality level).

## Where the detailed models hand over to the simple ones, in metres
## (0 = always the simple ones).
static var lod_distance := 9.0

static var _kits: Dictionary = {}   # kit -> {id: [[mesh, surface, mat_key], ...]}
static var _variants: Dictionary = {}  # "kit/id" -> [id, id_v1, ...]


static func _load(kit: String) -> Dictionary:
	if _kits.has(kit):
		return _kits[kit]
	var models := {}
	var path := "res://models/kit/%s.glb" % kit
	if ResourceLoader.exists(path):
		var scene: Node = (load(path) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			var id := String(mi.name)
			var parts := []
			var mesh := mi.mesh
			for s in mesh.get_surface_count():
				var m := mesh.surface_get_material(s)
				var key := m.resource_name if m != null else "white"
				parts.append([mesh, s, key])
			models[id] = parts
		scene.free()
	else:
		push_warning("Models: no kit " + path)
	_kits[kit] = models
	return models


static func has(kit: String, id: String) -> bool:
	return _load(kit).has(id)


## The id and its variants (id, id_v1, id_v2, …) present in the kit.
static func variants(kit: String, id: String) -> Array:
	var key := kit + "/" + id
	if not _variants.has(key):
		var out := []
		var models := _load(kit)
		if models.has(id):
			out.append(id)
		for v in range(1, 6):
			if models.has("%s_v%d" % [id, v]):
				out.append("%s_v%d" % [id, v])
		_variants[key] = out
	return _variants[key]


## Picks a variant of `id` from a seed (a position hashes well).
static func pick(kit: String, id: String, seed: int) -> String:
	var vs := variants(kit, id)
	if vs.is_empty():
		return ""
	return vs[absi(seed) % vs.size()]


static func seed_of(xf: Transform3D) -> int:
	var p := xf.origin * 997.0
	return int(p.x) * 73856093 ^ int(p.y) * 19349663 ^ int(p.z) * 83492791


## Splits "tex#rrggbb@kind" into [tex, tint, kind].
static func parse(key: String) -> Array:
	var kind := Mats.SOLID
	var tint := Color.WHITE
	var tex := key
	var at := tex.find("@")
	if at >= 0:
		kind = tex.substr(at + 1)
		tex = tex.substr(0, at)
	var hash_at := tex.find("#")
	if hash_at >= 0:
		tint = Color.html(tex.substr(hash_at + 1))
		tex = tex.substr(0, hash_at)
	# Blender appends .001 to duplicate names.
	var dot := tex.find(".")
	if dot >= 0:
		tex = tex.substr(0, dot)
	return [tex, tint, kind]


## Adds model `id` of `kit` at `xf` to the kit's builders (near and far).
## Returns false if the model is missing (the caller can fall back).
static func add(kit_out: MeshBuilder.Kit, kit: String, id: String, xf: Transform3D) -> bool:
	var models := _load(kit)
	if not models.has(id):
		return false
	var far_id := id + "_lod1"
	var has_far := models.has(far_id)
	if lod_distance <= 0.0 and has_far:
		_append(kit_out, models[far_id], xf, "")
		return true
	_append(kit_out, models[id], xf, "near" if has_far else "")
	if has_far:
		_append(kit_out, models[far_id], xf, "far")
	return true


static func _append(kit_out: MeshBuilder.Kit, parts: Array, xf: Transform3D, band: String) -> void:
	for p: Array in parts:
		var k := parse(p[2])
		var mb := kit_out.model(k[0], k[1], k[2], band)
		mb.append(p[0], p[1], xf)


## A standalone instance (for one-off props): its own MeshInstance3Ds with
## the game's materials, under a new Node3D.
static func instance(parent: Node3D, kit: String, id: String, xf: Transform3D, shadows := true) -> Node3D:
	var root := Node3D.new()
	root.transform = xf
	parent.add_child(root)
	var k := MeshBuilder.Kit.new()
	add(k, kit, id, Transform3D.IDENTITY)
	k.build(root, shadows)
	return root
