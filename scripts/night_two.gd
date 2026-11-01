class_name NightTwo
extends NightOne

## Night two, Monday 17 October 1988, from 22:30 to 06:00.
##
## 22:30  Kovpak hands over the post. With him is участковый Колесников, who
##        has come «to look at the new guard»; he smokes «Космос» in the hall,
##        talks to Gordeev and takes Nina's bag out of locker 31 as evidence,
##        with no record and no witnesses. Then both leave by the front.
## 22:50  the rows go dark.  23:05 the storage door: the killer is in.
## 23:30, 02:20, 04:20  rounds, as on night one.
## 00:40  the phone: the duty officer at the security desk says Пахомов, the
##        guard of the night of the 7th, was pulled out of Шарташ yesterday.
## 01:40  the killer leaves; on the floor by the storage door is the token of
##        locker 31, by the cellar door a fresh «Космос» end.
## 02:40  he is back.  03:20 the duty light and the booth lamp go out: he is
##        at the panel. Only the panel puts them back on.
## 03:40  the phone again: breathing.  05:10 he goes.
## 06:00  Вася Кран and Kovpak open up.
##
## Five clues: the bag taken without a record, Пахомов drowned, the token, the
## new padlock on the cellar door, the cigarette end. Chest A3 has been
## scrubbed clean since Friday.

const N2_HANDOVER := "Ковпак: — Принимай пост, Гордеев. И веди себя тихо: участковый пришёл на тебя посмотреть."
const N2_G_KOLES := "Участковый Колесников. Тот, что закрыл заявление про Нину за один день. Курит «Космос» прямо в зале, а Ковпак молчит."
const N2_KL_HELLO := "Колесников: — Так вот ты какой, Гордеев. Следователь в сторожах. Наслышан."
const N2_KL_BAG := "Колесников: — Сумочку Лукиной я у вас заберу. Вещдок, сам понимаешь."
const N2_CHOICE := "Колесников ждёт ответа."
const N2_ASK_PROTOCOL := "Спросить про протокол изъятия"
const N2_ASK_CASE := "Спросить, почему дело закрыли за день"
const N2_ASK_NONE := "Промолчать"
const N2_KL_PROTOCOL := "Колесников: — Протокол? Ты, Гордеев, теперь сторож. Протоколы не твоя забота."
const N2_G_PROTOCOL := "Ни протокола, ни понятых. Сумка Нины уходит с ним, и нигде это не записано."
const N2_KL_CASE := "Колесников: — Мать из Тагила звонила: дочка у неё. Дело закрыто, Гордеев. Не копай."
const N2_G_CASE := "Дочка у матери, а сумка с ключами и деньгами здесь. Не сходится. И он это знает."
const N2_G_SILENT := "Промолчал. Пусть думает, что старик ничего не понял."
const N2_G_TAKES := "Сам открыл тридцать первую, сам вынул сумку. Дорогу к ячейке не спрашивал."
const N2_KL_BYE := "Колесников: — Спокойной ночи, Гордеев. Не засыпай на посту."
const N2_K_LOCK := "Ковпак: — Запираю. До шести."
const N2_G_WALKS := "Колесников ушёл пешком, мимо «Волги». Опорный пункт в двух кварталах."
const N2_G_2245 := "Понедельник, двадцать два сорок пять. Магазин снова мой до шести. Только сумки Нины в нём больше нет."
const N2_G_0010 := "В пятницу я выучил: замолчал компрессор, значит, рядом кто-то стоит. Сегодня они молчат чаще."
const N2_G_PAPER := "У склада что-то блестит на полу."
const N2_G_BACK := "Опять дверь склада. Ключ у него свой, и он никуда не торопится."
const N2_G_DARK := "Погас дежурный свет над дверью и лампа на посту. Сами они не гаснут: это щиток."
const N2_G_0230 := "Половина третьего. Седьмого в это время на этом стуле сидел Пахомов. И что-то видел."
const N2_LIGHT_BACK := "Поднял рубильник дежурного света. Над дверью и на посту снова горит."
const N2_PANEL_DARK := "Рубильник дежурного света опущен до упора. Его не задели, его выключили."

