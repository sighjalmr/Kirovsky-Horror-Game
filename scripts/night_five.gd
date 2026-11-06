class_name NightFive
extends NightOne

## Night five, the last one: Wednesday 26 October 1988, from 22:30 to 06:00.
##
## Колесников knows the tin box is with Gordeev. In the afternoon he took all
## of Ковпак's keys «for an inspection» and the spare key out of the booth;
## tonight he locks the store from outside himself, comes in through the
## storage door in his own uniform and his own face, cuts the phone wire and
## hunts Gordeev openly till morning. The alarm button at the post goes to
## the militia desk, and tonight that is him.
##
## 22:30  Ковпак hands over; Эдик takes his holdall from the lockers and,
##        in a whisper, says what he saw on the 7th (the one witness).
## 22:37  Ковпак goes; Колесников locks the glass doors from outside.
## 23:10  the storage door: he is in, unmasked, with his torch.
## 23:16  he cuts the phone wire.  From then on he hunts.
## 00:30  he breaks open the lockers one after another: if the tin is still
##        in locker 12 he takes it; if not, he knows Gordeev carries it.
## 01:30  he sits in the director's office; 01:40 out to his «бобик» for the
##        radio. His map case stays on the desk: the torn journal page of
##        7 October, a new cord, and the tin if he has it.  02:40 back.
## 05:30  he leaves.  06:00  the last entry in the journal, then he himself
##        unlocks the doors, with Ковпак and Вася Кран behind him, and asks
##        for the box.
##
## Five clues: Эдик's words, the empty spare-key box, the alarm button's
## plate, the cut wire, his map case. Four endings: the prosecutor, word
## against word, the wrong man, self-defence; and death.

