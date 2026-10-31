extends "res://scripts/dev_nighttest.gd"

## Developer check of night two. Run
##   godot --headless --path . -- --night2 --nighttest
## Same as the night-one check: a fast clock, a blind killer, Gordeev put
## next to each thing in turn. Answers the участковый, takes the dispatcher's
## call, finds the floor finds after 01:40, puts the duty light back on at the
## panel, signs all three rounds and runs to the end card.


func _ready() -> void:
	Killer.blind = true
	main.time_scale = 40.0
	main.start_now()
	await _until_true(func(): return main.hud.choices.visible, 300.0)
	print(main._fmt(main.minutes), " choice shown: ", main.hud._choice_title.text)
	main.hud.chosen.emit(0)
	await _until_true(func(): return main.night.koles_state == "gone", 300.0)
	_check(main.night.clues.seizure, "bag taken by Колесников")
	await _until(23, 31)
	for id in ["locker31", "register2", "cellar", "chest_A3", "storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[0].signed, "round 1 signed")
	_check(not Main.checkpoint.is_empty(), "checkpoint saved")
	await _until_true(func(): return main.night._phone_t > 0.0, 400.0)
	_use("phone")
	await _wait(4.0)
	_check(main.night.clues.pahomov, "dispatcher's call")
	await _until_true(func(): return main.store._token.visible, 400.0)
	_use("token")
	_use("butt")
	await _until(2, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[1].signed, "round 2 signed")
	var saved: Dictionary = main.night.save_state()
	main.night.restore_state(saved)
	await _until_true(func(): return not main.store.duty_on, 400.0)
	print("duty light out at ", main._fmt(main.minutes), " lit at post: ", main.store.is_lit(Vector3(10, 0, 2.5)))
	_use("panel")
	_check(main.store.duty_on, "duty light back on")
	await _until(4, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[2].signed, "round 3 signed")
	await _until_true(func(): return main.phase == Main.Phase.END, 900.0)
	print("END: ", main.hud.title_sub.text.replace("\n", " | "))
	print("clues ", main.night.clue_count(), " rounds ", main.night.rounds_signed())
	get_tree().quit()


func _process(_delta: float) -> void:
	var scene: bool = main.night.koles_state == "talk" or main.killer.state == Killer.State.LEAVE
	main.time_scale = 1.0 if scene else 40.0
	var slot := int(main.minutes / 20.0)
	if slot != _last_report:
		_last_report = slot
		print("  [%s] killer %s phase=%s duty=%s" % [main._fmt(main.minutes), Killer.State.keys()[main.killer.state],
			main.night.killer_phase, main.store.duty_on])