const N2_PH_ANSWER := "— Пост охраны, «Кировский». Гордеев слушает."
const N2_PH_DISPATCH := "Дежурная: — Пульт вневедомственной, Сабурова. Гордеев? Пахомова, что до вас на «Кировском» сторожил, вчера из Шарташа выловили. Пьяный, говорят, утонул. Вы уж там не пейте."
const N2_PH_MISSED := "Не успел. Если это пульт, позвонят ещё."

const N2_CLUE_SEIZURE := "Сумку Нины забрал участковый. Без протокола, без понятых, без описи. Вещдок, который нигде не записан, уже не вещдок."
const N2_CLUE_PAHOMOV := "Пахомов дежурил в ночь на седьмое. Через день уволился, а теперь утонул. Кто-то убирает тех, кто видел."
const N2_CLUE_TOKEN := "Жетон тридцать первой ячейки, на шнурке. Нина носила его на шее. Шнурок не порван, его развязали. В пятницу его здесь не было."
## The same find when Tamara never told him where Nina kept the token.
const N2_CLUE_TOKEN_PLAIN := "Жетон тридцать первой ячейки, на шнурке. Шнурок не порван, его развязали. В пятницу его здесь не было."
const N2_CLUE_LOCK := "Дверь в подвал. Там сломанный холодильник, туда с августа никто не ходит. А замок новый, навесной, ещё в заводской смазке, и петли смазаны."
const N2_CLUE_BUTT := "Окурок «Космоса» у двери в подвал. Свежий, фильтр примят зубами. Вася курит «Беломор», Ковпак не курит. Вечером «Космос» курил участковый, но «Космос» курит полгорода."
const N2_FINAL := "Сумку Нины унёс участковый, без протокола. Сторож, который видел седьмое, утонул. Жетон с её шеи лежал у склада, на подвале новый замок, у двери свежий «Космос». Кто-то ходит сюда по ночам к тому, что спрятано внизу. У него есть ключи, и милиции он не боится."

const N2_A3 := "Третий ларь. Пельменей нет, иней соскоблен до металла, дно вымыто, пахнет хлоркой. После пятницы кто-то за собой убрал."
const N2_LOCKER_EMPTY := "Ячейка тридцать один пуста. Сумку Нины унёс Колесников."
const N2_LOCKER_BAG := "Сумка Нины. Колесников пришёл за ней."
const N2_REGISTER2 := "Касса № 2. Ленту сменили, старую забрал Ковпак. Хорошо, что я свою выписку сделал."
const N2_REGISTER2_LOST := "Касса № 2. Ленту сменили, старую забрал Ковпак. Что на ней было, теперь не узнать."
const N2_KL_LATER := "Колесников: — Потом, Гордеев. Сначала сумочка."
const N2_K_NOT_NOW := "Ковпак: — Не при нём, Гордеев. Иди на пост."
const N2_CELLAR_AGAIN := "Замок висит. Новый. Ключа у меня нет."
const N2_K_END_OK := "Ковпак: — Подписи на месте. Слыхал? Пахомов-то утонул. Пил много."
const N2_G_END := "Ковпак говорит про Пахомова, а смотрит в пол. Днём схожу к Ринату: седьмого он задерживался, мясо рубил."

var kolesnikov: Npc
## before, talk, gone
var koles_state := "before"
## "", "dispatch", "breath": what the ringing phone is
var _call := ""
var _calls_missed := 0
var _answer := -1
## What Gordeev brought from night one (clue keys) and day one (question ids).
var known: Dictionary = {}
var heard: Array = []


func _init(m: Node) -> void:
	super(m)
	clues = {"seizure": false, "pahomov": false, "token": false, "lock": false, "butt": false}
	known = Main.night_clues.duplicate()
	heard = Main.day_answers.duplicate()
	if known.is_empty():
		# Started from the title screen: as if nights one and day one were played through.
		known = {"bag": true, "clip": true, "tape": true, "page": true, "invoice": true}
		for q: Array in DayOne.QUESTIONS:
			heard.append(q[0])


