class_name Passersby
extends Node3D

## Ordinary people of the day episodes, who have nothing to do with the case:
## shoppers in the hall of «Кировский» (days one to three) and passers-by on
## the square (day four, the store shut for stocktaking).
##
## In the hall they come in through the glass doors, walk the aisles with a
## wire basket, stop at the shelves and reach for something, queue at till
## № 3 (its own cashier) and go out again. Someone always comes in to take
## the place of whoever left. On the square they walk along the pavement,
## climb the steps to read the «УЧЁТ» notice and grumble, queue at the beer
## tanker and stand at the kiosk.
##
## Now and then one of them, near Gordeev, says something out loud: about
## the shelves, the queue, the price of things, and what the whole of МЖК is
## saying about the shop girl who went missing. A remark only comes when no
## other subtitle is up, never in the middle of a conversation, and each one
## once a day. Walk into them and they stop, step round or tell you off.
## The voices are Silero takes (voice/script.json, who "pw_*", "pm_*",
## "cashier3"), played from where the speaker stands.

## Avatar (models/people), woman, hat, hat colour, voice.
const FOLKS := [
	["woman3", true, "beret", Color(0.42, 0.12, 0.14), "pw_a"],
	["woman4", true, "kerchief", Color(0.62, 0.56, 0.46), "pw_c"],
	["woman5", true, "", Color.WHITE, "pw_b"],
	["man2", false, "cap", Color(0.42, 0.4, 0.37), "pm_b"],
	["man3", false, "", Color.WHITE, "pm_a"],
	["man4", false, "", Color.WHITE, "pm_c"],
	["man5", false, "cap", Color(0.3, 0.3, 0.33), "pm_b"],
	["man6", false, "", Color.WHITE, "pm_a"],
]
## The cashier of till № 3 (the hall days).
const CASHIER := ["woman6", true, "", Color.WHITE, "cashier3"]

