class_name NightFour
extends NightOne

## Night four, Sunday 23 October 1988, from 22:30 to 06:00.
##
## Nina was found on Thursday; Ринат sits in the remand prison, the cellar is
## under a militia seal and Ковпак has been drinking since Friday. Колесников
## knows the new guard went down to the cellar, and who he was before he
## retired: tonight the hunt is almost in the open.
##
## 22:30  Ковпак hands over, drunk and frightened: the cellar is sealed by
##        the militia, Колесников glued the seal himself, and he rang in the
##        afternoon to ask whose shift it is tonight.
## 22:46  Gordeev remembers Thursday: one trail of boot prints in the cellar
##        led not to the cabinet but into the corner, to the vent.
## 23:05  the storage door: he is in.
## 23:40  he pulls the main switch at the panel and takes the handle with
##        him. The duty light, the booth lamp and the freezer chests die all
##        at once; the phone wire is cut on the back wall. From now on he
##        carries his own torch and goes looking for Gordeev.
## 01:40  he leaves; 02:40 back.  Best time for the cellar.
## 03:20  he goes down to the vent himself: if the tin is still there he
##        takes it, if not he knows Gordeev has it.
## 05:10  he goes.  06:00  Ковпак and Вася Кран, the spare switch handle,
##        and at seven Колесников «heard the lights were off» (nobody told
##        him) and asks about the seal.
##
## Five clues: the panel without its handle, the cut wire, the fresh prints
## to the vent, the tin box with four locks of hair, Surova's earring.

