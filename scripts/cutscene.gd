class_name Cutscene
extends CanvasLayer

## Story cutscenes, played before a chapter starts. Each one is its own small
## world in its own Full HD viewport, under the same film grade as the game,
## with black bars top and bottom; Gordeev's voice and the subtitles go
## through the game's HUD. E, Space, Enter or Esc skips.
##
##   flashback  7 October, 22:40: Nina at till 2 punches the receipt for the
##              beef, somebody waits in the dark of the storage doorway.
##   night1     Friday 14 October, 22:20, rain: Gordeev drives his Zhiguli up
##              to «Кировский», the facade, the director's «Волга», the steps.
##   day1       Saturday 15 October, 12:30: the square by day, the queue.
##   night2     Monday 17 October, 22:20: участковый Колесников smoking on
##              the porch, waiting.
##
## Dev: `godot --path . -- --cut=night1 --cutshots=/tmp/cut` saves a frame
## from the middle of every shot and quits.

signal finished

## Which cutscenes play before each chapter, in order.
const BEFORE := {"night1": ["flashback", "night1"], "day1": ["day1"], "night2": ["night2"]}

const NINA_1 := "Нина: — Вот. Пробила, как вы сказали. Сорок килограммов говядины, без реализации."
const NINA_2 := "Нина: — Теперь вы им всё покажете? Правда?"
const N1_CITY := "Свердловск. ЖБИ. Девятиэтажки, лужи до колена, и посреди всего этого универсам «Кировский»."
const N1_JOB := "Тридцать лет я ловил убийц. Теперь сторожу колбасу, которой нет на прилавках."
const N1_SUROVA := "В восемьдесят шестом меня убрали из следственного. Дело Галины Суровой я так и не закрыл. Мне велели не копать."
const N1_NINA := "Неделю назад отсюда не вернулась домой Нина Лукина, продавщица из кулинарии. Участковый закрыл заявление за один день: уехала к матери, в Тагил."
const N1_VOLGA := "«Волга» директора ещё у крыльца. Ночь через две, девяносто рублей к пенсии."
const N1_GO := "Ну что, Гордеев. Пошёл на смену."
const D1_DAY := "Днём «Кировский» не узнать: очередь до крыльца, авоськи, давка у молочного. Будто ночью тут ничего и не бывает."
const D1_TAMARA := "Тамара Ивановна сегодня на второй кассе. При Ковпаке она молчала. Посмотрим, что скажет при людях."
const N2_RAIN := "Понедельник. Дождь не перестаёт с пятницы."
const N2_KOLES := "На крыльце курит милиционер. Участковый Колесников, хозяин ЖБИ. Ждёт не Ковпака. Ждёт меня."
const N2_BAG := "Сумка Нины всё ещё лежит в тридцать первой ячейке. Если он пришёл за ней, мне её не удержать."

## Till 2 in the store, where Nina punched the receipt.
const TILL := Vector3(-2.35, 0.89, 7.95)
const NINA_AT_TILL := Vector3(-1.75, 0, 7.95)

var main: Main
var kind: String
var view: SubViewport
var cam: Camera3D
var root: Node3D
var ext: Exterior
var store: Store
var post: ShaderMaterial
var shot_dir := ""

var _caption: Label
var _bars: Array[ColorRect] = []
var _black: ColorRect
var _skip := false
var _done := false
var _shot := {}
var _shot_t := 0.0
var _tweens: Array[Tween] = []
var _players: Array[Node] = []
var _shot_n := 0
var _wipe_t := 0.0
var _wiping := false
var _engine: Node


func _init(m: Main, kind_: String) -> void:
	main = m
	kind = kind_
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cutshots="):
			shot_dir = a.get_slice("=", 1)