func _ready() -> void:
	super()
	kolesnikov = _person("kolesnikov")
	main.store.add_cellar()
	# The seal on the storage door was found torn on Friday; no news tonight.
	_talked["torn"] = true
	main.store.add_interactable("talk_kolesnikov", Vector3.ZERO, "Заговорить с участковым", 1.7, false, false)


# --- timeline -----------------------------------------------------------------

func build_timeline() -> void:
	var m: Node = main
	var hud: Hud = main.hud
	var store: Store = main.store
	kovpak_state = "done"
	m.at(22, 30, _prologue)
	m.at(22, 45, func(): hud.say(N2_G_2245))
	for i in store.rows.size():
		var idx := i
		m.at(22, 50 + i * 3, func():
			store.switch_off(idx)
			hud.say(ROW_LINES[idx]))
	m.at(23, 5, func():
		_killer_in()
		hud.say(G_DOOR, -1.0, true))
	m.at(0, 10, func(): hud.say(N2_G_0010))
	for i in rounds.size():
		var idx := i
		var r: Dictionary = rounds[i]
		m.at_min(r.start, func(): _round_start(idx))
	m.at(0, 40, func(): _ring("dispatch"))
	m.at(1, 40, func(): _killer_leave())
	m.at(1, 44, _floor_finds)
	m.at(2, 30, func(): hud.say(N2_G_0230))
	m.at(2, 40, _killer_return)
	m.at(3, 20, _duty_out)
	m.at(3, 40, func(): _ring("breath"))
	m.at(4, 0, func(): hud.say(G_0400))
	m.at(5, 10, func(): _killer_leave())
	m.at(5, 30, func(): hud.say(G_0530))
	m.at(6, 0, _morning)


# --- the prologue: Kovpak and the участковый ------------------------------------

func _prologue() -> void:
	var hud: Hud = main.hud
	var store: Store = main.store
	koles_state = "talk"
	store.car_park()
	kovpak.visible = true
	kovpak.global_position = Vector3(6.3, 0, 2.7)
	kovpak.look_at_point(main.player.global_position)
	kolesnikov.visible = true
	kolesnikov.global_position = Vector3(2.4, 0, 2.6)
	kolesnikov.look_at_point(main.player.global_position)
	hud.say(N2_HANDOVER)
	hud.say(K_ROUNDS)
	hud.say(N2_G_KOLES)
	await _wait_min(2.0)
	kolesnikov.walk(PackedVector3Array([Vector3(4.4, 0, 4.2), Vector3(6.1, 0, 4.0)]))
	await kolesnikov.arrived
	kolesnikov.look_at_point(main.player.global_position)
	hud.say(N2_KL_HELLO, -1.0, true)
	hud.say(N2_KL_BAG)
	await _wait_min(1.5)
	if main.phase != Main.Phase.PLAY:
		return
	var options: Array[String] = [N2_ASK_PROTOCOL, N2_ASK_CASE, N2_ASK_NONE]
	_answer = await hud.choose(N2_CHOICE, options)
	match _answer:
		0:
			hud.say(N2_KL_PROTOCOL, -1.0, true)
			hud.say(N2_G_PROTOCOL)
		1:
			hud.say(N2_KL_CASE, -1.0, true)
			hud.say(N2_G_CASE)
		_:
			hud.say(N2_G_SILENT, -1.0, true)
	await _wait_min(1.0)
	# Straight to locker 31: he knows which one.
	kolesnikov.walk(PackedVector3Array([Vector3(0, 0, 3.4), Vector3(-5.0, 0, 1.8), Vector3(-7.75, 0, 1.2)]))
	await kolesnikov.arrived
	kolesnikov.look_at_point(Vector3(-7.75, 0, 0))
	await get_tree().create_timer(1.5).timeout
	Sfx.play_3d(store, "clank", Vector3(-7.75, 0.7, 0.6), -6.0, 1.5)
	store.empty_locker31()
	kolesnikov.body.bag = kolesnikov.body.attach("Bip01 L Hand", Characters.handbag(Color(0.45, 0.2, 0.18)))
	_find_clue("seizure", N2_CLUE_SEIZURE)
	hud.say(N2_G_TAKES)
	await get_tree().create_timer(2.0).timeout
	kolesnikov.walk(PackedVector3Array([Vector3(-3.0, 0, 1.8), Vector3(-0.6, 0, 1.4)]))
	kovpak.walk(PackedVector3Array([Vector3(4.25, 0, 4.0), Vector3(0.4, 0, 2.6)]))
	await kolesnikov.arrived
	kolesnikov.look_at_point(main.player.global_position)
	hud.say(N2_KL_BYE)
	hud.say(N2_K_LOCK)
	store.set_front_door(true)
	await get_tree().create_timer(2.2).timeout
	kolesnikov.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0), Vector3(-6.0, 0, -6.5)]))
	await get_tree().create_timer(1.2).timeout
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0)]))
	await kovpak.arrived
	store.set_front_door(false)
	kovpak.look_at_point(Vector3(-1, 0, 2))
	await get_tree().create_timer(3.0).timeout
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, -6.5)]))
	await kovpak.arrived
	kovpak.visible = false
	kolesnikov.visible = false
	koles_state = "gone"
	store.car_start()
	hud.say(N2_G_WALKS)
	await get_tree().create_timer(2.5).timeout
	store.car_leave()
	hud.say(G_LOCKED)


