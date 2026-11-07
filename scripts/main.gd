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

## Hiding and tearing free.
const G_HIDE_LATE := "Он смотрит прямо на меня. Прятаться поздно."
const G_ESCAPE := "Ударил его фонарём в лицо и вырвался. Второй раз так не повезёт."
const G_ESCAPE_CORD := "Шнурок. Сзади, как Нину. Локтем ему под рёбра, и вывернулся. Шея горит."
## The cord takes more: E presses in seconds.
const CORD_PRESSES := 10
const CORD_TIME := 3.0
## E presses needed in STRUGGLE_TIME seconds to tear free, once a night.
const STRUGGLE_PRESSES := 7
const STRUGGLE_TIME := 2.2
## Gordeev's own pulse once he is near: it starts within DREAD_RANGE metres,
## and quickens and grows louder as the man closes in.
const DREAD_RANGE := 10.0
## The progress file: the chapter, what was found and asked, the last signature.
const SAVE_PATH := "user://save.json"

## How near a clue has to be before a ring shows round it, metres.
const CLUE_MARK_RANGE := 4.5

enum Phase { TITLE, CUT, PLAY, DEAD, END }

## The last signed round, kept across a scene reload after death.
static var checkpoint: Dictionary = {}
static var _resume := false
## "night1", "day1" … "night5"; survives the reload between chapters.
static var chapter := "night1"
## What night one turned up, handed on to the day. Starting the day from the
## title screen counts every clue as found.
static var night_clues: Dictionary = {}
## The questions put to Tamara Ivanovna on day one (DayOne.QUESTIONS ids),
## handed on to night two together with night_clues. Night two started from
## the title screen (night_clues empty) counts everything as known.
static var day_answers: Array = []
## Gordeev's morning conclusions: chapter -> index of the answer picked
## (Deductions.QUESTIONS). Kept in the save file.
static var deductions: Dictionary = {}
## The save file is read once, on the first start of the game.
static var _booted := false
## Set before a reload that should go straight into the chapter (menu: new
## game, a chapter), past the title.
static var _autostart := false

var phase := Phase.TITLE
var minutes := START_MIN
var view: SubViewport
var world: Node3D
var store: Store
var player: Player
var killer: Killer
var hud: Hud
var menu: GameMenu
var night: NightOne
var day: DayOne
## Each day -> [the night after it, end title, "next" hint].
const DAYS := {
	"day1": ["night2", "КОНЕЦ ДНЯ ПЕРВОГО", "ночь вторая"],
	"day2": ["night3", "КОНЕЦ ДНЯ ВТОРОГО", "ночь третья"],
	"day3": ["night4", "КОНЕЦ ДНЯ ТРЕТЬЕГО", "ночь четвёртая"],
}
## Cans, broken glass, валидол, the plan and the man's habits (nights only).
var tactics: Tactics
var env: Environment
var post: ShaderMaterial
var chasing := false
## Developer runs speed the clock up.
var time_scale := 1.0

