class_name GameMenu
extends CanvasLayer

## The title menu and the pause menu (Esc), with their pages: settings,
## chapters, the keys, and "are you sure". Drawn over everything and works
## while the game is paused. Main listens to `picked` and does the rest:
## "continue", "new", "new_sure", "chapter:<id>", "resume", "to_title", "quit".

signal picked(id: String)

const PAPER := Color(0.89, 0.87, 0.8)
const DIM := Color(0.62, 0.63, 0.56)
const HOVER := Color(1.0, 0.85, 0.55)

## Chapter ids in story order with their names in the chapter list.
const CHAPTERS := [
	["night1", "Ночь первая. Пятница, 14 октября"],
	["day1", "День первый. Суббота, 15 октября"],
	["night2", "Ночь вторая. Понедельник, 17 октября"],
	["day2", "День второй. Вторник, 18 октября"],
	["night3", "Ночь третья. Четверг, 20 октября"],
	["day3", "День третий. Пятница, 21 октября"],
	["night4", "Ночь четвёртая. Воскресенье, 23 октября"],
	["night5", "Ночь пятая, последняя. Среда, 26 октября"],
]

const KEYS := "Мышь — смотреть      W / A / S / D — идти\n" + \
	"Shift — бег (шумно и недолго: одышка)\nC — пригнуться (тихо)\n" + \
	"F или правая кнопка мыши (держать) — фонарик-«жучок» (жужжит, его слышно)\n" + \
	"E — осмотреть, поговорить, спрятаться\nQ — бросить банку или бутылку (если в руке)\n" + \
	"V — валидол (одышка и дрожь проходят)\n" + \
	"M — план эвакуации (когда осмотрен на посту)\n" + \
	"Tab — блокнот      J — что делать      Esc — пауза"

## "title" or "pause": where Back from a sub-page returns.
var mode := "title"
## Lines for the title page, filled by Main before show_title_menu().
var continue_label := ""
var has_progress := false

var _bg: ColorRect
var _panel: VBoxContainer
var _heading: Label
var _prev_paused := false
## On a sub-page (settings, chapters, keys, a question): Esc goes back.
var _sub := false
var _swatch: HBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.0)
	_bg.size = Vector2(1920, 1080)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_heading = Label.new()
	_heading.position = Vector2(560, 470)
	_heading.size = Vector2(800, 50)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.add_theme_font_size_override("font_size", 26)
	_heading.add_theme_color_override("font_color", DIM)
	add_child(_heading)
	_panel = VBoxContainer.new()
	_panel.position = Vector2(560, 530)
	_panel.size = Vector2(800, 500)
	_panel.add_theme_constant_override("separation", 4)
	add_child(_panel)
	visible = false


func is_open() -> bool:
	return visible


# --- pages -------------------------------------------------------------------------

func show_title_menu() -> void:
	mode = "title"
	visible = true
	_bg.color.a = 0.0
	_page("", Vector2(560, 560))
	if has_progress:
		_button(continue_label, "continue")
	if has_progress:
		_button("Новая игра", _ask_new)
	else:
		_button("Новая игра", "new")
	if Settings.reached.size() > 1:
		_button("Главы", _chapters)
	_button(Stats.tr_text(Stats.UI.menu), _achievements)
	_button("Настройки", _settings)
	_button("Управление", _keys)
	_button("Выход", "quit")
	_focus_first()


func open_pause() -> void:
	mode = "pause"
	_prev_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause_page()


func _pause_page() -> void:
	_bg.color.a = 0.72
	_page("ПАУЗА", Vector2(560, 380))
	_button("Продолжить", "resume")
	_button(Stats.tr_text(Stats.UI.menu), _achievements)
	_button("Настройки", _settings)
	_button("Управление", _keys)
	_button("Выйти в главное меню", _ask_title)
	_button("Выйти из игры", _ask_quit)
	_focus_first()


func _ask_new() -> void:
	_sure("Начать с первой ночи? Сохранение смены пропадёт, открытые главы останутся.", "new")


func _ask_title() -> void:
	_sure("Выйти в главное меню? Смена продолжится с последней подписи в журнале.", "to_title")


func _ask_quit() -> void:
	_sure("Выйти из игры? Смена продолжится с последней подписи в журнале.", "quit")


func close() -> void:
	visible = false
	if mode == "pause":
		get_tree().paused = _prev_paused
		if not _prev_paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _back() -> void:
	_bg.color.a = 0.0
	if mode == "pause":
		_pause_page()
	else:
		show_title_menu()


## Esc: back from a sub-page, or out of the pause menu.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _sub:
		_back()
	elif mode == "pause":
		picked.emit("resume")


func _chapters() -> void:
	_page("ГЛАВЫ", Vector2(560, 380))
	for c: Array in CHAPTERS:
		if c[0] in Settings.reached:
			_button(c[1], "chapter:" + c[0])
	_button("Назад", _back, true)
	_focus_first()


