extends Node

## Developer screenshots of the square at night, without playing the night
## through (software rendering in a container draws a frame every few
## seconds). Run
##   xvfb-run -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 -- --streetshot=/tmp/street
##   ... -- --night2 --streetshot=/tmp/street
## Sets the state of each street scene by hand and saves a frame of it.

var main: Main
var out_dir := ""


func with(m: Main) -> Node:
	main = m
	return self


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	Killer.blind = true
	main.start_now()
	main.time_scale = 0.0
	await _frames(3)
	var n: NightOne = main.night
	for i in main.store.rows.size():
		main.store.switch_off(i, true)
	n.interact("spare_key")
	main.store.set_front_door(true)
	if n is NightFour:
		main.store.set_front_door(false)
		await _night_four(n as NightFour)
	elif n is NightThree:
		main.store.set_front_door(false)
		await _night_three(n as NightThree)
	elif n is NightTwo:
		await _night_two(n as NightTwo)
	else:
		await _night_one(n)
	get_tree().quit()


func _night_one(n: NightOne) -> void:
	await _shot("s01_doors_open", Vector3(-0.6, 0, 1.2), Vector3(0, 0, -1))
	await _shot("s02_porch", Vector3(0.5, 0, -4.8), Vector3(-0.35, 0, -1))
	await _shot("s03_store_from_square", Vector3(2.0, 0, -13.0), Vector3(0.15, 0, 1))
	await _shot("s04_kiosk", Vector3(-6.0, 0, -15.0), Vector3(-0.7, 0, -0.35))
	n.outdoors.hang_handset()
	n._butt = n.outdoors.drop_butt(Outdoors.BOOTH + Vector3(0.12, 0.05, -0.12))
	n.street["booth_call"] = true
	n.killer_phase = "out"
	await _shot("s05_booths_from_porch", Vector3(8.5, 0, -2.8), Vector3(1, 0, 0.05))
	n._watch_street()
	await _frames(8)
	await _shot("s06_figure", Vector3(11.0, 0, -4.0), Vector3(0.75, 0, 0.35))
	main.player.force_flashlight = true
	await _shot("s07_booth", Vector3(14.6, 0, -3.9), Vector3(0.05, 0, 1), -0.35)
	main.player.force_flashlight = false
	n.interact("booth")
	await _shot("s08_booth_after", Vector3(14.6, 0, -4.4), Vector3(0.05, 0, 1))
	await _shot("s09_key_box", Vector3(10.2, 0, 1.6), Vector3(-0.15, 0, -1))
	n.update_notebook()
	main.hud.notebook.visible = true
	await _shot("s10_notebook", Vector3(0, 0, 5), Vector3(0, 0, 1))


func _night_two(n: NightTwo) -> void:
	n.kolesnikov.visible = false
	n.kovpak.visible = false
	n.koles_state = "gone"
	n.koles_car = "sitting"
	n.koles_seat.visible = true
	await _shot("t01_square_to_kiosk", Vector3(-0.8, 0, -5.0), Vector3(-0.7, 0, -1))
	await _shot("t02_behind_kiosk", Vector3(-15.0, 0, -15.4), Vector3(-0.2, 0, -1))
	main.player.crouching = true
	await _shot("t03_round_corner", Vector3(-13.2, 0, -17.6), Vector3(-0.9, 0, -0.45))
	main.player.crouching = false
	await _shot("t04_side", Vector3(-17.5, 0, -16.9), Vector3(-0.1, 0, -1), -0.1)
	Vehicles.set_lights(n.outdoors.bobik, true, 30.0)
	(n.outdoors.bobik.get_node("Dome") as OmniLight3D).light_energy = 1.4
	await _shot("t05_spotted", Vector3(-13.0, 0, -18.6), Vector3(-1, 0, -0.25))
	Vehicles.set_lights(n.outdoors.bobik, false)
	(n.outdoors.bobik.get_node("Dome") as OmniLight3D).light_energy = 0.0
	n.koles_seat.visible = false
	n.koles_car = "empty"
	n.kolesnikov.visible = true
	n.kolesnikov.global_position = Vector3(-22.6, Outdoors.GROUND, -14.0)
	n.kolesnikov.walk(PackedVector3Array([Vector3(-23.0, 0, -12.0), Vector3(-25.5, 0, -4.0)]))
	await _shot("t06_goes_round", Vector3(-18.5, 0, -17.0), Vector3(-0.8, 0, 0.6))
	n.kolesnikov.visible = false
	main.player.force_flashlight = true
	await _shot("t07_empty_car", n.outdoors.bobik_point(Vector3(-2.0, 0, -0.2)), Vector3.FORWARD, -0.25,
		n.outdoors.bobik_point(Vector3(0, 1.0, 0.3)))