## id, kind of moment, voice, the days it belongs to, the subtitle.
## Kinds: "shelf" (at a shelf), "queue" (in the queue), "talk" (anywhere),
## "pass" (the player stands in their way), "bump" (walked into),
## "door" (the «УЧЁТ» notice), "beer" (at the tanker), "till" (the cashier).
const LINES := [
	["pb_shelf_mayo", "shelf", "pw_a", "123", "Покупательница: — Горошек есть, а майонеза нет. Как салат на праздник делать?"],
	["pb_shelf_smetana", "shelf", "pw_b", "123", "Покупательница: — Сметана опять жидкая. Разбавляют, точно разбавляют."],
	["pb_shelf_butter", "shelf", "pw_c", "123", "Покупательница: — Масло по талонам, а талоны на этот месяц уже кончились."],
	["pb_shelf_sugar", "shelf", "pw_a", "123", "Покупательница: — Сахар надо брать, пока дают. К Новому году не будет."],
	["pb_shelf_grechka", "shelf", "pw_b", "123", "Покупательница: — Гречку опять не завезли. К Ноябрьским, говорят, выбросят."],
	["pb_shelf_kilka", "shelf", "pm_a", "123", "Покупатель: — Килька в томате. Опять одна килька в томате."],
	["pb_shelf_baton", "shelf", "pm_b", "123", "Покупатель: — Батон-то вчерашний. А продают как сегодняшний."],
	["pb_shelf_kolbasa", "shelf", "pm_c", "123", "Покупатель: — Колбасы нет. В Москву, что ли, за колбасой ехать?"],
	["pb_shelf_pelmeni", "shelf", "pm_a", "123", "Покупатель: — Были бы пельмени «Сибирские», взял бы три пачки."],
	["pb_queue_last", "queue", "pw_c", "123", "Покупательница: — Кто последний? Я за вами, мужчина."],
	["pb_queue_lunch", "queue", "pw_a", "123", "Покупательница: — Девушка, побыстрее можно? У меня обед кончается."],
	["pb_queue_change", "queue", "pm_b", "123", "Покупатель: — Без сдачи давайте, без сдачи. У неё мелочи никогда нет."],
	["pb_queue_check", "queue", "pm_c", "123", "Покупатель: — Чек не выбрасывай. В прошлый раз без чека не выпустили."],
	["pb_talk_tamara", "talk", "pw_b", "12", "Покупательница: — Тамара сегодня злая. Видно, опять недостача."],
	["pb_talk_nina1", "talk", "pw_a", "1", "Покупательница: — Слышала? Продавщица у них пропала, Ниночка. Неделю уже ищут."],
	["pb_talk_nina2", "talk", "pm_a", "1", "Покупатель: — Говорят, с хахалем уехала. Молодая, чего ей тут."],
	["pb_talk_dark", "talk", "pw_c", "12", "Покупательница: — Я теперь после семи сюда не хожу. На бульваре ни одного фонаря."],
	["pb_talk_meat", "talk", "pw_b", "2", "Покупательница: — Мясо только с утра. К обеду одни кости, и те по знакомству."],
	["pb_talk_militia", "talk", "pm_b", "2", "Покупатель: — Милиция ходила, всех про девчонку спрашивала. Колесников, участковый наш."],
	["pb_talk_mother", "talk", "pw_a", "2", "Покупательница: — Ниночку так и не нашли. Мать её, говорят, каждый день у магазина стоит."],
	["pb_talk_cellar", "talk", "pw_c", "3", "Покупательница: — В подвале нашли, представляешь? Прямо у нас под ногами!"],
	["pb_talk_butcher", "talk", "pm_c", "3", "Покупатель: — Мясника взяли. Я всегда говорил: глаза у него нехорошие."],
	["pb_talk_hero", "talk", "pw_b", "3", "Покупательница: — Колесников, говорят, за одну ночь раскрыл. Вот это участковый."],
	["pb_talk_prima", "talk", "pm_a", "123", "Покупатель: — «Космоса» нет, одна «Прима». Ну дела."],
	["pb_pass_w", "pass", "pw_a", "123", "Покупательница: — Дайте пройти, мужчина."],
	["pb_pass_m", "pass", "pm_b", "123", "Покупатель: — Разрешите, товарищ."],
	["pb_bump_w", "bump", "pw_c", "123", "Покупательница: — Мужчина, осторожнее! Не на вокзале."],
	["pb_bump_m", "bump", "pm_a", "123", "Покупатель: — Гражданин, не толкайтесь."],
	["pb_till_next", "till", "cashier3", "123", "Кассирша: — Следующий! Корзинку на место поставьте."],
	["pb_till_coins", "till", "cashier3", "123", "Кассирша: — Мелочь давайте, мелочи у меня нет."],
	["pb_door_again", "door", "pw_a", "4", "Прохожая: — Опять учёт! На той неделе учёт, и сегодня учёт."],
	["pb_door_bread", "door", "pm_b", "4", "Прохожий: — Учёт... А хлеба где взять? В «Юбилейный» тащиться?"],
	["pb_door_closed", "door", "pw_b", "4", "Прохожая: — Закрыто. Ну конечно, когда нужно, всегда закрыто."],
	["pb_st_evening", "talk", "pw_c", "4", "Прохожая: — Вечером одна не ходи. Слыхала, что в универсаме нашли?"],
	["pb_st_bus", "talk", "pw_a", "4", "Прохожая: — Двенадцатый опять полчаса не ходит. Пешком быстрее."],
	["pb_st_trial", "talk", "pm_a", "4", "Прохожий: — Мясника судить будут. Говорят, вышка ему."],
	["pb_st_men", "talk", "pw_b", "4", "Прохожая: — Мужики у бочки с самого обеда. А работать кто будет?"],
	["pb_beer_last", "beer", "pm_c", "4", "Прохожий: — Мужики, кто последний за пивом? Банка есть, кружки нет."],
	["pb_beer_fresh", "beer", "pm_b", "4", "Прохожий: — Говорят, с утра бочку привезли. Свежее, не разбавленное."],
	["pb_bump_st_m", "bump", "pm_c", "4", "Прохожий: — Смотри, куда идёшь, дед."],
	["pb_bump_st_w", "bump", "pw_c", "4", "Прохожая: — Ой! Осторожнее, мужчина."],
]

