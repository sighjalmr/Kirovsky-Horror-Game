class_name NightOne
extends Node

## Night one, Friday 14 October 1988, from 22:30 to 06:00.
##
## 22:30  Kovpak hands over the post, Tamara Ivanovna leaves; they lock the
##        doors from outside and the «Волга» drives off.
## 22:50  the rows go dark one by one.
## 23:10  the storage door: the killer is in.
## 23:30  first round: storage door, fuse panel, signature in the journal.
## 00:40  the phone at the post.
## 01:10  бакалея lights up for a second: somebody is at the panel.
## 01:40  the killer leaves; 01:50 Kovpak comes back at night, goes into the
##        storage room with his own key and carries out a heavy carton.
## 02:20  second round.  02:40 the killer is back.  03:15 cans fall.
## 04:20  third round.  05:10 the killer goes for good.
## 06:00  Kovpak and the loader Вася Кран open up. The shift ends.
##
## Five clues: Nina's bag (locker 31), her hair clip (chest A3), the till
## roll (касса № 2), the torn-out journal page, Kovpak's delivery note.
## Signing a round saves the shift: after death it resumes from there.

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
const CLUE_PAGE := "Журнал обходов. Страницы за седьмое октября нет, её вырвали аккуратно, по линейке. Сторож, что дежурил в ту ночь, через день уволился."
const CLUE_INVOICE := "Накладная, выпала из его коробки. Говядина, сорок килограммов, седьмое октября, «без реализации». Внизу подпись Ковпака и карандашом: «Р.»."
const FINAL_ENTRY := "Нина не уезжала. Седьмого в 22:58 кто-то пробил чек на второй кассе в закрытом магазине, потом её тащили к третьему ларю, а страницу журнала за ту ночь вырвали. Это свой. У него есть ключи."

# Prologue at the post.
const K_HANDOVER := "Ковпак: — Гордеев, принимай пост. Зал твой, склад не твой: он опечатан, ключ у меня."
const K_CHESTS := "Ковпак: — Лари не трогай. Покрывала по инструкции, санэпидстанция штрафует."
const K_ROUNDS := "Ковпак: — Обход каждые два часа, подпись в журнале. И без самодеятельности. Ты теперь сторож, а не следователь."
const G_KOVPAK := "Директор Ковпак. Оклад сто сорок рублей, а ездит на «Волге». Нина работала у него три года."
const T_BYE := "Тамара Ивановна: — Касса сдана. Я пошла. Спокойной вам ночи."
const G_TAMARA := "Тамара Ивановна. Последней видела Нину живой. С тех пор не смотрит мне в глаза."
const K_ASK := "Ковпак: — Лукина уволилась по собственному. Заявление у меня в столе. Всё, Гордеев, мне ехать."
const G_ASK := "Заявления этого никто не видел. Даже отдел кадров."
const K_BUSY := "Ковпак: — Иди работай, Гордеев."
const T_ASK := "Тамара Ивановна: — Я в десять кассу сдала и ушла. Ничего я не знаю. Пустите, автобус уйдёт."
const K_LOCK := "Ковпак: — Запираю снаружи. До шести."
const G_LOCKED := "Запер снаружи. Теперь до шести я тут один. По крайней мере, так считается."
# The night.
const G_2245 := "Двадцать два сорок пять. Касса сдана, директор Ковпак уехал на своей «Волге». Магазин мой до шести утра."
const G_LIGHT := "Свет гасят рядами, начиная с бакалеи. Директор говорит, экономия. В восемьдесят восьмом всё экономия."
const G_NINA := "Нина Лукина ушла со смены седьмого. В милиции сказали: уехала к матери. А её сумка до сих пор в камере хранения, ячейка тридцать один."
const ROW_LINES := ["Бакалея.", "Консервы.", "Молочный.", "Заморозка. Лари под покрывалами, как под простынями.", "Задний проход.",
	"Касса и вход. Остался дежурный свет над дверью и лампа на посту."]
const G_DOOR := "Хлопнула дверь склада. Ключи от неё есть у троих, и я не из них."
const G_COMPRESSORS := "Компрессоры ларей гудят всю ночь. Если какой-то замолчал, значит, рядом кто-то стоит."
const G_FLICKER := "Бакалея мигнула. Сама она не включается: рубильник на щитке в заднем проходе."
const G_LEFT_1 := "Хлопнула дверь склада. Ушёл? Или просто закрылся изнутри."
const G_HEADLIGHTS := "Фары за стеклом. В два часа ночи к универсаму подъезжает «Волга»."
const K_NIGHT := "Ковпак: — Не спишь, Гордеев? Правильно. Я на минуту, бумаги забыл. Сиди на посту."
const K_NIGHT_ASK := "Ковпак: — Сказал же, сиди на посту. Не твоё дело, Гордеев."
const G_TO_STORAGE := "Пошёл прямо на склад. Ключ у него свой, свет не включает, дорогу знает наизусть."
const G_BOX := "Коробка тяжёлая, несёт двумя руками. Бумаги так не носят."
const K_NOT_HERE := "Ковпак: — Гордеев. Меня здесь не было. В журнал не пиши. Понял?"
const G_PAPER := "У двери склада что-то белеет на полу."
const G_0230 := "Половина третьего. Ковпак на прошлой неделе тоже задерживался допоздна. Говорил, ревизия."
const G_BACK := "Опять дверь склада. Ковпак уехал. Значит, это не он. Или не только он."
const G_CANS := "В консервах что-то загремело. Банки сами с пирамиды не прыгают."
const G_0400 := "Четыре. Самое глухое время. Даже трамваи на Сиреневом не ходят."
const G_LEFT_2 := "Дверь склада закрылась. Ушёл тем же путём, что пришёл. До грузчиков меньше часа."
const G_0530 := "Полшестого. Скоро придут грузчики."
# Rounds.
const R_START := ["Половина двенадцатого. Обход: дверь склада, электрощиток в заднем проходе, потом подпись в журнале.",
	"Второй обход. Дверь склада, щиток, журнал. Ковпак утром проверит подписи.",
	"Третий обход, последний. Склад, щиток, журнал."]
const R_MISSED := "Обход я пропустил. Ковпак это заметит."
const R_SEALED := "Дверь склада заперта. На пломбе печать универсама."
const R_TORN := "Дверь склада открыта настежь. Пломба сорвана, нитка висит. А Ковпак говорил, опечатано."
const R_OPEN := "Дверь склада открыта. Из темноты тянет холодом холодильной камеры."
const R_SHUT := "Дверь склада заперта изнутри. Кто-то закрыл её за собой."
const R_PANEL := "Электрощиток. Шесть рубильников, подписаны рукой Ковпака. Все опущены, как положено."
const R_PANEL_WARM := "Рубильник бакалеи опущен, но ручка тёплая. Её держали минуту назад."
const R_PANEL_AGAIN := "Щиток. Всё опущено."
const R_SIGNED := "Расписался: обход проведён, замечаний нет. Замечания я пишу в блокнот."
const R_NEED := "Расписываться рано. Сначала дверь склада и щиток."
const R_DONE := "Обход записан. До следующего ещё есть время."
const R_NOT_YET := "Первый обход в половине двенадцатого. Журнал подождёт."
const R_NOT_NOW := "Потом распишусь. Пусть сначала уедет."
const R_CHASED := "Не до журнала."
const G_SIT := "Посижу. Ноги уже не те."
# The phone.
const PH_RING := "Звонит телефон на посту. В час ночи сюда не звонят."
const PH_STOP := "Перестал звонить."
const PH_ANSWER := "— Пост охраны, Гордеев. Слушаю."
const PH_BREATH := "В трубке молчат. Потом кто-то дышит, ровно, никуда не торопясь."
const PH_HANGUP := "Короткие гудки. Где-то в зале скрипнула тележка."
# Morning.
const V_MORNING := "Вася Кран: — Открывай, служба! Живой, дед?"
const K_END_OK := "Ковпак: — Подписи на месте. Свободен, Гордеев. До понедельника."
const K_END_BAD := "Ковпак: — Обходы пропущены. Ещё раз, Гордеев, и пойдёшь сторожить овощебазу."
const G_END := "Ковпак смотрит не на меня, а на дверь склада. Днём поговорю с Тамарой Ивановной. Она знает больше, чем сказала."

## Where the cans fall, by the pyramid of peas in консервы.
const CANS_POS := Vector3(1.6, 0, 19.0)

var main: Node
var clues := {"bag": false, "clip": false, "tape": false, "page": false, "invoice": false}
var rounds: Array = []
## before, in (inside the store), out (left, coming back), gone (left for good)
var killer_phase := "before"
## prologue, none (not yet back), visit, done
var kovpak_state := "prologue"
var panel_warm := false

var kovpak: Npc
var tamara: Npc
var vasya: Npc

var _phone: AudioStreamPlayer3D
var _phone_t := 0.0
var _phone_noise_t := 0.0
var _talked := {}


func _init(m: Node) -> void:
	main = m
	for t: Array in [[23, 30], [2, 20], [4, 20]]:
		rounds.append({"start": Main.clock(t[0], t[1]), "signed": false, "door": false, "panel": false})


func _ready() -> void:
	_phone = AudioStreamPlayer3D.new()
	_phone.stream = Sfx.get_stream("phone")
	_phone.bus = Sfx.BUS
	_phone.max_distance = 40.0
	_phone.unit_size = 8.0
	main.world.add_child(_phone)
	_phone.global_position = main.store.phone_pos
	kovpak = _person("kovpak")
	tamara = _person("tamara")
	vasya = _person("vasya")
	main.store.add_interactable("talk_kovpak", Vector3.ZERO, "Спросить про Нину", 1.6, false, false)
	main.store.add_interactable("talk_tamara", Vector3.ZERO, "Спросить про седьмое октября", 1.6, false, false)


func _person(role: String) -> Npc:
	var n := Npc.new().setup(role)
	main.world.add_child(n)
	n.visible = false
	n.global_position = main.store.street
	return n


# --- timeline -----------------------------------------------------------------

func build_timeline() -> void:
	var m: Node = main
	var hud: Hud = main.hud
	var store: Store = main.store
	m.at(22, 30, _prologue)
	m.at(22, 45, func(): hud.say(G_2245))
	m.at(22, 46, func():
		hud.say(G_LIGHT)
		hud.say(G_NINA))
	for i in store.rows.size():
		var idx := i
		m.at(22, 50 + i * 3, func():
			store.switch_off(idx)
			hud.say(ROW_LINES[idx]))
	m.at(23, 10, func():
		_killer_in()
		hud.say(G_DOOR, -1.0, true))
	m.at(23, 14, func(): hud.say(G_COMPRESSORS))
	for i in rounds.size():
		var idx := i
		var r: Dictionary = rounds[i]
		m.at_min(r.start, func(): _round_start(idx))
	m.at(0, 40, _ring_phone)
	m.at(1, 10, func():
		store.flicker(0)
		panel_warm = true
		hud.say(G_FLICKER, -1.0, true))
	m.at(1, 40, func(): _killer_leave())
	m.at(1, 50, _kovpak_visit)
	m.at(2, 30, func(): hud.say(G_0230))
	m.at(2, 40, _killer_return)
	m.at(3, 12, func():
		if main.killer.is_active():
			main.killer.wander_to(CANS_POS))
	m.at(3, 15, func():
		Sfx.play_3d(store, "cans", CANS_POS + Vector3(0, 0.3, 1.0), 0.0)
		hud.say(G_CANS, -1.0, true))
	m.at(4, 0, func(): hud.say(G_0400))
	m.at(5, 10, func(): _killer_leave())
	m.at(5, 30, func(): hud.say(G_0530))
	m.at(6, 0, _morning)


func current_round() -> int:
	var cur := -1
	for i in rounds.size():
		if main.minutes >= rounds[i].start:
			cur = i
	return cur


func _round_start(i: int) -> void:
	if i > 0 and not rounds[i - 1].signed:
		main.hud.say(R_MISSED)
	main.hud.say(R_START[i])
	update_notebook()


