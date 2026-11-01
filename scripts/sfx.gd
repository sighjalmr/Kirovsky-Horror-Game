class_name Sfx
extends RefCounted

## Sounds live in res://sounds/*.wav (44.1 kHz, 16 bit). tools/make_sounds.py
## synthesises the hall and the stings; tools/make_foley.py builds footsteps and
## the cleaver blows from real recordings (sounds/src/CREDITS.md). Any file can be
## swapped for a field recording of the same name. Sounds with several takes play
## them in random order. Everything plays through the "Hall" bus, which adds the
## echo of the big empty tiled hall; what plays in Gordeev's head (pulse,
## ringing) goes straight to "Master" so the muffle after a blow spares it.

const LOOPS := ["hum", "whirr", "phone", "compressor", "drone", "room", "engine", "crowd", "heartbeat", "killer_breath",
	"rain", "rain_car", "engine_drive"]
const TAKES := {"step": 12, "run": 6, "creep": 6, "heavy_step": 6, "chop": 3, "hurt": 3}
const BUS := "Hall"
const MUFFLE_FX := 1  # the low-pass on the Hall bus

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
## at night, a low-pass for the muffled hearing of a man going down, and a
## gentle compressor so the stinger does not clip.
static func setup_buses() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		muffle(false)
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
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 500.0
	AudioServer.add_bus_effect(i, lp)
	AudioServer.set_bus_effect_enabled(i, MUFFLE_FX, false)
	var comp := AudioEffectCompressor.new()
	comp.threshold = -10.0
	comp.ratio = 3.0
	AudioServer.add_bus_effect(0, comp)


static func play_3d(parent: Node, id: String, pos: Vector3, volume_db := 0.0, pitch := 1.0, max_dist := 24.0) -> AudioStreamPlayer3D:
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
	return p


## Everything in the hall sounds as through cotton wool: after the last blow.
static func muffle(on: bool) -> void:
	var i := AudioServer.get_bus_index(BUS)
	if i != -1:
		AudioServer.set_bus_effect_enabled(i, MUFFLE_FX, on)


static func play_2d(parent: Node, id: String, volume_db := 0.0, bus := BUS, pitch := 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(id)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p
