extends SceneTree

## Cuts the Rocketbox motion-capture clips down to what the store's people
## need and saves them as small Godot animations in models/people/anims.
## The source FBX files are not kept in the repository: download them from
## https://github.com/microsoft/Microsoft-Rocketbox/tree/master/Assets/Animations
## into _animsrc/ and run
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/make_people_anims.gd

const CLIPS := {
	"walk_m": "m_walk_neutral_01", "walk_f": "f_walk_neutral_01", "prowl": "m_walk_slow_01",
	"run": "m_run_neutral_01", "idle_m": "m_idle_neutral_01", "idle_f": "f_idle_neutral_01",
	"breathe_m": "m_idle_breathe_01", "talk_m": "m_gestic_talk_neutral_01",
	"talk_f": "f_gestic_talk_neutral_01", "sit_f": "f_sit_chair_idle_neutral_01",
	"bag_m": "m_hold_bag_idle", "bag_f": "f_hold_bag_idle_01",
}


func _init() -> void:
	# Any avatar will do: they all share the 81 bones of the Biped rig.
	var body: Node = (load("res://models/people/kovpak/kovpak.fbx") as PackedScene).instantiate()
	var skel: Skeleton3D = body.find_children("*", "Skeleton3D")[0]
	DirAccess.make_dir_recursive_absolute("res://models/people/anims")
	for key: String in CLIPS:
		var src: Node = (load("res://_animsrc/%s.max.fbx" % CLIPS[key]) as PackedScene).instantiate()
		var ap: AnimationPlayer = src.find_children("*", "AnimationPlayer")[0]
		var anim: Animation = ap.get_animation(ap.get_animation_list()[0]).duplicate(true)
		# Keep the bones the avatars have; drop the helpers, footsteps,
		# the extra facial bones and every scale track.
		for i in range(anim.get_track_count() - 1, -1, -1):
			var path := String(anim.track_get_path(i))
			var keep := path.begins_with("Skeleton3D:") and skel.find_bone(path.get_slice(":", 1)) >= 0 \
				and anim.track_get_type(i) != Animation.TYPE_SCALE_3D
			# Only the pelvis root moves; the other bones only turn.
			if keep and anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
				keep = path.get_slice(":", 1) in ["Bip01", "Bip01 Pelvis"]
			if not keep:
				anim.remove_track(i)
		anim.loop_mode = Animation.LOOP_LINEAR
		anim.optimize(0.01, 0.01, 0.01)
		anim.compress()
		ResourceSaver.save(anim, "res://models/people/anims/%s.res" % key)
		print(key, ": ", anim.length, " s, ", anim.get_track_count(), " tracks")
		src.free()
	body.free()
	quit()