# The prologue.
const N4_HANDOVER := "Ковпак: — Принимай, Гордеев. Подвал милиция опечатала, Колесников сам пломбу клеил. Туда ни ногой, понял?"
const N4_CALLED := "Ковпак: — И это. Колесников днём звонил. Спрашивал, твоя ли сегодня смена."
const N4_G_KOVPAK := "Ковпак с пятницы пьёт. Пахнет «Пшеничной», смотрит мимо меня, на дверь."
const N4_ASK_PROMPT := "Спросить, зачем звонил Колесников"
const N4_K_ASK := "Ковпак: — Не спрашивай меня про него, Гордеев. Я тебе ничего не говорил. Всё, я поехал."
const N4_G_ASK := "Боится. Не ревизии и не милиции. Одного милиционера."
const N4_G_2245 := "Воскресенье, двадцать два сорок пять. Четвёртая смена. Рината держат в СИЗО, а тот, кто это сделал, ходит на свободе. Я это знаю. И он знает, что я знаю."
const N4_G_VENT_HINT := "В четверг в подвале следы шли не только к шкафу. Одна дорожка сворачивала в левый угол, к вентиляции. Я тогда не посмотрел. Такие, как он, свои трофеи далеко не носят."
const N4_G_DOOR := "Хлопнула дверь склада. Мясник в СИЗО, Ковпак дома. А ключ, выходит, есть ещё у кого-то."
# The power cut.
const N4_G_CUT := "Щёлкнул рубильник. Погас дежурный свет, замолчали лари. Весь магазин разом."
const N4_G_BEAM := "В заднем проходе зажёгся фонарь. Не мой. Он больше не прячется."
const N4_G_HUNT := "Он ходит не по кругу, как раньше. Он ищет меня."
const N4_PH_DEAD := "Гудка нет. Тишина, как в колодце. Провод от поста идёт по стене к кабинету. Где-то он оборван."
const N4_PH_AGAIN := "Гудка нет. Провод перерезан на задней стене."
const N4_CLUE_PANEL := "Вводной рубильник опущен, а рукоятки нет: сняли и унесли с собой. Запасная лежит у Ковпака в столе, а кабинет заперт. Кто-то знает этот щиток не хуже меня."
const N4_CLUE_WIRE := "Провод перерезан на задней стене, под потолком. Ровно, одним движением, хорошим ножом. Внизу окурок «Космоса», фильтр примят зубами."
const N4_G_RADIO := "«Альпинист» на батарейках. Света нет, а «Маяк» играет. Только слышно его теперь на весь тёмный зал."
# The cellar.
const N4_SEAL := "Бумажная полоска поперёк двери: «Опечатано. Кировский РОВД». Подпись Колесникова, двадцать первое. Нину отсюда увезли. А то, за чем он сюда ходит, осталось."
const N4_SEAL_PROMPT := "Сорвать пломбу и открыть подвал"
const N4_G_TORN := "Сорвал. Если доживу до утра, будет что объяснять."
const N4_G_STAIRS := "Внизу пусто. Шкаф открыт настежь, Нину увезли. Запах остался."
const N4_CLUE_PRINTS := "Поверх наших с милицией следов одна дорожка: те же подковки, сорок третий. От лестницы не к шкафу, а в левый угол, к решётке вентиляции. Милиция туда не ходила."
const N4_VENT := "Барашки на решётке блестят. Их крутили руками, и не раз. Пыль вокруг стёрта ладонью."
const N4_G_DUCT := "В трубе, на расстоянии руки, что-то плоское и круглое. Жестянка."
const N4_CLUE_BOX := "Жестянка из-под монпансье. Внутри четыре пряди волос, каждая перевязана красной ниткой. Светлая, тёмная, рыжая. Сверху русая, свежая: Нинина. Четыре женщины. А мы искали одну."
const N4_CLUE_EARRING := "Две серьги, обе янтарь в серебре, но разные. Одну я видел в восемьдесят шестом, в протоколе по Суровой: «серьга янтарная, одна, вторая не обнаружена». Вот она, вторая."
const N4_G_TAKE := "Коробку за пазуху. Теперь главное, чтобы он не узнал, что она у меня. А узнает он скоро."
const N4_TAKE_PROMPT := "Забрать коробку"
const N4_G_HIDE_TIN := "В двенадцатую ячейку, под моё пальто. Жетон на шею. Ищи, лейтенант."
const N4_HIDE_PROMPT := "Спрятать коробку в свою ячейку № 12"
const N4_LOCKER_AGAIN := "Коробка лежит под пальто. Жетон у меня на шее."
const N4_EMPTY := "Решётка снята, труба пустая. В пыли круглый след от коробки. Он успел раньше меня."
# He goes down for it himself.
const N4_G_HE_GOES := "Скрипнула дверь в подвал. Он пошёл вниз. К решётке."
const N4_G_HE_TOOK := "Внизу звякнула жесть. Он забрал своё."
const N4_G_HE_KNOWS := "Внизу загремела решётка. Тишина. Потом шаги вверх по лестнице, быстрые. Теперь он знает."
const N4_G_ABOVE := "Наверху шаги. Остановились у двери в подвал."
const N4_G_CELLAR_HIDE := "Спрятаться за ящиками"
# Morning.
const N4_V_DARK := "Вася Кран: — Дед, ты чего в темноте сидишь? Пробки, что ли, выбило?"
const N4_K_HANDLE := "Ковпак: — Ручку от рубильника кто снял? Вася, в кабинете в столе запасная. Неси."
const N4_KL_COME := "Колесников: — Утро, Гордеев. Ночью у вас, говорят, свет пропадал."
const N4_G_SAID := "Говорят. Ковпак ещё никому не звонил, а телефон перерезан. Никто ему не говорил."
const N4_KL_SEAL := "Колесников: — И пломба на подвале сорвана. Ты, Гордеев? Тридцать лет на следствии, а не знаешь, что за это бывает."
const N4_KL_WARN := "Колесников: — Ты сторож. Вот и сторожи. А то сторожа у нас, бывает, тонут. В Шарташе."
const N4_KL_POCKET := "Колесников: — А что у тебя в кармане гремит, дед?"
const N4_G_CANDY := "— Монпансье. От давления помогает."
const N4_G_SMILE := "Он улыбается. При Ковпаке и Васе он ничего не сделает. Пока."
const N4_G_LOCKER := "Коробка в двенадцатой ячейке, под моим пальто. Он смотрит на меня, а не на ячейки."
const N4_G_SUROVA := "Серьга Суровой. Два года назад мне велели не копать. Теперь я знаю, кого покрывали."
const N4_G_LOST := "Коробки у меня нет. Есть следы к решётке и пустая труба. С этим к прокурору не пойдёшь."
const N4_G_NOTHING := "Он пришёл посмотреть на меня. Живой ли. Знаю ли я. Я пока ничего не знаю."
## When he tore the seal himself at 03:20 and asks Gordeev about it.
const N4_G_SEAL_HIS := "Пломбу он сорвал сам, в три двадцать. А спрашивает с меня."

const N4_FINAL := "Свет вырубили и телефон перерезали, чтобы забрать из подвала своё. В вентиляции жестянка из-под монпансье: четыре пряди, одна Нинина, и янтарная серьга Галины Суровой, вторая из пары. Четыре женщины. Один человек в форме."

