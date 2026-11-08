class_name Hud
extends CanvasLayer

## Clock, subtitles (Gordeev's voice-over and what he reads), the interact
## prompt, his notebook, fades and title cards. Drawn at 1920×1080 over the
## world view. A subtitle with a recorded take plays it as it appears.

const INK := Color(0.85, 0.88, 0.75)
const PAPER := Color(0.89, 0.87, 0.8)
const RED := Color(0.82, 0.22, 0.18)
## How far the hall sounds drop while Gordeev speaks, so his voice carries.
const DUCK_DB := -7.0

signal chosen(index: int)

var clock: Label
var subtitle: Label
var prompt: Label
var notebook: ColorRect
var notebook_text: Label
## The right-hand page: people and conclusions (Main fills it on opening).
var notebook_right: RichTextLabel
var fade: ColorRect
var title: Label
var title_sub: Label
var note: Label
var choices: ColorRect
var memo: ColorRect
## The task list in the top left corner (J hides it) and the rings round
## clues close by. Main fills them every frame while the shift is on.
var tasks: PanelContainer
var tasks_wanted := true
var tasks_allowed := false
var marks: ClueMarks

var _tasks_text: RichTextLabel
var _tasks_key := ""

var _memo_text: Label
## Under the paper, on the screen itself: how to put the note away.
var _memo_hint: Label

var _choice_box: VBoxContainer
var _choice_title: Label
var _choice_count := 0

## A key hint above the prompt the first time something is needed (Main.hint).
var hint: Label
var _hints: Array = []
var _hint_busy := false

