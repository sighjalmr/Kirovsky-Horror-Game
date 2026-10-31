extends SceneTree

## Dev: stills of the street outside without the cutscene timing.
##   godot --path . -s scripts/dev_extshot.gd -- night /tmp/dir
## Writes a few fixed views of the Exterior (night or day).

const VIEWS := [
	[Vector3(-14, 16, -46), Vector3(2, 4, 0)],
	[Vector3(2.5, 1.7, -22), Vector3(2.5, 3.5, 0)],
	[Vector3(-10, 2.6, -32), Vector3(2.5, 3.5, 0)],
	[Vector3(30, 8, -40), Vector3(30, 8, 0)],
	[Vector3(3, 1.4, -16), Vector3(4.6, 0.8, -11.4)],
	[Vector3(9, 1.2, -14), Vector3(4.6, 0.6, -11.4)],
	[Vector3.ZERO, Vector3.FORWARD],
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var look: String = args[0] if args.size() > 0 else "night"
	var out: String = args[1] if args.size() > 1 else "/tmp"
	var ext := Exterior.new(look)
	root.add_child(ext)
	await process_frame
	ext.light_signs(look == "night")
	ext.zhiguli.visible = true
	ext.zhiguli.position = Exterior.ZHIGULI_SPOT
	ext.zhiguli.rotation.y = PI
	Vehicles.set_lights(ext.zhiguli, true)
	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.far = 400.0
	root.add_child(cam)
	cam.current = true
	root.size = Vector2i(1280, 720)
	for i in VIEWS.size():
		cam.global_position = VIEWS[i][0]
		cam.look_at(VIEWS[i][1])
		if i == VIEWS.size() - 1:  # the driver's seat
			ext.zhiguli.position = Exterior.ZHIGULI_SPOT + Vector3(0, 0, -9)
			cam.fov = 62.0
			cam.global_transform = ext.zhiguli.global_transform * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-4.0)),
				ext.zhiguli.get_meta("seat"))
		ext.follow(cam)
		for f in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("%s/%s_%d.jpg" % [out, look, i], 0.85)
	quit()
