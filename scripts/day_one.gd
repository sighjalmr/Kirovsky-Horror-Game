class_name DayOne
extends Node

## Day one, Saturday 15 October 1988, 12:40. Gordeev comes back to the
## universam on his day off, as a customer, and questions Tamara Ivanovna at
## her till. The lights are on, there is a queue, Эдик hangs about the door.
##
## Tamara answers three questions before the queue runs out of patience.
## What he can ask depends on what he found in night one: the till roll, the
## bag, the invoice, the torn journal page. Each answer is a statement in
## the notebook that night two will build on.

const G_INTRO := "Суббота. Выходной. Пришёл как покупатель: кефир, батон и пара вопросов."
const E_JEANS := "Эдик: — Дед, джинсы надо? «Монтана», фирма. Для тебя за сто двадцать."
const G_EDIK := "Эдик. Каждый вечер здесь за пять минут до закрытия. Седьмого тоже."
const E_AGAIN := "Эдик: — Не хочешь, как хочешь. Я седьмого ничего не видел, если что."
const S_QUEUE := "Покупательница: — Мужчина, тут очередь! Вы за кем стояли?"
const G_QUEUE := "Я ненадолго, гражданка."
const T_HELLO := "Тамара Ивановна: — Опять вы. Чего вам, Гордеев? Кефир кончился, батоны вчерашние."
const S_HURRY := "Покупательница: — Сколько можно? Тамара, пробивай!"
const T_LIMIT := "Тамара Ивановна: — Всё, Гордеев. Люди ждут. Следующий!"
const T_BYE := "Тамара Ивановна: — Идите, Гордеев. И не ходите вы больше ко мне с этим."
const G_NOT_YET := "Сначала поговорю с Тамарой Ивановной."
const G_OUTRO := "Вечером снова на смену. Теперь я знаю, что искать."

## Questions: id, the clue from night one it needs ("" for none), the
## question on the button, Tamara's answer, Gordeev's thought, the notebook line.
const QUESTIONS := [
	["evening", "", "Что было седьмого вечером?",
		"Тамара Ивановна: — В десять сдала кассу и пошла на автобус. Нина ещё оставалась, сказала, догонит. Не догнала.",
		"Нина оставалась в магазине после десяти. Вчера Тамара об этом молчала.",
		"Тамара: 7-го Нина осталась в магазине после десяти."],
	["tape", "tape", "Чек на второй кассе пробит в 22:58.",
		"Тамара Ивановна: — Не я это! Нина попросила оставить кассу открытой. Сказала, надо кое-что пробить по-тихому, пока никого нет.",
		"Чек пробивала сама Нина. Что можно пробить в закрытом магазине? Только то, чего нет в накладных.",
		"Тамара: чек в 22:58 пробивала сама Нина, касса была оставлена открытой."],
	["bag", "bag", "Сумка Нины до сих пор в тридцать первой ячейке.",
		"Тамара Ивановна: — Жетон от тридцать первой она на шнурке носила, на шее. Никогда не снимала.",
		"Значит, ячейку открыл тот, кто снял жетон с её шеи.",
		"Тамара: жетон № 31 Нина носила на шее. Ячейку открыл тот, кто его снял."],
	["invoice", "invoice", "Ковпак ночью вывез со склада говядину.",
		"Тамара Ивановна: — Тише вы! Это Рината мясо, он с Ковпаком делится. Нина узнала. Сказала мне: я, Тома, в ОБХСС пойду.",
		"Нина собиралась в ОБХСС. Вот и мотив. Только чей: директора или мясника?",
		"Тамара: Нина узнала про говядину Рината и Ковпака, собиралась в ОБХСС."],
	["page", "page", "Из журнала вырвана страница за седьмое.",
		"Тамара Ивановна: — Сторожа того участковый Колесников на другой день к себе вызывал. А потом он уволился. Больше я его не видела.",
		"Колесников. Тот, что закрыл заявление о пропаже за один день.",
		"Тамара: сторожа с ночи 7-го вызывал Колесников, потом сторож уволился."],
	["who", "", "Кто ещё оставался седьмого?",
		"Тамара Ивановна: — Вася Кран на складе спал, пьяный. Ринат задерживался, мясо рубил. И Эдик крутился у входа до самого закрытия.",
		"Трое мужчин в закрытом магазине. И у двоих есть ключи от склада.",
		"Тамара: 7-го вечером в магазине были Вася Кран, Ринат и Эдик."],
]
const ASK_LIMIT := 3
## Where Tamara sits, behind the till of checkout 2 (the cashier's side is +x).
const TILL := Vector3(-1.75, 0, 7.9)
const QUEUE: Array[Vector3] = [Vector3(-3.4, 0, 8.3), Vector3(-3.4, 0, 9.3), Vector3(-3.3, 0, 10.2)]
const EDIK := Vector3(2.4, 0, 3.2)

var main: Node
## What night one turned up; set by Main from the end of the night.
var clues: Dictionary
var asked: Array[String] = []
var tamara: Npc
var edik: Npc
var shopper: Npc
var talking := false
var done := false

var _edik_talked := false


func _init(m: Node, found: Dictionary) -> void:
	main = m
	clues = found


