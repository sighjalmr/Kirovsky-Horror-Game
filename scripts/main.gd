extends Node

## Vertical slice: one shortened night shift in universam «Кировский»,
## 14 October 1988. Builds the Full HD world viewport with the film post
## pass, the store, Gordeev, the killer and the HUD, then runs the shift
## from 22:45 to 06:00 (about ten real minutes).

const START_MIN := 22.0 * 60.0 + 45.0
const KILLER_MIN := 23.0 * 60.0 + 10.0
const END_MIN := 30.0 * 60.0          # 06:00 next morning
const EARLY_RATE := 0.15              # game minutes per second while the rows go dark
const LATE_RATE := 1.0

## The world renders this small and is scaled ×4 to Full HD with hard pixels.
const RENDER_W := 1920
const RENDER_H := 1080

const FOG_LIT := Color("6f7671")
const FOG_DARK := Color("0d0f0e")

enum Phase { TITLE, PLAY, DEAD, END }

const CHEST_TEXT := {
	"A1": "Масло «Крестьянское», двенадцать пачек. По накладной должно быть сорок.",
	"A2": "Пельмени «Сибирские». Одна пачка надорвана, кто-то ел их прямо мёрзлыми.",
	"A4": "Пусто. Иней на дне стёрт ладонью, широкой, мужской.",
	"D1": "Мороженая треска в коробке без маркировки. В зале такую не продают.",
	"D2": "Творожные сырки. Кто-то сложил их аккуратными рядами, как на витрине.",
	"D3": "Говядина, четыре куска в бумаге. Бумага подписана карандашом: «Р.».",
	"D4": "Пломбир в стаканчиках. Половина ларя пустая, а в журнале приёмки полный.",
}
const CLUE_BAG := "Ячейка № 31. Сумка Нины: пропуск в универсам, кошелёк, три рубля сорок копеек, ключи от квартиры. К матери в Тагил без ключей и денег не уезжают."
const CLUE_CLIP := "Под покрывалом пачки пельменей, а между ними женская заколка-«краб». На инее бурые полосы, будто что-то тащили к краю. Масло так не течёт."
const CLUE_TAPE := "Касса № 2, контрольная лента. Последний чек за 7 октября пробит в 22:58, когда зал уже был закрыт. Кассу в тот вечер сдавала Тамара Ивановна. Ключ от аппарата есть ещё у директора."
const FINAL_ENTRY := "Нина не уезжала. Седьмого в 22:58 кто-то пробил чек на второй кассе в закрытом магазине, а потом её тащили к третьему ларю. Это свой. У него есть ключи."

var phase := Phase.TITLE
var minutes := START_MIN
var view: SubViewport
var store: Store
var player: Player
var killer: Killer
var hud: Hud
var env: Environment
var post: ShaderMaterial
var clues := {"bag": false, "clip": false, "tape": false}

var _timeline: Array = []
var _phone: AudioStreamPlayer3D
var _phone_t := 0.0
var _phone_noise_t := 0.0
var _chase_music: AudioStreamPlayer
var _chasing := false
var _lit := 1.0
var _flash := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input()
	_build_view()
	_build_world()
	hud = Hud.new()
	add_child(hud)
	_build_timeline()
	_update_notebook()
	hud.clock.text = _fmt(minutes)
	var shot_dir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autoshot="):
			shot_dir = a.get_slice("=", 1)
	if shot_dir != "":
		var dev: Node = load("res://scripts/dev_autoshot.gd").new()
		dev.set("main", self)
		dev.set("out_dir", shot_dir)
		add_child(dev)
		return
	hud.fade.color.a = 1.0
	hud.show_title("КИРОВСКИЙ: ЗАКРЫТИЕ",
		"Свердловск, октябрь 1988\n\nНочь первая\n\n\n" +
		"Мышь — смотреть      W / A / S / D — идти\n" +
		"Shift — бег (шумно)      F (держать) — фонарик-«жучок» (шумно)\n" +
		"E — осмотреть      Tab — блокнот\n\nНажмите E, чтобы начать смену")


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
	_bind("restart", [KEY_R], [JOY_BUTTON_START], [])
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
	var world := Node3D.new()
	view.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG_LIT
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.6)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = FOG_LIT
	env.fog_light_energy = 1.0
	env.fog_density = 1.0
	env.fog_depth_begin = 2.5
	env.fog_depth_end = 14.0
	env.fog_depth_curve = 1.0
	env.fog_sky_affect = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	store = Store.new()
	world.add_child(store)
	player = Player.new()
	world.add_child(player)
	player.global_position = Vector3(9.0, 0, 2.6)
	player.face(Vector3.LEFT)
	player.noise.connect(_on_noise)
	killer = Killer.new()
	world.add_child(killer)
	killer.setup(store, player)
	killer.global_position = Vector3(9.0, 0, 33.0)
	killer.spotted.connect(_on_spotted)
	killer.lost.connect(_on_lost)
	killer.caught_player.connect(_on_caught)
	player.camera.current = true

	_phone = AudioStreamPlayer3D.new()
	_phone.stream = Sfx.get_stream("phone")
	_phone.max_distance = 40.0
	_phone.unit_size = 8.0
	world.add_child(_phone)
	_phone.global_position = store.phone_pos
	_chase_music = AudioStreamPlayer.new()
	_chase_music.stream = Sfx.get_stream("drone")
	_chase_music.volume_db = -80.0
	_chase_music.autoplay = true
	add_child(_chase_music)