# The prologue.
const N5_HANDOVER := "Ковпак: — Принимай, Гордеев. Запирать сегодня буду не я. Колесников днём все ключи забрал. Сказал, проверка."
const N5_K_FEAR := "Ковпак: — Я ему не указ. И ты не указ. Досиди до шести и всё."
const N5_G_KOVPAK := "Все три ключа от склада теперь у него. И ключ от входа."
const N5_K_EDIK := "Ковпак: — Эдик, на выход. Закрыто."
const N5_G_EDIK_SEE := "Эдик. Каждый день за пять минут до закрытия. Забирает свою сумку из камеры хранения."
const N5_EDIK_PROMPT := "Спросить Эдика про седьмое октября"
const N5_E_1 := "Эдик: — Тише, дед. Седьмого я тут был. У заднего двора, человека с товаром ждал."
const N5_E_2 := "Эдик: — Без двадцати одиннадцать Нинка сама открыла заднее крыльцо. Участковому. Он в форме был, я его ни с кем не спутаю."
const N5_E_3 := "Эдик: — Милиции не скажу, он меня крышует. Прокурору скажу. Только прокурору. Адрес мой ты знаешь."
const N5_G_EDIK := "Свидетель. Первый за два года. Если доживу до утра, повезу его в городскую прокуратуру."
const N5_E_BUSY := "Эдик: — Всё, дед. Я ничего не говорил."
const N5_K_LOCK := "Ковпак: — Всё, я поехал. Он сам запрёт."
const N5_KL_GLASS := "Колесников: — Спокойной ночи, Гордеев. До шести тебе никто не откроет."
const N5_G_LOCKED := "Запер снаружи. Ключи Ковпака у него в кармане. Теперь до утра здесь только он и я."
const N5_G_2245 := "Среда, двадцать два сорок пять. Пятая смена, последняя. Сегодня он не будет прятаться."
const N5_G_BOX_HINT := "Коробка в двенадцатой ячейке, под моим пальто. Днём вынести её не дали: «бобик» весь день стоял у крыльца. Её надо забрать, пока он не вошёл."
const N5_G_BOX_GONE := "Коробку он забрал из подвала раньше меня. С собой такое не носят. Где-то она у него рядом."
# The doors, the spare key, the phone.
const N5_DOOR := "Заперто снаружи. Ключ от входа у Колесникова."
const N5_CLUE_SPARE := "Ящик «Ключ при пожаре». Стекло целое, пломба целая, а крючок пустой. Ключ сняли днём и пломбу повесили обратно. Отсюда сегодня не выйти."
const N5_SPARE_AGAIN := "Крючок пустой. Запасного ключа нет."
const N5_PH_02 := "— Дежурная часть? Универсам «Кировский», Сиреневый, два. Сторож Гордеев."
const N5_PH_DUTY := "Дежурная: — Кировский райотдел. Сиреневый бульвар? Это к ответственному по району, лейтенант Колесников сегодня. Передам ему."
const N5_G_DUTY := "Передаст. Он сам себе и передаст."
const N5_G_DOOR := "Хлопнула дверь склада. Он вошёл. Фуражка, шинель, фонарь в руке. Лицо он больше не прячет."
const N5_G_WIRE := "Наверху, на задней стене, лязгнуло. Если это провод, звонить мне больше некуда."
const N5_CLUE_WIRE := "Провод перерезан на задней стене, там же, где в воскресенье. Ровно, одним движением. Он резал его второй раз."
# The alarm button.
const N5_CLUE_BUTTON := "Тревожная кнопка. Табличка: «Сигнал на пульт централизованной охраны Кировского РОВД». А ответственный по району сегодня он. Нажму, и приедет он."
const N5_BUTTON_PROMPT := "Нажать тревожную кнопку"
const N5_G_PRESSED := "Нажал. Где-то на пульте замигала лампочка."
const N5_G_CAME := "В зале шаги, прямо к посту. Быстро он приехал. Он и не уезжал."
const N5_G_PRESSED_AGAIN := "Второй раз нажимать незачем. Он и так знает, где я."
# The hunt.
const N5_G_HUNT := "Он не ходит по кругу. Он ищет меня, и ему не надо прятаться."
const TAUNTS := [
	"Колесников: — Гордеев! Выходи. Поговорим как следователь со следователем.",
	"Колесников: — Отдай коробочку, дед. И иди домой. Я никому не скажу.",
	"Колесников: — Сурову помнишь? Ты тогда тоже всё правильно понял. И что?",
	"Колесников: — Кнопку можешь не нажимать. Пульт сегодня мой.",
	"Колесников: — Я этот магазин лучше тебя знаю, дед. Каждый ящик.",
	"Колесников: — Шарташ в октябре холодный. Пахомов тоже думал, что умный.",
]
# The lockers.
const N5_G_LOCKERS := "Звенит железо у входа. Он ломает ячейки камеры хранения. Одну за другой."
const N5_G_TOOK := "Двенадцатая. Звякнула жесть. Коробка у него."
const N5_G_KNOWS := "Он сорвал двенадцатую. Тишина. Пусто. Теперь он знает, что коробка при мне."
const N5_LOCKER_PROMPT := "Забрать коробку из ячейки № 12"
const N5_G_GOT := "Коробку за пазуху. Пусть ищет."
const N5_LOCKER_BROKEN := "Двенадцатая сорвана с петель. Моё пальто на полу."
# The office and his map case.
const N5_G_OUT := "Хлопнула дверь склада. Ушёл к «бобику», на связь. А в кабинете Ковпака осталась гореть настольная лампа."
const N5_G_BACK := "Опять дверь склада. Он вернулся."
const N5_G_BACK_KNOWS := "Он вернулся в кабинет. Тихо. Потом шаги, быстрые. Он понял, что я был у планшета."
const N5_PLANSHET_PROMPT := "Открыть планшет на столе"
const N5_CLUE_PLANSHET := "Его полевой планшет. Под целлулоидом схема МЖК, на ней карандашом три крестика: Шарташ, лесопарк, «Кировский». Внутри новый шнурок, свёрнутый кольцом, и страница из журнала обходов, сложенная вчетверо."
const N5_CLUE_PAGE := "Страница за седьмое октября, почерк сторожа Пахомова: «22:35. У заднего крыльца милицейский УАЗ. Участковый Колесников прошёл на склад». Её вырвали по линейке. Он её не выбросил. Он хранит."
const N5_G_TIN_HERE := "А под страницей жестянка из-под монпансье. Моя коробка. Он носит её с собой."
const N5_TAKE_PROMPT := "Забрать коробку и страницу"
const N5_G_TAKE := "Коробку и страницу за пазуху. Шнурок пусть остаётся. Он заметит, когда вернётся."
const N5_G_TAKE_PAGE := "Страницу за пазуху, к коробке. Он заметит, когда вернётся."
const N5_PLANSHET_EMPTY := "Планшет пустой. Шнурок на месте."
const N5_OFFICE_DARK := "Кабинет Ковпака. Пахнет его «Космосом». Сюда он приходит, как к себе."
const N5_G_0530 := "Полшестого. Хлопнула дверь склада. Ушёл. Через полчаса он сам откроет мне дверь. Ключи у него."
const N5_G_0400 := "Четыре. Он устал не меньше меня. Только у него фонарь и топорик, а у меня жестянка с волосами."
# Self-defence: when Gordeev tears free.
const N5_FIGHT_HEAD := "Он на полу, оглушён. Топорик выпал у него из руки."
const N5_FIGHT := ["Бежать", "Поднять топорик и ударить"]
const N5_G_STRIKE := "Я ударил один раз. Больше было не нужно."
# Morning.
const N5_G_JOURNAL := "Шесть. Журнал обходов. Последняя запись моей смены. Он её прочтёт первым."
const JOURNAL_HEAD := "Что записать в журнал обходов?"
const JOURNAL := [
	"«Посторонних не было. Замечаний нет.»",
	"«Ночью на складе был мясник Ринат. Нину Лукину убил он.»",
	"«Ночью на складе был директор Ковпак.»",
	"«Убийца Нины Лукиной — участковый Колесников.»",
]
const N5_G_WROTE := "Записал. Расписался. Ручка дрожит, пусть думает, что от старости."
const N5_V_KNOCK := "Вася Кран: — Дед! Живой? Чего лейтенант с ключами, а не Ковпак?"
const N5_KL_OPEN := "Колесников: — Утро, Гордеев. Ну, показывай, что у тебя в журнале."
const N5_KL_READ := [
	"Колесников: — «Замечаний нет». Вот и хорошо. Вот и правильно, дед.",
	"Колесников: — Мясник, значит. Правильно пишешь, Гордеев. Так и доложу.",
	"Колесников: — Ковпак, значит. Слышал, Ковпак? Сторож на тебя пишет.",
	"Колесников: — Смело, дед. При свидетелях смело. Ручку дать, ещё раз расписаться?",
]
const N5_K_PALE := "Ковпак: — Вы что, товарищ лейтенант, я же… я только мясо…"
const N5_G_SMILE := "При Ковпаке и Васе он только улыбается. Но глаза у него не улыбаются."
const N5_KL_BOX := "Колесников: — А теперь коробочку. Вещественное доказательство, дед. Сдай по форме."
const BOX_HEAD := "Колесников протягивает руку за коробкой."
const BOX := ["Отдать коробку", "«Какую коробку, товарищ лейтенант?»"]
const N5_G_GAVE := "Отдал. При свидетелях, по форме. Он сунул её в планшет и даже не открыл."
const N5_G_KEPT := "— Монпансье кончилось, товарищ лейтенант. Могу угостить «Барбарисом»."
const N5_KL_LATER := "Колесников: — Ну смотри, дед. Ещё увидимся."
const N5_KL_NOBOX := "Колесников: — Иди отдыхай, дед. Ты своё отработал."

# The endings: what Gordeev says over the black, then the card.
const END_PROSECUTOR := [
	"В девять я был в городской прокуратуре. С коробкой, со страницей Пахомова и с Эдиком, которого пришлось везти из дома за шиворот.",
	"Колесникова взяли через неделю. Дело засекретили: милиционер-убийца в восемьдесят восьмом никому не нужен. В газетах ни строчки.",
	"Ковпака тихо сняли, Рината выпустили в декабре. Нину похоронили на Широкой речке. Галину Сурову я тоже навещаю.",
]
const END_WORD := [
	"В прокуратуре меня выслушали. Сторож на пенсии против офицера милиции. Без свидетеля, с жестянкой чужих волос.",
	"Через неделю бумаги вернули в райотдел, для проверки по месту. Проверять поручили лейтенанту Колесникову.",
	"Я теперь не хожу мимо Шарташа. И сплю со светом.",
]
const END_WRONG := [
	"Дело закрыли за неделю. Рината осудили за убийство, мясо списали на него же.",
	"Коробку из-под монпансье потом в вещдоках не нашли.",
	"А в октябре восемьдесят девятого из гастронома на Сиреневом не вернулась домой продавщица. Участковый закрыл заявление за один день.",
]
const END_DEFENCE := [
	"Меня судили в марте. Убийство сотрудника милиции. Коробку к делу не приобщили: улики добыты неустановленным путём.",
	"Восемь лет усиленного режима. Пишу это в колонии под Нижним Тагилом.",
	"Нина так и не доехала до мамы в Тагил. А я доехал.",
]