func _ready() -> void:
	view = SubViewport.new()
	view.size = Vector2i(Main.RENDER_W, Main.RENDER_H)
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.audio_listener_enable_3d = true
	view.positional_shadow_atlas_size = 4096
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var screen := TextureRect.new()
	screen.texture = view.get_texture()
	screen.size = Vector2(1920, 1080)
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	post = main.post.duplicate()
	screen.material = post
	add_child(screen)
	for y: float in [0.0, 1080.0 - 118.0]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, y)
		bar.size = Vector2(1920, 118)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		_bars.append(bar)
	_caption = Label.new()
	_caption.position = Vector2(140, 150)
	_caption.size = Vector2(1100, 140)
	_caption.add_theme_font_size_override("font_size", 34)
	_caption.add_theme_color_override("font_color", Hud.PAPER)
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_caption.add_theme_constant_override("shadow_offset_x", 2)
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.modulate.a = 0.0
	add_child(_caption)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.size = Vector2(1920, 1080)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)

	root = Node3D.new()
	view.add_child(root)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.far = 400.0
	root.add_child(cam)
	cam.current = true
	_play.call_deferred()


# --- running a scene -------------------------------------------------------------

func _play() -> void:
	match kind:
		"flashback":
			await _flashback()
		"night1":
			await _night_one()
		"day1":
			await _day_one()
		"night2":
			await _night_two()
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	for t in _tweens:
		if t.is_valid():
			t.kill()
	for p in _players:
		if is_instance_valid(p):
			p.queue_free()
	main.hud.clear_subtitles()
	Sfx.muffle(false)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(Sfx.BUS), false)
	finished.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _done or shot_dir != "":
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip = true
		main.hud.clear_subtitles()
		for t in _tweens:
			if t.is_valid():
				t.kill()


## Waits `t` seconds of the scene; returns at once once skipped.
func wait(t: float) -> void:
	if _skip:
		await get_tree().process_frame
		return
	var left := t
	while left > 0.0 and not _skip:
		await get_tree().process_frame
		left -= get_process_delta_time()


## One camera move: from p0 looking at l0 to p1 looking at l1 (a Vector3 or
## a Node3D to follow), over `dur` seconds. Waits for it to end.
func shot(dur: float, p0: Vector3, l0: Variant, p1: Vector3, l1: Variant, fov := 45.0, sway := 0.6) -> void:
	_shot = {"dur": dur, "p0": p0, "l0": l0, "p1": p1, "l1": l1, "sway": sway}
	_shot_t = 0.0
	cam.fov = fov
	_place_camera()
	_shot_n += 1
	if shot_dir != "":
		await wait(dur * 0.5)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_jpg("%s/%s_%02d.jpg" % [shot_dir, kind, _shot_n], 0.88)
		await wait(dur * 0.5)
		return
	await wait(dur)


## The camera inside a car, at the driver's eyes, looking out ahead.
func ride(dur: float, car: Node3D, fov := 62.0) -> void:
	_shot = {"dur": dur, "car": car}
	_shot_t = 0.0
	cam.fov = fov
	_place_camera()
	_shot_n += 1
	if shot_dir != "":
		await wait(dur * 0.5)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("%s/%s_%02d.jpg" % [shot_dir, kind, _shot_n], 0.88)
		await wait(dur * 0.5)
		return
	await wait(dur)


func _process(delta: float) -> void:
	if _done or _shot.is_empty():
		return
	_shot_t += delta
	_place_camera()
	if ext:
		ext.follow(cam)
	if _wiping and ext:
		_wipe_t += delta
		var w: Node3D = ext.zhiguli.get_meta("wiper")
		var ph := fmod(_wipe_t, 1.6) / 1.6
		w.rotation.z = -sin(ph * PI) * 1.75