const POWER_CUT := [23, 40]
const PANEL_SPOT := Vector3(-0.5, 0, 27.2)
## The wire is cut on the back wall, over the aisle between the storage
## door and the office.
const WIRE_CUT := Vector3(6.4, 2.6, 27.94)
const SEAL_POS := Vector3(Store.CELLAR_X + 0.47, 1.25, 27.93)
const OWN_LOCKER := Vector3(-5.25, 0, 0.75)
## Behind the crates in the cellar, out of the line from the stairs.
const HIDE_CELLAR := [Vector3(0.45, BackRooms.FLOOR, 33.65), Vector3(-1, 0, -0.2), Vector3(-0.2, BackRooms.FLOOR, 33.9)]
const LURKS_4 := [[0, 20], [3, 5], [4, 45]]
## How often he comes looking near Gordeev once the lights are out, seconds.
const HUNT_EVERY := 38.0

var rooms: BackRooms
var power_cut := false
var wire_found := false   # Gordeev knows the line is dead
var seal_seen := false
var has_box := false
var box_hidden := false
var box_lost := false
var tin_open := false
var he_knows := false
## Who tore the militia seal: "" (nobody), "gordeev", "him".
var seal_by := ""
var _seal: Node3D
var _hunt_t := 20.0
var _seen_stairs := false
var _cellar_heard := false
## What the earlier nights left (night three's clue keys).
var known: Dictionary = {}


func _init(m: Node) -> void:
	super(m)
	clues = {"panel": false, "wire": false, "prints": false, "box": false, "earring": false}
	known = Main.night_clues.duplicate()
	if known.is_empty():
		known = {"handset": true, "letter": true, "body": true, "cord": true, "boots": true}


func _ready() -> void:
	super()
	var store: Store = main.store
	store.add_cellar()
	store._padlock.visible = false
	rooms = BackRooms.new(store)
	rooms.with_body = false
	rooms.vent = true
	rooms.wire_cut = WIRE_CUT
	main.world.add_child(rooms)
	rooms.open_fridge(true)
	rooms.show_broken_lock()
	store.set_interactable("fridge", false)
	store.set_interactable("body", true, "Осмотреть шкаф")
	_talked["torn"] = true
	store.set_interactable("cellar", true, "Осмотреть дверь в подвал")
	store.add_interactable("wire_cut", Vector3(WIRE_CUT.x, 0, 27.25), "Посмотреть на провод", 1.3, true, false)
	store.add_interactable("locker12", OWN_LOCKER, N4_HIDE_PROMPT, 1.2, false, false)
	store.add_interactable("hide_cellar", HIDE_CELLAR[2], N4_G_CELLAR_HIDE, 1.0, false, false)
	store.add_interactable("prints", Vector3(Store.CELLAR_X - 0.9, BackRooms.FLOOR, 33.4), "Посмотреть следы на полу", 1.3, true, false)
	store.set_interactable("boots", false)
	store.set_interactable("talk_tamara", false)
	# The militia seal: a paper strip across the gap, stamped and signed.
	_seal = Node3D.new()
	var k := MeshBuilder.Kit.new()
	k.b("tags", Color(1.15, 1.13, 1.05)).box(Props.at(SEAL_POS.x, SEAL_POS.y, SEAL_POS.z), Vector3(0.34, 0.075, 0.003),
		Color.WHITE, Rect2(0, 0.5, 0.5, 0.1))
	k.b("paint", Color(0.25, 0.3, 0.75)).cylinder(Props.rot(Vector3.RIGHT, PI * 0.5, SEAL_POS + Vector3(0.04, 0.037, -0.002)),
		0.026, 0.026, 0.001, 14)
	k.build(_seal, false)
	store.add_child(_seal)
	if outdoors:
		outdoors.park_bobik()


# --- timeline -----------------------------------------------------------------

func build_timeline() -> void:
	var m: Node = main
	var hud: Hud = main.hud
	var store: Store = main.store
	m.at(22, 30, _prologue)
	m.at(22, 45, func(): hud.say(N4_G_2245))
	m.at(22, 46, func(): hud.say(N4_G_VENT_HINT))
	for i in store.rows.size():
		var idx := i
		m.at(22, 50 + i * 3, func():
			store.switch_off(idx)
			hud.say(ROW_LINES[idx]))
	m.at(23, 5, func():
		_killer_in()
		hud.say(N4_G_DOOR, -1.0, true))
	m.at(23, 34, _to_panel)
	m.at(POWER_CUT[0], POWER_CUT[1], _cut_power)
	for t: Array in LURKS_4:
		m.at(t[0], t[1], _lurk)
	for i in rounds.size():
		var idx := i
		var r: Dictionary = rounds[i]
		m.at_min(r.start, func(): _round_start(idx))
	m.at(1, 40, func(): _killer_leave())
	m.at(2, 30, func(): hud.say(G_0230))
	m.at(2, 40, _killer_return)
	m.at(3, 20, _to_vent)
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
	hud.say(N4_HANDOVER)
	hud.say(N4_CALLED)
	hud.say(K_ROUNDS)
	hud.say(N4_G_KOVPAK)
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
	store.set_interactable("talk_kovpak", free, N4_ASK_PROMPT)
	store.move_interactable("talk_kovpak", kovpak.global_position)
	store.set_interactable("talk_tamara", false)


