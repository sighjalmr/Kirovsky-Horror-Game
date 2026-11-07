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
	if "--propshot" in OS.get_cmdline_user_args():
		await _prop_shots(p, store)
		get_tree().quit()
		return
	if "--handshot" in OS.get_cmdline_user_args():
		await _hand_shots(p, store, night)
		get_tree().quit()
		return
	if "--polishshot" in OS.get_cmdline_user_args():
		await _polish_shots(p, store, night)
		get_tree().quit()
		return
	if "--taskshot" in OS.get_cmdline_user_args():
		await _task_shots(p, store, night)
		get_tree().quit()
		return
	if night is NightTwo:
		await _night2_shots(p, store, night)
		get_tree().quit()
		return
	if "--kitshot" in OS.get_cmdline_user_args():
		await _kit_shots(p, store, night)
		get_tree().quit()
		return
	if "--gfxshot" in OS.get_cmdline_user_args():
		await _gfx_shots(p, store, night)
		get_tree().quit()
		return
	if "--hallshot" in OS.get_cmdline_user_args():
		await _hall_shots(p, store, night)
		get_tree().quit()
		return
	if "--lifeshot" in OS.get_cmdline_user_args():
		await _life_shots(p, store, night)
		get_tree().quit()
		return
	if "--goodsshot" in OS.get_cmdline_user_args():
		await _goods_shots(p, store, night)
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


## Goods and refrigerated equipment close up (--goodsshot): each aisle's
## shelves at arm's length, the juice pyramid, the chests, the dairy wall.
func _goods_shots(p: Player, store: Store, night: NightOne) -> void:
	main.hud.visible = false
	night.kovpak.visible = false
	night.tamara.visible = false
	var views := [
		["g1_bakaleya", Vector3(-1.2, 0, 13.4), Vector3(1, 0, 0.9), 0.25],
		["g2_konservy", Vector3(1.2, 0, 13.4), Vector3(-1, 0, 0.9), 0.25],
		["g3_moloko", Vector3(7.6, 0, 13.4), Vector3(-1, 0, 0.9), 0.2],
		["g4_dairy_wall", Vector3(10.0, 0, 13.0), Vector3(1, 0, 0.8), 0.15],
		["g5_left_wall", Vector3(-10.0, 0, 13.0), Vector3(-1, 0, 0.8), 0.15],
		["g6_pyramid", Vector3(-1.6, 0, 14.6), Vector3(0, 0, 1), 0.5],
		["g7_chest", Vector3(-9.9, 0, 12.0), Vector3(0.3, 0, 1), 0.45],
		["g8_aisle", Vector3(-3.0, 0, 11.2), Vector3(0, 0, 1), 0.1],
	]
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = -v[3]
		await _wait(0.8)
		await _shot(v[0])
	store.lift_cloth("A1")
	_place(p, views[6][1], views[6][2])
	p.head.rotation.x = -0.45
	await _wait(0.8)
	await _shot("g7b_chest_open")
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	for v: Array in [views[0], views[3]]:
		_place(p, v[1], v[2])
		p.head.rotation.x = -v[3]
		await _wait(0.8)
		await _shot(v[0] + "_dark")


## The equipment and the life of the shop (--lifeshot): the tills, the
## register close up, the guard booth, the entrance with the control scales,
## the back passage with the cartons, the juice on the floor, the crates.
func _life_shots(p: Player, store: Store, night: NightOne) -> void:
	main.hud.visible = false
	night.kovpak.visible = false
	night.tamara.visible = false
	var views := [
		["l1_tills", Vector3(-4.6, 0, 5.4), Vector3(0.9, 0, 1), 0.12],
		["l2_register", Vector3(-1.3, 0, 7.2), Vector3(-1, 0, 0.35), 0.45],
		["l3_booth", Vector3(8.2, 0, 3.6), Vector3(1, 0, -0.6), 0.2],
		["l4_entrance", Vector3(-1.5, 0, 4.0), Vector3(-0.6, 0, -1), 0.12],
		["l5_back", Vector3(-3.0, 0, 25.0), Vector3(0.2, 0, 1), 0.15],
		["l6_juice", Vector3(3.0, 0, 20.4), Vector3(0.1, 0, 1), 0.55],
		["l7_crates", Vector3(9.6, 0, 24.6), Vector3(0.6, 0, 1), 0.3],
	]
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = -v[3]
		await _wait(0.8)
		await _shot(v[0])
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	for v: Array in [views[0], views[5]]:
		_place(p, v[1], v[2])
		p.head.rotation.x = -v[3]
		await _wait(0.8)
		await _shot(v[0] + "_dark")


