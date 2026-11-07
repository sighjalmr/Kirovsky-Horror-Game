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
## Picture gamma 0.7..1.5 (1 = as the artists left it).
static var brightness := 1.0
static var subtitles := true
## 0: normal, 1: large, 2: very large.
static var sub_size := 0
## On-screen hints about the keys the first time they are needed.
static var hints := true
## "Следователь": no rings round clues, no clue counter, tasks in Gordeev's words.
static var detective := false
## Ids of the hints already shown (Main.hint).
static var hints_seen: Array = []
## Chapters reached at least once: the chapter menu opens these.
static var reached: Array = ["night1"]
## Ending ids seen at least once (prosecutor, word, wrong, defence, death).
static var endings: Array = []

static var _loaded := false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	master = cf.get_value("audio", "master", master)
	sounds = cf.get_value("audio", "sounds", sounds)
	voice = cf.get_value("audio", "voice", voice)
	mouse = cf.get_value("input", "mouse", mouse)
	invert_y = cf.get_value("input", "invert_y", invert_y)
	brightness = cf.get_value("video", "brightness", brightness)
	subtitles = cf.get_value("video", "subtitles", subtitles)
	sub_size = cf.get_value("video", "sub_size", sub_size)
	hints = cf.get_value("game", "hints", hints)
	detective = cf.get_value("game", "detective", detective)
	hints_seen = cf.get_value("game", "hints_seen", hints_seen)
	reached = cf.get_value("game", "reached", reached)
	endings = cf.get_value("game", "endings", endings)


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
	cf.set_value("video", "subtitles", subtitles)
	cf.set_value("video", "sub_size", sub_size)
	cf.set_value("game", "hints", hints)
	cf.set_value("game", "detective", detective)
	cf.set_value("game", "hints_seen", hints_seen)
	cf.set_value("game", "reached", reached)
	cf.set_value("game", "endings", endings)
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
