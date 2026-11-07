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


## Dev: subtitle lines that were shown with no take (--voice-missing=PATH).
static var missing: Dictionary = {}


static func note_missing(text: String) -> void:
	if text.strip_edges() != "" and find(text).is_empty():
		missing[text] = true


static func dump_missing() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--voice-missing=") and not missing.is_empty():
			var f := FileAccess.open(a.get_slice("=", 1), FileAccess.WRITE)
			if f:
				for k: String in missing:
					f.store_line(JSON.stringify(k))
