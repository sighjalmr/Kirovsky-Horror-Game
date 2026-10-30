extends Node

## Developer smoke test. Run
##   godot --path . -- --autoshot=/tmp/shots
## and it plays a scripted run (Kovpak handing over the post, Tamara at the till,
## the post, the lockers, the tills, the lit hall, the dark with the flashlight,
## Kovpak with his carton, the fuse panel, the «Волга» at the doors, the morning,
## the killer, his attack, the death) saving a screenshot of each step, then quits.
## Add --handshot to take only the close-ups of the hand with the torch, or
## --storeshot for views of the building itself (walls, columns, ducts, window).

var main: Node
var out_dir := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	main.start_now()
	var p: Player = main.player
	var store: Store = main.store
	var night: NightOne = main.night
	if "--handshot" in OS.get_cmdline_user_args():
		await _hand_shots(p, store, night)
		get_tree().quit()
		return
	if "--storeshot" in OS.get_cmdline_user_args():
		await _store_shots(p, store, night)
		get_tree().quit()
		return
	_place(p, Vector3(9.4, 0, 2.6), Vector3(-1, 0, 0.05))
	await _wait(2.5)
	await _shot("00_kovpak")
	_place(p, Vector3(0.3, 0, 7.4), Vector3(-0.4, 0, 1))
	p.head.rotation.x = -0.12
	night.tamara.rotation.y = atan2(0.9, 2.0)
	await _wait(0.5)
	await _shot("00b_tamara")
	night.kovpak.visible = false
	night.tamara.visible = false
	p.head.rotation.x = 0.0
	_place(p, Vector3(8.2, 0, 3.6), Vector3(1, 0, -0.8))
	await _wait(1.0)
	await _shot("01_post")
	_place(p, Vector3(-7.0, 0, 3.4), Vector3(-0.3, 0, -1))
	await _wait(1.0)
	await _shot("02_lockers")
	_place(p, Vector3(0.5, 0, 5.0), Vector3(-0.3, 0, 1))
	await _wait(1.0)
	await _shot("03_checkout")
	_place(p, Vector3(3.6, 0, 14.5), Vector3(1, 0, 0.9))
	p.head.rotation.x = -0.15
	await _wait(1.0)
	await _shot("03b_shelves")
	_place(p, Vector3(-7.5, 0, 12.6), Vector3(-0.8, 0, 1))
	p.head.rotation.x = -0.35
	await _wait(1.0)
	await _shot("03c_chests")
	_place(p, Vector3(-10.3, 0, 11.5), Vector3.BACK)
	await _wait(1.5)
	await _shot("04_hall_lit")
	for i in store.rows.size():
		store.switch_off(i)
	await _wait(3.5)
	await _shot("05_hall_dark")
	p.force_flashlight = true
	await _wait(0.6)
	await _shot("06_flashlight")
	# Kovpak's night visit: out of the storage room with the carton.
	night.kovpak.visible = true
	night.kovpak.carry(true)
	night.kovpak.global_position = Vector3(9.0, 0, 26.4)
	night.kovpak.rotation.y = 0.15
	_place(p, Vector3(7.6, 0, 22.6), Vector3(0.35, 0, 1))
	p.head.rotation.x = -0.05
	await _wait(0.8)
	await _shot("10_kovpak_box")
	night.kovpak.visible = false
	_place(p, Vector3(-0.2, 0, 26.0), Vector3(-0.2, 0, 1))
	p.head.rotation.x = 0.05
	await _wait(0.6)
	await _shot("11_panel")
	p.force_flashlight = false
	store.car_arrive()
	_place(p, Vector3(1.4, 0, 4.0), Vector3(-0.45, 0, -1))
	p.head.rotation.x = -0.25
	await _wait(5.5)
	await _shot("12_volga")
	night.vasya.visible = true
	night.vasya.global_position = Vector3(-0.6, 0, 1.8)
	night.vasya.rotation.y = 0.5
	night.kovpak.visible = true
	night.kovpak.carry(false)
	night.kovpak.global_position = Vector3(0.6, 0, 2.3)
	night.kovpak.rotation.y = -0.4
	_place(p, Vector3(1.5, 0, 5.4), Vector3(-0.4, 0, -1))
	await _wait(0.6)
	await _shot("13_morning")
	night.vasya.visible = false
	night.kovpak.visible = false
	store.car.visible = false
	p.force_flashlight = true
	_place(p, Vector3(-10.3, 0, 11.5), Vector3.BACK)
	await _wait(0.6)
	var k: Killer = main.killer
	k.activate(p.global_position + Vector3(0, 0, 6.5))
	await _wait(0.9)
	await _shot("07_killer")
	while k.state != Killer.State.ATTACK:
		await _wait(0.1)
	await _wait(0.65)
	await _shot("08_attack")
	await _wait(7.0)
	await _shot("09_death")
	get_tree().quit()


func _hand_shots(p: Player, store: Store, night: NightOne) -> void:
	night.kovpak.visible = false
	night.tamara.visible = false
	p.force_flashlight = true
	_place(p, Vector3(3.6, 0, 14.5), Vector3(1, 0, 0.9))
	p.head.rotation.x = -0.15
	await _wait(1.0)
	await _shot("h1_lit")
	p.head.rotation.x = -0.6
	await _wait(0.6)
	await _shot("h2_down")
	_place(p, Vector3(-10.3, 0, 11.5), Vector3.BACK)
	p.head.rotation.x = 0.0
	for i in store.rows.size():
		store.switch_off(i)
	await _wait(3.5)
	await _shot("h3_dark")
	p.force_flashlight = false
	await _wait(0.12)
	await _shot("h4_lowering")
	await _wait(0.8)
	await _shot("h5_off")


func _store_shots(p: Player, store: Store, night: NightOne) -> void:
	night.kovpak.visible = false
	night.tamara.visible = false
	var views := [
		["s1_window", Vector3(-1.5, 0, 5.0), Vector3(0.7, 0, -1), 0.05],
		["s2_aisle", Vector3(-3.0, 0, 11.2), Vector3(0, 0, 1), 0.12],
		["s3_column", Vector3(-4.2, 0, 16.2), Vector3(-0.6, 0, 1), 0.2],
		["s4_back", Vector3(-6.5, 0, 25.6), Vector3(-0.55, 0, 1), 0.0],
		["s5_entrance", Vector3(-6.5, 0, 6.5), Vector3(-1, 0, -0.5), 0.0],
		["s6_ceiling", Vector3(-3.0, 0, 18.5), Vector3(0, 0, 1), 0.55],
	]
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(0.8)
		await _shot(v[0])
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	for v: Array in [views[0], views[2], views[3]]:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(0.8)
		await _shot(v[0] + "_dark")


func _place(p: Player, pos: Vector3, dir: Vector3) -> void:
	p.global_position = pos
	p.face(dir)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(id + ".png"))
	print("shot ", id)