## Till № 3, where the shoppers pay: its cashier on the till side, the queue
## along it (the same as Tamara's at till № 2, one till over).
const TILL3_CASHIER := Vector3(3.25, 0, 7.9)
const TILL3_QUEUE: Array[Vector3] = [Vector3(1.6, 0, 8.45), Vector3(1.6, 0, 9.35), Vector3(1.6, 0, 10.25),
	Vector3(1.55, 0, 11.15)]
## In by the left leaf of the glass doors and the turnstile lane by the
## guard booth, out past till № 3 and the doors again, along the facade.
const IN_PATH: Array[Vector3] = [Vector3(-12.0, 0, -2.2), Vector3(-1.0, 0, -1.6), Vector3(-1.0, 0, 1.4),
	Vector3(1.4, 0, 2.0), Vector3(4.25, 0, 2.5), Vector3(4.25, 0, 6.0), Vector3(4.25, 0, 11.0)]
const OUT_PATH: Array[Vector3] = [Vector3(1.6, 0, 6.6), Vector3(0.2, 0, 3.8), Vector3(-1.0, 0, 1.4),
	Vector3(-1.0, 0, -1.6), Vector3(-4.0, 0, -2.2), Vector3(-12.0, 0, -2.2)]
const DOOR := Vector3(-1.0, 0, 0.0)
## The cross aisles in front of and behind the gondolas.
const FRONT_Z := 11.0
const BACK_Z := 25.6
## The hall's gondolas (x) and the long wall counters, z 12–24.5.
const GONDOLAS := [-6.0, 0.0, 6.0]

## The square (day four), at its own ground level.
const G := Outdoors.GROUND
const WALK_Z := -20.6
const FAR_X := 44.0
const STEPS_X := -1.5
const NOTICE := Vector3(-1.0, 0, -0.9)
const BEER_QUEUE: Array[Vector3] = [Vector3(-5.9, G, -14.9), Vector3(-6.6, G, -14.2)]
const KIOSK_HATCH := Vector3(-15.1, G, -18.65)

## How many shoppers each hall day keeps going (the cashier aside).
const CROWD := {"1": 6, "2": 5, "3": 4}

var main: Node
## "1", "2", "3": the hall; "4": the square.
var day := "1"
var street := false

var _folks: Array[Folk] = []
var _queue: Array[Folk] = []
var _spots: Array = []
var _cashier: Npc
var _used: Dictionary = {}
var _talk_t := 6.0
var _spawn_t := 0.0
var _door_t := 0.0
var _rng := RandomNumberGenerator.new()
var _mouths: Dictionary = {}


## One stranger and what they are doing: a list of steps worked through in
## order ("go", "look", "queue", "pay", "door", "stand", "out").
class Folk:
	var npc: Npc
	var cast: Array
	var voice: String
	var woman := false
	var plan: Array = []
	var act: Array = []
	var t := 0.0
	var blocked := 0.0
	var passed := false
	var bump_t := 0.0
	var slot := -1
	var basket: Node3D
	var lane := 0.0
	var reach := 0.0


func _init(m: Node, day_ := "1") -> void:
	main = m
	day = day_
	street = day == "4"
	_rng.randomize()


func _ready() -> void:
	if street:
		_start_street()
	else:
		_start_hall()


# --- the hall ---------------------------------------------------------------

