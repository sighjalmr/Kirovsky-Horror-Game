class_name Loc
extends Translation

## The game's languages. The game is written in Russian and the voices stay
## Russian; English and Hungarian are subtitles and on-screen text only.
##
## i18n/<code>.json maps the exact Russian text to its translation. Every
## Label, Button and RichTextLabel in Godot passes its text through the
## TranslationServer, so code keeps passing Russian strings around (the voice
## takes are found by the Russian text too) and the screen shows the chosen
## language. Text the game builds from pieces is taken apart again here:
##   * a key with %s / %d is a template: "Улики: %d из %d" matches
##     "Улики: 3 из 5", the numbers are kept and every %s piece is translated
##     on its own. A translation may reorder pieces with %1$s, %2$s...
##   * text of several lines that is not a key is translated line by line,
##     and every multi-line key also teaches its lines one by one;
##   * a line wrapped in a dash, a bullet or BBCode tags is translated inside.
## Signs on the walls and plates (ПОДВАЛ, МИЛИЦИЯ...) are left out of the
## files on purpose: the store is in Sverdlovsk.

const LANGS := ["ru", "en", "hu"]
## Shown in their own language in the settings, never translated.
const NAMES := ["Русский", "English", "Magyar"]

## Dev: Russian text that reached the screen untranslated (--i18n-missing=PATH).
static var missing := {}
static var _ready_done := false
## The registered translations. A translation written in GDScript has to leave
## the TranslationServer before the game closes, or Godot crashes on exit:
## Main takes them out in its _exit_tree and puts them back on a reload.
static var _added: Array = []

var _map := {}
## [RegEx, translated template, number of pieces], longest keys first.
var _templates: Array = []
var _cache := {}
static var _cyr := RegEx.create_from_string("[А-Яа-яЁё]")
static var _spec := RegEx.create_from_string("%(?:(\\d+)\\$)?[-0-9.]*[sdf]")
## Dashes, bullets, quotes and BBCode around a line: translate what is inside.
static var _wrap := RegEx.create_from_string(
	"^((?:\\[[^\\]]*\\]|[\\s—–•·×!\\-]|\\d+\\.\\s)*)(.*?)((?:\\[/[^\\]]*\\]|\\s)*)$")


## Registers the translations once and switches to the chosen language.
static func setup() -> void:
	if _added.is_empty():
		for code: String in ["en", "hu"]:
			var t := Loc.new()
			t.locale = code
			t._load("res://i18n/%s.json" % code)
			TranslationServer.add_translation(t)
			_added.append(t)
	if not _ready_done:
		_ready_done = true
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--lang="):
				Settings.language = maxi(0, LANGS.find(a.get_slice("=", 1)))
	apply()


static func apply() -> void:
	TranslationServer.set_locale(code())
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title(t(ProjectSettings.get_setting("application/config/name")))


static func code() -> String:
	return LANGS[clampi(Settings.language, 0, LANGS.size() - 1)]


## The language a first start picks: the computer's own, Russian for the
## Russian-reading countries, otherwise English.
static func default_language() -> int:
	var l := OS.get_locale_language()
	if l == "hu":
		return 2
	if l in ["ru", "uk", "be", "kk", "ky", "uz", "tg", "hy", "az", "ka"]:
		return 0
	return 1


## The text in the chosen language (for places that are not a Label).
## A context keeps a word apart from the same word elsewhere: the fire plan
## says СКЛАД in the player's language, the sign on the door stays Russian.
## Its keys in the files are "<context>|<text>".
static func t(text: String, context := "") -> String:
	return String(TranslationServer.translate(text, context))


## Takes the translations out of the server (see _added).
static func shutdown() -> void:
	dump_missing()
	for t: Loc in _added:
		TranslationServer.remove_translation(t)
	_added.clear()


## Dev: writes the untranslated lines met during the run.
static func dump_missing() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--i18n-missing=") and not missing.is_empty():
			var f := FileAccess.open(a.get_slice("=", 1), FileAccess.WRITE)
			if f:
				for k: String in missing:
					f.store_line(JSON.stringify(k))