var _timeline: Array = []
var _chase_music: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _dread: AudioStreamPlayer
var _lit := 1.0
var _flash := 0.0
var _morning := false
## Once a night Gordeev may tear free of him (mash E).
var _escaped := false
var _struggling := false
var _mash := 0
var _need := STRUGGLE_PRESSES
var _cord := false
## The morning question is on screen: the end-of-shift keys wait.
var _deducing := false
var _hide_spot: Dictionary = {}
## Seconds of play in this chapter, for the first key hints.
var _played := 0.0


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
	if not _booted:
		_booted = true
		Settings.load_all()
		if not _dev():
			_load_save()
	_setup_input()
	Sfx.setup_buses()
	Settings.setup_bus()
	_build_view()
	_build_world()
	hud = Hud.new()
	add_child(hud)
	menu = GameMenu.new()
	add_child(menu)
	menu.picked.connect(_on_menu)
	apply_settings()
	if "--daytest" in OS.get_cmdline_user_args():
		chapter = "day1"
	for d in ["--day2", "--day3"]:
		if d in OS.get_cmdline_user_args():
			chapter = d.substr(2)
	if "--night2" in OS.get_cmdline_user_args():
		chapter = "night2"
	if "--night3" in OS.get_cmdline_user_args():
		chapter = "night3"
	if "--night4" in OS.get_cmdline_user_args():
		chapter = "night4"
	if "--night5" in OS.get_cmdline_user_args():
		chapter = "night5"
	if Cutscene.vertical():  # dev: a phone video of a cutscene
		get_tree().root.content_scale_size = Vector2i(1080, 1920)
		hud.subtitle.position = Vector2(60, 1260)
		hud.subtitle.size = Vector2(960, 320)
		hud.subtitle.add_theme_font_size_override("font_size", 42)
		hud.subtitle.visible = "--subs" in OS.get_cmdline_user_args()  # the voice plays, no subtitles
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cut="):
			chapter = a.get_slice("=", 1)
			get_tree().create_timer(2.0).timeout.connect(_start)
	if chapter in DAYS:
		_ready_day()
		return
	if chapter == "night5":
		night = NightFive.new(self)
	elif chapter == "night4":
		night = NightFour.new(self)
	elif chapter == "night3":
		night = NightThree.new(self)
	elif chapter == "night2":
		night = NightTwo.new(self)
	else:
		night = NightOne.new(self)
	add_child(night)
	tactics = Tactics.new(self, int(chapter.right(1)))
	add_child(tactics)
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
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--streetshot="):
			var ss: Node = load("res://scripts/dev_streetshot.gd").new().with(self)
			ss.set("out_dir", a.get_slice("=", 1))
			add_child(ss)
			return
		if a.begins_with("--streettest="):
			var st: Node = load("res://scripts/dev_streettest.gd").new().with(self)
			st.set("out_dir", a.get_slice("=", 1))
			add_child(st)
			return
	if "--nighttest" in OS.get_cmdline_user_args():
		var test: String = {"night2": "res://scripts/dev_night2test.gd", "night3": "res://scripts/dev_night3test.gd",
			"night4": "res://scripts/dev_night4test.gd", "night5": "res://scripts/dev_night5test.gd"}.get(
			chapter, "res://scripts/dev_nighttest.gd")
		add_child(load(test).new().with(self))
		return
	if shot_dir != "":
		var dev: Node = load("res://scripts/dev_autoshot.gd").new()
		dev.set("main", self)
		dev.set("out_dir", shot_dir)
		add_child(dev)
		return
	hud.fade.color.a = 1.0
	_title_menu()


## The title: the name over black and the menu under it. A reload that came
## from "new game" or the chapter list goes straight in.
func _title_menu() -> void:
	if _autostart:
		_autostart = false
		_start()
		return
	hud.show_title("КИРОВСКИЙ: ЗАКРЫТИЕ", "Свердловск, октябрь 1988")
	menu.has_progress = chapter != "night1" or not checkpoint.is_empty() or not night_clues.is_empty()
	menu.continue_label = "Продолжить: " + _night_name()
	if not checkpoint.is_empty():
		menu.continue_label += ", с подписи в %s" % _fmt(checkpoint.minutes)
	menu.show_title_menu()


func _on_menu(id: String) -> void:
	match id:
		"apply":
			apply_settings()
		"resume":
			menu.close()
		"quit":
			Settings.save()
			get_tree().quit()
		"to_title":
			menu.close()
			get_tree().paused = false
			Settings.save()
			get_tree().reload_current_scene()
		"continue":
			menu.close()
			if not checkpoint.is_empty() and night:
				_resume = true
				get_tree().reload_current_scene()
			else:
				_start()
		"new":
			menu.close()
			if chapter == "night1" and checkpoint.is_empty() and night_clues.is_empty():
				_start()
			else:
				_autostart = true
				_go_to("night1", {}, [])
		_:
			if id.begins_with("chapter:"):
				menu.close()
				_autostart = true
				_go_to(id.get_slice(":", 1), {}, [])


## Brightness, subtitles and the detective mode, from Settings.
func apply_settings() -> void:
	post.set_shader_parameter("brightness", Settings.brightness)
	if hud:
		hud.apply_settings()