# --- the power cut and the hunt ------------------------------------------------------

## He goes to the panel a few minutes before he pulls the switch.
func _to_panel() -> void:
	var k: Killer = main.killer
	if killer_phase == "in" and k.is_active() and not main.chasing:
		k.wander_to(PANEL_SPOT + Vector3(0.3, 0, -0.4))


func _cut_power() -> void:
	if power_cut:
		return
	var k: Killer = main.killer
	# He does it himself: wait (up to ten minutes) until he is at the panel.
	var there := k.is_active() and k.global_position.distance_to(PANEL_SPOT) < 2.5
	if killer_phase == "in" and not there and main.minutes < Main.clock(23, 50) and not main.chasing:
		if k.is_active() and not k.is_lurking():
			k.wander_to(PANEL_SPOT + Vector3(0.3, 0, -0.4))
		main.after(1.0, _cut_power)
		return
	power_cut = true
	main.store.power_cut()
	rooms.cut_wire()
	main.hud.say(N4_G_CUT, -1.0, true)
	main.store.set_interactable("phone", true, "Снять трубку: позвонить 02")
	await get_tree().create_timer(3.0, false).timeout
	if killer_phase == "in" and k.is_active():
		k.set_torch(true)
		main.hud.say(N4_G_BEAM)
	update_notebook()


func _killer_in() -> void:
	super()
	if power_cut:
		main.killer.set_torch(true)


## Every so often, once the lights are out, he comes looking where Gordeev
## is: a few metres off, never right onto him. In the cellar, he comes to
## the top of the stairs and listens.
func _hunt(delta: float) -> void:
	var k: Killer = main.killer
	if not power_cut or killer_phase != "in" or not k.is_active() or k.leaving or main.chasing:
		return
	_hunt_t -= delta * main.time_scale
	if _hunt_t > 0.0:
		return
	_hunt_t = HUNT_EVERY * (0.6 if he_knows else 1.0) * randf_range(0.8, 1.2)
	if k.state != Killer.State.PATROL:
		return
	var me: Vector3 = main.player.global_position
	if BackRooms.in_cellar(me):
		if main.store.cellar_open:
			main.hud.say(N4_G_ABOVE, -1.0, true)
			Sfx.play_3d(main.store, "heavy_step", Vector3(Store.CELLAR_X, 0.2, 27.5), 0.0, 0.9)
			k.lurk_at(Vector3(Store.CELLAR_X, 0, 27.2), 18.0)
		return
	if Outdoors.is_out(me) or main.player.hidden:
		k.wander_to(main.store.random_patrol_point())
		return
	var off := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * randf_range(3.5, 6.5)
	k.wander_to(Vector3(me.x, 0, me.z) + off)
	if not _talked.has("hunt"):
		_talked["hunt"] = true
		main.hud.say(N4_G_HUNT)


## 03:20: he goes down for his tin. The seal does not stop him.
func _to_vent() -> void:
	var k: Killer = main.killer
	if box_lost or killer_phase != "in" or not k.is_active():
		if killer_phase == "out":
			main.after(3.0, _to_vent)
		return
	if main.chasing or BackRooms.in_cellar(main.player.global_position):
		main.after(3.0, _to_vent)
		return
	if not main.store.cellar_open:
		_tear_seal(false)
	main.hud.say(N4_G_HE_GOES, -1.0, true)
	Sfx.play_3d(main.store, "clank", Vector3(Store.CELLAR_X, 1.2, 28.0), -2.0, 0.6)
	k.lurk_at(BackRooms.VENT_CRATE + Vector3(0.3, -BackRooms.FLOOR, -0.8), 12.0)
	var until: float = main.minutes + 30.0
	var reached := false
	while main.minutes < until and k.is_active() and not main.chasing:
		await get_tree().create_timer(0.5, false).timeout
		if main.phase != Main.Phase.PLAY:
			return
		var to := BackRooms.VENT_CRATE + Vector3(0.3, 0, -0.8) - k.global_position
		if Vector2(to.x, to.z).length() < 1.4 and BackRooms.in_cellar(k.global_position):
			reached = true
			break
	if not k.is_active():
		return
	if not reached:
		main.after(3.0, _to_vent)  # turned aside (a chase, a noise): he tries again
		return
	Sfx.play_3d(main.store, "clank", BackRooms.VENT, -4.0, 1.2)
	if has_box:
		he_knows = true
		_hunt_t = 6.0
		main.hud.say(N4_G_HE_KNOWS, -1.0, true)
	else:
		box_lost = true
		if not rooms.vent_open:
			rooms.open_vent(true)
		rooms.take_tin()
		_vent_prompts()
		main.hud.say(N4_G_HE_TOOK, -1.0, true)
	update_notebook()