var _queue: Array = []
var _sub_t := 0.0
var _voice: AudioStreamPlayer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.position = Vector2.ZERO
	fade.size = Vector2(1920, 1080)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	clock = _label(Vector2(1560, 28), Vector2(330, 44), 32, HORIZONTAL_ALIGNMENT_RIGHT, INK)
	note = _label(Vector2(30, 28), Vector2(1000, 44), 28, HORIZONTAL_ALIGNMENT_LEFT, PAPER)
	note.modulate.a = 0.0
	prompt = _label(Vector2(260, 830), Vector2(1400, 44), 30, HORIZONTAL_ALIGNMENT_CENTER, PAPER)
	subtitle = _label(Vector2(260, 890), Vector2(1400, 170), 32, HORIZONTAL_ALIGNMENT_CENTER, INK)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title = _label(Vector2(0, 300), Vector2(1920, 110), 64, HORIZONTAL_ALIGNMENT_CENTER, PAPER)
	title_sub = _label(Vector2(360, 440), Vector2(1200, 560), 30, HORIZONTAL_ALIGNMENT_CENTER, INK)
	title_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_sub.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	marks = ClueMarks.new()
	marks.position = Vector2.ZERO
	marks.size = Vector2(1920, 1080)
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marks)
	move_child(marks, 1)
	_build_tasks()
	_voice = AudioStreamPlayer.new()
	_voice.process_mode = Node.PROCESS_MODE_PAUSABLE   # holds while the notebook is open
	_voice.bus = Settings.VOICE_BUS
	add_child(_voice)
	hint = _label(Vector2(260, 740), Vector2(1400, 80), 27, HORIZONTAL_ALIGNMENT_CENTER, Color(1.0, 0.86, 0.58))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate.a = 0.0
	apply_settings()

	# A school notebook open on two pages of squared paper, written in blue
	# ballpoint: the findings on the left, the people and conclusions right.
	notebook = ColorRect.new()
	notebook.color = Color(0.9, 0.89, 0.83, 0.98)
	notebook.position = Vector2(170, 80)
	notebook.size = Vector2(1580, 920)
	notebook.visible = false
	add_child(notebook)
	for i in 41:
		var h := ColorRect.new()
		h.color = Color(0.42, 0.55, 0.72, 0.16)
		h.position = Vector2(0, 14 + i * 22.5)
		h.size = Vector2(1580, 1)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		notebook.add_child(h)
	for i in 71:
		var v := ColorRect.new()
		v.color = Color(0.42, 0.55, 0.72, 0.12)
		v.position = Vector2(10 + i * 22.5, 0)
		v.size = Vector2(1, 920)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		notebook.add_child(v)
	var spine := ColorRect.new()
	spine.color = Color(0.2, 0.18, 0.15, 0.35)
	spine.position = Vector2(788, 0)
	spine.size = Vector2(4, 920)
	notebook.add_child(spine)
	var margin := ColorRect.new()
	margin.color = Color(0.8, 0.25, 0.25, 0.35)
	margin.position = Vector2(1520, 0)
	margin.size = Vector2(2, 920)
	notebook.add_child(margin)
	notebook_text = Label.new()
	notebook_text.position = Vector2(40, 30)
	notebook_text.size = Vector2(716, 860)
	notebook_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_text.add_theme_font_size_override("font_size", 25)
	notebook_text.add_theme_color_override("font_color", Color(0.13, 0.17, 0.4))
	notebook.add_child(notebook_text)
	notebook_right = RichTextLabel.new()
	notebook_right.bbcode_enabled = true
	notebook_right.position = Vector2(830, 30)
	notebook_right.size = Vector2(680, 860)
	notebook_right.scroll_active = false
	notebook_right.add_theme_font_size_override("normal_font_size", 24)
	notebook_right.add_theme_font_size_override("bold_font_size", 25)
	notebook_right.add_theme_color_override("default_color", Color(0.13, 0.17, 0.4))
	notebook_right.add_theme_constant_override("line_separation", 6)
	notebook.add_child(notebook_right)

	choices = ColorRect.new()
	choices.color = Color(0.03, 0.03, 0.03, 0.78)
	choices.position = Vector2(410, 380)
	choices.size = Vector2(1100, 480)
	choices.visible = false
	add_child(choices)
	_choice_title = Label.new()
	_choice_title.position = Vector2(36, 24)
	_choice_title.size = Vector2(1028, 40)
	_choice_title.add_theme_font_size_override("font_size", 26)
	_choice_title.add_theme_color_override("font_color", Color(0.65, 0.66, 0.58))
	choices.add_child(_choice_title)
	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(36, 78)
	_choice_box.size = Vector2(1028, 380)
	_choice_box.add_theme_constant_override("separation", 6)
	choices.add_child(_choice_box)

	# A sheet of squared school paper, slightly askew: notes left in the post.
	memo = ColorRect.new()
	memo.color = Color(0.86, 0.84, 0.76, 0.98)
	memo.position = Vector2(480, 30)
	memo.size = Vector2(960, 1020)
	memo.pivot_offset = memo.size * 0.5
	memo.rotation = deg_to_rad(-1.2)
	memo.visible = false
	add_child(memo)
	for i in 46:
		var line := ColorRect.new()
		line.color = Color(0.45, 0.55, 0.7, 0.18)
		line.position = Vector2(0, 30 + i * 23)
		line.size = Vector2(960, 1)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		memo.add_child(line)
	_memo_text = Label.new()
	_memo_text.position = Vector2(56, 34)
	_memo_text.size = Vector2(848, 960)
	_memo_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_memo_text.add_theme_font_size_override("font_size", 25)
	_memo_text.add_theme_color_override("font_color", Color(0.12, 0.16, 0.38))
	memo.add_child(_memo_text)
	_memo_hint = Label.new()
	_memo_hint.text = "E, клик или W — убрать записку"
	_memo_hint.position = Vector2(0, 1046)
	_memo_hint.size = Vector2(1920, 34)
	_memo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_memo_hint.add_theme_font_size_override("font_size", 24)
	_memo_hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	_memo_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_memo_hint.add_theme_constant_override("outline_size", 8)
	_memo_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_memo_hint.visible = false
	add_child(_memo_hint)


func _build_tasks() -> void:
	tasks = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.02, 0.02, 0.34)
	box.border_color = Color(PAPER, 0.35)
	box.border_width_left = 2
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 12
	tasks.add_theme_stylebox_override("panel", box)
	tasks.position = Vector2(30, 84)
	tasks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tasks.visible = false
	add_child(tasks)
	_tasks_text = RichTextLabel.new()
	_tasks_text.bbcode_enabled = true
	_tasks_text.fit_content = true
	_tasks_text.scroll_active = false
	_tasks_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tasks_text.custom_minimum_size = Vector2(540, 0)
	_tasks_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tasks_text.add_theme_font_size_override("normal_font_size", 21)
	_tasks_text.add_theme_color_override("default_color", INK)
	_tasks_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_tasks_text.add_theme_constant_override("outline_size", 6)
	_tasks_text.add_theme_constant_override("line_separation", 3)
	tasks.add_child(_tasks_text)