## The two-storey hall (--hallshot): the gallery, the parapet, the letters on
## the back wall; at night with the rows lit, then dark with the torch, then
## in the day look.
func _hall_shots(p: Player, store: Store, night: NightOne) -> void:
	night.kovpak.visible = false
	night.tamara.visible = false
	var views := [
		["h1_from_tills", Vector3(-0.5, 0, 9.6), Vector3(0.05, 0, 1), 0.3],
		["h2_up_gallery", Vector3(-3.0, 0, 15.0), Vector3(-0.8, 0, 1), 0.5],
		["h3_back_letters", Vector3(1.5, 0, 13.0), Vector3(0, 0, 1), 0.38],
		["h4_look_back", Vector3(-1.5, 0, 23.0), Vector3(0.15, 0, -1), 0.4],
		["h5_aisle_d", Vector3(7.4, 0, 13.0), Vector3(0.1, 0, 1), 0.3],
	]
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(0.8)
		await _shot(v[0])
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	for v: Array in [views[1], views[3]]:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(0.8)
		await _shot(v[0] + "_dark")
	p.force_flashlight = false
	for i in store.rows.size():
		store.switch_on(i)
	main._day_look()
	await _wait(1.0)
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(0.8)
		await _shot(v[0] + "_day")


## Model comparison (--autoshot=DIR --kitshot): close views of the goods,
## shelves, cases, chests, tills and the back passage by day (no fog, so the
## shapes read), then three of them at night in the torch beam.
const KIT_VIEWS := [
	["k01_konservy", Vector3(1.25, 0, 14.0), Vector3(-1, 0, 0.6), -0.3],
	["k02_bakaleya", Vector3(-1.25, 0, 14.0), Vector3(1, 0, 0.6), -0.3],
	["k03_moloko", Vector3(9.9, 0, 14.5), Vector3(1, 0, 0.55), -0.25],
	["k04_frozen", Vector3(-9.9, 0, 14.5), Vector3(-1, 0, 0.5), -0.45],
	["k05_pyramid", Vector3(-3.4, 0, 14.0), Vector3(0.55, 0, 1), -0.4],
	["k06_tills", Vector3(-0.2, 0, 10.8), Vector3(-0.45, 0, -1), -0.3],
	["k07_chests", Vector3(-7.4, 0, 12.8), Vector3(-0.45, 0, 1), -0.5],
	["k08_back", Vector3(9.4, 0, 24.2), Vector3(0.6, 0, 1), -0.2],
	["k09_shelf_close", Vector3(0.75, 0, 16.0), Vector3(-1, 0, 0.25), -0.45],
	["k10_hall", Vector3(-3.0, 0, 11.0), Vector3(0.1, 0, 1), -0.1],
]


func _kit_shots(p: Player, store: Store, night: NightOne) -> void:
	main.hud.visible = false
	night.tamara.visible = false
	night.kovpak.visible = false
	if night.get("vasya") != null:
		night.vasya.visible = false
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	for v: Array in [KIT_VIEWS[0], KIT_VIEWS[2], KIT_VIEWS[8]]:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(1.0)
		await _shot(v[0] + "_dark")
	p.force_flashlight = false
	for i in store.rows.size():
		store.switch_on(i)
	main._day_look()
	for v: Array in KIT_VIEWS:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(1.0)
		await _shot(v[0] + "_day")


