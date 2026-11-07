class_name Stats
extends RefCounted

## What the player has done over every playthrough, and the achievements.
## Kept in user://stats.cfg, apart from the settings and the save, so a new
## game never resets them. Main and the chapters report events here
## (Stats.add, Stats.night_survived, Stats.ending …); the menu shows the
## page "Достижения и статистика".
##
## All player-facing text is in ACHIEVEMENTS, STAT_LINES and UI below, so a
## translation only has to touch this file. Strings go through tr() when
## shown, so a Godot translation (.po / .csv) can replace them as they are.

const PATH := "user://stats.cfg"

## id -> [name, how to get it, secret]. A secret one shows as
## «Секретное достижение» until it is earned (the endings give the plot away).
## Order is the order on the page.
const ACHIEVEMENTS := [
	["first_shift", "Первая смена", "Дожить до утра первой ночи.", false],
	["witness", "Свидетельница", "Расспросить Тамару Ивановну в первый день.", false],
	["all_rounds", "По уставу", "Подписать все обходы в журнале за одну ночь.", false],
	["all_clues_night", "Глазастый", "Найти все улики за одну ночь.", false],
	["ghost", "Тише воды", "Пережить ночь, ни разу не попавшись ему на глаза (со второй ночи).", false],
	["tore_free", "Вырвался", "Вырваться у него из рук.", false],
	["cord_free", "Шнурок не затянулся", "Вырваться, когда он душит сзади.", false],
	["first_death", "Не дожил до утра", "Погибнуть на смене.", false],
	["thrower", "Звон в зале", "Бросить десять банок или бутылок, чтобы отвлечь его.", false],
	["no_pills", "Сердце выдержало", "Пережить четвёртую ночь, не приняв валидола.", false],
	["third_key", "Третий ключ", "Добиться от Ковпака признания про третий ключ.", false],
	["night_five", "Последняя смена", "Дойти до пятой ночи.", false],
	["detective", "Следователь", "Найти все улики за ночь в режиме «Следователь».", false],
	["all_clues_ever", "Ничего не упустил", "Найти все 25 улик игры (можно за разные прохождения).", false],
	["sleuth", "Сыщик", "Записать в блокнот все четыре верных вывода за одно прохождение.", false],
	["end_prosecutor", "Прокурор", "Довести дело до прокурора.", true],
	["end_word", "Слово против слова", "Дожить до утра, но без коробки или свидетеля.", true],
	["end_wrong", "Дело закрыто", "Ошибиться в последнюю ночь.", true],
	["end_defence", "Самооборона", "Покончить с ним самому.", true],
	["end_death", "Сторож оставил пост", "Погибнуть в последнюю ночь.", true],
	["all_endings", "Все пять концовок", "Увидеть все пять концовок.", false],
	["clean_run", "Ни царапины", "Пройти всю игру с первой ночи, ни разу не погибнув.", false],
]

## Ending ids in order, with their names on the statistics page.
const ENDINGS := [
	["prosecutor", "Прокурор"],
	["word", "Слово против слова"],
	["wrong", "Дело закрыто"],
	["defence", "Самооборона"],
	["death", "Смерть"],
]

## Clues in each night (NightOne.clues keys): the 25 of the whole game.
const CLUES := {
	"night1": ["bag", "clip", "tape", "page", "invoice"],
	"night2": ["seizure", "pahomov", "token", "lock", "butt"],
	"night3": ["handset", "letter", "body", "cord", "boots"],
	"night4": ["panel", "wire", "prints", "box", "earring"],
	"night5": ["edik", "spare", "button", "wire", "planshet"],
}

## Counters on the statistics page, in order: [key, line]. A line with %s
## gets the value as text (time), the others %d.
const STAT_LINES := [
	["time", "Время в игре: %s"],
	["runs", "Новых игр начато: %d"],
	["shifts", "Ночей пережито до утра: %d"],
	["days", "Дней отработано: %d"],
	["deaths", "Гибелей на смене: %d"],
	["deaths_axe", "    от топорика: %d"],
	["deaths_cord", "    от шнурка: %d"],
	["spotted", "Раз попался ему на глаза: %d"],
	["lost_him", "Раз ушёл от погони: %d"],
	["tore_free", "Раз вырвался из рук: %d"],
	["hid", "Раз прятался: %d"],
	["thrown", "Банок и бутылок брошено: %d"],
	["pills", "Таблеток валидола: %d"],
	["rounds", "Обходов подписано: %d"],
]