const SPARE_BOX := Vector3(9.9, 1.4, 0.04)
const BUTTON_POS := Vector3(11.9, 1.3, 2.05)
const WIRE_CUT := Vector3(6.4, 2.6, 27.94)
const OWN_LOCKER := Vector3(-5.25, 0, 0.75)
const LOCKERS_SPOT := Vector3(-7.2, 0, 1.7)
const PLANSHET := Vector3(2.25, 0.765, 30.3)
const LURKS_5 := [[0, 5], [3, 0], [4, 35]]
const HUNT_EVERY := 30.0
const HIDE_CELLAR := [Vector3(0.45, BackRooms.FLOOR, 33.65), Vector3(-1, 0, -0.2), Vector3(-0.2, BackRooms.FLOOR, 33.9)]

var rooms: BackRooms
## Where the tin is: "locker" (Gordeev's locker 12), "me" (on Gordeev), "him"
## (his map case), "given" (handed to him in the morning).
var box_at := "locker"
var page_taken := false
var planshet_out := false
var planshet_open := false
var wire_cut := false
var wire_found := false
var he_knows := false
var lockers_done := false
var button_pressed := false
var locker_broken := false
## The journal entry (index into JOURNAL), -1 until the morning.
var entry := -1
var edik: Npc
var _edik_state := "prologue"
var _planshet: Node3D
var _planshet_page: Node3D
var _planshet_tin: Node3D
var _lamp: OmniLight3D
var _hunt_t := 20.0
var _taunt_i := 0
var _killed_him := false
## What the earlier nights left.
var known: Dictionary = {}


func _init(m: Node) -> void:
	super(m)
	clues = {"edik": false, "spare": false, "button": false, "wire": false, "planshet": false}
	known = Main.night_clues.duplicate()
	if known.is_empty():
		known = {"panel": true, "wire": true, "prints": true, "box": true, "earring": true, "has_box": true}
	box_at = "locker" if known.get("has_box", true) else "him"


func _ready() -> void:
	super()
	var store: Store = main.store
	main.killer.set_body(Characters.build_killer_unmasked())
	store.add_cellar()
	store._padlock.visible = false
	rooms = BackRooms.new(store)
	rooms.with_body = false
	rooms.vent = true
	rooms.wire_cut = WIRE_CUT
	main.world.add_child(rooms)
	rooms.open_fridge(true)
	rooms.show_broken_lock()
	rooms.open_vent(true)
	rooms.take_tin()
	store.open_cellar(true)
	store.set_interactable("cellar", false)
	store.set_interactable("fridge", false)
	store.set_interactable("body", true, "Осмотреть шкаф")
	store.set_interactable("boots", false)
	store.set_interactable("talk_tamara", false)
	_talked["torn"] = true
	# The spare key is gone: an empty hook behind the glass.
	_key_mesh.visible = false
	store.set_interactable("spare_key", true, "Осмотреть ящик «Ключ при пожаре»")
	store.set_interactable("door_out", false)
	store.add_interactable("wire_cut", Vector3(WIRE_CUT.x, 0, 27.25), "Посмотреть на провод", 1.3, true, false)
	store.add_interactable("locker12", OWN_LOCKER, N5_LOCKER_PROMPT, 1.2, false, box_at == "locker")
	store.add_interactable("alarm", Vector3(11.2, 0, 2.05), "Осмотреть тревожную кнопку", 1.0, false)
	store.add_interactable("talk_edik", Vector3.ZERO, N5_EDIK_PROMPT, 1.6, false, false)
	store.add_interactable("planshet", Vector3(2.25, 0, 29.75), N5_PLANSHET_PROMPT, 1.1, true, false)
	store.add_interactable("hide_cellar", HIDE_CELLAR[2], "Спрятаться за ящиками", 1.0, false)
	store.set_interactable("phone", true, "Снять трубку: позвонить 02")
	_build_button()
	_build_planshet()
	edik = _person("edik")
	if outdoors:
		outdoors.park_bobik()


func _build_button() -> void:
	var k := MeshBuilder.Kit.new()
	var b := BUTTON_POS
	k.b("paint", Color(0.85, 0.83, 0.78)).box(Props.at(b.x, b.y - 0.06, b.z), Vector3(0.03, 0.12, 0.12))
	k.b("paint", Color(0.75, 0.08, 0.06)).cylinder(Props.rot(Vector3.BACK, PI * 0.5, Vector3(b.x - 0.015, b.y, b.z)),
		0.025, 0.025, 0.02, 14)
	k.b("tags", Color(1.1, 1.08, 1.0)).box(Props.at(b.x + 0.005, b.y - 0.2, b.z), Vector3(0.006, 0.1, 0.16),
		Color.WHITE, Rect2(0, 0.5, 0.5, 0.1))
	k.build(main.store, false)
	var label := Label3D.new()
	label.text = "ТРЕВОГА"
	label.font_size = 22
	label.pixel_size = 0.0016
	label.modulate = Color(0.75, 0.08, 0.06)
	label.shaded = true
	label.position = Vector3(b.x - 0.02, b.y + 0.09, b.z)
	label.rotation.y = -PI * 0.5
	main.store.add_child(label)


