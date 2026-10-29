class_name AnimalRig
extends Node3D
## Animais estilizados procedurais (ovelha, coelho, cervo, pássaro, jumento, cabra, peixe).

var kind := "sheep"
var palette := {}
var speed := 0.0
var phase := 0.0
var cheer_time := 0.0
var _time := 0.0
var built := false
var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
var wing_l: Node3D
var wing_r: Node3D
var base_y := 0.0

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

func _build_sheep() -> void:
	var wool: Color = palette.get("body", Color("#f3efe4"))
	var face: Color = palette.get("face", Color("#4b463f"))
	body = _node(Vector3(0, 0.78, 0))
	Props.part(body, Props.sphere_mesh(0.55, 12, 7), Props.mat(wool), Vector3.ZERO, Vector3.ZERO, Vector3(1.35, 0.95, 1.0))
	for offset in [Vector3(0.4, 0.15, 0.15), Vector3(-0.4, 0.1, -0.1), Vector3(0.05, 0.35, 0.3)]:
		Props.part(body, Props.sphere_mesh(0.3, 8, 5), Props.mat(wool.lightened(0.03)), offset)
	head = _node(Vector3(0, 0.95, -0.62))
	Props.part(head, Props.sphere_mesh(0.25, 10, 6), Props.mat(face), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.95, 1.1))
	Props.part(head, Props.sphere_mesh(0.13, 8, 5), Props.mat(face.lightened(0.06)), Vector3(0, -0.08, -0.2), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))
	_eyes(head, face, 0.2, 0.07, 0.08, -0.2)
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.09, 6, 4), Props.mat(face), Vector3(side * 0.22, 0.05, 0.02),
			Vector3(0, 0, side * 20), Vector3(1.0, 0.45, 0.7))
	_legs(0.5, 0.5, 0.07, face.darkened(0.15), [[-0.28, 0.3], [0.28, 0.3], [-0.28, -0.3], [0.28, -0.3]])
	tail = _node(Vector3(0, 0.85, 0.55))
	Props.part(tail, Props.sphere_mesh(0.16, 8, 5), Props.mat(wool), Vector3.ZERO)

func _build_rabbit() -> void:
	var fur: Color = palette.get("body", Color("#d8c3a5"))
	var pink: Color = palette.get("ears", Color("#e8a7a0"))
	body = _node(Vector3(0, 0.5, 0))
	Props.part(body, Props.sphere_mesh(0.36, 12, 7), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(1.05, 1.0, 1.25))
	head = _node(Vector3(0, 0.72, -0.33))
	Props.part(head, Props.sphere_mesh(0.24, 12, 7), Props.mat(fur), Vector3.ZERO)
	Props.part(head, Props.sphere_mesh(0.065, 6, 4), Props.mat(pink), Vector3(0, -0.05, -0.22))
	for side in [-1, 1]:
		var ear := _node(Vector3(side * 0.1, 0.2, 0.02), head)
		Props.part(ear, Props.sphere_mesh(0.09, 8, 5), Props.mat(fur), Vector3(0, 0.22, 0),
			Vector3(0, 0, side * 6), Vector3(0.85, 2.2, 0.5))
		Props.part(ear, Props.sphere_mesh(0.055, 6, 4), Props.mat(pink), Vector3(0, 0.22, -0.03),
			Vector3(0, 0, side * 6), Vector3(0.8, 2.0, 0.25))
	_eyes(head, fur, 0.2, 0.08, 0.09, -0.19)
	_legs(0.32, 0.28, 0.085, fur, [[-0.18, -0.2], [0.18, -0.2], [-0.18, 0.2], [0.18, 0.2]])
	tail = _node(Vector3(0, 0.52, 0.38))
	Props.part(tail, Props.sphere_mesh(0.12, 8, 5), Props.mat(Color("#fffaf0")), Vector3.ZERO)