func _load(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		push_error("Loc: %s is not a JSON object" % path)
		return
	var keys: Array = []
	for k: String in data:
		var v: String = data[k]
		_map[k] = v
		var sk := k.strip_edges()
		if sk != k and not _map.has(sk):
			_map[sk] = v.strip_edges()
		# Multi-line keys teach their lines one by one.
		var kl := sk.split("\n")
		var vl := v.strip_edges().split("\n")
		if kl.size() > 1 and kl.size() == vl.size():
			for i in kl.size():
				var a := kl[i].strip_edges()
				if a != "" and not _map.has(a):
					_map[a] = vl[i].strip_edges()
		if "%" in k:
			keys.append(sk)
	keys.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	for k: String in keys:
		var pat := "^"
		var pos := 0
		var n := 0
		for m in _spec.search_all(k):
			pat += _escape(k.substr(pos, m.get_start() - pos))
			# A piece of a one-line template stays on its line.
			pat += "(-?\\d+)" if m.get_string().ends_with("d") else ("([\\s\\S]*?)" if "\n" in k else "([^\\n]*?)")
			pos = m.get_end()
			n += 1
		pat += _escape(k.substr(pos)) + "$"
		if n == 0:
			continue
		var re := RegEx.create_from_string(pat)
		if re.is_valid():
			_templates.append([re, _map[k], n])


static func _escape(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if ch in "\\.^$|?*+()[]{}" else ch
	return out


func _get_message(src_message: StringName, context: StringName) -> StringName:
	var s := String(src_message)
	if context != &"":
		return StringName(_map.get(String(context) + "|" + s, ""))
	var r := _resolve(s)
	if r == "":
		if _cyr.search(s) and OS.is_debug_build():
			missing[s] = true
		return StringName()
	return StringName(r)


## The translation, or "" when there is nothing to translate.
func _resolve(s: String) -> String:
	if _map.has(s):
		return _map[s]
	if _cache.has(s):
		return _cache[s]
	var out := ""
	if _cyr.search(s):
		out = _compose(s)
	if _cache.size() > 4000:
		_cache.clear()
	_cache[s] = out
	return out


func _compose(s: String) -> String:
	# A template.
	for tp: Array in _templates:
		var m: RegExMatch = (tp[0] as RegEx).search(s)
		if m == null:
			continue
		var args: Array[String] = []
		for i in range(1, int(tp[2]) + 1):
			var a := m.get_string(i)
			var ta := _resolve(a)
			args.append(ta if ta != "" else a)
		return _fill(tp[1], args)
	# Several lines: one by one.
	if "\n" in s:
		var lines := s.split("\n")
		var changed := false
		for i in lines.size():
			var tl := _resolve(lines[i])
			if tl != "":
				lines[i] = tl
				changed = true
		return "\n".join(lines) if changed else ""
	# A dash, a bullet, a number or BBCode around it.
	var w := _wrap.search(s)
	if w and (w.get_string(1) != "" or w.get_string(3) != "") and w.get_string(2) != "":
		var inner := _resolve(w.get_string(2))
		if inner != "":
			return w.get_string(1) + inner + w.get_string(3)
	# Sentences glued together: "Записал в блокнот. " + entry.
	var cut := s.find(" ")
	while cut != -1:
		var head := s.substr(0, cut)
		if head.ends_with(".") or head.ends_with("!") or head.ends_with("?"):
			var th: String = _map.get(head, "")
			if th != "":
				var tt := _resolve(s.substr(cut + 1))
				if tt != "":
					return th + " " + tt
		cut = s.find(" ", cut + 1)
	return ""


## The translated template with the pieces put in, in order or by %N$.
static func _fill(tmpl: String, args: Array[String]) -> String:
	var out := ""
	var pos := 0
	var next := 0
	for m in _spec.search_all(tmpl):
		out += tmpl.substr(pos, m.get_start() - pos)
		var idx := next
		if m.get_string(1) != "":
			idx = int(m.get_string(1)) - 1
		else:
			next += 1
		out += args[idx] if idx < args.size() else ""
		pos = m.get_end()
	return out + tmpl.substr(pos)