func _place_camera() -> void:
	if _shot.has("car"):
		var car: Node3D = _shot.car
		var seat: Vector3 = car.get_meta("seat")
		var bob := Vector3(sin(_shot_t * 7.0) * 0.004, sin(_shot_t * 11.0) * 0.006, 0)
		cam.global_transform = car.global_transform * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-4.0)), seat + bob)
		return
	var k := clampf(_shot_t / maxf(_shot.dur, 0.01), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k) * 0.6 + k * 0.4
	var p: Vector3 = (_shot.p0 as Vector3).lerp(_shot.p1, k)
	var look: Vector3 = _point(_shot.l0).lerp(_point(_shot.l1), k)
	# A held camera breathes a little.
	var s: float = _shot.sway
	p += Vector3(sin(_shot_t * 0.9) * 0.03, sin(_shot_t * 1.3 + 1.0) * 0.02, 0) * s
	cam.global_position = p
	if not p.is_equal_approx(look):
		cam.look_at(look, Vector3.UP)


static func _point(v: Variant) -> Vector3:
	if v is Npc or v is Person:
		return (v as Node3D).global_position + Vector3(0, 1.0, 0)
	if v is Node3D:
		return (v as Node3D).global_position
	return v


func say(text: String) -> void:
	if not _skip:
		main.hud.say(text)


func caption(text: String, hold := 5.0) -> void:
	_caption.text = text
	var tw := _tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 1.2)
	tw.tween_interval(hold)
	tw.tween_property(_caption, "modulate:a", 0.0, 1.2)


func fade(alpha: float, time: float) -> void:
	_tween().tween_property(_black, "color:a", alpha, time)


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


## A looping or one-off sound outside, straight to Master (the hall's echo
## does not belong in the street).
func sound(id: String, volume_db := 0.0, at: Variant = null, bus := "Master") -> Node:
	var p: Node
	if at == null:
		var a := AudioStreamPlayer.new()
		a.stream = Sfx.get_stream(id)
		a.volume_db = volume_db
		a.bus = bus
		add_child(a)
		a.play()
		p = a
	else:
		var a3 := AudioStreamPlayer3D.new()
		a3.stream = Sfx.get_stream(id)
		a3.volume_db = volume_db
		a3.unit_size = 5.0
		a3.max_distance = 60.0
		a3.bus = bus
		if at is Node3D:
			(at as Node3D).add_child(a3)
		else:
			root.add_child(a3)
			a3.global_position = at
		a3.play()
		p = a3
	_players.append(p)
	return p


func _street(look: String) -> void:
	ext = Exterior.new(look)
	root.add_child(ext)
	ext.light_signs(look == "night")
	AudioServer.set_bus_mute(AudioServer.get_bus_index(Sfx.BUS), true)
	if look == "day":
		post.set_shader_parameter("grain", 0.03)
		post.set_shader_parameter("vignette", 0.22)
	else:
		post.set_shader_parameter("grain", 0.08)