func _build_deer() -> void:
	var fur: Color = palette.get("body", Color("#b98a62"))
	var dark: Color = fur.darkened(0.25)
	body = _node(Vector3(0, 0.92, 0))
	Props.part(body, Props.sphere_mesh(0.45, 12, 7), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(1.25, 0.95, 1.0))
	for z in [-0.2, 0.1, 0.3]:
		Props.part(body, Props.sphere_mesh(0.05, 6, 4), Props.mat(Color("#f7edda")), Vector3(0.16, 0.25, z))
	head = _node(Vector3(0, 1.42, -0.48))
	Props.part(head, Props.sphere_mesh(0.23, 10, 6), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 1.0, 1.2))
	Props.part(head, Props.sphere_mesh(0.12, 8, 5), Props.mat(fur.darkened(0.08)), Vector3(0, -0.05, -0.22), Vector3.ZERO, Vector3(0.9, 0.8, 1.1))
	Props.part(self, Props.cylinder_mesh(0.11, 0.16, 0.5, 8), Props.mat(fur), Vector3(0, 1.15, -0.3), Vector3(12, 0, 0))
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.1, 6, 4), Props.mat(fur), Vector3(side * 0.2, 0.08, 0.02),
			Vector3(0, 0, side * 24), Vector3(1.0, 0.5, 0.7))
		var horn := _node(Vector3(side * 0.1, 0.18, 0.02), head)
		Props.part(horn, Props.cylinder_mesh(0.0, 0.03, 0.3, 5), Props.mat(Color("#e6d3b3")),
			Vector3(0, 0.14, 0), Vector3(-20, 0, side * -22))
		Props.part(horn, Props.cylinder_mesh(0.0, 0.025, 0.18, 5), Props.mat(Color("#e6d3b3")),
			Vector3(side * 0.08, 0.28, 0), Vector3(-10, 0, side * -50))
	_eyes(head, fur, 0.2, 0.075, 0.09, -0.2)
	_legs(0.78, 0.8, 0.06, dark, [[-0.22, 0.35], [0.22, 0.35], [-0.22, -0.35], [0.22, -0.35]])
	tail = _node(Vector3(0, 1.0, 0.5))
	Props.part(tail, Props.sphere_mesh(0.09, 6, 4), Props.mat(Color("#f7edda")), Vector3(0, 0, 0))

func _build_bird() -> void:
	var feather: Color = palette.get("body", Color("#5b8fd6"))
	body = _node(Vector3(0, 1.0, 0))
	Props.part(body, Props.sphere_mesh(0.22, 10, 6), Props.mat(feather), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.9, 1.3))
	head = _node(Vector3(0, 0.16, -0.22), body)
	Props.part(head, Props.sphere_mesh(0.15, 10, 6), Props.mat(feather.lightened(0.06)), Vector3.ZERO)
	Props.part(head, Props.cylinder_mesh(0.0, 0.05, 0.13, 5), Props.mat(Color("#f2b544")), Vector3(0, -0.01, -0.17), Vector3(90, 0, 0))
	_eyes(head, feather, 0.16, 0.06, 0.06, -0.12)
	wing_l = _node(Vector3(-0.2, 0.02, 0), body)
	wing_r = _node(Vector3(0.2, 0.02, 0), body)
	Props.part(wing_l, Props.sphere_mesh(0.26, 8, 5), Props.mat(feather.darkened(0.06)), Vector3(-0.14, 0, 0.02),
		Vector3(0, 0, 15), Vector3(1.1, 0.12, 0.55))
	Props.part(wing_r, Props.sphere_mesh(0.26, 8, 5), Props.mat(feather.darkened(0.06)), Vector3(0.14, 0, 0.02),
		Vector3(0, 0, -15), Vector3(1.1, 0.12, 0.55))
	tail = _node(Vector3(0, 0, 0.28), body)
	Props.part(tail, Props.sphere_mesh(0.16, 6, 4), Props.mat(feather.darkened(0.12)), Vector3(0, 0.02, 0.12),
		Vector3(0, 0, 0), Vector3(1.2, 0.16, 1.5))

