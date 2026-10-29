class_name AnimalRig
extends Node3D
## Animais procedurais (ovelha, coelho, cervo, pássaro, jumento, cabra, peixe)
## com corpos em camadas, focinho, olhos com brilho, patas com cascos e
## animação de respiração, piscada e orelhas.

var kind := "sheep"
var palette := {}
var speed := 0.0
var phase := 0.0
var cheer_time := 0.0
var _time := 0.0
var _blink := 2.4
var _blink_scale := 1.0
var built := false
var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var wing_l: Node3D
var wing_r: Node3D
var base_y := 0.0
var _ears: Array[Node3D] = []
var _eyes_nodes: Array[Node3D] = []

func _ready() -> void:
	if not built:
		_build()

func setup(new_kind: String, colors := {}) -> void:
	kind = new_kind
	palette = colors
	if built:
		_build()

func set_motion(new_speed: float) -> void:
	speed = new_speed

func cheer(duration := 1.2) -> void:
	cheer_time = duration

func _build() -> void:
	built = true
	legs.clear()
	_knees.clear()
	_ears.clear()
	_eyes_nodes.clear()
	for child in get_children():
		child.queue_free()
	head = null
	tail = null
	body = null
	wing_l = null
	wing_r = null

	match kind:
		"sheep":
			_build_sheep()
		"rabbit":
			_build_rabbit()
		"deer":
			_build_deer()
		"bird":
			_build_bird()
		"donkey":
			_build_donkey()
		"goat":
			_build_goat()
		"fish":
			_build_fish()
		_:
			_build_sheep()

# ---------------------------------------------------------------- ovelha

func _build_sheep() -> void:
	var wool: Color = palette.get("body", Color("#f1ece0"))
	var face: Color = palette.get("face", Color("#e7dcc9"))
	var hoof := Color("#3b342e")
	body = _node(Vector3(0, 0.72, 0))
	Props.part(body, Props.sphere_mesh(0.44, 16, 9), Props.fur_mat(wool),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.26, 0.88, 1.02), "WoolBody")
	Props.part(body, Props.sphere_mesh(0.32, 12, 7), Props.fur_mat(wool.darkened(0.03)),
		Vector3(0, -0.1, 0.02), Vector3.ZERO, Vector3(1.24, 0.68, 1.0), "WoolBelly")
	# tufos menores em três anéis cobrem o corpo como um velo contínuo
	var rings := [[8, 0.26, 0.42, 0.36], [7, 0.41, 0.3, 0.26], [4, 0.52, 0.16, 0.14]]
	var clump_index := 0
	for ring in rings:
		for i in int(ring[0]):
			var a := TAU * float(i) / float(ring[0]) + float(clump_index) * 0.4
			Props.part(body, Props.sphere_mesh(0.115 + 0.015 * (clump_index % 3), 8, 5),
				Props.fur_mat(wool.lightened(0.03 if clump_index % 2 == 0 else -0.02)),
				Vector3(sin(a) * float(ring[2]), float(ring[1]), cos(a) * float(ring[3])),
				Vector3(0, rad_to_deg(a), 0), Vector3(1.15, 0.82, 1.05), "WoolCurl")
			clump_index += 1
	head = _node(Vector3(0, 0.92, -0.5))
	var coat := face.darkened(0.06)
	Props.part(head, Props.sphere_mesh(0.235, 18, 11), Props.fur_mat(coat),
		Vector3.ZERO, Vector3.ZERO, Vector3(0.95, 1.0, 1.12), "Head")
	Props.part(head, Props.sphere_mesh(0.138, 12, 7), Props.fur_mat(face.lightened(0.05)),
		Vector3(0, -0.078, -0.205), Vector3.ZERO, Vector3(0.98, 0.76, 1.02), "Muzzle")
	Props.part(head, Props.sphere_mesh(0.09, 9, 6), Props.fur_mat(face),
		Vector3(0, -0.145, -0.2), Vector3.ZERO, Vector3(1.0, 0.7, 0.9), "Chin")
	# ponta do focinho em marrom quente, com narinas finas
	Props.part(head, Props.sphere_mesh(0.037, 9, 6), Props.mat(Color("#6b5242"), 0.86),
		Vector3(0, -0.102, -0.334), Vector3.ZERO, Vector3(0.96, 0.6, 0.56), "Nose")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.0085, 6, 4), Props.mat(Color("#3b2a22"), 0.9),
			Vector3(side * 0.016, -0.109, -0.352), Vector3(0, side * 14, side * 16), Vector3(1.45, 0.5, 0.4), "Nostril")
	Props.part(head, Props.box_mesh(Vector3(0.005, 0.03, 0.006)), Props.mat(Color("#7c6250"), 0.9),
		Vector3(0, -0.132, -0.335), Vector3(8, 0, 0), Vector3.ONE, "MuzzleSplit")
	Props.part(head, Props.box_mesh(Vector3(0.046, 0.007, 0.008)), Props.mat(Color("#50382c"), 0.9),
		Vector3(0, -0.158, -0.3), Vector3(0, 0, 0), Vector3.ONE, "Mouth")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.014, 6, 4), Props.fur_mat(face.darkened(0.08)),
			Vector3(side * 0.034, -0.15, -0.303), Vector3.ZERO, Vector3(1.4, 0.3, 0.4), "MuzzleCrease")
	Props.part(head, Props.sphere_mesh(0.13, 9, 6), Props.fur_mat(wool),
		Vector3(0, 0.17, 0.03), Vector3.ZERO, Vector3(1.18, 0.58, 0.95), "WoolForehead")
	Props.part(head, Props.sphere_mesh(0.08, 8, 5), Props.fur_mat(wool.lightened(0.02)),
		Vector3(0, 0.24, 0.06), Vector3.ZERO, Vector3(1.0, 0.7, 1.0), "WoolTuft")
	_eyes(head, 0.165, 0.07, -0.162, 0.046)
	for side in [-1, 1]:
		var ear := _node(Vector3(side * 0.2, 0.02, 0.0), head)
		ear.rotation_degrees = Vector3(0, 0, side * -58)
		Props.part(ear, Props.sphere_mesh(0.125, 9, 6), Props.fur_mat(face.darkened(0.04)),
			Vector3(side * 0.08, 0, 0), Vector3.ZERO, Vector3(1.35, 0.32, 0.68), "Ear")
		Props.part(ear, Props.sphere_mesh(0.07, 7, 4), Props.fur_mat(Color("#c79a8a")),
			Vector3(side * 0.084, -0.004, -0.032), Vector3.ZERO, Vector3(1.25, 0.2, 0.42), "EarInner")
		_ears.append(ear)
	# velo extra ao redor do rosto e tufos nas bochechas
	_fur_tufts(head, Vector3(0, -0.12, 0.03), wool, 6, 0.13, 0.05)
	_fur_tufts(head, Vector3(0, 0.05, 0.1), wool, 4, 0.16, 0.055)
	_legs(0.42, 0.42, 0.07, face.lightened(0.12), hoof, [[-0.23, 0.27], [0.23, 0.27], [-0.23, -0.27], [0.23, -0.27]])
	for leg in legs:
		Props.part(leg, Props.cylinder_mesh(0.095, 0.075, 0.07, 8), Props.fur_mat(wool.lightened(0.02)),
			Vector3(0, -0.03, 0), Vector3.ZERO, Vector3.ONE, "WoolCuff")
	tail = _node(Vector3(0, 0.78, 0.46))
	Props.part(tail, Props.sphere_mesh(0.13, 9, 6), Props.fur_mat(wool), Vector3(0, -0.03, 0.02),
		Vector3.ZERO, Vector3(1, 1.2, 0.9), "Tail")
	Props.part(tail, Props.sphere_mesh(0.07, 7, 4), Props.fur_mat(wool.lightened(0.03)),
		Vector3(0, -0.14, 0.04), Vector3.ZERO, Vector3(0.9, 1.1, 0.8), "TailTuft")