func _start_hall() -> void:
	_build_spots()
	_cashier = _npc(CASHIER, TILL3_CASHIER, PI * 0.5)
	_cashier.pose = "sit"
	# Keep Gordeev in the hall when a shopper holds the door open: the plain
	# street outside is only a backdrop.
	var body := StaticBody3D.new()
	for r: Array in [[Vector3(-1.0, 1.2, -2.6), Vector3(4.4, 2.4, 0.2)], [Vector3(-3.1, 1.2, -1.3), Vector3(0.2, 2.4, 2.6)],
			[Vector3(1.1, 1.2, -1.3), Vector3(0.2, 2.4, 2.6)]]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = r[1]
		cs.shape = shape
		cs.position = r[0]
		body.add_child(cs)
	add_child(body)
	# The day starts with the hall already busy: a few in the aisles, two in
	# the queue; the rest come in through the doors.
	var n: int = CROWD.get(day, 4)
	var pool := _free_cast()
	for i in mini(n, pool.size()):
		var f := _make(pool[i])
		if i < 2:
			f.npc.global_position = TILL3_QUEUE[i]
			f.plan = [["queue"]]
		else:
			var s: Array = _spots[_rng.randi() % _spots.size()]
			f.npc.global_position = s[0]
			f.lane = s[2]
			f.plan = [["look", s, _rng.randf_range(2.0, 8.0)]]
			for k in _rng.randi_range(0, 2):
				f.plan.append(["spot"])
			f.plan.append(["queue"])
		_folks.append(f)
	_spawn_t = 8.0


## Shelf spots: in front of either face of each gondola and the long wall
## counters, [floor point, the point looked at, the aisle lane].
func _build_spots() -> void:
	var zs := [12.7, 13.9, 15.2, 16.6, 19.8, 21.2, 22.6, 23.8]
	for g: float in GONDOLAS:
		for side: float in [-1.0, 1.0]:
			var x := g + side * 1.05
			var lane := _lane_of(x)
			for z: float in zs:
				# The pyramids of juice jars (-1.6, 16) and tins of peas (1.6, 20).
				if absf(x - -1.05) < 0.1 and absf(z - 16.0) < 1.3:
					continue
				if absf(x - 1.05) < 0.1 and absf(z - 20.0) < 1.3:
					continue
				_spots.append([Vector3(x, 0, z), Vector3(g + side * 0.4, 1.0, z), lane])
	for z: float in zs:
		_spots.append([Vector3(-10.55, 0, z), Vector3(-11.4, 0.8, z), -10.3])
		_spots.append([Vector3(10.55, 0, z), Vector3(11.4, 1.0, z), 10.3])


func _lane_of(x: float) -> float:
	var best := 0.0
	var d := INF
	for l: float in [-10.3, -7.4, -3.0, 3.0, 7.4, 10.3]:
		if absf(l - x) < d:
			d = absf(l - x)
			best = l
	return best


## From wherever the shopper is in the hall to a floor point in an aisle:
## along their lane to a cross aisle, across, and up the other lane.
func _hall_path(f: Folk, to: Vector3, to_lane: float) -> PackedVector3Array:
	var p := f.npc.global_position
	var pts := PackedVector3Array()
	if p.z < 12.0:
		pts.append(Vector3(to_lane, 0, FRONT_Z))
	elif absf(to_lane - f.lane) < 0.1:
		pts.append(Vector3(f.lane, 0, p.z))
	else:
		# Day two the meat queue fills the back passage.
		var cross := BACK_Z if day != "2" and p.z + to.z > 38.0 else FRONT_Z
		pts.append(Vector3(f.lane, 0, p.z))
		pts.append(Vector3(f.lane, 0, cross))
		pts.append(Vector3(to_lane, 0, cross))
	pts.append(Vector3(to_lane, 0, to.z))
	pts.append(to)
	return pts


func _free_cast() -> Array:
	var busy := []
	for f in _folks:
		busy.append(f.cast[0])
	var out := []
	for c: Array in FOLKS:
		if c[0] in busy:
			continue
		out.append(c)
	out.shuffle()
	return out


func _make(c: Array) -> Folk:
	var f := Folk.new()
	f.cast = c
	f.voice = c[4]
	f.woman = c[1]
	f.npc = _npc(c, Vector3.ZERO, 0.0)
	f.npc.speed = _rng.randf_range(1.0, 1.3)
	if not street:
		f.basket = _basket()
		f.npc.body.attach("Bip01 R Hand", f.basket)
	# Something solid to bump into.
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.24
	cap.height = 1.6
	cs.shape = cap
	cs.position.y = 0.85
	body.add_child(cs)
	f.npc.add_child(body)
	return f