# --- the prologue ---------------------------------------------------------------

func _prologue() -> void:
	var hud: Hud = main.hud
	var store: Store = main.store
	kovpak_state = "prologue"
	store.car_park()
	kovpak.visible = true
	kovpak.global_position = Vector3(6.3, 0, 2.7)
	kovpak.look_at_point(main.player.global_position)
	tamara.visible = true
	tamara.global_position = Vector3(-0.6, 0, 9.4)
	tamara.rotation.y = PI * 0.5
	hud.say(K_HANDOVER)
	hud.say(K_CHESTS)
	hud.say(K_ROUNDS)
	hud.say(G_KOVPAK)
	main.at(22, 34, func():
		_talked["tamara_walk"] = true
		tamara.walk(PackedVector3Array([Vector3(0, 0, 8.25), Vector3(-0.3, 0, 4.5), Vector3(-1.4, 0, 1.4)]))
		await tamara.arrived
		tamara.look_at_point(main.player.global_position)
		hud.say(T_BYE)
		hud.say(G_TAMARA))
	main.at(22, 37, func():
		_talked["kovpak_walk"] = true
		hud.say(K_LOCK)
		kovpak.walk(PackedVector3Array([Vector3(4.25, 0, 4.0), Vector3(0, 0, 3.0), Vector3(-0.6, 0, 1.2)]))
		await kovpak.arrived
		store.set_front_door(true)
		await get_tree().create_timer(2.2).timeout
		tamara.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0), Vector3(-3.0, 0, -6.0)]))
		await get_tree().create_timer(1.2).timeout
		kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0)]))
		await kovpak.arrived
		store.set_front_door(false)
		kovpak.look_at_point(Vector3(-1, 0, 2))
		await get_tree().create_timer(3.0).timeout
		kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, -6.5)]))
		await kovpak.arrived
		kovpak.visible = false
		tamara.visible = false
		kovpak_state = "none"
		store.car_start()
		await get_tree().create_timer(2.5).timeout
		store.car_leave()
		hud.say(G_LOCKED))


## The people of the prologue and the night visit can be spoken to.
func _process(_delta: float) -> void:
	var store: Store = main.store
	var k_free := kovpak.visible and not kovpak.walking and not _talked.has("kovpak_walk") and kovpak_state == "prologue"
	store.set_interactable("talk_kovpak", k_free or (kovpak_state == "visit" and kovpak.visible),
		"Спросить про Нину" if kovpak_state == "prologue" else "Заговорить с Ковпаком")
	store.move_interactable("talk_kovpak", kovpak.global_position)
	store.set_interactable("talk_tamara", tamara.visible and not tamara.walking and not _talked.has("tamara_walk"))
	store.move_interactable("talk_tamara", tamara.global_position)


# --- the killer's comings and goings -------------------------------------------

func _killer_in() -> void:
	main.store.open_storage_door()
	main.killer.activate(main.store.killer_spawn)
	killer_phase = "in"


func _killer_leave() -> void:
	if not main.killer.is_active():
		return
	main.killer.leave()
	await main.killer.left
	main.store.close_storage_door()
	var final: bool = main.minutes > Main.clock(4, 0)
	killer_phase = "gone" if final else "out"
	main.hud.say(G_LEFT_2 if final else G_LEFT_1, -1.0, true)


func _killer_return() -> void:
	if kovpak_state != "done" or killer_phase != "out":
		if killer_phase == "out":
			main.after(4.0, _killer_return)
		return
	_killer_in()
	main.hud.say(G_BACK, -1.0, true)


# --- Kovpak at two in the morning ------------------------------------------------

