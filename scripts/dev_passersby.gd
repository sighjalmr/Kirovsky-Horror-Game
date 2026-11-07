extends Node

## Developer check of the passers-by in a day episode. Run
##   godot --headless --path . -- --passtest [--day2|--day3|--day4]
## Lets the day run four minutes (fast) with Gordeev standing in the hall
## or on the square, then reports who came and went, the queue at till № 3,
## every remark heard and anyone stuck. With --shots=DIR (rendered, under
## xvfb-run) it saves pictures from a few places instead.

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
	main.start_now()
	main.day.start()
	var pb: Passersby = null
	for c in main.world.get_children():
		if c is Passersby:
			pb = c
	_check(pb != null, "passers-by in the scene")
	if out_dir != "":
		await _shots(pb)
		get_tree().quit()
		return
	Engine.time_scale = 8.0
	var street := main.chapter == "day4"
	# Stand where people pass: by the tills, or at the foot of the steps.
	main.player.global_position = Vector3(-0.5, 0, 9.6) if not street else Vector3(0.5, Outdoors.GROUND, -12.5)
	main.player.face(Vector3(0, 0, 1) if not street else Vector3(-1, 0, -1))
	var seen := {}
	var left := 0
	var heard: Array[String] = []
	var max_queue := 0
	var last_pos := {}
	var still := {}
	var stuck := 0
	var t := 0.0
	var last_sub := ""
	while t < 240.0:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		t += dt
		var now := {}
		for f in pb._folks:
			now[f.npc] = true
			if not seen.has(f.npc):
				seen[f.npc] = f.cast[0]
			var p: Vector3 = f.npc.global_position
			if f.npc.walking and last_pos.has(f.npc) and p.distance_to(last_pos[f.npc]) < 0.0005:
				still[f.npc] = still.get(f.npc, 0.0) + dt
				if still[f.npc] > 20.0:
					stuck += 1
					still[f.npc] = -1000.0
					print("STUCK ", f.cast[0], " at ", p, " doing ", f.act)
			else:
				still[f.npc] = 0.0
			last_pos[f.npc] = p
		for n in last_pos.keys():
			if not now.has(n):
				left += 1
				last_pos.erase(n)
		max_queue = maxi(max_queue, pb._queue.size())
		var sub: String = main.hud.subtitle.text
		if sub != last_sub and sub != "":
			if sub.begins_with("Покуп") or sub.begins_with("Прохож") or sub.begins_with("Кассир"):
				heard.append(sub)
		last_sub = sub
	print("people seen: %d, gone: %d, now: %d, longest queue: %d" % [seen.size(), left, pb._folks.size(), max_queue])
	print("faces: ", ", ".join(PackedStringArray(seen.values())))
	for h in heard:
		print("  heard: ", h)
	_check(seen.size() >= 4, "enough people about")
	_check(left >= 1, "people leave")
	_check(street or max_queue >= 1, "queue at till 3")
	_check(heard.size() >= 3, "remarks heard")
	_check(stuck == 0, "nobody stuck")
	get_tree().quit()


func _shots(pb: Passersby) -> void:
	await _wait(1.0)
	if "--pano" in OS.get_cmdline_user_args():
		# Round the square from three places: is there a district all round?
		var g := Outdoors.GROUND
		for at: Vector3 in [Vector3(0, g, -15.0), Vector3(-20.0, g, -19.0), Vector3(18.0, g, -18.0)]:
			for k in 8:
				var a := k * TAU / 8.0
				main.player.global_position = at
				main.player.face(Vector3(sin(a), 0.08, -cos(a)))
				await _wait(0.3)
				await RenderingServer.frame_post_draw
				var id := "pano_%d_%d" % [int(at.x), k]
				get_viewport().get_texture().get_image().save_png(out_dir.path_join(id + ".png"))
		# The road: cars going by.
		for k in 8:
			main.player.global_position = Vector3(-4.0, g, -21.0)
			main.player.face(Vector3(1.0 if k % 2 == 0 else -1.0, 0.0, -0.45))
			await _wait(2.5)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("road_%d.png" % k))
		return
	var views: Array
	if main.chapter == "day4":
		var g := Outdoors.GROUND
		views = [[Vector3(1.6, 0, -3.2), Vector3(-6, g + 1.2, -15)], [Vector3(-1.5, g, -12.0), Vector3(-1.5, 0.6, -2.0)],
			[Vector3(2.0, g, -17.0), Vector3(-6.0, g + 1.0, -20.6)], [Vector3(-12.5, g, -20.5), Vector3(-15.1, g + 1.2, -18.4)]]
	else:
		views = [[Vector3(-1.2, 0, 2.6), Vector3(2.5, 1.2, 9.0)], [Vector3(-3.0, 0, 11.4), Vector3(-3.0, 1.2, 20.0)],
			[Vector3(3.0, 0, 11.4), Vector3(3.0, 1.2, 20.0)], [Vector3(0.0, 0, 5.2), Vector3(-1.0, 1.0, -2.0)],
			[Vector3(7.6, 0, 11.6), Vector3(8.85, 0.3, 17.0)]]  # the open chests of aisle D
	for k in 3:
		for i in views.size():
			main.player.global_position = views[i][0]
			main.player.face(views[i][1] - views[i][0])
			await _wait(0.4)
			await RenderingServer.frame_post_draw
			var id := "%s_%d_%d" % [main.chapter, i, k]
			get_viewport().get_texture().get_image().save_png(out_dir.path_join(id + ".png"))
			print("shot ", id, " people ", pb._folks.size())
		await _wait(12.0)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout
