class_name DayThree
extends DayOne

## Day three, Friday 21 October 1988, 12:40. Ринат is in the remand prison;
## Ковпак does the stocktaking himself at the tills with a clipboard. Gordeev
## lays what he found on the counter, one thing at a time, and watches the
## man. Ковпак has patience for three. Only one thing breaks him: the call
## from his own office on the night Nina was found. Then he tells about the
## third key: in September участковый Колесников came about the beef, and
## Ковпак gave him the storage key to be left alone. Колесников had a copy
## made.

const D3_INTRO := "Пятница. Рината взяли во вторник ночью. Ковпак сам считает товар: продавцов не хватает."
const D3_K_HELLO := "Ковпак: — Гордеев? У тебя выходной. Иди домой. Тут ревизия."
const D3_G_HELLO := "Ревизия подождёт. Посмотрите, что я нашёл."
const D3_K_LIMIT := "Ковпак: — Всё, Гордеев. Хватит. Ещё слово, и пиши заявление."
const D3_G_OUTRO_KEY := "Третий ключ у Колесникова. С сентября. Теперь я знаю, кто входит ночью через склад."
const D3_G_OUTRO_NO := "Ковпак что-то знает про ключи. Но боится больше, чем меня."
const D3_G_NOT_YET := "Сначала поговорю с Ковпаком у касс."
const KOVPAK := Vector3(-4.6, 0, 6.6)

## Things to lay on the counter: id, the clue it needs (from night three, or
## night one / "" for always), the label, Ковпак's answer, Gordeev's thought,
## and whether this is the one that breaks him.
const EVIDENCE := [
	["d3_invoice", "", "Накладная на сорок килограммов говядины с вашей подписью.",
		"Ковпак: — Это ОБХСС интересно, Гордеев, а не тебе. И им я уже всё объяснил.",
		"Объяснил. Видно, хорошо объяснил.", false],
	["d3_body", "body", "Нина лежала в подвале под вашим складом.",
		"Ковпак: — Я в подвал десять лет не спускался! Шкаф этот с прошлой ревизии стоит. Это Ринат, его же взяли!",
		"Испуган. Но про подвал не врёт: пыль там на ступенях нетронутая была, только одни следы.", false],
	["d3_boots", "boots", "У шкафа в подвале следы хромовых сапог.",
		"Ковпак: — Хромовые? Я в ботинках хожу, сам видишь. В хромовых у нас... (замолкает) Не знаю я, кто в хромовых.",
		"Он знает, кто ходит в хромовых сапогах. Все знают.", false],
	["d3_call", "handset", "В ночь на пятницу мне звонили из вашего кабинета. Кабинет был заперт.",
		"Ковпак: — Не я звонил! (садится) В сентябре участковый пришёл. Говядина, говорит, на три года потянет. Дай ключ от склада, и я ничего не видел. Я дал. Через неделю вернул. Копию себе сделал, конечно. И от кабинета тоже.",
		"Третий ключ. У Колесникова. С сентября.", true],
	["d3_token", "", "Жетон тридцать первой ячейки, что Нина носила на шее.",
		"Ковпак: — Жетон и жетон. Я в камеру хранения не хожу, Гордеев.",
		"Пустое. Жетон его не трогает.", false],
]
const ASK_D3 := 3

var kovpak: Npc
var confessed := false


func _ready() -> void:
	var store: Store = main.store
	for it in store.interactables:
		it.active = false
	kovpak = _person("kovpak", KOVPAK, atan2(-0.6, -1.0))  # turned to the till side
	kovpak.pose = "talk"
	shopper = _person("shopper2", Vector3(-3.4, 0, 9.0), PI)
	store.add_interactable("talk_kovpak_day", KOVPAK + Vector3(0.6, 0, 1.0), "Поговорить с Ковпаком", 1.9, false)
	store.set_interactable("door_front", true, "Уйти домой")
	var crowd := AudioStreamPlayer.new()
	crowd.stream = Sfx.get_stream("crowd")
	crowd.volume_db = -20.0
	crowd.bus = Sfx.BUS
	crowd.autoplay = true
	add_child(crowd)
	update_notebook()


func start() -> void:
	main.hud.say(D3_INTRO)


func questions() -> Array:
	return EVIDENCE


func interact(id: String) -> bool:
	var hud: Hud = main.hud
	match id:
		"talk_kovpak_day":
			if not talking:
				_talk_kovpak()
		"door_front":
			if done:
				_leave()
			else:
				hud.say(D3_G_NOT_YET, -1.0, true)
		_:
			return false
	return true


func _talk_kovpak() -> void:
	var hud: Hud = main.hud
	talking = true
	main.player.busy = true
	main.store.set_interactable("talk_kovpak_day", false)
	kovpak.look_at_point(main.player.global_position)
	await _say(D3_K_HELLO)
	await _say(D3_G_HELLO)
	while asked.size() < ASK_D3 and not confessed:
		var avail := _available()
		var labels: Array[String] = []
		for q: Array in avail:
			labels.append(q[2])
		labels.append("Уйти")
		var left := ASK_D3 - asked.size()
		var pick: int = await hud.choose("Что положить перед Ковпаком? Терпения у него ещё на %d." % left, labels)
		if pick >= avail.size():
			break
		var q: Array = avail[pick]
		asked.append(q[0])
		await _say(q[3])
		await _say(q[4])
		if q[5]:
			confessed = true
		update_notebook()
	if not confessed and asked.size() >= ASK_D3:
		await _say(D3_K_LIMIT)
	done = true
	talking = false
	main.player.busy = false
	hud.say(D3_G_OUTRO_KEY if confessed else D3_G_OUTRO_NO)
	main.store.set_interactable("door_front", true, "Уйти домой")


func update_notebook() -> void:
	var lines := PackedStringArray(["БЛОКНОТ ГОРДЕЕВА", "День третий, 21 октября 1988, пятница", ""])
	lines.append("Ковпак:")
	if asked.is_empty():
		lines.append("— пока ничего. Ковпак считает товар у касс.")
	for q: Array in EVIDENCE:
		if q[0] in asked:
			lines.append("— " + q[4])
	if confessed:
		lines.append("")
		lines.append("КЛЮЧЕЙ ОТ СКЛАДА ТРИ: у Ковпака, у Рината и копия у Колесникова (с сентября). У него же ключ от кабинета.")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


func objectives() -> Array:
	var out: Array = []
	if not done:
		out.append(NightOne.task("Поговорить с Ковпаком у касс и выложить ему находки"))
	else:
		out.append(NightOne.task("Поговорить с Ковпаком", true))
		out.append(NightOne.task("Уйти домой через входную дверь"))
	return out


func summary() -> String:
	if confessed:
		return "Ковпак признался: третий ключ от склада с сентября у Колесникова. И ключ от кабинета."
	return "Ковпак ничего не сказал. Про ключи он знает больше, чем говорит."