func _kovpak_visit() -> void:
	var store: Store = main.store
	var hud: Hud = main.hud
	if killer_phase == "in":
		main.after(4.0, _kovpak_visit)
		return
	kovpak_state = "visit"
	store.car_arrive()
	hud.say(G_HEADLIGHTS, -1.0, true)
	await get_tree().create_timer(6.0).timeout
	kovpak.visible = true
	kovpak.global_position = Vector3(-1.2, 0, -6.5)
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, -1.2)]))
	await kovpak.arrived
	store.set_front_door(true)
	await get_tree().create_timer(2.0).timeout
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.6), Vector3(-0.2, 0, 2.2)]))
	await kovpak.arrived
	store.set_front_door(false)
	kovpak.look_at_point(main.player.global_position)
	hud.say(K_NIGHT, -1.0, true)
	await get_tree().create_timer(5.5).timeout
	hud.say(G_TO_STORAGE)
	kovpak.walk(store.route(kovpak.global_position, store.killer_spawn))
	await kovpak.arrived
	Sfx.play_3d(store, "keys", store.killer_spawn + Vector3(0, 1, 0), -6.0)
	await get_tree().create_timer(1.0).timeout
	store.open_storage_door()
	await get_tree().create_timer(1.2).timeout
	kovpak.walk(PackedVector3Array([store.storage_inside]))
	await kovpak.arrived
	kovpak.visible = false
	# Boxes shifted about in the dark storage room.
	for k in 5:
		await get_tree().create_timer(randf_range(5.0, 9.0)).timeout
		Sfx.play_3d(store, ["clank", "cloth", "pickup", "keys", "cloth"][k], store.storage_inside + Vector3(randf_range(-2, 2), 1, 1),
			-10.0, randf_range(0.7, 0.9))
	kovpak.visible = true
	kovpak.carry(true)
	kovpak.speed = 1.0
	kovpak.walk(PackedVector3Array([store.killer_spawn]))
	await kovpak.arrived
	store.close_storage_door()
	hud.say(G_BOX)
	kovpak.walk(store.route(kovpak.global_position, Vector3(-0.4, 0, 1.6)))
	await kovpak.arrived
	kovpak.look_at_point(main.player.global_position)
	hud.say(K_NOT_HERE, -1.0, true)
	await get_tree().create_timer(5.0).timeout
	store.set_front_door(true)
	await get_tree().create_timer(2.0).timeout
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0)]))
	await kovpak.arrived
	store.set_front_door(false)
	kovpak.walk(PackedVector3Array([Vector3(-1.2, 0, -6.5)]))
	await kovpak.arrived
	kovpak.visible = false
	kovpak.carry(false)
	kovpak.speed = 1.25
	store.car_leave()
	store.show_invoice()
	kovpak_state = "done"
	await get_tree().create_timer(3.0).timeout
	hud.say(G_PAPER)


# --- interactions -----------------------------------------------------------------

## Returns true when it handled `id`.
func interact(id: String) -> bool:
	var hud: Hud = main.hud
	var store: Store = main.store
	match id:
		"locker31":
			if clues.bag:
				hud.say("Сумка Нины. Я оставил всё как было.", -1.0, true)
			else:
				Sfx.play_3d(main.view, "clank", main.player.global_position + Vector3(0, 1, 0), -10.0, 1.6)
				_find_clue("bag", CLUE_BAG)
		"register2":
			if clues.tape:
				hud.say("Лента на месте. 22:58.", -1.0, true)
			else:
				Sfx.play_3d(main.view, "pickup", main.player.global_position, -6.0)
				_find_clue("tape", CLUE_TAPE)
		"register1":
			hud.say("Касса № 1. Лента чистая, смену закрыли вовремя.", -1.0, true)
		"register3":
			hud.say("Касса № 3. Не работает с августа. Под ней окурки «Беломора».", -1.0, true)
		"journal":
			_journal()
		"door_front":
			hud.say("Заперто снаружи до шести. Так положено. За стеклом дождь и пустой Сиреневый бульвар.", -1.0, true)
		"phone":
			_answer_phone()
		"storage_door":
			var r := current_round()
			if not store.storage_open:
				hud.say(R_SHUT if killer_phase in ["out", "gone"] else R_SEALED, -1.0, true)
			elif not _talked.has("torn"):
				_talked["torn"] = true
				hud.say(R_TORN, -1.0, true)
			else:
				hud.say(R_OPEN, -1.0, true)
			if r >= 0:
				rounds[r].door = true
				update_notebook()
		"panel":
			var r := current_round()
			Sfx.play_3d(store, "pickup", Vector3(-0.5, 1.2, 27.8), -10.0, 0.7)
			if panel_warm:
				panel_warm = false
				hud.say(R_PANEL_WARM, -1.0, true)
			elif not _talked.has("panel"):
				_talked["panel"] = true
				hud.say(R_PANEL, -1.0, true)
			else:
				hud.say(R_PANEL_AGAIN, -1.0, true)
			if r >= 0:
				rounds[r].panel = true
				update_notebook()
		"invoice":
			Sfx.play_3d(main.view, "pickup", main.player.global_position, -6.0)
			store.hide_invoice()
			_find_clue("invoice", CLUE_INVOICE)
		"talk_kovpak":
			if kovpak_state == "visit":
				hud.say(K_NIGHT_ASK, -1.0, true)
			elif not _talked.has("kovpak"):
				_talked["kovpak"] = true
				kovpak.look_at_point(main.player.global_position)
				hud.say(K_ASK, -1.0, true)
				hud.say(G_ASK)
			else:
				hud.say(K_BUSY, -1.0, true)
		"talk_tamara":
			if not _talked.has("tamara"):
				_talked["tamara"] = true
				tamara.look_at_point(main.player.global_position)
				hud.say(T_ASK, -1.0, true)
		"chair":
			main.sit_down()
			hud.say(G_SIT, -1.0, true)
		_:
			if id.begins_with("chest_"):
				_lift(id.trim_prefix("chest_"))
			else:
				return false
	return true