# ---------------------------------------------------------------- coelho

func _build_rabbit() -> void:
	var fur: Color = palette.get("body", Color("#cdb894"))
	var pink: Color = palette.get("ears", Color("#e3a19a"))
	body = _node(Vector3(0, 0.45, 0))
	Props.part(body, Props.sphere_mesh(0.33, 16, 9), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.94, 1.24), "Body")
	Props.part(body, Props.sphere_mesh(0.23, 12, 7), Props.fur_mat(fur.lightened(0.05)),
		Vector3(0, -0.06, -0.12), Vector3.ZERO, Vector3(1.0, 0.9, 1.0), "Chest")
	Props.part(body, Props.sphere_mesh(0.17, 10, 6), Props.fur_mat(Color("#f4ead8")),
		Vector3(0, -0.12, -0.1), Vector3.ZERO, Vector3(0.95, 0.8, 0.9), "Bib")
	for side in [-1, 1]:
		Props.part(body, Props.sphere_mesh(0.2, 10, 6), Props.fur_mat(fur.darkened(0.03)),
			Vector3(side * 0.21, -0.02, 0.18), Vector3.ZERO, Vector3(0.88, 1.05, 1.18), "Haunch")
		Props.part(body, Props.sphere_mesh(0.085, 8, 5), Props.fur_mat(fur.lightened(0.08)),
			Vector3(side * 0.2, -0.08, 0.3), Vector3.ZERO, Vector3(0.75, 0.55, 1.75), "HindFoot")
		Props.part(body, Props.sphere_mesh(0.06, 7, 4), Props.fur_mat(fur),
			Vector3(side * 0.12, -0.06, -0.26), Vector3.ZERO, Vector3(0.75, 0.55, 1.0), "Paw")
	head = _node(Vector3(0, 0.75, -0.3))
	Props.part(head, Props.sphere_mesh(0.225, 18, 11), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.96, 1.08), "Head")
	Props.part(head, Props.sphere_mesh(0.11, 9, 6), Props.fur_mat(Color("#f4ead8")),
		Vector3(0, -0.075, -0.17), Vector3.ZERO, Vector3(1.05, 0.8, 1.0), "Muzzle")
	Props.part(head, Props.sphere_mesh(0.035, 7, 4), Props.mat(pink.darkened(0.1), 0.7),
		Vector3(0, -0.06, -0.27), Vector3.ZERO, Vector3(1.2, 0.9, 0.6), "Nose")
	Props.part(head, Props.box_mesh(Vector3(0.05, 0.01, 0.02)), Props.mat(fur.darkened(0.4)),
		Vector3(0, -0.12, -0.26), Vector3.ZERO, Vector3.ONE, "Mouth")
	_eyes(head, 0.165, 0.055, -0.135, 0.048)
	for side in [-1, 1]:
		for i in 3:
			Props.part(head, Props.box_mesh(Vector3(0.11, 0.006, 0.006)), Props.mat(fur.darkened(0.25)),
				Vector3(side * 0.11, -0.09 + i * 0.015, -0.26), Vector3(0, 0, side * (8 + i * 9)))
		Props.part(head, Props.sphere_mesh(0.006, 5, 3), Props.mat(fur.darkened(0.3)),
			Vector3(side * 0.045, -0.086, -0.274), Vector3.ZERO, Vector3.ONE, "WhiskerDot")
	for side in [-1, 1]:
		var ear := _node(Vector3(side * 0.085, 0.15, 0.02), head)
		ear.rotation_degrees = Vector3(-6, 0, side * -9)
		Props.part(ear, Props.capsule_mesh(0.42, 0.068, 8), Props.fur_mat(fur),
			Vector3(0, 0.2, 0), Vector3(0, 0, side * 4), Vector3(1, 1, 0.6), "Ear")
		Props.part(ear, Props.capsule_mesh(0.33, 0.042, 7), Props.fur_mat(pink),
			Vector3(0, 0.2, -0.027), Vector3(0, 0, side * 4), Vector3(1, 1, 0.35), "EarInner")
		Props.part(ear, Props.sphere_mesh(0.05, 7, 4), Props.fur_mat(fur.lightened(0.06)),
			Vector3(0, 0.02, 0.01), Vector3.ZERO, Vector3(1.2, 0.7, 0.8), "EarBase")
		_ears.append(ear)
	_legs(0.3, 0.3, 0.062, fur, fur.darkened(0.2), [[-0.19, 0.22], [0.19, 0.22]])
	_legs(0.28, 0.28, 0.048, fur, fur.darkened(0.2), [[-0.11, -0.22], [0.11, -0.22]])
	for side in [-1, 1]:
		for i in 3:
			Props.part(body, Props.sphere_mesh(0.017, 6, 4), Props.fur_mat(fur.lightened(0.08)),
				Vector3(side * 0.105 + (i - 1) * 0.018, -0.075, -0.31), Vector3.ZERO, Vector3(1, 0.8, 1.1), "PawToe")
	_fur_tufts(body, Vector3(0, 0.02, 0.14), fur, 5, 0.17, 0.05)
	tail = _node(Vector3(0, 0.5, 0.42))
	Props.part(tail, Props.sphere_mesh(0.115, 9, 6), Props.fur_mat(Color("#fffaf0")),
		Vector3(0, 0, 0), Vector3.ZERO, Vector3(1, 1.1, 1), "Tail")
	Props.part(tail, Props.sphere_mesh(0.075, 8, 5), Props.fur_mat(Color("#fffdf6")),
		Vector3(0, 0.07, 0.03), Vector3.ZERO, Vector3(0.9, 0.9, 0.9), "TailPuff")
	Props.part(tail, Props.sphere_mesh(0.06, 7, 4), Props.fur_mat(Color("#f7efe0")),
		Vector3(0, -0.07, 0.03), Vector3.ZERO, Vector3(0.85, 0.85, 0.85), "TailPuff")