func _build_timeline() -> void:
	_at(22, 45, func(): hud.say("Двадцать два сорок пять. Касса сдана, директор Ковпак уехал на своей «Волге». Магазин мой до шести утра."))
	_at(22, 46, func():
		hud.say("Свет гасят рядами, начиная с бакалеи. Директор говорит, экономия. В восемьдесят восьмом всё экономия.")
		hud.say("Нина Лукина ушла со смены седьмого. В милиции сказали: уехала к матери. А её сумка до сих пор в камере хранения, ячейка тридцать один."))
	var lines := ["Бакалея.", "Консервы.", "Молочный.", "Заморозка. Лари под покрывалами, как под простынями.", "Задний проход.",
		"Касса и вход. Остался дежурный свет над дверью и лампа на посту."]
	for i in store.rows.size():
		var idx := i
		_at(22, 50 + i * 3, func():
			store.switch_off(idx)
			hud.say(lines[idx]))
	_at(23, 10, func():
		store.open_storage_door()
		killer.activate(store.killer_spawn)
		hud.say("Хлопнула дверь склада. Ключи от неё есть у троих, и я не из них.", -1.0, true))
	_at(23, 14, func(): hud.say("Компрессоры ларей гудят всю ночь. Если какой-то замолчал, значит, рядом кто-то стоит."))
	_at(0, 40, _ring_phone)
	_at(2, 30, func(): hud.say("Половина третьего. Ковпак на прошлой неделе тоже задерживался допоздна. Говорил, ревизия."))
	_at(4, 0, func(): hud.say("Четыре. Самое глухое время. Даже трамваи на Сиреневом не ходят."))
	_at(5, 30, func(): hud.say("Полшестого. Скоро придут грузчики."))
	_timeline.sort_custom(func(a, b): return a[0] < b[0])


func _at(h: int, m: int, f: Callable) -> void:
	var t := float(h * 60 + m)
	if h < 12:
		t += 1440.0
	_timeline.append([t, f])


# --- loop -------------------------------------------------------------------------

func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 1.6)
	post.set_shader_parameter("flash", _flash)
	if phase != Phase.PLAY or get_tree().paused:
		return
	minutes += (EARLY_RATE if minutes < KILLER_MIN else LATE_RATE) * delta
	while not _timeline.is_empty() and minutes >= _timeline[0][0]:
		var ev: Array = _timeline.pop_front()
		(ev[1] as Callable).call()
	hud.clock.text = _fmt(minutes)
	_update_env(delta)
	_update_interaction()
	_update_phone(delta)
	store.update_compressors(killer.global_position if killer.is_active() else Vector3(999, 0, 999), delta)
	var music_target := -6.0 if _chasing else -80.0
	_chase_music.volume_db = move_toward(_chase_music.volume_db, music_target, delta * (60.0 if _chasing else 12.0))
	if minutes >= END_MIN:
		_end_shift()


