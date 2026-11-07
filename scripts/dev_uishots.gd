extends Node

## Developer screenshots of the menus and paper screens. Run (not headless)
##   godot --path . -- --uishots=DIR
## Saves the title menu, settings, chapters, pause, notebook, floor plan,
## a morning conclusion and a newspaper epilogue into DIR, then quits.

var main: Main
var out_dir := ""


func with(m: Main, dir: String) -> Node:
	main = m
	out_dir = dir
	DirAccess.make_dir_recursive_absolute(out_dir)
	process_mode = Node.PROCESS_MODE_ALWAYS
	return self


func _ready() -> void:
	await _wait(2.5)
	main.menu.show_title_menu()
	await _wait(0.5)
	await _shot("01_title_menu")
	main.menu._settings()
	await _wait(0.3)
	await _shot("02_settings")
	main.menu._chapters()
	await _wait(0.3)
	await _shot("03_chapters")
	main.menu.close()
	main.hud.fade.color.a = 0.0
	main.start_now()
	await _wait(3.0)
	main.menu.open_pause()
	await _wait(0.3)
	await _shot("04_pause")
	main.menu.close()
	get_tree().paused = false
	Main.deductions = {"night1": 1}
	main._fill_notebook_right()
	main.hud.notebook.visible = true
	await _wait(0.3)
	await _shot("05_notebook")
	main.hud.notebook.visible = false
	main.tactics.open_plan()
	await _wait(0.4)
	await _shot("06_plan")
	main.tactics.close_plan()
	get_tree().paused = false
	var q := Deductions.question("night1")
	var labels: Array[String] = []
	for a: String in q[1]:
		labels.append(a)
	main.hud.choose("Утро. Записываю в блокнот вывод. " + String(q[0]), labels)
	await _wait(0.4)
	await _shot("07_deduction")
	main.hud.chosen.emit(1)
	await _wait(0.3)
	main.hud.show_epilogue("ПРОКУРОР", Deductions.EPILOGUES["prosecutor"],
		"Выводов верных: 4 из 4. Концовок найдено: 1 из 5.\n\nR: сыграть пятую ночь ещё раз      N: начать с первой ночи")
	await _wait(1.5)
	await _shot("08_epilogue")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func _shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(id + ".png"))
	print("shot ", id)