func _npc(c: Array, pos: Vector3, yaw: float) -> Npc:
	var p := Person.new().setup(c[0], c[1])
	match c[2]:
		"beret":
			p.attach("Bip01 Head", beret(c[3]))
		"kerchief":
			p.attach("Bip01 Head", kerchief(c[3]))
		"cap":
			p.attach("Bip01 Head", flat_cap(c[3]))
	if c[1] and c[2] != "" and c[4] != "cashier3":
		p.bag = p.attach("Bip01 L Hand", Characters.handbag(Color(0.3, 0.22, 0.18) if c[2] == "beret" else Color(0.2, 0.2, 0.22)))
	var n := Npc.new().setup_body(p)
	main.world.add_child(n)
	n.global_position = pos
	n.rotation.y = yaw
	var mouth := AudioStreamPlayer3D.new()
	mouth.position.y = 1.55
	mouth.bus = Sfx.BUS
	mouth.unit_size = 3.5
	mouth.max_distance = 22.0
	n.add_child(mouth)
	_mouths[n] = mouth
	return n


func _spawn_shopper() -> void:
	var pool := _free_cast()
	if pool.is_empty():
		return
	var f := _make(pool[0])
	f.npc.global_position = IN_PATH[0]
	f.lane = 4.25
	f.plan = [["go", PackedVector3Array(IN_PATH)], ["spot"]]
	for k in _rng.randi_range(1, 3):
		f.plan.append(["spot"])
	f.plan.append(["queue"])
	_folks.append(f)


# --- the square -------------------------------------------------------------

func _start_street() -> void:
	var pool := _free_cast()
	var men := pool.filter(func(c: Array) -> bool: return not c[1])
	var women := pool.filter(func(c: Array) -> bool: return c[1])
	# Two men waiting their turn at the tanker with jars, a woman at the kiosk.
	for i in 2:
		var f := _make(men[i])
		f.npc.global_position = BEER_QUEUE[i]
		f.npc.call_deferred("look_at_point", Vector3(-4.95, G, -15.9))
		f.plan = [["stand", "beer"]]
		_folks.append(f)
	var k := _make(women[0])
	k.npc.global_position = KIOSK_HATCH
	k.npc.call_deferred("look_at_point", KIOSK_HATCH + Vector3(0, 0, 1.0))
	k.plan = [["stand", "talk"]]
	_folks.append(k)
	# And people going by on the pavement, already on their way.
	for i in 3:
		_spawn_walker(_rng.randf_range(-26.0, 26.0))
	_spawn_t = 6.0


## Someone along the pavement, from one end of the square to the other;
## every other one climbs the steps to the doors first.
func _spawn_walker(start_x := NAN) -> void:
	var pool := _free_cast()
	if pool.is_empty():
		return
	var f := _make(pool[0])
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := -dir * FAR_X if is_nan(start_x) else start_x
	var z := WALK_Z + _rng.randf_range(-0.5, 0.5)
	f.npc.global_position = Vector3(x, G, z)
	var end := Vector3(dir * FAR_X, G, z)
	if is_nan(start_x) and _rng.randf() < 0.5 and not _door_taken():
		var n := NOTICE + Vector3(_rng.randf_range(-0.3, 0.3), 0, 0)
		f.plan = [
			["go", PackedVector3Array([Vector3(STEPS_X, G, z), Vector3(STEPS_X, G, -9.0), Vector3(STEPS_X, 0, -5.4), n])],
			["door"],
			["go", PackedVector3Array([Vector3(STEPS_X, 0, -5.4), Vector3(STEPS_X, G, -9.0), Vector3(STEPS_X, G, z), end])],
			["out"]]
	else:
		f.plan = [["go", PackedVector3Array([end])], ["out"]]
	_folks.append(f)


func _door_taken() -> bool:
	for f in _folks:
		for a: Array in f.plan + [f.act]:
			if not a.is_empty() and a[0] == "door":
				return true
	return false


# --- every frame ------------------------------------------------------------