## Graphics comparison (--autoshot=DIR --gfxshot): the same views before and
## after a change to the look: Kovpak's face, the lit hall, the dark hall in
## the torch beam, the wet floor by the storeroom, the hall by day.
func _gfx_shots(p: Player, store: Store, night: NightOne) -> void:
	main.hud.visible = false
	night.tamara.visible = false
	night.kovpak.global_position = Vector3(7.9, 0, 2.6)
	night.kovpak.rotation.y = PI * 0.5
	_place(p, Vector3(9.3, 0, 2.7), Vector3(-1, 0, 0.0))
	p.head.rotation.x = 0.04
	await _wait(2.0)
	await _shot("g01_face")
	var kp: Vector3 = night.kovpak.global_position
	_place(p, kp + Vector3(0.95, 0, 0.05), Vector3(-1, 0, -0.05))
	p.head.rotation.x = 0.05
	p.camera.fov = 45.0
	await _wait(0.8)
	await _shot("g07_face_close")
	p.camera.fov = 70.0
	_place(p, Vector3(-0.5, 0, 9.6), Vector3(0.05, 0, 1))
	p.head.rotation.x = -0.75
	await _wait(0.8)
	await _shot("g08_floor")
	if "--gfxquick" in OS.get_cmdline_user_args():
		return
	night.kovpak.visible = false
	var views := [
		["g02_hall", Vector3(-0.5, 0, 9.6), Vector3(0.05, 0, 1), 0.3],
		["g03_gallery", Vector3(-3.0, 0, 15.0), Vector3(-0.8, 0, 1), 0.2],
		["g04_aisle", Vector3(7.4, 0, 13.0), Vector3(0.1, 0, 1), 0.0],
		["g05_back", Vector3(-1.5, 0, 23.0), Vector3(0.15, 0, -1), 0.1],
		["g06_store", Vector3(7.6, 0, 22.6), Vector3(0.35, 0, 1), -0.25],
	]
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(1.0)
		await _shot(v[0])
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	for v: Array in views:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(1.0)
		await _shot(v[0] + "_dark")
	p.force_flashlight = false
	for i in store.rows.size():
		store.switch_on(i)
	main._day_look()
	await _wait(1.0)
	for v: Array in [views[0], views[1]]:
		_place(p, v[1], v[2])
		p.head.rotation.x = v[3]
		await _wait(1.0)
		await _shot(v[0] + "_day")


## Night two (--night2 --autoshot=DIR): the участковый at the post, his
## question, the bag out of locker 31, the cellar door, the token on the
## floor, the post gone dark.
func _night2_shots(p: Player, store: Store, night: NightTwo) -> void:
	_place(p, Vector3(9.4, 0, 2.6), Vector3(-1, 0, 0.1))
	await _wait(3.0)
	await _shot("n2_01_handover")
	while not main.hud.choices.visible:
		await get_tree().process_frame
	_place(p, Vector3(8.0, 0, 3.6), Vector3(-1, 0, 0.25))
	p.head.rotation.x = 0.1
	await _wait(1.0)
	await _shot("n2_02_question")
	main.hud.chosen.emit(1)
	await _wait(0.5)
	p.head.rotation.x = 0.0
	_place(p, Vector3(-6.0, 0, 3.4), Vector3(-0.6, 0, -1))
	while not night.clues.seizure:
		await get_tree().process_frame
	await _wait(0.6)
	await _shot("n2_03_locker31")
	main.time_scale = 6.0
	while night.koles_state != "gone":
		await get_tree().process_frame
	for i in store.rows.size():
		store.switch_off(i, true)
	p.force_flashlight = true
	_place(p, Vector3(-2.5, 0, 25.6), Vector3(0.3, 0, 1))
	p.head.rotation.x = -0.12
	await _wait(1.5)
	await _shot("n2_04_cellar")
	store.show_floor_finds()
	_place(p, Vector3(8.15, 0, 26.2), Vector3(0.1, 0, 1))
	p.head.rotation.x = -0.9
	await _wait(1.5)
	await _shot("n2_05_token")
	p.head.rotation.x = -0.1
	store.set_duty(false)
	_place(p, Vector3(3.5, 0, 6.5), Vector3(0.75, 0, -0.65))
	await _wait(1.5)
	await _shot("n2_06_dark_post")