## His field map case, brown leather with a celluloid window, on Ковпак's
## desk, and what is inside it once opened.
func _build_planshet() -> void:
	_planshet = Node3D.new()
	var k := MeshBuilder.Kit.new()
	var p := PLANSHET
	k.b("leather", Color(0.42, 0.26, 0.16)).box(Props.rot(Vector3.UP, 0.25, p), Vector3(0.26, 0.035, 0.34))
	k.b("glass", Color(0.75, 0.78, 0.7, 0.4), Color.BLACK, Mats.GLASS).box(
		Props.rot(Vector3.UP, 0.25, p + Vector3(0, 0.036, 0)), Vector3(0.2, 0.002, 0.24))
	k.b("leather", Color(0.32, 0.2, 0.12)).box(Props.rot(Vector3.UP, 0.25, p + Vector3(0.18, 0.0, 0.05)), Vector3(0.36, 0.006, 0.03))
	k.build(_planshet, false)
	main.store.add_child(_planshet)
	_planshet_page = Node3D.new()
	var kp := MeshBuilder.Kit.new()
	kp.b("tags", Color(1.05, 1.0, 0.9)).box(Props.rot(Vector3.UP, -0.3, p + Vector3(-0.3, 0.0, -0.05)), Vector3(0.15, 0.002, 0.21),
		Color.WHITE, Rect2(0, 0, 0.5, 0.25))
	kp.b("rubber", Color(0.12, 0.1, 0.08)).cylinder(Props.at(p.x + 0.25, p.y - 0.01, p.z + 0.12), 0.05, 0.05, 0.012, 14)
	kp.build(_planshet_page, false)
	_planshet_page.visible = false
	main.store.add_child(_planshet_page)
	_planshet_tin = Node3D.new()
	var kt := MeshBuilder.Kit.new()
	kt.b("chrome", Color(0.75, 0.55, 0.3)).cylinder(Props.at(p.x - 0.12, p.y, p.z + 0.2), 0.055, 0.055, 0.028, 16)
	kt.build(_planshet_tin, false)
	_planshet_tin.visible = false
	main.store.add_child(_planshet_tin)
	_planshet.visible = false
	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.85, 0.55)
	_lamp.light_energy = 1.4
	_lamp.omni_range = 3.2
	_lamp.position = Vector3(1.85, 1.0, 30.55)
	_lamp.visible = false
	main.store.add_child(_lamp)


# --- timeline -----------------------------------------------------------------

func build_timeline() -> void:
	var m: Node = main
	var hud: Hud = main.hud
	var store: Store = main.store
	m.at(22, 30, _prologue)
	m.at(22, 45, func(): hud.say(N5_G_2245))
	m.at(22, 46, func(): hud.say(N5_G_BOX_HINT if box_at == "locker" else N5_G_BOX_GONE))
	for i in store.rows.size():
		var idx := i
		m.at(22, 50 + i * 3, func():
			store.switch_off(idx)
			hud.say(ROW_LINES[idx]))
	m.at(23, 10, func():
		_killer_in()
		hud.say(N5_G_DOOR, -1.0, true))
	m.at(23, 13, _to_wire)
	for t: Array in LURKS_5:
		m.at(t[0], t[1], _lurk)
	for i in rounds.size():
		var idx := i
		var r: Dictionary = rounds[i]
		m.at_min(r.start, func(): _round_start(idx))
	m.at(0, 30, _to_lockers)
	m.at(1, 30, _to_office)
	m.at(1, 40, _go_out)
	m.at(2, 40, _come_back)
	m.at(4, 0, func(): hud.say(N5_G_0400))
	m.at(5, 30, _leave_for_good)
	m.at(6, 0, _morning)


# --- the prologue ---------------------------------------------------------------

func _prologue() -> void:
	var hud: Hud = main.hud
	var store: Store = main.store
	kovpak_state = "prologue"
	store.car_park()
	kovpak.visible = true
	kovpak.global_position = Vector3(6.3, 0, 2.7)
	kovpak.look_at_point(main.player.global_position)
	edik.visible = true
	edik.global_position = Vector3(-6.6, 0, 1.4)
	edik.look_at_point(Vector3(-6.6, 0, 0))
	hud.say(N5_HANDOVER)
	hud.say(N5_K_FEAR)
	hud.say(N5_G_KOVPAK)
	hud.say(N5_G_EDIK_SEE)
	main.at(22, 33, func():
		if _edik_state == "talking":
			main.after(1.0, func(): _edik_out())
		else:
			_edik_out())
	main.at(22, 37, func():
		_talked["kovpak_walk"] = true
		hud.say(N5_K_LOCK)
		kovpak.walk(PackedVector3Array([Vector3(4.25, 0, 4.0), Vector3(0, 0, 3.0), Vector3(-0.6, 0, 1.2)]))
		await kovpak.arrived
		store.set_front_door(true)
		await get_tree().create_timer(1.6, false).timeout
		kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.4), Vector3(-1.0, 0, -2.0), Vector3(-2.2, 0, -6.5)]))
		await get_tree().create_timer(1.4, false).timeout
		# Колесников steps up from the dark of the porch and shuts the doors himself.
		var koles := _person("kolesnikov")
		koles.visible = true
		koles.global_position = Vector3(0.4, 0, -4.2)
		koles.walk(PackedVector3Array([Vector3(-0.6, 0, -1.6)]))
		await koles.arrived
		store.set_front_door(false)
		Sfx.play_3d(store, "keys", Vector3(-0.6, 1.1, -0.4), -4.0)
		koles.look_at_point(main.player.global_position)
		hud.say(N5_KL_GLASS, -1.0, true)
		await kovpak.arrived
		kovpak.visible = false
		kovpak_state = "done"
		store.car_start()
		await get_tree().create_timer(3.5, false).timeout
		koles.walk(PackedVector3Array([Vector3(2.5, 0, -5.0), Vector3(9.0, 0, -6.0)]))
		store.car_leave()
		hud.say(N5_G_LOCKED)
		await koles.arrived
		koles.visible = false
		if main.phase == Main.Phase.PLAY:
			main.save_checkpoint())


func _edik_out() -> void:
	if _edik_state == "gone":
		return
	_edik_state = "leaving"
	main.hud.say(N5_K_EDIK)
	main.store.set_front_door(true)
	edik.walk(PackedVector3Array([Vector3(-3.0, 0, 1.6), Vector3(-1.0, 0, 0.6), Vector3(-1.0, 0, -2.0), Vector3(-3.5, 0, -7.0)]))
	await edik.arrived
	edik.visible = false
	_edik_state = "gone"
	if kovpak_state == "prologue" and not _talked.has("kovpak_walk"):
		main.store.set_front_door(false)
	update_notebook()


func _talk_edik() -> void:
	var hud: Hud = main.hud
	if clues.edik:
		hud.say(N5_E_BUSY, -1.0, true)
		return
	_edik_state = "talking"
	edik.look_at_point(main.player.global_position)
	clues.edik = true
	hud.say(N5_E_1, -1.0, true)
	hud.say(N5_E_2)
	hud.say(N5_E_3)
	hud.say(N5_G_EDIK)
	update_notebook()
	await get_tree().create_timer(5.0, false).timeout
	if _edik_state == "talking":
		_edik_state = "prologue"


func _process(_delta: float) -> void:
	var store: Store = main.store
	var free := kovpak.visible and not kovpak.walking and not _talked.has("kovpak_walk") and kovpak_state == "prologue"
	store.set_interactable("talk_kovpak", free, "Спросить Ковпака про ключи")
	store.move_interactable("talk_kovpak", kovpak.global_position)
	store.set_interactable("talk_tamara", false)
	var e_free := edik.visible and not edik.walking and _edik_state in ["prologue", "talking"]
	store.set_interactable("talk_edik", e_free, N5_EDIK_PROMPT if not clues.edik else "Эдик")
	store.move_interactable("talk_edik", edik.global_position)