## Night three: the wire, the office, the cellar, Nina, the morning.
##   ... -- --night3 --streetshot=/tmp/n3
func _night_four(n: NightFour) -> void:
	n.kovpak.visible = false
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.get_slice("=", 1)
	await _shot4(only, "v01_seal", Vector3(Store.CELLAR_X + 0.4, 0, 26.6), Vector3(0, 0, 1), -0.12, true)
	main.store.power_cut()
	n.rooms.cut_wire()
	main._lit = 0.0
	var k: Killer = main.killer
	var bx := -3.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--beamx="):
			bx = float(a.get_slice("=", 1))
	k.activate(Vector3(bx + 0.3, 0, 17.6))
	k.look_at(Vector3(bx, 0, 12.5), Vector3.UP)
	k.deactivate()
	k.visible = true
	k.set_torch(true)
	await _frames(4)
	k.torch.rotation.x = deg_to_rad(-10.0)
	await _shot4(only, "v02_beam", Vector3(bx, 0, 12.5), Vector3(0.03, 0, 1), 0.02, true)
	k.visible = false
	k.set_torch(false)
	await _shot4(only, "v03_panel", Vector3(-0.5, 0, 26.7), Vector3(0, 0, 1), 0.05, true)
	await _shot4(only, "v04_wire", Vector3(6.2, 0, 26.2), Vector3(0.05, 0, 1), 0.45, true)
	main.store.open_cellar(true)
	await _shot4(only, "v05_cellar", Vector3(Store.CELLAR_X + 0.2, BackRooms.FLOOR, 32.2), Vector3(-0.55, 0, 1), -0.25, true)
	await _shot4(only, "v06_vent", Vector3(-4.2, BackRooms.FLOOR, 35.55), Vector3(0, 0, 1), 0.0, true)
	n.rooms.open_vent(true)
	await _shot4(only, "v07_duct", Vector3(-4.3, BackRooms.FLOOR, 35.75), Vector3(0, 0, 1), -0.05, true)
	n.rooms.open_tin()
	main.player.crouching = true
	await _shot4(only, "v08_tin", Vector3(-4.31, BackRooms.FLOOR, 35.9), Vector3(0, 0, 1), -0.8, true)
	main.player.crouching = false
	n.clues = {"panel": true, "wire": true, "prints": true, "box": true, "earring": true}
	n.power_cut = true
	n.seal_seen = true
	n.has_box = true
	n.update_notebook()
	main.hud.notebook.visible = only == "" or only == "v09_notebook"
	await _shot4(only, "v09_notebook", Vector3(0, 0, 5), Vector3(0, 0, 1), 0.0, false)


func _shot4(only: String, id: String, pos: Vector3, dir: Vector3, pitch: float, torch: bool) -> void:
	if only != "" and only != id:
		return
	main.hud.clear_subtitles()
	main.player.force_flashlight = torch
	await _shot(id, pos, dir, pitch)
	main.player.force_flashlight = false


func _night_three(n: NightThree) -> void:
	n.kovpak.visible = false
	n.line = "open"
	main.store.open_office(true)
	main.night.update_notebook()
	await _shot("u01_wire", Vector3(9.4, 0, 21.0), Vector3(0.45, 0, 1), 0.28)
	await _shot("u02_office_door", Vector3(2.4, 0, 24.2), Vector3(0.05, 0, 1), 0.02)
	main.player.force_flashlight = true
	await _shot("u03_office_desk", Vector3(1.75, 0, 29.0), Vector3.FORWARD, -0.42, BackRooms.HANDSET)
	main.player.force_flashlight = false
	await _shot("u04_cellar_padlock", Vector3(Store.CELLAR_X + 0.2, 0, 26.4), Vector3(0, 0, 1), -0.1)
	n._talked["cellar"] = true
	n.interact("crowbar")
	await _shot("u05_crowbar_gone", Vector3(-8.6, 0, 26.6), Vector3(-0.5, 0, 1), 0.1)
	n.rooms.show_broken_lock()
	main.store.open_cellar(true)
	main.player.force_flashlight = true
	await _shot("u06_stairs", Vector3(Store.CELLAR_X, 0, 28.15), Vector3(0, 0, 1), -0.45)
	await _shot("u07_cellar", Vector3(Store.CELLAR_X + 0.3, BackRooms.FLOOR, 32.3), Vector3(-0.1, 0, 1), -0.12)
	n.rooms.open_fridge(true)
	await _shot("u08_body", Vector3(BackRooms.FRIDGE.x + 0.15, BackRooms.FLOOR, BackRooms.FRIDGE.z - 1.25), Vector3(0, 0, 1), -0.38)
	await _shot("u09_boots", Vector3(Store.CELLAR_X - 0.1, BackRooms.FLOOR, 32.7), Vector3(0, 0, 1), -0.9)
	main.player.force_flashlight = false
	for i in main.store.rows.size():
		main.store.switch_on(i)
	var koles := Npc.new().setup("kolesnikov")
	main.world.add_child(koles)
	koles.global_position = Vector3(5.6, 0, 3.0)
	koles.look_at_point(Vector3(7.6, 0, 3.6))
	n.kovpak.visible = true
	n.kovpak.global_position = Vector3(4.6, 0, 4.6)
	n.kovpak.look_at_point(koles.global_position)
	await _frames(10)
	await _shot("u10_morning", Vector3(7.6, 0, 3.6), Vector3.FORWARD, 0.04, Vector3(5.6, 0, 3.0))
	n.update_notebook()
	main.hud.notebook.visible = true
	await _shot("u11_notebook", Vector3(0, 0, 5), Vector3(0, 0, 1))


func _shot(id: String, pos: Vector3, dir: Vector3, pitch := 0.0, look := Vector3.INF) -> void:
	main.player.global_position = pos
	if look != Vector3.INF:
		dir = look - pos
		dir.y = 0.0
	main.player.face(dir)
	main.player.head.rotation.x = pitch
	await _frames(4)
	await RenderingServer.frame_post_draw
	main.get_viewport().get_texture().get_image().save_png(out_dir.path_join(id + ".png"))
	print("shot ", id, " at ", main.player.global_position)


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
