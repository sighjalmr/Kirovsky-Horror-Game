class_name Main
extends Node

## The first night shift in universam «Кировский», Friday 14 October 1988,
## from 22:30 to 06:00 (about half an hour of play). Builds the Full HD world
## viewport with the film post pass, the store, Gordeev, the killer and the
## HUD, keeps the clock and the timeline, and handles death, saving at the
## journal and the end of the shift. The story itself is in night_one.gd.
## The same store by day, Saturday the 15th, is day_one.gd: Main switches
## chapters by reloading the scene with `chapter` set.

const START_MIN := 22.0 * 60.0 + 30.0
const DAY_START_MIN := 12.0 * 60.0 + 40.0
const KILLER_MIN := 23.0 * 60.0 + 10.0
const END_MIN := 30.0 * 60.0          # 06:00 next morning
const EARLY_RATE := 0.15              # game minutes per second until the killer comes
const LATE_RATE := 0.3
const WAIT_RATE := 6.0                # how much faster time goes on the chair

const RENDER_W := 1920
const RENDER_H := 1080

const FOG_LIT := Color("6f7671")
const FOG_DARK := Color("0d0f0e")
const DAY_AIR := Color("d8dad4")
## The first time Gordeev runs out of breath.
const G_WINDED := "Сердце колотится в горле. Мне не тридцать лет, долго я не пробегу."

enum Phase { TITLE, CUT, PLAY, DEAD, END }

## The last signed round, kept across a scene reload after death.
static var checkpoint: Dictionary = {}
static var _resume := false
## "night1", "day1" or "night2"; survives the reload between chapters.
static var chapter := "night1"
## What night one turned up, handed on to the day. Starting the day from the
## title screen counts every clue as found.
static var night_clues: Dictionary = {}
## The questions put to Tamara Ivanovna on day one (DayOne.QUESTIONS ids),
## handed on to night two together with night_clues. Night two started from
## the title screen (night_clues empty) counts everything as known.
static var day_answers: Array = []

var phase := Phase.TITLE
var minutes := START_MIN
var view: SubViewport
var world: Node3D
var store: Store
var player: Player
var killer: Killer
var hud: Hud
var night: NightOne
var day: DayOne
var env: Environment
var post: ShaderMaterial
var chasing := false
## Developer runs speed the clock up.
var time_scale := 1.0

var _timeline: Array = []
var _chase_music: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _lit := 1.0
var _flash := 0.0
var _morning := false


## Minutes since midnight of the 14th for a clock time; after-midnight hours
## count on into the 15th.
static func clock(h: int, m: int) -> float:
	var t := float(h * 60 + m)
	if h < 12:
		t += 1440.0
	return t


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input()
	Sfx.setup_buses()
	_build_view()
	_build_world()
	hud = Hud.new()
	add_child(hud)
	if "--daytest" in OS.get_cmdline_user_args():
		chapter = "day1"
	if "--night2" in OS.get_cmdline_user_args():
		chapter = "night2"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cut="):
			chapter = a.get_slice("=", 1)
			get_tree().create_timer(2.0).timeout.connect(_start)
	if chapter == "day1":
		_ready_day()
		return
	night = NightTwo.new(self) if chapter == "night2" else NightOne.new(self)
	add_child(night)
	night.build_timeline()
	night.update_notebook()
	hud.clock.text = _fmt(minutes)
	if _resume:
		_resume = false
		_restore()
		return
	var shot_dir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autoshot="):
			shot_dir = a.get_slice("=", 1)
	if "--nighttest" in OS.get_cmdline_user_args():
		var test := "res://scripts/dev_night2test.gd" if chapter == "night2" else "res://scripts/dev_nighttest.gd"
		add_child(load(test).new().with(self))
		return
	if shot_dir != "":
		var dev: Node = load("res://scripts/dev_autoshot.gd").new()
		dev.set("main", self)
		dev.set("out_dir", shot_dir)
		add_child(dev)
		return
	hud.fade.color.a = 1.0
	hud.show_title("КИРОВСКИЙ: ЗАКРЫТИЕ",
		"Свердловск, октябрь 1988\n\n%s\n\n\n" % _night_name() +
		"Мышь — смотреть      W / A / S / D — идти\n" +
		"Shift — бег (шумно и недолго: одышка)      C — пригнуться (тихо)\n" +
		"F (держать) — фонарик-«жучок» (шумно)\n" +
		"E — осмотреть, поговорить      Tab — блокнот\n\nНажмите E, чтобы начать смену\n1 — ночь первая      2 — день первый      3 — ночь вторая")


