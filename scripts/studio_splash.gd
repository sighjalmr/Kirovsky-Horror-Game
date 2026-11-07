class_name StudioSplash
extends CanvasLayer

## The studio card at launch, before the title. The boot splash
## (project.godot) already shows the SIGHJALMR GAMES PRODUCTION logo while
## the game loads; this picks it up in the same place, holds it a moment and
## fades it out to the title. Any key, click or pad button skips it.

signal finished

const LOGO := "res://textures/brand/studio_logo.png"
const HOLD := 2.2
const FADE_OUT := 0.9

var _logo: TextureRect
var _tw: Tween
var _done := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var black := ColorRect.new()
	black.color = Color(0.0863, 0.0863, 0.0863)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)
	_logo = TextureRect.new()
	_logo.texture = load(LOGO)
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)
	_tw = create_tween()
	_tw.tween_interval(HOLD)
	_tw.tween_property(_logo, "modulate:a", 0.0, FADE_OUT)
	_tw.tween_interval(0.3)
	_tw.tween_callback(_end)


func _input(event: InputEvent) -> void:
	if _done:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		if _tw and _tw.is_valid():
			_tw.kill()
		_end()


func _end() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()
