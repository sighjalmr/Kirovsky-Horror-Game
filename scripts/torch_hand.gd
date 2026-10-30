class_name TorchHand
extends Node3D

## Gordeev's right hand round the «жучок», the first-person viewmodel. The
## hand is a scanned-looking model with a skeleton (models/hand, CC0, from
## Godot XR Tools); four fingers are curled under the torch body over the
## lever and the thumb lies along the top. The torch itself is built here: an
## olive moulded body, a chrome bezel with its reflector, a domed glass and
## the bulb, the squeeze lever underneath. Origin: the middle of the torch,
## its lens looking down -z.

const HAND_SCENE := "res://models/hand/Hand_Nails_R.gltf"
## Fingers start straight and are curled onto the torch one joint at a time.
const POSE_OPEN := "res://models/hand/Default pose.res"
## The thumb is taken from this pose: straight, lying along the torch.
const POSE_THUMB := "res://models/hand/Grip 5.res"
## The thumb lies along the top of the torch: height of its middle line
## above the torch axis, and how far forward of its base it reaches.
const THUMB_TOP := 0.027
## A point of the torch axis in the hand model's own space: a finger's
## breadth off the middle of the palm (the palm faces -x).
const PALM_LINE := Vector3(-0.052, 0.0, -0.05)
## Distance from the torch axis at which a finger joint rests on the body.
const TOUCH := 0.031
## The torch is modelled at 1.2 times its size: a real «жучок» is 10 cm long.
const TORCH_SCALE := 0.76
## Where the beam leaves the glass.
const LENS := Vector3(0, 0, -0.062 * TORCH_SCALE)

## How the hand holds the torch: the angle between the torch and the line
## of the knuckles (degrees), and the fist rolled round the torch axis.
var diagonal := 55.0
var roll := 0.0
## The torch slides this far forward through the fist (metres).
var slide := 0.0
## The forearm leaves the wrist this way (towards the elbow).
var arm_dir := Vector3(0.55, -0.55, 0.62)

var model: Node3D
var lens_mat: ShaderMaterial
var bulb_mat: ShaderMaterial

var _body: Node3D
var _lever: Node3D
var _skeleton: Skeleton3D
var _open: Dictionary = {}  # bone index -> Quaternion
var _thumb: Dictionary = {}


func _ready() -> void:
	_build_torch()
	_build_hand()


func set_lit(on: bool) -> void:
	lens_mat.set_shader_parameter("emission", Color(0.9, 0.8, 0.6) if on else Color.BLACK)
	bulb_mat.set_shader_parameter("emission", Color(3.0, 2.6, 1.8) if on else Color.BLACK)


