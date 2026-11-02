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
	if n is NightTwo:
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
