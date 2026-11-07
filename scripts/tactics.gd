class_name Tactics
extends Node

## What Gordeev can do against him besides running and hiding, and what makes
## every night his own. Main adds one to every night shift.
##
## - A tin or a bottle off the shelf (E), thrown with Q: it clatters where it
##   lands and he goes to look.
## - Broken glass on the floor: walk on it upright and it crunches.
## - Валидол (V): two tablets a shift. The breath comes back and the hand
##   with the torch stops shaking. Run yourself out without it and the
##   picture darkens at the edges.
## - The plan of the floor on the post wall: looked at once, copied into the
##   notebook, then M opens it anywhere.
## - The man himself: he does not keep to a timetable. Left alone too long,
##   Gordeev hears him coming his way; after a chase he gives him a breather.
##   He learns: from night two he looks into hiding places, from night three
##   he walks softly, from night four he hears further.
## - Signs he has been somewhere: wet boot prints, a cloth pulled off a chest,
##   a tin set in the middle of the floor. Each is noticed when Gordeev comes
##   close.

const SPOTS := {
	"take_peas1": [Vector3(2.15, 0, 13.6), "can", "Взять банку горошка с полки"],
	"take_peas2": [Vector3(3.85, 0, 17.2), "can", "Взять банку тушёнки с полки"],
	"take_peas3": [Vector3(2.15, 0, 22.6), "can", "Взять банку кильки с полки"],
	"take_salt": [Vector3(-2.15, 0, 20.4), "can", "Взять банку икры кабачковой"],
	"take_kefir1": [Vector3(10.7, 0, 14.8), "bottle", "Взять бутылку кефира"],
	"take_kefir2": [Vector3(10.7, 0, 22.1), "bottle", "Взять бутылку молока"],
	"take_crate": [Vector3(6.6, 0, 26.4), "bottle", "Взять пустую бутылку из ящика"],
}
## Broken glass: the smashed juice jar, and two more in the dark.
const SHARDS := [Vector3(3.3, 0, 22.4), Vector3(-8.0, 0, 25.6), Vector3(-3.0, 0, 11.4)]
const PILLS_A_NIGHT := 2
## Seconds of play with him far away before he drifts Gordeev's way.
const CALM_LIMIT := 70.0
const PLAN_POS := Vector3(8.0, 0, 4.1)

const G_TOOK_CAN := "Банка. Если бросить подальше, загремит на весь зал."
const G_TOOK_BOTTLE := "Бутылка. Разобьётся громко."
const G_PILL := "Валидол под язык. Холодок. Отпускает."
const G_NO_PILLS := "Валидола больше нет. Надо было брать вторую пластинку."
const G_PILL_NOT_NOW := "Сердце пока терпит. Валидол поберегу."
const G_STRAIN := "В глазах темнеет. Ещё немного, и сердце не выдержит."
const G_GLASS := "Стекло под ногами. Хрустнуло на весь зал."
const G_PLAN := "План эвакуации. Перерисую себе в блокнот: в темноте пригодится."
const TRACE_LINES := {
	"boots": "Мокрые следы сапог. От склада к посту. Час назад их не было.",
	"cloth": "Покрывало с ларя сдёрнуто. Я его не трогал.",
	"tin": "Банка горошка посреди прохода. Стоит ровно, этикеткой к посту. Это для меня.",
}

var main: Node
var night_no := 1
var held := ""
var pills := PILLS_A_NIGHT
## 0..1: how hard the heart is working; grows each time he runs out of breath.
var strain := 0.0
var _calm := 0.0
var _rest := 0.0
var _glass_t := 0.0
var _traces: Array = []
var _trace_times: Array = []
var _held_mesh: MeshInstance3D
var _plan: PlanView
var _vignette := 0.55


