class_name Sfx
extends RefCounted

## Sounds live in res://sounds/*.wav (44.1 kHz, 16 bit), synthesised by
## tools/make_sounds.py. Any file can be swapped for a field recording of the
## same name. Footsteps have four takes each and play in random order.
## Everything plays through the "Hall" bus, which adds the echo of the big
## empty tiled hall.

const LOOPS := ["hum", "whirr", "phone", "compressor", "drone", "room"]
const TAKES := {"step": 4, "heavy_step": 4}
const BUS := "Hall"

static var _cache: Dictionary = {}


static func get_stream(id: String) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var s: AudioStream
	if TAKES.has(id):
		var r := AudioStreamRandomizer.new()
		r.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
		r.random_pitch = 1.0
		r.random_volume_offset_db = 1.5
		for i in TAKES[id]:
			r.add_stream(-1, _load("%s_%d" % [id, i + 1]))
		s = r
	else:
		s = _load(id)
	_cache[id] = s
	return s


static func _load(id: String) -> AudioStreamWAV:
	var path := "res://sounds/%s.wav" % id
	if not ResourceLoader.exists(path):
		push_error("Missing sound: " + path)
		return AudioStreamWAV.new()
	var w: AudioStreamWAV = load(path)
	if id in LOOPS:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	return w


## Creates the "Hall" bus once: a long, dark reverb like a tiled supermarket
## at night, and a gentle compressor so the stinger does not clip.
static func setup_buses() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, "Master")
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.78
	rv.damping = 0.55
	rv.spread = 0.8
	rv.hipass = 0.08
	rv.predelay_msec = 45.0
	rv.predelay_feedback = 0.25
	rv.dry = 0.9
	rv.wet = 0.22
	AudioServer.add_bus_effect(i, rv)
	var comp := AudioEffectCompressor.new()
	comp.threshold = -10.0
	comp.ratio = 3.0
	AudioServer.add_bus_effect(0, comp)


static func play_3d(parent: Node, id: String, pos: Vector3, volume_db := 0.0, pitch := 1.0, max_dist := 24.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = get_stream(id)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.max_distance = max_dist
	p.unit_size = 4.0
	p.bus = BUS
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


static func play_2d(parent: Node, id: String, volume_db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(id)
	p.volume_db = volume_db
	p.bus = BUS
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