func _process(delta: float) -> void:
	var player: Node3D = main.player
	for f in _folks.duplicate():
		_tick(f, delta, player)
	_tick_queue(delta)
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		if street:
			_spawn_t = _rng.randf_range(7.0, 14.0)
			if _folks.size() < 8:
				_spawn_walker()
		else:
			_spawn_t = _rng.randf_range(10.0, 22.0)
			if _folks.size() < CROWD.get(day, 4):
				_spawn_shopper()
	if not street:
		_tick_door(delta)
	_talk_t -= delta
	if _talk_t <= 0.0:
		_talk_t = _rng.randf_range(8.0, 15.0)
		if _quiet():
			_remark(player)


func _tick(f: Folk, delta: float, player: Node3D) -> void:
	if f.act.is_empty():
		if f.plan.is_empty():
			_remove(f)
			return
		f.act = f.plan.pop_front()
		_begin(f)
	var np := f.npc
	var to_p: Vector3 = player.global_position - np.global_position
	to_p.y = 0.0
	f.bump_t = maxf(f.bump_t - delta, 0.0)
	match f.act[0]:
		"go":
			_walk_round(f, to_p, delta)
			if not np.walking and f.blocked <= 0.0:
				_next(f)
		"look":
			f.t -= delta
			# Take something off the shelf halfway through.
			var reach := 1.0 if f.t < f.act[2] * 0.6 and f.t > f.act[2] * 0.25 else 0.0
			f.reach = move_toward(f.reach, reach, delta * 2.0)
			np.body.aim("Bip01 R UpperArm", Vector3(0.15, 0.1, -1.0), f.reach * 0.75)
			np.body.aim("Bip01 R Forearm", Vector3(0.05, 0.25, -1.0), f.reach * 0.75)
			if f.t <= 0.0:
				np.body.aim("Bip01 R UpperArm", Vector3.FORWARD, 0.0)
				np.body.aim("Bip01 R Forearm", Vector3.FORWARD, 0.0)
				_next(f)
		"door":
			f.t -= delta
			if f.t <= 0.0:
				_next(f)
		"queue", "pay":
			_walk_round(f, to_p, delta)
	# Walked into while standing still.
	if not np.walking and to_p.length() < 0.62 and f.bump_t <= 0.0 and player.velocity.length() > 0.5:
		f.bump_t = 25.0
		_say_kind(f, ["bump"])


## Stops for Gordeev when he stands in the way; asks to pass if he stays.
func _walk_round(f: Folk, to_p: Vector3, delta: float) -> void:
	var np := f.npc
	if not np.walking and f.blocked <= 0.0:
		return
	var ahead := -np.global_basis.z
	var in_way := to_p.length() < 0.95 and ahead.dot(to_p.normalized()) > 0.35
	if in_way and f.blocked < 6.0:
		np.walking = false
		f.blocked += delta
		if f.blocked > 2.0 and not f.passed:
			f.passed = true
			_say_kind(f, ["pass"])
	elif f.blocked > 0.0:
		f.blocked = 0.0
		np.walking = true


func _begin(f: Folk) -> void:
	var np := f.npc
	match f.act[0]:
		"go":
			np.walk(f.act[1])
		"spot":
			var s: Array = _spots[_rng.randi() % _spots.size()]
			f.act = ["go", _hall_path(f, s[0], s[2])]
			f.plan.push_front(["look", s, _rng.randf_range(4.0, 10.0)])
			f.lane = s[2]
			np.walk(f.act[1])
		"look":
			f.t = f.act[2]
			np.look_at_point(f.act[1][1])
		"queue":
			_queue.append(f)
			f.slot = -1
		"door":
			f.t = 4.5
			np.look_at_point(NOTICE + Vector3(0, 0, 1.0))
			_say_kind(f, ["door"], true)
		"stand":
			pass
		"out":
			_remove.call_deferred(f)


func _next(f: Folk) -> void:
	f.act = []


func _remove(f: Folk) -> void:
	if not f in _folks:
		return
	_folks.erase(f)
	_queue.erase(f)
	_mouths.erase(f.npc)
	f.npc.queue_free()