func _init(m: Node, night_number: int) -> void:
	main = m
	night_no = night_number


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var store: Store = main.store
	for id: String in SPOTS:
		var s: Array = SPOTS[id]
		store.add_interactable(id, s[0], s[2], 1.1, false)
	store.add_interactable("plan", PLAN_POS, "Посмотреть план эвакуации на стене поста", 1.2, false)
	for p: Vector3 in SHARDS:
		if p.distance_to(Vector3(3.3, 0, 22.4)) > 0.1:
			Equip.decal(store, p, 0.8, "juice", randf() * TAU, Color(0.75, 0.8, 0.8))
	var k: Killer = main.killer
	k.quiet = night_no >= 3
	k.hear_mult = 1.4 if night_no >= 4 else 1.0
	k.lost.connect(func() -> void: _rest = 25.0)
	main.player.out_of_breath.connect(_on_winded)
	_plan = PlanView.new()
	main.hud.add_child(_plan)
	_held_mesh = MeshInstance3D.new()
	_held_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_held_mesh.position = Vector3(-0.2, -0.2, -0.42)
	_held_mesh.visible = false
	main.player.camera.add_child(_held_mesh)
	# Two signs of him a night, at a random hour while he is inside.
	var kinds := ["boots", "cloth", "tin"]
	kinds.shuffle()
	for i in 2:
		_trace_times.append([Main.clock(23, 40) + i * 150.0 + randf_range(0.0, 90.0), kinds[i]])


## Story code asks first: these ids belong here.
func interact(id: String) -> bool:
	if SPOTS.has(id):
		_take(SPOTS[id][1])
		return true
	if id == "plan":
		Settings.plan_copied = true
		Settings.save()
		main.hud.say(G_PLAN, -1.0, true)
		open_plan()
		return true
	return false


func _take(kind: String) -> void:
	if held != "":
		main.hud.say("Руки заняты: сначала бросить то, что держу (Q).", -1.0, true)
		return
	held = kind
	Sfx.play_3d(main.view, "pickup", main.player.global_position + Vector3(0, 1.0, 0), -10.0, 1.3)
	main.hud.say(G_TOOK_CAN if kind == "can" else G_TOOK_BOTTLE, -1.0, true)
	main.hint("throw", "Q — бросить. Он пойдёт на звук туда, где упадёт")
	_held_mesh.mesh = _item_mesh(kind)
	_held_mesh.material_override = _item_mat(kind)
	_held_mesh.visible = true


static func _item_mesh(kind: String) -> Mesh:
	var c := CylinderMesh.new()
	if kind == "can":
		c.top_radius = 0.037
		c.bottom_radius = 0.037
		c.height = 0.11
	else:
		c.top_radius = 0.016
		c.bottom_radius = 0.034
		c.height = 0.27
	return c


static func _item_mat(kind: String) -> Material:
	if kind == "can":
		return Mats.get_mat("chrome", Color(0.75, 0.75, 0.7))
	return Mats.get_mat("glass", Color(0.75, 0.85, 0.8, 0.6), Color.BLACK, Mats.GLASS)


func throw() -> void:
	if held == "" or main.player.hidden or main.player.busy:
		return
	var kind := held
	held = ""
	_held_mesh.visible = false
	var cam: Camera3D = main.player.camera
	var fwd := -cam.global_transform.basis.z
	var item := Thrown.new()
	item.kind = kind
	item.main = main
	main.world.add_child(item)
	item.global_position = cam.global_position + fwd * 0.45 + Vector3(0, -0.15, 0)
	item.linear_velocity = fwd * 9.5 + Vector3(0, 2.2, 0)
	item.angular_velocity = Vector3(randf_range(-8, 8), randf_range(-4, 4), randf_range(-8, 8))
	Sfx.play_3d(main.view, "swing", cam.global_position, -14.0, 1.4)


func take_pill() -> void:
	if pills <= 0:
		main.hud.say(G_NO_PILLS, -1.0, true)
		return
	var p: Player = main.player
	if not p.winded and p.breath > 0.6 and strain < 0.2:
		main.hud.say(G_PILL_NOT_NOW, -1.0, true)
		return
	pills -= 1
	p.breath = 1.0
	p.winded = false
	strain = 0.0
	Sfx.play_2d(main, "pickup", -12.0, "Master", 1.6)
	main.hud.say(G_PILL, -1.0, true)
	main.hud.flash_note("Валидол: осталось %d" % pills)


func _on_winded() -> void:
	strain = minf(1.0, strain + 0.4)
	if strain >= 0.75:
		main.hud.say(G_STRAIN, -1.0, true)
	if pills > 0:
		main.hint("pill", "V — валидол под язык: одышка и дрожь пройдут. На смену две таблетки")