# ---------------------------------------------------------------- cervo

func _build_deer() -> void:
	var fur: Color = palette.get("body", Color("#b98a62"))
	var cream := Color("#f4e9d3")
	var hoof := Color("#3e332a")
	var antler_color := Color("#d8c19a")
	body = _node(Vector3(0, 0.92, 0))
	Props.part(body, Props.sphere_mesh(0.4, 16, 9), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.24, 0.88, 1.0), "Body")
	Props.part(body, Props.sphere_mesh(0.3, 12, 7), Props.fur_mat(fur.lightened(0.04)),
		Vector3(0, 0.02, -0.26), Vector3.ZERO, Vector3(1.0, 1.0, 0.9), "Chest")
	Props.part(body, Props.sphere_mesh(0.3, 12, 7), Props.fur_mat(fur.darkened(0.03)),
		Vector3(0, 0.01, 0.24), Vector3.ZERO, Vector3(1.0, 1.02, 0.95), "Haunch")
	Props.part(body, Props.sphere_mesh(0.24, 12, 7), Props.fur_mat(Color("#e9d7b8")),
		Vector3(0, -0.26, 0.0), Vector3.ZERO, Vector3(1.2, 0.42, 0.95), "Belly")
	for i in 6:
		Props.part(body, Props.sphere_mesh(0.035, 7, 4), Props.mat(cream, 0.95),
			Vector3(-0.18 + (i % 3) * 0.18, 0.24 + (i % 2) * 0.08, -0.15 + (i % 3) * 0.22),
			Vector3.ZERO, Vector3(1, 1, 1), "Spot")
	Props.part(self, Props.cylinder_mesh(0.13, 0.17, 0.46, 10), Props.fur_mat(fur),
		Vector3(0, 1.14, -0.3), Vector3(22, 0, 0), Vector3.ONE, "Neck")
	head = _node(Vector3(0, 1.37, -0.46))
	Props.part(head, Props.sphere_mesh(0.235, 18, 11), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(0.92, 0.96, 1.18), "Head")
	Props.part(head, Props.sphere_mesh(0.145, 9, 6), Props.fur_mat(fur.lightened(0.05)),
		Vector3(0, -0.07, -0.21), Vector3.ZERO, Vector3(0.9, 0.8, 1.05), "Muzzle")
	Props.part(head, Props.sphere_mesh(0.045, 10, 6), Props.mat(Color("#3a2a20"), 0.72),
		Vector3(0, -0.092, -0.342), Vector3.ZERO, Vector3(1.12, 0.72, 0.56), "Nose")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.0095, 7, 4), Props.mat(Color("#1c130e"), 0.9),
			Vector3(side * 0.019, -0.103, -0.363), Vector3(0, side * 14, side * 16), Vector3(1.4, 0.5, 0.4), "Nostril")
	Props.part(head, Props.box_mesh(Vector3(0.005, 0.032, 0.006)), Props.mat(Color("#4a3628"), 0.9),
		Vector3(0, -0.122, -0.351), Vector3(6, 0, 0), Vector3.ONE, "Philtrum")
	Props.part(head, Props.box_mesh(Vector3(0.056, 0.007, 0.008)), Props.mat(Color("#3a2a20"), 0.9),
		Vector3(0, -0.151, -0.322), Vector3.ZERO, Vector3.ONE, "Mouth")
	_eyes(head, 0.18, 0.055, -0.15, 0.048)
	Props.part(head, Props.sphere_mesh(0.1, 8, 5), Props.fur_mat(cream),
		Vector3(0, -0.15, -0.1), Vector3.ZERO, Vector3(1.1, 0.75, 0.85), "Throat")
	Props.part(body, Props.sphere_mesh(0.13, 9, 6), Props.fur_mat(cream),
		Vector3(0, 0.03, 0.4), Vector3.ZERO, Vector3(1.2, 0.9, 0.45), "RumpPatch")
	_fur_tufts(self, Vector3(0, 1.2, -0.32), fur, 6, 0.12, 0.05)
	for side in [-1, 1]:
		var ear := _node(Vector3(side * 0.19, 0.12, 0.02), head)
		ear.rotation_degrees = Vector3(-8, 0, side * -48)
		Props.part(ear, Props.sphere_mesh(0.13, 9, 6), Props.fur_mat(fur),
			Vector3(side * 0.1, 0.02, 0), Vector3(0, 0, side * 8), Vector3(1.55, 0.34, 0.72), "Ear")
		Props.part(ear, Props.sphere_mesh(0.08, 7, 4), Props.fur_mat(Color("#e2c7a8")),
			Vector3(side * 0.1, 0.02, -0.025), Vector3(0, 0, side * 8), Vector3(1.3, 0.2, 0.5), "EarInner")
		_ears.append(ear)
		# haste principal + duas pontas fazem uma galhada de cervo simples
		var beam := _node(Vector3(side * 0.08, 0.2, 0.02), head)
		beam.rotation_degrees = Vector3(-16, 0, side * -22)
		Props.part(beam, Props.torus_mesh(0.028, 0.046, 12, 6), Props.mat(antler_color.darkened(0.12), 0.8),
			Vector3(0, 0.02, 0), Vector3.ZERO, Vector3.ONE, "AntlerBurr")
		Props.part(beam, Props.cylinder_mesh(0.028, 0.042, 0.36, 7), Props.mat(antler_color, 0.8),
			Vector3(0, 0.16, 0), Vector3.ZERO, Vector3.ONE, "Antler")
		var tip_a := _node(Vector3(0, 0.32, 0), beam)
		tip_a.rotation_degrees = Vector3(-38, 0, side * -28)
		Props.part(tip_a, Props.cylinder_mesh(0.014, 0.026, 0.2, 6), Props.mat(antler_color.lightened(0.04), 0.8),
			Vector3(0, 0.09, 0), Vector3.ZERO, Vector3.ONE, "Antler")
		var tip_b := _node(Vector3(0, 0.2, 0), beam)
		tip_b.rotation_degrees = Vector3(28, 0, side * -34)
		Props.part(tip_b, Props.cylinder_mesh(0.012, 0.024, 0.16, 6), Props.mat(antler_color, 0.8),
			Vector3(0, 0.07, 0), Vector3.ZERO, Vector3.ONE, "Antler")
	_legs(0.8, 0.8, 0.06, fur, hoof, [[-0.2, 0.32], [0.2, 0.32], [-0.2, -0.34], [0.2, -0.34]])
	tail = _node(Vector3(0, 0.98, 0.48))
	Props.part(tail, Props.sphere_mesh(0.1, 8, 5), Props.fur_mat(cream),
		Vector3(0, -0.02, 0.02), Vector3.ZERO, Vector3(0.8, 1.1, 0.8), "Tail")

