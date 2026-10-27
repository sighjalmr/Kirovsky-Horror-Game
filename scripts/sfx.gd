class_name Sfx
extends RefCounted

## Procedural placeholder sounds, synthesised at 22 kHz in 8 bits to sound
## like the PS1 sound chip. Each id is swapped for a real recording later.

const RATE := 22050

static var _cache: Dictionary = {}


static func get_stream(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var s: AudioStreamWAV
	match id:
		"hum": s = _hum()
		"click": s = _click()
		"whirr": s = _whirr()
		"step": s = _step(0.11, 0.35, 90.0, 40.0)
		"heavy_step": s = _step(0.2, 0.15, 60.0, 22.0)
		"phone": s = _phone()
		"cloth": s = _cloth()
		"stinger": s = _stinger()
		"stab": s = _stab()
		"compressor": s = _compressor()
		"drone": s = _drone()
		"chime": s = _chime()
		"breath": s = _breath()
		"clank": s = _clank()
		"keys": s = _keys()
		"pickup": s = _step(0.08, 0.5, 300.0, 50.0)
		_: push_error("Unknown sound: " + id)
	_cache[id] = s
	return s


static func play_3d(parent: Node, id: String, pos: Vector3, volume_db := 0.0, pitch := 1.0, max_dist := 24.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = get_stream(id)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.max_distance = max_dist
	p.unit_size = 4.0
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


static func play_2d(parent: Node, id: String, volume_db := 0.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(id)
	p.volume_db = volume_db
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


static func _wav(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size())
	for i in buf.size():
		data[i] = int(clampf(buf[i], -1.0, 1.0) * 127.0) & 0xFF
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


static func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Fluorescent tube: 100 Hz mains buzz with harmonics. 1 s loops cleanly.
static func _hum() -> AudioStreamWAV:
	var b := _buf(1.0)
	for i in b.size():
		var t := float(i) / RATE
		var s := sin(TAU * 100.0 * t)
		b[i] = (s * 0.5 + sin(TAU * 200.0 * t) * 0.25 + sin(TAU * 300.0 * t) * 0.12 + (0.15 if s > 0.9 else 0.0)) * 0.35
	return _wav(b, true)


## A row switching off: relay pop, tube ping, fading rattle.
static func _click() -> AudioStreamWAV:
	var b := _buf(0.7)
	for i in b.size():
		var t := float(i) / RATE
		var pop := randf_range(-1, 1) * exp(-t * 200.0)
		var ping := sin(TAU * 2200.0 * t) * exp(-t * 12.0) * 0.2
		var rattle := signf(sin(TAU * 100.0 * t)) * exp(-t * 7.0) * 0.15
		b[i] = pop * 0.8 + ping + rattle
	return _wav(b)


## Dynamo "zhuchok" flashlight: pumped saw at 170 Hz, 6 squeezes a second.
static func _whirr() -> AudioStreamWAV:
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		var saw := fmod(t * 170.0, 1.0) * 2.0 - 1.0
		var amp := 0.6 + 0.4 * sin(TAU * 6.0 * t)
		b[i] = (saw * 0.35 + sin(TAU * 340.0 * t) * 0.2 + randf_range(-0.12, 0.12)) * amp * 0.6
	return _wav(b, true)


static func _step(seconds: float, lp: float, thump_hz: float, decay: float) -> AudioStreamWAV:
	var b := _buf(seconds)
	var y := 0.0
	for i in b.size():
		var t := float(i) / RATE
		y += (randf_range(-1, 1) - y) * lp
		b[i] = (y * 1.4 + sin(TAU * thump_hz * t) * 0.6) * exp(-t * decay)
	return _wav(b)


## Rotary desk phone bell: hammer at 25 Hz, one second on, two off.
static func _phone() -> AudioStreamWAV:
	var b := _buf(3.0)
	for i in b.size():
		var t := float(i) / RATE
		if t > 1.0:
			b[i] = 0.0
			continue
		var e := exp(-fmod(t * 25.0, 1.0) * 6.0)
		b[i] = (sin(TAU * 1100.0 * t) * 0.5 + sin(TAU * 1650.0 * t) * 0.3) * e * 0.7
	return _wav(b, true)


static func _cloth() -> AudioStreamWAV:
	var b := _buf(1.2)
	var y := 0.0
	for i in b.size():
		var t := float(i) / RATE
		y += (randf_range(-1, 1) - y) * 0.3
		b[i] = y * sin(PI * t / 1.2) * (0.6 + 0.4 * sin(TAU * 7.0 * t)) * 0.9
	return _wav(b)


## Spotted: a low dissonant cluster with a metallic scrape over it.
static func _stinger() -> AudioStreamWAV:
	var b := _buf(2.0)
	var y := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var env := minf(1.0, t * 40.0) * exp(-t * 1.6)
		var low := 0.0
		for f: float in [55.0, 58.3, 82.4, 116.5]:
			low += (fmod(t * f, 1.0) * 2.0 - 1.0) * 0.18
		var n := randf_range(-1, 1)
		y += (n - y) * 0.5
		var scrape := (n - y) * sin(TAU * (900.0 + t * 600.0) * t) * 0.35
		b[i] = (low + scrape) * env
	return _wav(b)


## A cleaver blow: dull thump and a wet crunch.
static func _stab() -> AudioStreamWAV:
	var b := _buf(0.4)
	var y := 0.0
	for i in b.size():
		var t := float(i) / RATE
		y += (randf_range(-1, 1) - y) * 0.4
		b[i] = sin(TAU * 70.0 * t) * exp(-t * 18.0) * 0.8 + y * exp(-t * 12.0) * 0.9
	return _wav(b)


## Freezer chest compressor: 50 Hz rumble, 2 s loop.
static func _compressor() -> AudioStreamWAV:
	var b := _buf(2.0)
	var y := 0.0
	for i in b.size():
		var t := float(i) / RATE
		y += (randf_range(-1, 1) - y) * 0.05
		b[i] = sin(TAU * 50.0 * t) * 0.3 + sin(TAU * 100.0 * t) * 0.12 + y * 0.6
	return _wav(b, true)


## Chase bed: detuned low saws and a slow metallic beat, 4 s loop.
static func _drone() -> AudioStreamWAV:
	var b := _buf(4.0)
	for i in b.size():
		var t := float(i) / RATE
		var s := (fmod(t * 55.0, 1.0) + fmod(t * 55.5, 1.0) - 1.0) * 0.3
		var beat := sin(TAU * 440.0 * t) * exp(-fmod(t, 0.5) * 9.0) * 0.12
		b[i] = s + beat + randf_range(-0.04, 0.04)
	return _wav(b, true)


## PA chime before an announcement.
static func _chime() -> AudioStreamWAV:
	var b := _buf(1.4)
	for i in b.size():
		var t := float(i) / RATE
		var v := sin(TAU * 660.0 * t) * exp(-t * 3.0)
		if t > 0.5:
			v += sin(TAU * 523.0 * (t - 0.5)) * exp(-(t - 0.5) * 3.0)
		b[i] = v * 0.4
	return _wav(b)


## Breathing on the line.
static func _breath() -> AudioStreamWAV:
	var b := _buf(3.6)
	var y := 0.0
	for i in b.size():
		var t := float(i) / RATE
		y += (randf_range(-1, 1) - y) * 0.15
		var e := pow(maxf(0.0, sin(PI * t / 1.2)), 2.0)
		b[i] = y * e * 0.8
	return _wav(b)


## Heavy storage door.
static func _clank() -> AudioStreamWAV:
	var b := _buf(1.2)
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for f: float in [180.0, 287.0, 413.0, 590.0]:
			v += sin(TAU * f * t) * 0.2
		b[i] = v * exp(-t * 3.5) + randf_range(-1, 1) * exp(-t * 30.0) * 0.6
	return _wav(b)


## A bunch of keys jingling.
static func _keys() -> AudioStreamWAV:
	var b := _buf(0.6)
	var hits := []
	for k in 6:
		hits.append(randf_range(0.0, 0.4))
	for i in b.size():
		var t := float(i) / RATE
		var v := 0.0
		for h: float in hits:
			if t >= h:
				var dt := t - h
				v += (sin(TAU * 3200.0 * dt) + sin(TAU * 4700.0 * dt) * 0.6) * exp(-dt * 40.0) * 0.25
		b[i] = v
	return _wav(b)
