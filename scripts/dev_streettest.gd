extends "res://scripts/dev_nighttest.gd"

## Developer check of the street missions, with screenshots. Run
##   xvfb-run -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 -- --streettest=/tmp/street
##   ... -- --night2 --streettest=/tmp/street        (night two, sneaking up)
##   ... -- --night2 --streettest=/tmp/street --spotted   (night two, seen)
## Night one: takes the spare key, opens the doors, looks out over the square,
## answers the 00:40 call, goes out to the booth, sees the man go round the
## corner, looks into the booth. Night two: Колесников walks to his «бобик»,
## Gordeev creeps up behind the kiosk (or is seen), watches him leave the car
## at 23:03, looks into the empty car, and sees it drive off at 01:46.

var out_dir := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	if "--lowres" in OS.get_cmdline_user_args():
		# Software rendering in the container: a quarter of the pixels.
		main.view.size = Vector2i(960, 540)
		main.view.msaa_3d = Viewport.MSAA_DISABLED
	Killer.blind = true
	main.time_scale = 40.0
	main.start_now()
	await _wait(1.0)
	if main.night is NightTwo:
		await _night_two()
	else:
		await _night_one()
	print("notebook:\n", main.hud.notebook_text.text)
	get_tree().quit()


func _night_one() -> void:
	var n: NightOne = main.night
	await _until(22, 50)
	_use("door_front")
	_use("spare_key")
	_check(n.has_key, "spare key taken")
	_use("door_front")
	await _wait(3.0)
	_check(main.store.front_open, "glass doors open")
	_place(Vector3(-0.5, 0, 0.8), Vector3(0, 0, -1))
	await _wait(1.0)
	await _shot("s01_doors_open")
	_place(Vector3(0.5, 0, -4.8), Vector3(-0.3, 0, -1))
	await _wait(1.5)
	print("porch y ", main.player.global_position.y, " mix ", n.outdoors.mix)
	await _shot("s02_porch")
	_place(Vector3(1.0, 0, -6.6), Vector3(0, 0, -1))
	await _wait(0.5)
	print("steps y ", main.player.global_position.y)
	_place(Vector3(2.0, 0, -12.0), Vector3(0.2, 0, 1))
	await _wait(2.5)
	print("square y ", main.player.global_position.y, " mix ", n.outdoors.mix)
	await _shot("s03_store_from_square")
	_place(Vector3(-6.0, 0, -15.0), Vector3(-0.6, 0, -0.4))
	await _wait(1.0)
	await _shot("s04_kiosk")
	# Back in, wait for the call.
	_place(Vector3(10.3, 0, 3.0), Vector3(0, 0, -1))
	await _until_true(func(): return n._phone_t > 0.0, 600.0)
	print("phone at ", main._fmt(main.minutes), " killer ", n.killer_phase, " booth call ", n._booth_call)
	_use("phone")
	await _wait(8.0)
	_check(n.street.get("booth_call", false), "heard the street in the receiver")
	_place(Vector3(11.5, 0, -3.6), Vector3(0.6, 0, 0.4))
	await _wait(0.6)
	_check(n.street.get("figure", false), "figure going round the corner")
	await _wait(0.8)
	await _shot("s05_figure")
	_place(Vector3(14.6, 0, -4.4), Vector3(0.1, 0, 1))
	await _wait(1.0)
	await _shot("s06_booth")
	_use("booth", Vector3(14.78, 0, -3.0))
	_check(n.street.get("booth", false), "looked into the booth")
	await _wait(1.0)
	await _shot("s07_booth_after")
	var saved: Dictionary = n.save_state()
	n.restore_state(saved)
	_check(n.has_key and n.street.get("booth", false), "save and restore keep the street")
	await _until_true(func(): return n.killer_phase == "in", 300.0)
	print("caller back at ", main._fmt(main.minutes))
	_place(Vector3(0.0, 0, 5.0), Vector3(0, 0, -1))
	main.hud.notebook.visible = true
	await _wait(0.5)
	await _shot("s08_notebook")
	main.hud.notebook.visible = false