## Every achievement in two columns: earned ones bright with a gold mark,
## the rest dim; secret ones keep their name to themselves until earned.
func _achievements() -> void:
	_page(Stats.tr_text(Stats.UI.achievements), Vector2(150, 150))
	_heading.position = Vector2(460, 80)
	_dark()
	var count := Label.new()
	count.text = Stats.tr_text(Stats.UI.earned) % [Stats.earned.size(), Stats.ACHIEVEMENTS.size()]
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 24)
	count.add_theme_color_override("font_color", DIM)
	_panel.add_child(count)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 60)
	grid.add_theme_constant_override("v_separation", 10)
	_panel.add_child(grid)
	for a: Array in Stats.ACHIEVEMENTS:
		var got: bool = a[0] in Stats.earned
		var secret: bool = a[3] and not got
		grid.add_child(_achievement_cell(
			Stats.tr_text(Stats.UI.secret) if secret else Stats.tr_text(a[1]),
			Stats.tr_text(Stats.UI.secret_desc) if secret else Stats.tr_text(a[2]), got))
	_bottom_buttons(Stats.tr_text(Stats.UI.to_stats), _statistics)
	_focus_first()


func _achievement_cell(name_text: String, desc: String, got: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(780, 0)
	var mark := Panel.new()
	mark.custom_minimum_size = Vector2(22, 22)
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.68, 0.3) if got else Color(0, 0, 0, 0)
	sb.border_color = Color(0.86, 0.68, 0.3) if got else Color(0.4, 0.4, 0.37)
	sb.set_border_width_all(2)
	mark.add_theme_stylebox_override("panel", sb)
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_top", 6)
	wrap.add_child(mark)
	row.add_child(wrap)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var n := Label.new()
	n.text = name_text
	n.add_theme_font_size_override("font_size", 26)
	n.add_theme_color_override("font_color", PAPER if got else Color(0.6, 0.6, 0.55))
	col.add_child(n)
	var d := Label.new()
	d.text = desc
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 19)
	d.add_theme_color_override("font_color", Color(0.72, 0.72, 0.66) if got else Color(0.5, 0.5, 0.47))
	col.add_child(d)
	return row


## The counters: what was done on the left, clues, conclusions and endings right.
func _statistics() -> void:
	_page(Stats.tr_text(Stats.UI.stats), Vector2(250, 180))
	_heading.position = Vector2(460, 110)
	_dark()
	var lines := Stats.stat_lines()
	var split := lines.find("")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 80)
	_panel.add_child(cols)
	for part: PackedStringArray in [lines.slice(0, split), lines.slice(split + 1)]:
		var l := Label.new()
		l.text = "\n".join(part)
		l.custom_minimum_size = Vector2(660, 0)
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", PAPER)
		l.add_theme_constant_override("line_spacing", 6)
		l.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		cols.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 24)
	_panel.add_child(gap)
	_bottom_buttons(Stats.tr_text(Stats.UI.to_achievements), _achievements)
	_focus_first()


## Long lists of small print need the hall behind them nearly black.
func _dark() -> void:
	_bg.color.a = maxf(_bg.color.a, 0.9)


## [other page] [Назад] in a row under a page.
func _bottom_buttons(other: String, go: Callable) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 80)
	_panel.add_child(row)
	var a := _button(other, go)
	_panel.remove_child(a)
	row.add_child(a)
	var b := _button(Stats.tr_text(Stats.UI.back), _back, true)
	_panel.remove_child(b)
	row.add_child(b)


func _keys() -> void:
	_page("УПРАВЛЕНИЕ", Vector2(460, 360))
	var l := Label.new()
	l.text = KEYS
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", PAPER)
	_panel.add_child(l)
	_button("Назад", _back, true)
	_focus_first()


func _sure(question: String, id: String) -> void:
	_page(question, Vector2(560, 470))
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button("Да", id)
	_button("Нет", _back, true)
	_focus_first(1)


func _settings() -> void:
	_page("НАСТРОЙКИ", Vector2(460, 210))
	_option("Язык субтитров и текста", Loc.NAMES, Settings.language, _set_language, false)
	_slider("Общая громкость", 0.0, 1.0, Settings.master, _set_master)
	_slider("Звуки", 0.0, 1.0, Settings.sounds, _set_sounds)
	_slider("Голоса", 0.0, 1.0, Settings.voice, _set_voice)
	_slider("Скорость мыши", 0.3, 2.5, Settings.mouse, _set_mouse)
	_toggle("Перевернуть мышь по вертикали", Settings.invert_y, _set_invert)
	_toggle("Во весь экран", Settings.fullscreen, _set_fullscreen)
	_option("Разрешение", Settings.RESOLUTION_NAMES, Settings.resolution, _set_resolution)
	_slider("Яркость", 0.7, 1.5, Settings.brightness, _set_brightness)
	_panel.add_child(_brightness_swatch())
	_toggle("Субтитры", Settings.subtitles, _set_subtitles)
	_option("Размер субтитров", ["обычный", "крупный", "очень крупный"], Settings.sub_size, _set_sub_size)
	_toggle("Подсказки по управлению", Settings.hints, _set_hints)
	_toggle("Режим «Следователь»: без колец у улик и без счётчика", Settings.detective, _set_detective)
	_button("Готово", _settings_done, true)
	_focus_first()


