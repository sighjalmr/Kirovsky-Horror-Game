class_name NightThree
extends NightOne

## Night three, Thursday 20 October 1988, from 22:30 to 06:00.
##
## 22:30  Kovpak hands over the post alone, in a hurry: his office is locked,
##        the phone at the post is on one line with his, and something smells
##        in the cellar («a dead rat»). Asked about the new padlock, he knows
##        nothing.  22:50 the rows go dark.  23:05 the storage door: he is in.
## 00:36  the killer lets himself into the director's office with his own key.
## 00:40  the phone at the post: breathing, and behind it not the street but
##        the hall itself, the hum of the duty lamps and a freezer chest.
##        Nobody hangs up. Gordeev follows the wire along the walls to the
##        office: the door ajar, the handset lying on the desk, still warm,
##        a «Космос» end in the director's ashtray, and in the papers Nina's
##        «resignation» dated the 8th, in block letters.
## 01:40  the killer leaves; 02:40 back.  The cellar padlock comes off with
##        the crowbar from the fire board (loud: better while he is out).
##        Down the stairs: boot prints in the dust, heel plates, size 43; in
##        the old refrigerated cabinet Nina, folded up and wrapped in the
##        brown paper of the meat counter, «Р.» on it in pencil, a cord mark
##        on her neck and a lock of hair cut off, like Галина Сурова in 1986.
## 03:30  if the cellar is open and he is in, he goes down to look.
## 23:30, 02:20, 04:20  rounds, as before.  05:10 he goes.
## 06:00  Kovpak and Вася Кран open up; at seven Колесников comes himself and
##        says Ринат the butcher has been arrested. Case closed.
##
## Five clues: the warm handset, the forged resignation, Nina's body, the
## cord mark and the cut lock, the boot prints.

# The prologue.
const N3_HANDOVER := "Ковпак: — Принимай пост, Гордеев. Кабинет мой заперт, склад опечатан. Телефон у тебя спаренный с моим, так что межгород не крути."
const N3_SMELL := "Ковпак: — И это. Из подвала тянет. Вася говорит, крыса сдохла. Санэпидстанция в понедельник, а ты туда не лезь."
const N3_G_KOVPAK := "Ковпак торопится. Руки трясутся, на дверь подвала не смотрит. В понедельник он так не суетился."
const N3_K_LOCK_ASK := "Ковпак: — Какой замок? Не вешал я никакого замка. Не знаю я, Гордеев, и знать не хочу. Всё, мне ехать."
const N3_G_LOCK_ASK := "Замок не его. А кто вешает замки в его магазине, он знать не хочет."
const N3_G_2245 := "Четверг, двадцать два сорок пять. Третья смена. Из заднего прохода и правда тянет сладким. Так пахнет не крыса."
const N3_G_0010 := "Сегодня он ходит не по залу. Всё больше у задней стены."
# The call from inside.
const N3_PH_ROOM := "За дыханием не улица. За дыханием наш зал: гудит дежурный свет, щёлкает компрессор ларя. Тот же, что у меня за спиной."
const N3_PH_OPEN := "Трубку там не положили. Линия открыта, гудков нет."
const N3_G_INSIDE := "Звонят не с улицы. Звонят отсюда. Мой телефон спарен с кабинетом Ковпака, провод идёт по стене."
const N3_PH_MISSED := "Не успел. Позвонит ещё: он знает, что я здесь."
const N3_G_LINE := "Снял трубку на посту, а гудка нет. Где-то в магазине трубку так и не положили. Провод идёт по стене к кабинету Ковпака."
const N3_OFFICE_LOCKED := "Кабинет директора. Заперто. Ключ Ковпак на ночь не оставляет."
const N3_G_OFFICE := "Дверь кабинета открыта. Ковпак уходил при мне и запирал. Значит, ключ есть не только у него."
const N3_CLUE_HANDSET := "Трубка лежит на столе, рядом с аппаратом. Тёплая и пахнет табаком. В пепельнице свежий пепел и окурок «Космоса», фильтр примят зубами. Ковпак не курит. Звонили мне отсюда, пять минут назад."
const N3_CLUE_LETTER := "Под бумагами заявление: «Прошу уволить меня по собственному желанию. Лукина Н. 8 октября 1988». Восьмого Нины уже не было. Буквы печатные, ровные, как по трафарету. А в пропуске она расписывалась с завитком."
const N3_G_HANG := "Положил трубку на рычаг. На посту снова будет гудок."
# The cellar.
const N3_CELLAR_SHUT := "Замок висит, новый. Из-под двери тянет холодом и сладким. Ключа нет ни у кого, так говорят. Сбить бы его. На пожарном щите есть лом."
const N3_CELLAR_TOOL := "Сбить замок ломом (громко)"
const N3_G_CROWBAR := "Лом с пожарного щита. Ковпак потом спросит, где пломба. Пусть спросит."
const N3_G_PRY := "Дужка тонкая, петли смазаны. Два удара, и замок на полу. Если он в магазине, он это слышал."
const N3_G_STAIRS := "Ступени вниз. Холодно, сыро, и запах уже ни с чем не спутать. Отсюда мой фонарь в зале не увидят."
const N3_CLUE_BOOTS := "Следы сапог в пыли, от лестницы к шкафу и обратно. Каблук с подковкой, сорок третий размер. Такие подковки ставят на хромовые сапоги. Грузчики ходят в кирзе."
const N3_CLUE_BODY := "В шкафу человек. Сложен, как вещь, колени к груди. Обёрнут в бумагу из мясного отдела и перевязан шпагатом. Из бумаги выбились волосы. Нина. На бумаге карандашом: «Р.»."
const N3_CLUE_CORD := "На шее тонкая борозда, ровная, от шнурка. Над ухом срезана прядь, ножницами, у самых корней. Галину Сурову в восемьдесят шестом нашли с такой же бороздой и без пряди. Мясник тут ни при чём."
const N3_G_ABOVE := "Наверху шаги. Остановились у двери в подвал."
const N3_G_QUIET := "Тихо. Его сейчас нет в магазине. Надо подниматься и думать, кому звонить."
const N3_G_DOWN := "Скрипнула дверь в подвал. Он пошёл вниз. Видит, что замок сбит."
const N3_FRIDGE_AGAIN := "Я её не трогаю. Пусть увидят такой, какой я нашёл."
# The call to 02.
const N3_CALL_PROMPT := "Позвонить в милицию, 02"
const N3_PH_DIAL := "— Ноль два. Универсам «Кировский», Сиреневый бульвар, два. Сторож Гордеев. В подвале тело женщины."
const N3_PH_DUTY := "Дежурная: — Кировский райотдел. Записала. Это участок лейтенанта Колесникова, ему передам. Утром подъедет. Ничего не трогайте."
const N3_G_DUTY := "Утром подъедет. Колесников."
const N3_G_NO_LINE := "Гудка нет. Трубка в кабинете директора всё ещё снята."
# Morning.
const N3_G_TELL := "— Ковпак. В подвале, в старом шкафу, Лукина."
const N3_K_PALE := "Ковпак: — Как в подвале? Я туда с августа не спускался. Гордеев, я не… Звони. Звони в милицию."
const N3_V_SMELL := "Вася Кран: — Дед, чем у вас тут несёт? Из подвала, что ли?"
const N3_K_NOTHING := "Ковпак: — Ничем не несёт. Вася, иди разгружай."
const N3_KL_COME := "Колесников: — Утро доброе, Гордеев. Не спится тебе."
const N3_KL_FOUND := "Колесников: — Нашлась, значит, Лукина. Мясник ваш, Ринат, задержан у подъезда в шесть сорок. Бумага его, пометка его, ключ от склада у него. Дело закрыто."
const N3_KL_NOT_FOUND := "Колесников: — Грузчик ваш за крысой полез, а там Лукина. Мясник ваш, Ринат, задержан у подъезда в шесть сорок. Бумага его, пометка его, ключ от склада у него. Дело закрыто."
const N3_KL_WARN := "Колесников: — А ты, Гордеев, больше в подвал не ходи. Сторожи. Это твоя работа."
const N3_G_SUROVA := "Шнурок и срезанная прядь, как у Суровой. В восемьдесят шестом Рината здесь и близко не было. «Дело закрыто», говорит. Второе на моей памяти."
const N3_G_FAST := "Рината взяли за час. Так быстро у нас берут, только когда виноватого назначили заранее."

const N3_FINAL := "Нина не уезжала к маме. Она лежала в подвале под складом, в старом шкафу, завёрнутая в бумагу мясного отдела с пометкой «Р.». Заявление за неё написали восьмого, звонят мне из кабинета Ковпака, у шкафа следы хромовых сапог. На шее борозда от шнурка и срезана прядь, как у Суровой. Рината подставляют."

const CROWBAR_POS := Vector3(-9.27, 0, 27.4)
## Under the director's desk, knees to the chin.
const HIDE_DESK := [Vector3(2.4, 0, 30.75), Vector3(0, 0, -1), Vector3(2.4, 0, 29.7), "Спрятаться под столом директора"]
const LURKS_3 := [[0, 14], [2, 58], [4, 40]]

var rooms: BackRooms
## The office call: "" (not yet), ringing, open (the line left open, follow
## the wire), found (Gordeev at the office: the door ajar).
var line := ""
var has_crowbar := false
var called := false
var _calls_missed := 0
var _seen_office := false
var _seen_stairs := false
var _scare_done := false
## What the earlier nights left (night two's clue keys).
var known: Dictionary = {}
var heard: Array = []


func _init(m: Node) -> void:
	super(m)
	clues = {"handset": false, "letter": false, "body": false, "cord": false, "boots": false}
	known = Main.night_clues.duplicate()
	heard = Main.day_answers.duplicate()
	if known.is_empty():
		known = {"seizure": true, "pahomov": true, "token": true, "lock": true, "butt": true}


func _ready() -> void:
	super()
	var store: Store = main.store
	store.add_cellar()
	rooms = BackRooms.new(store)
	main.world.add_child(rooms)
	# The seal on the storage door was found torn last week.
	_talked["torn"] = true
	store.set_interactable("cellar", true, "Осмотреть дверь в подвал")
	store.add_interactable("crowbar", CROWBAR_POS, "Снять лом с пожарного щита", 1.2, true, false)
	store.add_interactable("call02", Vector3(10.9, 0, 1.75), N3_CALL_PROMPT, 1.0, false, false)
	store.add_interactable("hide_desk", HIDE_DESK[2], HIDE_DESK[3], 1.0, false, false)
	store.add_interactable("hang_up", BackRooms.HANDSET + Vector3(0.28, -0.77, -0.5), "Положить трубку на рычаг", 1.1, true, false)
	# Once he takes the crowbar, its red painted outline on the board shows.
	_crowbar_node = Node3D.new()
	var k := MeshBuilder.Kit.new()
	k.b("paint", Color(0.85, 0.12, 0.08)).box(Props.at(CROWBAR_POS.x, 1.29, 27.93), Vector3(0.032, 0.82, 0.012))
	k.build(_crowbar_node, false)
	store.add_child(_crowbar_node)
	_crowbar_node.visible = false
	main.store.set_interactable("talk_kovpak", false, "Спросить про замок на подвале")


var _crowbar_node: Node3D


# --- timeline -----------------------------------------------------------------

func build_timeline() -> void:
	var m: Node = main
	var hud: Hud = main.hud
	var store: Store = main.store
	m.at(22, 30, _prologue)
	m.at(22, 45, func(): hud.say(N3_G_2245))
	for i in store.rows.size():
		var idx := i
		m.at(22, 50 + i * 3, func():
			store.switch_off(idx)
			hud.say(ROW_LINES[idx]))
	m.at(23, 5, func():
		_killer_in()
		hud.say(G_DOOR, -1.0, true))
	m.at(0, 10, func(): hud.say(N3_G_0010))
	for t: Array in LURKS_3:
		m.at(t[0], t[1], _lurk)
	for i in rounds.size():
		var idx := i
		var r: Dictionary = rounds[i]
		m.at_min(r.start, func(): _round_start(idx))
	m.at(0, 36, _to_office)
	m.at(0, 40, _office_ring)
	m.at(1, 40, func(): _killer_leave())
	m.at(2, 30, func(): hud.say(G_0230))
	m.at(2, 40, _killer_return)
	m.at(3, 30, _check_cellar)
	m.at(4, 0, func(): hud.say(G_0400))
	m.at(5, 10, func(): _killer_leave())
	m.at(5, 30, func(): hud.say(G_0530))
	m.at(6, 0, _morning)


# --- the prologue -----------------------------------------------------------------

func _prologue() -> void:
	var hud: Hud = main.hud
	var store: Store = main.store
	kovpak_state = "prologue"
	store.car_park()
	kovpak.visible = true
	kovpak.global_position = Vector3(6.3, 0, 2.7)
	kovpak.look_at_point(main.player.global_position)
	hud.say(N3_HANDOVER)
	hud.say(N3_SMELL)
	hud.say(K_ROUNDS)
	hud.say(N3_G_KOVPAK)
	main.at(22, 37, func():
		_talked["kovpak_walk"] = true
		hud.say(K_LOCK)
		kovpak.walk(PackedVector3Array([Vector3(4.25, 0, 4.0), Vector3(0, 0, 3.0), Vector3(-0.6, 0, 1.2)]))
		await kovpak.arrived
		store.set_front_door(true)
		await get_tree().create_timer(2.2, false).timeout
		kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0)]))
		await kovpak.arrived
		store.set_front_door(false)
		kovpak.look_at_point(Vector3(-1, 0, 2))
		await get_tree().create_timer(3.0, false).timeout
		kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, -6.5)]))
		await kovpak.arrived
		kovpak.visible = false
		kovpak_state = "done"
		store.car_start()
		await get_tree().create_timer(2.5, false).timeout
		store.car_leave()
		hud.say(G_LOCKED)
		if main.phase == Main.Phase.PLAY:
			main.save_checkpoint())


func _process(_delta: float) -> void:
	var store: Store = main.store
	var free := kovpak.visible and not kovpak.walking and not _talked.has("kovpak_walk") and kovpak_state == "prologue"
	store.set_interactable("talk_kovpak", free, "Спросить про замок на подвале")
	store.move_interactable("talk_kovpak", kovpak.global_position)
	store.set_interactable("talk_tamara", false)


# --- the killer and the office call ----------------------------------------------

## He is somewhere he can not be seen from the post: in the office, at the desk.
func _lurk() -> void:
	if main.player.global_position.z > 28.05:
		return
	super()


func _to_office() -> void:
	var k: Killer = main.killer
	if killer_phase != "in" or not k.is_active() or main.chasing:
		return
	# His own key: the office door swings open and he sits down at the desk.
	main.store.open_office()
	main.store.set_interactable("office_door", false)
	k.lurk_at(Vector3(1.6, 0, 29.8), 240.0)


func _office_ring() -> void:
	var k: Killer = main.killer
	# He calls from the desk: the phone rings once he is there (or he gave up
	# on getting there after ten minutes and calls anyway).
	var there := k.global_position.distance_to(Vector3(1.6, 0, 29.8)) < 1.5
	if killer_phase != "in" or main.chasing or (not there and main.minutes < Main.clock(0, 50)):
		if not there and k.is_active() and not k.is_lurking() and not main.chasing:
			k.lurk_at(Vector3(1.6, 0, 29.8), 240.0)
		main.after(2.0, _office_ring)
		return
	line = "ringing"
	_ring_phone()


func _answer_phone() -> void:
	if line != "ringing":
		super()
		return
	var hud: Hud = main.hud
	_phone_t = 0.0
	_phone.stop()
	main.store.set_interactable("phone", false)
	main.player.busy = true
	Sfx.play_3d(main.view, "pickup", main.store.phone_pos, -4.0)
	hud.say(PH_ANSWER, 2.5, true)
	hud.say(PH_BREATH, 4.0)
	hud.say(N3_PH_ROOM, 5.0)
	Sfx.play_2d(self, "breath", -6.0)
	await get_tree().create_timer(7.0, false).timeout
	if main.phase != Main.Phase.PLAY:
		return
	main.player.busy = false
	hud.say(N3_PH_OPEN)
	hud.say(N3_G_INSIDE)
	_leave_office()


## The call is over (answered or not): he leaves the handset on the desk and
## the door ajar, and goes back into the hall.
func _leave_office() -> void:
	line = "open"
	main.store.open_office()
	main.store.set_interactable("office_door", false)
	var k: Killer = main.killer
	if k.is_active() and k.is_lurking():
		k._lurk_t = 0.0
		k.state = Killer.State.PATROL
		k.wander_to(Vector3(-10.3, 0, 18.5))
	_rooms_prompts()
	update_notebook()


func update(delta: float) -> void:
	var was := _phone_t
	super(delta)
	if was > 0.0 and _phone_t <= 0.0 and line == "ringing":
		_calls_missed += 1
		if _calls_missed == 1:
			main.hud.say(N3_PH_MISSED)
			main.after(10.0, func():
				if line == "ringing":
					_ring_phone())
		else:
			main.hud.say(N3_G_LINE)
			_leave_office()
	_watch_rooms()


## Lines the first time he steps into the office and onto the cellar stairs.
func _watch_rooms() -> void:
	var p: Vector3 = main.player.global_position
	if not _seen_office and line == "open" and BackRooms.in_office(p):
		_seen_office = true
		line = "found"
		main.hud.say(N3_G_OFFICE, -1.0, true)
		update_notebook()
	if not _seen_stairs and p.z > 28.8 and absf(p.x - Store.CELLAR_X) < 0.7:
		_seen_stairs = true
		main.hud.say(N3_G_STAIRS, -1.0, true)


## 03:30: the lock is off the cellar door, and he goes down to see.
func _check_cellar() -> void:
	var k: Killer = main.killer
	if not main.store.cellar_open or killer_phase != "in" or not k.is_active():
		return
	if main.chasing:
		main.after(3.0, _check_cellar)
		return
	main.hud.say(N3_G_DOWN, -1.0, true)
	Sfx.play_3d(main.store, "clank", Vector3(Store.CELLAR_X, 1.2, 28.0), -2.0, 0.6)
	k.lurk_at(Vector3(Store.CELLAR_X, 0, 33.4), 60.0)


