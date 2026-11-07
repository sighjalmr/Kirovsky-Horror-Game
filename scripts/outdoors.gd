class_name Outdoors
extends Node3D

## The square outside «Кировский» at night, built round the store you play
## in, so that Gordeev can unlock the glass doors with the spare key from the
## booth and walk out into the rain: the porch, the steps, the kiosk, the
## phone booths, the bins, his own «Жигули» parked on the asphalt.
##
## It is the cutscenes' Exterior, embedded: moved 0.3 m out so its facade
## sits in the store's front wall, and 0.75 m down so its porch is level with
## the hall floor. Gordeev's feet (Player) and the people walking out (Npc)
## follow ground_y(): 0 in the hall and on the porch, down the steps, −0.75
## on the square. Invisible walls keep him to the square (and off the road).
## The killer neither sees nor hears anything out here (Killer).
##
## What happens out here is in the chapters: night one's call from the phone
## booth, night two's «бобик» behind the kiosk (NightOne, NightTwo).

const OFFSET := Vector3(0, -Exterior.PORCH, -0.3)
const GROUND := -Exterior.PORCH
## The porch (x, z), level with the hall, and the steps down along its front.
const PORCH := Rect2(-4.5, -5.8, 14.0, 5.5)
const STEPS := Rect2(-4.9, -7.45, 14.8, 1.65)
## Out of the doors means z below this.
const OUT_Z := -0.35
## The phone booths: the right one is where night one's call comes from.
const BOOTH := Vector3(14.78, GROUND, -2.3)
## The kiosk, and where the «бобик» stands behind it, out of sight of the doors.
const KIOSK := Vector3(-15.5, GROUND, -17.1)
const BOBIK_SPOT := Vector3(-18.0, GROUND, -19.9)

const OUT_FOG := Color(0.07, 0.075, 0.085)
const OUT_SKY := Color(0.035, 0.04, 0.05)
const OUT_AMBIENT := Color(0.45, 0.5, 0.62)

static var active: Outdoors

var main: Node
var ext: Exterior
## 0 in the hall, 1 out on the square (eased): the store's environment and
## the rain blend on it.
var mix := 0.0
## The handset of the right booth: on its hook, or hanging and swinging.
var handset: Node3D
var booth_light: OmniLight3D
var bobik: Node3D

var _rain_sound: AudioStreamPlayer
var _swing := 0.0
var _swing_t := 0.0


## "night" (rain, sodium lamps) or "day" (day four: a grey noon, dry).
var look := "night"


func _init(m: Node, look_ := "night") -> void:
	main = m
	look = look_


func _enter_tree() -> void:
	active = self


func _exit_tree() -> void:
	if active == self:
		active = null


func _ready() -> void:
	ext = Exterior.new(look, true)
	ext.position = OFFSET
	add_child(ext)
	_walls()
	_build_handset()
	_build_yard_lights()
	_rain_sound = AudioStreamPlayer.new()
	_rain_sound.stream = Sfx.get_stream("rain")
	_rain_sound.volume_db = -30.0
	_rain_sound.autoplay = true
	add_child(_rain_sound)


## Height of the ground under a point, or NAN when `n` is not in the night
## store's world (the cutscenes have their own streets).
static func ground_for(n: Node3D) -> float:
	if active == null or not is_instance_valid(active) or not n.is_inside_tree() \
			or n.get_viewport() != active.get_viewport():
		return NAN
	return active.ground_y(n.global_position)


static func is_out(p: Vector3) -> bool:
	return active != null and is_instance_valid(active) and p.z < OUT_Z


func ground_y(p: Vector3) -> float:
	if p.z > 28.05:
		return BackRooms.floor_y(p)  # behind the back wall: the cellar stairs go down
	if p.z >= PORCH.position.y + PORCH.size.y:
		return 0.0  # the hall and the door sill
	var q := Vector2(p.x, p.z)
	if PORCH.has_point(q):
		return 0.0
	if STEPS.has_point(q):
		var t := clampf((PORCH.position.y - p.z) / STEPS.size.y, 0.0, 1.0)
		return lerpf(0.0, GROUND, t)
	return GROUND


func _process(delta: float) -> void:
	var cam: Camera3D = main.player.camera
	var p: Vector3 = main.player.global_position
	mix = move_toward(mix, clampf((OUT_Z - p.z) / 2.0, 0.0, 1.0), delta * 0.8)
	# Rain only over the square, never inside the hall, centred ahead of the eye.
	if ext.rain:
		var c := cam.global_position - cam.global_basis.z * 6.0
		ext.rain.global_position = Vector3(c.x, cam.global_position.y + 9.0, minf(c.z, -16.8))
	var open: bool = main.store.front_open
	_rain_sound.volume_db = -80.0 if look != "night" else lerpf(-30.0 if not open else -20.0, -7.0, mix)
	if handset and _swing > 0.001:
		_swing_t += delta
		_swing = maxf(0.0, _swing - delta * 0.012)
		handset.rotation.x = sin(_swing_t * 2.6) * _swing
		handset.rotation.z = sin(_swing_t * 1.9 + 1.0) * _swing * 0.5