func open_plan() -> void:
	_plan.show_plan(main)


func plan_open() -> bool:
	return _plan.visible


func close_plan() -> void:
	_plan.close()


func update(delta: float) -> void:
	var p: Player = main.player
	# The heart settles slowly; the hand shakes and the edges close in while it races.
	strain = maxf(0.0, strain - delta * 0.012)
	p.tremor = strain
	_vignette = lerpf(_vignette, 0.55 + strain * 0.45, delta * 2.0)
	if not main._struggling:
		main.post.set_shader_parameter("vignette", _vignette)
	_held_mesh.position.y = -0.2 + sin(Time.get_ticks_msec() * 0.008) * 0.004 * strain
	_watch_glass(delta)
	_director(delta)
	_place_traces()
	_notice_traces()


func _watch_glass(delta: float) -> void:
	_glass_t -= delta
	var p: Player = main.player
	if _glass_t > 0.0 or p.crouching or p.velocity.length() < 0.5:
		return
	for s: Vector3 in SHARDS:
		if Vector2(s.x - p.global_position.x, s.z - p.global_position.z).length() < 0.55:
			_glass_t = 3.0
			Sfx.play_3d(main.view, "cans", s + Vector3(0, 0.05, 0), -10.0, 1.9)
			Sfx.play_3d(main.view, "click", s + Vector3(0, 0.05, 0), -4.0, 0.6)
			main.on_noise(s, 8.0)
			main.hud.say(G_GLASS, -1.0, true)
			main.hint("glass", "Пригнитесь (C), чтобы ступать по стеклу тихо")
			return


## Not to a timetable: left alone too long, he drifts Gordeev's way; after a
## chase, a breather. From night two he looks into a hiding place on the way.
func _director(delta: float) -> void:
	var k: Killer = main.killer
	var p: Player = main.player
	_rest = maxf(0.0, _rest - delta)
	if not k.is_active() or k.leaving or main.chasing or k.state != Killer.State.PATROL \
			or Outdoors.is_out(p.global_position) or main._morning:
		_calm = 0.0
		return
	var d := k.global_position.distance_to(p.global_position)
	if d < 12.0 or _rest > 0.0:
		_calm = 0.0
		return
	_calm += delta
	var limit := CALM_LIMIT * (0.8 if night_no >= 3 else 1.0)
	if _calm < limit:
		return
	_calm = 0.0
	var store: Store = main.store
	if night_no >= 2 and randf() < 0.45:
		var best: Array = []
		var best_d := 14.0
		for id: String in NightOne.HIDES:
			var h: Array = NightOne.HIDES[id]
			var hd := (h[2] as Vector3).distance_to(p.global_position)
			if hd < best_d:
				best_d = hd
				best = h
		if not best.is_empty():
			k.lurk_at(best[2], 6.0)
			return
	# Somewhere five to eight metres from him, along a walkable line.
	for i in 12:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
		var to := p.global_position + dir * randf_range(5.0, 8.0)
		to.y = 0.0
		if store.walkable(p.global_position, to):
			k.wander_to(to)
			return
	k.wander_to(p.global_position)


func _place_traces() -> void:
	if _trace_times.is_empty() or main.minutes < _trace_times[0][0]:
		return
	var k: Killer = main.killer
	if not k.is_active():
		return
	var kind: String = _trace_times[0][1]
	var at := _trace_spot(kind)
	var p: Player = main.player
	if at == Vector3.INF or at.distance_to(p.global_position) < 9.0:
		return  # wait until he is elsewhere
	_trace_times.pop_front()
	var store: Store = main.store
	match kind:
		"boots":
			# From the storage door towards the post, drying as they go.
			for i in 9:
				var t := float(i) / 8.0
				var q: Vector3 = Vector3(9.0, 0, 26.0).lerp(Vector3(7.6, 0, 12.0), t)
				q.x += (0.12 if i % 2 == 0 else -0.12)
				Equip.decal(store, q, 0.42, "boots", PI, Color(0.55, 0.58, 0.62, 1.0 - t * 0.6))
		"cloth":
			store.lift_cloth(_trace_chest)
			Sfx.play_3d(store, "cloth", at, -16.0)
		"tin":
			var mi := MeshInstance3D.new()
			mi.mesh = _item_mesh("can")
			mi.material_override = _item_mat("can")
			store.add_child(mi)
			mi.position = at + Vector3(0, 0.055, 0)
	_traces.append([at, kind])