func _ready() -> void:
	var store: Store = main.store
	for it in store.interactables:
		it.active = false
	# Tamara on her stool at till 2, the queue on the customer side, Эдик
	# leaning by the doors with a bag of jeans.
	tamara = _person("tamara_day", TILL, PI * 0.5)
	tamara.pose = "sit"
	shopper = _person("shopper", QUEUE[0], -PI * 0.5)
	_person("shopper_man", QUEUE[1], 0.0)
	_person("shopper2", QUEUE[2], 0.0)
	edik = _person("edik", EDIK, 0.93)
	store.add_interactable("talk_tamara_day", TILL + Vector3(0.25, 0, -0.95), "Поговорить с Тамарой Ивановной", 1.9, false)
	store.add_interactable("talk_edik", EDIK, "Заговорить с Эдиком", 1.6, false)
	store.set_interactable("door_front", true, "Уйти домой")
	var crowd := AudioStreamPlayer.new()
	crowd.stream = Sfx.get_stream("crowd")
	crowd.volume_db = -16.0
	crowd.bus = Sfx.BUS
	crowd.autoplay = true
	add_child(crowd)
	update_notebook()


func _person(role: String, pos: Vector3, yaw: float) -> Npc:
	var n := Npc.new().setup(role)
	main.world.add_child(n)
	n.global_position = pos
	n.rotation.y = yaw
	return n


func start() -> void:
	main.hud.say(G_INTRO)


func update(_delta: float) -> void:
	pass


func interact(id: String) -> bool:
	var hud: Hud = main.hud
	match id:
		"talk_tamara_day":
			if not talking:
				_talk()
		"talk_edik":
			edik.look_at_point(main.player.global_position)
			if _edik_talked:
				hud.say(E_AGAIN, -1.0, true)
			else:
				_edik_talked = true
				hud.say(E_JEANS, -1.0, true)
				hud.say(G_EDIK)
		"door_front":
			if done:
				_leave()
			else:
				hud.say(G_NOT_YET, -1.0, true)
		_:
			return false
	return true


## The conversation at the till: three questions, then the queue wins.
func _talk() -> void:
	var hud: Hud = main.hud
	talking = true
	main.player.busy = true
	main.store.set_interactable("talk_tamara_day", false)
	tamara.look_at_point(main.player.global_position)
	if asked.is_empty():
		shopper.look_at_point(main.player.global_position)
		await _say(S_QUEUE)
		await _say(G_QUEUE)
		await _say(T_HELLO)
	while asked.size() < ASK_LIMIT:
		var avail := _available()
		var labels: Array[String] = []
		for q: Array in avail:
			labels.append(q[2])
		labels.append("Уйти")
		var left := ASK_LIMIT - asked.size()
		var pick: int = await hud.choose("Спросить Тамару Ивановну. Очередь ждёт: ещё %d %s." % [left, _questions_word(left)], labels)
		if pick >= avail.size():
			await _say(T_BYE)
			break
		var q: Array = avail[pick]
		asked.append(q[0])
		update_notebook()
		await _say(q[3])
		await _say(q[4])
		if asked.size() == 2:
			await _say(S_HURRY)
	if asked.size() >= ASK_LIMIT:
		await _say(T_LIMIT)
	done = true
	talking = false
	main.player.busy = false
	hud.say(G_OUTRO)
	main.store.set_interactable("door_front", true, "Уйти домой")


func _questions_word(n: int) -> String:
	return "вопрос" if n == 1 else "вопроса"


func _available() -> Array:
	var out := []
	for q: Array in QUESTIONS:
		if q[0] in asked:
			continue
		if q[1] != "" and not clues.get(q[1], false):
			continue
		out.append(q)
	return out


## Shows a line and waits until it has been spoken.
func _say(text: String) -> void:
	var hud: Hud = main.hud
	hud.say(text, -1.0, true)
	var t := 2.5 + text.length() * 0.05
	var take := Voice.find(text)
	if not take.is_empty():
		t = maxf(t, float(take.length) + 0.4)
	await get_tree().create_timer(t).timeout


func _leave() -> void:
	main.player.busy = true
	main.store.set_front_door(true)
	main.hud.fade_to(1.0, 2.0)
	await get_tree().create_timer(2.5).timeout
	main.end_day()


func update_notebook() -> void:
	var lines := PackedStringArray(["БЛОКНОТ ГОРДЕЕВА", "День первый, 15 октября 1988, суббота", ""])
	lines.append("Улики первой ночи: %d из 5" % clues.values().count(true))
	lines.append("")
	lines.append("Показания:")
	if asked.is_empty():
		lines.append("— пока нет. Тамара Ивановна на второй кассе.")
	for q: Array in QUESTIONS:
		if q[0] in asked:
			lines.append("— " + q[5])
	lines.append("")
	lines.append("Подозреваемые: Ковпак (директор), Вася Кран (грузчик), Ринат (мясник), Колесников (участковый), Эдик (фарцовщик), Тамара Ивановна (кассир).")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


func summary() -> String:
	var lines := PackedStringArray()
	for q: Array in QUESTIONS:
		if q[0] in asked:
			lines.append("— " + q[5])
	if lines.is_empty():
		lines.append("Тамара Ивановна так ничего и не сказала.")
	return "Показаний записано: %d из %d.\n\n%s" % [asked.size(), ASK_LIMIT, "\n".join(lines)]
