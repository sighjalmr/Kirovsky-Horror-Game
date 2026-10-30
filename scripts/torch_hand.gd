class_name TorchHand
extends Node3D

## Gordeev's right hand squeezing the «жучок», the first-person viewmodel.
## The fist is posed in Blender by tools/build_torch_hand.py: the hand model
## (models/hand, Godot XR Tools, CC0) with its fingers closed one joint at a
## time until they rest on the torch, four fingers round the steel lever
## underneath, the thumb laid straight along the top towards the glass, a
## wool coat sleeve from the wrist towards the elbow. The pose is baked into
## models/torch_hand/torch_hand.glb.
## Origin: the middle of the torch, the lens looking down -z; the fist sits
## on the torch's +y side and the player turns the whole thing so the thumb
## is on top (see player.gd HAND_ROT).

const SCENE := "res://models/torch_hand/torch_hand.glb"
## Where the beam leaves the glass.
const LENS := Vector3(0, 0, -0.056)

var model: Node3D
var _lit: Array[StandardMaterial3D] = []


func _ready() -> void:
	model = (load(SCENE) as PackedScene).instantiate()
	add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.name.begins_with("mesh_Hand"):
			mi.material_override = _skin()
		elif mi.name == "sleeve":
			mi.material_override = Mats.get_mat("guard_wool")
		elif mi.name in ["torch_lens", "torch_bulb"]:
			var m := mi.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
			m.emission_enabled = true
			m.emission = Color(1.0, 0.86, 0.6)
			m.emission_energy_multiplier = 0.0
			mi.material_override = m
			_lit.append(m)


func set_lit(on: bool) -> void:
	for m in _lit:
		m.emission_energy_multiplier = (2.0 if m.albedo_color.a < 1.0 else 6.0) if on else 0.0


## The skin of a man past fifty under shop light: the model's photo texture
## graded paler and greyer, with its own relief and roughness maps.
func _skin() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://models/hand/hand_skin.png")
	m.normal_enabled = true
	m.normal_texture = load("res://models/hand/hands_normal.png")
	m.normal_scale = 0.5
	m.ao_enabled = true
	m.ao_texture = load("res://models/hand/hands_occlusionRoughnessMetallic.png")
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness_texture = m.ao_texture
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.roughness = 1.0
	m.metallic_specular = 0.35
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m