## The store's environment, blended towards the night air outside.
func blend_env(env: Environment) -> void:
	if mix <= 0.001 or look != "night":
		return
	env.fog_light_color = env.fog_light_color.lerp(OUT_FOG, mix)
	env.background_color = env.background_color.lerp(OUT_SKY, mix)
	env.ambient_light_color = Color(0.6, 0.65, 0.6).lerp(OUT_AMBIENT, mix)
	env.ambient_light_energy = lerpf(env.ambient_light_energy, 0.1, mix)
	env.fog_depth_begin = lerpf(env.fog_depth_begin, 5.0, mix)
	env.fog_depth_end = lerpf(env.fog_depth_end, 60.0, mix)


# --- the square's edges ---------------------------------------------------------

func _wall(center_xz: Vector2, size_xz: Vector2, parent: Node3D = null) -> void:
	Props.collider(parent if parent else self, Vector3(center_xz.x, GROUND - 1.0, center_xz.y),
		Vector3(size_xz.x, 6.0, size_xz.y))


func _walls() -> void:
	# The porch drops 75 cm at its ends: down the steps only.
	_wall(Vector2(-4.62, -3.05), Vector2(0.12, 5.5))
	_wall(Vector2(9.62, -3.05), Vector2(0.12, 5.5))
	# The building's wings either side of the store's own front wall.
	_wall(Vector2(-18.0, 0.2), Vector2(12.2, 1.0))
	_wall(Vector2(14.2, 0.2), Vector2(4.4, 1.0))
	# The square ends: the corner of the building on the left, the blocks'
	# lawn on the right, the kerb of the road in front.
	_wall(Vector2(-23.75, -11.0), Vector2(0.3, 22.0))
	_wall(Vector2(22.0, -11.0), Vector2(0.3, 22.0))
	_wall(Vector2(-1.0, -21.9), Vector2(46.0, 0.3))
	# Street furniture (exterior coordinates moved by OFFSET).
	_wall(Vector2(KIOSK.x, KIOSK.z - 0.1), Vector2(3.15, 2.35))          # the Blender kiosk: 3.1 x 2.3 m with its roof
	_wall(Vector2(14.3, -2.3), Vector2(1.95, 0.95))                   # phone booths
	_wall(Vector2(20.5, -3.3), Vector2(4.2, 1.6))                     # bins
	_wall(Vector2(-20.1, -13.1), Vector2(6.4, 0.15))                  # lawn fence, gap for the path
	_wall(Vector2(-10.5, -13.1), Vector2(9.2, 0.15))
	_wall(Vector2(-10.5, -13.8), Vector2(2.1, 0.55))                  # benches
	_wall(Vector2(-19.5, -13.8), Vector2(2.1, 0.55))
	for px: float in [9.4, 5.5, -0.5, -4.4]:                          # canopy posts
		_wall(Vector2(px, -5.7), Vector2(0.4, 0.4))
	for fx: float in [10.6, -5.6]:                                    # flower boxes
		_wall(Vector2(fx, -4.3), Vector2(1.8, 3.5))
	for t: Vector2 in [Vector2(15.5, -7.3), Vector2(19.0, -3.8), Vector2(-9.5, -3.8), Vector2(-13.0, -8.3),
			Vector2(-17.5, -4.3), Vector2(-21.5, -9.8)]:              # firs
		_wall(t, Vector2(0.7, 0.7))
	_wall(Vector2(-17.6, -1.2), Vector2(1.6, 1.2))                    # bottle crates
	_wall(Vector2(-14.2, -1.7), Vector2(1.4, 1.0))
	var z := Exterior.ZHIGULI_SPOT + OFFSET                           # Gordeev's «Жигули»
	_wall(Vector2(z.x, z.z), Vector2(1.75, 4.3))
	for u: Vector2 in [Vector2(-4.6, -8.0), Vector2(9.6, -8.0), Vector2(-13.5, -13.7)]:
		_wall(u, Vector2(0.5, 0.5))                                   # urns