## The Zhiguli's way off the road into the square and up to the steps; it
## drives along it from `from` (0..1) to the end over `time` seconds.
func _drive(from: float, time: float) -> void:
	var path := Path3D.new()
	var c := Curve3D.new()
	var rz := Exterior.ROAD_Z
	var spot := Exterior.ZHIGULI_SPOT
	c.add_point(Vector3(48, 0, rz - 2.0), Vector3.ZERO, Vector3(-8, 0, 0))
	c.add_point(Vector3(14, 0, rz - 2.0), Vector3(8, 0, 0), Vector3(-6, 0, 0))
	c.add_point(Vector3(6.0, 0, rz + 5.0), Vector3(2, 0, -4), Vector3(-1, 0, 4))
	c.add_point(spot + Vector3(0, 0, -5.5), Vector3(0, 0, -2), Vector3(0, 0, 2))
	c.add_point(spot, Vector3(0, 0, -1.5), Vector3.ZERO)
	path.curve = c
	ext.add_child(path)
	var follow := PathFollow3D.new()
	follow.loop = false
	follow.rotation_mode = PathFollow3D.ROTATION_Y
	path.add_child(follow)
	var car := ext.zhiguli
	car.get_parent().remove_child(car)
	follow.add_child(car)
	car.position = Vector3.ZERO
	car.rotation = Vector3.ZERO
	car.visible = true
	Vehicles.set_lights(car, true)
	follow.progress_ratio = from
	var engine := sound("engine_drive", -4.0, car)
	_engine = engine
	var tw := _tween()
	tw.tween_property(follow, "progress_ratio", 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(engine, "pitch_scale", 0.7, time).set_ease(Tween.EASE_IN)


func _park_zhiguli() -> void:
	var car := ext.zhiguli
	car.visible = true
	car.global_position = Exterior.ZHIGULI_SPOT
	car.rotation.y = PI


# --- 7 October -------------------------------------------------------------------

func _flashback() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Main.FOG_DARK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.6)
	env.ambient_light_energy = 0.05
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.3
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Main.FOG_DARK
	env.fog_depth_begin = 1.5
	env.fog_depth_end = 13.0
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	store = Store.new()
	root.add_child(store)
	# After closing: only the dairy row and the tills still lit, low.
	for i in store.rows.size() - 1:
		if i != 2:
			store.switch_off(i, true)
	for l: OmniLight3D in store.rows[2].lights:
		l.light_energy = 0.4
	for l: OmniLight3D in store.rows[store.rows.size() - 1].lights:
		l.light_energy = 0.7
	var lamp := OmniLight3D.new()
	lamp.position = TILL + Vector3(0.6, 1.3, 0.2)
	lamp.omni_range = 3.0
	lamp.light_energy = 1.1
	lamp.light_color = Store.WARM_COLOR
	root.add_child(lamp)
	# A memory: colder, paler, more grain.
	post.set_shader_parameter("saturation", 0.45)
	post.set_shader_parameter("grain", 0.14)
	post.set_shader_parameter("vignette", 0.55)
	main.view.audio_listener_enable_3d = false
	# Cold light from the refrigerated storage behind the door.
	var cold := OmniLight3D.new()
	cold.position = Vector3(9.0, 2.0, 29.6)
	cold.omni_range = 5.0
	cold.light_energy = 1.6
	cold.light_color = Color(0.6, 0.75, 0.95)
	root.add_child(cold)
	var nina := Npc.new().setup("shopper2")
	root.add_child(nina)
	nina.global_position = Vector3(9.0, 0, 28.6)
	nina.rotation.y = 0.0
	nina.speed = 1.1
	var him := Person.new().setup("killer", false)
	root.add_child(him)
	him.position = Vector3(9.05, 0, 29.9)
	him.rotation.y = PI  # faces into the hall
	him.play("idle")
	var receipt := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.075, 0.15)
	receipt.mesh = q
	receipt.material_override = Mats.get_mat("ext_receipt", Color.WHITE, Color(0.08, 0.08, 0.07), Mats.DOUBLE)
	root.add_child(receipt)
	receipt.position = TILL + Vector3(0.12, 0.1, 0.0)
	receipt.rotation.y = PI * 0.5
	receipt.scale = Vector3(1, 0.05, 1)

	await wait(0.5)
	caption("7 октября 1988 года, 22:40\nУниверсам «Кировский», после закрытия", 4.5)
	fade(0.0, 3.0)
	store.open_storage_door(true)
	nina.walk(PackedVector3Array([Vector3(9.0, 0, 26.6), Vector3(8.85, 0, 21.0), Vector3(8.0, 0, 12.0)]))
	await shot(8.0, Vector3(6.6, 1.45, 20.5), Vector3(9.0, 1.3, 28.0), Vector3(6.8, 1.4, 19.4), Vector3(8.6, 1.3, 23.0), 40.0)
	# At the till: she goes round to the cashier's side and punches it.
	nina.global_position = Vector3(-0.6, 0, 8.6)
	nina.walk(PackedVector3Array([NINA_AT_TILL]))
	await nina.arrived
	nina.look_at_point(TILL)
	var pr := sound("printer", -4.0, TILL, Sfx.BUS)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(Sfx.BUS), false)
	var tw := _tween()
	tw.tween_interval(0.4)
	tw.tween_property(receipt, "scale:y", 1.0, 1.4)
	tw.parallel().tween_property(receipt, "position:y", TILL.y + 0.25, 1.4)
	await shot(4.5, NINA_AT_TILL + Vector3(0.9, 1.55, -1.3), TILL + Vector3(0.1, 0.25, 0),
		NINA_AT_TILL + Vector3(0.75, 1.5, -1.1), TILL + Vector3(0.1, 0.25, 0), 36.0, 0.3)
	# The time on it: 22-58.
	await shot(3.0, TILL + Vector3(0.42, 0.26, -0.02), TILL + Vector3(0.12, 0.24, 0.0), TILL + Vector3(0.36, 0.255, 0.0),
		TILL + Vector3(0.12, 0.245, 0.0), 30.0, 0.1)
	if is_instance_valid(pr):
		pr.queue_free()
	# She turns to whoever she is talking to, out there in the dark.
	nina.look_at_point(Vector3(2.0, 0, 12.0))
	nina.pose = "talk"
	say(NINA_1)
	him.global_position = Vector3(3.6, 0, 14.5)
	him.rotation.y = atan2(-(NINA_AT_TILL.x - 3.6), -(NINA_AT_TILL.z - 14.5))
	him.play("idle")
	await shot(6.5, NINA_AT_TILL + Vector3(1.0, 1.55, 2.3), NINA_AT_TILL + Vector3(0, 1.45, 0),
		NINA_AT_TILL + Vector3(0.8, 1.55, 1.9), NINA_AT_TILL + Vector3(0, 1.5, 0), 40.0)
	# Over her shoulder: he comes out of the dark between the shelves.
	say(NINA_2)
	him.play("prowl", 0.6)
	# Just enough light off the tills to make out a man, not a face.
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.7, 0.8, 0.75)
	rim.light_energy = 0.5
	rim.omni_range = 2.5
	him.add_child(rim)
	rim.position = Vector3(0, 2.2, 1.0)
	var walk := _tween()
	walk.tween_property(him, "global_position", NINA_AT_TILL + Vector3(1.0, 0, 1.6), 4.5)
	await shot(4.5, NINA_AT_TILL + Vector3(-0.35, 1.78, -1.05), Vector3(3.0, 1.2, 13.5), NINA_AT_TILL + Vector3(-0.25, 1.76, -0.9),
		Vector3(1.6, 1.1, 11.0), 40.0, 0.4)
	nina.pose = "idle"
	# The duty light goes out.
	store.set_duty(false)
	for l: OmniLight3D in store.rows[store.rows.size() - 1].lights:
		l.light_energy = 0.0
	fade(1.0, 0.15)
	await wait(0.6)
	sound("cloth", -2.0, NINA_AT_TILL + Vector3(0, 1.0, 0), Sfx.BUS)
	await wait(0.9)
	sound("bodyfall", -6.0, NINA_AT_TILL, Sfx.BUS)
	await wait(2.0)
	caption("Через неделю", 1.8)
	await wait(3.2)
	main.view.audio_listener_enable_3d = true