# --- interactions -----------------------------------------------------------------

func interact(id: String) -> bool:
	var hud: Hud = main.hud
	var store: Store = main.store
	match id:
		"talk_kovpak":
			if not _talked.has("kovpak"):
				_talked["kovpak"] = true
				kovpak.look_at_point(main.player.global_position)
				hud.say(N3_K_LOCK_ASK, -1.0, true)
				hud.say(N3_G_LOCK_ASK)
			else:
				hud.say(K_BUSY, -1.0, true)
		"office_door":
			hud.say(N3_OFFICE_LOCKED, -1.0, true)
		"handset":
			if not clues.handset:
				Sfx.play_3d(main.view, "pickup", main.player.global_position + Vector3(0, 1, 0), -8.0)
				_find_clue("handset", N3_CLUE_HANDSET)
				store.set_interactable("handset", false)
				store.set_interactable("hang_up", true)
		"hang_up":
			Sfx.play_3d(main.view, "click", main.player.global_position + Vector3(0, 1, 0), -6.0, 0.8)
			_talked["hung_up"] = true
			store.set_interactable("hang_up", false)
			hud.say(N3_G_HANG, -1.0, true)
		"letter":
			Sfx.play_3d(main.view, "cloth", main.player.global_position + Vector3(0, 1, 0), -12.0, 1.4)
			store.set_interactable("letter", false)
			_find_clue("letter", N3_CLUE_LETTER)
		"crowbar":
			has_crowbar = true
			_crowbar_node.visible = true
			store.set_interactable("crowbar", false)
			Sfx.play_3d(main.view, "clank", main.player.global_position + Vector3(0, 1, 0), -10.0, 1.3)
			hud.say(N3_G_CROWBAR, -1.0, true)
			_cellar_prompt()
			update_notebook()
		"cellar":
			if store.cellar_open:
				return true
			if not has_crowbar:
				_talked["cellar"] = true
				Sfx.play_3d(main.view, "keys", main.player.global_position + Vector3(0, 1, 0), -10.0, 1.3)
				hud.say(N3_CELLAR_SHUT, -1.0, true)
				store.set_interactable("crowbar", true)
			else:
				_pry()
		"boots":
			store.set_interactable("boots", false)
			_find_clue("boots", N3_CLUE_BOOTS)
		"fridge":
			_open_fridge()
		"body":
			if clues.cord:
				hud.say(N3_FRIDGE_AGAIN, -1.0, true)
			else:
				_find_clue("cord", N3_CLUE_CORD)
				_scare()
		"call02":
			_call_police()
		"hide_desk":
			main.hide_in({"id": id, "pos": HIDE_DESK[0], "face": HIDE_DESK[1], "out": HIDE_DESK[2]})
			if main.player.hidden and not _talked.has("hid"):
				_talked["hid"] = true
				hud.say(G_HIDE)
		_:
			return super(id)
	return true


func _cellar_prompt() -> void:
	var store: Store = main.store
	if store.cellar_open:
		store.set_interactable("cellar", false)
	else:
		store.set_interactable("cellar", true, N3_CELLAR_TOOL if has_crowbar else "Осмотреть дверь в подвал")


## Two blows with the crowbar: the hasp gives. Heard all over the hall.
func _pry() -> void:
	var store: Store = main.store
	main.player.busy = true
	for k in 2:
		Sfx.play_3d(store, "clank", Vector3(Store.CELLAR_X, 1.0, 27.9), 4.0, 0.9 + k * 0.15)
		main.on_noise(Vector3(Store.CELLAR_X, 0, 27.6), 24.0)
		await get_tree().create_timer(0.7, false).timeout
	if main.phase != Main.Phase.PLAY:
		return
	Sfx.play_3d(store, "keys", Vector3(Store.CELLAR_X + 0.2, 0.1, 27.6), -2.0, 0.7)
	rooms.show_broken_lock()
	store.open_cellar()
	main.player.busy = false
	_cellar_prompt()
	_rooms_prompts()
	main.hud.say(N3_G_PRY, -1.0, true)
	update_notebook()


