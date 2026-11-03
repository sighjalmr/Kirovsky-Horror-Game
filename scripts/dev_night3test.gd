extends "res://scripts/dev_nighttest.gd"

## Developer check of night three. Run
##   godot --headless --path . -- --night3 --nighttest
## A fast clock and a blind killer. Asks Ковпак about the padlock, signs the
## rounds, answers the call from the office, follows the wire, takes the
## handset and the letter, breaks into the cellar with the crowbar while he
## is out, finds the boot prints and Nina, calls 02 and runs to the end card.


func _ready() -> void:
	Killer.blind = true
	main.time_scale = 40.0
	main.start_now()
	await _until_true(func(): return main.night.kovpak.visible, 60.0)
	await _wait(2.0)
	_use("talk_kovpak")
	_check(main.night._talked.has("kovpak"), "asked Ковпак about the lock")
	await _until_true(func(): return main.night.kovpak_state == "done", 300.0)
	await _until(23, 31)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[0].signed, "round 1 signed")
	_use("cellar")
	_check(main.store.interactables.any(func(it): return it.id == "crowbar" and it.active), "crowbar offered after the padlock")
	_use("office_door")
	var k: Killer = main.killer
	await _until_true(func(): return main.night.line == "ringing", 600.0)
	print(main._fmt(main.minutes), " the office call rings; killer at ", main.killer.global_position)
	_use("phone")
	await _until_true(func(): return main.night.line == "open", 30.0)
	print("after the call: killer ", Killer.State.keys()[k.state], " at ", k.global_position)
	_check(main.store.office_open, "office door left ajar")
	await _wait(1.0)
	main.player.global_position = Vector3(2.0, 0, 29.4)
	await _wait(0.5)
	_check(main.night.line == "found", "Gordeev in the office")
	_use("handset")
	_use("letter")
	_use("hang_up")
	_check(main.night.clues.handset and main.night.clues.letter, "handset and letter")
	await _until(1, 45)
	slow = true
	_use("crowbar")
	_use("cellar")
	await _wait(2.5)
	_check(main.store.cellar_open, "cellar padlock broken")
	main.player.global_position = Vector3(Store.CELLAR_X, 0, 29.5)
	await _wait(0.4)
	print("on the stairs: y ", main.player.global_position.y)
	_use("boots")
	_use("fridge")
	await _wait(2.5)
	_check(main.night.clues.body, "Nina found")
	_use("body")
	_check(main.night.clues.cord, "cord mark and lock of hair")
	await _wait(4.0)
	_use("call02")
	await _wait(10.0)
	_check(main.night.called, "called 02")
	main.player.global_position = Vector3(8.0, 0, 3.0)
	slow = false
	await _until(2, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[1].signed, "round 2 signed")
	var saved: Dictionary = main.night.save_state()
	main.night.restore_state(saved)
	_check(main.store.cellar_open and main.store.office_open and main.night.rooms.fridge_open, "state restored")
	await _until(4, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[2].signed, "round 3 signed")
	await _until_true(func(): return main.phase == Main.Phase.END, 900.0)
	print("END: ", main.hud.title_sub.text.replace("\n", " | "))
	print("clues ", main.night.clue_count(), " rounds ", main.night.rounds_signed())
	get_tree().quit()


var slow := false


func _use(id: String, at := Vector3.INF) -> void:
	for it in main.store.interactables:
		if it.id == id:
			var p: Vector3 = it.pos if at == Vector3.INF else at
			var q := Vector3(p.x, 0, p.z) - Vector3(0, 0, 0.3)
			q.y = BackRooms.floor_y(q) if q.z > 28.05 else 0.0
			main.player.global_position = q
			print("%s use %s (active %s)" % [main._fmt(main.minutes), id, it.active])
			main.night.interact(id)
			print("   says: ", main.hud._queue.map(func(q2): return q2[0]))
			return
	print("!! no interactable ", id)


func _process(_delta: float) -> void:
	var scene: bool = main.night.kovpak_state == "prologue" or main.killer.state == Killer.State.LEAVE or slow \
		or (main.minutes > Main.clock(0, 36) and main.night.line == "")
	main.time_scale = 1.0 if scene else 40.0
	var slot := int(main.minutes / 20.0)
	if slot != _last_report:
		_last_report = slot
		print("  [%s] killer %s phase=%s at %s" % [main._fmt(main.minutes), Killer.State.keys()[main.killer.state],
			main.night.killer_phase, main.killer.global_position.snapped(Vector3.ONE * 0.1)])