# --- Friday 14 October: the drive -------------------------------------------------

func _night_one() -> void:
	_street("night")
	sound("rain", -10.0)
	var kovpak := Npc.new().setup("kovpak")
	ext.add_child(kovpak)
	kovpak.global_position = Vector3(0.6, Exterior.PORCH, 1.2)
	kovpak.rotation.y = 0.0  # faces the glass and the street
	kovpak.pose = "idle"
	_black.color.a = 1.0
	fade(0.0, 2.5)
	caption("Свердловск, ЖБИ, Сиреневый бульвар\nПятница, 14 октября 1988 года, 22:20", 5.0)
	say(N1_CITY)
	await shot(8.0, Vector3(-14, 16, -46), Vector3(2, 4, 0), Vector3(-9, 8, -36), Vector3(2.5, 3, -2), 42.0, 0.2)
	# Along the road: headlights in the rain, the car turns into the square.
	_drive(0.0, 21.0)
	say(N1_JOB)
	await shot(6.5, Vector3(-4, 0.7, Exterior.ROAD_Z + 5.8), ext.zhiguli, Vector3(-3.5, 0.75, Exterior.ROAD_Z + 5.6), ext.zhiguli,
		38.0, 0.3)
	# From the driver's seat: wipers, the letters coming up through the rain.
	_wiping = true
	var inside := sound("rain_car", -6.0)
	var wipe := sound("wiper", -12.0)
	(wipe as AudioStreamPlayer).finished.connect(func(): if is_instance_valid(wipe) and _wiping: (wipe as AudioStreamPlayer).play())
	say(N1_SUROVA)
	await ride(8.5, ext.zhiguli)
	_wiping = false
	inside.queue_free()
	wipe.queue_free()
	# Outside, by the steps: he pulls up beside the «Волга», lights off.
	say(N1_NINA)
	await shot(5.5, Vector3(-5.5, 1.5, -18.5), ext.zhiguli, Vector3(-4.8, 1.5, -17.5), Vector3(3.0, 1.6, -8.0), 40.0)
	Vehicles.set_lights(ext.zhiguli, false)
	sound("click", -8.0, ext.zhiguli)
	if is_instance_valid(_engine):
		_tween().tween_property(_engine, "volume_db", -60.0, 1.5)
	await shot(5.0, Vector3(-4.8, 1.5, -17.5), Vector3(3.0, 1.6, -8.0), Vector3(-4.4, 1.5, -16.8), Vector3(3.0, 2.0, -6.0), 40.0)
	# The letters over the canopy, the arrow, the rain in the lamplight.
	sound("car_door", -4.0, Exterior.ZHIGULI_SPOT + Vector3(-0.9, 1, 0))
	say(N1_VOLGA)
	await shot(6.5, Vector3(2.5, 1.0, -12.5), Vector3(2.5, 5.2, -5.6), Vector3(2.4, 1.1, -11.2), Vector3(2.5, 5.6, -5.6), 50.0, 0.3)
	# Up the steps to the doors; Ковпак waits behind the glass.
	say(N1_GO)
	await shot(6.0, Vector3(3.6, 1.65, -10.0), Vector3(0.5, 1.7, 1.0), Vector3(0.6, Exterior.PORCH + 1.62, -1.6),
		Vector3(0.5, Exterior.PORCH + 1.5, 1.2), 50.0, 1.0)
	fade(1.0, 1.0)
	await wait(1.2)