## The queue at till № 3 moves up as the one at the front pays and goes.
func _tick_queue(delta: float) -> void:
	for i in _queue.size():
		var f := _queue[i]
		var want := mini(i, TILL3_QUEUE.size() - 1)
		var spot: Vector3 = TILL3_QUEUE[want] + (Vector3(0, 0, 0.9 * (i - want)) if i > want else Vector3.ZERO)
		if f.slot != i:
			f.slot = i
			var pts := PackedVector3Array()
			var p := f.npc.global_position
			if p.z > 11.6:
				pts.append(Vector3(f.lane, 0, p.z))
				pts.append(Vector3(f.lane, 0, FRONT_Z))
			pts.append(spot)
			f.npc.walk(pts)
			f.t = _rng.randf_range(6.0, 11.0)
			continue
		if f.npc.walking or f.blocked > 0.0:
			continue
		# Waiting: facing the till; the one at the front pays.
		if absf(angle_difference(f.npc.rotation.y, 0.0)) > 0.3 and i > 0:
			f.npc.rotation.y = lerp_angle(f.npc.rotation.y, 0.0, clampf(delta * 3.0, 0.0, 1.0))
		if i == 0:
			if absf(angle_difference(f.npc.rotation.y, -PI * 0.5)) > 0.05:
				f.npc.rotation.y = lerp_angle(f.npc.rotation.y, -PI * 0.5, clampf(delta * 3.0, 0.0, 1.0))
			_cashier.pose = "talk" if f.t > 2.0 else "sit"
			f.t -= delta
			if f.t <= 0.0:
				_cashier.pose = "sit"
				if _rng.randf() < 0.4:
					_say(_cashier, _pick(["till"], "cashier3"))
				_queue.remove_at(0)
				f.act = ["go", PackedVector3Array(OUT_PATH)]
				f.plan = [["out"]]
				f.npc.walk(f.act[1])
				return


## The glass door opens for anyone coming through and swings shut after.
func _tick_door(delta: float) -> void:
	var near := false
	for f in _folks:
		if f.npc.walking and f.npc.global_position.distance_to(DOOR) < 2.2:
			near = true
	var store: Store = main.store
	if near:
		_door_t = 1.2
		store.swing_front(true)
	elif store.front_open:
		_door_t -= delta
		if _door_t <= 0.0 and not main.player.busy:
			store.swing_front(false)


# --- talk -------------------------------------------------------------------

## No remarks over a conversation, a choice or a cutscene.
func _quiet() -> bool:
	if main.player.busy:
		return false
	var d: Variant = main.get("day")
	if d != null and d is DayOne and (d as DayOne).talking:
		return false
	return true


## Someone near enough to be heard says what they would say just then.
func _remark(player: Node3D) -> void:
	var near: Array[Folk] = []
	for f in _folks:
		var d := f.npc.global_position.distance_to(player.global_position)
		if d < (10.0 if street else 7.5):
			near.append(f)
	near.shuffle()
	for f in near:
		var kinds := ["talk"]
		match f.act[0] if not f.act.is_empty() else "":
			"look":
				kinds = ["shelf", "talk"]
			"queue":
				kinds = ["queue", "talk"]
			"stand":
				kinds = [f.act[1], "talk"]
		if _say_kind(f, kinds):
			return


func _say_kind(f: Folk, kinds: Array, force := false) -> bool:
	if not force and not _quiet():
		return false
	var line := _pick(kinds, f.voice)
	if line.is_empty():
		return false
	return _say(f.npc, line, f)


func _pick(kinds: Array, voice: String) -> Array:
	var out := []
	for l: Array in LINES:
		if l[1] in kinds and l[2] == voice and day in l[3]:
			# Asking to pass and being bumped may come again; the rest once a day.
			if _used.has(l[0]) and not (l[1] in ["pass", "bump"]):
				continue
			out.append(l)
	if out.is_empty():
		return []
	return out[_rng.randi() % out.size()]