## The task list: each entry is {text, done, sub, urgent, hint}. Done ones are
## struck through and dimmed, sub-steps indented, urgent ones in red. The
## panel flares up for a moment when something new appears on it.
func set_tasks(list: Array) -> void:
	var key := ""
	for t: Dictionary in list:
		key += "%s|%s|%s\n" % [t.text, t.get("done", false), t.get("urgent", false)]
	if key == _tasks_key:
		return
	var grew := false
	for line in key.split("\n"):
		if line != "" and line.ends_with("|false|false") and not _tasks_key.contains(line):
			grew = true
	_tasks_key = key
	var out := PackedStringArray(["[color=#8f927f][font_size=17]ЧТО ДЕЛАТЬ      J — скрыть[/font_size][/color]"])
	for t: Dictionary in list:
		var text: String = t.text
		var mark := "·"
		if t.get("done", false):
			text = "[color=#7d7f72][s]%s[/s][/color]" % text
			mark = "[color=#7d7f72]×[/color]"
		elif t.get("hint", false):
			text = "[color=#a4a796]%s[/color]" % text
		elif t.get("urgent", false):
			text = "[color=#e0634f]%s[/color]" % text
			mark = "[color=#e0634f]![/color]"
		if t.get("sub", false):
			out.append("[indent]%s %s[/indent]" % [mark, text])
		else:
			out.append("%s  %s" % ["—" if not t.get("done", false) else mark, text])
	_tasks_text.text = "\n".join(out)
	tasks.reset_size()
	if grew and tasks.visible:
		tasks.modulate = Color(1.6, 1.45, 1.15)
		create_tween().tween_property(tasks, "modulate", Color.WHITE, 1.4)


func toggle_tasks() -> void:
	tasks_wanted = not tasks_wanted


## Shows a handwritten note until E (or a click) puts it away.
func read_memo(text: String) -> void:
	_memo_text.text = text
	memo.modulate.a = 0.0
	memo.visible = true
	_memo_hint.visible = true
	create_tween().tween_property(memo, "modulate:a", 1.0, 0.5)
	var t := 0.0
	while true:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 0.8 and (Input.is_action_just_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
				or Input.is_action_just_pressed("ui_cancel") or _wants_to_walk()):
			break
	# The click that put the note away must not also light the torch (left button).
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(memo, "modulate:a", 0.0, 0.4)
	_memo_hint.visible = false
	await tw.finished
	memo.visible = false


## W/A/S/D or the arrows while a note is up: he wants to get going, so the
## note goes away (the game stands still while it is read).
func _wants_to_walk() -> bool:
	for a in ["move_forward", "move_back", "strafe_left", "strafe_right"]:
		if Input.is_action_just_pressed(a):
			return true
	return false


## A list of answers to pick with the mouse or the number keys; returns the
## index of the one picked. The player is held still meanwhile by the caller.
func choose(heading: String, labels: Array[String]) -> int:
	for c in _choice_box.get_children():
		c.queue_free()
	_choice_title.text = heading
	_choice_count = labels.size()
	for i in labels.size():
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, labels[i]]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 30)
		b.add_theme_color_override("font_color", PAPER)
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.55))
		b.add_theme_color_override("font_focus_color", Color(1.0, 0.85, 0.55))
		b.pressed.connect(func() -> void: chosen.emit(i))
		_choice_box.add_child(b)
	choices.size.y = 110 + labels.size() * 58
	choices.position.y = 860 - choices.size.y
	choices.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var pick: int = await chosen
	choices.visible = false
	_choice_count = 0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return pick


func _unhandled_key_input(event: InputEvent) -> void:
	if _choice_count == 0 or not event.is_pressed() or event.is_echo():
		return
	var k := (event as InputEventKey).physical_keycode
	if k >= KEY_1 and k < KEY_1 + _choice_count:
		get_viewport().set_input_as_handled()
		chosen.emit(k - KEY_1)