## A key hint shown once ever (Settings.hints_seen), if hints are on.
func hint(id: String, text: String) -> void:
	if not Settings.hints or id in Settings.hints_seen or _dev():
		return
	Settings.hints_seen.append(id)
	Settings.save()
	hud.show_hint(text)


## The first time something is needed, the key for it.
func _update_hints(delta: float) -> void:
	_played += delta
	if _played > 2.0:
		hint("move", "Мышь — смотреть, W / A / S / D — идти. Esc — пауза и настройки")
	if _played > 25.0:
		hint("tasks", "J — что делать сейчас. Tab — блокнот с уликами")
	if day:
		hint("day", "E — поговорить. Вопрос выбирайте цифрами или мышью")
		return
	if not store.is_lit(player.global_position) and not player.flashlight_on and not player.hidden:
		hint("dark", "Темно. Держите F или правую кнопку мыши — фонарик. Он жужжит: его слышно")
	if killer.is_active() and killer.visible \
			and player.global_position.distance_to(killer.global_position) < 16.0:
		hint("crouch", "Он близко. C — пригнуться: шаги тише, вас хуже видно")
	if chasing:
		hint("run", "Shift — бежать, но недолго. Оторвитесь и спрячьтесь: E у прилавков и коробок")


func _night_name() -> String:
	for c: Array in GameMenu.CHAPTERS:
		if c[0] == chapter:
			return c[1]
	if chapter == "night5":
		return "Ночь пятая, последняя. Среда, 26 октября"
	if chapter == "night4":
		return "Ночь четвёртая. Воскресенье, 23 октября"
	if chapter == "night3":
		return "Ночь третья. Четверг, 20 октября"
	return "Ночь вторая. Понедельник, 17 октября" if chapter == "night2" else "Ночь первая. Пятница, 14 октября"


## Day one: the lights on, people in the hall, no killer and no rounds.
func _ready_day() -> void:
	minutes = DAY_START_MIN
	match chapter:
		"day2":
			if night_clues.is_empty():
				night_clues = {"seizure": true, "pahomov": true, "token": true, "lock": true, "butt": true}
			day = DayTwo.new(self, night_clues)
		"day3":
			if night_clues.is_empty():
				night_clues = {"handset": true, "letter": true, "body": true, "cord": true, "boots": true}
			day = DayThree.new(self, night_clues)
		_:
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
	_title_menu()


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
	store.set_upper_lights(true)
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
	_bind("tasks", [KEY_J], [JOY_BUTTON_X], [])
	_bind("throw", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], [])
	_bind("pill", [KEY_V], [], [])
	_bind("plan", [KEY_M], [], [])
	# E works in the menus as well as Enter and Space.
	var has_e := false
	for ev in InputMap.action_get_events("ui_accept"):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_E:
			has_e = true
	if not has_e:
		var ek := InputEventKey.new()
		ek.physical_keycode = KEY_E
		InputMap.action_add_event("ui_accept", ek)
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
	_dread = AudioStreamPlayer.new()
	_dread.stream = Sfx.get_stream("heartbeat")
	_dread.volume_db = -80.0
	_dread.bus = "Master"
	_dread.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_dread)
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
	hud.tasks_allowed = phase == Phase.PLAY and not _morning and player.controllable
	if phase != Phase.PLAY or get_tree().paused:
		return
	if not _morning and player.controllable:
		_update_hints(delta)
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
	_update_tasks()
	if day:
		day.update(delta)
		return
	night.update(delta)
	tactics.update(delta)
	store.update_compressors(killer.global_position if killer.is_active() else Vector3(999, 0, 999), delta)
	var music_target := -6.0 if chasing else -80.0
	_chase_music.volume_db = move_toward(_chase_music.volume_db, music_target, delta * (60.0 if chasing else 12.0))
	_update_dread(delta)


