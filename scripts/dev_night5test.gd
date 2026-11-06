extends "res://scripts/dev_night3test.gd"

## Developer check of night five. Run
##   godot --headless --path . -- --night5 --nighttest [--ending=word|wrong|defence|lost]
## A fast clock and a blind killer. Talks to Эдик, takes the tin from locker
## 12, finds the spare-key box, the alarm plate and the cut wire, opens his
## map case while he is out, saves and restores, writes the journal at six
## and keeps the box: the prosecutor ending. --ending picks another way:
## word (Эдик not asked), wrong (Ринат in the journal), defence (he is let
## catch Gordeev, who tears free and strikes), lost (the tin left in the
## locker: he takes it at 00:30, and it is got back from his map case).

var ending := "prosecutor"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ending="):
			ending = a.get_slice("=", 1)
	Killer.blind = ending != "defence"
	main.time_scale = 40.0
	main.start_now()
	var n: NightFive = main.night
	await _until_true(func(): return n.edik.visible, 60.0)
	await _wait(2.0)
	if ending != "word":
		_use("talk_edik")
		_check(n.clues.edik, "Эдик told")
	await _until_true(func(): return n.kovpak_state == "done", 400.0)
	_check(not main.store.front_open, "front door locked by him")
	if ending != "lost":
		_use("locker12")
		_check(n.box_at == "me", "tin taken from locker 12")
	_use("spare_key")
	_check(n.clues.spare, "spare-key clue")
	_use("alarm")
	_check(n.clues.button, "alarm plate clue")
	await _until(23, 31)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(n.rounds[0].signed, "round 1 signed")
	_check(n.wire_cut, "wire cut by 23:31")
	_check(main.killer.torch_on(), "his torch is on")
	main.player.global_position = Vector3(10.6, 0, 2.2)
	_use("phone")
	_check(n.wire_found, "the line is dead")
	_use("wire_cut")
	_check(n.clues.wire, "wire clue")
	if ending == "defence":
		Killer.blind = false
		main.player.global_position = Vector3(1.0, 0, 15.0)
		main.killer.global_position = Vector3(1.0, 0, 17.0)
		main.killer.hear(main.player.global_position, 30.0)
		slow = true
		await _until_true(func(): return main._struggling, 300.0)
		_check(true, "caught")
		for i in 10:
			main._mash += 1
		await _until_true(func(): return main.hud.choices.visible, 30.0)
		main.hud.chosen.emit(1)
		await _until_true(func(): return main.phase == Main.Phase.END and main.hud.title_sub.text != "", 300.0)
		print("END: ", main.hud.title.text, " | ", main.hud.title_sub.text.replace("\n", " | "))
		get_tree().quit()
		return
	main.player.global_position = Vector3(10.3, 0, 3.4)
	await _until(0, 29)
	slow = true
	await _until_true(func(): return n.lockers_done, 300.0)
	slow = false
	print(main._fmt(main.minutes), " lockers done; box at ", n.box_at, " he_knows ", n.he_knows)
	await _until(2, 0)
	_check(n.killer_phase == "out" and n.planshet_out, "he is out, map case on the desk")
	_use("planshet")
	_check(n.clues.planshet, "map-case clue")
	_use("planshet")
	_check(n.page_taken and n.box_at == "me", "page and tin on Gordeev")
	var saved: Dictionary = n.save_state()
	n.restore_state(saved)
	_check(n.box_at == "me" and n.wire_cut, "state restored")
	await _until(2, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(n.rounds[1].signed, "round 2 signed")
	await _until(3, 40)
	_check(n.he_knows, "he knows after the desk")
	await _until(4, 25)
	for id in ["storage_door", "panel", "journal"]:
		_use(id)
		await _wait(0.3)
	_check(n.rounds[2].signed, "round 3 signed")
	await _until_true(func(): return main.hud.choices.visible, 1200.0)
	slow = true
	print("journal choice up at ", main._fmt(main.minutes))
	main.hud.chosen.emit(1 if ending == "wrong" else 3)
	await _until_true(func(): return main.hud.choices.visible, 200.0)
	print("box choice up")
	main.hud.chosen.emit(1)
	await _until_true(func(): return main.phase == Main.Phase.END and main.hud.title_sub.text != "", 400.0)
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