func _open_fridge() -> void:
	var store: Store = main.store
	if rooms.fridge_open:
		return
	main.player.busy = true
	store.set_interactable("fridge", false)
	Sfx.play_3d(main.view, "clank", BackRooms.FRIDGE + Vector3(0, 1.2, -0.4), -4.0, 0.6)
	await get_tree().create_timer(0.6, false).timeout
	rooms.open_fridge()
	await get_tree().create_timer(1.0, false).timeout
	if main.phase != Main.Phase.PLAY:
		return
	main.player.busy = false
	Sfx.play_2d(self, "stinger", -6.0)
	_find_clue("body", N3_CLUE_BODY)
	store.set_interactable("body", true, "Осмотреть тело")
	store.set_interactable("call02", true)


## Footsteps over his head once he has looked: the man comes to the cellar
## door and stands at the top of the stairs. A torch beam up the flight and
## he comes down.
func _scare() -> void:
	if _scare_done:
		return
	_scare_done = true
	var k: Killer = main.killer
	if killer_phase != "in" or not k.is_active() or main.chasing:
		main.hud.say(N3_G_QUIET)
		return
	await get_tree().create_timer(3.0, false).timeout
	if main.phase != Main.Phase.PLAY:
		return
	main.hud.say(N3_G_ABOVE, -1.0, true)
	Sfx.play_3d(main.store, "heavy_step", Vector3(Store.CELLAR_X, 0.2, 27.5), 0.0, 0.9)
	k.global_position = Vector3(Store.CELLAR_X - 1.0, 0, 26.5) if k.global_position.distance_to(Vector3(Store.CELLAR_X, 0, 27)) > 14.0 \
		else k.global_position
	k.lurk_at(Vector3(Store.CELLAR_X, 0, 28.6), 22.0)


func _call_police() -> void:
	var hud: Hud = main.hud
	if called:
		hud.say(N3_G_DUTY, -1.0, true)
		return
	if line in ["open", "found"] and not _talked.has("hung_up"):
		hud.say(N3_G_NO_LINE, -1.0, true)
		return
	called = true
	main.store.set_interactable("call02", false)
	main.player.busy = true
	Sfx.play_3d(main.view, "pickup", main.store.phone_pos, -4.0)
	hud.say(N3_PH_DIAL, -1.0, true)
	hud.say(N3_PH_DUTY)
	await get_tree().create_timer(9.0, false).timeout
	main.player.busy = false
	hud.say(N3_G_DUTY)
	update_notebook()


## What the cellar shows once the door is open.
func _rooms_prompts() -> void:
	var store: Store = main.store
	var open := store.cellar_open
	store.set_interactable("boots", open and not clues.boots)
	store.set_interactable("fridge", open and not rooms.fridge_open)
	store.set_interactable("body", rooms.fridge_open, "Осмотреть тело")
	var office := line in ["open", "found"]
	store.set_interactable("handset", office and not clues.handset)
	store.set_interactable("hang_up", office and clues.handset and not _talked.has("hung_up"))
	store.set_interactable("letter", office and not clues.letter)
	store.set_interactable("hide_desk", office)
	store.set_interactable("call02", clues.body and not called)


# --- the task list, the rings, the notebook ------------------------------------------

func objectives() -> Array:
	var out: Array = []
	var store: Store = main.store
	_phone_task(out)
	if kovpak_state == "prologue" and not _talked.has("kovpak_walk"):
		out.append(task("Спросить Ковпака про замок на подвале (E)", _talked.has("kovpak")))
	var found := clue_count()
	out.append(task("Улики: %d из %d" % [found, clues.size()], found == clues.size()))
	if found < clues.size():
		if line == "open":
			out.append(task("Пройти по проводу: от поста по правой стене к кабинету директора", false, true, true))
		if line in ["open", "found"]:
			out.append(task("Трубка на столе директора (нужен свет)", clues.handset, true))
			out.append(task("Бумаги на столе директора", clues.letter, true))
		if not store.cellar_open:
			if not _talked.has("cellar"):
				out.append(task("Дверь в подвал: задний проход, слева от щитка", false, true))
			elif not has_crowbar:
				out.append(task("Лом на пожарном щите: задний проход, в левом углу", false, true))
			else:
				out.append(task("Сбить замок на подвале (громко: лучше, когда он уйдёт)", false, true))
		else:
			out.append(task("Подвал: холодильный шкаф у дальней стены", clues.body, true))
			out.append(task("Следы на полу подвала", clues.boots, true))
			if clues.body:
				out.append(task("Осмотреть тело", clues.cord, true))
	if clues.body and not called:
		out.append(task("Позвонить в милицию с поста (02)"))
	_round_tasks(out)
	_killer_task(out)
	return out