var _trace_chest := ""


func _trace_spot(kind: String) -> Vector3:
	var store: Store = main.store
	match kind:
		"boots":
			return Vector3(7.6, 0, 12.0)
		"cloth":
			if _trace_chest == "":
				for id: String in ["D2", "A1", "D4", "A4", "D1"]:
					if store.chests.has(id) and not store.chests[id].lifted:
						_trace_chest = id
						break
			if _trace_chest == "":
				return Vector3.INF
			return store.chests[_trace_chest].pos
		"tin":
			return Vector3(3.0, 0, 15.5)
	return Vector3.INF


func _notice_traces() -> void:
	var p: Player = main.player
	for i in range(_traces.size() - 1, -1, -1):
		var at: Vector3 = _traces[i][0]
		if at.distance_to(p.global_position) > 2.6:
			continue
		var lit: bool = p.flashlight_on or main.store.is_lit(at)
		if not lit and at.distance_to(p.global_position) > 1.2:
			continue
		main.hud.say(TRACE_LINES[_traces[i][1]], -1.0, true)
		Sfx.play_2d(main, "stinger", -14.0)
		_traces.remove_at(i)


## A tin or bottle in flight: where it first hits, it clatters, and he hears.
class Thrown extends RigidBody3D:
	var kind := "can"
	var main: Node
	var _hit := false
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 16
		collision_mask = 1
		mass = 0.4
		contact_monitor = true
		max_contacts_reported = 2
		continuous_cd = true
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.04
		sh.height = 0.12 if kind == "can" else 0.26
		cs.shape = sh
		add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = Tactics._item_mesh(kind)
		mi.material_override = Tactics._item_mat(kind)
		add_child(mi)
		body_entered.connect(_on_hit)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t > 25.0:
			queue_free()

	func _on_hit(_b: Node) -> void:
		if _hit or _t < 0.05:
			return
		_hit = true
		var at := global_position
		if kind == "can":
			Sfx.play_3d(main.view, "cans", at, -2.0, randf_range(1.15, 1.3))
		else:
			Sfx.play_3d(main.view, "cans", at, 0.0, 1.8)
			Sfx.play_3d(main.view, "clank", at, -4.0, 1.9)
			Equip.decal(main.store, Vector3(at.x, 0, at.z), 0.6, "juice", randf() * TAU, Color(0.85, 0.9, 0.9))
			queue_free()
		main.on_noise(Vector3(at.x, 0, at.z), 14.0)


