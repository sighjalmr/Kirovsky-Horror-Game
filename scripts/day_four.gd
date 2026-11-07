class_name DayFour
extends DayOne

## Day four, Tuesday 25 October 1988, 12:40, the day before the last shift.
## «Кировский» is shut for stocktaking. Out on the square a yellow beer
## tanker («ПИВО») stands by the bottle crates; Эдик drinks at the round
## stand-up table beside it, Вася Кран at the next one, one of «his» men
## by the kiosk. Gordeev walks out of the doors (the store stays shut behind
## him) and talks to Эдик while the mug lasts: three questions.
##
## Эдик has seen who Nina opened the back porch to on the 7th and will not
## say it here. What scares him into it is proof that it is not the first
## time (the tin of hair, Сурова's earring, Пахомов in the lake) or that the
## third key is the policeman's. Two of those and he promises to come by
## the lockers tomorrow before closing, as he always does: in night five he
## then waits for Gordeev and adds a warning about the alarm button
## (Main.night_clues "edik_ready", see NightFive).

const D4_INTRO := "Вторник. Универсам закрыт на учёт. Завтра моя последняя смена, а свидетель у меня один. И тот пьёт пиво у бочки."
const D4_G_NOT_YET := "Сначала поговорю с Эдиком у пивной бочки."
const D4_P_MUG := "Продавщица: — Кружек нет, мужчина. Со своей банкой приходите. Вон, у Эдика спросите, у него всё есть."
const D4_V_HELLO := "Вася Кран: — Гордеич! Учёт у нас, Ковпак всех разогнал. Ты Эдика не трогай, он сегодня нервный. Всё оглядывается."
const D4_G_VASYA := "Вася Кран пьёт с обеда. Первым приходит, последним трезвеет."
const D4_E_HELLO := "Эдик: — Опять ты, дед. Я в субботу сказал: ничего не видел. Допью и пойду."
const D4_E_YES := "Эдик: — Ладно, дед. Завтра вечером приду за сумкой, как всегда, перед закрытием. Там и поговорим. Здесь нельзя."
const D4_E_NO := "Эдик: — Всё, дед. Допил. И ты бы шёл отсюда, пока цел."
const D4_E_BYE := "Эдик: — Иди, дед. Не стой рядом со мной."
const D4_G_OUTRO_YES := "Завтра, перед закрытием, у камеры хранения. Если придёт, у меня будет свидетель. Если доживёт."
const D4_G_OUTRO_NO := "Здесь он не скажет ни слова. Может, завтра сам испугается."
const D4_CAR_PROMPT := "Сесть в «Жигули» и уехать домой"

## id, the clue it needs ("" always; "answer:<id>" a question asked on an
## earlier day), the question, Эдик's answer, Gordeev's thought, the notebook
## line, and whether it frightens Эдик into talking.
const QUESTIONS_D4 := [
	["d4_seven", "", "Седьмого ты стоял у заднего двора. Я знаю.",
		"Эдик: — Ну стоял. Человека с товаром ждал. За это не сажают, дед. Почти.",
		"Признал, что был. Значит, видел: с заднего двора крыльцо как на ладони.",
		"Эдик: 7-го вечером стоял у заднего двора, ждал «товар».", false],
	["d4_box", "box", "В вентиляции жестянка: четыре пряди. Одна Нинина.",
		"Эдик: — Убери. Убери, говорю! Четыре? Я думал, одна. Я думал, она сама.",
		"Он думал, что Нина сама кому-то открыла и сама ушла. Теперь он боится по-настоящему.",
		"Эдик: про жестянку не знал. Испугался.", true],
	["d4_earring", "earring", "Серьга Галины Суровой. Восемьдесят шестой год, тоже МЖК.",
		"Эдик: — Суровой? Кассирша с Сиреневого? Её же так и не нашли. Дед, это не моё дело.",
		"Его. Он видел того, кто это делает, и тот знает, что он видел.",
		"Эдик: помнит Сурову. Понял, что Нина не первая.", true],
	["d4_key", "answer:d3_call", "Третий ключ от склада у Колесникова. Ковпак сам сказал.",
		"Эдик: — Тише ты! Вон тот, у киоска, его человек. Он мне товар крышует, понял? Мне его называть нельзя.",
		"Имени не назвал. Но и не удивился.",
		"Эдик: Колесников его «крышует». Боится его больше всех.", true],
	["d4_pahomov", "", "Пахомов, сторож с седьмого, тоже кое-что видел. Его нашли в Шарташе.",
		"Эдик: — Пахомов? Он же сам утонул. Пьяный. Все говорили, сам.",
		"Все говорили. Участковый так записал.",
		"Эдик: про Пахомова слышал. Верил, что тот утонул сам.", true],
	["d4_jeans", "", "Почём нынче «Монтана»?",
		"Эдик: — Тебе, дед, уже не надо. Тебе бы до пенсии дожить. А, ты ж и так на пенсии.",
		"Шутит. Значит, ещё не понял, во что влез.",
		"Эдик: шутит, пока не страшно.", false],
]
const ASK_D4 := 3
## Two of the frightening ones and he comes tomorrow.
const NEED_SCARED := 2