# --- Saturday 15 October: the square by day ----------------------------------------

func _day_one() -> void:
	_street("day")
	_park_zhiguli()
	var crowd := sound("crowd", -18.0)
	_black.color.a = 1.0
	fade(0.0, 1.5)
	var people: Array[Npc] = []
	var routes := [
		["shopper", [Vector3(-6, 0, -20), Vector3(0.5, 0, -7.6), Vector3(0.6, Exterior.PORCH, -4.0), Vector3(0.6, Exterior.PORCH, 1.0)]],
		["shopper_man", [Vector3(1.0, Exterior.PORCH, 0.5), Vector3(1.4, Exterior.PORCH, -4.5), Vector3(2.0, 0, -8.0), Vector3(12, 0, -24)]],
		["shopper2", [Vector3(9, 0, -18), Vector3(3.5, 0, -8.0), Vector3(3.2, Exterior.PORCH, -4.5), Vector3(2.0, Exterior.PORCH, 1.0)]],
		["edik", [Vector3(-1.5, Exterior.PORCH, -3.6), Vector3(-1.5, Exterior.PORCH, -3.6)]],
	]
	for r: Array in routes:
		var n := Npc.new().setup(r[0])
		ext.add_child(n)
		var pts: Array = r[1]
		n.global_position = pts[0]
		n.walk(PackedVector3Array(pts.slice(1)))
		people.append(n)
	# The queue on the porch, out of the doors.
	for i in 5:
		var n := Npc.new().setup(["shopper", "shopper_man", "shopper2", "shopper", "shopper_man"][i])
		ext.add_child(n)
		n.global_position = Vector3(-1.2 - i * 0.05, Exterior.PORCH, -0.8 - i * 0.65)
		n.rotation.y = PI if i % 2 == 0 else PI - 0.25  # facing the doors (+Z)
		n.pose = "idle"
	caption("Суббота, 15 октября 1988 года, 12:30", 4.5)
	say(D1_DAY)
	await shot(8.5, Vector3(-10, 2.6, -32), Vector3(2.5, 3.5, 0), Vector3(-7, 2.2, -24), Vector3(2.0, 3.0, -2), 42.0, 0.3)
	say(D1_TAMARA)
	await shot(7.5, Vector3(4.5, 1.65, -13.0), Vector3(1.0, 1.7, 1.0), Vector3(1.0, Exterior.PORCH + 1.62, -2.6),
		Vector3(1.2, Exterior.PORCH + 1.5, 1.2), 50.0, 1.0)
	fade(1.0, 0.8)
	await wait(1.0)
	crowd.queue_free()