func _label(pos: Vector2, size: Vector2, font_size: int, align: HorizontalAlignment, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _process(delta: float) -> void:
	var hall := AudioServer.get_bus_index(Sfx.BUS)
	if hall != -1:
		var duck := (DUCK_DB if _voice.playing else 0.0) + Settings.db(Settings.sounds)
		AudioServer.set_bus_volume_db(hall, move_toward(AudioServer.get_bus_volume_db(hall), duck, delta * 20.0))
	tasks.visible = tasks_wanted and tasks_allowed and _tasks_key != "" \
		and not notebook.visible and not memo.visible and not choices.visible
	marks.visible = tasks_allowed and not notebook.visible and not memo.visible
	if get_tree().paused:
		return
	_sub_t -= delta
	if _sub_t <= 0.0:
		if _queue.is_empty():
			subtitle.text = ""
		else:
			var next: Array = _queue.pop_front()
			subtitle.text = next[0]
			_sub_t = next[1]
			_speak(next[0])


## Queues a subtitle. `now` drops whatever is queued and shows it at once.
## A voiced line stays up at least as long as its take.
func say(text: String, duration := -1.0, now := false) -> void:
	var take := Voice.find(text)
	if take.is_empty():
		Voice.note_missing(text)
	if duration < 0.0:
		duration = 2.5 + text.length() * 0.05
	if not take.is_empty():
		duration = maxf(duration, float(take.length) + 0.4)
	if now:
		_queue.clear()
		_queue.append([text, duration])
		_sub_t = 0.0
	else:
		_queue.append([text, duration])


## A stranger's remark in passing: shown only when no other subtitle is up
## or waiting, so it never cuts into a conversation. Its voice is played by
## the caller, from where the speaker stands. True if it was shown.
func say_aside(text: String, duration: float) -> bool:
	if not _queue.is_empty() or _sub_t > 0.0 or _voice.playing or choices.visible:
		return false
	Voice.note_missing(text)
	subtitle.text = text
	_sub_t = duration
	return true


func clear_subtitles() -> void:
	_queue.clear()
	_sub_t = 0.0
	subtitle.text = ""
	_voice.stop()


func _speak(text: String) -> void:
	var take := Voice.find(text)
	if take.is_empty():
		_voice.stop()
		return
	_voice.stream = load(take.file)
	_voice.play()


## A short line in the corner that fades out: "the shift is saved".
func flash_note(text: String) -> void:
	note.text = text
	var tw := create_tween()
	tw.tween_property(note, "modulate:a", 1.0, 0.5)
	tw.tween_interval(3.5)
	tw.tween_property(note, "modulate:a", 0.0, 1.5)


## Subtitles on or off and their size, from the settings.
func apply_settings() -> void:
	subtitle.visible = Settings.subtitles
	subtitle.add_theme_font_size_override("font_size", Settings.sub_font())
	subtitle.position.y = 890 - (Settings.sub_font() - 32) * 3
	subtitle.size.y = 170 + (Settings.sub_font() - 32) * 3


## Shows a key hint for a few seconds; several wait their turn.
func show_hint(text: String) -> void:
	_hints.append(text)
	if _hint_busy:
		return
	_hint_busy = true
	while not _hints.is_empty():
		hint.text = _hints.pop_front()
		var tw := create_tween()
		tw.tween_property(hint, "modulate:a", 1.0, 0.4)
		tw.tween_interval(5.5)
		tw.tween_property(hint, "modulate:a", 0.0, 0.8)
		await tw.finished
	_hint_busy = false


func set_prompt(text: String) -> void:
	prompt.text = text


## Long notebooks (night two carries the earlier findings over) get a smaller
## hand so the page never runs off the bottom of the sheet.
func set_notebook(text: String) -> void:
	notebook_text.text = text
	var size := 25
	while size > 16:
		var per_line := int(notebook_text.size.x / (size * 0.5))
		var lines := 0
		for l in text.split("\n"):
			lines += maxi(1, ceili(float(l.length()) / per_line))
		if lines * size * 1.38 <= notebook_text.size.y:
			break
		size -= 1
	notebook_text.add_theme_font_size_override("font_size", size)


func fade_to(alpha: float, time: float) -> void:
	create_tween().tween_property(fade, "color:a", alpha, time)


## True while a voice line is playing.
func speaking() -> bool:
	return _voice.playing


func show_title(t: String, sub: String, color := PAPER) -> void:
	title.text = t
	title.add_theme_color_override("font_color", color)
	title_sub.text = sub
	title.modulate.a = 0.0
	title_sub.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(title, "modulate:a", 1.0, 1.2)
	tw.tween_property(title_sub, "modulate:a", 1.0, 1.8)


## The ending a year on: a newspaper cutting at the top, the fates and the
## keys under it.
func show_epilogue(heading: String, ep: Array, tail: String) -> void:
	var paper := ColorRect.new()
	paper.color = Color(0.86, 0.84, 0.76)
	paper.position = Vector2(500, 40)
	paper.size = Vector2(920, 470)
	paper.rotation = deg_to_rad(-0.8)
	paper.modulate.a = 0.0
	add_child(paper)
	var ink := Color(0.12, 0.11, 0.1)
	var rows := [
		[Vector2(30, 14), Vector2(860, 60), 44, "ВЕЧЕРНИЙ СВЕРДЛОВСК", HORIZONTAL_ALIGNMENT_CENTER],
		[Vector2(30, 76), Vector2(860, 30), 20, "Газета горкома КПСС и горисполкома  ·  %s  ·  Цена 3 коп." % ep[0], HORIZONTAL_ALIGNMENT_CENTER],
		[Vector2(30, 128), Vector2(860, 48), 36, ep[1], HORIZONTAL_ALIGNMENT_LEFT],
		[Vector2(30, 186), Vector2(860, 270), 25, ep[2], HORIZONTAL_ALIGNMENT_LEFT],
	]
	for r: Array in rows:
		var l := Label.new()
		l.position = r[0]
		l.size = r[1]
		l.text = r[3]
		l.horizontal_alignment = r[4]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", r[2])
		l.add_theme_color_override("font_color", ink)
		paper.add_child(l)
	var rule := ColorRect.new()
	rule.color = ink
	rule.position = Vector2(30, 112)
	rule.size = Vector2(860, 3)
	paper.add_child(rule)
	title.text = ""
	title_sub.position = Vector2(300, 540)
	title_sub.size = Vector2(1320, 530)
	title_sub.add_theme_font_size_override("font_size", 24)
	title_sub.text = "%s\n\n%s\n\n%s" % [heading, ep[3], tail]
	title_sub.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(paper, "modulate:a", 1.0, 1.5)
	tw.tween_property(title_sub, "modulate:a", 1.0, 1.5)


func hide_title() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(title, "modulate:a", 0.0, 0.6)
	tw.tween_property(title_sub, "modulate:a", 0.0, 0.6)


## Thin pale rings round the clues within a few steps of Gordeev, so the eye
## finds them in the gloom. Main hands over screen points each frame:
## [position, nearness 0..1].
class ClueMarks extends Control:
	var points: Array = []
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 2.4)
		for p: Array in points:
			var at: Vector2 = p[0]
			var near: float = p[1]
			var r := lerpf(20.0, 34.0, near) + pulse * 2.5
			var a := clampf(near * 1.6, 0.0, 1.0) * lerpf(0.55, 0.85, pulse)
			draw_arc(at, r + 1.5, 0, TAU, 48, Color(0, 0, 0, a * 0.45), 4.0, true)
			draw_arc(at, r, 0, TAU, 48, Color(0.93, 0.9, 0.78, a), 2.0, true)
			draw_circle(at, 2.2, Color(0.93, 0.9, 0.78, a * 0.8))