func _night_name() -> String:
	return "Ночь вторая. Понедельник, 17 октября" if chapter == "night2" else "Ночь первая. Пятница, 14 октября"


## Day one: the lights on, people in the hall, no killer and no rounds.
func _ready_day() -> void:
	minutes = DAY_START_MIN
	if night_clues.is_empty():
		night_clues = {"bag": true, "clip": true, "tape": true, "page": true, "invoice": true}
	day = DayOne.new(self, night_clues)
	add_child(day)
	hud.clock.text = _fmt(minutes)
	_day_look()
	player.global_position = Vector3(-0.3, 0, 1.0)
	player.face(Vector3(0.15, 0, 1))
	if "--daytest" in OS.get_cmdline_user_args():
		add_child(load("res://scripts/dev_daytest.gd").new().with(self))
		return
	hud.fade.color.a = 1.0
	hud.show_title("ДЕНЬ ПЕРВЫЙ",
		"Суббота, 15 октября 1988, 12:40\nУниверсам «Кировский», Сиреневый бульвар, 2\n\n\n" +
		"Выходной. Гордеев пришёл как покупатель.\nТамара Ивановна сидит на второй кассе.\n\n" +
		"E — поговорить      цифры или мышь — выбрать вопрос\nTab — блокнот\n\nНажмите E, чтобы войти")


## Daytime: a busy shop at noon, plainly and evenly lit, no fog and no murk.
## The night keeps its fog, green grade and heavy grain.
func _day_look() -> void:
	env.fog_enabled = false
	env.background_color = DAY_AIR
	env.ambient_light_color = Color(0.93, 0.94, 0.9)
	env.ambient_light_energy = 0.95
	env.tonemap_exposure = 1.15
	for row in store.rows:
		for l: OmniLight3D in row.lights:
			l.light_energy = 1.6
			l.omni_range = 8.5
	post.set_shader_parameter("grain", 0.025)
	post.set_shader_parameter("vignette", 0.18)
	post.set_shader_parameter("saturation", 0.88)
	post.set_shader_parameter("shadow_tint", Color(0.03, 0.03, 0.03))
	post.set_shader_parameter("highlight_tint", Color(1.0, 0.99, 0.95))
	post.set_shader_parameter("halation", 0.15)
	post.set_shader_parameter("fringe", 0.3)


# --- setup ----------------------------------------------------------------------

func _setup_input() -> void:
	_bind("move_forward", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_back", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("strafe_left", [KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("strafe_right", [KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("look_left", [KEY_LEFT], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_bind("look_right", [KEY_RIGHT], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_bind("look_up", [], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_bind("look_down", [], [], [[JOY_AXIS_RIGHT_Y, 1.0]])
	_bind("run", [KEY_SHIFT], [JOY_BUTTON_B], [])
	_bind("flashlight", [KEY_F], [JOY_BUTTON_RIGHT_SHOULDER], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_bind("interact", [KEY_E, KEY_SPACE, KEY_ENTER], [JOY_BUTTON_A], [])
	_bind("notebook", [KEY_TAB], [JOY_BUTTON_BACK, JOY_BUTTON_Y], [])
	_bind("crouch", [KEY_C, KEY_CTRL], [JOY_BUTTON_LEFT_STICK], [])
	_bind("restart", [KEY_R], [JOY_BUTTON_START], [])
	_bind("new_night", [KEY_N], [], [])
	if InputMap.action_get_events("flashlight").size() < 4:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("flashlight", m)


func _bind(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.3)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)
	for a in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = a[0]
		e.axis_value = a[1]
		InputMap.action_add_event(action, e)


func _build_view() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	view = SubViewport.new()
	view.size = Vector2i(RENDER_W, RENDER_H)
	view.msaa_3d = Viewport.MSAA_4X
	view.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	view.audio_listener_enable_3d = true
	view.positional_shadow_atlas_size = 4096
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(view)
	var screen := TextureRect.new()
	screen.texture = view.get_texture()
	screen.position = Vector2.ZERO
	screen.size = Vector2(1920, 1080)
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	post = ShaderMaterial.new()
	post.shader = load("res://shaders/psx_post.gdshader")
	screen.material = post
	layer.add_child(screen)


func _build_world() -> void:
	world = Node3D.new()
	view.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG_LIT
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.6)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.25
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = FOG_LIT
	env.fog_light_energy = 1.0
	env.fog_density = 1.0
	env.fog_depth_begin = 2.0
	env.fog_depth_end = 12.0
	env.fog_depth_curve = 1.0
	env.fog_sky_affect = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	store = Store.new()
	world.add_child(store)
	player = Player.new()
	world.add_child(player)
	player.global_position = Vector3(9.2, 0, 2.7)
	player.face(Vector3.LEFT)
	player.noise.connect(on_noise)
	player.out_of_breath.connect(_on_winded)
	killer = Killer.new()
	world.add_child(killer)
	killer.setup(store, player)
	killer.global_position = Vector3(9.0, 0, 33.0)
	killer.spotted.connect(_on_spotted)
	killer.lost.connect(_on_lost)
	killer.caught_player.connect(_on_caught)
	player.camera.current = true

	_chase_music = AudioStreamPlayer.new()
	_chase_music.stream = Sfx.get_stream("drone")
	_chase_music.volume_db = -80.0
	_chase_music.autoplay = true
	add_child(_chase_music)
	var room := AudioStreamPlayer.new()
	room.stream = Sfx.get_stream("room")
	room.volume_db = -14.0
	room.bus = Sfx.BUS
	room.autoplay = true
	add_child(room)