func _night_two() -> void:
	var n: NightTwo = main.night
	var spotted := "--spotted" in OS.get_cmdline_user_args()
	await _until_true(func(): return main.hud.choices.visible, 300.0)
	main.hud.chosen.emit(2)
	_use("spare_key")
	await _until_true(func(): return n.koles_car == "walking", 300.0)
	print("koles walking at ", main._fmt(main.minutes))
	_place(Vector3(-0.5, 0, 1.0), Vector3(-0.3, 0, -1))
	await _wait(9.0)
	await _shot("t01_koles_walks")
	await _until_true(func(): return n.koles_car == "sitting", 120.0)
	print("koles in the car at ", main._fmt(main.minutes))
	_use("door_front")
	await _wait(3.0)
	if spotted:
		_place(Vector3(-12.5, 0, -20.2), Vector3(-1, 0, 0.1))
		await _wait(3.0)
		_check(n.street.get("spotted", false), "seen by Колесников")
		await _shot("t02_spotted")
		await _wait(5.0)
	else:
		# Creep up behind the kiosk, crouched, and look round its corner.
		main.player.crouching = true
		_place(Vector3(-15.5, 0, -15.0), Vector3(0, 0, -1))
		await _wait(1.5)
		_check(not n.street.get("spotted", false), "not seen behind the kiosk")
		_place(Vector3(-13.3, 0, -17.4), Vector3(-0.8, 0, -0.5))
		await _wait(0.5)
		await _shot("t02_watch")
		print("interactable: ", main.store.find_interactable(main.player).get("id", ""))
		main.night.interact("bobik_watch")
		_check(n.street.get("bobik", false), "watched him in the car")
		main.player.crouching = false
		await _wait(1.0)
		_place(Vector3(-18.0, 0, -17.6), Vector3(0, 0, -1))
		await _wait(1.0)
		await _shot("t03_close")
	_place(Vector3(-17.0, 0, -12.0), Vector3(-0.3, 0, -1))
	await _until_true(func(): return n.koles_car == "empty", 300.0)
	print("koles out of the car at ", main._fmt(main.minutes), " sneaks ", n.street.get("sneaks", false))
	await _wait(2.0)
	await _shot("t04_goes_round")
	main.player.force_flashlight = true
	_use("bobik_car", outdoors_point(n, Vector3(-1.3, 0, -0.4)))
	_check(n.street.get("car", false), "looked into the empty car")
	await _wait(1.0)
	await _shot("t05_empty_car")
	main.player.force_flashlight = false
	await _until_true(func(): return n.koles_car == "gone", 900.0)
	print("bobik gone at ", main._fmt(main.minutes))
	main.hud.notebook.visible = true
	await _wait(0.5)
	await _shot("t06_notebook")
	main.hud.notebook.visible = false


func outdoors_point(n: NightTwo, local: Vector3) -> Vector3:
	return n.outdoors.bobik_point(local)


func _place(pos: Vector3, dir: Vector3) -> void:
	main.player.global_position = pos
	main.player.face(dir)


func _shot(id: String) -> void:
	var f := FileAccess.open(out_dir.path_join("log.txt"), FileAccess.READ_WRITE if FileAccess.file_exists(out_dir.path_join("log.txt")) else FileAccess.WRITE)
	f.seek_end()
	f.store_line("%s %s fps %.2f night %s" % [main._fmt(main.minutes), id, Engine.get_frames_per_second(), main.night.street])
	f.close()
	if DisplayServer.get_name() == "headless":
		print("(shot ", id, " skipped headless)")
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(id + ".png"))
	print("shot ", id)


func _process(_delta: float) -> void:
	var n: NightOne = main.night
	var scene: bool = n.kovpak_state in ["prologue", "visit"] or main.killer.state == Killer.State.LEAVE
	if n is NightTwo:
		scene = (n as NightTwo).koles_state == "talk" or (n as NightTwo).koles_car in ["walking", "sitting"] \
			or (main.minutes > Main.clock(23, 1) and main.minutes < Main.clock(23, 4))
	main.time_scale = 1.0 if scene else 40.0
	if Engine.get_process_frames() % 20 == 0 and out_dir != "":
		var f := FileAccess.open(out_dir.path_join("tick.txt"), FileAccess.WRITE)
		f.store_line("%s frame %d killer %s scene %s" % [main._fmt(main.minutes), Engine.get_process_frames(),
			Killer.State.keys()[main.killer.state], scene])
		f.close()