func _journal() -> void:
	var hud: Hud = main.hud
	Sfx.play_3d(main.view, "pickup", main.player.global_position, -8.0)
	if not clues.page:
		_find_clue("page", CLUE_PAGE)
		return
	var r := current_round()
	if r < 0:
		hud.say(R_NOT_YET, -1.0, true)
	elif rounds[r].signed:
		hud.say(R_DONE, -1.0, true)
	elif kovpak_state == "visit":
		hud.say(R_NOT_NOW, -1.0, true)
	elif main.chasing:
		hud.say(R_CHASED, -1.0, true)
	elif not (rounds[r].door and rounds[r].panel):
		hud.say(R_NEED, -1.0, true)
	else:
		rounds[r].signed = true
		hud.say(R_SIGNED, -1.0, true)
		update_notebook()
		main.save_checkpoint()


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
	if chest == Store.CLUE_CHEST:
		Sfx.play_2d(self, "stinger", -10.0)
		_find_clue("clip", CLUE_CLIP)
	else:
		main.hud.say(CHEST_TEXT[chest], -1.0, true)


func _find_clue(key: String, text: String) -> void:
	clues[key] = true
	main.hud.say(text, -1.0, true)
	if not clues.values().has(false):
		main.hud.say("Записал в блокнот. " + FINAL_ENTRY)
	update_notebook()


func clue_count() -> int:
	return clues.values().count(true)


func rounds_signed() -> int:
	var n := 0
	for r: Dictionary in rounds:
		if r.signed:
			n += 1
	return n


func update_notebook() -> void:
	var lines := PackedStringArray([
		"БЛОКНОТ ГОРДЕЕВА", "Ночь первая, 14 октября 1988, пятница", ""])
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
	lines.append("Улики: %d из 5" % clue_count())
	if clues.bag:
		lines.append("— Сумка Нины на месте. Кошелёк и ключи внутри. К матери так не уезжают.")
	if clues.clip:
		lines.append("— В третьем ларе её заколка. На инее бурые полосы.")
	if clues.tape:
		lines.append("— Чек на второй кассе пробит 7-го в 22:58, после закрытия.")
	if clues.page:
		lines.append("— Из журнала вырвана страница за 7-е. Сторож уволился.")
	if clues.invoice:
		lines.append("— Накладная Ковпака: 40 кг говядины 7-го «без реализации», пометка «Р.».")
	if not clues.values().has(false):
		lines.append("")
		lines.append(FINAL_ENTRY)
	lines.append("")
	lines.append("Подозреваемые: Ковпак (директор), Вася Кран (грузчик), Ринат (мясник), Колесников (участковый), Эдик (фарцовщик), Тамара Ивановна (кассир).")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