## Outside coordinates (Outdoors, the square at its own ground level): on
## the asphalt left of the parked cars, the lawn further left.
const G := Outdoors.GROUND
## The tanker on its two wheels, the tap at its left end (−x).
const TANK := Vector3(-3.2, G, -16.2)
const SELLER := Vector3(-4.95, G, -15.9)
const EDIK_AT := Vector3(-3.3, G, -13.7)
const TABLE_E := Vector3(-2.85, G, -13.9)
const VASYA_AT := Vector3(-0.6, G, -14.3)
const TABLE_V := Vector3(-1.1, G, -14.45)
const HIS_MAN := Vector3(-8.2, G, -17.6)
## Gordeev's «Жигули» (Exterior.ZHIGULI_SPOT, moved like the square).
const CAR := Exterior.ZHIGULI_SPOT + Outdoors.OFFSET
## Where the day starts: on the porch, the shut doors behind him.
const START := Vector3(1.6, 0, -3.2)

var outdoors: Outdoors
var seller: Npc
var vasya: Npc
var promised := false

var _vasya_talked := false
var _seller_talked := false
var _sun: DirectionalLight3D


func _ready() -> void:
	var store: Store = main.store
	for it in store.interactables:
		it.active = false
	outdoors = Outdoors.new(main, "day")
	main.world.add_child(outdoors)
	store.embed_street(Outdoors.GROUND)
	_build_tanker()
	_build_table(TABLE_E)
	_build_table(TABLE_V)
	_build_sign()
	seller = _person("shopper", SELLER, 0.0)
	seller.pose = "sit"
	edik = _person("edik", EDIK_AT, 0.0)
	edik.pose = "talk"
	vasya = _person("vasya", VASYA_AT, 0.0)
	var man := _person("shopper_man", HIS_MAN, 0.0)
	for n: Npc in [seller, edik, vasya, man]:
		n.call_deferred("look_at_point", TANK + Vector3(0, 0, 2.0))
	man.call_deferred("look_at_point", EDIK_AT)
	store.add_interactable("talk_edik4", EDIK_AT + Vector3(0.4, 0, 0.7), "Поговорить с Эдиком", 1.8, false)
	store.add_interactable("talk_vasya4", VASYA_AT + Vector3(0.3, 0, 0.7), "Заговорить с Васей Краном", 1.6, false)
	store.add_interactable("talk_seller4", SELLER + Vector3(0.9, 0, 0.6), "Спросить кружку пива", 1.4, false)
	store.add_interactable("car_home", CAR + Vector3(1.1, 0, 0.6), D4_CAR_PROMPT, 1.8, false)
	var crowd := AudioStreamPlayer3D.new()
	crowd.stream = Sfx.get_stream("crowd")
	crowd.volume_db = -14.0
	crowd.unit_size = 6.0
	crowd.bus = Sfx.BUS
	crowd.autoplay = true
	crowd.position = TANK + Vector3(0, 1.2, 1.5)
	main.world.add_child(crowd)
	main.world.add_child(Passersby.new(main, "4"))
	main.world.add_child(Traffic.new())
	update_notebook()