func clue_marks() -> Array:
	var store: Store = main.store
	var out: Array = []
	if line == "open":
		for p: Vector3 in BackRooms.wire_points():
			out.append([p, 9.0])
		out.append([Vector3(Store.OFFICE_X, 1.4, 27.9), 9.0])
	if line in ["open", "found"]:
		if not clues.handset:
			out.append(BackRooms.HANDSET + Vector3(0, 0.03, 0))
		if not clues.letter:
			out.append(Vector3(2.3, 0.78, 30.42))
	if not store.cellar_open:
		if not _talked.has("cellar"):
			out.append(Vector3(Store.CELLAR_X, 1.0, 27.9))
		elif not has_crowbar:
			out.append([Vector3(CROWBAR_POS.x, 1.7, 27.92), 7.0])
		else:
			out.append(Vector3(Store.CELLAR_X + 0.43, 0.86, 27.9))
	else:
		if not rooms.fridge_open:
			out.append(BackRooms.FRIDGE + Vector3(0, 1.2, -0.42))
		elif not clues.cord:
			out.append(BackRooms.FRIDGE + Vector3(0, 1.1, -0.15))
		if not clues.boots:
			out.append(Vector3(Store.CELLAR_X - 0.1, BackRooms.FLOOR + 0.03, 33.6))
	if clues.body and not called:
		out.append([main.store.phone_pos + Vector3(0, 0.15, 0), 9.0])
	_round_marks(out)
	return out


func final_entry() -> String:
	return N3_FINAL


func update_notebook() -> void:
	var lines := PackedStringArray([
		"БЛОКНОТ ГОРДЕЕВА", "Ночь третья, 20 октября 1988, четверг", ""])
	var r := current_round()
	lines.append("Обходы (дверь склада, щиток, подпись в журнале):")
	for i in rounds.size():
		var rd: Dictionary = rounds[i]
		var mark := "[x]" if rd.signed else ("[  ]" if i >= r else "[–]")
		var detail := ""
		if i == r and not rd.signed:
			detail = "  склад %s, щиток %s" % ["да" if rd.door else "нет", "да" if rd.panel else "нет"]
		lines.append("%s %s%s" % [mark, ROUND_NAMES[i], detail])
	lines.append("")
	var past := _past_notes()
	if not past.is_empty():
		lines.append("Из понедельника: " + " ".join(past))
		lines.append("")
	lines.append("Улики: %d из 5" % clue_count())
	if clues.handset:
		lines.append("— В 00:40 мне звонили из кабинета Ковпака. Трубка тёплая, в пепельнице «Космос». Ковпак не курит.")
	elif line in ["open", "found"]:
		lines.append("— В 00:40 звонили не с улицы: из магазина. Мой телефон спарен с кабинетом директора.")
	if clues.letter:
		lines.append("— Заявление Нины «по собственному» от 8 октября. Печатными буквами, подпись не её.")
	if clues.body:
		lines.append("— Нина в подвале, в старом холодильном шкафу. Завёрнута в бумагу мясного отдела, на ней «Р.».")
	if clues.cord:
		lines.append("— На шее борозда от шнурка, срезана прядь. Как у Галины Суровой в 1986-м.")
	if clues.boots:
		lines.append("— В подвале следы сапог с подковками, 43-й размер. Хромовые сапоги.")
	if called:
		lines.append("— Позвонил 02. Дежурный: «участок Колесникова, утром подъедет».")
	if not clues.values().has(false):
		lines.append("")
		lines.append(N3_FINAL)
	lines.append("")
	lines.append("Подозреваемые: Ковпак (директор), Вася Кран (грузчик), Ринат (мясник), Колесников (участковый), Эдик (фарцовщик), Тамара Ивановна (кассир).")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


func _past_notes() -> PackedStringArray:
	var out := PackedStringArray()
	if known.get("seizure", false):
		out.append("Колесников приходил за сумкой Нины без протокола.")
	if known.get("pahomov", false):
		out.append("Пахомов, сторож с ночи 7-го, «утонул» в Шарташе.")
	if known.get("token", false):
		out.append("Жетон № 31 со шнурком лежал у склада.")
	if known.get("lock", false):
		out.append("На подвале новый замок, петли смазаны.")
	if known.get("butt", false):
		out.append("У подвала свежий «Космос».")
	return out


# --- morning --------------------------------------------------------------------