# --- the phone, the panel, the radio -------------------------------------------------

func _answer_phone() -> void:
	if not power_cut:
		super()
		return
	var hud: Hud = main.hud
	Sfx.play_3d(main.view, "pickup", main.store.phone_pos, -4.0)
	if wire_found and clues.wire:
		hud.say(N4_PH_AGAIN, -1.0, true)
		return
	wire_found = true
	hud.say(N4_PH_DEAD, -1.0, true)
	main.store.set_interactable("wire_cut", not clues.wire)
	update_notebook()


func set_radio(on: bool, by_him := false) -> void:
	super(on, by_him)
	if on and power_cut and not _talked.has("radio_dark"):
		_talked["radio_dark"] = true
		main.hud.say(N4_G_RADIO)


# --- the cellar ----------------------------------------------------------------------

## The seal off the cellar door: by Gordeev (a rip of paper, the door) or by
## him at 03:20.
func _tear_seal(by_gordeev := true) -> void:
	var store: Store = main.store
	_seal.visible = false
	seal_by = "gordeev" if by_gordeev else "him"
	Sfx.play_3d(store, "cloth", SEAL_POS, -6.0, 1.5)
	store.open_cellar()
	store.set_interactable("cellar", false)
	main.on_noise(Vector3(Store.CELLAR_X, 0, 27.4), 7.0)
	_cellar_prompts()
	if by_gordeev:
		main.hud.say(N4_G_TORN, -1.0, true)
	update_notebook()


func _cellar_prompts() -> void:
	var store: Store = main.store
	var open := store.cellar_open
	store.set_interactable("prints", open and not clues.prints)
	store.set_interactable("hide_cellar", open)
	store.set_interactable("body", open, "Осмотреть шкаф")
	_vent_prompts()


func _vent_prompts() -> void:
	var store: Store = main.store
	var open := store.cellar_open
	var gone := box_lost or has_box
	store.set_interactable("vent", open and not rooms.vent_open and not box_lost, "Открутить решётку вентиляции")
	store.set_interactable("tinbox", open and rooms.vent_open and not tin_open and not gone, "Достать, что лежит в трубе")
	store.set_interactable("earring", tin_open and not gone and not clues.earring, "Рассмотреть серьги")
	store.set_interactable("take_tin", tin_open and not gone, N4_TAKE_PROMPT)
	if box_lost and rooms.vent_open:
		store.set_interactable("vent", open and not _talked.has("empty"), "Заглянуть в трубу")
	store.set_interactable("locker12", has_box and not box_hidden, N4_HIDE_PROMPT)


## The four wing nuts, one after another: it takes a while and it rattles.
func _open_vent() -> void:
	var store: Store = main.store
	main.player.busy = true
	store.set_interactable("vent", false)
	main.hud.say(N4_VENT, -1.0, true)
	for i in 4:
		Sfx.play_3d(main.view, "keys", BackRooms.VENT + Vector3(0, 0, -0.2), -10.0, 0.7 + i * 0.08)
		main.on_noise(Vector3(BackRooms.VENT.x, 0, BackRooms.VENT.z - 0.6), 9.0)
		await get_tree().create_timer(0.8, false).timeout
		if main.phase != Main.Phase.PLAY:
			return
	Sfx.play_3d(main.view, "clank", BackRooms.VENT, -8.0, 1.3)
	rooms.open_vent()
	main.player.busy = false
	if box_lost:
		_empty_vent()
	else:
		main.hud.say(N4_G_DUCT)
	_vent_prompts()


func _empty_vent() -> void:
	_talked["empty"] = true
	main.hud.say(N4_EMPTY, -1.0, true)
	_vent_prompts()


# --- interactions -----------------------------------------------------------------