## The fire-evacuation plan of the ground floor, as Gordeev copied it into his
## notebook: the hall, the rows, the doors, where he stands.
class PlanView extends Control:
	const SCALE := 28.0
	const ORIGIN := Vector2(960, 960)
	var main: Node

	func _init() -> void:
		position = Vector2.ZERO
		size = Vector2(1920, 1080)
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS

	func show_plan(m: Node) -> void:
		main = m
		visible = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		queue_redraw()

	func close() -> void:
		visible = false
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	func _p(x: float, z: float) -> Vector2:
		# x to the right, z (deeper into the store) up the sheet.
		return ORIGIN + Vector2(x * SCALE, -z * SCALE)

	func _rect(x0: float, z0: float, x1: float, z1: float, fill: Color, line: Color, w := 2.0) -> void:
		var a := _p(x0, z1)
		var r := Rect2(a, _p(x1, z0) - a)
		draw_rect(r, fill, true)
		draw_rect(r, line, false, w)

	func _text(at: Vector2, s: String, sz := 18, c := Color(0.16, 0.15, 0.13)) -> void:
		draw_string(ThemeDB.fallback_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)

	func _draw() -> void:
		var ink := Color(0.16, 0.15, 0.13)
		var red := Color(0.7, 0.12, 0.1)
		var green := Color(0.1, 0.5, 0.25)
		var shelf := Color(0.78, 0.74, 0.64)
		draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(540, 30, 840, 1020), Color(0.9, 0.88, 0.8))
		_text(Vector2(580, 72), "ПЛАН ЭВАКУАЦИИ ЛЮДЕЙ ПРИ ПОЖАРЕ", 26, red)
		_text(Vector2(580, 102), "Универсам «Кировский». 1 этаж. Перерисовано от руки", 18)
		# The hall and the back passage.
		_rect(-12, 0, 12, 28, Color(0.95, 0.93, 0.86), ink, 3.0)
		for x: float in [-6.0, 0.0, 6.0]:
			_rect(x - 0.45, 12.0, x + 0.45, 24.5, shelf, ink, 1.0)
		_rect(-11.9, 12.0, -11.2, 25.0, shelf, ink, 1.0)
		_rect(11.2, 12.0, 11.9, 25.0, shelf, ink, 1.0)
		for z0: float in [14.0, 16.8, 19.6, 22.4]:
			_rect(-9.35, z0 - 0.5, -8.35, z0 + 0.5, Color(0.8, 0.86, 0.9), ink, 1.0)
			_rect(8.35, z0 - 0.5, 9.35, z0 + 0.5, Color(0.8, 0.86, 0.9), ink, 1.0)
		for x: float in [-3.25, 0.0, 3.25]:
			_rect(x - 0.6, 7.2, x + 0.6, 9.6, shelf, ink, 1.0)
		_rect(-12, 0.2, -8.5, 5.5, shelf, ink, 1.0)
		_rect(7.0, 0.2, 11.8, 4.8, Color(0.86, 0.82, 0.7), ink, 2.0)
		_text(_p(-9.6, 19.0), "ЗАМОРОЗКА", 15)
		_text(_p(-4.4, 19.0), "БАКАЛЕЯ", 15)
		_text(_p(1.4, 19.0), "КОНСЕРВЫ", 15)
		_text(_p(6.9, 19.0), "МОЛОЧНЫЙ", 15)
		_text(_p(-3.6, 10.6), "КАССЫ", 15)
		_text(_p(-11.8, 3.4), "КАМЕРА", 14)
		_text(_p(-11.8, 2.7), "ХРАНЕНИЯ", 14)
		_text(_p(7.6, 2.6), "ПОСТ ОХРАНЫ", 15)
		_text(_p(-6.0, 26.2), "ЗАДНИЙ ПРОХОД", 15)
		# Doors in the back wall.
		for d: Array in [[9.0, "СКЛАД"], [Store.CELLAR_X, "ПОДВАЛ"], [Store.OFFICE_X, "КАБИНЕТ"]]:
			var at := _p(d[0], 28.0)
			draw_rect(Rect2(at - Vector2(16, 4), Vector2(32, 8)), red)
			_text(at + Vector2(-26, -12), d[1], 15, red)
		_text(_p(-1.0, 28.0) + Vector2(-20, 30), "щиток", 14)
		# The way out: the glass doors.
		var ex := _p(-1.0, 0.0)
		draw_rect(Rect2(ex - Vector2(30, 4), Vector2(60, 8)), green)
		_text(ex + Vector2(-34, 28), "ВЫХОД", 18, green)
		draw_line(_p(-1.0, 6.0), ex + Vector2(0, -8), green, 4.0)
		draw_line(ex + Vector2(0, -8), ex + Vector2(-10, -22), green, 4.0)
		draw_line(ex + Vector2(0, -8), ex + Vector2(10, -22), green, 4.0)
		# Where he stands, and which way he looks.
		if main and main.player:
			var pp: Vector3 = main.player.global_position
			if pp.z > -1.0:
				var at := _p(pp.x, pp.z)
				var f: Vector3 = -main.player.global_transform.basis.z
				var dir := Vector2(f.x, -f.z).normalized()
				draw_circle(at, 9.0, red)
				draw_line(at, at + dir * 24.0, red, 3.0)
				_text(at + Vector2(12, -10), "я", 18, red)
		_text(Vector2(580, 1030), "M или Esc — закрыть", 18, Color(0.4, 0.38, 0.33))