## The task list and the clue rings in a few states of the night
## (`--autoshot=DIR --taskshot`, add `--night2` for night two).
func _task_shots(p: Player, store: Store, night: NightOne) -> void:
	if night is NightTwo:
		main.minutes = Main.clock(1, 50)
		night.koles_state = "gone"
		night.clues.seizure = true
		store.show_floor_finds()
		store.set_duty(false, true)
		_place(p, Vector3(5.5, 0, 25.6), Vector3(1, 0, 0.5))
		await _wait(1.5)
		await _shot("t20_night2_token")
		_place(p, Vector3(-3.6, 0, 25.4), Vector3(0.6, 0, 1))
		await _wait(1.0)
		await _shot("t21_night2_cellar")
		return
	_place(p, Vector3(-0.2, 0, 5.6), Vector3(-0.5, 0, 1))
	await _wait(1.5)
	await _shot("t01_till")
	night.clues.bag = true
	night.clues.tape = true
	main.minutes = Main.clock(23, 40)
	night.rounds[0].door = true
	night._ring_phone()
	_place(p, Vector3(-4.0, 0, 15.0), Vector3(0.3, 0, 1))
	await _wait(1.0)
	await _shot("t02_round_phone")
	night.stop_sounds()
	night.rounds[0].signed = true
	main.minutes = Main.clock(2, 5)
	night.kovpak_state = "done"
	store.show_invoice()
	_place(p, Vector3(9.0, 0, 24.0), Vector3(0.2, 0, 1))
	p.flashlight_on = true
	await _wait(1.0)
	await _shot("t03_invoice")
	main.hud.toggle_tasks()
	await _wait(0.3)
	await _shot("t04_hidden")


## The night-one polish: the round's rings and directions, and him standing
## still at the end of a dark aisle.
func _polish_shots(p: Player, store: Store, night: NightOne) -> void:
	Killer.blind = true
	if night is NightTwo or night is NightThree or night is NightFour:
		await _polish_late(p, store, night)
		return
	main._timeline.clear()
	night.kovpak.visible = false
	night.tamara.visible = false
	night.kovpak_state = "none"
	night._talked["kovpak_walk"] = true
	for i in store.rows.size():
		store.switch_off(i, true)
	main.minutes = Main.clock(23, 40)
	night.clues.bag = true
	night.clues.tape = true
	night.clues.page = true
	_place(p, Vector3(5.2, 0, 26.4), Vector3(1, 0, 0.12))
	p.force_flashlight = true
	await _wait(1.5)
	await _shot("p01_round_door")
	night.rounds[0].door = true
	_place(p, Vector3(-6.5, 0, 26.4), Vector3(1, 0, 0.1))
	await _wait(1.0)
	await _shot("p02_round_panel")
	main.killer.activate(Vector3(-3.0, 0, 16.8))
	_place(p, Vector3(-3.0, 0, 11.0), Vector3(0, 0, 1))
	p.head.rotation.x = 0.02
	main.killer.lurk_at(Vector3(-3.0, 0, 16.4), 120.0)
	night._lurk_seen = false
	await _until(func(): return main.killer.is_lurking(), 60.0)
	print("lurking ", main.killer.is_lurking(), " at ", main.killer.global_position, " state ", main.killer.state)
	await _wait(1.5)
	await _shot("p03_lurk")
	await _wait(2.5)
	await _shot("p04_lurk_said")


func _until(f: Callable, limit: float) -> void:
	var end := Time.get_ticks_msec() + int(limit * 1000.0)
	while not f.call() and Time.get_ticks_msec() < end:
		await get_tree().process_frame


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


