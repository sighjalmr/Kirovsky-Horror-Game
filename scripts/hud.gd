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

var clock: Label
var subtitle: Label
var prompt: Label
var notebook: ColorRect
var notebook_text: Label
var fade: ColorRect
var title: Label
var title_sub: Label
var note: Label

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
	_voice = AudioStreamPlayer.new()
	_voice.process_mode = Node.PROCESS_MODE_PAUSABLE   # holds while the notebook is open
	add_child(_voice)

	notebook = ColorRect.new()
	notebook.color = Color(0.89, 0.87, 0.8, 0.97)
	notebook.position = Vector2(510, 90)
	notebook.size = Vector2(900, 900)
	notebook.visible = false
	add_child(notebook)
	notebook_text = Label.new()
	notebook_text.position = Vector2(44, 36)
	notebook_text.size = Vector2(812, 830)
	notebook_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_text.add_theme_font_size_override("font_size", 27)
	notebook_text.add_theme_color_override("font_color", Color(0.14, 0.13, 0.11))
	notebook.add_child(notebook_text)


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
		var duck := DUCK_DB if _voice.playing else 0.0
		AudioServer.set_bus_volume_db(hall, move_toward(AudioServer.get_bus_volume_db(hall), duck, delta * 20.0))
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


func set_prompt(text: String) -> void:
	prompt.text = text


func set_notebook(text: String) -> void:
	notebook_text.text = text


func fade_to(alpha: float, time: float) -> void:
	create_tween().tween_property(fade, "color:a", alpha, time)


func show_title(t: String, sub: String, color := PAPER) -> void:
	title.text = t
	title.add_theme_color_override("font_color", color)
	title_sub.text = sub
	title.modulate.a = 0.0
	title_sub.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(title, "modulate:a", 1.0, 1.2)
	tw.tween_property(title_sub, "modulate:a", 1.0, 1.8)


func hide_title() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(title, "modulate:a", 0.0, 0.6)
	tw.tween_property(title_sub, "modulate:a", 0.0, 0.6)
