class_name Settings
extends RefCounted

## The player's own settings and what the game remembers about him beyond one
## playthrough: volumes, mouse, brightness, subtitles, hints already shown, the
## chapters he has reached. Kept in user://settings.cfg, apart from the
## progress file, so a new game never resets them.

const PATH := "user://settings.cfg"
const VOICE_BUS := "Voice"

## 0..1 sliders.
static var master := 0.9
static var sounds := 1.0
static var voice := 1.0
## Mouse speed multiplier 0.3..2.5, and the pitch axis turned over.
static var mouse := 1.0
static var invert_y := false
## Full screen, or a window of the chosen size.
static var fullscreen := true
## Index in RESOLUTIONS: the size the 3D picture is drawn at (and the window,
## when not full screen). Menus and subtitles scale with the window.
static var resolution := 2
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const RESOLUTION_NAMES := ["1280 × 720", "1600 × 900", "1920 × 1080 (Full HD)", "2560 × 1440 (2K)"]
## Picture gamma 0.7..1.5 (1 = as the artists left it).
static var brightness := 1.0
static var subtitles := true
## 0: normal, 1: large, 2: very large.
static var sub_size := 0
## On-screen hints about the keys the first time they are needed.
static var hints := true
## "Следователь": no rings round clues, no clue counter, tasks in Gordeev's words.
static var detective := false
## Index in Loc.LANGS: the language of subtitles and on-screen text (the
## voices stay Russian). -1 until the first start picks the computer's own.
static var language := -1
## Ids of the hints already shown (Main.hint).
static var hints_seen: Array = []
## Chapters reached at least once: the chapter menu opens these.
static var reached: Array = ["night1"]
## The evacuation plan has been copied into the notebook: M opens it.
static var plan_copied := false
## Ending ids seen at least once (prosecutor, word, wrong, defence, death).
static var endings: Array = []

static var _loaded := false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		language = 0 if not OS.get_cmdline_user_args().is_empty() else Loc.default_language()
		return
	master = cf.get_value("audio", "master", master)
	sounds = cf.get_value("audio", "sounds", sounds)
	voice = cf.get_value("audio", "voice", voice)
	mouse = cf.get_value("input", "mouse", mouse)
	invert_y = cf.get_value("input", "invert_y", invert_y)
	brightness = cf.get_value("video", "brightness", brightness)
	fullscreen = cf.get_value("video", "fullscreen", fullscreen)
	resolution = clampi(cf.get_value("video", "resolution", resolution), 0, RESOLUTIONS.size() - 1)
	subtitles = cf.get_value("video", "subtitles", subtitles)
	sub_size = cf.get_value("video", "sub_size", sub_size)
	hints = cf.get_value("game", "hints", hints)
	detective = cf.get_value("game", "detective", detective)
	hints_seen = cf.get_value("game", "hints_seen", hints_seen)
	reached = cf.get_value("game", "reached", reached)
	endings = cf.get_value("game", "endings", endings)
	plan_copied = cf.get_value("game", "plan_copied", plan_copied)
	language = clampi(cf.get_value("game", "language", Loc.default_language()), 0, Loc.LANGS.size() - 1)


static func save() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		return  # developer runs leave the player's file alone
	var cf := ConfigFile.new()
	cf.set_value("audio", "master", master)
	cf.set_value("audio", "sounds", sounds)
	cf.set_value("audio", "voice", voice)
	cf.set_value("input", "mouse", mouse)
	cf.set_value("input", "invert_y", invert_y)
	cf.set_value("video", "brightness", brightness)
	cf.set_value("video", "fullscreen", fullscreen)
	cf.set_value("video", "resolution", resolution)
	cf.set_value("video", "subtitles", subtitles)
	cf.set_value("video", "sub_size", sub_size)
	cf.set_value("game", "hints", hints)
	cf.set_value("game", "detective", detective)
	cf.set_value("game", "hints_seen", hints_seen)
	cf.set_value("game", "reached", reached)
	cf.set_value("game", "endings", endings)
	cf.set_value("game", "plan_copied", plan_copied)
	cf.set_value("game", "language", language)
	cf.save(PATH)


## A slider value 0..1 as decibels (0 is silence).
static func db(v: float) -> float:
	return -80.0 if v <= 0.01 else linear_to_db(v)


## The Voice bus (Gordeev and the others speaking) is made once, beside Hall.
static func setup_bus() -> void:
	if AudioServer.get_bus_index(VOICE_BUS) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, VOICE_BUS)
		AudioServer.set_bus_send(i, "Master")
	apply_audio()


static func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, db(master))
	var v := AudioServer.get_bus_index(VOICE_BUS)
	if v != -1:
		AudioServer.set_bus_volume_db(v, db(voice))
	# The Hall bus is ducked under speech by the HUD every frame, which adds
	# db(sounds) to its own offset.


## The size to draw a 1920 × 1080 picture at for the chosen resolution
## (a portrait picture keeps its own size).
static func render_size(base: Vector2i) -> Vector2i:
	if base.x < base.y:
		return base
	var r := RESOLUTIONS[clampi(resolution, 0, RESOLUTIONS.size() - 1)]
	return Vector2i(roundi(base.x * r.y / 1080.0), r.y)


## Full screen or a window of the chosen size, centred on the screen. A window
## larger than the screen is cut down to fit; the picture inside stays at the
## chosen size. Developer runs (screenshots, tests) keep their own window.
static func apply_display() -> void:
	if not OS.get_cmdline_user_args().is_empty() or DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var want := RESOLUTIONS[clampi(resolution, 0, RESOLUTIONS.size() - 1)]
	var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var k := minf(1.0, minf(screen.size.x / float(want.x), (screen.size.y - 40) / float(want.y)))
	var size := Vector2i(roundi(want.x * k), roundi(want.y * k))
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


static func reach(ch: String) -> void:
	if not ch in reached:
		reached.append(ch)
		save()


static func saw_ending(id: String) -> void:
	if not id in endings:
		endings.append(id)
		save()


## The font size of subtitles for the chosen setting.
static func sub_font() -> int:
	return [32, 40, 48][clampi(sub_size, 0, 2)]