## The pulse in his ears: nothing while the hall is empty, a slow thud when
## the man is a shelf or two away, racing in a chase.
func _update_dread(delta: float) -> void:
	var near := 0.0
	if killer.is_active() and killer.visible and not _morning:
		var d := Vector2(killer.global_position.x - player.global_position.x,
			killer.global_position.z - player.global_position.z).length()
		near = clampf((DREAD_RANGE - d) / (DREAD_RANGE - 2.0), 0.0, 1.0)
		if chasing:
			near = maxf(near, 0.8)
	var vol := -80.0 if near <= 0.0 or player._pant.playing else lerpf(-26.0, -7.0, near)
	_dread.volume_db = move_toward(_dread.volume_db, vol, delta * (30.0 if vol > _dread.volume_db else 10.0))
	_dread.pitch_scale = lerpf(_dread.pitch_scale, lerpf(0.9, 1.45, near), delta * 0.8)
	if _dread.volume_db > -79.0 and not _dread.playing:
		_dread.play()
	elif _dread.volume_db <= -79.0 and _dread.playing:
		_dread.stop()


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
	if night and night.outdoors:
		night.outdoors.blend_env(env)


func _update_interaction() -> void:
	if player.hidden:
		hud.set_prompt("Вы спрятались. E или W / A / S / D — выйти")
		if Input.is_action_just_pressed("interact") \
				or Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back").length() > 0.3:
			leave_hiding()
		return
	if _struggling:
		hud.set_prompt(("ШНУРОК НА ШЕЕ! Жмите E: %d" if _cord else "ВЫРЫВАЙТЕСЬ! Жмите E: %d") % maxi(0, _need - _mash))
		return
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


## The task list and the rings round clues near by.
func _update_tasks() -> void:
	var chap: Node = day if day else night
	var list: Array = chap.objectives()
	if Settings.detective:
		# No counters and no step-by-step directions: what to do, not where.
		var kept: Array = []
		for t: Dictionary in list:
			var text: String = t.text
			if text.begins_with("Улики") or (t.get("sub", false) and not t.get("urgent", false)):
				continue
			kept.append(t)
		list = kept
	hud.set_tasks(list)
	var pts: Array = []
	if Settings.detective:
		hud.marks.points = pts
		return
	var cam := player.camera
	var eye := cam.global_position
	var space := player.get_world_3d().direct_space_state
	for m: Variant in chap.clue_marks():
		# A point, or [point, range] for things seen from further off.
		var p: Vector3 = m[0] if m is Array else m
		var reach: float = m[1] if m is Array else CLUE_MARK_RANGE
		var d := eye.distance_to(p)
		if d > reach or cam.is_position_behind(p):
			continue
		var q := PhysicsRayQueryParameters3D.create(eye, p)
		q.exclude = [player.get_rid()]
		var hit := space.intersect_ray(q)
		# Hidden behind a shelf or a wall; the clue's own box may stop the ray close to it.
		if not hit.is_empty() and eye.distance_to(hit.position) < d - 0.9:
			continue
		var at := cam.unproject_position(p)
		if Rect2(0, 0, RENDER_W, RENDER_H).has_point(at):
			pts.append([at, 1.0 - clampf((d - 1.2) / (reach - 1.2), 0.0, 1.0)])
	hud.marks.points = pts


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tasks"):
		hud.toggle_tasks()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look((event as InputEventMouseMotion).relative)
	elif event is InputEventMouseButton and event.pressed and phase == Phase.PLAY and not hud.notebook.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if tactics and tactics.plan_open():
		if event.is_action_pressed("plan") or event.is_action_pressed("ui_cancel"):
			tactics.close_plan()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not menu.is_open():
		if phase == Phase.PLAY and not _struggling and not hud.choices.visible:
			if hud.notebook.visible:
				hud.notebook.visible = false
				get_tree().paused = false
			menu.open_pause()
			get_viewport().set_input_as_handled()
			return
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Developer jump to any chapter from the title: the number keys 1–6.
	if phase == Phase.TITLE and day == null and event is InputEventKey and event.pressed \
			and (event as InputEventKey).physical_keycode in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]:
		var to: String = {KEY_1: "night1", KEY_2: "day1", KEY_3: "night2", KEY_4: "night3", KEY_5: "night4",
			KEY_6: "night5"}[
			(event as InputEventKey).physical_keycode]
		if to != chapter:
			_go_to(to, {}, [])
		return
	if menu.is_open():
		return
	if _struggling and event.is_action_pressed("interact"):
		_mash += 1
		Sfx.play_2d(self, "hurt", -14.0, Sfx.BUS, randf_range(1.1, 1.3))
		return
	if _deducing:
		return
	if phase == Phase.END and night and chapter == "night1" and event.is_action_pressed("interact"):
		_go_to("day1", night.clues.duplicate(), [])
	elif phase == Phase.END and night and chapter == "night2" and event.is_action_pressed("interact"):
		_go_to("day2", night.clues.duplicate(), day_answers)
	elif phase == Phase.END and night and chapter == "night3" and event.is_action_pressed("interact"):
		_go_to("day3", night.clues.duplicate(), day_answers)
	elif phase == Phase.END and night and chapter == "night4" and event.is_action_pressed("interact"):
		var carried := night.clues.duplicate()
		carried["has_box"] = (night as NightFour).has_box
		_go_to("night5", carried, day_answers)
	elif phase == Phase.END and day and event.is_action_pressed("interact"):
		_go_to(DAYS[chapter][0], _day_carry(), _day_answers_after())
	elif phase == Phase.PLAY and tactics and player.controllable and not _struggling and event.is_action_pressed("throw"):
		tactics.throw()
	elif phase == Phase.PLAY and tactics and player.controllable and not _struggling and event.is_action_pressed("pill"):
		tactics.take_pill()
	elif phase == Phase.PLAY and tactics and not hud.notebook.visible and not hud.memo.visible and not _struggling \
			and event.is_action_pressed("plan"):
		if Settings.plan_copied:
			tactics.open_plan()
		else:
			hud.say("План бы пригодился. Он висит на стене поста.", -1.0, true)
	elif phase == Phase.PLAY and event.is_action_pressed("notebook") and not hud.memo.visible and not _struggling:
		var open := not hud.notebook.visible
		if open:
			_fill_notebook_right()
		hud.notebook.visible = open
		get_tree().paused = open
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	elif (phase == Phase.DEAD or phase == Phase.END) and event.is_action_pressed("restart"):
		get_tree().paused = false
		_resume = phase == Phase.DEAD and not checkpoint.is_empty()
		_autostart = not _resume
		get_tree().reload_current_scene()
	elif (phase == Phase.DEAD or phase == Phase.END) and event.is_action_pressed("new_night"):
		if chapter in ["night2", "night3", "night4", "night5"] and phase == Phase.DEAD:
			_go_to(chapter, night_clues, day_answers)
		else:
			_go_to("night1", {}, [])


