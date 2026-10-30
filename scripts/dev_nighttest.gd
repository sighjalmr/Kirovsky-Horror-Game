extends Node

## Developer check of the whole night. Run
##   godot --headless --path . -- --nighttest
## The clock runs 40 times faster, the killer is blind, and Gordeev is
## teleported to each thing at the right time: talks in the prologue, the
## clues, all three rounds, the invoice after Kovpak's visit, a save and a
## restore of the saved state. Prints what happens and quits at the end card.

var main: Main


func with(m: Main) -> Node:
	main = m
	return self


func _ready() -> void:
	Killer.blind = true
	main.time_scale = 40.0
	main.start_now()
	await _wait(1.0)
	_use("talk_kovpak", Vector3(7.2, 0, 2.7))
	_use("talk_tamara", Vector3(0.4, 0, 9.4))
	await _until(23, 31)
	for id in ["locker31", "register2", "journal", "chest_A3", "chest_D3", "storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[0].signed, "round 1 signed")
	_check(not Main.checkpoint.is_empty(), "checkpoint saved")
	if "--restore" in OS.get_cmdline_user_args():
		# Die and press R: the scene reloads at the signature.
		main.killer.activate(main.player.global_position + Vector3(0, 0, 1.5))
		Killer.blind = false
		await _until_true(func(): return main.phase == Main.Phase.DEAD, 30.0)
		_check(main.phase == Main.Phase.DEAD, "killed")
		await _wait(3.0)
		reparent(get_tree().root)  # outlive the reload
		set_process(false)
		var ev := InputEventAction.new()
		ev.action = "restart"
		ev.pressed = true
		Input.parse_input_event(ev)
		await _wait(3.0)
		var m: Main = get_tree().current_scene
		print("after restart: ", m._fmt(m.minutes), " phase ", m.phase, " clues ", m.night.clue_count(),
			" killer ", Killer.State.keys()[m.killer.state], " round1 ", m.night.rounds[0].signed,
			" rows lit ", m.store.lit_fraction())
		get_tree().quit()
		return
	_use("chair")
	_check(main.player.sitting, "sitting on the chair")
	await _until(1, 12)
	_check(not main.player.sitting, "stood up for an event")
	await _until_true(func(): return main.night.kovpak_state == "done", 400.0)
	print("kovpak visit done at ", main._fmt(main.minutes))
	_use("invoice")
	await _until(2, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[1].signed, "round 2 signed")
	# Restore the saved state into this scene's night as a smoke test.
	var saved := main.night.save_state()
	main.night.restore_state(saved)
	await _until_true(func(): return main.killer.is_active(), 200.0)
	print("killer back at ", main._fmt(main.minutes))
	await _until(4, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(main.night.rounds[2].signed, "round 3 signed")
	await _until_true(func(): return main.night.killer_phase == "gone", 400.0)
	print("killer gone at ", main._fmt(main.minutes))
	await _until_true(func(): return main.phase == Main.Phase.END, 600.0)
	print("END: ", main.hud.title_sub.text.replace("\n", " | "))
	print("clues ", main.night.clue_count(), " rounds ", main.night.rounds_signed())
	get_tree().quit()


func _use(id: String, at := Vector3.INF) -> void:
	for it in main.store.interactables:
		if it.id == id:
			var p: Vector3 = it.pos if at == Vector3.INF else at
			main.player.global_position = Vector3(p.x, 0, p.z) - Vector3(0, 0, 0.3)
			print("%s use %s (active %s)" % [main._fmt(main.minutes), id, it.active])
			main.night.interact(id)
			print("   says: ", main.hud._queue.map(func(q): return q[0]))
			return
	print("!! no interactable ", id)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _until(h: int, m: int) -> void:
	var t := Main.clock(h, m)
	while main.minutes < t:
		await get_tree().process_frame


func _until_true(f: Callable, limit: float) -> void:
	var t := 0.0
	while not f.call() and t < limit:
		await get_tree().process_frame
		t += get_process_delta_time()


var _last_report := 0


func _process(_delta: float) -> void:
	# Real-time scenes (people walking) run at the normal clock.
	var scene: bool = main.night.kovpak_state in ["prologue", "visit"] or main.killer.state == Killer.State.LEAVE
	main.time_scale = 1.0 if scene else 40.0
	var slot := int(main.minutes / 20.0)
	if slot != _last_report:
		_last_report = slot
		print("  [%s] killer %s leaving=%s pos=%s phase=%s kovpak=%s" % [main._fmt(main.minutes),
			Killer.State.keys()[main.killer.state], main.killer.leaving, main.killer.global_position.snapped(Vector3.ONE * 0.1),
			main.night.killer_phase, main.night.kovpak_state])