## Main calls it after its own day look (the hall's), which has no fog.
## A grey October noon over the square: a low sun through cloud, the far
## blocks fading into haze.
func _outdoor_look() -> void:
	var env: Environment = main.env
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_curve = 1.4
	env.fog_light_color = Color(0.74, 0.76, 0.77)
	env.fog_depth_begin = 30.0
	env.fog_depth_end = 300.0
	# In the hall the eye never needs more than 40 m; out here the whole
	# estate stands round the square (Exterior._build_district).
	main.player.camera.far = 600.0
	env.background_color = Color(0.74, 0.76, 0.77)
	env.ambient_light_color = Color(0.85, 0.88, 0.92)
	env.ambient_light_energy = 0.75
	env.tonemap_exposure = 1.05
	_sun = DirectionalLight3D.new()
	_sun.rotation = Vector3(deg_to_rad(-30), deg_to_rad(-150), 0)
	_sun.light_color = Color(0.95, 0.93, 0.88)
	_sun.light_energy = 0.9
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 60.0
	main.world.add_child(_sun)


## The yellow tanker: a round tank on two wheels and a tow bar, the tap and
## a tray at the seller's end, «ПИВО» along the side.
func _build_tanker() -> void:
	var k := MeshBuilder.Kit.new()
	var yellow := Color(0.86, 0.66, 0.12)
	var tank_len := 2.7
	var r := 0.62
	var axis_y := 1.05
	var right_end := TANK + Vector3(tank_len * 0.5, axis_y, 0)
	# Rotating +Y onto −X: the tank runs from its right end to the left.
	k.b("paint", yellow).cylinder(Props.rot(Vector3.BACK, PI * 0.5, right_end), r, r, tank_len, 20,
		Color.WHITE, Rect2(0, 0, 1, 1), Rect2(), true, true)
	# Bands round the tank and the hatch on top.
	for x: float in [-0.9, 0.0, 0.9]:
		k.b("metal", Color(0.42, 0.38, 0.3)).cylinder(Props.rot(Vector3.BACK, PI * 0.5,
			TANK + Vector3(x + 0.03, axis_y, 0)), r + 0.012, r + 0.012, 0.06, 20)
	k.b("paint", yellow * 0.9).cylinder(Props.at(TANK.x + 0.3, TANK.y + axis_y + r - 0.05, TANK.z), 0.22, 0.2, 0.14, 14)
	# Frame, axle, wheels.
	k.b("metal", Color(0.18, 0.18, 0.17)).box(Props.at(TANK.x, TANK.y + 0.42, TANK.z), Vector3(tank_len, 0.08, 0.9))
	for side: float in [-1.0, 1.0]:
		var w := TANK + Vector3(0.2, 0.36, side * 0.62)
		k.b("rubber", Color(0.07, 0.07, 0.07)).cylinder(Props.rot(Vector3.RIGHT, PI * 0.5, w - Vector3(0, 0, side * 0.08)),
			0.36, 0.36, 0.16, 16, Color.WHITE, Rect2(0, 0, 1, 1), Rect2(), true, true)
		k.b("paint", Color(0.5, 0.45, 0.3)).cylinder(Props.rot(Vector3.RIGHT, PI * 0.5, w + Vector3(0, 0, side * 0.09)),
			0.16, 0.16, 0.02, 12, Color.WHITE, Rect2(0, 0, 1, 1), Rect2(), true, true)
	k.b("metal", Color(0.2, 0.2, 0.19)).box(Props.at(TANK.x + tank_len * 0.5 + 0.6, TANK.y + 0.4, TANK.z),
		Vector3(1.2, 0.07, 0.07))
	k.b("metal", Color(0.2, 0.2, 0.19)).box(Props.at(TANK.x + tank_len * 0.5 + 1.15, TANK.y + 0.2, TANK.z),
		Vector3(0.06, 0.4, 0.06))
	# The tap and the drip tray at the left end, where the seller sits.
	var tap := TANK + Vector3(-tank_len * 0.5 - 0.02, axis_y - 0.35, 0.18)
	k.b("chrome", Color(0.75, 0.75, 0.72)).box(Props.at(tap.x - 0.08, tap.y, tap.z), Vector3(0.16, 0.04, 0.04))
	k.b("chrome", Color(0.75, 0.75, 0.72)).box(Props.at(tap.x - 0.15, tap.y - 0.06, tap.z), Vector3(0.03, 0.1, 0.03))
	k.b("metal", Color(0.5, 0.5, 0.48)).box(Props.at(tap.x - 0.15, TANK.y + 0.55, tap.z), Vector3(0.3, 0.03, 0.3))
	k.b("metal", Color(0.3, 0.3, 0.28)).box(Props.at(tap.x - 0.15, TANK.y + 0.27, tap.z), Vector3(0.05, 0.55, 0.05))
	# The seller's stool and a crate of empty jars beside her.
	k.b("wood", Color(0.45, 0.32, 0.2)).box(Props.at(SELLER.x, SELLER.y + 0.42, SELLER.z), Vector3(0.36, 0.05, 0.36))
	for dx: float in [-0.15, 0.15]:
		for dz: float in [-0.15, 0.15]:
			k.b("wood", Color(0.4, 0.28, 0.18)).box(Props.at(SELLER.x + dx, SELLER.y + 0.2, SELLER.z + dz),
				Vector3(0.04, 0.4, 0.04))
	var crate := SELLER + Vector3(-0.2, 0, 0.75)
	k.b("wood", Color(0.5, 0.36, 0.22)).box(Props.at(crate.x, crate.y + 0.15, crate.z), Vector3(0.6, 0.3, 0.4))
	for i in 6:
		var j := crate + Vector3(-0.2 + (i % 3) * 0.2, 0.3, -0.09 + (i / 3) * 0.18)
		k.b("glass", Color(0.7, 0.75, 0.72, 0.45), Color.BLACK, Mats.GLASS).cylinder(Props.at(j.x, j.y, j.z),
			0.055, 0.05, 0.17, 10)
	k.build(main.world, true)
	Props.collider(main.world, TANK + Vector3(0.4, 0.8, 0), Vector3(tank_len + 1.6, 1.6, 1.4))
	Props.collider(main.world, SELLER + Vector3(-0.1, 0.5, 0.3), Vector3(0.9, 1.0, 1.2))
	for side: float in [-1.0, 1.0]:
		var label := Label3D.new()
		label.text = "ПИВО"
		label.font_size = 120
		label.pixel_size = 0.0035
		label.modulate = Color(0.62, 0.1, 0.06)
		label.shaded = true
		label.position = TANK + Vector3(0.05, axis_y + 0.05, side * (r + 0.015))
		label.rotation.y = 0.0 if side > 0.0 else PI
		main.world.add_child(label)