## Reloads the scene into another chapter.
func _go_to(ch: String, clues: Dictionary, answers: Array) -> void:
	_autostart = true
	if ch == "night1":
		deductions = {}
	get_tree().paused = false
	checkpoint = {}
	chapter = ch
	night_clues = clues
	day_answers = answers
	write_save(ch, clues, answers, {})
	get_tree().reload_current_scene()


func _start() -> void:
	phase = Phase.CUT
	hud.hide_title()
	await _cutscenes()
	checkpoint = {}
	write_save(chapter, night_clues, day_answers, {})
	start_now()
	_echo_deduction()
	if day:
		day.start()
	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 2.0)
	hud.hide_title()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if chapter == "night1":
		# The previous guard's note in the round journal: how not to be seen.
		get_tree().paused = true
		await get_tree().create_timer(1.2).timeout
		await hud.read_memo(NightOne.MEMO)
		get_tree().paused = false
		hud.say(NightOne.G_MEMO)


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
	var args := " ".join(OS.get_cmdline_user_args())
	if "--cutshots" in args or "--cutquit" in args:  # dev: stills, or a movie with --write-movie
		get_tree().quit()


## Starts the shift at once (also used by the dev screenshot run).
func start_now() -> void:
	phase = Phase.PLAY
	hud.fade.color.a = 0.0
	await get_tree().create_timer(0.3).timeout
	player.controllable = true


# --- interactions -----------------------------------------------------------------

func _interact(id: String) -> void:
	if tactics and tactics.interact(id):
		return
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
	if player.hidden:
		leave_hiding()
	player.sitting = false
	player.busy = false


