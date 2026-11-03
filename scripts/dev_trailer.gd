extends Node

## Developer: footage for the vertical gameplay trailer (Instagram Reels).
## One shot per run, recorded with the movie writer:
##   godot --path . --resolution 1080x1920 --fixed-fps 30 --write-movie OUT.avi \
##     -- --vertical --trailer=torch            (add --night2 for night-two shots)
## The clock stands still and the story timeline is emptied, so only what the
## shot stages happens. It prints TRAILER_IN / TRAILER_OUT with the frame
## numbers to cut the clip from the movie, then quits.
## Shots: lit, lightsout, torch, kovpak, phone (night 1); koles, cellar,
## token (night 2); killer (night 1, the chase and the blow).

var main: Node
var shot := ""

var p: Player
var store: Store
var night: Node
var _t0 := 0


func _ready() -> void:
	p = main.player
	store = main.store
	night = main.night
	main._timeline.clear()
	main.time_scale = 0.0
	main.hud.visible = false
	Killer.blind = shot != "killer"
	p.camera.fov = 76.0
	p.hand_shift = Vector3(-0.085, -0.04, 0.0)
	for n: String in ["kovpak", "tamara", "vasya", "kolesnikov"]:
		var npc = night.get(n)
		if npc is Node3D:
			npc.visible = false
	main.start_now()
	await _wait(1.0)
	await call("_" + shot)
	print("TRAILER_OUT ", Engine.get_frames_drawn())
	get_tree().quit()


func _in() -> void:
	_t0 = Engine.get_frames_drawn()
	print("TRAILER_IN ", _t0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stills="):  # quick framing check without the movie writer
			_stills(a.get_slice("=", 1))


func _stills(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var i := 0
	while true:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("%s_%d.jpg" % [shot, i]))
		i += 1
		await _wait(1.0)


func _dark() -> void:
	for i in store.rows.size():
		store.switch_off(i, true)


## Walks him for `t` seconds, turning the head from yaw0/pitch0 to yaw1/pitch1 (degrees).
func _walk(t: float, drive: Vector2, yaw: Vector2 = Vector2.ZERO, pitch: Vector2 = Vector2.ZERO) -> void:
	p.drive = drive
	var base := p.rotation.y
	var e := 0.0
	while e < t:
		var k := smoothstep(0.0, 1.0, e / t)
		p.rotation.y = base + deg_to_rad(lerpf(yaw.x, yaw.y, k))
		p.head.rotation.x = deg_to_rad(lerpf(pitch.x, pitch.y, k))
		await get_tree().process_frame
		e += get_process_delta_time()
	p.drive = Vector2.ZERO


func _place(pos: Vector3, dir: Vector3) -> void:
	p.global_position = pos
	p.face(dir)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


# --- night one -------------------------------------------------------------------

## The lit hall, an ordinary evening: walking down the aisle.
func _lit() -> void:
	_place(Vector3(-3.0, 0, 9.8), Vector3(0, 0, 1))
	await _wait(0.6)
	_in()
	await _walk(4.0, Vector2(0, -0.6), Vector2(4, -6), Vector2(4, 8))


## The rows going out one after another, looking down the hall.
func _lightsout() -> void:
	_place(Vector3(-3.0, 0, 9.8), Vector3(0.1, 0, 1))
	p.head.rotation.x = deg_to_rad(14)
	await _wait(0.6)
	_in()
	await _wait(0.5)
	for i in range(store.rows.size() - 1, -1, -1):
		store.switch_off(i)
		await _wait(0.45)
	await _wait(1.2)


## Dark: the torch comes up with its whirr, a slow walk into the aisle.
func _torch() -> void:
	_dark()
	_place(Vector3(-3.0, 0, 10.6), Vector3(0, 0, 1))
	await _wait(1.0)
	_in()
	await _wait(0.5)
	p.force_flashlight = true
	await _walk(4.5, Vector2(0, -0.45), Vector2(10, -14), Vector2(-4, -8))


## The director carrying a carton out of the storage room at night.
func _kovpak() -> void:
	_dark()
	var k: Npc = night.kovpak
	k.visible = true
	k.carry(true)
	k.global_position = Vector3(9.0, 0, 26.0)
	p.force_flashlight = true
	_place(Vector3(7.4, 0, 22.4), Vector3(0.45, 0, 1))
	p.head.rotation.x = deg_to_rad(-3)
	await _wait(1.0)
	_in()
	k.look_at_point(p.global_position)
	await _walk(3.6, Vector2(0, -0.3), Vector2(0, -3), Vector2(-3, -1))


## The phone at the post ringing in the empty, dark shop.
func _phone() -> void:
	_dark()
	store.set_duty(true, true)
	_place(Vector3(5.6, 0, 6.2), Vector3(0.75, 0, -0.65))
	await _wait(1.0)
	_in()
	night._ring_phone()
	await _walk(3.5, Vector2(0, -0.35), Vector2(-4, 3), Vector2(-6, -8))
	night.stop_sounds()


## The man in the hat at the end of the aisle; he comes, the cleaver, the floor.
func _killer() -> void:
	_dark()
	main.chasing = false
	p.force_flashlight = true
	_place(Vector3(-10.3, 0, 11.0), Vector3.BACK)
	await _wait(1.0)
	_in()
	var k: Killer = main.killer
	k.activate(p.global_position + Vector3(0, 0, 8.0))
	await _wait(1.2)
	p.drive = Vector2(0, 0.7)
	var e := 0.0
	while k.state != Killer.State.ATTACK and e < 8.0:
		await get_tree().process_frame
		e += get_process_delta_time()
	p.drive = Vector2.ZERO
	await _wait(3.2)


# --- night two -------------------------------------------------------------------

## Участковый Колесников at the post: he walks up and says hello.
func _koles() -> void:
	var k: Npc = night.kolesnikov
	k.visible = true
	k.global_position = Vector3(2.6, 0, 2.8)
	_place(Vector3(8.0, 0, 3.7), Vector3(-1, 0, 0.1))
	p.head.rotation.x = deg_to_rad(3)
	await _wait(1.0)
	_in()
	k.walk(PackedVector3Array([Vector3(4.4, 0, 4.2), Vector3(6.3, 0, 3.9)]))
	await _walk(2.2, Vector2.ZERO, Vector2(0, 4), Vector2(3, 2))
	k.look_at_point(p.global_position)
	main.hud.say(NightTwo.N2_KL_HELLO, -1.0, true)
	await _wait(3.6)


## The new padlock on the cellar door in the back passage.
func _cellar() -> void:
	_dark()
	p.force_flashlight = true
	_place(Vector3(-2.4, 0, 23.6), Vector3(0.05, 0, 1))
	await _wait(1.0)
	_in()
	await _walk(4.0, Vector2(0, -0.4), Vector2(-3, 2), Vector2(-2, -10))


## The brass token of locker 31 on the floor.
func _token() -> void:
	_dark()
	store.show_floor_finds()
	p.force_flashlight = true
	_place(Vector3(8.15, 0, 25.6), Vector3(0.1, 0, 1))
	await _wait(1.0)
	_in()
	await _walk(3.2, Vector2(0, -0.25), Vector2(0, 2), Vector2(-25, -62))
	await _wait(0.4)