func _build_donkey() -> void:
	var fur: Color = palette.get("body", Color("#9d9a91"))
	body = _node(Vector3(0, 0.85, 0))
	Props.part(body, Props.sphere_mesh(0.48, 12, 7), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(1.3, 0.95, 1.0))
	head = _node(Vector3(0, 1.25, -0.55))
	Props.part(head, Props.sphere_mesh(0.24, 10, 6), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(0.85, 1.0, 1.2))
	Props.part(head, Props.box_mesh(Vector3(0.22, 0.2, 0.34)), Props.mat(fur.lightened(0.08)), Vector3(0, -0.1, -0.24))
	Props.part(head, Props.sphere_mesh(0.055, 6, 4), Props.mat(Color("#4b463f")), Vector3(0, -0.12, -0.42))
	for side in [-1, 1]:
		var ear := _node(Vector3(side * 0.12, 0.2, 0.02), head)
		Props.part(ear, Props.sphere_mesh(0.1, 8, 5), Props.mat(fur), Vector3(0, 0.24, 0),
			Vector3(0, 0, side * 18), Vector3(0.6, 2.4, 0.45))
	_eyes(head, fur, 0.2, 0.075, 0.08, -0.18)
	Props.part(self, Props.box_mesh(Vector3(0.08, 0.5, 0.12)), Props.mat(fur.darkened(0.2)), Vector3(0, 1.15, -0.28))
	_legs(0.7, 0.72, 0.07, fur.darkened(0.1), [[-0.26, 0.34], [0.26, 0.34], [-0.26, -0.34], [0.26, -0.34]])
	Props.part(body, Props.cylinder_mesh(0.05, 0.07, 0.5, 6), Props.mat(fur.darkened(0.18)), Vector3(0, 0.1, 0.48), Vector3(35, 0, 0))
	tail = _node(Vector3(0, 0.75, 0.55))
	Props.part(tail, Props.sphere_mesh(0.1, 6, 4), Props.mat(fur.darkened(0.2)), Vector3(0, -0.15, 0.08))

func _build_goat() -> void:
	var fur: Color = palette.get("body", Color("#efe6d2"))
	body = _node(Vector3(0, 0.68, 0))
	Props.part(body, Props.sphere_mesh(0.4, 12, 7), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(1.25, 0.95, 0.95))
	head = _node(Vector3(0, 0.98, -0.42))
	Props.part(head, Props.sphere_mesh(0.22, 10, 6), Props.mat(fur), Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 1.0, 1.15))
	Props.part(head, Props.sphere_mesh(0.12, 6, 4), Props.mat(fur.lightened(0.05)), Vector3(0, -0.06, -0.2))
	Props.part(head, Props.sphere_mesh(0.09, 6, 4), Props.mat(Color("#d8cbb5")), Vector3(0, -0.2, -0.15),
		Vector3.ZERO, Vector3(0.7, 1.2, 0.6), "Beard")
	for side in [-1, 1]:
		Props.part(head, Props.cylinder_mesh(0.0, 0.035, 0.3, 5), Props.mat(Color("#b9a17c")),
			Vector3(side * 0.08, 0.2, 0.04), Vector3(-30, 0, side * -30))
		Props.part(head, Props.sphere_mesh(0.09, 6, 4), Props.mat(fur), Vector3(side * 0.2, 0.03, 0),
			Vector3(0, 0, side * 28), Vector3(1.0, 0.45, 0.7))
	_eyes(head, fur, 0.2, 0.07, 0.08, -0.18)
	_legs(0.5, 0.52, 0.065, fur.darkened(0.12), [[-0.22, 0.28], [0.22, 0.28], [-0.22, -0.28], [0.22, -0.28]])
	tail = _node(Vector3(0, 0.75, 0.4))
	Props.part(tail, Props.sphere_mesh(0.09, 6, 4), Props.mat(fur), Vector3(0, 0.08, 0.06),
		Vector3(0, 0, 0), Vector3(0.6, 1.4, 0.6))