# ---------------------------------------------------------------- passarinho

func _build_bird() -> void:
	var feather: Color = palette.get("body", Color("#5b8fd6"))
	var belly: Color = palette.get("belly", feather.lightened(0.25))
	var wing_color := feather.darkened(0.1)
	body = _node(Vector3(0, 0.34, 0))
	Props.part(body, Props.sphere_mesh(0.2, 18, 11), Props.fur_mat(feather),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.92, 1.3), "Body")
	Props.part(body, Props.sphere_mesh(0.14, 10, 6), Props.fur_mat(belly),
		Vector3(0, -0.05, -0.1), Vector3.ZERO, Vector3(0.9, 0.9, 1.0), "Breast")
	head = _node(Vector3(0, 0.17, -0.23), body)
	Props.part(head, Props.sphere_mesh(0.145, 12, 7), Props.fur_mat(feather.lightened(0.04)),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 1.05), "Head")
	Props.part(head, Props.cylinder_mesh(0.0, 0.05, 0.14, 6), Props.mat(Color("#e8a33c"), 0.7),
		Vector3(0, -0.012, -0.17), Vector3(90, 0, 0), Vector3(1, 0.7, 1), "Beak")
	Props.part(head, Props.cylinder_mesh(0.0, 0.03, 0.09, 5), Props.mat(Color("#c98228"), 0.7),
		Vector3(0, -0.045, -0.15), Vector3(90, 0, 0), Vector3(1, 0.6, 0.8), "BeakLower")
	_eyes(head, 0.1, 0.03, -0.11, 0.033)
	wing_l = _node(Vector3(-0.18, 0.01, 0.0), body)
	wing_r = _node(Vector3(0.18, 0.01, 0.0), body)
	for side in [-1, 1]:
		var wing := wing_l if side < 0 else wing_r
		# asas dobradas junto ao corpo, com penas sobrepostas na traseira
		Props.part(wing, Props.sphere_mesh(0.22, 10, 6), Props.fur_mat(wing_color),
			Vector3(side * 0.02, -0.01, 0.06), Vector3(0, 0, side * 10),
			Vector3(0.2, 0.62, 1.15), "Wing")
		for i in 3:
			Props.part(wing, Props.sphere_mesh(0.16 - i * 0.02, 8, 5),
				Props.fur_mat(wing_color.lightened(0.04 * (i + 1))),
				Vector3(side * (0.03 + i * 0.012), -0.02 - i * 0.012, 0.14 + i * 0.06),
				Vector3(0, side * 6, side * (6 + i * 3)),
				Vector3(0.16, 0.3, 0.95), "Feather")
	tail = _node(Vector3(0, 0, 0.27), body)
	for i in 5:
		var spread := float(i - 2)
		Props.part(tail, Props.sphere_mesh(0.17, 8, 5), Props.fur_mat(wing_color.lightened(0.05 + absf(spread) * 0.02)),
			Vector3(spread * 0.042, 0.012 + absf(spread) * 0.008, 0.12 + absf(spread) * 0.012),
			Vector3(-4, spread * 9, 0), Vector3(0.4, 0.085, 1.6 - absf(spread) * 0.12), "TailFeather")
	for i in 3:
		Props.part(body, Props.cylinder_mesh(0.012, 0.016, 0.16, 5), Props.mat(Color("#9c6b33"), 0.8),
			Vector3(-0.042 + i * 0.042, -0.18, 0.02), Vector3(8, 0, -10 + i * 10), Vector3.ONE, "Leg")
		Props.part(body, Props.cylinder_mesh(0.0125, 0.0125, 0.012, 6), Props.mat(Color("#b07f45"), 0.75),
			Vector3(-0.042 + i * 0.042, -0.19, 0.02), Vector3(8, 0, -10 + i * 10), Vector3.ONE, "LegScale")
	for side in [-1, 1]:
		Props.part(body, Props.box_mesh(Vector3(0.07, 0.012, 0.12)), Props.mat(Color("#9c6b33"), 0.8),
			Vector3(side * 0.075, -0.26, -0.02), Vector3.ZERO, Vector3.ONE, "Foot")
		for i in 3:
			Props.part(body, Props.cylinder_mesh(0.0, 0.008, 0.05, 5), Props.mat(Color("#6b4a2c"), 0.7),
				Vector3(side * 0.075 + (i - 1) * 0.022, -0.262, -0.09), Vector3(84, 0, (i - 1) * 16), Vector3.ONE, "Claw")

# ---------------------------------------------------------------- jumento

