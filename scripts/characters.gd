class_name Characters
extends RefCounted

## Who is who in the store, and the things they wear or carry that the
## photographed avatars (Person) do not have: Kovpak's muskrat hat and
## briefcase, Vasya's cap, the women's handbags, the killer's knitted hat,
## the scarf over his face and his cleaver. Everything here is built in the
## person's own space (+Y up, -Z forward) around the bone it hangs from.

const NO_RECT := Rect2()

## name -> [avatar in models/people, woman, hat, bag]
const CAST := {
	"kovpak": ["kovpak", false, "fur", "briefcase"],
	"tamara": ["tamara", true, "", "handbag"],
	"tamara_day": ["tamara", true, "", ""],
	"vasya": ["vasya", false, "cap", ""],
	"edik": ["edik", false, "", "holdall"],
	"shopper": ["woman1", true, "", "handbag"],
	"shopper2": ["woman2", true, "", "handbag"],
	"shopper_man": ["man1", false, "", ""],
}


## One of the people of the store, dressed for the street or the shop.
static func build(role: String) -> Person:
	var c: Array = CAST[role]
	var p := Person.new().setup(c[0], c[1])
	match c[2]:
		"fur":
			# A tall muskrat hat, the badge of a director.
			var k := MeshBuilder.Kit.new()
			k.ao = false
			k.b("fur").cylinder(_oval(Vector3(0, 0.105, -0.02), 1.15), 0.116, 0.124, 0.16, 20, Color.WHITE, Rect2(0, 0, 2, 0.6))
			p.attach("Bip01 Head", _built(k))
		"cap":
			var k := MeshBuilder.Kit.new()
			k.ao = false
			var cap := k.b("trousers", Color(0.55, 0.52, 0.5))
			cap.cylinder(_oval(Vector3(0, 0.12, -0.02), 1.15), 0.104, 0.108, 0.06, 20)
			cap.ellipsoid(Props.at(0, 0.18, -0.02), Vector3(0.108, 0.03, 0.118), 16, 6)
			cap.box(Props.rot(Vector3.RIGHT, 0.15, Vector3(0, 0.125, -0.155)), Vector3(0.16, 0.012, 0.07))
			p.attach("Bip01 Head", _built(k))
	match c[3]:
		"briefcase":
			var k := MeshBuilder.Kit.new()
			k.b("leather", Color(0.55, 0.4, 0.3)).box(Props.at(0, -0.24, 0), Vector3(0.09, 0.29, 0.4))
			k.b("chrome").box(Props.at(0, -0.08, 0), Vector3(0.02, 0.03, 0.1))
			p.bag = p.attach("Bip01 L Hand", _built(k))
		"handbag":
			var k := MeshBuilder.Kit.new()
			k.b("leather", Color(0.35, 0.3, 0.3)).box(Props.at(0, -0.2, 0), Vector3(0.07, 0.2, 0.26))
			k.b("leather", Color(0.3, 0.25, 0.25)).box(Props.at(0, -0.07, 0), Vector3(0.015, 0.1, 0.015))
			p.bag = p.attach("Bip01 L Hand", _built(k))
		"holdall":
			# Эдик's bag of jeans: a soft sports holdall.
			var k := MeshBuilder.Kit.new()
			k.b("cloth", Color(0.25, 0.3, 0.45)).capsule(Props.at(0, -0.25, 0), Vector3(0, 0, -0.18), Vector3(0, 0, 0.18),
				0.13, 0.13, 14)
			k.b("leather", Color(0.3, 0.25, 0.25)).box(Props.at(0, -0.1, 0), Vector3(0.015, 0.14, 0.02))
			p.bag = p.attach("Bip01 L Hand", _built(k))
	return p


## The killer: a man in black, gloves and all, a knitted hat pulled down to
## the brows and a dark scarf wound up over the nose, so only the eyes show
## and nobody can be recognised before the fifth night. A butcher's cleaver
## in the right hand, dull and stained.
static func build_killer() -> Person:
	var p := Person.new().setup("killer", false)
	var k := MeshBuilder.Kit.new()
	k.ao = false
	var knit := k.b("knit")
	knit.cylinder(_oval(Vector3(0, 0.125, -0.02), 1.15), 0.11, 0.09, 0.13, 20, Color.WHITE, Rect2(0, 0, 2, 0.5))
	knit.cylinder(_oval(Vector3(0, 0.12, -0.02), 1.15), 0.115, 0.114, 0.05, 20, Color(1.3, 1.3, 1.3))
	knit.ellipsoid(Props.at(0, 0.255, -0.02), Vector3(0.09, 0.03, 0.1), 16, 6)
	# The scarf: from the bridge of the nose down round the neck.
	k.b("knit", Color(0.6, 0.55, 0.52)).cylinder(_oval(Vector3(0, -0.04, -0.025), 1.3), 0.105, 0.1, 0.135, 20)
	p.attach("Bip01 Head", _built(k))
	var ck := MeshBuilder.Kit.new()
	ck.ao = false
	# Cleaver: wooden grip in the fist, a wide blade pointing forward.
	ck.b("wood").box(Props.at(0.0, -0.06, -0.03), Vector3(0.03, 0.035, 0.14))
	ck.b("chrome", Color(0.85, 0.8, 0.78)).box(Props.at(0.0, -0.13, -0.23), Vector3(0.006, 0.13, 0.22))
	ck.b("blood").box(Props.at(0.0, -0.13, -0.27), Vector3(0.008, 0.08, 0.13), Color(1.2, 1.0, 1.0),
		Rect2(0.3, 0.3, 0.4, 0.4))
	p.attach("Bip01 R Hand", _built(ck))
	return p


## A carton held against the chest in both arms (Kovpak's night visit).
static func carton() -> Node3D:
	var box := MeshBuilder.Kit.new()
	box.b("cardboard").box(Props.at(0, 1.0, -0.33), Vector3(0.5, 0.32, 0.36), Color.WHITE, NO_RECT, Vector2(0.6, 0.6))
	return _built(box)


static func _built(kit: MeshBuilder.Kit) -> Node3D:
	var n := Node3D.new()
	kit.build(n)
	return n


## Flattened (elliptic) upright cylinder: depth is `flat` times the width.
static func _oval(x: Vector3, flat: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3(1, 1, flat)), x)