func _build_fish() -> void:
	var scale_color: Color = palette.get("body", Color("#e8a35c"))
	body = _node(Vector3(0, 0, 0))
	Props.part(body, Props.sphere_mesh(0.28, 10, 6), Props.mat(scale_color), Vector3.ZERO, Vector3.ZERO, Vector3(0.75, 1.0, 1.7))
	Props.part(body, Props.sphere_mesh(0.12, 8, 5), Props.mat(scale_color.lightened(0.1)), Vector3(0, 0.06, -0.3), Vector3.ZERO, Vector3(0.7, 0.8, 0.8))
	_eyes(body, scale_color, 0.1, 0.1, 0.0, -0.22)
	tail = _node(Vector3(0, 0, 0.42), body)
	Props.part(tail, Props.sphere_mesh(0.2, 6, 4), Props.mat(scale_color.lightened(0.05)), Vector3(0, 0, 0.08),
		Vector3(0, 0, 0), Vector3(0.2, 1.1, 0.9))
	Props.part(body, Props.sphere_mesh(0.12, 6, 4), Props.mat(scale_color.darkened(0.1)), Vector3(0, 0.26, 0.05),
		Vector3(0, 0, 0), Vector3(0.2, 1.0, 1.2))

func _node(position: Vector3, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	node.position = position
	if parent:
		parent.add_child(node)
	else:
		add_child(node)
	return node

func _legs(top_y: float, height: float, radius: float, color: Color, positions: Array) -> void:
	for pair in positions:
		var pivot := _node(Vector3(pair[0], top_y, pair[1]))
		Props.part(pivot, Props.cylinder_mesh(radius, radius * 1.05, height, 7), Props.mat(color),
			Vector3(0, -height * 0.5, 0))
		Props.part(pivot, Props.sphere_mesh(radius * 1.3, 6, 4), Props.mat(color.darkened(0.1)),
			Vector3(0, -height, -0.02))
		legs.append(pivot)

func _eyes(parent: Node3D, _color: Color, x: float, y: float, _z: float, distance: float) -> void:
	Props.part(parent, Props.sphere_mesh(0.045, 6, 4), Props.unshaded(Color("#2f2721")),
		Vector3(-x, y, distance), Vector3.ZERO, Vector3(1, 1, 0.6))
	Props.part(parent, Props.sphere_mesh(0.045, 6, 4), Props.unshaded(Color("#2f2721")),
		Vector3(x, y, distance), Vector3.ZERO, Vector3(1, 1, 0.6))
	Props.part(parent, Props.sphere_mesh(0.014, 5, 3), Props.unshaded(Color("#ffffff")),
		Vector3(-x + 0.012, y + 0.018, distance - 0.03))
	Props.part(parent, Props.sphere_mesh(0.014, 5, 3), Props.unshaded(Color("#ffffff")),
		Vector3(x + 0.012, y + 0.018, distance - 0.03))

func _process(delta: float) -> void:
	_time += delta
	if cheer_time > 0.0:
		cheer_time -= delta
	var amp := clampf(speed / 2.2, 0.0, 1.0)
	phase += delta * (2.2 + speed * 4.5)
	for i in legs.size():
		legs[i].rotation.x = sin(phase + (PI if i % 2 == 0 else 0.0)) * 0.55 * amp

	if kind == "bird" and wing_l and wing_r:
		var flap := sin(_time * 8.0) * 0.55
		wing_l.rotation.z = 0.2 + flap
		wing_r.rotation.z = -0.2 - flap
		if body:
			body.position.y = 1.0 + sin(_time * 1.6) * 0.08
	elif kind == "fish" and tail:
		tail.rotation.y = sin(_time * 5.0) * 0.4

	if head and kind != "bird" and kind != "fish":
		head.rotation.x = sin(phase * 2.0) * 0.05 * amp
	if tail and kind != "fish" and kind != "bird":
		tail.rotation.z = sin(_time * 3.0) * 0.18 + (0.25 * amp)
	if cheer_time > 0.0:
		position.y = absf(sin(_time * 10.0)) * 0.32
	else:
		position.y = lerpf(position.y, base_y, minf(1.0, delta * 8.0))