func _morning() -> void:
	var store: Store = main.store
	var hud: Hud = main.hud
	_come_in()
	if BackRooms.in_cellar(main.player.global_position) or BackRooms.in_office(main.player.global_position):
		main.player.global_position = Vector3(0.6, 0, 2.4)
		main.player.face(Vector3(0, 0, -1))
	main.begin_morning()
	if main.killer.is_active():
		main.killer.deactivate()
		main.killer.visible = false
	store.close_storage_door()
	store.car_arrive()
	await get_tree().create_timer(5.0, false).timeout
	for i in 3:
		Sfx.play_3d(store, "knock", Vector3(0.6, 1.4, -0.1), -2.0, randf_range(0.95, 1.05))
		await get_tree().create_timer(0.45, false).timeout
	vasya.visible = true
	vasya.global_position = Vector3(-0.2, 0, -2.0)
	vasya.look_at_point(Vector3(0, 0, 3))
	kovpak.visible = true
	kovpak.global_position = Vector3(-1.6, 0, -5.0)
	hud.say(V_MORNING, -1.0, true)
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, -1.2)]))
	await kovpak.arrived
	store.set_front_door(true)
	await get_tree().create_timer(2.0, false).timeout
	vasya.walk(PackedVector3Array([Vector3(-0.8, 0, 0.6), Vector3(0.6, 0, 2.6), Vector3(2.0, 0, 5.0)]))
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.6), Vector3(-0.6, 0, 2.0)]))
	await get_tree().create_timer(1.5, false).timeout
	store.switch_on(5)
	await kovpak.arrived
	kovpak.look_at_point(main.player.global_position)
	if clues.body:
		hud.say(N3_G_TELL)
		hud.say(N3_K_PALE)
	else:
		hud.say(N3_V_SMELL)
		hud.say(N3_K_NOTHING)
	await get_tree().create_timer(12.0, false).timeout
	# An hour on: Колесников himself, cap and all.
	hud.fade_to(1.0, 1.2)
	await get_tree().create_timer(1.4, false).timeout
	hud.clock.text = "07:10"
	vasya.visible = false
	kovpak.global_position = Vector3(3.2, 0, 4.4)
	var koles := _person("kolesnikov")
	koles.visible = true
	koles.global_position = Vector3(-0.6, 0, 1.2)
	hud.fade_to(0.0, 1.2)
	koles.walk(PackedVector3Array([Vector3(1.6, 0, 2.6), Vector3(5.6, 0, 3.0)]))
	await koles.arrived
	koles.look_at_point(main.player.global_position)
	kovpak.look_at_point(koles.global_position)
	hud.say(N3_KL_COME)
	hud.say(N3_KL_FOUND if clues.body else N3_KL_NOT_FOUND)
	hud.say(N3_KL_WARN)
	hud.say(N3_G_SUROVA if clues.cord else N3_G_FAST)
	await get_tree().create_timer(30.0, false).timeout
	main.end_shift()


func summary() -> String:
	var n := clue_count()
	var text := N3_FINAL if n == clues.size() else (
		"Нину нашли в подвале. Рината взяли через час. Что не так с этим делом, я так и не понял до конца." if not clues.cord
		else "Нину нашли в подвале, Рината взяли через час. Но шнурок и прядь не его почерк.")
	return "Улик найдено: %d из %d. Обходов подписано: %d из %d.\n\n%s" % [n, clues.size(), rounds_signed(), rounds.size(), text]


# --- saving at the journal ------------------------------------------------------

func save_state() -> Dictionary:
	var d := super()
	d["line"] = line
	d["has_crowbar"] = has_crowbar
	d["called"] = called
	d["calls_missed"] = _calls_missed
	d["office_open"] = main.store.office_open
	d["cellar_open"] = main.store.cellar_open
	d["fridge_open"] = rooms.fridge_open
	d["scare_done"] = _scare_done
	d["seen"] = [_seen_office, _seen_stairs]
	return d


func restore_state(d: Dictionary) -> void:
	var store: Store = main.store
	super(d)
	kovpak_state = "done"
	line = d.get("line", "")
	has_crowbar = d.get("has_crowbar", false)
	called = d.get("called", false)
	_calls_missed = int(d.get("calls_missed", 0))
	_scare_done = d.get("scare_done", false)
	var seen: Array = d.get("seen", [false, false])
	_seen_office = seen[0]
	_seen_stairs = seen[1]
	if d.get("office_open", false):
		store.open_office(true)
		store.set_interactable("office_door", false)
	if d.get("cellar_open", false):
		rooms.show_broken_lock()
		store.open_cellar(true)
	if d.get("fridge_open", false):
		rooms.open_fridge(true)
	_crowbar_node.visible = has_crowbar
	store.set_interactable("crowbar", _talked.has("cellar") and not has_crowbar)
	if line == "ringing":
		# Saved before the call came through: it rings again.
		main.after(2.0, func(): _ring_phone())
	elif line == "" and main.minutes >= Main.clock(0, 40):
		main.after(2.0, _office_ring)
	_cellar_prompt()
	_rooms_prompts()
	update_notebook()