func _build_torch() -> void:
	lens_mat = Mats.unique("glass", Color(0.85, 0.9, 0.85, 0.45), Color.BLACK, Mats.GLASS)
	bulb_mat = Mats.unique("white", Color(0.7, 0.68, 0.6))
	var fwd := Basis(Vector3.RIGHT, -PI * 0.5)  # lathes pointing ahead (-z)
	var body := Node3D.new()
	body.scale = Vector3.ONE * TORCH_SCALE
	add_child(body)
	_body = body
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	# An oval moulded body, rounded at the back, a chrome bezel with a
	# polished reflector, a domed glass and the bulb behind it.
	var c := Vector3.ZERO
	var flat := fwd * Basis.from_scale(Vector3(1.2, 1.0, 0.9))
	kit.b("torch").lathe(Transform3D(flat, c), [Vector2(0, -0.066), Vector2(0.012, -0.065), Vector2(0.021, -0.061),
		Vector2(0.027, -0.054), Vector2(0.03, -0.042), Vector2(0.031, -0.02), Vector2(0.031, 0.015), Vector2(0.03, 0.035),
		Vector2(0.028, 0.046)], 28, Color.WHITE, Rect2(0, 0, 2, 1))
	var chrome := kit.b("chrome")
	chrome.lathe(Transform3D(fwd, c), [Vector2(0.025, 0.043), Vector2(0.031, 0.046), Vector2(0.0325, 0.05),
		Vector2(0.0325, 0.056), Vector2(0.031, 0.059), Vector2(0.026, 0.0595)], 28, Color.WHITE, Rect2(0, 0, 3, 0.3))
	chrome.lathe(Transform3D(fwd, c), [Vector2(0.026, 0.0595), Vector2(0.018, 0.055), Vector2(0.009, 0.05),
		Vector2(0.0, 0.048)], 28, Color(1.2, 1.18, 1.1), Rect2(0, 0.3, 3, 0.4))
	kit.custom(bulb_mat).ellipsoid(Transform3D(fwd, c + Vector3(0, 0, -0.052)), Vector3(0.0045, 0.006, 0.0045), 10, 6)
	kit.custom(lens_mat).lathe(Transform3D(fwd, c), [Vector2(0.0255, 0.0585), Vector2(0.018, 0.0605),
		Vector2(0.009, 0.0615), Vector2(0.0, 0.0618)], 28, Color.WHITE, Rect2(0.3, 0.3, 0.4, 0.4))
	kit.build(body, false)

	# The squeeze lever under the body, hinged at the front.
	var hinge := Vector3(0, -0.026, -0.042)
	_lever = Node3D.new()
	_lever.position = hinge
	body.add_child(_lever)
	var lk := MeshBuilder.Kit.new()
	lk.ao = false
	var lever := lk.b("metal", Color(0.55, 0.55, 0.5))
	for i in 7:
		var p := Vector3(0, -0.032 - i * 0.0012, -0.036 + i * 0.012) - hinge
		lever.box(Props.rot(Vector3.RIGHT, -0.1, p), Vector3(0.03 - i * 0.0008, 0.005, 0.013))
		lever.box(Props.at(p.x, p.y - 0.0012, p.z), Vector3(0.031 - i * 0.0008, 0.0015, 0.004), Color(0.75, 0.75, 0.7))
	lk.b("chrome").cylinder(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.018, -0.029, -0.04) - hinge), 0.004,
		0.004, 0.036, 10)
	lk.build(_lever, false)


func _build_hand() -> void:
	model = (load(HAND_SCENE) as PackedScene).instantiate()
	# The torch lies diagonally across the palm, from the heel of the hand to
	# the root of the index finger, as people really hold one: the lens ahead,
	# the forearm behind, the palm on the torch's side.
	var b := Basis(Vector3.BACK, deg_to_rad(roll)) * Basis(Vector3.RIGHT, deg_to_rad(diagonal - 90.0))
	model.transform = Transform3D(b, -(b * PALM_LINE) + Vector3(0, 0, slide))
	add_child(model)
	_skeleton = model.find_child("Skeleton3D", true, false)
	var mesh: MeshInstance3D = model.find_child("mesh_*", true, false)
	mesh.material_override = _skin()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pose in [[POSE_OPEN, _open], [POSE_THUMB, _thumb]]:
		var anim: Animation = load(pose[0])
		for i in anim.get_track_count():
			var bone := _skeleton.find_bone(String(anim.track_get_path(i).get_concatenated_subnames()))
			pose[1][bone] = anim.track_get_key_value(i, 0)
	for bone in _open:
		_skeleton.set_bone_pose_rotation(bone, _open[bone])
	for f in ["Index", "Middle", "Ring", "Little"]:
		for j in ["Proximal", "Intermediate", "Distal"]:
			_close_on_torch(_skeleton.find_bone("%s_%s_R" % [f, j]))
	_lay_thumb()

	# Wool sleeve: a turned cuff round the wrist on the line of the hand,
	# then the forearm inside the sleeve bending away towards the elbow
	# (arm_dir), so it leaves the frame instead of covering the view.
	var wrist := model.transform * Vector3(0, -0.004, 0.012)
	var stub := (model.basis * Vector3.BACK).normalized()
	var up := -stub
	var side := up.cross(Vector3.FORWARD).normalized()
	var sb := Basis(side, up, side.cross(up))
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	var wool := kit.b("guard_wool")
	var o := wrist - up * 0.012
	wool.lathe(Transform3D(sb, o), [Vector2(0.0, -0.02), Vector2(0.035, -0.015), Vector2(0.047, -0.01),
		Vector2(0.05, -0.005), Vector2(0.05, 0.008), Vector2(0.046, 0.012), Vector2(0.038, 0.01)],
		24, Color(0.75, 0.75, 0.72), Rect2(0, 0, 3, 0.3))
	# The forearm along a curve from the cuff: out along the hand, round
	# towards the elbow; short capsules make the bend.
	var p0 := o - stub * 0.01
	var p1 := p0 + stub * 0.02
	var p2 := p1 + arm_dir.normalized() * 0.36
	var prev := p0
	for i in range(1, 9):
		var t := i / 8.0
		var p := p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
		wool.capsule(Transform3D.IDENTITY, prev, p, 0.042 + 0.008 * (t - 0.125), 0.042 + 0.008 * t, 24, Color.WHITE,
			Rect2(0, 0, 3, 0.4))
		prev = p
	kit.build(self, false)


