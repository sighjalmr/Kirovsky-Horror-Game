class_name DayTwo
extends DayOne

## Day two, Tuesday 18 October 1988, 12:40. Gordeev comes in on his day off
## and goes to the meat counter in the back passage, where Ринат is cutting
## meat for a queue of women. Three questions before the queue loses its
## patience. Ринат is frightened of the ОБХСС, not of a murder charge: he
## saw the militia «бобик» at the back porch on the 7th, and Колесников
## takes his meat for nothing and holds his old conviction over him.
## Two days later Ринат is arrested for the murder (night three).

const D2_INTRO := "Вторник. Выходной. Мясной отдел работает до семи, очередь до самого склада."
const D2_PHOTO := "За стеклом у весов фотокарточка: женщина в платке и двое мальчишек. Семья Рината."
const D2_R_HELLO := "Ринат: — Сторож? Мяса нет, отец. Только суповой набор. Или ты не за мясом?"
const D2_S_QUEUE := "Покупательница: — Мужчина, вы тут не стояли! Ринатик, мне кости на холодец."
const D2_S_HURRY := "Покупательница: — Ну сколько можно лясы точить? Люди с работы отпросились!"
const D2_R_LIMIT := "Ринат: — Всё, отец. Видишь, народ. Приходи вечером, поговорим. Если меня не заберут."
const D2_R_BYE := "Ринат: — Иди, отец. Тебе мясо, а мне срок."
const D2_G_OUTRO := "Ринат боится ОБХСС. Убийства он не боится. Или не знает, что его уже ищут."
const D2_G_NOT_YET := "Сначала поговорю с Ринатом за мясным прилавком."
## Behind the counter in the back passage, the queue in front of it.
const COUNTER := Vector3(5.0, 0, 26.7)
const RINAT := Vector3(5.0, 0, 27.4)
const QUEUE2: Array[Vector3] = [Vector3(4.2, 0, 25.6), Vector3(3.2, 0, 25.4), Vector3(2.2, 0, 25.5)]

const D2_QUESTIONS := [
	["d2_beef", "", "Говядина со склада. Сорок килограммов, седьмое октября.",
		"Ринат: — Тише, отец! Не я это придумал. Ковпак велел, я рубил, он вывозил. Нина узнала. Я ей сказал: молчи, всех посадят.",
		"Мясник боится ОБХСС. На убийцу не похож: убийца бы так не трясся.",
		"Ринат: говядину рубил по указке Ковпака. Нина знала и грозила ОБХСС."],
	["d2_seven", "", "Где ты был седьмого после десяти?",
		"Ринат: — До пол-одиннадцатого рубил. Вышел через склад, своим ключом запер. А у заднего крыльца «бобик» стоит, милицейский. Я ещё подумал: за мной.",
		"Милицейский «бобик» у заднего крыльца в половине одиннадцатого. В тот вечер, когда пропала Нина.",
		"Ринат: 7-го в 22:30 у заднего крыльца стоял милицейский «бобик»."],
	["d2_key", "", "У кого ещё есть ключ от склада?",
		"Ринат: — У Ковпака и у меня. Больше ни у кого. Хотя в сентябре Ковпак без ключа неделю ходил, у меня просил. Свой кому-то отдавал.",
		"Ковпак отдавал свой ключ. Кому директор отдаёт ключ от склада и не спорит?",
		"Ринат: в сентябре Ковпак кому-то отдавал свой ключ от склада."],
	["d2_prison", "", "Говорят, ты сидел.",
		"Ринат: — Кто говорит? Участковый? По малолетке, за драку, двадцать лет назад. Он мне этим каждый месяц тычет. И каждый месяц мясо берёт. Без денег.",
		"Колесников кормится у мясника и держит его на крючке. Удобный человек, чтобы на него всё повесить.",
		"Ринат: Колесников бесплатно берёт у него мясо и держит его старой судимостью."],
	["d2_paper", "", "Бумага с пометкой «Р.». Твоя?",
		"Ринат: — Моя, конечно. Я всё подписываю: «Р.», чтоб не путали. Пачка вон лежит у весов. Бери кто хочет.",
		"Бумагу с «Р.» мог взять любой, кто заходил за прилавок.",
		"Ринат: бумага с «Р.» лежит пачкой у весов, взять мог любой."],
	["d2_token", "token", "Жетон тридцать первой ячейки нашёлся. Нина носила его на шее.",
		"Ринат: — На шее, да. На шнурке. Я ей говорил: потеряешь. Её же не нашли? Отец, её же не нашли?",
		"Он не знает, что с Ниной. Или очень хорошо играет.",
		"Ринат: про жетон знал. Спрашивал, нашли ли Нину. Испуган по-настоящему."],
]