# --- him -------------------------------------------------------------------------------

func _killer_in() -> void:
	super()
	main.store.open_office()
	main.killer.set_torch(true)


## 23:13: up the ladder of crates to the wire on the back wall, as on Sunday.
func _to_wire() -> void:
	var k: Killer = main.killer
	if wire_cut:
		return
	var there := k.is_active() and Vector2(k.global_position.x - WIRE_CUT.x, k.global_position.z - 27.2).length() < 1.6
	if killer_phase == "in" and not there and main.minutes < Main.clock(23, 30) and not main.chasing:
		if k.is_active() and not k.is_lurking():
			k.wander_to(Vector3(WIRE_CUT.x, 0, 27.2))
		main.after(1.0, _to_wire)
		return
	wire_cut = true
	rooms.cut_wire()
	Sfx.play_3d(main.store, "clank", WIRE_CUT, -6.0, 1.4)
	main.hud.say(N5_G_WIRE, -1.0, true)
	update_notebook()


## Every so often he comes looking where Gordeev is, a few metres off, and
## calls out to him from the dark.
func _hunt(delta: float) -> void:
	var k: Killer = main.killer
	if killer_phase != "in" or not k.is_active() or k.leaving or main.chasing or not wire_cut:
		return
	_hunt_t -= delta * main.time_scale
	if _hunt_t > 0.0:
		return
	_hunt_t = HUNT_EVERY * (0.65 if he_knows else 1.0) * randf_range(0.8, 1.2)
	if k.state != Killer.State.PATROL:
		return
	var me: Vector3 = main.player.global_position
	if not _talked.has("hunt"):
		_talked["hunt"] = true
		main.hud.say(N5_G_HUNT)
	elif randf() < 0.6:
		main.hud.say(TAUNTS[_taunt_i % TAUNTS.size()], -1.0, true)
		_taunt_i += 1
	if BackRooms.in_cellar(me):
		Sfx.play_3d(main.store, "heavy_step", Vector3(Store.CELLAR_X, 0.2, 27.5), 0.0, 0.9)
		k.lurk_at(Vector3(Store.CELLAR_X, 0, 27.2), 18.0)
		return
	if main.player.hidden:
		k.wander_to(main.store.random_patrol_point())
		return
	var off := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * randf_range(3.0, 6.0)
	k.wander_to(Vector3(me.x, 0, me.z) + off)


## 00:30: the lockers, one after another, with a crowbar.
func _to_lockers() -> void:
	var k: Killer = main.killer
	if lockers_done:
		return
	if killer_phase != "in" or not k.is_active() or main.chasing or k.leaving:
		main.after(3.0, _to_lockers)
		return
	main.hud.say(N5_G_LOCKERS, -1.0, true)
	k.lurk_at(LOCKERS_SPOT, 30.0)
	# He walks there in real time (about a minute across the hall), whatever the clock does.
	var t := 0.0
	var reached := false
	while t < 75.0 and k.is_active() and not main.chasing:
		await get_tree().create_timer(0.5, false).timeout
		t += 0.5
		if main.phase != Main.Phase.PLAY:
			return
		if Vector2(k.global_position.x - LOCKERS_SPOT.x, k.global_position.z - LOCKERS_SPOT.z).length() < 1.2:
			reached = true
			break
	if not reached or not k.is_active():
		main.after(3.0, _to_lockers)
		return
	for i in 5:
		Sfx.play_3d(main.store, "clank", Vector3(-9.0 + i * 0.8, 1.2, 0.4), -2.0, randf_range(0.8, 1.1))
		main.on_noise(LOCKERS_SPOT, 4.0)
		await get_tree().create_timer(1.4, false).timeout
		if main.phase != Main.Phase.PLAY:
			return
	lockers_done = true
	locker_broken = true
	Sfx.play_3d(main.store, "clank", OWN_LOCKER + Vector3(0, 1.2, -0.4), 0.0, 0.7)
	if box_at == "locker":
		box_at = "him"
		main.hud.say(N5_G_TOOK, -1.0, true)
	else:
		he_knows = true
		_hunt_t = 4.0
		main.hud.say(N5_G_KNOWS, -1.0, true)
	main.store.set_interactable("locker12", true, "Ячейка № 12")
	update_notebook()


## 01:30: he sits a while in Ковпак's office, then goes out to his car.
func _to_office() -> void:
	var k: Killer = main.killer
	if killer_phase == "in" and k.is_active() and not main.chasing:
		k.lurk_at(Vector3(2.4, 0, 29.6), 40.0)


func _go_out() -> void:
	var k: Killer = main.killer
	if killer_phase != "in" or not k.is_active():
		return
	planshet_out = true
	_planshet.visible = true
	_lamp.visible = true
	if box_at == "him":
		_planshet_tin.visible = false
	main.store.set_interactable("planshet", true, N5_PLANSHET_PROMPT)
	k.leave()
	await k.left
	main.store.close_storage_door()
	door_shut_by = "killer"
	killer_phase = "out"
	main.hud.say(N5_G_OUT, -1.0, true)
	update_notebook()


func _come_back() -> void:
	if killer_phase != "out":
		return
	_killer_in()
	main.hud.say(N5_G_BACK, -1.0, true)
	await get_tree().create_timer(4.0, false).timeout
	_back_to_desk()


## Back at the desk, he finds his map case gone through.
func _back_to_desk() -> void:
	if not planshet_open or he_knows:
		_put_planshet_away()
		return
	he_knows = true
	_hunt_t = 4.0
	main.hud.say(N5_G_BACK_KNOWS, -1.0, true)
	_put_planshet_away()
	update_notebook()


func _put_planshet_away() -> void:
	planshet_out = false
	_planshet.visible = false
	_planshet_page.visible = false
	_planshet_tin.visible = false
	_lamp.visible = false
	main.store.set_interactable("planshet", false)


func _leave_for_good() -> void:
	var k: Killer = main.killer
	if not k.is_active():
		return
	k.leave()
	await k.left
	main.store.close_storage_door()
	killer_phase = "gone"
	main.hud.say(N5_G_0530, -1.0, true)