## Subtitles and every word on the screen change at once; the voices stay.
func _set_language(i: int) -> void:
	Settings.language = i
	Loc.apply()
	picked.emit("apply")


func _set_master(v: float) -> void:
	Settings.master = v
	Settings.apply_audio()


func _set_sounds(v: float) -> void:
	Settings.sounds = v


func _set_voice(v: float) -> void:
	Settings.voice = v
	Settings.apply_audio()


func _set_mouse(v: float) -> void:
	Settings.mouse = v


func _set_invert(on: bool) -> void:
	Settings.invert_y = on


func _set_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	picked.emit("apply")


func _set_resolution(i: int) -> void:
	Settings.resolution = i
	picked.emit("apply")


func _set_brightness(v: float) -> void:
	Settings.brightness = v
	_update_swatch()
	picked.emit("apply")


func _set_subtitles(on: bool) -> void:
	Settings.subtitles = on
	picked.emit("apply")


func _set_sub_size(i: int) -> void:
	Settings.sub_size = i
	picked.emit("apply")


func _set_hints(on: bool) -> void:
	Settings.hints = on


func _set_detective(on: bool) -> void:
	Settings.detective = on
	picked.emit("apply")


func _settings_done() -> void:
	Settings.save()
	_back()


## Three grey squares on black: the middle one should be only just visible.
func _brightness_swatch() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var hint := Label.new()
	hint.text = "Средний квадрат должен быть едва виден:"
	hint.custom_minimum_size = Vector2(560, 0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", DIM)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hint.add_theme_constant_override("outline_size", 4)
	row.add_child(hint)
	for v: float in [0.0, 0.035, 0.09]:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(44, 28)
		r.color = Color(v, v, v)
		r.set_meta("v", v)
		row.add_child(r)
	_swatch = row
	_update_swatch()
	return row


## The squares through the same gamma the world gets.
func _update_swatch() -> void:
	if not is_instance_valid(_swatch):
		return
	for c in _swatch.get_children():
		if c is ColorRect:
			var g: float = pow(float(c.get_meta("v")) + 0.075, 1.0 / Settings.brightness)
			(c as ColorRect).color = Color(g, g * 1.05, g * 0.97)


# --- widgets ------------------------------------------------------------------------

func _page(heading: String, at: Vector2) -> void:
	_sub = heading != "" and heading != "ПАУЗА"
	for c in _panel.get_children():
		_panel.remove_child(c)
		c.queue_free()
	_heading.text = heading
	_heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	_heading.position = Vector2(at.x - 100, at.y - 60)
	_heading.size = Vector2(1000, 50)
	_panel.position = at
	_panel.size = Vector2(1920 - at.x * 2, 0)


func _button(text: String, action: Variant, dim := false) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 32)
	b.add_theme_color_override("font_color", DIM if dim else PAPER)
	b.add_theme_color_override("font_hover_color", HOVER)
	b.add_theme_color_override("font_focus_color", HOVER)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	b.add_theme_constant_override("outline_size", 6)
	if action is Callable:
		b.pressed.connect(action)
	else:
		b.pressed.connect(func() -> void: picked.emit(String(action)))
	_panel.add_child(b)
	return b


func _row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var l := Label.new()
	l.text = text
	# A long label (the detective mode, or any line in Hungarian) wraps in its
	# column instead of pushing the switch out of line with the others.
	l.custom_minimum_size = Vector2(560, 0)
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", PAPER)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	row.add_child(l)
	_panel.add_child(row)
	return row


func _slider(text: String, lo: float, hi: float, value: float, on_change: Callable) -> void:
	var row := _row(text)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = value
	s.custom_minimum_size = Vector2(380, 36)
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(on_change)
	row.add_child(s)


func _toggle(text: String, value: bool, on_change: Callable) -> void:
	var row := _row(text)
	var c := CheckButton.new()
	c.button_pressed = value
	c.focus_mode = Control.FOCUS_ALL
	c.toggled.connect(on_change)
	row.add_child(c)


func _option(text: String, items: Array, value: int, on_change: Callable, translate := true) -> void:
	var row := _row(text)
	var o := OptionButton.new()
	if not translate:  # language names stay in their own language
		o.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for it: String in items:
		o.add_item(it)
	o.select(value)
	o.focus_mode = Control.FOCUS_ALL
	o.add_theme_font_size_override("font_size", 24)
	o.item_selected.connect(on_change)
	row.add_child(o)


func _focus_first(index := 0) -> void:
	await get_tree().process_frame
	var n := 0
	for c in _panel.get_children():
		var f: Control = c
		if c is HBoxContainer:
			f = c.get_child(1)
		if f.focus_mode == Control.FOCUS_ALL:
			if n == index:
				f.grab_focus()
				return
			n += 1