## Two more lamps on the dark left side of the square: one on a pole by the
## kiosk, a bare bulb on the corner of the building over the way round to
## the back yard.
func _build_yard_lights() -> void:
	var s := Fittings.street_lamp(self, Vector3(-21.8, GROUND, -18.6), Vector3(-17.0, GROUND, -17.0))
	s.spot_range = 16.0
	s.spot_angle = 55.0
	s.light_energy = 6.0
	s.shadow_enabled = true
	_wall(Vector2(-21.8, -18.6), Vector2(0.3, 0.3))
	var bulb := OmniLight3D.new()
	bulb.position = Vector3(-23.2, GROUND + 3.4, -0.7)
	bulb.light_color = Color(1.0, 0.8, 0.55)
	bulb.omni_range = 11.0
	bulb.light_energy = 1.6 if look == "night" else 0.0
	add_child(bulb)
	if look != "night":
		s.light_energy = 0.0
	var kit := MeshBuilder.Kit.new()
	kit.b("white", Color(1, 0.9, 0.7), Color(3.0, 2.4, 1.5)).cylinder(Props.at(-23.2, GROUND + 3.35, -0.7), 0.05, 0.05, 0.1, 8)
	kit.b("metal", Color(0.3, 0.3, 0.3)).box(Props.at(-23.2, GROUND + 3.45, -0.5), Vector3(0.04, 0.04, 0.45))
	kit.build(self, false)


# --- night one: the call from the booth -------------------------------------------

func _build_handset() -> void:
	# On the back wall of the right booth: the payphone at z −1.85 + 0.33.
	var pivot := Node3D.new()
	pivot.position = BOOTH + Vector3(-0.14, 1.36, 0.35)
	add_child(pivot)
	handset = pivot
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	kit.b("rubber", Color(0.08, 0.08, 0.08)).capsule(Transform3D.IDENTITY, Vector3(0, 0, 0), Vector3(0, 0.2, 0), 0.03, 0.03, 6)
	kit.build(pivot, false)
	booth_light = OmniLight3D.new()
	booth_light.position = BOOTH + Vector3(0, 2.05, 0)
	booth_light.light_color = Color(1.0, 0.82, 0.55)
	booth_light.omni_range = 4.5
	booth_light.light_energy = 0.0
	add_child(booth_light)


## The handset left off the hook: it hangs on its cord, still swinging, and
## the bulb in the booth is on.
func hang_handset() -> void:
	booth_light.light_energy = 1.2
	for c in handset.get_children():
		c.queue_free()
	# Pivots at the box; the handset hangs 60 cm below it on the cord.
	handset.position = BOOTH + Vector3(-0.14, 1.3, 0.3)
	handset.rotation = Vector3.ZERO
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	kit.b("rubber", Color(0.08, 0.08, 0.08)).capsule(Transform3D.IDENTITY, Vector3(0, -0.62, 0), Vector3(0, -0.42, 0), 0.03,
		0.03, 6)
	kit.b("rubber", Color(0.05, 0.05, 0.05)).capsule(Transform3D.IDENTITY, Vector3(0, -0.42, 0), Vector3(0, 0, 0), 0.006,
		0.006, 4)
	kit.build(handset, false)
	_swing = 0.35
	_swing_t = 0.0


## Gordeev puts it back on the hook.
func replace_handset() -> void:
	for c in handset.get_children():
		c.queue_free()
	var kit := MeshBuilder.Kit.new()
	kit.ao = false
	kit.b("rubber", Color(0.08, 0.08, 0.08)).capsule(Transform3D.IDENTITY, Vector3(0, 0, 0), Vector3(0, 0.2, 0), 0.03, 0.03, 6)
	kit.build(handset, false)
	handset.position = BOOTH + Vector3(-0.14, 1.36, 0.35)
	handset.rotation = Vector3.ZERO
	_swing = 0.0


# --- night two: the «бобик» behind the kiosk ---------------------------------------

func park_bobik() -> Node3D:
	bobik = Vehicles.bobik()
	add_child(bobik)
	bobik.position = BOBIK_SPOT
	bobik.rotation.y = PI * 0.5  # nose to the left along the road, driver's side to the kiosk
	_wall(Vector2.ZERO, Vector2(1.85, 4.1), bobik)
	return bobik


## A world point of the «бобик» from its own (nose −Z) coordinates.
func bobik_point(local: Vector3) -> Vector3:
	return bobik.global_transform * local


## A fresh cigarette end on the ground (the booth's floor, by the car).
func drop_butt(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	var b := MeshBuilder.Kit.new()
	b.b("white", Color(0.95, 0.93, 0.88)).cylinder(Props.rot(Vector3.BACK, PI * 0.5, pos + Vector3(0, 0.005, 0)), 0.005, 0.005,
		0.03, 8)
	b.b("rubber", Color(0.6, 0.45, 0.25)).cylinder(Props.rot(Vector3.BACK, PI * 0.5, pos + Vector3(0.03, 0.005, 0)), 0.005,
		0.005, 0.012, 8)
	b.build(n, false)
	add_child(n)
	return n
