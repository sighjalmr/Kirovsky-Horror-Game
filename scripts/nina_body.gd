class_name NinaBody
extends Node3D

## Nina in the old refrigerated cabinet: the same woman as in the flashback
## (Rocketbox Female_Adult_14), folded knees to chest, sitting on the cabinet
## floor, head fallen forward onto the knees and over to the left. She is
## wrapped in the brown paper of the meat counter, crumpled sheets tied with
## twine, open at the top where the paper has torn: the hair spills out, the
## grey back of the neck shows, and her right hand has slipped out at the
## side. «Р.» in pencil on the front sheet.
##
## Origin: the middle of the cabinet floor; front (the doors) is -Z.

const PAPER := Color(0.62, 0.56, 0.5)
## Folding: bone -> direction it points in her own space (-Z forward, +Y up).
const FOLD := {
	"Bip01 Spine": Vector3(0.0, 0.85, -0.5),
	"Bip01 Spine1": Vector3(0.05, 0.7, -0.7),
	"Bip01 Spine2": Vector3(0.1, 0.5, -0.85),
	"Bip01 Neck": Vector3(-0.35, -0.1, -0.95),
	"Bip01 L Thigh": Vector3(0.12, 0.72, -0.68),
	"Bip01 R Thigh": Vector3(-0.08, 0.72, -0.68),
	"Bip01 L Calf": Vector3(0.05, -0.92, 0.38),
	"Bip01 R Calf": Vector3(-0.05, -0.92, 0.38),
	"Bip01 L UpperArm": Vector3(0.2, -0.85, -0.45),
	"Bip01 L Forearm": Vector3(0.8, -0.2, -0.55),
	"Bip01 R UpperArm": Vector3(-0.25, -0.9, -0.35),
	"Bip01 R Forearm": Vector3(-0.2, -0.95, 0.1),
	"Bip01 R Hand": Vector3(-0.15, -0.98, 0.1),
}

## Limbs and trunk as capsules, [a, b, radius], in this node's space.
const CAPSULES := [
	["Bip01 Pelvis", "Bip01 Spine2", 0.15], ["Bip01 Spine2", "Bip01 Neck", 0.14], ["Bip01 Neck", "Bip01 Head", 0.07],
	["Bip01 L Thigh", "Bip01 L Calf", 0.085], ["Bip01 R Thigh", "Bip01 R Calf", 0.085],
	["Bip01 L Calf", "Bip01 L Foot", 0.06], ["Bip01 R Calf", "Bip01 R Foot", 0.06],
	["Bip01 L UpperArm", "Bip01 L Forearm", 0.05], ["Bip01 L Forearm", "Bip01 L Hand", 0.045],
	["Bip01 R UpperArm", "Bip01 R Forearm", 0.05],
]

var person: Person
var _frames := 0
var _capsules: Array = []


func _ready() -> void:
	person = Person.new().setup("woman2", true)
	add_child(person)
	# Sitting on the floor of the cabinet: the chair pose with no chair.
	person.position = Vector3(0, -0.4, 0.1)
	person.play("sit", 0.0, 0.0)
	person.player.seek(0.5, true)
	for b: String in FOLD:
		person.aim(b, FOLD[b], 1.0)
	_pale(person)


## Four days in a cold cabinet: the colour gone grey and blue.
static func _pale(p: Person) -> void:
	for mi: MeshInstance3D in p.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m:
				m = m.duplicate()
				m.set_shader_parameter("tint", Color(0.5, 0.53, 0.6))
				mi.set_surface_override_material(i, m)


## The pose holds once the bones are set: nothing in there moves again.
func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 4:
		person.set_process(false)
		set_process(false)
		_capsules = _bones_as_capsules()
		_wrap()


# --- the paper ------------------------------------------------------------------

func _wrap() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 1988
	noise.frequency = 6.0
	noise.fractal_octaves = 3
	var stain := FastNoiseLite.new()
	stain.seed = 7
	stain.frequency = 3.0
	# The big sheet round the folded legs and the body, up to the shoulders,
	# torn open over the head; the right forearm comes out through a tear.
	_sheet(Vector3(0, 0.36, -0.04), 0.03, 0.5, noise, stain, [[_bone("Bip01 R Hand"), 0.13]])
	# A second, rumpled sheet over the knees and the shins, crosswise.
	_sheet(Vector3(0, 0.3, -0.08), 0.05, 0.2, noise, stain, [[_bone("Bip01 R Hand"), 0.15]], 0.9,
		Vector3(0.55, 0.75, -0.35))
	# A loose end over the back and the left shoulder.
	_sheet(Vector3(0.04, 0.42, 0.04), 0.065, 0.35, noise, stain, [[_bone("Bip01 Head"), 0.18], [_bone("Bip01 R Hand"), 0.15],
		[Vector3(0, 0.25, -0.35), 0.32]], -0.6, Vector3(-0.3, 0.9, 0.3))
	# Twine, three turns.
	var kit := MeshBuilder.Kit.new()
	var twine := kit.b("cloth", Color(0.5, 0.44, 0.33))
	for k in 3:
		var y := 0.14 + k * 0.17
		var r := 0.29 - absf(k - 1) * 0.02
		twine.cylinder(Props.rot(Vector3.BACK, 0.05 * (k - 1), Vector3(0, y, -0.03)), r, r, 0.008, 20)
	# What seeped through and pooled under her.
	kit.b("blood", Color(0.2, 0.06, 0.05)).cylinder(Props.at(0.03, 0.002, -0.08), 0.27, 0.27, 0.003, 18)
	kit.build(self, false)
	var mark := Label3D.new()
	mark.text = "Р."
	mark.font_size = 44
	mark.pixel_size = 0.0018
	mark.modulate = Color(0.13, 0.12, 0.13)
	mark.position = Vector3(0.09, 0.42, -0.305)
	mark.rotation = Vector3(0, 0, 0.1)
	mark.shaded = true
	add_child(mark)


