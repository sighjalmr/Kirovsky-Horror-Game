class_name Deductions
extends RefCounted

## What Gordeev concludes at six in the morning after each night: one
## question, three answers, one of them right. The answer goes into the
## notebook, changes what he says at the start of the next shift and counts
## towards the endings (Main.deductions, kept in the save file).
## Also the right-hand page of the notebook: the people and the conclusions.

## night -> [question, [answers], index of the right one, [line next night if right, if wrong]]
const QUESTIONS := {
	"night1": ["Что случилось с Ниной седьмого октября?", [
		"Уехала к маме в Тагил, как сказали в милиции",
		"Её убили здесь, после закрытия, свой человек с ключами",
		"Уволилась и уехала с Ковпаком",
	], 1, ["Нину убили в магазине, после закрытия. Значит, убийца ходит сюда, как к себе домой.",
		"Может, и правда уехала. Только сумку без ключей и денег не бросают."]],
	"night2": ["Кто входит ночью через склад?", [
		"Мясник Ринат: ключ от склада у него",
		"Ковпак: склад его, он сам так говорит",
		"Третий человек: у него свой ключ, и Ковпак его боится",
	], 2, ["Ключей от склада три. Найду, у кого третий, найду его.",
		"Слежу за складом. Если это он, рано или поздно ошибётся."]],
	"night3": ["Почему Рината взяли так быстро?", [
		"Он и есть убийца: бумага с его пометкой, ключ у него",
		"Его подставили: шнурок и срезанная прядь не его почерк",
		"Ковпак сдал его, чтобы прикрыть говядину",
	], 1, ["Рината подставили. Кто-то знал, где лежит Нина, и знал, кого назначить.",
		"Рината взяли. А мне всё равно не спится на этом посту."]],
	"night4": ["Кто убивает женщин на МЖК с восемьдесят пятого?", [
		"Ринат: шнурок мог быть и его",
		"Ковпак: всё в этом магазине идёт через него",
		"Человек в форме: тот, кто сам потом закрывает эти дела",
	], 2, ["Человек в форме. Как сказала тогда свидетельница по Суровой. Я знаю, кто это.",
		"Почти понял. Не хватает одного шага."]],
}

## The people on the right-hand page and what Gordeev thinks of them by now.
const PEOPLE := [
	["Ковпак", "директор. Ключи, говядина, «Волга»"],
	["Вася Кран", "грузчик. Всегда первый утром"],
	["Ринат", "мясник. Бумага с пометкой «Р.»"],
	["Колесников", "участковый. Слишком быстро закрывает дела"],
	["Эдик", "фарцовщик. Что-то видел седьмого"],
	["Тамара Ивановна", "кассир. Последней видела Нину"],
]


static func question(ch: String) -> Array:
	return QUESTIONS.get(ch, [])


static func right(ch: String, pick: int) -> bool:
	var q := question(ch)
	return not q.is_empty() and pick == int(q[2])


## Gordeev's thought at the start of the next shift about last night's answer.
static func echo(prev: String, d: Dictionary) -> String:
	if not d.has(prev):
		return ""
	var q := question(prev)
	return q[3][0] if right(prev, int(d[prev])) else q[3][1]


static func count_right(d: Dictionary) -> int:
	var n := 0
	for ch: String in d:
		if right(ch, int(d[ch])):
			n += 1
	return n


## The right-hand page: people (struck through once cleared) and conclusions.
static func people_page(ch: String, d: Dictionary) -> String:
	var order := ["night1", "day1", "night2", "day2", "night3", "day3", "night4", "night5"]
	var at := maxi(0, order.find(ch))
	var out := PackedStringArray(["[b]ЛЮДИ[/b]"])
	for p: Array in PEOPLE:
		var who: String = p[0]
		var note: String = p[1]
		var cleared := false
		match who:
			"Тамара Ивановна":
				cleared = at >= order.find("night2")
				if cleared:
					note = "свидетель, не убийца"
			"Ринат":
				if at >= order.find("night4"):
					note = "в СИЗО. " + ("Подставили" if right("night3", int(d.get("night3", -1))) else "Взяли быстро")
				cleared = right("night3", int(d.get("night3", -1)))
			"Эдик":
				cleared = at >= order.find("night5")
				if cleared:
					note = "свидетель: видел, кому Нина открыла"
			"Вася Кран":
				cleared = at >= order.find("night3")
				if cleared:
					note = "нашёл Нину. Испугался больше всех"
		out.append(("[s][color=#5c5a52]%s[/color][/s] — %s" if cleared else "%s — %s") % [who, note])
	out.append("")
	out.append("[b]МОИ ВЫВОДЫ[/b]")
	if d.is_empty():
		out.append("Пока никаких. Утром запишу, что понял за ночь.")
	for k: String in ["night1", "night2", "night3", "night4"]:
		if d.has(k):
			var q := question(k)
			out.append("%s — %s" % [q[0], q[1][int(d[k])]])
	return "\n".join(out)