## Gets into a hiding place: {"id", "pos" (where he crouches), "face", "out"
## (where he steps back out)}. Too late if the killer is watching him.
func hide_in(spot: Dictionary) -> void:
	if killer.has_him_in_sight():
		hud.say(G_HIDE_LATE, -1.0, true)
		return
	_hide_spot = spot
	player.crouching = false
	player.hidden = true
	player.busy = true
	player.global_position = spot.pos
	player.face(spot.face)
	Sfx.play_3d(view, "cloth", spot.pos + Vector3(0, 0.5, 0), -12.0, 0.8)


func leave_hiding() -> void:
	if not player.hidden:
		return
	player.hidden = false
	player.busy = false
	if not _hide_spot.is_empty():
		player.global_position = _hide_spot.out
	_hide_spot = {}


# --- saving at the journal -------------------------------------------------------

func save_checkpoint() -> void:
	checkpoint = night.save_state()
	checkpoint["minutes"] = minutes
	write_save(chapter, night_clues, day_answers, checkpoint)
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
	hud.flash_note("Продолжение с сохранения: %s" % _fmt(minutes))
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
	if phase != Phase.PLAY or _struggling:
		return
	_cord = killer.garrote
	if not _escaped:
		_struggle()
		return
	_kill()


## His hands on Gordeev: one chance a night to tear free by hammering E.
## From behind it is the cord: more presses, the picture closing in.
func _struggle() -> void:
	_escaped = true
	_struggling = true
	_mash = 0
	_need = CORD_PRESSES if _cord else STRUGGLE_PRESSES
	var limit := CORD_TIME if _cord else STRUGGLE_TIME
	stand_up()
	player.controllable = false
	player.busy = true
	hud.notebook.visible = false
	var to := killer.global_position - player.global_position
	create_tween().tween_property(player, "rotation:y",
		player.rotation.y + angle_difference(player.rotation.y, atan2(-to.x, -to.z)), 0.2)
	Sfx.play_2d(self, "attack_sting", -4.0)
	Sfx.play_3d(view, "killer_breath", killer.global_position + Vector3(0, 1.7, 0), -2.0, 1.0, 6.0)
	_flash = 0.6
	player.hit(0)
	if _cord:
		Sfx.play_2d(self, "cloth", -2.0, "Master", 0.7)
	var t := 0.0
	while t < limit and phase == Phase.PLAY:
		await get_tree().process_frame
		t += get_process_delta_time()
		if _cord:
			post.set_shader_parameter("vignette", lerpf(0.55, 1.6, t / limit))
	_struggling = false
	if _cord:
		post.set_shader_parameter("vignette", 0.55)
	if phase != Phase.PLAY:
		return
	if _mash < _need:
		_kill()
		return
	Sfx.play_3d(view, "clank", killer.global_position + Vector3(0, 1.6, 0), 0.0, 0.8)
	_flash = 0.3
	# Night five: he is down, and Gordeev may finish it (an ending).
	if await night.on_tore_free():
		return
	player.controllable = true
	player.busy = false
	player.breath = maxf(player.breath, 0.7)
	player.winded = false
	hud.set_prompt("")
	hud.say(G_ESCAPE_CORD if _cord else G_ESCAPE, -1.0, true)
	killer.stun(2.5)
	on_noise(player.global_position, 10.0)


func _kill() -> void:
	phase = Phase.DEAD
	if chapter == "night5":
		Settings.saw_ending("death")
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
	_dread.stop()
	Sfx.play_2d(self, "attack_sting", -2.0)
	_heart = Sfx.play_2d(self, "heartbeat", -4.0, "Master", 1.7)
	if _cord:
		_strangled()
		return
	killer.play_attack(_on_hit)