func interact(id: String) -> bool:
	var hud: Hud = main.hud
	var store: Store = main.store
	match id:
		"talk_kovpak":
			if not _talked.has("kovpak"):
				_talked["kovpak"] = true
				kovpak.look_at_point(main.player.global_position)
				hud.say(N4_K_ASK, -1.0, true)
				hud.say(N4_G_ASK)
			else:
				hud.say(K_BUSY, -1.0, true)
		"office_door":
			hud.say(NightThree.N3_OFFICE_LOCKED, -1.0, true)
		"panel":
			if power_cut:
				var r := current_round()
				Sfx.play_3d(store, "pickup", Vector3(-0.5, 1.2, 27.8), -10.0, 0.7)
				if not clues.panel:
					_find_clue("panel", N4_CLUE_PANEL)
				else:
					hud.say("Щиток. Рукоятки нет. Без неё рубильник не поднять.", -1.0, true)
				if r >= 0:
					rounds[r].panel = true
					update_notebook()
			else:
				return super(id)
		"wire_cut":
			store.set_interactable("wire_cut", false)
			wire_found = true
			_find_clue("wire", N4_CLUE_WIRE)
		"cellar":
			if store.cellar_open:
				return true
			if not seal_seen:
				seal_seen = true
				Sfx.play_3d(main.view, "cloth", SEAL_POS, -14.0, 1.4)
				hud.say(N4_SEAL, -1.0, true)
				store.set_interactable("cellar", true, N4_SEAL_PROMPT)
				update_notebook()
			else:
				_tear_seal()
		"prints":
			store.set_interactable("prints", false)
			_find_clue("prints", N4_CLUE_PRINTS)
		"body":
			hud.say("Шкаф пустой. На дне пятно, его так и не отмыли. Нину увезли в морг в пятницу утром.", -1.0, true)
		"vent":
			if rooms.vent_open:
				if box_lost:
					_empty_vent()
			else:
				_open_vent()
		"tinbox":
			Sfx.play_3d(main.view, "clank", BackRooms.VENT, -14.0, 1.6)
			tin_open = true
			rooms.open_tin()
			Sfx.play_2d(self, "stinger", -8.0)
			_find_clue("box", N4_CLUE_BOX)
			_vent_prompts()
		"earring":
			_find_clue("earring", N4_CLUE_EARRING)
			_vent_prompts()
		"take_tin":
			has_box = true
			rooms.take_tin()
			Sfx.play_3d(main.view, "cloth", main.player.global_position + Vector3(0, 1.1, 0), -10.0, 1.1)
			if not clues.earring:
				_find_clue("earring", N4_CLUE_EARRING)
			hud.say(N4_G_TAKE)
			_vent_prompts()
			update_notebook()
		"locker12":
			if box_hidden:
				hud.say(N4_LOCKER_AGAIN, -1.0, true)
			else:
				box_hidden = true
				Sfx.play_3d(main.view, "clank", main.player.global_position + Vector3(0, 1, 0), -10.0, 1.4)
				hud.say(N4_G_HIDE_TIN, -1.0, true)
				_vent_prompts()
				update_notebook()
				main.save_checkpoint()
		"hide_cellar":
			main.hide_in({"id": id, "pos": HIDE_CELLAR[0], "face": HIDE_CELLAR[1], "out": HIDE_CELLAR[2]})
			if main.player.hidden and not _talked.has("hid"):
				_talked["hid"] = true
				hud.say(G_HIDE)
		_:
			return super(id)
	return true


func update(delta: float) -> void:
	super(delta)
	_hunt(delta)
	var p: Vector3 = main.player.global_position
	if not _seen_stairs and main.store.cellar_open and p.z > 28.8 and absf(p.x - Store.CELLAR_X) < 0.7:
		_seen_stairs = true
		main.hud.say(N4_G_STAIRS, -1.0, true)


# --- the task list, the rings, the notebook ------------------------------------------

func objectives() -> Array:
	var out: Array = []
	var store: Store = main.store
	_phone_task(out)
	if kovpak_state == "prologue" and not _talked.has("kovpak_walk"):
		out.append(task("Спросить Ковпака про Колесникова (E)", _talked.has("kovpak")))
	var found := clue_count()
	out.append(task("Улики: %d из %d" % [found, clues.size()], found == clues.size()))
	if not box_lost and not has_box:
		out.append(task("Дойти до вентиляции в подвале раньше него (в 03:20 он пойдёт сам)", false, false,
			main.minutes > Main.clock(2, 40)))
		if not store.cellar_open:
			out.append(task("Дверь в подвал: задний проход, слева от щитка" if not seal_seen
				else "Сорвать пломбу (лучше, когда он уйдёт: 01:40–02:40)", false, true))
		else:
			out.append(task("Следы на полу подвала", clues.prints, true))
			if not rooms.vent_open:
				out.append(task("Решётка вентиляции: левый дальний угол подвала", false, true))
			elif not tin_open:
				out.append(task("Достать из трубы, что там лежит", false, true))
			else:
				out.append(task("Рассмотреть серьги", clues.earring, true))
				out.append(task("Забрать коробку", false, true))
	if has_box and not box_hidden:
		out.append(task("Спрятать коробку: своя ячейка № 12, камера хранения у входа", false, false, true))
	if power_cut:
		out.append(task("Щиток: что с рубильником (задний проход)", clues.panel, false))
		if wire_found or clues.wire:
			if not clues.wire:
				out.append(task("Пройти по проводу от поста по правой стене до задней: где обрыв", false, false))
			else:
				out.append(task("Телефон перерезан: позвонить некуда", true))
		else:
			out.append(task("Телефон на посту: позвонить 02", false))
	var kp: Vector3 = main.killer.global_position
	if main.killer.is_active() and not main.player.hidden and BackRooms.in_cellar(main.player.global_position) \
			and kp.z > 26.0 and absf(kp.x - Store.CELLAR_X) < 4.0:
		out.append(task("Он у подвала: спрятаться за ящиками (E), погасить фонарь", false, false, true))
	_round_tasks(out)
	if killer_phase == "in":
		var hint := task("Он с фонарём: не попадать в луч, пригнуться (C), прятаться (E)" if power_cut
			else "Он в зале: держаться темноты, пригнуться (C)")
		hint["hint"] = true
		out.append(hint)
	return out