func _build_donkey() -> void:
	var fur: Color = palette.get("body", Color("#9d9a91"))
	var mane := fur.darkened(0.3)
	var hoof := Color("#3a332c")
	body = _node(Vector3(0, 0.95, 0))
	Props.part(body, Props.sphere_mesh(0.45, 16, 9), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.32, 0.9, 1.0), "Body")
	Props.part(body, Props.sphere_mesh(0.32, 12, 7), Props.fur_mat(fur.lightened(0.03)),
		Vector3(0, 0.02, -0.28), Vector3.ZERO, Vector3(1.0, 1.0, 0.9), "Chest")
	Props.part(body, Props.sphere_mesh(0.31, 12, 7), Props.fur_mat(fur.darkened(0.02)),
		Vector3(0, 0.02, 0.26), Vector3.ZERO, Vector3(1.0, 1.0, 0.9), "Haunch")
	Props.part(body, Props.sphere_mesh(0.25, 12, 7), Props.fur_mat(fur.lightened(0.08)),
		Vector3(0, -0.27, -0.05), Vector3.ZERO, Vector3(1.1, 0.4, 1.0), "Belly")
	Props.part(self, Props.cylinder_mesh(0.13, 0.17, 0.55, 10), Props.fur_mat(fur),
		Vector3(0, 1.28, -0.38), Vector3(18, 0, 0), Vector3.ONE, "Neck")
	head = _node(Vector3(0, 1.5, -0.56))
	Props.part(head, Props.sphere_mesh(0.22, 18, 11), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(0.88, 1.0, 1.2), "Head")
	Props.part(head, Props.sphere_mesh(0.15, 18, 11), Props.fur_mat(fur.lightened(0.03)),
		Vector3(0, -0.1, -0.235), Vector3(-8, 0, 0), Vector3(0.74, 0.7, 1.2), "Muzzle")
	Props.part(head, Props.sphere_mesh(0.06, 12, 8), Props.fur_mat(fur.lightened(0.06)),
		Vector3(0, -0.187, -0.348), Vector3.ZERO, Vector3(1.25, 0.72, 0.95), "Chin")
	Props.part(head, Props.sphere_mesh(0.05, 12, 8), Props.mat(fur.darkened(0.4), 0.8),
		Vector3(0, -0.148, -0.402), Vector3.ZERO, Vector3(1.2, 0.72, 0.5), "Nose")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.011, 7, 4), Props.mat(fur.darkened(0.55), 0.8),
			Vector3(side * 0.026, -0.156, -0.426), Vector3(0, side * 14, side * 16), Vector3(1.3, 0.6, 0.35), "Nostril")
	Props.part(head, Props.box_mesh(Vector3(0.005, 0.024, 0.006)), Props.mat(fur.darkened(0.35), 0.9),
		Vector3(0, -0.178, -0.421), Vector3(10, 0, 0), Vector3.ONE, "Philtrum")
	Props.part(head, Props.box_mesh(Vector3(0.05, 0.007, 0.008)), Props.mat(fur.darkened(0.45), 0.9),
		Vector3(0, -0.199, -0.404), Vector3(-6, 0, 0), Vector3.ONE, "Mouth")
	_eyes(head, 0.155, 0.07, -0.15, 0.042)
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.105, 12, 8), Props.fur_mat(fur),
			Vector3(side * 0.088, -0.085, -0.15), Vector3.ZERO, Vector3(0.9, 0.78, 1.05), "Cheek")
	Props.part(head, Props.sphere_mesh(0.1, 9, 6), Props.fur_mat(fur.lightened(0.05)),
		Vector3(0, -0.12, -0.06), Vector3.ZERO, Vector3(1.0, 0.9, 0.7), "Jaw")
	for side in [-1, 1]:
		var ear := _node(Vector3(side * 0.105, 0.18, 0.03), head)
		ear.rotation_degrees = Vector3(-12, 0, side * -16)
		Props.part(ear, Props.capsule_mesh(0.46, 0.07, 8), Props.fur_mat(fur),
			Vector3(0, 0.22, 0), Vector3.ZERO, Vector3(1, 1, 0.55), "Ear")
		Props.part(ear, Props.capsule_mesh(0.36, 0.045, 7), Props.fur_mat(fur.lightened(0.07)),
			Vector3(0, 0.22, -0.028), Vector3.ZERO, Vector3(1, 1, 0.3), "EarInner")
		Props.part(ear, Props.sphere_mesh(0.055, 7, 4), Props.fur_mat(fur.darkened(0.06)),
			Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(1.1, 0.8, 0.7), "EarBase")
		_ears.append(ear)
	for i in 6:
		Props.part(head, Props.box_mesh(Vector3(0.05, 0.09, 0.06)), Props.mat(mane),
			Vector3(0, 0.16 - i * 0.055, 0.04 + i * 0.035), Vector3(0, 0, 6), Vector3.ONE, "Forelock")
		Props.part(self, Props.box_mesh(Vector3(0.05, 0.1, 0.07)), Props.mat(mane),
			Vector3(0, 1.47 - i * 0.07, -0.18 + i * 0.06), Vector3(18, 0, 0), Vector3.ONE, "Mane")
		Props.part(head, Props.capsule_mesh(0.08, 0.012, 6), Props.mat(mane.lightened(0.04)),
			Vector3(0, 0.2 - i * 0.06, 0.02 + i * 0.04), Vector3(-24, 0, 0), Vector3.ONE, "ManeHair")
	_fur_tufts(body, Vector3(0, -0.12, -0.24), fur.lightened(0.06), 6, 0.12, 0.045)
	_legs(0.82, 0.82, 0.06, fur.darkened(0.06), hoof,
		[[-0.24, 0.32], [0.24, 0.32], [-0.24, -0.34], [0.24, -0.34]])
	for leg in legs:
		Props.part(leg, Props.cylinder_mesh(0.075, 0.055, 0.09, 8), Props.fur_mat(fur.darkened(0.14)),
			Vector3(0, -0.44, 0.01), Vector3.ZERO, Vector3.ONE, "Feathers")
	tail = _node(Vector3(0, 0.9, 0.55))
	Props.part(tail, Props.cylinder_mesh(0.025, 0.04, 0.34, 6), Props.mat(mane),
		Vector3(0, -0.15, 0.03), Vector3(20, 0, 0), Vector3.ONE, "TailHair")
	for i in 3:
		Props.part(tail, Props.capsule_mesh(0.24, 0.012, 5), Props.mat(mane.lightened(0.03)),
			Vector3((i - 1) * 0.025, -0.28, 0.09 + absf(i - 1) * 0.01), Vector3(20, 0, (i - 1) * 8), Vector3.ONE, "TailStrand")
	Props.part(tail, Props.sphere_mesh(0.07, 7, 4), Props.mat(mane.darkened(0.05)),
		Vector3(0, -0.34, 0.1), Vector3.ZERO, Vector3(0.8, 1.4, 0.8), "TailTuft")

# ---------------------------------------------------------------- cabra