## Fixed words of the page (menu headings and the toast).
const UI := {
	"menu": "Достижения и статистика",
	"achievements": "ДОСТИЖЕНИЯ",
	"stats": "СТАТИСТИКА",
	"to_stats": "Статистика",
	"to_achievements": "Достижения",
	"back": "Назад",
	"secret": "Секретное достижение",
	"secret_desc": "Откроется, когда получите.",
	"earned": "Получено: %d из %d",
	"toast": "Достижение получено",
	"clues": "Улик найдено за всё время: %d из %d",
	"deductions": "Лучший итог выводов в блокноте: %d из 4",
	"endings": "Концовки (сколько раз):",
	"ending_unseen": "???",
	"chapters": "Глав открыто: %d из %d",
}

## Counters (STAT_LINES keys and a few more).
static var counts: Dictionary = {}
## Achievement ids earned.
static var earned: Array = []
## "night1:bag" for every clue ever found.
static var clues_found: Array = []
## Ending id -> how many times seen.
static var ending_counts: Dictionary = {}
static var best_deductions := 0
## This playthrough: started with "new game" from night one, and deaths since.
static var run_from_start := false
static var run_deaths := 0

## Called with (name, description) when an achievement is earned: Main points
## it at the HUD toast.
static var notify: Callable

## This shift only: spotted, pills taken (reset as a chapter starts).
static var _spotted_tonight := 0
static var _pills_tonight := 0
## Seconds of play not yet written to disk.
static var _unsaved_time := 0.0
static var _loaded := false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	counts = cf.get_value("stats", "counts", counts)
	earned = cf.get_value("stats", "earned", earned)
	clues_found = cf.get_value("stats", "clues_found", clues_found)
	ending_counts = cf.get_value("stats", "ending_counts", ending_counts)
	best_deductions = cf.get_value("stats", "best_deductions", best_deductions)
	run_from_start = cf.get_value("run", "from_start", run_from_start)
	run_deaths = cf.get_value("run", "deaths", run_deaths)


## What earlier versions of the game already remembered (the endings and the
## chapters reached, in Settings) counts too, without a toast.
static func catch_up() -> void:
	for e: String in Settings.endings:
		if not ("end_" + e) in earned:
			earned.append("end_" + e)
		if not ending_counts.has(e):
			ending_counts[e] = 1
	if "night5" in Settings.reached and not "night_five" in earned:
		earned.append("night_five")
	if "day1" in Settings.reached and not "first_shift" in earned:
		earned.append("first_shift")
	if "night2" in Settings.reached and not "witness" in earned:
		earned.append("witness")


static func save() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		return  # developer runs leave the player's file alone
	if _unsaved_time > 0.0:
		counts["time"] = float(counts.get("time", 0.0)) + _unsaved_time
		_unsaved_time = 0.0
	var cf := ConfigFile.new()
	cf.set_value("stats", "counts", counts)
	cf.set_value("stats", "earned", earned)
	cf.set_value("stats", "clues_found", clues_found)
	cf.set_value("stats", "ending_counts", ending_counts)
	cf.set_value("stats", "best_deductions", best_deductions)
	cf.set_value("run", "from_start", run_from_start)
	cf.set_value("run", "deaths", run_deaths)
	cf.save(PATH)


# --- events --------------------------------------------------------------------

static func add(key: String, n := 1) -> void:
	counts[key] = int(counts.get(key, 0)) + n
	match key:
		"spotted":
			_spotted_tonight += n
		"pills":
			_pills_tonight += n
		"thrown":
			if int(counts[key]) >= 10:
				earn("thrower")


## Seconds of play, written out at the next save.
static func tick(delta: float) -> void:
	_unsaved_time += delta


## A chapter begins (after its cutscenes): the per-shift counters start over.
static func chapter_started(ch: String) -> void:
	_spotted_tonight = 0
	_pills_tonight = 0
	if ch == "night5":
		earn("night_five")


## "Новая игра" from night one: a fresh run for «Ни царапины».
static func new_run() -> void:
	run_from_start = true
	run_deaths = 0
	add("runs")
	save()


## A chapter picked from the list: this run no longer counts as a whole game.
static func chapter_jump() -> void:
	run_from_start = false
	save()


