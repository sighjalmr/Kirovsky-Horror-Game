extends SceneTree

## Dev: close-ups of one of the people, front, three-quarter and side.
##   godot --path . -s scripts/dev_portrait.gd -- kolesnikov /tmp/dir [tag]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var role: String = args[0] if args.size() > 0 else "kolesnikov"
	var out: String = args[1] if args.size() > 1 else "/tmp"
	var tag: String = args[2] if args.size() > 2 else ""
	root.size = Vector2i(1280, 720)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.34, 0.33)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.7)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.6, 0.5, 0)
	sun.light_energy = 1.4
	root.add_child(sun)
	var n := Npc.new().setup(role)
	root.add_child(n)
	n.global_position = Vector3.ZERO
	n.rotation.y = PI
	var cam := Camera3D.new()
	cam.fov = 30.0
	root.add_child(cam)
	cam.current = true
	for f in 30:
		await process_frame
	if "nohat" in args:
		for ba in n.body.skeleton.find_children("*", "BoneAttachment3D", true, false):
			ba.visible = false
	var head := Vector3(0, 1.68, 0)
	var views := {"front": Vector3(0, 1.75, 1.6), "three": Vector3(1.1, 1.8, 1.2), "side": Vector3(1.6, 1.72, 0.0),
		"full": Vector3(0.6, 1.3, 4.2)}
	for k: String in views:
		var at: Vector3 = head if k != "full" else Vector3(0, 1.0, 0)
		cam.global_transform = Transform3D(Basis.looking_at(at - views[k], Vector3.UP), views[k])
		for f in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("%s/%s_%s%s.jpg" % [out, role, k, tag], 0.9)
	quit()