func at(h: int, m: int, f: Callable) -> void:
	at_min(clock(h, m), f)


## Adds an event at `t` game minutes, in order.
func at_min(t: float, f: Callable) -> void:
	var i := 0
	while i < _timeline.size() and _timeline[i][0] <= t:
		i += 1
	_timeline.insert(i, [t, f])


## An event `dm` game minutes from now (postponed story beats).
func after(dm: float, f: Callable) -> void:
	at_min(minutes + dm, f)


# --- loop -------------------------------------------------------------------------

func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 1.6)
	post.set_shader_parameter("flash", _flash)
	if phase != Phase.PLAY or get_tree().paused:
		return
	var rate := EARLY_RATE if minutes < KILLER_MIN or day else LATE_RATE
	if player.sitting:
		rate *= WAIT_RATE
		if Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back").length() > 0.3 \
				or Input.is_action_just_pressed("interact") or chasing:
			stand_up()
	if not _morning:
		minutes = minf(minutes + rate * delta * time_scale, END_MIN)
	while not _timeline.is_empty() and minutes >= _timeline[0][0]:
		var ev: Array = _timeline.pop_front()
		if player.sitting:
			stand_up()
		(ev[1] as Callable).call()
	hud.clock.text = _fmt(minutes)
	_update_env(delta)
	_update_interaction()
	if day:
		day.update(delta)
		return
	night.update(delta)
	store.update_compressors(killer.global_position if killer.is_active() else Vector3(999, 0, 999), delta)
	var music_target := -6.0 if chasing else -80.0
	_chase_music.volume_db = move_toward(_chase_music.volume_db, music_target, delta * (60.0 if chasing else 12.0))


func _update_env(delta: float) -> void:
	if day:
		return
	_lit = move_toward(_lit, store.lit_fraction(), delta * 0.4)
	var fog := FOG_DARK.lerp(FOG_LIT, _lit)
	env.fog_light_color = fog
	env.background_color = fog
	env.ambient_light_energy = lerpf(0.03, 0.35, _lit)
	env.fog_depth_begin = lerpf(1.0, 2.0, _lit)
	env.fog_depth_end = lerpf(7.5, 12.0, _lit)
	post.set_shader_parameter("grain", lerpf(0.11, 0.07, _lit))