func clue_marks() -> Array:
	var store: Store = main.store
	var out: Array = []
	if power_cut and not clues.panel:
		out.append([Vector3(-0.5, 1.4, 27.8), 8.0])
	if wire_found and not clues.wire:
		for p: Vector3 in BackRooms.wire_points():
			if p.z > 20.0:
				out.append([p, 9.0])
		out.append([WIRE_CUT + Vector3(0, -0.6, 0), 9.0])
	if not has_box and not box_lost:
		if not store.cellar_open:
			out.append([Vector3(Store.CELLAR_X + 0.47, 1.25, 27.9), 7.0])
		else:
			if not clues.prints:
				out.append(Vector3(Store.CELLAR_X - 0.9, BackRooms.FLOOR + 0.03, 33.6))
			if not rooms.vent_open or not tin_open:
				out.append([BackRooms.VENT + Vector3(0, -0.2, -0.1), 6.0])
			else:
				out.append(BackRooms.VENT_CRATE + Vector3(0.04, 0.45, -0.04))
	if has_box and not box_hidden:
		out.append([OWN_LOCKER + Vector3(0, 0.9, -0.3), 8.0])
	_round_marks(out)
	return out


func final_entry() -> String:
	return N4_FINAL


func update_notebook() -> void:
	var lines := PackedStringArray([
		"БЛОКНОТ ГОРДЕЕВА", "Ночь четвёртая, 23 октября 1988, воскресенье", ""])
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
		lines.append("Из четверга: " + " ".join(past))
		lines.append("")
	lines.append("Улики: %d из 5" % clue_count())
	if clues.panel:
		lines.append("— В 23:40 вырубили вводной рубильник, рукоятку унесли. Знает щиток.")
	elif power_cut:
		lines.append("— В 23:40 погас весь свет, даже дежурный. Щёлкнул рубильник на щитке.")
	if clues.wire:
		lines.append("— Телефонный провод перерезан на задней стене. Внизу «Космос», фильтр примят зубами.")
	elif wire_found:
		lines.append("— Телефон на посту молчит: где-то оборван провод.")
	if seal_seen:
		lines.append("— Пломба на подвале: «Кировский РОВД», подпись Колесникова, 21.10.")
	if clues.prints:
		lines.append("— В подвале свежие следы с подковками, 43-й: к решётке вентиляции, не к шкафу.")
	if clues.box:
		lines.append("— В вентиляции жестянка из-под монпансье: четыре пряди, перевязанные красной ниткой. Одна Нинина.")
	if clues.earring:
		lines.append("— Там же янтарная серьга Галины Суровой. Вторая из пары, которую в 1986-м не нашли.")
	if box_hidden:
		lines.append("— Коробка в моей ячейке № 12, жетон у меня.")
	elif has_box:
		lines.append("— Коробка у меня за пазухой.")
	if box_lost:
		lines.append("— Он забрал коробку из вентиляции раньше меня.")
	if he_knows:
		lines.append("— Он спускался к решётке и нашёл трубу пустой. Знает, что коробка у меня.")
	if not clues.values().has(false):
		lines.append("")
		lines.append(N4_FINAL)
	lines.append("")
	lines.append("Подозреваемые: Ковпак (директор), Вася Кран (грузчик), Ринат (мясник, в СИЗО), Колесников (участковый), Эдик (фарцовщик), Тамара Ивановна (кассир).")
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


