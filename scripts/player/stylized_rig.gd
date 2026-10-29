class_name StylizedRig
extends Node3D
## Corpo estilizado (chibi) feito de primitivas, com animação procedural:
## parado, caminhada, corrida, salto, interação e comemoração.
## Substituível por um modelo .glb + AnimationPlayer mantendo os mesmos métodos.

var skin := Color("#e8b98f")
var hair := Color("#5a3b26")
var tunic := Color("#3f8f7f")
var trim := Color("#f2c14e")
var pants := Color("#6f5a4a")
var shoe := Color("#5a3b26")

var hips: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var eye_l: MeshInstance3D
var eye_r: MeshInstance3D
var hat: Node3D

var speed := 0.0
var on_floor := true
var vertical_speed := 0.0
var phase := 0.0
var walk_blend := 0.0
var interact_time := 0.0
var cheer_time := 0.0
var _time := 0.0
var _blink_timer := 2.0
var _eye_scale := 1.0
var built := false

func _ready() -> void:
	if not built:
		_build()

func configure(colors: Dictionary) -> void:
	skin = colors.get("skin", skin)
	hair = colors.get("hair", hair)
	tunic = colors.get("tunic", tunic)
	trim = colors.get("trim", trim)
	pants = colors.get("pants", pants)
	shoe = colors.get("shoe", shoe)
	if built:
		_build()

func _build() -> void:
	built = true
	for child in get_children():
		child.queue_free()

	leg_l = _pivot(Vector3(-0.13, 0.58, 0))
	leg_r = _pivot(Vector3(0.13, 0.58, 0))
	_build_leg(leg_l)
	_build_leg(leg_r)

	hips = Node3D.new()
	hips.name = "Hips"
	add_child(hips)

	torso = Node3D.new()
	torso.name = "Torso"
	hips.add_child(torso)

	Props.part(hips, Props.cylinder_mesh(0.2, 0.33, 0.52, 10), Props.mat(tunic),
		Vector3(0, 0.76, 0), Vector3.ZERO, Vector3(1, 1, 0.85), "Tunic")
	Props.part(hips, Props.box_mesh(Vector3(0.5, 0.08, 0.32)), Props.mat(trim), Vector3(0, 0.78, 0))
	Props.part(hips, Props.capsule_mesh(0.5, 0.22), Props.mat(tunic.lightened(0.05)),
		Vector3(0, 0.98, 0), Vector3.ZERO, Vector3.ONE, "TorsoMesh")
	Props.part(hips, Props.sphere_mesh(0.06, 8, 4), Props.mat(trim), Vector3(0, 1.02, -0.2))

	arm_l = _pivot(Vector3(-0.28, 1.08, 0), hips)
	arm_r = _pivot(Vector3(0.28, 1.08, 0), hips)
	_build_arm(arm_l)
	_build_arm(arm_r)

	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.36, 0)
	hips.add_child(head)
	Props.part(head, Props.sphere_mesh(0.235, 14, 8), Props.mat(skin), Vector3.ZERO)
	Props.part(head, Props.sphere_mesh(0.235, 12, 6), Props.mat(hair), Vector3(0, 0.06, 0.03),
		Vector3.ZERO, Vector3(1.03, 0.82, 1.03), "Hair")
	Props.part(head, Props.box_mesh(Vector3(0.16, 0.1, 0.06)), Props.mat(hair.darkened(0.08)), Vector3(0, 0.09, 0.02))
	# olhos
	eye_l = Props.part(head, Props.sphere_mesh(0.035, 8, 5), Props.unshaded(Color("#33261f")), Vector3(-0.082, 0.01, -0.216))
	eye_r = Props.part(head, Props.sphere_mesh(0.035, 8, 5), Props.unshaded(Color("#33261f")), Vector3(0.082, 0.01, -0.216))
	Props.part(head, Props.sphere_mesh(0.012, 6, 4), Props.unshaded(Color("#ffffff")), Vector3(-0.07, 0.022, -0.244))
	Props.part(head, Props.sphere_mesh(0.012, 6, 4), Props.unshaded(Color("#ffffff")), Vector3(0.094, 0.022, -0.244))
	Props.part(head, Props.sphere_mesh(0.024, 6, 4), Props.mat(skin.darkened(0.08)), Vector3(0, -0.03, -0.235))
	Props.part(head, Props.sphere_mesh(0.04, 6, 4), Props.unshaded(Color("#8c4a42")), Vector3(0, -0.085, -0.22),
		Vector3.ZERO, Vector3(1.25, 0.4, 0.4))
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.055, 8, 4), Props.mat(skin.darkened(0.03)),
			Vector3(side * 0.22, 0, 0), Vector3.ZERO, Vector3(0.5, 1, 1))