## A round stand-up table on one leg, a jar of beer on it.
func _build_table(at: Vector3) -> void:
	var k := MeshBuilder.Kit.new()
	k.b("metal", Color(0.35, 0.36, 0.34)).cylinder(Props.at(at.x, at.y, at.z), 0.22, 0.22, 0.03, 14)
	k.b("metal", Color(0.35, 0.36, 0.34)).cylinder(Props.at(at.x, at.y, at.z), 0.03, 0.03, 1.08, 8)
	k.b("metal", Color(0.42, 0.42, 0.4)).cylinder(Props.at(at.x, at.y + 1.08, at.z), 0.36, 0.36, 0.03, 18,
		Color.WHITE, Rect2(0, 0, 1, 1), Rect2(), true, true)
	k.b("glass", Color(0.85, 0.62, 0.2, 0.7), Color.BLACK, Mats.GLASS).cylinder(Props.at(at.x + 0.1, at.y + 1.11, at.z),
		0.055, 0.05, 0.15, 10)
	k.b("glass", Color(0.95, 0.93, 0.85, 0.8), Color.BLACK, Mats.GLASS).cylinder(Props.at(at.x + 0.1, at.y + 1.26, at.z),
		0.05, 0.05, 0.02, 10)
	k.build(main.world, true)
	Props.collider(main.world, at + Vector3(0, 0.55, 0), Vector3(0.5, 1.1, 0.5))


## A cardboard notice in the glass doors: shut for stocktaking.
func _build_sign() -> void:
	var k := MeshBuilder.Kit.new()
	k.b("kraft", Color(0.92, 0.88, 0.78)).box(Props.at(-1.0, 1.35, -0.06), Vector3(0.5, 0.32, 0.01))
	k.build(main.store, false)
	var label := Label3D.new()
	label.text = "УЧЁТ"
	label.font_size = 64
	label.pixel_size = 0.0028
	label.modulate = Color(0.2, 0.18, 0.15)
	label.position = Vector3(-1.0, 1.37, -0.075)
	label.rotation.y = PI
	main.store.add_child(label)


func start() -> void:
	main.hud.say(D4_INTRO)


func questions() -> Array:
	return QUESTIONS_D4


