extends SceneTree

## Dev: stills of the cars on the square in daylight (the «бобик» and the
## «Москвич» from tools/blender, next to the «Жигули»).
##   godot --path . -s scripts/dev_carshot.gd -- /tmp/dir


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp"
	DirAccess.make_dir_recursive_absolute(out)
	Graphics.install(self)
	var ext := Exterior.new("day")
	root.add_child(ext)
	await process_frame
	ext.zhiguli.visible = false
	var spot := Exterior.ZHIGULI_SPOT
	var cars: Array[Node3D] = [Vehicles.bobik()]
	if ResourceLoader.exists(Vehicles.MOSKVICH.model):
		cars.append(Vehicles.build(Vehicles.MOSKVICH))
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.far = 400.0
	root.add_child(cam)
	cam.current = true
	root.size = Vector2i(1280, 720)
	for c in cars.size():
		var car := cars[c]
		ext.add_child(car)
		car.position = spot
		car.rotation.y = PI * 0.25
		for v in 3:
			var eye: Vector3 = [Vector3(-3.6, 1.5, -4.2), Vector3(4.2, 1.3, 2.6), Vector3(-1.2, 2.4, 4.8)][v]
			cam.global_position = spot + eye
			cam.look_at(spot + Vector3(0, 0.8, 0))
			ext.follow(cam)
			for f in 24:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg("%s/car%d_%d.jpg" % [out, c, v], 0.85)
		car.queue_free()
	quit()