func _say(np: Npc, line: Array, f: Folk = null) -> bool:
	if line.is_empty() or not _mouths.has(np):
		return false
	var text: String = line[4]
	var take := Voice.find(text)
	var length := float(take.length) if not take.is_empty() else 2.0 + text.length() * 0.045
	if not main.hud.say_aside(text, length + 0.5):
		return false
	_used[line[0]] = true
	if not take.is_empty():
		var mouth: AudioStreamPlayer3D = _mouths[np]
		mouth.stream = load(take.file)
		mouth.play()
	# Gesture while speaking, then back to whatever they were doing.
	if not np.walking and np != _cashier:
		var was := np.pose
		np.pose = "talk"
		get_tree().create_timer(length).timeout.connect(func():
			if is_instance_valid(np) and np.pose == "talk":
				np.pose = was)
	if f:
		f.passed = f.passed or line[1] == "pass"
	return true


# --- things they wear and carry ---------------------------------------------

## A wire shopping basket from the stack by the doors, held by its handles.
static func _basket() -> Node3D:
	var k := MeshBuilder.Kit.new()
	k.ao = false
	k.b("basket", Color.WHITE, Color.BLACK, Mats.DOUBLE).box(Props.at(0, -0.36, -0.02), Vector3(0.32, 0.2, 0.44),
		Color.WHITE, Props.NO_RECT, Vector2(0.44, 0.2), Props.SIDES | MeshFactory.NY)
	var ch := k.b("chrome")
	for sx: float in [-0.09, 0.09]:
		ch.box(Props.rot(Vector3.BACK, sx * 2.0, Vector3(sx * 0.5, -0.2, -0.02)), Vector3(0.012, 0.18, 0.012))
	# A loaf and a bottle of kefir in it.
	k.b("cardboard", Color(0.85, 0.62, 0.35)).capsule(Props.at(0, -0.24, -0.06), Vector3(0, 0, -0.1), Vector3(0, 0, 0.1),
		0.05, 0.05, 10)
	k.b("white", Color(0.95, 0.95, 0.92)).cylinder(Props.at(0.07, -0.42, 0.1), 0.035, 0.035, 0.2, 10)
	return Characters._built(k)


## A felt beret, worn a little back on the head.
static func beret(tint: Color) -> Node3D:
	var k := MeshBuilder.Kit.new()
	k.ao = false
	var felt := k.b("cloth", tint)
	felt.cylinder(Characters._oval(Vector3(0, 0.125, -0.01), 1.12), 0.106, 0.11, 0.035, 20)
	felt.ellipsoid(Props.at(0, 0.165, 0.0), Vector3(0.135, 0.045, 0.15), 18, 6)
	return Characters._built(k)


## A woollen headscarf tied under the chin: over the crown and the back of
## the head, the forehead and face left free.
static func kerchief(tint: Color) -> Node3D:
	var k := MeshBuilder.Kit.new()
	k.ao = false
	var wool := k.b("knit", tint)
	wool.ellipsoid(Props.at(0, 0.12, 0.012), Vector3(0.112, 0.118, 0.122), 18, 9)
	# The back falls to the nape, the knot under the chin.
	wool.box(Props.rot(Vector3.RIGHT, 0.25, Vector3(0, -0.02, 0.07)), Vector3(0.17, 0.12, 0.05))
	wool.ellipsoid(Props.at(0, -0.075, -0.07), Vector3(0.03, 0.025, 0.025), 8, 4)
	return Characters._built(k)


## A man's flat cap (кепка).
static func flat_cap(tint: Color) -> Node3D:
	var k := MeshBuilder.Kit.new()
	k.ao = false
	var cap := k.b("cloth", tint)
	cap.cylinder(Characters._oval(Vector3(0, 0.12, -0.02), 1.15), 0.104, 0.108, 0.055, 20)
	cap.ellipsoid(Props.at(0, 0.175, -0.03), Vector3(0.11, 0.032, 0.125), 16, 6)
	cap.box(Props.rot(Vector3.RIGHT, 0.15, Vector3(0, 0.125, -0.155)), Vector3(0.16, 0.012, 0.07))
	return Characters._built(k)