static func died(cord: bool, ch: String) -> void:
	add("deaths")
	add("deaths_cord" if cord else "deaths_axe")
	run_deaths += 1
	earn("first_death")
	if ch == "night5":
		ending("death")
	save()


static func tore_free(cord: bool) -> void:
	add("tore_free")
	earn("cord_free" if cord else "tore_free")
	save()


## The clues found so far tonight (the night's own clues dictionary).
static func clues_seen(ch: String, clues: Dictionary) -> void:
	var list: Array = CLUES.get(ch, [])
	var changed := false
	for k: String in list:
		if clues.get(k, false) == true and not ("%s:%s" % [ch, k]) in clues_found:
			clues_found.append("%s:%s" % [ch, k])
			changed = true
	if changed:
		if clues_found.size() >= total_clues():
			earn("all_clues_ever")
		save()


## 06:00, the night is over and he is alive.
static func night_survived(ch: String, night: NightOne, detective: bool) -> void:
	add("shifts")
	clues_seen(ch, night.clues)
	add("rounds", night.rounds_signed())
	if ch == "night1":
		earn("first_shift")
	if night.rounds.size() > 0 and night.rounds_signed() == night.rounds.size():
		earn("all_rounds")
	if night.clue_count() >= night.clues.size():
		earn("all_clues_night")
		if detective:
			earn("detective")
	if ch != "night1" and _spotted_tonight == 0:
		earn("ghost")
	if ch == "night4" and _pills_tonight == 0:
		earn("no_pills")
	save()


static func day_done(ch: String, confessed: bool) -> void:
	add("days")
	if ch == "day1":
		earn("witness")
	if confessed:
		earn("third_key")
	save()


## One of the five endings (night five).
static func ending(kind: String) -> void:
	ending_counts[kind] = int(ending_counts.get(kind, 0)) + 1
	earn("end_" + kind)
	var all := true
	for e: Array in ENDINGS:
		if not ending_counts.has(e[0]):
			all = false
	if all:
		earn("all_endings")
	save()


## The end of the game (every ending but death): the run as a whole.
static func game_finished(right_deductions: int) -> void:
	best_deductions = maxi(best_deductions, right_deductions)
	if right_deductions >= 4:
		earn("sleuth")
	if run_from_start and run_deaths == 0:
		earn("clean_run")
	save()


static func earn(id: String) -> void:
	if id in earned:
		return
	var a := find(id)
	if a.is_empty():
		return
	earned.append(id)
	save()
	if notify.is_valid():
		notify.call(tr_text(a[1]), tr_text(a[2]))


# --- reading -------------------------------------------------------------------

static func find(id: String) -> Array:
	for a: Array in ACHIEVEMENTS:
		if a[0] == id:
			return a
	return []


static func total_clues() -> int:
	var n := 0
	for ch: String in CLUES:
		n += (CLUES[ch] as Array).size()
	return n


static func play_time() -> float:
	return float(counts.get("time", 0.0)) + _unsaved_time


## "3 ч 05 мин" or "12 мин".
static func time_text(s: float) -> String:
	var m := int(s / 60.0)
	if m >= 60:
		return tr_text("%d ч %02d мин") % [m / 60, m % 60]
	return tr_text("%d мин") % m


## A line through the game's translation, if one is loaded.
static func tr_text(s: String) -> String:
	return TranslationServer.translate(s)


## The lines of the statistics page.
static func stat_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for l: Array in STAT_LINES:
		var key: String = l[0]
		if key == "time":
			out.append(tr_text(l[1]) % time_text(play_time()))
		else:
			out.append(tr_text(l[1]) % int(counts.get(key, 0)))
	out.append("")
	out.append(tr_text(UI.clues) % [clues_found.size(), total_clues()])
	out.append(tr_text(UI.deductions) % best_deductions)
	out.append(tr_text(UI.chapters) % [Settings.reached.size(), GameMenu.CHAPTERS.size()])
	out.append("")
	out.append(tr_text(UI.endings))
	for e: Array in ENDINGS:
		var n := int(ending_counts.get(e[0], 0))
		if n > 0 or e[0] in Settings.endings:
			out.append("    %s: %d" % [tr_text(e[1]), maxi(n, 1)])
		else:
			out.append("    " + tr_text(UI.ending_unseen))
	return out
