class_name DriverLegs
extends Person

## Gordeev's legs in the «Жигули», for the look down at the pedals: a
## Rocketbox avatar in the seated clip with everything above the waist
## folded away (the hands on the wheel are their own model), the thighs,
## calves and feet aimed so the right foot rests on the accelerator and the
## left one on the floor beside the clutch. Car space: nose -Z, the driver
## on the left. `hip` is where the middle of his pelvis sits on the cushion.

## [bone, direction in car space] for each leg bone.
const POSE := [
	["Bip01 R Thigh", Vector3(0.07, 0.1, -0.36)],
	["Bip01 R Calf", Vector3(-0.05, -0.27, -0.24)],
	["Bip01 R Foot", Vector3(0.0, 0.1, -0.25)],
	["Bip01 L Thigh", Vector3(-0.03, 0.09, -0.34)],
	["Bip01 L Calf", Vector3(0.0, -0.27, -0.24)],
	["Bip01 L Foot", Vector3(-0.01, -0.02, -0.28)],
]

var hip := Vector3.ZERO
var _spine := -1


static func make(hip_: Vector3) -> DriverLegs:
	var d := DriverLegs.new()
	d.setup("man1", false)
	d.hip = hip_
	d.play("sit", 0.0, 0.0)
	for p: Array in POSE:
		d.aim(p[0], p[1])
	return d


func _process(delta: float) -> void:
	super(0.0)
	if _spine < 0:
		_spine = skeleton.find_bone("Bip01 Spine1")
	skeleton.set_bone_pose_scale(_spine, Vector3.ONE * 0.001)
	# Sit the pelvis on the cushion: move the whole avatar so the pelvis
	# bone lands on `hip` (every frame: the seated pose only settles once
	# the clip has run in the tree).
	var pelvis := skeleton.find_bone("Bip01 Pelvis")
	var at := (_model.transform * skeleton.transform * skeleton.get_bone_global_pose(pelvis)).origin
	position = hip - at