## The cord: no blows, the picture closes in from the edges, the pulse
## stumbles and stops.
func _strangled() -> void:
	killer.play_garrote()
	chasing = false
	Sfx.play_2d(self, "hurt", -6.0, Sfx.BUS, 0.8)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: post.set_shader_parameter("vignette", v), 0.9, 2.4, 3.5)
	tw.parallel().tween_property(player.head, "rotation:x", deg_to_rad(28.0), 3.5)
	tw.parallel().tween_property(_heart, "pitch_scale", 0.5, 4.0)
	tw.tween_callback(func() -> void:
		player.die(killer.global_position)
		Sfx.play_3d(view, "bodyfall", player.global_position + Vector3(0, 0.2, 0), 2.0)
		Sfx.muffle(true))
	tw.tween_property(_heart, "volume_db", -40.0, 3.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(_heart.stop)
	_show_death()


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
		again = "R: продолжить с последнего сохранения (%s)\nN: начать ночь сначала" % _fmt(checkpoint.minutes)
	var after := "Участковый Колесников в тот же день задержал мясника Рината. Дело закрыли за неделю."
	if chapter == "night4":
		after = "Участковый Колесников записал: «Сторож оставил пост, находился в нетрезвом виде». Дело закрыли за неделю."
	if chapter == "night5":
		after = "В журнале обходов последняя запись почерком участкового: «Сторож оставил пост». Коробку из-под монпансье никто не искал.\nКонцовка «Смерть». Всего концовок пять."
	var how := "Рядом лежал топорик из мясного отдела."
	if _cord:
		how = "На шее борозда от шнурка, как у Нины Лукиной и Галины Суровой."
	hud.show_title("ГОРДЕЕВ НЕ ДОЖИЛ ДО УТРА",
		"В 6:10 его нашли грузчики, у %s. %s\n%s\n\n%s" % [_where(player.global_position), how, after, again],
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
	await _deduce()
	if chapter == "night4":
		var carried := night.clues.duplicate()
		carried["has_box"] = (night as NightFour).has_box
		write_save("night5", carried, day_answers, {})
		hud.show_title("06:00. КОНЕЦ ЧЕТВЁРТОЙ НОЧИ",
			"%s\n\nE: дальше, ночь пятая, последняя (день четвёртый в работе)\nR: сыграть ночь ещё раз      N: начать с первой ночи" % night.summary())
		return
	if chapter == "night3":
		write_save("day3", night.clues, day_answers, {})
		hud.show_title("06:00. КОНЕЦ ТРЕТЬЕЙ НОЧИ",
			"%s\n\nE: дальше, день третий (Ковпак)\nR: сыграть ночь ещё раз      N: начать с первой ночи" % night.summary())
		return
	if chapter == "night2":
		write_save("day2", night.clues, day_answers, {})
		hud.show_title("06:00. КОНЕЦ ВТОРОЙ НОЧИ",
			"%s\n\nE: дальше, день второй (Ринат)\nR: сыграть ночь ещё раз      N: начать с первой ночи" % night.summary())
		return
	write_save("day1", night.clues, [], {})
	hud.show_title("06:00. КОНЕЦ ПЕРВОЙ НОЧИ",
		"%s\n\nE: дальше, день первый\nR: сыграть ночь ещё раз" % night.summary())


## Six in the morning: what Gordeev makes of the night, one answer of three.
func _deduce() -> void:
	var q := Deductions.question(chapter)
	if q.is_empty() or "--nighttest" in OS.get_cmdline_user_args():
		return
	_deducing = true
	await get_tree().create_timer(1.5).timeout
	var labels: Array[String] = []
	for a: String in q[1]:
		labels.append(a)
	var pick := await hud.choose("Утро. Записываю в блокнот вывод. " + String(q[0]), labels)
	deductions[chapter] = pick
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play_2d(self, "pickup", -14.0, "Master", 0.8)
	_deducing = false


## Last morning's conclusion, in Gordeev's words, as the next shift starts.
func _echo_deduction() -> void:
	var prev: String = {"night2": "night1", "night3": "night2", "night4": "night3", "night5": "night4"}.get(chapter, "")
	var line := Deductions.echo(prev, deductions)
	if line == "":
		return
	await get_tree().create_timer(9.0).timeout
	if phase == Phase.PLAY:
		hud.say(line)


## The right-hand page of the notebook, filled as it opens.
func _fill_notebook_right() -> void:
	var extra := ""
	if tactics:
		extra += "\n\nВалидол: %d %s." % [tactics.pills, "таблетка" if tactics.pills == 1 else "таблетки"]
	if night and Settings.detective:
		var left := night.clues.size() - night.clue_count()
		if left > 0:
			extra += "\nЧто-то я ещё упускаю. Мест, куда я не заглянул, %d." % left
	hud.notebook_right.text = Deductions.people_page(chapter, deductions) + extra


const ENDINGS := {
	"prosecutor": ["КОНЕЦ. ПРОКУРОР", "Гордеев дожил до утра и довёл дело до прокурора: коробка, страница Пахомова и показания Эдика. Колесников осуждён, дело засекречено.\nЛучшая концовка."],
	"word": ["КОНЕЦ. СЛОВО ПРОТИВ СЛОВА", "Гордеев дожил до утра, но для суда этого мало. Нужны и коробка, и свидетель: Эдик забирает сумку из камеры хранения в самом начале смены."],
	"wrong": ["КОНЕЦ. ДЕЛО ЗАКРЫТО", "Неверное обвинение или улика в чужих руках. Колесников закрыл дело, и через год всё повторилось."],
	"defence": ["КОНЕЦ. САМООБОРОНА", "Гордеев убил Колесникова в зале. Правду он знает, но судили его самого."],
}


## Night five is the last: its ending, over black.
func end_game(kind: String, summary: String) -> void:
	phase = Phase.END
	checkpoint = {}
	player.controllable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_prompt("")
	hud.clear_subtitles()
	hud.fade_to(0.95, 1.0)
	write_save("night5", night_clues, day_answers, {})
	Settings.saw_ending(kind)
	var e: Array = ENDINGS[kind]
	summary += "\nВерных выводов в блокноте: %d из 4." % Deductions.count_right(deductions)
	summary += "\nКонцовок открыто: %d из 5." % Settings.endings.size()
	var tail := "%s\n\n%s\nВсего концовок пять: прокурор, слово против слова, дело закрыто, самооборона и смерть.\n\nR: сыграть пятую ночь ещё раз      N: начать с первой ночи" % [e[1], summary]
	if Deductions.EPILOGUES.has(kind):
		await get_tree().create_timer(1.2).timeout
		hud.show_epilogue(e[0], Deductions.EPILOGUES[kind], tail)
	else:
		hud.show_title(e[0], tail)


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
	var next: Array = DAYS[chapter]
	write_save(next[0], _day_carry(), _day_answers_after(), {})
	hud.show_title(next[1],
		"%s\n\nE: дальше, %s\nR: сыграть день ещё раз      N: начать с первой ночи" % [day.summary(), next[2]])


## What a day hands on to the next night: the clues of the night before it,
## plus the third key if Ковпак told about it on day three.
func _day_carry() -> Dictionary:
	var c := night_clues.duplicate()
	if chapter == "day3" and (day as DayThree).confessed:
		c["third_key"] = true
	return c


## Every question asked on every day so far, so later nights can refer to them.
func _day_answers_after() -> Array:
	var out: Array = day_answers.duplicate() if chapter != "day1" else []
	for a in day.asked:
		if not a in out:
			out.append(a)
	return out


# --- the save file -----------------------------------------------------------------

## Developer runs (any command-line arguments) neither read nor write the save.
static func _dev() -> bool:
	return not OS.get_cmdline_user_args().is_empty()


## Where the player is: the chapter to start, what the earlier chapters left,
## and the last signature in the journal (night only).
static func write_save(ch: String, clues: Dictionary, answers: Array, cp: Dictionary) -> void:
	Settings.reach(ch)
	if _dev():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": 1, "chapter": ch, "night_clues": clues,
			"day_answers": answers, "checkpoint": cp, "deductions": deductions}))


static func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or not data.get("chapter", "") in ["night1", "day1", "night2", "day2", "night3", "day3", "night4", "night5"]:
		return
	chapter = data.chapter
	night_clues = data.get("night_clues", {})
	day_answers = data.get("day_answers", [])
	checkpoint = data.get("checkpoint", {})
	deductions = data.get("deductions", {})
	if chapter in DAYS:
		checkpoint = {}


func _fmt(m: float) -> String:
	var t := int(m) % 1440
	return "%02d:%02d" % [t / 60, t % 60]