## Waits `dm` minutes of game time.
func _wait_min(dm: float) -> void:
	var until: float = main.minutes + dm
	while main.minutes < until and main.phase == Main.Phase.PLAY:
		await get_tree().process_frame


func _process(_delta: float) -> void:
	var store: Store = main.store
	var free := kolesnikov.visible and not kolesnikov.walking and koles_state == "talk"
	store.set_interactable("talk_kolesnikov", free)
	store.move_interactable("talk_kolesnikov", kolesnikov.global_position)
	store.set_interactable("talk_kovpak", kovpak.visible and not kovpak.walking and koles_state == "talk", "Заговорить с Ковпаком")
	store.move_interactable("talk_kovpak", kovpak.global_position)
	store.set_interactable("talk_tamara", false)


# --- the killer -----------------------------------------------------------------

func _killer_return() -> void:
	if killer_phase != "out":
		return
	_killer_in()
	main.hud.say(N2_G_BACK, -1.0, true)


func _floor_finds() -> void:
	if killer_phase == "in":
		main.after(3.0, _floor_finds)
		return
	main.store.show_floor_finds()
	main.hud.say(N2_G_PAPER)


func _duty_out() -> void:
	if not main.killer.is_active():
		main.after(5.0, _duty_out)
		return
	main.store.set_duty(false)
	main.hud.say(N2_G_DARK, -1.0, true)


# --- the phone --------------------------------------------------------------------

func _ring(kind: String) -> void:
	_call = kind
	_ring_phone()


func update(delta: float) -> void:
	var was := _phone_t
	super(delta)
	if was > 0.0 and _phone_t <= 0.0 and _call == "dispatch":
		_calls_missed += 1
		if _calls_missed == 1:
			main.hud.say(N2_PH_MISSED)
			main.after(15.0, func(): _ring("dispatch"))
	if _phone_t <= 0.0 and was > 0.0:
		_call = ""


func _answer_phone() -> void:
	if _call != "dispatch":
		super()
		return
	var hud: Hud = main.hud
	_call = ""
	_phone_t = 0.0
	_phone.stop()
	main.store.set_interactable("phone", false)
	main.player.busy = true
	Sfx.play_3d(main.view, "pickup", main.store.phone_pos, -4.0)
	hud.say(N2_PH_ANSWER, 2.5, true)
	hud.say(N2_PH_DISPATCH)
	await get_tree().create_timer(3.0).timeout
	main.player.busy = false
	_find_clue("pahomov", N2_CLUE_PAHOMOV)


# --- interactions -----------------------------------------------------------------