func _build_goat() -> void:
	var fur: Color = palette.get("body", Color("#efe6d2"))
	var horn := Color("#bda684")
	var hoof := Color("#4a4038")
	body = _node(Vector3(0, 0.76, 0))
	Props.part(body, Props.sphere_mesh(0.37, 16, 9), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.3, 0.95, 0.95), "Body")
	Props.part(body, Props.sphere_mesh(0.26, 12, 7), Props.fur_mat(fur.lightened(0.05)),
		Vector3(0, 0.02, -0.24), Vector3.ZERO, Vector3(1.0, 1.0, 0.9), "Chest")
	Props.part(body, Props.sphere_mesh(0.24, 12, 7), Props.fur_mat(fur.darkened(0.03)),
		Vector3(0, -0.25, 0.0), Vector3.ZERO, Vector3(1.05, 0.45, 0.95), "Belly")
	Props.part(self, Props.cylinder_mesh(0.1, 0.13, 0.34, 9), Props.fur_mat(fur),
		Vector3(0, 1.0, -0.3), Vector3(22, 0, 0), Vector3.ONE, "Neck")
	head = _node(Vector3(0, 1.16, -0.46))
	Props.part(head, Props.sphere_mesh(0.2, 18, 11), Props.fur_mat(fur),
		Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 1.0, 1.15), "Head")
	Props.part(head, Props.sphere_mesh(0.12, 9, 6), Props.fur_mat(fur.lightened(0.04)),
		Vector3(0, -0.07, -0.19), Vector3.ZERO, Vector3(0.9, 0.8, 1.1), "Muzzle")
	Props.part(head, Props.sphere_mesh(0.042, 9, 6), Props.mat(fur.darkened(0.28), 0.8),
		Vector3(0, -0.09, -0.307), Vector3.ZERO, Vector3(1.12, 0.72, 0.56), "Nose")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.009), Props.mat(fur.darkened(0.52), 0.9),
			Vector3(side * 0.018, -0.101, -0.332), Vector3(0, side * 14, side * 16), Vector3(1.4, 0.5, 0.4), "Nostril")
	Props.part(head, Props.box_mesh(Vector3(0.005, 0.028, 0.006)), Props.mat(fur.darkened(0.42), 0.9),
		Vector3(0, -0.118, -0.316), Vector3(6, 0, 0), Vector3.ONE, "Philtrum")
	Props.part(head, Props.box_mesh(Vector3(0.05, 0.007, 0.008)), Props.mat(fur.darkened(0.45), 0.9),
		Vector3(0, -0.146, -0.277), Vector3.ZERO, Vector3.ONE, "Mouth")
	Props.part(head, Props.sphere_mesh(0.08, 8, 5), Props.fur_mat(fur.darkened(0.08)),
		Vector3(0, -0.23, -0.14), Vector3.ZERO, Vector3(0.7, 1.5, 0.6), "Beard")
	_eyes(head, 0.155, 0.06, -0.14, 0.043)
	for side in [-1, 1]:
		var horn_node := _node(Vector3(side * 0.08, 0.15, 0.02), head)
		Props.part(horn_node, Props.torus_mesh(0.038, 0.06, 12, 6), Props.mat(horn.darkened(0.1), 0.8),
			Vector3(0, 0.01, -0.02), Vector3.ZERO, Vector3.ONE, "HornRidge")
		Props.part(horn_node, Props.cylinder_mesh(0.032, 0.052, 0.28, 7), Props.mat(horn, 0.8),
			Vector3(0, 0.12, -0.02), Vector3(-30, 0, side * -12), Vector3.ONE, "Horn")
		var mid := _node(Vector3(0, 0.24, -0.07), horn_node)
		mid.rotation_degrees = Vector3(-62, 0, side * -16)
		Props.part(mid, Props.cylinder_mesh(0.018, 0.032, 0.2, 6), Props.mat(horn.darkened(0.03), 0.8),
			Vector3(0, 0.09, 0), Vector3.ZERO, Vector3.ONE, "Horn")
		var tip := _node(Vector3(0, 0.17, 0), mid)
		tip.rotation_degrees = Vector3(-52, 0, side * -14)
		Props.part(tip, Props.cylinder_mesh(0.007, 0.018, 0.13, 5), Props.mat(horn.lightened(0.05), 0.8),
			Vector3(0, 0.06, 0), Vector3.ZERO, Vector3.ONE, "HornTip")
		var ear := _node(Vector3(side * 0.17, 0.02, 0.02), head)
		ear.rotation_degrees = Vector3(0, 0, side * -58)
		Props.part(ear, Props.sphere_mesh(0.115, 9, 6), Props.fur_mat(fur),
			Vector3(side * 0.08, 0, 0), Vector3.ZERO, Vector3(1.55, 0.32, 0.7), "Ear")
		Props.part(ear, Props.sphere_mesh(0.065, 7, 4), Props.fur_mat(fur.darkened(0.14)),
			Vector3(side * 0.085, -0.004, -0.028), Vector3.ZERO, Vector3(1.35, 0.2, 0.45), "EarInner")
		_ears.append(ear)
	# barba em mechas e tufos no peito
	for i in 5:
		Props.part(head, Props.capsule_mesh(0.15 - absf(i - 2) * 0.02, 0.018, 6), Props.fur_mat(fur.darkened(0.05 + i * 0.01)),
			Vector3((i - 2) * 0.028, -0.3, -0.13 + absf(i - 2) * 0.01), Vector3(4, 0, (i - 2) * 8),
			Vector3(1, 1, 0.8), "BeardStrand")
	_fur_tufts(body, Vector3(0, -0.14, -0.2), fur.lightened(0.04), 5, 0.1, 0.04)
	_legs(0.5, 0.5, 0.052, fur.darkened(0.05), hoof, [[-0.2, 0.28], [0.2, 0.28], [-0.2, -0.28], [0.2, -0.28]])
	tail = _node(Vector3(0, 0.82, 0.42))
	Props.part(tail, Props.sphere_mesh(0.075, 8, 5), Props.fur_mat(fur),
		Vector3(0, 0.07, 0.03), Vector3.ZERO, Vector3(0.6, 1.5, 0.6), "Tail")
	Props.part(tail, Props.sphere_mesh(0.045, 6, 4), Props.fur_mat(fur.lightened(0.05)),
		Vector3(0, 0.16, 0.04), Vector3.ZERO, Vector3(0.5, 1.2, 0.5), "TailTip")

# ---------------------------------------------------------------- peixe

