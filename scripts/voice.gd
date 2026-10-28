class_name Voice
extends RefCounted

## Voice-over takes for subtitle lines. voice/index.json maps the exact
## subtitle text to its .ogg and length; tools/make_voice.py writes it from
## voice/script.json. Lines that are not in it stay silent subtitles.

const INDEX := "res://voice/index.json"

static var _index: Dictionary = {}
static var _loaded := false


## {"file": ..., "length": ...} for this text, or empty if it has no take.
static func find(text: String) -> Dictionary:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open(INDEX, FileAccess.READ)
		if f:
			var data: Variant = JSON.parse_string(f.get_as_text())
			if data is Dictionary:
				_index = data
	return _index.get(text, {})