func _update_env(delta: float) -> void:
	_lit = move_toward(_lit, store.lit_fraction(), delta * 0.4)
	var fog := FOG_DARK.lerp(FOG_LIT, _lit)
	env.fog_light_color = fog
	env.background_color = fog
	env.ambient_light_energy = lerpf(0.03, 0.35, _lit)
	env.fog_depth_begin = lerpf(1.5, 2.5, _lit)
	env.fog_depth_end = lerpf(9.0, 14.0, _lit)
	post.set_shader_parameter("grain", lerpf(0.10, 0.06, _lit))


func _update_interaction() -> void:
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
	elif phase == Phase.PLAY and event.is_action_pressed("notebook"):
		var open := not hud.notebook.visible
		hud.notebook.visible = open
		get_tree().paused = open
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	elif (phase == Phase.DEAD or phase == Phase.END) and event.is_action_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _start() -> void:
	start_now()
	hud.fade.color.a = 1.0
	hud.fade_to(0.0, 2.0)
	hud.hide_title()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Starts the shift at once (also used by the dev screenshot run).
func start_now() -> void:
	phase = Phase.PLAY
	hud.fade.color.a = 0.0
	await get_tree().create_timer(0.3).timeout
	player.controllable = true


# --- interactions -----------------------------------------------------------------

func _interact(id: String) -> void:
	match id:
		"locker31":
			if clues.bag:
				hud.say("Сумка Нины. Я оставил всё как было.", -1.0, true)
			else:
				Sfx.play_3d(view, "clank", player.global_position + Vector3(0, 1, 0), -10.0, 1.6)
				_find_clue("bag", CLUE_BAG)
		"register2":
			if clues.tape:
				hud.say("Лента на месте. 22:58.", -1.0, true)
			else:
				Sfx.play_3d(view, "pickup", player.global_position, -6.0)
				_find_clue("tape", CLUE_TAPE)
		"register1":
			hud.say("Касса № 1. Лента чистая, смену закрыли вовремя.", -1.0, true)
		"register3":
			hud.say("Касса № 3. Не работает с августа. Под ней окурки «Беломора».", -1.0, true)
		"journal":
			var n := clues.values().count(true)
			hud.say("Журнал обходов. «22:45 — пост принял, Гордеев». Сам себе написал план: камера хранения, лари в заморозке, касса № 2. Проверено: %d из 3." % n, -1.0, true)
		"door_front":
			hud.say("Заперто снаружи до шести. Так положено. За стеклом дождь и пустой Сиреневый бульвар.", -1.0, true)
		"phone":
			_answer_phone()
		_:
			if id.begins_with("chest_"):
				_lift(id.trim_prefix("chest_"))


func _lift(chest: String) -> void:
	var c: Dictionary = store.chests[chest]
	if c.lifted:
		hud.say("Этот ларь я уже смотрел.", -1.0, true)
		return
	player.busy = true
	Sfx.play_3d(view, "cloth", c.pos + Vector3(0, 0.8, 0), 0.0)
	_on_noise(c.pos, 8.0)
	await get_tree().create_timer(1.3).timeout
	if phase != Phase.PLAY:
		return
	store.lift_cloth(chest)
	player.busy = false
	if chest == Store.CLUE_CHEST:
		Sfx.play_2d(self, "stinger", -10.0)
		_find_clue("clip", CLUE_CLIP)
	else:
		hud.say(CHEST_TEXT[chest], -1.0, true)


func _find_clue(key: String, text: String) -> void:
	clues[key] = true
	hud.say(text, -1.0, true)
	if not clues.values().has(false):
		hud.say("Записал в блокнот. " + FINAL_ENTRY)
	_update_notebook()


func _update_notebook() -> void:
	var lines := PackedStringArray([
		"БЛОКНОТ ГОРДЕЕВА", "Ночь первая, 14 октября 1988, пятница", "",
		"Обход:",
		("[x] " if clues.bag else "[  ] ") + "Камера хранения, ячейка № 31",
		("[x] " if clues.clip else "[  ] ") + "Лари в заморозке",
		("[x] " if clues.tape else "[  ] ") + "Касса № 2, контрольная лента",
		""])
	if clues.bag:
		lines.append("— Сумка Нины на месте. Кошелёк и ключи внутри. К матери так не уезжают.")
	if clues.clip:
		lines.append("— В третьем ларе её заколка. На инее бурые полосы.")
	if clues.tape:
		lines.append("— Чек на второй кассе пробит 7-го в 22:58, после закрытия.")
	if not clues.values().has(false):
		lines.append("")
		lines.append(FINAL_ENTRY)
	lines.append("")
	lines.append("Подозреваемые: Ковпак (директор), Вася Кран (грузчик), Ринат (мясник), Колесников (участковый), Эдик (фарцовщик), Тамара Ивановна (кассир).")
	lines.append("")
	lines.append("Tab: закрыть")
	hud.set_notebook("\n".join(lines))