func _build_fish() -> void:
	var scale_color: Color = palette.get("body", Color("#e8a35c"))
	var fin := scale_color.lightened(0.12)
	var belly := scale_color.lightened(0.3)
	body = _node(Vector3.ZERO)
	head = body
	Props.part(body, Props.sphere_mesh(0.27, 14, 8), Props.fur_mat(scale_color),
		Vector3.ZERO, Vector3.ZERO, Vector3(0.62, 0.98, 1.66), "Body")
	Props.part(body, Props.sphere_mesh(0.2, 10, 6), Props.fur_mat(belly),
		Vector3(0, -0.06, 0.02), Vector3.ZERO, Vector3(0.55, 0.78, 1.5), "Belly")
	Props.part(body, Props.sphere_mesh(0.11, 8, 5), Props.fur_mat(scale_color.darkened(0.07)),
		Vector3(0, 0.03, -0.3), Vector3.ZERO, Vector3(0.62, 0.8, 0.55), "Gill")
	Props.part(body, Props.sphere_mesh(0.04, 6, 4), Props.mat(scale_color.darkened(0.35), 0.7),
		Vector3(0, -0.04, -0.44), Vector3.ZERO, Vector3(1.1, 0.8, 0.5), "Mouth")
	Props.part(body, Props.sphere_mesh(0.05, 7, 4), Props.fur_mat(scale_color.lightened(0.1)),
		Vector3(0, -0.055, -0.43), Vector3.ZERO, Vector3(1.1, 0.5, 0.6), "LipLower")
	# escamas em fileiras alternadas, linha lateral e opérculo
	for side in [-1, 1]:
		for row in 3:
			var y := -0.09 + row * 0.1
			for i in 5:
				var z := -0.18 + i * 0.12
				var x := 0.165 - absf(y) * 0.22 - pow((z - 0.03) / 0.5, 2.0) * 0.08
				Props.part(body, Props.sphere_mesh(0.048, 7, 4),
					Props.fur_mat(scale_color.lightened(0.07 if (row + i) % 2 == 0 else -0.02)),
					Vector3(side * x, y + (i % 2) * 0.012, z), Vector3(0, side * 18, row * 6),
					Vector3(0.35, 1.0, 1.0), "Scale")
		Props.part(body, Props.box_mesh(Vector3(0.006, 0.012, 0.36)), Props.mat(scale_color.darkened(0.16), 0.8),
			Vector3(side * 0.168, -0.005, 0.04), Vector3.ZERO, Vector3.ONE, "LateralLine")
		Props.part(body, Props.box_mesh(Vector3(0.008, 0.14, 0.012)), Props.mat(scale_color.darkened(0.24), 0.8),
			Vector3(side * 0.15, 0.02, -0.27), Vector3(0, 0, -14), Vector3.ONE, "GillSlit")
	_eyes(body, 0.115, 0.075, -0.36, 0.042)
	Props.part(body, Props.sphere_mesh(0.13, 8, 5), Props.fur_mat(fin),
		Vector3(0, 0.24, 0.02), Vector3.ZERO, Vector3(0.16, 0.9, 1.25), "DorsalFin")
	for i in 4:
		Props.part(body, Props.box_mesh(Vector3(0.006, 0.09, 0.012)), Props.mat(fin.darkened(0.1), 0.8),
			Vector3(0, 0.28, -0.1 + i * 0.06), Vector3(0, 0, -8 + i * 5), Vector3.ONE, "FinRay")
	for side in [-1, 1]:
		Props.part(body, Props.sphere_mesh(0.1, 7, 4), Props.fur_mat(fin),
			Vector3(side * 0.17, -0.05, -0.06), Vector3(0, 0, side * 34), Vector3(0.18, 0.9, 0.7), "PectoralFin")
		for i in 3:
			Props.part(body, Props.box_mesh(Vector3(0.006, 0.055, 0.012)), Props.mat(fin.darkened(0.12), 0.8),
				Vector3(side * 0.192, -0.05 + (i - 1) * 0.026, -0.06), Vector3(0, 0, side * 34), Vector3.ONE, "PectoralRay")
	tail = _node(Vector3(0, 0, 0.4), body)
	Props.part(tail, Props.sphere_mesh(0.16, 8, 5), Props.fur_mat(fin),
		Vector3(0, 0.06, 0.08), Vector3(0, 0, 18), Vector3(0.14, 1.0, 0.95), "TailFin")
	Props.part(tail, Props.sphere_mesh(0.16, 8, 5), Props.fur_mat(fin),
		Vector3(0, -0.06, 0.08), Vector3(0, 0, -18), Vector3(0.14, 1.0, 0.95), "TailFin")
	for i in 3:
		Props.part(tail, Props.box_mesh(Vector3(0.006, 0.1, 0.012)), Props.mat(fin.darkened(0.14), 0.8),
			Vector3(0, 0.065 + (i - 1) * 0.03, 0.1), Vector3(0, 0, 18 - (i - 1) * 6), Vector3.ONE, "TailRay")
		Props.part(tail, Props.box_mesh(Vector3(0.006, 0.1, 0.012)), Props.mat(fin.darkened(0.14), 0.8),
			Vector3(0, -0.065 + (i - 1) * 0.03, 0.1), Vector3(0, 0, -18 + (i - 1) * 6), Vector3.ONE, "TailRay")

# ---------------------------------------------------------------- helpers