## The alarm button: summons him, wherever he is.
func _press_button() -> void:
	var hud: Hud = main.hud
	button_pressed = true
	Sfx.play_3d(main.view, "click", BUTTON_POS, -4.0, 0.8)
	hud.say(N5_G_PRESSED, -1.0, true)
	main.store.set_interactable("alarm", true, "Тревожная кнопка")
	update_notebook()
	await get_tree().create_timer(6.0, false).timeout
	if main.phase != Main.Phase.PLAY:
		return
	var k: Killer = main.killer
	if killer_phase == "out":
		_killer_in()
		_put_planshet_away()
	if k.is_active() and not k.leaving:
		hud.say(N5_G_CAME, -1.0, true)
		k.hear(Vector3(10.0, 0, 3.0), 80.0)


# --- interactions -----------------------------------------------------------------

func interact(id: String) -> bool:
	var hud: Hud = main.hud
	var store: Store = main.store
	match id:
		"talk_kovpak":
			if not _talked.has("kovpak"):
				_talked["kovpak"] = true
				kovpak.look_at_point(main.player.global_position)
				hud.say("Ковпак: — Не спрашивай, Гордеев. Он сказал, проверка. Я ему ключи, он мне спокойную жизнь.", -1.0, true)
			else:
				hud.say(K_BUSY, -1.0, true)
		"talk_edik":
			_talk_edik()
		"spare_key":
			if clues.spare:
				hud.say(N5_SPARE_AGAIN, -1.0, true)
			else:
				Sfx.play_3d(main.view, "pickup", SPARE_BOX, -10.0, 1.2)
				_find_clue("spare", N5_CLUE_SPARE)
		"door_front", "door_out":
			hud.say(N5_DOOR, -1.0, true)
		"phone":
			_call()
		"wire_cut":
			store.set_interactable("wire_cut", false)
			wire_found = true
			_find_clue("wire", N5_CLUE_WIRE)
		"alarm":
			if not clues.button:
				_find_clue("button", N5_CLUE_BUTTON)
				store.set_interactable("alarm", true, N5_BUTTON_PROMPT)
			elif not button_pressed:
				_press_button()
			else:
				hud.say(N5_G_PRESSED_AGAIN, -1.0, true)
		"locker12":
			if box_at == "locker":
				box_at = "me"
				Sfx.play_3d(main.view, "clank", OWN_LOCKER + Vector3(0, 1, -0.3), -10.0, 1.4)
				hud.say(N5_G_GOT, -1.0, true)
				store.set_interactable("locker12", false)
				update_notebook()
			elif locker_broken:
				hud.say(N5_LOCKER_BROKEN, -1.0, true)
		"planshet":
			_open_planshet()
		"office_door":
			hud.say(N5_OFFICE_DARK, -1.0, true)
		"body":
			hud.say("Шкаф пустой. Пятно на дне так и не отмыли.", -1.0, true)
		"hide_cellar":
			main.hide_in({"id": id, "pos": HIDE_CELLAR[0], "face": HIDE_CELLAR[1], "out": HIDE_CELLAR[2]})
			if main.player.hidden and not _talked.has("hid"):
				_talked["hid"] = true
				hud.say(G_HIDE)
		_:
			return super(id)
	return true


func _call() -> void:
	var hud: Hud = main.hud
	Sfx.play_3d(main.view, "pickup", main.store.phone_pos, -4.0)
	if wire_cut:
		if not wire_found:
			wire_found = true
			hud.say(NightFour.N4_PH_DEAD, -1.0, true)
			main.store.set_interactable("wire_cut", not clues.wire)
		else:
			hud.say(NightFour.N4_PH_AGAIN, -1.0, true)
		update_notebook()
		return
	if _talked.has("called"):
		hud.say(N5_G_DUTY, -1.0, true)
		return
	_talked["called"] = true
	hud.say(N5_PH_02, -1.0, true)
	hud.say(N5_PH_DUTY)
	hud.say(N5_G_DUTY)
	update_notebook()


func _open_planshet() -> void:
	var hud: Hud = main.hud
	if not planshet_open:
		planshet_open = true
		Sfx.play_3d(main.view, "cloth", PLANSHET, -12.0, 1.3)
		_planshet_page.visible = true
		_planshet_tin.visible = box_at == "him"
		_find_clue("planshet", N5_CLUE_PLANSHET)
		hud.say(N5_CLUE_PAGE)
		if box_at == "him":
			hud.say(N5_G_TIN_HERE)
		main.store.set_interactable("planshet", true, N5_TAKE_PROMPT)
		return
	if not page_taken:
		page_taken = true
		Sfx.play_3d(main.view, "cloth", main.player.global_position + Vector3(0, 1.1, 0), -10.0, 1.1)
		_planshet_page.visible = false
		if box_at == "him":
			box_at = "me"
			_planshet_tin.visible = false
			hud.say(N5_G_TAKE, -1.0, true)
		else:
			hud.say(N5_G_TAKE_PAGE, -1.0, true)
		main.store.set_interactable("planshet", true, "Планшет")
		update_notebook()
		return
	hud.say(N5_PLANSHET_EMPTY, -1.0, true)


func update(delta: float) -> void:
	super(delta)
	_hunt(delta)


# --- self-defence ---------------------------------------------------------------

## Gordeev has just torn free and he is down: run, or finish it.
func on_tore_free() -> bool:
	var hud: Hud = main.hud
	get_tree().paused = true
	var pick := await hud.choose(N5_FIGHT_HEAD, _labels(N5_FIGHT))
	get_tree().paused = false
	if pick == 0:
		return false
	_killed_him = true
	main.phase = Main.Phase.END
	var k: Killer = main.killer
	main.player.controllable = false
	main.player.busy = true
	k.deactivate()
	main.chasing = false
	hud.set_prompt("")
	hud.clear_subtitles()
	var p := k.global_position
	for i in 2:
		Sfx.play_3d(main.view, "chop", p + Vector3(0, 0.6, 0), 2.0, randf_range(0.9, 1.0))
		main._flash = 1.0
		main.store.spawn_blood(p + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)), 0.35)
		await get_tree().create_timer(0.45).timeout
	# He goes down on his back, the cap rolls off.
	var tw := create_tween().set_parallel()
	tw.tween_property(k.body, "rotation:x", -PI * 0.5, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(k.body, "position:y", 0.15, 0.6)
	Sfx.play_3d(main.view, "bodyfall", p + Vector3(0, 0.2, 0), 2.0)
	var pool: MeshInstance3D = main.store.spawn_blood(p, 0.2)
	create_tween().tween_property(pool, "scale", Vector3(8, 1, 8), 4.0).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.5).timeout
	hud.say(N5_G_STRIKE, -1.0, true)
	await get_tree().create_timer(4.0).timeout
	_ending("defence")
	return true


