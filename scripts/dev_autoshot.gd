extends Node

## Developer smoke test. Run
##   godot --path . -- --autoshot=/tmp/shots
## and it plays a scripted run (the post, the lockers, the lit hall, the
## dark with the flashlight, the killer, the death) saving a screenshot of
## each step, then quits.

var main: Node
var out_dir := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	main.start_now()
	var p: Player = main.player
	var store: Store = main.store
	await _wait(2.5)
	await _shot("01_post")
	_place(p, Vector3(-6.5, 0, 2.0), Vector3.LEFT)
	await _wait(1.0)
	await _shot("02_lockers")
	_place(p, Vector3(0.0, 0, 6.0), Vector3.BACK)
	await _wait(1.0)
	await _shot("03_checkout")
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
	var k: Killer = main.killer
	k.activate(p.global_position + Vector3(0, 0, 7.5))
	await _wait(0.8)
	await _shot("07_killer")
	await _wait(8.0)
	await _shot("08_death")
	get_tree().quit()


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