func _bone(n: String) -> Vector3:
	var sk := person.skeleton
	return to_local(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(n)).origin)


func _bones_as_capsules() -> Array:
	var out: Array = []
	for c: Array in CAPSULES:
		out.append([_bone(c[0]), _bone(c[1]), c[2]])
	return out


## How far `p` is outside her (negative inside).
func _sdf(p: Vector3) -> float:
	var best := INF
	for c: Array in _capsules:
		var a: Vector3 = c[0]
		var ab: Vector3 = (c[1] as Vector3) - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t) - float(c[2]))
	return best


## One crumpled sheet shrunk round her: from a sphere about `c`, each point
## comes in along its ray until it is `gap` off the body, the folds between
## limbs bridged by smoothing, then creases pressed in by noise. It stops
## raggedly near the top (`top`, -1..1 of the height), with holes torn at
## `holes` ([centre, radius]). `twist` turns the grain so sheets differ.
func _sheet(c: Vector3, gap: float, top: float, noise: FastNoiseLite, stain: FastNoiseLite, holes: Array,
		twist := 0.0, up := Vector3.UP) -> void:
	up = up.normalized()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 30
	var segs := 44
	var dirs: Array[PackedVector3Array] = []
	var rad: Array[PackedFloat32Array] = []
	for i in rings + 1:
		var lat := lerpf(-PI * 0.5, PI * 0.5, float(i) / rings)
		var drow := PackedVector3Array()
		var rrow := PackedFloat32Array()
		for j in segs + 1:
			var lon := float(j) / segs * TAU + twist
			var n := Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))
			# Start no further out than the cabinet floor along the ray.
			var t := 0.6
			if n.y < -0.05:
				t = minf(t, (c.y - 0.01) / -n.y)
			while t > 0.02 and _sdf(c + n * t) > gap:
				t -= 0.01
			if t <= 0.02:
				t = 0.12  # nothing of her that way: the paper folds in
			drow.append(n)
			rrow.append(t)
		dirs.append(drow)
		rad.append(rrow)
	# Paper does not go into the hollows: smooth the radius out a little,
	# never pulling it in.
	for it in 3:
		var nr: Array[PackedFloat32Array] = []
		for i in rings + 1:
			var row := PackedFloat32Array()
			for j in segs + 1:
				var sum := 0.0
				var k := 0
				for di in [-1, 0, 1]:
					for dj in [-1, 0, 1]:
						var ii: int = clampi(i + di, 0, rings)
						var jj: int = posmod(j + dj, segs)
						sum += rad[ii][jj]
						k += 1
				row.append(maxf(rad[i][j], sum / k))
			nr.append(row)
		rad = nr
	var pts: Array[PackedVector3Array] = []
	var keep: Array[PackedByteArray] = []
	for i in rings + 1:
		var row := PackedVector3Array()
		var ok := PackedByteArray()
		for j in segs + 1:
			var n: Vector3 = dirs[i][j % segs if j == segs else j]
			var p := c + n * rad[i][j % segs if j == segs else j]
			var crease := 1.0 - absf(noise.get_noise_3dv(p * 1.3))
			var fine := 1.0 - absf(noise.get_noise_3dv(p * 3.5))
			p += n * ((crease * crease - 0.45) * 0.02 + (fine * fine - 0.45) * 0.007 + noise.get_noise_3dv(p * 0.5) * 0.012)
			p.y = maxf(p.y, 0.006)
			row.append(p)
			var edge := top + noise.get_noise_2d(float(j) * 1.3, twist * 7.0 + float(i) * 0.3) * 0.28
			var open := n.dot(up) > edge
			for h: Array in holes:
				if p.distance_to(h[0]) < float(h[1]) * (1.0 + noise.get_noise_3dv(p * 2.0) * 0.35):
					open = true
			ok.append(0 if open else 1)
		pts.append(row)
		keep.append(ok)
	for i in rings:
		for j in segs:
			if not (keep[i][j] and keep[i + 1][j] and keep[i][j + 1] and keep[i + 1][j + 1]):
				continue
			var quad := [pts[i][j], pts[i + 1][j], pts[i + 1][j + 1], pts[i][j + 1]]
			var uv := [Vector2(j, i), Vector2(j, i + 1), Vector2(j + 1, i + 1), Vector2(j + 1, i)]
			for k: int in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = quad[k]
				# Grease and what came through from inside: darker low down.
				var s := clampf(stain.get_noise_3dv(p) * 1.4 + (0.2 - p.y) * 1.6, 0.0, 1.0)
				var shade := lerpf(1.0, 0.5, s)
				st.set_color(Color(shade, shade * (1.0 - s * 0.15), shade * (1.0 - s * 0.2)))
				st.set_uv((uv[k] as Vector2) * Vector2(1.0 / 12.0, 1.0 / 9.0))
				st.add_vertex(p)
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Mats.get_mat("kraft", PAPER, Color.BLACK, Mats.DOUBLE)
	add_child(mi)