# --- the task list, the rings, the notebook ------------------------------------------

func objectives() -> Array:
	var out: Array = []
	if kovpak_state == "prologue" and _edik_state in ["prologue", "talking"] and not clues.edik:
		out.append(task("Эдик у камеры хранения: спросить его про седьмое (E), пока не ушёл", false, false, true))
	var found := clue_count()
	out.append(task("Улики: %d из %d" % [found, clues.size()], found == clues.size()))
	if box_at == "locker":
		out.append(task("Забрать коробку из своей ячейки № 12 (камера хранения, слева у входа)", false, false,
			main.minutes > Main.clock(23, 0)))
	elif box_at == "him" and not planshet_out:
		out.append(task("Коробка у него. Он где-то держит её при себе"))
	if planshet_out and (not planshet_open or not page_taken):
		out.append(task("Кабинет директора открыт, горит лампа: посмотреть на столе, пока его нет (до 02:40)", false, false, true))
	if not clues.spare:
		out.append(task("Ящик «Ключ при пожаре» на посту", false, true))
	if not clues.button:
		out.append(task("Тревожная кнопка на посту, у телефона", false, true))
	if not wire_cut:
		out.append(task("Телефон на посту: позвонить 02", _talked.has("called"), true))
	elif wire_found and not clues.wire:
		out.append(task("Пройти по проводу от поста по правой стене до задней: где обрыв", false, true))
	elif not wire_found:
		out.append(task("Телефон на посту: позвонить 02", false, true))
	var kp: Vector3 = main.killer.global_position
	if main.killer.is_active() and not main.player.hidden and BackRooms.in_cellar(main.player.global_position) \
			and kp.z > 26.0 and absf(kp.x - Store.CELLAR_X) < 4.0:
		out.append(task("Он у подвала: спрятаться за ящиками (E), погасить фонарь", false, false, true))
	_round_tasks(out)
	if killer_phase == "in":
		var hint := task("Он с фонарём: не попадать в луч, пригнуться (C), прятаться (E). Схватит: жать E")
		hint["hint"] = true
		out.append(hint)
	return out


func clue_marks() -> Array:
	var out: Array = []
	if not clues.spare:
		out.append(SPARE_BOX + Vector3(0, 0.02, 0.06))
	if not clues.button:
		out.append(BUTTON_POS + Vector3(-0.05, 0, 0))
	if box_at == "locker":
		out.append([OWN_LOCKER + Vector3(0, 0.9, -0.3), 8.0])
	if planshet_out and not page_taken:
		out.append([PLANSHET + Vector3(0, 0.05, 0), 6.0])
	if wire_found and not clues.wire:
		for p: Vector3 in BackRooms.wire_points():
			if p.z > 20.0:
				out.append([p, 9.0])
		out.append([WIRE_CUT + Vector3(0, -0.6, 0), 9.0])
	if kovpak_state == "prologue" and edik.visible and not clues.edik:
		out.append([edik.global_position + Vector3(0, 1.9, 0), 12.0])
	_round_marks(out)
	return out


func final_entry() -> String:
	return "Колесников. Участковый МЖК, лейтенант милиции. Нина, Сурова и ещё две. Свидетель есть, коробка есть, страница Пахомова есть. Дожить до утра."


func update_notebook() -> void:
	var lines := PackedStringArray([
		"БЛОКНОТ ГОРДЕЕВА", "Ночь пятая, 26 октября 1988, среда", ""])
	var r := current_round()
	lines.append("Обходы (дверь склада, щиток, подпись в журнале):")
	for i in rounds.size():
		var rd: Dictionary = rounds[i]
		var mark := "[x]" if rd.signed else ("[  ]" if i >= r else "[–]")
		lines.append("%s %s" % [mark, ROUND_NAMES[i]])
	lines.append("")
	lines.append("Что я знаю: Нину убил Колесников. Его жестянка из подвала: четыре пряди и серьга Суровой.")
	lines.append("")
	lines.append("Улики: %d из 5" % clue_count())
	if clues.edik:
		lines.append("— Эдик: 7-го в 22:40 Нина сама открыла заднее крыльцо участковому в форме. Даст показания только прокурору.")
	if clues.spare:
		lines.append("— Запасной ключ от входа сняли днём, пломбу повесили обратно. Выйти нельзя.")
	if clues.button:
		lines.append("— Тревожная кнопка идёт на пульт РОВД. Ответственный сегодня он.")
	if _talked.has("called"):
		lines.append("— Дежурная по 02 обещала передать Колесникову.")
	if clues.wire:
		lines.append("— Провод перерезан на задней стене второй раз.")
	elif wire_found:
		lines.append("— Телефон молчит.")
	if clues.planshet:
		lines.append("— Его планшет: схема с тремя крестиками, новый шнурок и вырванная страница за 7-е: «22:35 у заднего крыльца милицейский УАЗ».")
	lines.append("")
	match box_at:
		"locker":
			lines.append("Коробка в моей ячейке № 12.")
		"me":
			lines.append("Коробка у меня за пазухой." + (" Страница Пахомова тоже." if page_taken else ""))
		"him":
			lines.append("Коробка у него.")
	if he_knows:
		lines.append("Он знает, что коробка у меня.")
	if not clues.values().has(false):
		lines.append("")
		lines.append(final_entry())
	lines.append("")
	lines.append("Tab: закрыть")
	main.hud.set_notebook("\n".join(lines))


# --- morning and the endings ------------------------------------------------------