func interact(id: String) -> bool:
	var hud: Hud = main.hud
	var store: Store = main.store
	match id:
		"locker31":
			if koles_state == "gone" or clues.seizure:
				hud.say(N2_LOCKER_EMPTY, -1.0, true)
			else:
				hud.say(N2_LOCKER_BAG, -1.0, true)
		"register2":
			hud.say(N2_REGISTER2 if known.get("tape", false) else N2_REGISTER2_LOST, -1.0, true)
		"talk_kolesnikov":
			kolesnikov.look_at_point(main.player.global_position)
			hud.say(N2_KL_LATER, -1.0, true)
		"talk_kovpak":
			kovpak.look_at_point(main.player.global_position)
			hud.say(N2_K_NOT_NOW, -1.0, true)
		"cellar":
			if clues.lock:
				hud.say(N2_CELLAR_AGAIN, -1.0, true)
			else:
				Sfx.play_3d(main.view, "keys", main.player.global_position + Vector3(0, 1, 0), -10.0, 1.3)
				_find_clue("lock", N2_CLUE_LOCK)
		"token":
			Sfx.play_3d(main.view, "pickup", main.player.global_position, -6.0)
			store.take_token()
			_find_clue("token", N2_CLUE_TOKEN if "bag" in heard else N2_CLUE_TOKEN_PLAIN)
		"butt":
			Sfx.play_3d(main.view, "pickup", main.player.global_position, -10.0)
			store.take_butt()
			_find_clue("butt", N2_CLUE_BUTT)
		"panel":
			if store.duty_on:
				return super(id)
			hud.say(N2_PANEL_DARK, -1.0, true)
			store.set_duty(true)
			hud.say(N2_LIGHT_BACK)
			var r := current_round()
			if r >= 0:
				rounds[r].panel = true
				update_notebook()
		_:
			return super(id)
	return true


func _lift(chest: String) -> void:
	var store: Store = main.store
	var c: Dictionary = store.chests[chest]
	if c.lifted:
		main.hud.say("Этот ларь я уже смотрел.", -1.0, true)
		return
	main.player.busy = true
	Sfx.play_3d(main.view, "cloth", c.pos + Vector3(0, 0.8, 0), 0.0)
	main.on_noise(c.pos, 8.0)
	await get_tree().create_timer(1.3).timeout
	if main.phase != Main.Phase.PLAY:
		return
	store.lift_cloth(chest)
	main.player.busy = false
	main.hud.say(N2_A3 if chest == Store.CLUE_CHEST else CHEST_TEXT[chest], -1.0, true)


func final_entry() -> String:
	return N2_FINAL


func update_notebook() -> void:
	var lines := PackedStringArray([
		"БЛОКНОТ ГОРДЕЕВА", "Ночь вторая, 17 октября 1988, понедельник", ""])
	var r := current_round()
	lines.append("Обходы (дверь склада, щиток, подпись в журнале):")
	var names := ["23:30", "02:20", "04:20"]
	for i in rounds.size():
		var rd: Dictionary = rounds[i]
		var mark := "[x]" if rd.signed else ("[  ]" if i >= r else "[–]")
		var detail := ""
		if i == r and not rd.signed:
			detail = "  склад %s, щиток %s" % ["да" if rd.door else "нет", "да" if rd.panel else "нет"]
		lines.append("%s %s%s" % [mark, names[i], detail])
	lines.append("")
	var past := _past_notes()
	if not past.is_empty():
		lines.append("Из пятницы и субботы: " + " ".join(past))
		lines.append("")
	lines.append("Улики: %d из 5" % clue_count())
	if clues.seizure:
		lines.append("— Колесников забрал сумку Нины без протокола и понятых.")
	if clues.pahomov:
		lines.append("— Пахомов, сторож с ночи 7-го, «утонул пьяный» в Шарташе.")
	if clues.token:
		lines.append("— Жетон № 31 со шнурком у двери склада. Шнурок развязан, не порван.")
	if clues.lock:
		lines.append("— На подвале новый навесной замок, петли смазаны.")
	if clues.butt:
		lines.append("— Свежий окурок «Космоса» у двери в подвал.")
	if not clues.values().has(false):
		lines.append("")
		lines.append(N2_FINAL)
	lines.append("")
	lines.append("Подозреваемые: Ковпак (директор), Вася Кран (грузчик), Ринат (мясник), Колесников (участковый), Эдик (фарцовщик), Тамара Ивановна (кассир).")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