# --- the phone --------------------------------------------------------------------

func _ring_phone() -> void:
	_phone.play()
	_phone_t = 40.0
	store.set_interactable("phone", true)
	hud.say("Звонит телефон на посту. В час ночи сюда не звонят.", -1.0, true)


func _update_phone(delta: float) -> void:
	if _phone_t <= 0.0:
		return
	_phone_t -= delta
	_phone_noise_t -= delta
	if _phone_noise_t <= 0.0:
		_phone_noise_t = 2.0
		killer.hear(store.phone_pos, 30.0)
	if _phone_t <= 0.0:
		_phone.stop()
		store.set_interactable("phone", false)
		hud.say("Перестал звонить.")


func _answer_phone() -> void:
	_phone_t = 0.0
	_phone.stop()
	store.set_interactable("phone", false)
	player.busy = true
	Sfx.play_3d(view, "pickup", store.phone_pos, -4.0)
	hud.say("— Пост охраны, Гордеев. Слушаю.", 2.5, true)
	hud.say("В трубке молчат. Потом кто-то дышит, ровно, никуда не торопясь.", 4.0)
	Sfx.play_2d(self, "breath", -6.0)
	if killer.is_active():
		killer.wander_to(store.random_patrol_point())
	await get_tree().create_timer(6.0).timeout
	if phase != Phase.PLAY:
		return
	hud.say("Короткие гудки. Где-то в зале скрипнула тележка.")
	player.busy = false


# --- the killer -------------------------------------------------------------------

func _on_noise(pos: Vector3, radius: float) -> void:
	if killer.is_active():
		killer.hear(pos, radius)


func _on_spotted() -> void:
	_chasing = true
	Sfx.play_2d(self, "stinger", -4.0)


func _on_lost() -> void:
	_chasing = false


func _on_caught() -> void:
	if phase != Phase.PLAY:
		return
	phase = Phase.DEAD
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
	killer.play_attack(_on_hit)


func _on_hit(i: int) -> void:
	var p := player.global_position
	Sfx.play_3d(view, "stab", p + Vector3(0, 1.2, 0), 2.0, randf_range(0.85, 1.05))
	_flash = 1.0
	store.spawn_blood(p + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), 0.3 + i * 0.15)
	player.hit(i)
	if i == 2:
		player.die(killer.global_position)
		var pool := store.spawn_blood(p, 0.2)
		create_tween().tween_property(pool, "scale", Vector3(9, 1, 9), 4.0).set_ease(Tween.EASE_OUT)
		_chasing = false
		_show_death()


func _show_death() -> void:
	await get_tree().create_timer(2.0).timeout
	hud.fade_to(0.75, 2.0)
	hud.show_title("ГОРДЕЕВ НЕ ДОЖИЛ ДО УТРА",
		"В 6:10 его нашли грузчики, у %s.\nУчастковый Колесников записал: несчастный случай на рабочем месте.\n\nR: начать смену заново" % _where(player.global_position),
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


func _end_shift() -> void:
	phase = Phase.END
	player.controllable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	killer.deactivate()
	killer.visible = false
	_chasing = false
	_phone.stop()
	hud.set_prompt("")
	hud.clear_subtitles()
	hud.fade_to(0.9, 2.5)
	var n := clues.values().count(true)
	var summary := FINAL_ENTRY if n == 3 else "В блокноте пока мало. Нина так и числится уехавшей к матери."
	hud.show_title("06:00. КОНЕЦ СМЕНЫ",
		"Пришли грузчики. Вася Кран прячет глаза и пахнет вчерашним.\nУлик найдено: %d из 3.\n\n%s\n\nДальше: дневной эпизод и вторая ночь.\nКонец вертикального среза. R: сыграть ещё раз" % [n, summary])


func _fmt(m: float) -> String:
	var t := int(m) % 1440
	return "%02d:%02d" % [t / 60, t % 60]