func _morning() -> void:
	var store: Store = main.store
	var hud: Hud = main.hud
	_come_in()
	if BackRooms.in_cellar(main.player.global_position) or not store.booth_rect.has_point(
			Vector2(main.player.global_position.x, main.player.global_position.z)):
		main.player.global_position = Vector3(10.3, 0, 3.4)
	main.player.face(Vector3(0.3, 0, -1))
	main.begin_morning()
	if main.killer.is_active():
		main.killer.deactivate()
		main.killer.visible = false
	store.close_storage_door()
	hud.say(N5_G_JOURNAL, -1.0, true)
	await get_tree().create_timer(3.0, false).timeout
	Sfx.play_3d(main.view, "pickup", main.player.global_position, -8.0)
	entry = await hud.choose(JOURNAL_HEAD, _labels(JOURNAL))
	hud.say(N5_G_WROTE, -1.0, true)
	await get_tree().create_timer(4.0, false).timeout
	# He opens up himself, Ковпак and Вася behind him.
	store.car_arrive()
	var koles := _person("kolesnikov")
	koles.visible = true
	koles.global_position = Vector3(-0.6, 0, -2.6)
	vasya.visible = true
	vasya.global_position = Vector3(-1.6, 0, -3.6)
	kovpak.visible = true
	kovpak.global_position = Vector3(-2.4, 0, -4.6)
	await get_tree().create_timer(3.0, false).timeout
	Sfx.play_3d(store, "keys", Vector3(-0.6, 1.1, -0.4), -2.0)
	hud.say(N5_V_KNOCK, -1.0, true)
	await get_tree().create_timer(2.0, false).timeout
	store.set_front_door(true)
	koles.walk(PackedVector3Array([Vector3(-0.8, 0, 0.6), Vector3(1.6, 0, 2.6), Vector3(6.2, 0, 3.0)]))
	vasya.walk(PackedVector3Array([Vector3(-0.8, 0, 0.6), Vector3(0.6, 0, 2.6), Vector3(2.4, 0, 4.4)]))
	kovpak.walk(PackedVector3Array([Vector3(-1.0, 0, 0.6), Vector3(0.4, 0, 2.2), Vector3(3.6, 0, 4.2)]))
	store.switch_on(5)
	await koles.arrived
	koles.look_at_point(main.player.global_position)
	kovpak.look_at_point(koles.global_position)
	vasya.look_at_point(koles.global_position)
	hud.say(N5_KL_OPEN)
	hud.say(N5_KL_READ[entry])
	if entry == 2:
		hud.say(N5_K_PALE)
	if entry == 3:
		hud.say(N5_G_SMILE)
	await _wait_voice()
	var gave := false
	if box_at == "me" or box_at == "locker":
		hud.say(N5_KL_BOX)
		await _wait_voice()
		var pick := await hud.choose(BOX_HEAD, _labels(BOX))
		gave = pick == 0
		if gave:
			box_at = "given"
			hud.say(N5_G_GAVE, -1.0, true)
		else:
			hud.say(N5_G_KEPT, -1.0, true)
			hud.say(N5_KL_LATER)
	else:
		hud.say(N5_KL_NOBOX)
	await _wait_voice()
	koles.walk(PackedVector3Array([Vector3(1.6, 0, 2.6), Vector3(-0.8, 0, 0.6), Vector3(-1.0, 0, -3.0)]))
	await get_tree().create_timer(4.0, false).timeout
	if entry in [1, 2] or gave:
		_ending("wrong")
	elif (box_at == "me" or box_at == "locker") and clues.edik:
		_ending("prosecutor")
	else:
		_ending("word")


static func _labels(a: Array) -> Array[String]:
	var out: Array[String] = []
	out.assign(a)
	return out


## Waits until every queued subtitle has been said.
func _wait_voice() -> void:
	var hud: Hud = main.hud
	await get_tree().create_timer(0.5, false).timeout
	var t := 0.0
	while (not hud._queue.is_empty() or hud.subtitle.text != "") and t < 60.0:
		await get_tree().create_timer(0.25, false).timeout
		t += 0.25
	await get_tree().create_timer(0.6, false).timeout


func _ending(kind: String) -> void:
	var hud: Hud = main.hud
	main.phase = Main.Phase.END
	main.checkpoint = {}
	main.player.controllable = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_prompt("")
	hud.fade_to(1.0, 2.5)
	await get_tree().create_timer(3.0).timeout
	var lines: Array = {"prosecutor": END_PROSECUTOR, "word": END_WORD, "wrong": END_WRONG, "defence": END_DEFENCE}[kind]
	for l: String in lines:
		hud.say(l, -1.0, false)
	await _wait_voice()
	main.end_game(kind, summary())


func summary() -> String:
	return "Улик найдено: %d из %d. Обходов подписано: %d из %d." % [clue_count(), clues.size(), rounds_signed(), rounds.size()]


# --- saving at the journal ------------------------------------------------------

func save_state() -> Dictionary:
	var d := super()
	d["box_at"] = box_at
	d["page_taken"] = page_taken
	d["planshet_open"] = planshet_open
	d["planshet_out"] = planshet_out
	d["wire_cut"] = wire_cut
	d["wire_found"] = wire_found
	d["he_knows"] = he_knows
	d["lockers_done"] = lockers_done
	d["locker_broken"] = locker_broken
	d["button_pressed"] = button_pressed
	d["edik_state"] = _edik_state
	return d


func restore_state(d: Dictionary) -> void:
	var store: Store = main.store
	super(d)
	kovpak_state = "done"
	_edik_state = "gone"
	box_at = d.get("box_at", box_at)
	page_taken = d.get("page_taken", false)
	planshet_open = d.get("planshet_open", false)
	wire_cut = d.get("wire_cut", false)
	wire_found = d.get("wire_found", false)
	he_knows = d.get("he_knows", false)
	lockers_done = d.get("lockers_done", false)
	locker_broken = d.get("locker_broken", false)
	button_pressed = d.get("button_pressed", false)
	_key_mesh.visible = false
	store.set_interactable("spare_key", true, "Осмотреть ящик «Ключ при пожаре»")
	store.set_interactable("door_out", false)
	store.set_interactable("locker12", box_at == "locker" or locker_broken,
		N5_LOCKER_PROMPT if box_at == "locker" else "Ячейка № 12")
	if clues.button:
		store.set_interactable("alarm", true, "Тревожная кнопка" if button_pressed else N5_BUTTON_PROMPT)
	if wire_cut:
		rooms.cut_wire()
	elif main.minutes >= Main.clock(23, 13):
		main.after(1.0, _to_wire)
	store.set_interactable("wire_cut", wire_found and not clues.wire)
	if killer_phase == "in":
		main.killer.set_torch(true)
		store.open_office(true)
	if d.get("planshet_out", false) and killer_phase == "out":
		planshet_out = true
		_planshet.visible = true
		_lamp.visible = true
		_planshet_page.visible = planshet_open and not page_taken
		_planshet_tin.visible = planshet_open and box_at == "him"
		store.set_interactable("planshet", true, N5_PLANSHET_PROMPT if not planshet_open
			else (N5_TAKE_PROMPT if not page_taken else "Планшет"))
		store.open_office(true)
	if not lockers_done and main.minutes >= Main.clock(0, 30):
		main.after(2.0, _to_lockers)
	update_notebook()