func _update_interaction() -> void:
	if player.sitting:
		hud.set_prompt("Сидите и ждёте. W / A / S / D — встать")
		return
	if not player.controllable or player.busy:
		hud.set_prompt("")
		return
	var it := store.find_interactable(player)
	if it.is_empty():
		hud.set_prompt("")
		return
	if it.needs_light and not (player.flashlight_on or store.is_lit(player.global_position)):
		hud.set_prompt("Темно. Нужен свет: держите F")
		return
	hud.set_prompt("E: " + it.prompt)
	if Input.is_action_just_pressed("interact"):
		_interact(it.id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look((event as InputEventMouseMotion).relative)
	elif event is InputEventMouseButton and event.pressed and phase == Phase.PLAY and not hud.notebook.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if phase == Phase.TITLE and event.is_action_pressed("interact"):
		_start()
	elif phase == Phase.TITLE and day == null and event is InputEventKey and event.pressed \
			and (event as InputEventKey).physical_keycode in [KEY_1, KEY_2, KEY_3]:
		var to: String = {KEY_1: "night1", KEY_2: "day1", KEY_3: "night2"}[(event as InputEventKey).physical_keycode]
		if to != chapter:
			_go_to(to, {}, [])
	elif phase == Phase.END and night and chapter == "night1" and event.is_action_pressed("interact"):
		_go_to("day1", night.clues.duplicate(), [])
	elif phase == Phase.END and day and event.is_action_pressed("interact"):
		_go_to("night2", night_clues.duplicate(), day.asked.duplicate())
	elif phase == Phase.PLAY and event.is_action_pressed("notebook"):
		var open := not hud.notebook.visible
		hud.notebook.visible = open
		get_tree().paused = open
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	elif (phase == Phase.DEAD or phase == Phase.END) and event.is_action_pressed("restart"):
		get_tree().paused = false
		_resume = phase == Phase.DEAD and not checkpoint.is_empty()
		get_tree().reload_current_scene()
	elif (phase == Phase.DEAD or phase == Phase.END) and event.is_action_pressed("new_night"):
		if chapter == "night2" and phase == Phase.DEAD:
			_go_to("night2", night_clues, day_answers)
		else:
			_go_to("night1", {}, [])


## Reloads the scene into another chapter.
func _go_to(ch: String, clues: Dictionary, answers: Array) -> void:
	get_tree().paused = false
	checkpoint = {}
	chapter = ch
	night_clues = clues
	day_answers = answers
	get_tree().reload_current_scene()


func _start() -> void:
	phase = Phase.CUT
	hud.hide_title()
	await _cutscenes()
	checkpoint = {}
	start_now()
	if day:
		day.start()
	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 2.0)
	hud.hide_title()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## The story cutscenes before this chapter (Cutscene.BEFORE), one after
## another; the store underneath stops drawing meanwhile.
func _cutscenes() -> void:
	var list: Array = Cutscene.BEFORE.get(chapter, [])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cutonly="):  # dev: just this one
			list = [a.get_slice("=", 1)]
	if list.is_empty():
		return
	hud.clock.visible = false
	hud.fade.color.a = 0.0
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	view.audio_listener_enable_3d = false
	for k: String in list:
		var cs := Cutscene.new(self, k)
		add_child(cs)
		await cs.finished
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.audio_listener_enable_3d = true
	hud.clock.visible = true
	hud.fade.color.a = 1.0
	if "--cutshots" in " ".join(OS.get_cmdline_user_args()):
		get_tree().quit()


## Starts the shift at once (also used by the dev screenshot run).
func start_now() -> void:
	phase = Phase.PLAY
	hud.fade.color.a = 0.0
	await get_tree().create_timer(0.3).timeout
	player.controllable = true


# --- interactions -----------------------------------------------------------------

func _interact(id: String) -> void:
	if day:
		day.interact(id)
	else:
		night.interact(id)


func sit_down() -> void:
	player.sitting = true
	player.busy = true
	player.global_position = Vector3(10.15, 0, 2.2)
	player.face(Vector3(-0.4, 0, 1))


func stand_up() -> void:
	player.sitting = false
	player.busy = false


# --- saving at the journal -------------------------------------------------------

func save_checkpoint() -> void:
	checkpoint = night.save_state()
	checkpoint["minutes"] = minutes
	hud.flash_note("Смена сохранена: %s" % _fmt(minutes))


## Back at the post at the time of the last signature.
func _restore() -> void:
	minutes = checkpoint.minutes
	while not _timeline.is_empty() and _timeline[0][0] <= minutes:
		_timeline.pop_front()
	night.restore_state(checkpoint)
	_lit = store.lit_fraction()
	hud.clock.text = _fmt(minutes)
	player.global_position = Vector3(10.3, 0, 3.4)
	player.face(Vector3(0.3, 0, -1))
	start_now()
	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 1.5)
	hud.flash_note("Продолжение с подписи в журнале: %s" % _fmt(minutes))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- the killer -------------------------------------------------------------------

func on_noise(pos: Vector3, radius: float) -> void:
	if killer.is_active():
		killer.hear(pos, radius)


var _winded_said := false


func _on_winded() -> void:
	if not _winded_said and phase == Phase.PLAY:
		_winded_said = true
		hud.say(G_WINDED)


func _on_spotted() -> void:
	chasing = true
	Sfx.play_2d(self, "stinger", -4.0)


func _on_lost() -> void:
	chasing = false