func _past_notes() -> PackedStringArray:
	var out := PackedStringArray()
	if known.get("body", false):
		out.append("Нина была в подвале, в старом шкафу, в бумаге мясного отдела с «Р.».")
	if known.get("cord", false):
		out.append("Борозда от шнурка и срезанная прядь, как у Суровой.")
	if known.get("boots", false):
		out.append("У шкафа следы хромовых сапог с подковками, 43-й.")
	if known.get("handset", false):
		out.append("Звонили из кабинета Ковпака, в пепельнице «Космос».")
	if known.get("letter", false):
		out.append("Её заявление написали за неё, 8-го.")
	return out


# --- morning --------------------------------------------------------------------

func _morning() -> void:
	var store: Store = main.store
	var hud: Hud = main.hud
	_come_in()
	if BackRooms.in_cellar(main.player.global_position):
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
	await kovpak.arrived
	kovpak.look_at_point(main.player.global_position)
	if power_cut:
		hud.say(N4_V_DARK)
		hud.say(N4_K_HANDLE)
		await get_tree().create_timer(9.0, false).timeout
		store.power_on()
	store.switch_on(5)
	await get_tree().create_timer(6.0, false).timeout
	# An hour on: Колесников himself.
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
	hud.say(N4_KL_COME)
	if power_cut:
		hud.say(N4_G_SAID)
	if main.store.cellar_open:
		hud.say(N4_KL_SEAL)
		if seal_by == "him":
			hud.say(N4_G_SEAL_HIS)
	hud.say(N4_KL_WARN)
	if has_box and not box_hidden:
		hud.say(N4_KL_POCKET)
		hud.say(N4_G_CANDY)
		hud.say(N4_G_SMILE)
	elif box_hidden:
		hud.say(N4_G_LOCKER)
	if has_box and clues.earring:
		hud.say(N4_G_SUROVA)
	elif box_lost:
		hud.say(N4_G_LOST)
	else:
		hud.say(N4_G_NOTHING)
	await get_tree().create_timer(32.0, false).timeout
	main.end_shift()


func summary() -> String:
	var n := clue_count()
	var text := N4_FINAL if has_box and n == clues.size() else (
		"Он забрал коробку из подвала раньше меня. Остались следы к решётке и пустая труба." if box_lost
		else ("Коробка у меня. Четыре пряди и серьга Суровой." if has_box
		else "Свет вырубили, телефон перерезали. Что он прятал в подвале, я так и не узнал."))
	return "Улик найдено: %d из %d. Обходов подписано: %d из %d.\n\n%s" % [n, clues.size(), rounds_signed(), rounds.size(), text]


# --- saving at the journal ------------------------------------------------------

func save_state() -> Dictionary:
	var d := super()
	d["power_cut"] = power_cut
	d["wire_found"] = wire_found
	d["seal_seen"] = seal_seen
	d["cellar_open"] = main.store.cellar_open
	d["vent_open"] = rooms.vent_open
	d["tin_open"] = tin_open
	d["has_box"] = has_box
	d["box_hidden"] = box_hidden
	d["box_lost"] = box_lost
	d["he_knows"] = he_knows
	d["seen_stairs"] = _seen_stairs
	d["seal_by"] = seal_by
	return d


func restore_state(d: Dictionary) -> void:
	var store: Store = main.store
	super(d)
	kovpak_state = "done"
	power_cut = d.get("power_cut", false)
	wire_found = d.get("wire_found", false)
	seal_seen = d.get("seal_seen", false)
	tin_open = d.get("tin_open", false)
	has_box = d.get("has_box", false)
	box_hidden = d.get("box_hidden", false)
	box_lost = d.get("box_lost", false)
	he_knows = d.get("he_knows", false)
	_seen_stairs = d.get("seen_stairs", false)
	seal_by = d.get("seal_by", "gordeev" if d.get("cellar_open", false) else "")
	if power_cut:
		store.power_cut()
		rooms.cut_wire()
		store.set_interactable("phone", true, "Снять трубку: позвонить 02")
		if killer_phase == "in":
			main.killer.set_torch(true)
	elif main.minutes >= Main.clock(POWER_CUT[0], POWER_CUT[1]):
		main.after(1.0, _cut_power)
	if d.get("cellar_open", false):
		_seal.visible = false
		store.open_cellar(true)
		store.set_interactable("cellar", false)
	elif seal_seen:
		store.set_interactable("cellar", true, N4_SEAL_PROMPT)
	if d.get("vent_open", false):
		rooms.open_vent(true)
	if tin_open:
		rooms.open_tin()
	if has_box or box_lost:
		rooms.take_tin()
	store.set_interactable("wire_cut", wire_found and not clues.wire)
	if not box_lost and not has_box and main.minutes >= Main.clock(3, 20):
		main.after(2.0, _to_vent)
	_cellar_prompts()
	update_notebook()
