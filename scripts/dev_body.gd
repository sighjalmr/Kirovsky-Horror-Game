extends SceneTree

## Dev: Nina's body on its own under a torch, from the front and the side.
##   godot --path . -s scripts/dev_body.gd -- /tmp/dir [nopaper]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp"
	root.size = Vector2i(1280, 720)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.5)
	env.ambient_light_energy = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3, 3)
	floor.mesh = pm
	floor.material_override = Mats.get_mat("enamel", Color(0.7, 0.7, 0.66))
	root.add_child(floor)
	var body := NinaBody.new()
	root.add_child(body)
	var cam := Camera3D.new()
	cam.fov = 45.0
	root.add_child(cam)
	cam.current = true
	var torch := SpotLight3D.new()
	torch.light_energy = 6.0
	torch.spot_range = 6.0
	torch.spot_angle = 30.0
	cam.add_child(torch)
	torch.position = Vector3(0.2, -0.2, 0)
	for f in 20:
		await process_frame
	if "nopaper" in args:
		for c in body.get_children():
			if c is MeshInstance3D or c is Label3D:
				c.visible = false
	var views := {"front": Vector3(0.1, 1.45, -1.2), "side": Vector3(-1.2, 1.2, -0.4), "close": Vector3(-0.15, 1.15, -0.65)}
	for k: String in views:
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.45, 0) - views[k], Vector3.UP), views[k])
		for f in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("%s/body_%s.jpg" % [out, k], 0.9)
	quit()