func _available() -> Array:
	var out := []
	for q: Array in QUESTIONS_D4:
		if q[0] in asked:
			continue
		var need: String = q[1]
		if need.begins_with("answer:"):
			if not need.substr(7) in main.day_answers:
				continue
		elif need != "" and not clues.get(need, false):
			continue
		out.append(q)
	return out


func interact(id: String) -> bool:
	var hud: Hud = main.hud
	match id:
		"talk_edik4":
			if done:
				edik.look_at_point(main.player.global_position)
				hud.say(D4_E_BYE, -1.0, true)
			elif not talking:
				_talk_edik()
		"talk_vasya4":
			vasya.look_at_point(main.player.global_position)
			hud.say(D4_V_HELLO, -1.0, true)
			if not _vasya_talked:
				hud.say(D4_G_VASYA)
			_vasya_talked = true
		"talk_seller4":
			seller.look_at_point(main.player.global_position)
			_seller_talked = true
			hud.say(D4_P_MUG, -1.0, true)
		"car_home":
			if done:
				_leave()
			else:
				hud.say(D4_G_NOT_YET, -1.0, true)
		_:
			return false
	return true


func _scared() -> int:
	var n := 0
	for q: Array in QUESTIONS_D4:
		if q[0] in asked and q[6]:
			n += 1
	return n


func _talk_edik() -> void:
	var hud: Hud = main.hud
	talking = true
	main.player.busy = true
	main.store.set_interactable("talk_edik4", false)
	edik.look_at_point(main.player.global_position)
	if asked.is_empty():
		await _say(D4_E_HELLO)
	while asked.size() < ASK_D4 and _scared() < NEED_SCARED:
		var avail := _available()
		var labels: Array[String] = []
		for q: Array in avail:
			labels.append(q[2])
		labels.append("Уйти")
		var left := ASK_D4 - asked.size()
		var pick: int = await hud.choose("Спросить Эдика. Пива у него ещё на %d %s." % [left, _questions_word(left)], labels)
		if pick >= avail.size():
			await _say(D4_E_BYE)
			break
		var q: Array = avail[pick]
		asked.append(q[0])
		update_notebook()
		await _say(q[3])
		await _say(q[4])
	promised = _scared() >= NEED_SCARED
	if promised:
		await _say(D4_E_YES)
	elif asked.size() >= ASK_D4:
		await _say(D4_E_NO)
	done = true
	talking = false
	main.player.busy = false
	main.store.set_interactable("talk_edik4", true, "Эдик")
	hud.say(D4_G_OUTRO_YES if promised else D4_G_OUTRO_NO)
	update_notebook()


func _leave() -> void:
	main.player.busy = true
	Sfx.play_2d(self, "car_door", -6.0)
	main.hud.fade_to(1.0, 2.0)
	await get_tree().create_timer(1.2).timeout
	Sfx.play_2d(self, "engine", -12.0)
	await get_tree().create_timer(1.3).timeout
	main.end_day()


func update_notebook() -> void:
	var lines := PackedStringArray(["БЛОКНОТ ГОРДЕЕВА", "День четвёртый, 25 октября 1988, вторник", ""])
	lines.append("Эдик:")
	if asked.is_empty():
		lines.append("— пока ничего. Эдик пьёт пиво у бочки на площади.")
	for q: Array in QUESTIONS_D4:
		if q[0] in asked:
			lines.append("— " + q[5])
	if promised:
		lines.append("")
		lines.append("ЭДИК ПРИДЁТ: завтра перед закрытием, к камере хранения. Скажет, кого видел седьмого.")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


func objectives() -> Array:
	var out: Array = []
	if not done:
		out.append(NightOne.task("Поговорить с Эдиком у пивной бочки на площади"))
		out.append(NightOne.task("Можно заговорить с Васей Краном", _vasya_talked, true))
	else:
		out.append(NightOne.task("Поговорить с Эдиком", true))
		out.append(NightOne.task("Уехать домой на «Жигулях»"))
	return out


func summary() -> String:
	var lines := PackedStringArray()
	for q: Array in QUESTIONS_D4:
		if q[0] in asked:
			lines.append("— " + q[5])
	if promised:
		lines.append("Эдик обещал прийти завтра перед закрытием и рассказать, кого видел.")
	else:
		lines.append("Эдик ничего не обещал. Может, придёт за сумкой, как всегда.")
	return "\n".join(lines)