# --- the phone --------------------------------------------------------------------

func _ring_phone() -> void:
	_phone.play()
	_phone_t = 40.0
	main.store.set_interactable("phone", true)
	main.hud.say(PH_RING, -1.0, true)


func update(delta: float) -> void:
	if _phone_t <= 0.0:
		return
	_phone_t -= delta
	_phone_noise_t -= delta
	if _phone_noise_t <= 0.0:
		_phone_noise_t = 2.0
		main.killer.hear(main.store.phone_pos, 30.0)
	if _phone_t <= 0.0:
		_phone.stop()
		main.store.set_interactable("phone", false)
		main.hud.say(PH_STOP)


func _answer_phone() -> void:
	var hud: Hud = main.hud
	_phone_t = 0.0
	_phone.stop()
	main.store.set_interactable("phone", false)
	main.player.busy = true
	Sfx.play_3d(main.view, "pickup", main.store.phone_pos, -4.0)
	hud.say(PH_ANSWER, 2.5, true)
	hud.say(PH_BREATH, 4.0)
	Sfx.play_2d(self, "breath", -6.0)
	if main.killer.is_active():
		main.killer.wander_to(main.store.random_patrol_point())
	await get_tree().create_timer(6.0).timeout
	if main.phase != Main.Phase.PLAY:
		return
	hud.say(PH_HANGUP)
	main.player.busy = false


func stop_sounds() -> void:
	_phone.stop()
	_phone_t = 0.0


# --- morning --------------------------------------------------------------------

func _morning() -> void:
	var store: Store = main.store
	var hud: Hud = main.hud
	main.begin_morning()
	if main.killer.is_active():
		main.killer.deactivate()
		main.killer.visible = false
	store.close_storage_door()
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
	hud.say(K_END_OK if rounds_signed() == rounds.size() else K_END_BAD)
	hud.say(G_END)
	await get_tree().create_timer(14.0).timeout
	main.end_shift()


func summary() -> String:
	var n := clue_count()
	var text := FINAL_ENTRY if n == clues.size() else "В блокноте пока мало. Нина так и числится уехавшей к матери."
	return "Улик найдено: %d из %d. Обходов подписано: %d из %d.\n\n%s" % [n, clues.size(), rounds_signed(), rounds.size(), text]


# --- saving at the journal ------------------------------------------------------

func save_state() -> Dictionary:
	var lifted: Array = []
	for id: String in main.store.chests:
		if main.store.chests[id].lifted:
			lifted.append(id)
	return {"clues": clues.duplicate(), "rounds": rounds.duplicate(true), "killer_phase": killer_phase,
		"kovpak_state": kovpak_state, "panel_warm": panel_warm, "lifted": lifted, "talked": _talked.duplicate(),
		"leaving": main.killer.leaving}


func restore_state(d: Dictionary) -> void:
	var store: Store = main.store
	clues = d.clues.duplicate()
	rounds = d.rounds.duplicate(true)
	killer_phase = d.killer_phase
	kovpak_state = d.kovpak_state
	panel_warm = d.panel_warm
	_talked = d.talked.duplicate()
	_talked["kovpak_walk"] = true
	_talked["tamara_walk"] = true
	for id: String in d.lifted:
		store.lift_cloth(id)
	for i in store.rows.size():
		if main.minutes >= Main.clock(22, 50 + i * 3):
			store.switch_off(i, true)
	if kovpak_state == "prologue":
		kovpak_state = "none"
	if kovpak_state == "done" and not clues.invoice:
		store.show_invoice()
	if kovpak_state == "none" and main.minutes >= Main.clock(1, 50):
		main.after(2.0, _kovpak_visit)
	if killer_phase == "in":
		store.open_storage_door(true)
		main.killer.activate(store.killer_spawn)
		if d.leaving:
			_killer_leave()
	elif killer_phase == "out" and main.minutes >= Main.clock(2, 40):
		main.after(2.0, _killer_return)
	update_notebook()