func _on_caught() -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.DEAD
	stand_up()
	player.controllable = false
	player.busy = true
	hud.set_prompt("")
	hud.clear_subtitles()
	hud.notebook.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Gordeev turns to face him: the blows land in full view.
	var to := killer.global_position - player.global_position
	var tw := create_tween().set_parallel()
	tw.tween_property(player, "rotation:y", player.rotation.y + angle_difference(player.rotation.y, atan2(-to.x, -to.z)), 0.25)
	tw.tween_property(player.head, "rotation:x", deg_to_rad(8.0), 0.25)
	Sfx.play_2d(self, "attack_sting", -2.0)
	_heart = Sfx.play_2d(self, "heartbeat", -4.0, "Master", 1.7)
	killer.play_attack(_on_hit)


func _on_hit(i: int) -> void:
	var p := player.global_position
	Sfx.play_3d(view, "chop", p + Vector3(0, 1.2, 0), 2.0, randf_range(0.95, 1.05))
	_flash = 1.0
	store.spawn_blood(p + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), 0.3 + i * 0.15)
	player.hit(i)
	if i < 2:
		Sfx.play_2d(self, "hurt", -3.0, Sfx.BUS, randf_range(0.97, 1.03))
		return
	player.die(killer.global_position)
	var pool := store.spawn_blood(p, 0.2)
	create_tween().tween_property(pool, "scale", Vector3(9, 1, 9), 4.0).set_ease(Tween.EASE_OUT)
	chasing = false
	Sfx.play_2d(self, "death_scream", -2.0)
	# He goes down: the hall goes dull as through cotton wool, the ears ring,
	# the pulse slows and stops.
	var tw := create_tween()
	tw.tween_interval(0.65)
	tw.tween_callback(func() -> void:
		Sfx.play_3d(view, "bodyfall", p + Vector3(0, 0.2, 0), 2.0)
		Sfx.muffle(true)
		Sfx.play_2d(self, "ringing", -14.0, "Master"))
	tw.tween_property(_heart, "pitch_scale", 0.55, 4.0)
	tw.parallel().tween_property(_heart, "volume_db", -40.0, 5.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(_heart.stop)
	_show_death()


func _show_death() -> void:
	await get_tree().create_timer(2.0).timeout
	hud.fade_to(0.75, 2.0)
	var again := "R: начать смену заново"
	if not checkpoint.is_empty():
		again = "R: продолжить с подписи в журнале (%s)\nN: начать ночь сначала" % _fmt(checkpoint.minutes)
	hud.show_title("ГОРДЕЕВ НЕ ДОЖИЛ ДО УТРА",
		"В 6:10 его нашли грузчики, у %s. Рядом лежал топорик из мясного отдела.\nУчастковый Колесников в тот же день задержал мясника Рината. Дело закрыли за неделю.\n\n%s" % [_where(player.global_position), again],
		Hud.RED)


func _where(p: Vector3) -> String:
	if store.booth_rect.has_point(Vector2(p.x, p.z)):
		return "поста охраны"
	if p.z < 6.0:
		return "камеры хранения"
	if p.z < 11.0:
		return "касс"
	if p.z > 25.0:
		return "двери склада"
	return "ларей с заморозкой" if absf(p.x) > 6.5 else "стеллажей"


## 06:00: the clock stops, Gordeev can look round but not walk; the morning
## scene plays out in night_one.gd and calls end_shift().
func begin_morning() -> void:
	_morning = true
	minutes = END_MIN
	stand_up()
	player.busy = true
	chasing = false
	night.stop_sounds()
	hud.set_prompt("")


func end_shift() -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.END
	checkpoint = {}
	player.controllable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_prompt("")
	hud.clear_subtitles()
	hud.fade_to(0.92, 2.5)
	if chapter == "night2":
		hud.show_title("06:00. КОНЕЦ ВТОРОЙ НОЧИ",
			"%s\n\nДальше: день второй, разговор с Ринатом (в работе).\nR: сыграть ночь ещё раз      N: начать с первой ночи" % night.summary())
		return
	hud.show_title("06:00. КОНЕЦ ПЕРВОЙ НОЧИ",
		"%s\n\nE: дальше, день первый\nR: сыграть ночь ещё раз" % night.summary())


## Gordeev walks out into the afternoon; the day's statements on the card.
func end_day() -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.END
	player.controllable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_prompt("")
	hud.clear_subtitles()
	hud.fade_to(0.92, 1.0)
	hud.show_title("КОНЕЦ ДНЯ ПЕРВОГО",
		"%s\n\nE: дальше, ночь вторая\nR: сыграть день ещё раз      N: начать с первой ночи" % day.summary())


func _fmt(m: float) -> String:
	var t := int(m) % 1440
	return "%02d:%02d" % [t / 60, t % 60]
