extends SceneTree

## Dev: stills of the street outside without the cutscene timing.
##   godot --path . -s scripts/dev_extshot.gd -- night /tmp/dir [seat]
## Writes a few fixed views of the Exterior (night or day); with "seat" only
## the view from the driver's seat of the «Жигули», with "feet" his feet on
## the pedals.

const VIEWS := [
	[Vector3(-14, 16, -46), Vector3(2, 4, 0)],
	[Vector3(2.5, 1.7, -22), Vector3(2.5, 3.5, 0)],
	[Vector3(-10, 2.6, -32), Vector3(2.5, 3.5, 0)],
	[Vector3(30, 8, -40), Vector3(30, 8, 0)],
	[Vector3(3, 1.4, -16), Vector3(4.6, 0.8, -11.4)],
	[Vector3(9, 1.2, -14), Vector3(4.6, 0.6, -11.4)],
	[Vector3.ZERO, Vector3.FORWARD],
]
## Close-ups of the street furniture ("detail"): kiosk, phone booths, bus stop,
## the bottle-return door, a block entrance, the roof slogan, lawn and benches.
const DETAIL := [
	[Vector3(-13.0, 1.6, -22.0), Vector3(-15.5, 1.3, -17.0)],
	[Vector3(12.0, 1.6, -7.5), Vector3(14.3, 1.3, -2.0)],
	[Vector3(-34.5, 1.6, -26.0), Vector3(-38.0, 1.3, -20.6)],
	[Vector3(-13.0, 1.7, -8.0), Vector3(-16.0, 1.2, 0.0)],
	[Vector3(30.0, 1.7, -8.0), Vector3(36.0, 1.5, 2.0)],
	[Vector3(30.0, 12.0, -40.0), Vector3(46.0, 26.0, 0.0)],
	[Vector3(-6.0, 1.6, -18.0), Vector3(-14.0, 0.5, -11.0)],
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var look: String = args[0] if args.size() > 0 else "night"
	var out: String = args[1] if args.size() > 1 else "/tmp"
	Graphics.install(self)
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
	var only_seat := args.size() > 2 and args[2] in ["seat", "feet"]
	if args.size() > 2 and args[2] == "feet":  # the footwell, as in the cutscene
		ext.zhiguli.position = Exterior.ZHIGULI_SPOT + Vector3(0, 0, -9)
		cam.fov = 55.0
		var e := Vector3(-0.34, 1.0, 0.02)
		cam.global_transform = ext.zhiguli.global_transform * Transform3D(
			Basis.looking_at(Vector3(-0.4, 0.4, -0.55) - e, Vector3.UP), e)
		for f in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("%s/%s_feet.jpg" % [out, look], 0.85)
		var e2 := Vector3(0.45, 0.62, -0.25)
		cam.global_transform = ext.zhiguli.global_transform * Transform3D(
			Basis.looking_at(Vector3(-0.4, 0.5, -0.3) - e2, Vector3.UP), e2)
		for f in 2:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("%s/%s_feet_side.jpg" % [out, look], 0.85)
		quit()
		return
	if args.size() > 2 and args[2] == "detail":
		for i in DETAIL.size():
			cam.global_position = DETAIL[i][0]
			cam.look_at(DETAIL[i][1])
			ext.follow(cam)
			for f in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg("%s/%s_d%d.jpg" % [out, look, i], 0.85)
		quit()
		return
	for i in VIEWS.size():
		if only_seat and i != VIEWS.size() - 1:
			continue
		cam.global_position = VIEWS[i][0]
		cam.look_at(VIEWS[i][1])
		if i == VIEWS.size() - 1:  # the driver's seat
			ext.zhiguli.position = Exterior.ZHIGULI_SPOT + Vector3(0, 0, -9)
			cam.fov = 62.0
			cam.global_transform = ext.zhiguli.global_transform * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-10.0)),
				ext.zhiguli.get_meta("seat"))
		ext.follow(cam)
		for f in 24:  # the volumetric fog settles over a few frames
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("%s/%s_%d.jpg" % [out, look, i], 0.85)
	quit()