var rinat: Npc
var _photo_seen := false


func _ready() -> void:
	var store: Store = main.store
	for it in store.interactables:
		it.active = false
	store._counter(COUNTER, 3.2, true)
	var label := Label3D.new()
	label.text = "МЯСО"
	label.font_size = 96
	label.pixel_size = 0.004
	label.modulate = Color(0.8, 0.12, 0.08)
	label.position = Vector3(5.0, 2.4, 27.9)
	label.rotation.y = PI  # read from the hall side
	store.add_child(label)
	rinat = _person("rinat", RINAT, 0.0)
	rinat.pose = "talk"
	shopper = _person("shopper", QUEUE2[0], -PI * 0.1)
	_person("shopper2", QUEUE2[1], -PI * 0.2)
	var tam := _person("tamara_day", Vector3(-1.75, 0, 7.9), PI * 0.5)
	tam.pose = "sit"
	store.add_interactable("talk_rinat", COUNTER + Vector3(0, 0, -0.9), "Поговорить с Ринатом", 1.9, false)
	store.add_interactable("rinat_photo", COUNTER + Vector3(1.3, 0, -0.8), "Посмотреть на фотокарточку у весов", 1.0, false)
	store.set_interactable("door_front", true, "Уйти домой")
	var crowd := AudioStreamPlayer.new()
	crowd.stream = Sfx.get_stream("crowd")
	crowd.volume_db = -16.0
	crowd.bus = Sfx.BUS
	crowd.autoplay = true
	add_child(crowd)
	update_notebook()


func start() -> void:
	main.hud.say(D2_INTRO)


func questions() -> Array:
	return D2_QUESTIONS


func interact(id: String) -> bool:
	var hud: Hud = main.hud
	match id:
		"talk_rinat":
			if not talking:
				_talk_rinat()
		"rinat_photo":
			_photo_seen = true
			hud.say(D2_PHOTO, -1.0, true)
		"door_front":
			if done:
				_leave()
			else:
				hud.say(D2_G_NOT_YET, -1.0, true)
		_:
			return false
	return true


func _talk_rinat() -> void:
	var hud: Hud = main.hud
	talking = true
	main.player.busy = true
	main.store.set_interactable("talk_rinat", false)
	rinat.look_at_point(main.player.global_position)
	if asked.is_empty():
		shopper.look_at_point(main.player.global_position)
		await _say(D2_S_QUEUE)
		await _say(D2_R_HELLO)
	while asked.size() < ASK_LIMIT:
		var avail := _available()
		var labels: Array[String] = []
		for q: Array in avail:
			labels.append(q[2])
		labels.append("Уйти")
		var left := ASK_LIMIT - asked.size()
		var pick: int = await hud.choose("Спросить Рината. Очередь ждёт: ещё %d %s." % [left, _questions_word(left)], labels)
		if pick >= avail.size():
			await _say(D2_R_BYE)
			break
		var q: Array = avail[pick]
		asked.append(q[0])
		update_notebook()
		await _say(q[3])
		await _say(q[4])
		if asked.size() == 2:
			await _say(D2_S_HURRY)
	if asked.size() >= ASK_LIMIT:
		await _say(D2_R_LIMIT)
	done = true
	talking = false
	main.player.busy = false
	hud.say(D2_G_OUTRO)
	main.store.set_interactable("door_front", true, "Уйти домой")


func update_notebook() -> void:
	var lines := PackedStringArray(["БЛОКНОТ ГОРДЕЕВА", "День второй, 18 октября 1988, вторник", ""])
	lines.append("Показания Рината:")
	if asked.is_empty():
		lines.append("— пока нет. Ринат за мясным прилавком в заднем проходе.")
	for q: Array in D2_QUESTIONS:
		if q[0] in asked:
			lines.append("— " + q[5])
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


func objectives() -> Array:
	var out: Array = []
	if not done:
		var left := ASK_LIMIT - asked.size()
		out.append(NightOne.task("Расспросить Рината за мясным прилавком (в глубине зала)" if not talking
			else "Расспросить Рината: ещё %d %s" % [left, _questions_word(left)]))
		out.append(NightOne.task("Фотокарточка у весов", _photo_seen, true))
	else:
		out.append(NightOne.task("Расспросить Рината", true))
		out.append(NightOne.task("Уйти домой через входную дверь"))
	return out


func summary() -> String:
	var lines := PackedStringArray()
	for q: Array in D2_QUESTIONS:
		if q[0] in asked:
			lines.append("— " + q[5])
	if lines.is_empty():
		lines.append("Ринат так ничего и не сказал.")
	return "Показаний записано: %d из %d.\n\n%s" % [asked.size(), ASK_LIMIT, "\n".join(lines)]