## What night one and Tamara's statements left in the notebook: only what
## Gordeev actually found and asked about.
func _past_notes() -> PackedStringArray:
	var out := PackedStringArray()
	if known.get("bag", false):
		out.append("Сумка Нины пролежала в 31-й с ключами и деньгами.")
	if "evening" in heard:
		out.append("7-го Нина осталась в магазине после десяти.")
	if known.get("tape", false):
		out.append("Чек в 22:58 пробила сама Нина." if "tape" in heard else "7-го в 22:58 на второй кассе пробит чек, магазин был закрыт.")
	if known.get("clip", false):
		out.append("В третьем ларе была её заколка.")
	if known.get("invoice", false):
		out.append("Нина узнала про мясо Ковпака и Рината и шла в ОБХСС." if "invoice" in heard else "Ковпак вывозит говядину «без реализации», пометка «Р.».")
	if "page" in heard:
		out.append("Сторожа с ночи 7-го вызывал к себе Колесников.")
	elif known.get("page", false):
		out.append("Страница журнала за 7-е вырвана.")
	if "bag" in heard:
		out.append("Жетон № 31 Нина носила на шее, при сумке его не было.")
	if "who" in heard:
		out.append("7-го вечером в магазине были Вася Кран, Ринат и Эдик.")
	return out


# --- morning --------------------------------------------------------------------

func _morning() -> void:
	var store: Store = main.store
	var hud: Hud = main.hud
	main.begin_morning()
	if main.killer.is_active():
		main.killer.deactivate()
		main.killer.visible = false
	store.close_storage_door()
	if not store.duty_on:
		store.set_duty(true, true)
	store.car_arrive()
	await get_tree().create_timer(5.0).timeout
	for i in 3:
		Sfx.play_3d(store, "knock", Vector3(0.6, 1.4, -0.1), -2.0, randf_range(0.95, 1.05))
		await get_tree().create_timer(0.45).timeout
	vasya.visible = true
	vasya.global_position = Vector3(-0.2, 0, -2.0)
	vasya.look_at_point(Vector3(0, 0, 3))
	kovpak.visible = true
	kovpak.global_position = Vector3(-1.6, 0, -5.0)
	hud.say(V_MORNING, -1.0, true)
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, -1.2)]))
	await kovpak.arrived
	store.set_front_door(true)
	await get_tree().create_timer(2.0).timeout
	vasya.walk(PackedVector3Array([Vector3(-0.8, 0, 0.6), Vector3(0.6, 0, 2.6), Vector3(2.0, 0, 5.0)]))
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.6), Vector3(-0.6, 0, 2.0)]))
	await get_tree().create_timer(1.5).timeout
	store.switch_on(5)
	await kovpak.arrived
	kovpak.look_at_point(main.player.global_position)
	hud.say(N2_K_END_OK if rounds_signed() == rounds.size() else K_END_BAD)
	hud.say(N2_G_END)
	await get_tree().create_timer(14.0).timeout
	main.end_shift()


func summary() -> String:
	var n := clue_count()
	var text := N2_FINAL if n == clues.size() else "Сумки Нины в универсаме больше нет. А то, что ещё есть, кто-то прячет внизу."
	return "Улик найдено: %d из %d. Обходов подписано: %d из %d.\n\n%s" % [n, clues.size(), rounds_signed(), rounds.size(), text]


# --- saving at the journal ------------------------------------------------------

func save_state() -> Dictionary:
	var d := super()
	d["koles_state"] = koles_state
	d["duty_on"] = main.store.duty_on
	d["calls_missed"] = _calls_missed
	return d


func restore_state(d: Dictionary) -> void:
	var store: Store = main.store
	koles_state = "gone"
	_calls_missed = d.get("calls_missed", 0)
	super(d)
	kovpak_state = "done"
	store.empty_locker31()
	if not d.get("duty_on", true):
		store.set_duty(false, true)
	if main.minutes >= Main.clock(1, 44) and killer_phase != "before":
		store.show_floor_finds()
		if clues.token:
			store.take_token()
		if clues.butt:
			store.take_butt()
	if not clues.pahomov and _calls_missed < 2 and main.minutes > Main.clock(0, 40):
		main.after(3.0, func(): _ring("dispatch"))
	update_notebook()