## Nights two to four (--night2/3/4 --autoshot=DIR --polishshot): the man
## waiting at the end of an aisle, the hiding place in the cellar with the
## task hint, his torch held low while he waits.
func _polish_late(p: Player, store: Store, night: NightOne) -> void:
	main._timeline.clear()
	night.kovpak.visible = false
	night._talked["kovpak_walk"] = true
	night.kovpak_state = "done"
	for i in store.rows.size():
		store.switch_off(i, true)
	main.minutes = Main.clock(3, 6)
	var k: Killer = main.killer
	# The torch's whirr would call him straight over: keep him at his post.
	p.noise.disconnect(main.on_noise)
	if night is NightTwo:
		var n2: NightTwo = night
		n2.koles_state = "gone"
		n2.koles_car = "gone"
		night.killer_phase = "in"
		k.activate(Vector3(-3.0, 0, 16.8))
		_place(p, Vector3(-3.0, 0, 11.4), Vector3(0, 0, 1))
		p.head.rotation.x = 0.03
		p.force_flashlight = true
		k.lurk_at(Vector3(-3.0, 0, 16.4), 120.0)
		night._lurk_seen = false
		await _until(func(): return k.is_lurking(), 60.0)
		await _wait(2.5)
		# The prologue's talk is still running underneath: put it out of view.
		main.hud.choices.visible = false
		n2.kolesnikov.visible = false
		n2.kovpak.visible = false
		await _wait(0.5)
		await _shot("p2_lurk")
		return
	if night is NightThree:
		var n3: NightThree = night
		n3.rooms.show_broken_lock()
		store.open_cellar(true)
		n3.rooms.open_fridge(true)
		n3.clues.body = true
		n3._rooms_prompts()
		night.killer_phase = "in"
		k.activate(Vector3(Store.CELLAR_X - 0.4, 0, 27.2))
		k.lurk_at(Vector3(Store.CELLAR_X, 0, 27.4), 120.0)
		_place(p, Vector3(-0.2, BackRooms.FLOOR, 33.9), Vector3(1, 0, 0.1))
		p.force_flashlight = true
		await _wait(1.5)
		_place(p, n3.HIDE_CELLAR[2] + Vector3(0, 0, -0.5), Vector3(0.6, 0, 1))
		p.head.rotation.x = -0.25
		await _wait(2.0)
		await _shot("p3_hide_cellar_hint")
		return
	var n4: NightFour = night
	store.power_cut()
	n4.rooms.cut_wire()
	n4.power_cut = true
	main._lit = 0.0
	night.killer_phase = "in"
	k.activate(Vector3(-3.0, 0, 17.6))
	k.set_torch(true)
	_place(p, Vector3(-3.0, 0, 11.6), Vector3(0, 0, 1))
	p.head.rotation.x = 0.02
	k.lurk_at(Vector3(-3.0, 0, 17.2), 120.0)
	night._lurk_seen = false
	await _until(func(): return k.is_lurking(), 60.0)
	await _wait(3.0)
	await _shot("p4_lurk_torch_low")


## --propshot: the round journal on the booth desk, and every freezer chest
## with its cloth off (what lies in it should match the line about it).
func _prop_shots(p: Player, store: Store) -> void:
	main._timeline.clear()
	await _wait(1.0)
	_place(p, Vector3(10.2, 0, 2.6), Vector3(0.6, 0, 0))
	p.head.rotation.x = -0.75
	await _wait(0.6)
	await _shot("journal")
	# Under the booth desk and under till 3, the man's boots going past.
	for id: String in ["hide_booth", "hide_till3"]:
		var h: Array = NightOne.HIDES[id]
		_place(p, h[2], (h[0] as Vector3) - (h[2] as Vector3))
		await _wait(0.3)
		main.hide_in({"id": id, "pos": h[0], "face": h[1], "out": h[2]})
		await _shot(id + "_0_going_in")
		await _wait(0.6)
		await _shot(id + "_1_crawling")
		await _wait(1.6)
		var k: Node3D = main.killer
		k.visible = true
		k.global_position = (h[0] as Vector3) + (h[1] as Vector3) * 1.3 + Vector3(0, 0, 0.6)
		await _wait(0.4)
		await _shot(id + "_2_hidden")
		print("hidden ", p.hidden, " clock ", main.minutes)
		main.leave_hiding()
		k.global_position = Vector3(9.0, 0, 33.0)
	for id: String in store.chests:
		store.lift_cloth(id)
		var c: Vector3 = store.chests[id].pos
		var side := 1.0 if c.x < 0.0 else -1.0
		_place(p, c + Vector3(side * 1.3, 0, 0), Vector3(-side, 0, 0))
		p.head.rotation.x = -0.8
		await _wait(0.5)
		await _shot("chest_" + id)
