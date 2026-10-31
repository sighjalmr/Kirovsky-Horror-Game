class_name Person
extends Node3D

## A real person: one of the Microsoft Rocketbox avatars (MIT licence, see
## models/people/CREDITS.md) with skin, clothes and hair from photographs, an
## 81-bone Biped skeleton and motion-captured walks, idles and talk. Front is
## -Z, feet on the origin.
##
## Over the captured motion an arm can be aimed by hand (carrying a carton,
## raising a cleaver): `aim()` turns a bone so it points a given way in the
## person's own space, which works whatever axes the rig uses.

const DIR := "res://models/people/"
const ANIMS := ["walk_m", "walk_f", "prowl", "run", "idle_m", "idle_f", "breathe_m", "talk_m", "talk_f",
	"sit_f", "bag_m", "bag_f"]

static var _lib: AnimationLibrary

## A foot comes down (walking or running clips, twice a loop).
signal footfall

var who: String
var woman := false
var skeleton: Skeleton3D
var player: AnimationPlayer
## The clip playing, without the m/f suffix ("walk", "idle", "talk"...).
var clip := ""
## What hangs from the left hand (a bag), if anything.
var bag: Node3D

## bone index -> [direction (person space), weight 0..1]
var _aims: Dictionary = {}
var _model: Node3D
var _phase := 0.0
var _pending: Array[Node3D] = []


func setup(name_: String, is_woman: bool) -> Person:
	who = name_
	woman = is_woman
	var model: Node3D = (load("%s%s/%s.fbx" % [DIR, who, who]) as PackedScene).instantiate()
	# The avatars look down +Z; the store's people look down -Z.
	model.rotation.y = PI
	add_child(model)
	_model = model
	skeleton = model.find_children("*", "Skeleton3D")[0]
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D"):
		_dress(mi)
	player = model.find_children("*", "AnimationPlayer")[0]
	player.add_animation_library("p", _library())
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	play("idle")
	player.advance(0.0)
	# Start everyone at a different moment of their idle so a queue does not
	# breathe in step.
	player.seek(randf() * 5.0, true)
	return self


static func _library() -> AnimationLibrary:
	if _lib == null:
		_lib = AnimationLibrary.new()
		for a: String in ANIMS:
			_lib.add_animation(a, load("%sanims/%s.res" % [DIR, a]))
	return _lib


## Photo textures on the shared store shader, so the people take the torch,
## the fog and the grade like everything else.
func _dress(mi: MeshInstance3D) -> void:
	for i in mi.mesh.get_surface_count():
		var src := mi.mesh.surface_get_material(i)
		var part := src.resource_name.get_slice("_", 1) if src else "body"
		var kind := Mats.SOLID
		var color := "%s%s/%s_color.jpg" % [DIR, who, part]
		if part == "opacity" or part == "glasses":
			# Hair, lashes and spectacle glass are cut-out cards seen from both sides.
			kind = Mats.DOUBLE
			color = "%s%s/%s%s_color.png" % [DIR, who, part, "_opacity" if part == "glasses" else ""]
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/%s.gdshader" % kind)
		m.set_shader_parameter("albedo_tex", load(color))
		var normal := "%s%s/%s_normal.jpg" % [DIR, who, part]
		if ResourceLoader.exists(normal):
			m.set_shader_parameter("normal_tex", load(normal))
		m.set_shader_parameter("roughness", 0.55 if part == "head" else 0.8)
		m.set_shader_parameter("specular", 0.35 if part == "head" else 0.2)
		mi.set_surface_override_material(i, m)


## Plays "walk", "idle", "talk", "sit", "bag", "run", "prowl" or "breathe",
## the woman's version where there is one. For a gait, `pace` is how fast the
## person really moves (m/s): the clip runs at the rate its feet cover that
## ground, so they plant on the floor instead of sliding.
func play(name_: String, pace := 0.0, blend := 0.35) -> void:
	var a := name_
	for suffix: String in (["_f", "_m"] if woman else ["_m", "_f"]):
		if (name_ + suffix) in ANIMS:
			a = name_ + suffix
			break
	var natural: float = (_library().get_animation(a) as Animation).get_meta("speed", 0.0)
	player.speed_scale = clampf(pace / natural, 0.5, 1.8) if natural > 0.0 and pace > 0.0 else 1.0
	if clip != name_:
		clip = name_
		player.play("p/" + a, blend)


## The bone (by its Biped name, "Bip01 R UpperArm") turns so it points along
## `dir` (person space: -Z forward, +Y up), `weight` of the way from where the
## animation has it. Weight 0 lets the animation have it back.
func aim(bone: String, dir: Vector3, weight := 1.0) -> void:
	var b := skeleton.find_bone(bone)
	if weight <= 0.0:
		_aims.erase(b)
	else:
		_aims[b] = [dir.normalized(), weight]


## A node that follows a bone (a hat on the head, a cleaver in the hand).
## `node` is built in the person's own space around the bone, as the bone
## stands in the idle pose: the arms hanging, the head upright.
func attach(bone: String, node: Node3D) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	var holder := Node3D.new()
	ba.add_child(holder)
	holder.add_child(node)
	_pending.append(holder)
	if is_inside_tree():
		_fit_attachments()
	return ba


func _ready() -> void:
	_fit_attachments()


## The idle pose only exists once the animation has run in the tree, so the
## attachments are squared up to it then.
func _fit_attachments() -> void:
	if _pending.is_empty():
		return
	var keep_aims := _aims
	_aims = {}
	var pos := player.current_animation_position
	player.play("p/" + ("idle_f" if woman else "idle_m"), 0.0)
	player.seek(0.0, true)
	var to_person := _model.transform * skeleton.transform
	for holder: Node3D in _pending:
		var bone := skeleton.find_bone((holder.get_parent() as BoneAttachment3D).bone_name)
		holder.basis = (to_person.basis * skeleton.get_bone_global_pose(bone).basis).orthonormalized().inverse()
	_pending.clear()
	_aims = keep_aims
	var c := clip
	clip = ""
	play(c, player.speed_scale, 0.0)
	player.seek(pos, true)


func _process(delta: float) -> void:
	player.advance(delta)
	# Two footfalls a loop: at the start and the middle of a gait clip.
	var anim := player.get_animation(player.current_animation) if player.current_animation != "" else null
	if anim and anim.get_meta("speed", 0.0) > 0.0:
		var ph := fmod(player.current_animation_position / anim.length * 2.0, 1.0)
		if ph < _phase:
			footfall.emit()
		_phase = ph
	if _aims.is_empty():
		return
	# Parents before children: bone indices already run down the hierarchy.
	var bones := _aims.keys()
	bones.sort()
	var to_skel := (_model.transform * skeleton.transform).affine_inverse()
	for b: int in bones:
		var child := _first_child(b)
		if child < 0:
			continue
		var g := skeleton.get_bone_global_pose(b)
		var now := (skeleton.get_bone_global_pose(child).origin - g.origin).normalized()
		var want: Vector3 = (to_skel.basis * (_aims[b][0] as Vector3)).normalized()
		var turn := Quaternion(now, want)
		var target := Basis(Quaternion.IDENTITY.slerp(turn, _aims[b][1])) * g.basis
		var parent := skeleton.get_bone_parent(b)
		var pb := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
		skeleton.set_bone_pose_rotation(b, (pb.inverse() * target).get_rotation_quaternion())


func _first_child(b: int) -> int:
	var c := skeleton.get_bone_children(b)
	return c[0] if c.size() > 0 else -1