# --- achievements ----------------------------------------------------------------

var _ach_queue: Array = []
var _ach_busy := false
var _ach_panel: PanelContainer
var _ach_name: Label
var _ach_desc: Label


## A small card in the top right corner: «Достижение получено» and its name.
## Several wait their turn. Shows over the fades and the end titles.
func show_achievement(name_text: String, desc: String) -> void:
	_ach_queue.append([name_text, desc])
	if _ach_busy:
		return
	_ach_busy = true
	if _ach_panel == null:
		_build_achievement_card()
	while not _ach_queue.is_empty():
		var a: Array = _ach_queue.pop_front()
		_ach_name.text = "«%s»" % a[0]
		_ach_desc.text = a[1]
		move_child(_ach_panel, get_child_count() - 1)
		Sfx.play_2d(self, "pickup", -10.0, "Master", 0.7)
		var tw := create_tween()
		tw.tween_property(_ach_panel, "modulate:a", 1.0, 0.5)
		tw.tween_interval(4.5)
		tw.tween_property(_ach_panel, "modulate:a", 0.0, 1.0)
		await tw.finished
	_ach_busy = false


func _build_achievement_card() -> void:
	_ach_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.05, 0.88)
	sb.border_color = Color(0.62, 0.55, 0.38)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	_ach_panel.add_theme_stylebox_override("panel", sb)
	_ach_panel.position = Vector2(1290, 96)
	_ach_panel.custom_minimum_size = Vector2(600, 0)
	_ach_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ach_panel.modulate.a = 0.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_ach_panel.add_child(box)
	var head := Label.new()
	head.text = Stats.tr_text(Stats.UI.toast)
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.78, 0.68, 0.45))
	box.add_child(head)
	_ach_name = Label.new()
	_ach_name.add_theme_font_size_override("font_size", 30)
	_ach_name.add_theme_color_override("font_color", PAPER)
	box.add_child(_ach_name)
	_ach_desc = Label.new()
	_ach_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ach_desc.custom_minimum_size = Vector2(564, 0)
	_ach_desc.add_theme_font_size_override("font_size", 20)
	_ach_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.64))
	box.add_child(_ach_desc)
	add_child(_ach_panel)
