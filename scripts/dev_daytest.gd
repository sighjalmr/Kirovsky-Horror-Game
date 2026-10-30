extends Node

## Developer check of day one. Run
##   godot --headless --path . -- --daytest
## Talks to Эдик, sits through Tamara's three questions (always taking the
## first one offered), walks out of the door and prints the end card. With
## --shots=DIR (not headless) it also saves screenshots on the way.

var main: Main
var out_dir := ""


func with(m: Main) -> Node:
	main = m
	return self


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			out_dir = a.get_slice("=", 1)
			DirAccess.make_dir_recursive_absolute(out_dir)
	if out_dir == "":
		Engine.time_scale = 8.0
	main.start_now()
	main.day.start()
	await _wait(1.0)
	await _shot("20_day_entrance")
	_use("door_front")
	_check(not main.day.done, "door refuses before the talk")
	_place(Vector3(1.2, 0, 2.6), main.day.edik.global_position)
	await _wait(0.6)
	await _shot("21_edik")
	_use("talk_edik")
	_place(Vector3(-0.2, 0, 6.3), main.day.tamara.global_position + Vector3(0, 0, 0.2))
	await _wait(0.6)
	await _shot("22_till")
	_use("talk_tamara_day")
	var picks := 0
	while not main.day.done:
		if main.hud.choices.visible:
			print("   choices: ", main.hud._choice_box.get_children().map(func(b): return b.text))
			if picks == 0:
				await _shot("23_choices")
			main.hud.chosen.emit(0)
			picks += 1
		await _wait(0.2)
	print("asked: ", main.day.asked)
	_check(main.day.asked.size() == DayOne.ASK_LIMIT, "three questions asked")
	_check(not main.player.busy, "player free after the talk")
	_use("door_front")
	await _until_true(func(): return main.phase == Main.Phase.END, 20.0)
	_check(main.phase == Main.Phase.END, "day ended")
	print("END: ", main.hud.title_sub.text.replace("\n", " | "))
	await _wait(2.0)
	await _shot("24_day_end")
	get_tree().quit()


func _use(id: String) -> void:
	for it in main.store.interactables:
		if it.id == id:
			print("use %s (active %s)" % [id, it.active])
			main.day.interact(id)
			print("   says: ", main.hud._queue.map(func(q): return q[0]))
			return
	print("!! no interactable ", id)


func _place(pos: Vector3, look_at_p: Vector3) -> void:
	main.player.global_position = pos
	main.player.face(look_at_p - pos)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _until_true(f: Callable, limit: float) -> void:
	var t := 0.0
	while not f.call() and t < limit:
		await get_tree().process_frame
		t += get_process_delta_time()


func _shot(id: String) -> void:
	if out_dir == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(id + ".png"))
	print("shot ", id)