func _node(position: Vector3, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	node.position = position
	if parent:
		parent.add_child(node)
	else:
		add_child(node)
	return node

func _legs(top_y: float, height: float, radius: float, color: Color, hoof: Color, positions: Array) -> void:
	for index in positions.size():
		var pair: Array = positions[index]
		var pivot := _node(Vector3(pair[0], top_y, pair[1]))
		# coxa, joelho, canela e boleto: pernas em dois segmentos
		Props.part(pivot, Props.capsule_mesh(height * 0.5, radius, 8), Props.fur_mat(color),
			Vector3(0, -height * 0.24, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.95), "UpperLeg")
		Props.part(pivot, Props.sphere_mesh(radius * 0.92, 7, 5), Props.fur_mat(color.darkened(0.02)),
			Vector3(0, -height * 0.44, 0.006), Vector3.ZERO, Vector3(1.0, 1.0, 0.95), "Knee")
		var knee := _node(Vector3(0, -height * 0.46, 0), pivot)
		Props.part(knee, Props.cylinder_mesh(radius * 0.78, radius * 0.62, height * 0.4, 8),
			Props.fur_mat(color), Vector3(0, -height * 0.18, 0), Vector3.ZERO, Vector3.ONE, "Cannon")
		Props.part(knee, Props.sphere_mesh(radius * 0.8, 7, 5), Props.fur_mat(color.darkened(0.04)),
			Vector3(0, -height * 0.36, 0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0), "Fetlock")
		# casco fendido em duas unhas, com banda córnea
		for side in [-1, 1]:
			Props.part(knee, Props.sphere_mesh(radius * 0.62, 7, 5), Props.mat(hoof, 0.72),
				Vector3(side * radius * 0.34, -height * 0.5, -0.012), Vector3.ZERO,
				Vector3(0.82, 0.85, 1.5), "Hoof")
			Props.part(knee, Props.box_mesh(Vector3(radius * 0.5, 0.014, radius * 0.72)), Props.mat(hoof.lightened(0.16), 0.7),
				Vector3(side * radius * 0.34, -height * 0.53, -0.02), Vector3(6, 0, side * 4), Vector3.ONE, "HoofWall")
		Props.part(knee, Props.sphere_mesh(radius * 0.34, 6, 4), Props.mat(hoof.darkened(0.15), 0.8),
			Vector3(0, -height * 0.47, 0.05), Vector3.ZERO, Vector3(1.1, 0.55, 0.9), "Dewclaw")
		legs.append(pivot)
		_knees.append(knee)

func _eyes(parent: Node3D, x: float, y: float, z: float, radius: float) -> void:
	var iris_color: Color = palette.get("eye", Color("#4d311c"))
	var coat: Color = palette.get("body", Color("#c9b79c"))
	for side in [-1, 1]:
		var eye := _node(Vector3(side * x, y, z), parent)
		# órbita escura em volta do olho dá contorno e profundidade
		Props.part(eye, Props.sphere_mesh(radius * 1.16, 10, 6), Props.fur_mat(coat.darkened(0.3)),
			Vector3(0, 0, radius * 0.16), Vector3.ZERO, Vector3(1.0, 1.0, 0.5), "EyeSocket")
		Props.part(eye, Props.sphere_mesh(radius, 12, 7), Props.unshaded(Color("#f1e8d6")),
			Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.94, 0.55), "Eye")
		# íris e pupila ficam à frente da esclera, senão somem dentro do olho
		Props.part(eye, Props.sphere_mesh(radius * 0.88, 12, 7), Props.unshaded(iris_color.darkened(0.3)),
			Vector3(0, 0, -radius * 0.34), Vector3.ZERO, Vector3(1.0, 1.0, 0.3), "IrisRim")
		Props.part(eye, Props.sphere_mesh(radius * 0.8, 12, 7), Props.unshaded(iris_color),
			Vector3(0, 0, -radius * 0.38), Vector3.ZERO, Vector3(1.0, 1.0, 0.3), "Iris")
		Props.part(eye, Props.sphere_mesh(radius * 0.42, 9, 6), Props.unshaded(Color("#0f0b08")),
			Vector3(0, 0, -radius * 0.55), Vector3.ZERO, Vector3(1.0, 1.0, 0.28), "Pupil")
		Props.part(eye, Props.sphere_mesh(radius * 0.13, 6, 4), Props.unshaded(Color("#ffffff")),
			Vector3(radius * 0.3, radius * 0.28, -radius * 0.62), Vector3.ZERO, Vector3.ONE, "Glint")
		# pálpebra superior cobre o topo; a inferior fecha o contorno
		Props.part(parent, Props.sphere_mesh(radius * 1.12, 9, 5), Props.fur_mat(coat.darkened(0.14)),
			Vector3(side * x, y + radius * 0.42, z + radius * 0.05), Vector3(-12, 0, side * -6),
			Vector3(1.0, 0.34, 0.55), "UpperLid")
		Props.part(parent, Props.sphere_mesh(radius * 0.94, 8, 4), Props.fur_mat(coat.darkened(0.08)),
			Vector3(side * x, y - radius * 0.62, z + radius * 0.05), Vector3.ZERO,
			Vector3(0.85, 0.2, 0.32), "LowerLid")
		_eyes_nodes.append(eye)

func _fur_tufts(parent: Node3D, center: Vector3, coat: Color, count: int, spread: float,
		size := 0.045, rows := 1) -> void:
	for i in count:
		var t := float(i) / maxf(1.0, float(count - 1))
		var angle := TAU * t * rows
		var offset := Vector3(cos(angle) * spread, (fmod(float(i) * 0.37, 1.0) - 0.5) * spread * 0.6,
			sin(angle) * spread * 0.55)
		Props.part(parent, Props.sphere_mesh(size * (0.82 + 0.35 * fmod(float(i) * 0.53, 1.0)), 6, 4),
			Props.fur_mat(coat.lightened(0.05 if i % 2 == 0 else -0.04)),
			center + offset, Vector3(0, rad_to_deg(angle), 0), Vector3(1.25, 0.72, 1.1), "FurTuft")

func _process(delta: float) -> void:
	_time += delta
	if cheer_time > 0.0:
		cheer_time -= delta
	var amp := clampf(speed / 2.2, 0.0, 1.0)
	phase += delta * (2.2 + speed * 4.5)
	for i in legs.size():
		var swing := sin(phase + (PI if i % 2 == 0 else 0.0)) * 0.6 * amp
		legs[i].rotation.x = swing
		if i < _knees.size():
			_knees[i].rotation.x = maxf(0.0, swing) * 0.55

	if kind == "bird" and wing_l and wing_r:
		var flap := sin(_time * 8.0) * 0.18
		wing_l.rotation.z = 0.08 + flap
		wing_r.rotation.z = -0.08 - flap
		if body:
			body.position.y = 0.34 + sin(_time * 2.2) * 0.025
	elif kind == "fish" and tail:
		tail.rotation.y = sin(_time * 5.0) * 0.45
		if body:
			body.position.y = sin(_time * 1.2) * 0.03

	if body and kind != "bird" and kind != "fish":
		var breath := 1.0 + sin(_time * 1.5) * 0.012
		body.scale = Vector3(1.0, breath, 1.0)
	if head and kind != "bird" and kind != "fish":
		head.rotation.x = sin(phase * 2.0) * 0.045 * amp + sin(_time * 1.1) * 0.012
	for i in _ears.size():
		var ear := _ears[i]
		var twitch := 0.0
		if fmod(_time + i * 1.7, 4.6) < 0.16:
			twitch = sin(_time * 55.0) * 0.16
		ear.rotation.z += sin(_time * 1.7 + i * 2.4) * 0.0009 + twitch * 0.02
	if tail and kind != "fish" and kind != "bird":
		tail.rotation.z = sin(_time * 3.0) * 0.2 + (0.2 * amp)
	if _eyes_nodes.size() > 0:
		_blink -= delta
		if _blink <= 0.0:
			_blink = randf_range(2.4, 5.6)
			_blink_scale = 0.12
		_blink_scale = lerpf(_blink_scale, 1.0, minf(1.0, delta * 16.0))
		for eye in _eyes_nodes:
			eye.scale.y = _blink_scale
	if cheer_time > 0.0:
		position.y = absf(sin(_time * 10.0)) * 0.32
	else:
		position.y = lerpf(position.y, base_y, minf(1.0, delta * 8.0))
