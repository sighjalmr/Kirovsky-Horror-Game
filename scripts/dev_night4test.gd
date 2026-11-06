extends "res://scripts/dev_night3test.gd"

## Developer check of night four. Run
##   godot --headless --path . -- --night4 --nighttest [--late]
## A fast clock and a blind killer. Asks Ковпак about Колесников, signs the
## first round, waits for the power cut, finds the dead phone, the panel and
## the cut wire, tears the seal while he is out, finds the prints, opens the
## vent, takes the tin, hides it in locker 12, saves and restores, runs to the
## end card. With --late Gordeev never goes down: at 03:20 he takes the tin.


func _ready() -> void:
	Killer.blind = true
	main.time_scale = 40.0
	main.start_now()
	var n: NightFour = main.night
	await _until_true(func(): return n.kovpak.visible, 60.0)
	await _wait(2.0)
	_use("talk_kovpak")
	_check(n._talked.has("kovpak"), "asked Ковпак")
	await _until_true(func(): return n.kovpak_state == "done", 300.0)
	await _until(23, 31)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(n.rounds[0].signed, "round 1 signed")
	await _until_true(func(): return n.power_cut, 900.0)
	print(main._fmt(main.minutes), " power cut; killer at ", main.killer.global_position)
	_check(not main.store.power and not main.store.duty_on, "power and duty light out")
	await _wait(4.0)
	_check(main.killer.torch_on(), "his torch is on")
	main.player.global_position = Vector3(10.6, 0, 2.2)
	_use("phone")
	_check(n.wire_found, "the line is dead")
	_use("panel")
	_check(n.clues.panel, "panel clue")
	_use("wire_cut")
	_check(n.clues.wire, "wire clue")
	if "--late" in OS.get_cmdline_user_args():
		main.player.global_position = Vector3(10.3, 0, 3.4)
		await _until(3, 15)
		slow = true
		await _until_true(func(): return n.box_lost, 200.0)
		print(main._fmt(main.minutes), " killer at ", main.killer.global_position)
		slow = false
		_check(n.box_lost, "he took the tin at 03:20")
		await _until_true(func(): return main.phase == Main.Phase.END, 900.0)
		print("END: ", main.hud.title_sub.text.replace("\n", " | "))
		get_tree().quit()
		return
	await _until(1, 50)
	slow = true
	_use("cellar")
	_check(n.seal_seen, "seal read")
	_use("cellar")
	await _wait(2.5)
	_check(main.store.cellar_open, "cellar open")
	main.player.global_position = Vector3(Store.CELLAR_X, 0, 29.5)
	await _wait(0.4)
	_use("prints")
	_check(n.clues.prints, "prints clue")
	_use("vent")
	await _wait(4.5)
	_check(n.rooms.vent_open, "vent open")
	_use("tinbox")
	_check(n.clues.box, "box clue")
	_use("earring")
	_check(n.clues.earring, "earring clue")
	_use("take_tin")
	_check(n.has_box, "tin taken")
	main.player.global_position = Vector3(-5.0, 0, 1.5)
	_use("locker12")
	_check(n.box_hidden, "tin hidden in locker 12")
	slow = false
	var saved: Dictionary = n.save_state()
	n.restore_state(saved)
	_check(main.store.cellar_open and n.rooms.vent_open and n.has_box, "state restored")
	await _until(2, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(n.rounds[1].signed, "round 2 signed")
	await _until(3, 40)
	print("03:40 he_knows=", n.he_knows)
	await _until(4, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(n.rounds[2].signed, "round 3 signed")
	await _until_true(func(): return main.phase == Main.Phase.END, 900.0)
	print("END: ", main.hud.title_sub.text.replace("\n", " | "))
	print("clues ", n.clue_count(), " rounds ", n.rounds_signed())
	get_tree().quit()


func _process(_delta: float) -> void:
	var scene: bool = main.night.kovpak_state == "prologue" or main.killer.state == Killer.State.LEAVE or slow
	main.time_scale = 1.0 if scene else 40.0
	var slot := int(main.minutes / 20.0)
	if slot != _last_report:
		_last_report = slot
		print("  [%s] killer %s phase=%s at %s" % [main._fmt(main.minutes), Killer.State.keys()[main.killer.state],
			main.night.killer_phase, main.killer.global_position.snapped(Vector3.ONE * 0.1)])