# --- Monday 17 October: the участковый on the porch ---------------------------------

func _night_two() -> void:
	_street("night")
	sound("rain", -10.0)
	var koles := Npc.new().setup("kolesnikov")
	ext.add_child(koles)
	var kp := Vector3(1.9, Exterior.PORCH, -3.8)
	koles.global_position = kp
	koles.rotation.y = 0.0  # facing the street, watching for the car
	koles.pose = "idle"
	# His «Космос»: an ember at the fingers that glows up as he draws on it.
	var ember := OmniLight3D.new()
	ember.light_color = Color(1.0, 0.45, 0.15)
	ember.omni_range = 0.9
	ember.light_energy = 0.6
	var tip := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.008
	sm.height = 0.016
	tip.mesh = sm
	tip.material_override = Mats.get_mat("white", Color(1, 0.5, 0.2), Color(4.0, 1.4, 0.3))
	var cig := Node3D.new()
	cig.add_child(tip)
	cig.add_child(ember)
	cig.position = Vector3(0.0, -0.1, -0.06)
	koles.body.attach("Bip01 R Hand", cig)
	var glow := _tween().set_loops()
	glow.tween_property(ember, "light_energy", 1.4, 0.8)
	glow.tween_property(ember, "light_energy", 0.4, 2.2)
	_black.color.a = 1.0
	fade(0.0, 2.0)
	caption("Понедельник, 17 октября 1988 года, 22:20", 4.5)
	_drive(0.25, 17.0)
	say(N2_RAIN)
	await shot(6.0, Vector3(16, 9, -34), Vector3(0, 2, -4), Vector3(12, 6, -28), Vector3(0.5, 2, -4), 42.0, 0.2)
	_wiping = true
	var inside := sound("rain_car", -6.0)
	say(N2_KOLES)
	await ride(9.0, ext.zhiguli)
	_wiping = false
	inside.queue_free()
	Vehicles.set_lights(ext.zhiguli, false)
	koles.look_at_point(Exterior.ZHIGULI_SPOT)
	say(N2_BAG)
	await shot(7.0, kp + Vector3(1.4, 0.55, -3.2), kp + Vector3(0, 1.62, 0), kp + Vector3(1.0, 0.5, -2.6),
		kp + Vector3(0, 1.64, 0), 34.0, 0.3)
	sound("car_door", -4.0, Exterior.ZHIGULI_SPOT + Vector3(-0.9, 1, 0))
	await shot(5.0, Vector3(3.8, 1.65, -10.0), kp + Vector3(0, 1.5, 0), Vector3(1.5, Exterior.PORCH + 1.62, -5.6),
		kp + Vector3(0, 1.6, 0), 45.0, 1.0)
	fade(1.0, 1.0)
	await wait(1.2)