## Thumb straight along the top of the torch, pointing at the lens, the tip
## bent down a little onto the body: each bone is turned to aim at its point.
func _lay_thumb() -> void:
	for bone in _thumb:
		if _skeleton.get_bone_name(bone).begins_with("Thumb"):
			_skeleton.set_bone_pose_rotation(bone, _thumb[bone])
	var to_hand := model.transform.affine_inverse()  # torch space -> skeleton
	var meta := _skeleton.find_bone("Thumb_Metacarpal_R")
	var base := model.transform * _bone_global(meta).origin
	var knuckle := Vector3(base.x * 0.4, THUMB_TOP, base.z - 0.012)
	var aims: Array[Vector3] = [knuckle, knuckle + Vector3(0, 0.002, -0.04), knuckle + Vector3(0, -0.006, -0.072)]
	var chain: Array[int] = [meta, _skeleton.find_bone("Thumb_Proximal_R"), _skeleton.find_bone("Thumb_Distal_R")]
	for i in 3:
		var b := chain[i]
		var g := _bone_global(b)
		var want := ((to_hand * aims[i]) - g.origin).normalized()
		var have := g.basis.y.normalized()
		var turn := Quaternion(have, want) if have.cross(want).length() > 0.0001 else Quaternion.IDENTITY
		var parent := _bone_global(_skeleton.get_bone_parent(b)).basis
		var q := (parent.inverse() * Basis(turn) * g.basis).get_rotation_quaternion()
		_skeleton.set_bone_pose_rotation(b, q)


## Curls one finger bone (round its own z, the way the knuckle bends) until
## the joint after it touches the torch body, as a hand closing on it would.
func _close_on_torch(b: int) -> void:
	var tip := _skeleton.get_bone_children(b)[0]
	var start := _skeleton.get_bone_pose_rotation(b)
	var best := start
	var best_gap := INF
	for step in 60:
		var q := start * Quaternion(Vector3.BACK, deg_to_rad(-10.0 + step * 2.0))
		_skeleton.set_bone_pose_rotation(b, q)
		var p := model.transform * _bone_global(tip).origin
		var gap := Vector2(p.x / 1.1, p.y).length() - TOUCH
		if absf(gap) < best_gap:
			best_gap = absf(gap)
			best = q
		if gap < 0.0:
			break
	_skeleton.set_bone_pose_rotation(b, best)


## A bone's pose in skeleton space, worked out from the local poses.
func _bone_global(b: int) -> Transform3D:
	var t := _skeleton.get_bone_pose(b)
	var p := _skeleton.get_bone_parent(b)
	while p >= 0:
		t = _skeleton.get_bone_pose(p) * t
		p = _skeleton.get_bone_parent(p)
	return t


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