func _pivot(position: Vector3, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	node.position = position
	if parent:
		parent.add_child(node)
	else:
		add_child(node)
	return node

func _build_leg(leg: Node3D) -> void:
	Props.part(leg, Props.capsule_mesh(0.48, 0.09), Props.mat(pants), Vector3(0, -0.22, 0), Vector3.ZERO, Vector3(0.85, 0.9, 0.85))
	Props.part(leg, Props.sphere_mesh(0.095, 8, 4), Props.mat(skin), Vector3(0, -0.44, 0))
	Props.part(leg, Props.box_mesh(Vector3(0.17, 0.1, 0.26)), Props.mat(shoe), Vector3(0, -0.52, -0.04))

func _build_arm(arm: Node3D) -> void:
	Props.part(arm, Props.sphere_mesh(0.075, 8, 4), Props.mat(tunic), Vector3.ZERO)
	Props.part(arm, Props.capsule_mesh(0.42, 0.06), Props.mat(skin), Vector3(0, -0.23, 0), Vector3.ZERO, Vector3(0.85, 1, 0.85))
	Props.part(arm, Props.sphere_mesh(0.075, 8, 4), Props.mat(skin), Vector3(0, -0.46, 0))

func add_hat(color := Color("#b8644a")) -> void:
	if hat and is_instance_valid(hat):
		return
	hat = Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0, 0.17, 0)
	head.add_child(hat)
	Props.part(hat, Props.cylinder_mesh(0.34, 0.36, 0.05, 12), Props.mat(color), Vector3.ZERO)
	Props.part(hat, Props.cylinder_mesh(0.18, 0.24, 0.18, 12), Props.mat(color.darkened(0.06)), Vector3(0, 0.1, 0))

func add_beard(color := Color("#8a8a8a")) -> void:
	Props.part(head, Props.sphere_mesh(0.17, 10, 6), Props.mat(color), Vector3(0, -0.16, -0.09),
		Vector3.ZERO, Vector3(1.0, 0.9, 0.8), "Beard")

func set_locomotion(new_speed: float, grounded: bool, vertical := 0.0) -> void:
	speed = new_speed
	on_floor = grounded
	vertical_speed = vertical

func play_interact() -> void:
	interact_time = 0.7

func play_cheer(duration := 1.4) -> void:
	cheer_time = duration

func _process(delta: float) -> void:
	_time += delta
	if cheer_time > 0.0:
		cheer_time -= delta
	if interact_time > 0.0:
		interact_time -= delta

	var target_blend := clampf(speed / 6.5, 0.0, 1.0) if on_floor else 0.25
	walk_blend = lerpf(walk_blend, target_blend, minf(1.0, delta * 9.0))
	phase += delta * (3.5 + clampf(speed, 0.0, 8.0) * 1.6)

	var sway := sin(phase) * walk_blend
	var idle_t := _time * 1.6
	var hip_bob := absf(sin(phase)) * 0.035 * walk_blend + sin(idle_t) * 0.006
	var leg_swing := sway * 0.75
	var arm_swing := -sway * 0.6

	if not on_floor:
		leg_swing = 0.35 if vertical_speed > 0.0 else 0.15
		arm_swing = -0.9
		hip_bob = 0.05

	if cheer_time > 0.0:
		arm_swing = -2.4
		hip_bob += absf(sin(_time * 9.0)) * 0.06

	if interact_time > 0.0:
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.35, minf(1.0, delta * 14.0))
		arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_swing, minf(1.0, delta * 10.0))
	else:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_swing, minf(1.0, delta * 10.0))
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -arm_swing, minf(1.0, delta * 10.0))

	arm_l.rotation.z = lerpf(arm_l.rotation.z, 0.08 + sin(idle_t) * 0.02, minf(1.0, delta * 6.0))
	arm_r.rotation.z = lerpf(arm_r.rotation.z, -0.08 - sin(idle_t) * 0.02, minf(1.0, delta * 6.0))

	leg_l.rotation.x = lerpf(leg_l.rotation.x, leg_swing, minf(1.0, delta * 12.0))
	leg_r.rotation.x = lerpf(leg_r.rotation.x, -leg_swing, minf(1.0, delta * 12.0))

	hips.position.y = lerpf(hips.position.y, hip_bob, minf(1.0, delta * 10.0))
	hips.rotation.x = lerpf(hips.rotation.x, -0.06 * walk_blend, minf(1.0, delta * 8.0))
	head.rotation.y = sin(idle_t * 0.5) * 0.06
	head.rotation.x = sin(idle_t * 0.8) * 0.025

	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.2, 4.8)
		_eye_scale = 0.15
	_eye_scale = lerpf(_eye_scale, 1.0, minf(1.0, delta * 18.0))
	if eye_l and eye_r:
		eye_l.scale.y = _eye_scale
		eye_r.scale.y = _eye_scale
