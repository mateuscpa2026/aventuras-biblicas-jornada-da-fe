class_name StylizedRig
extends Node3D
## Corpo estilizado (chibi) feito de primitivas, com rosto, cabelos, mãos,
## sandálias e trajes masculinos/femininos. Animação procedural: parado,
## caminhada, corrida, salto, interação e comemoração.
##
## Configuração (todas opcionais):
##   gender: "male" | "female"
##   outfit: "tunic" (curta) | "robe" (longa) | "dress" (vestido)
##   hair_style: "short" | "long" | "braid" | "bun" | "bald"
##   headwear: "none" | "headband" | "turban" | "veil" | "hood"
##   jewelry: true/false, cloak: Color, sash: Color, veil: Color
## Substituível por um modelo .glb + AnimationPlayer mantendo os mesmos métodos.

const HIP_Y := 0.60

var skin := Color("#e8b98f")
var hair := Color("#5a3b26")
var iris := Color("#5b3a24")
var tunic := Color("#3f8f7f")
var trim := Color("#f2c14e")
var pants := Color("#6f5a4a")
var shoe := Color("#5a3b26")
var sash := Color("#c9a06a")
var cloak := Color(0, 0, 0, 0)
var veil := Color(0, 0, 0, 0)

var gender := "male"
var outfit := "tunic"
var hair_style := "short"
var headwear := "none"
var jewelry := false

var hips: Node3D
var torso: Node3D
var skirt: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var ankle_l: Node3D
var ankle_r: Node3D
var eye_l: Node3D
var eye_r: Node3D
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
	iris = colors.get("iris", iris)
	tunic = colors.get("tunic", tunic)
	trim = colors.get("trim", trim)
	pants = colors.get("pants", pants)
	shoe = colors.get("shoe", shoe)
	sash = colors.get("sash", trim)
	cloak = colors.get("cloak", cloak)
	veil = colors.get("veil", trim.lightened(0.45))
	gender = str(colors.get("gender", gender))
	outfit = str(colors.get("outfit", "dress" if gender == "female" else "tunic"))
	hair_style = str(colors.get("hair_style", "long" if gender == "female" else "short"))
	headwear = str(colors.get("headwear", headwear))
	jewelry = bool(colors.get("jewelry", gender == "female"))
	if built:
		_build()

func _build() -> void:
	built = true
	for child in get_children():
		child.queue_free()

	if outfit == "dress":
		gender = "female"
		if hair_style == "short":
			hair_style = "long"

	_build_legs()

	hips = Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, HIP_Y, 0)
	add_child(hips)
	torso = Node3D.new()
	torso.name = "Torso"
	hips.add_child(torso)

	_build_skirt()
	_build_torso()
	_build_arms()
	_build_cloak()
	_build_head()

# ---------------------------------------------------------------- pernas

func _pivot(parent: Node3D, position: Vector3, node_name := "") -> Node3D:
	var node := Node3D.new()
	node.position = position
	if node_name != "":
		node.name = node_name
	parent.add_child(node)
	return node

func _build_legs() -> void:
	leg_l = _pivot(self, Vector3(-0.115, HIP_Y, 0), "LegL")
	leg_r = _pivot(self, Vector3(0.115, HIP_Y, 0), "LegR")
	_build_leg(leg_l, true)
	_build_leg(leg_r, false)

func _build_leg(leg: Node3D, is_left: bool) -> void:
	Props.part(leg, Props.capsule_mesh(0.32, 0.085, 10),
		Props.fabric_mat(pants) if outfit == "tunic" else Props.mat(skin, 0.72),
		Vector3(0, -0.16, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "Thigh")
	var knee := _pivot(leg, Vector3(0, -0.32, 0), "Knee")
	Props.part(knee, Props.sphere_mesh(0.072, 8, 5), Props.mat(pants if outfit == "tunic" else skin), Vector3.ZERO)
	Props.part(knee, Props.capsule_mesh(0.24, 0.062, 10), Props.mat(skin),
		Vector3(0, -0.12, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "Shin")
	var ankle := _pivot(knee, Vector3(0, -0.24, 0), "Ankle")
	_build_foot(ankle)
	if is_left:
		knee_l = knee
		ankle_l = ankle
	else:
		knee_r = knee
		ankle_r = ankle

func _build_foot(ankle: Node3D) -> void:
	Props.part(ankle, Props.box_mesh(Vector3(0.17, 0.035, 0.29)), Props.mat(shoe),
		Vector3(0, -0.022, -0.06), Vector3.ZERO, Vector3.ONE, "Sole")
	Props.part(ankle, Props.sphere_mesh(0.072, 9, 5), Props.mat(skin),
		Vector3(0, 0.012, -0.075), Vector3.ZERO, Vector3(0.85, 0.55, 1.55), "Foot")
	Props.part(ankle, Props.box_mesh(Vector3(0.145, 0.022, 0.03)), Props.mat(shoe.darkened(0.06)),
		Vector3(0, 0.038, -0.135), Vector3(10, 0, 0), Vector3.ONE, "SandalStrap")
	Props.part(ankle, Props.box_mesh(Vector3(0.135, 0.018, 0.032)), Props.mat(shoe.darkened(0.02)),
		Vector3(0, 0.03, -0.06), Vector3(0, 34, 4), Vector3.ONE, "SandalCross")
	Props.part(ankle, Props.box_mesh(Vector3(0.15, 0.028, 0.06)), Props.mat(shoe),
		Vector3(0, 0.05, 0.0), Vector3.ZERO, Vector3.ONE, "AnkleStrap")
	for i in 3:
		Props.part(ankle, Props.sphere_mesh(0.019, 6, 4), Props.mat(skin),
			Vector3(-0.045 + i * 0.045, 0.012, -0.205), Vector3.ZERO, Vector3(1, 0.7, 1), "Toe")

# ---------------------------------------------------------------- tronco e roupa

func _build_skirt() -> void:
	skirt = Node3D.new()
	skirt.name = "Skirt"
	if outfit == "tunic":
		skirt.position = Vector3(0, 0.07, 0)
	else:
		skirt.position = Vector3(0, 0.1, 0)
	hips.add_child(skirt)

	var cloth := tunic
	var long := outfit != "tunic"
	var height := 0.58 if long else 0.34
	var center := -height * 0.5
	var top_radius := 0.17
	var bottom_radius := 0.30 if outfit == "robe" else 0.34 if outfit == "dress" else 0.27
	Props.part(skirt, Props.cylinder_mesh(top_radius, bottom_radius, height, 16), Props.fabric_mat(cloth),
		Vector3(0, center, 0), Vector3.ZERO, Vector3(1, 1, 0.88), "SkirtCloth")
	Props.part(skirt, Props.cylinder_mesh(bottom_radius + 0.012, bottom_radius + 0.012, 0.05, 16),
		Props.mat(trim), Vector3(0, center - height * 0.5 + 0.025, 0), Vector3.ZERO, Vector3(1, 1, 0.88), "Hem")
	Props.part(skirt, Props.cylinder_mesh(top_radius + 0.008, top_radius + 0.012, 0.06, 16),
		Props.fabric_mat(cloth.darkened(0.10)), Vector3(0, 0.015, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "Waistband")
	for i in 8:
		var stitch := TAU * float(i) / 8.0
		Props.part(skirt, Props.box_mesh(Vector3(0.034, 0.022, 0.016)), Props.mat(trim.darkened(0.05)),
			Vector3(sin(stitch) * (bottom_radius + 0.01), center - height * 0.5 + 0.022,
				cos(stitch) * (bottom_radius + 0.01) * 0.88),
			Vector3(0, rad_to_deg(stitch), 0), Vector3.ONE, "HemStitch")
	var folds := 9 if long else 6
	var slant := sqrt(height * height + pow(bottom_radius - top_radius, 2.0))
	var tilt := -atan2(bottom_radius - top_radius, height)
	for i in folds:
		var a := TAU * float(i) / float(folds)
		var radius := (top_radius + bottom_radius) * 0.5
		Props.part(skirt, Props.box_mesh(Vector3(0.028, slant * 0.94, 0.03)),
			Props.mat(cloth.darkened(0.06)),
			Vector3(sin(a) * radius, center - 0.005, cos(a) * radius * 0.88),
			Vector3(rad_to_deg(tilt), rad_to_deg(a), 0), Vector3.ONE, "Fold")
	if outfit == "dress":
		Props.part(skirt, Props.cylinder_mesh(0.185, 0.19, 0.16, 16), Props.mat(trim.lightened(0.12)),
			Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "OverTunic")
		Props.part(skirt, Props.sphere_mesh(0.05, 8, 5), Props.mat(trim),
			Vector3(0, -0.02, -0.17), Vector3.ZERO, Vector3(1.5, 0.7, 0.5), "SashKnot")
		for side in [-1, 1]:
			Props.part(skirt, Props.box_mesh(Vector3(0.05, 0.22, 0.02)), Props.mat(trim.darkened(0.05)),
				Vector3(side * 0.035, -0.14, -0.165), Vector3(0, 0, side * 6.0), Vector3.ONE, "SashTail")

func _build_torso() -> void:
	Props.part(torso, Props.cylinder_mesh(0.185, 0.155, 0.36, 16), Props.fabric_mat(tunic),
		Vector3(0, 0.27, 0), Vector3.ZERO, Vector3(1, 1, 0.78), "TorsoCloth")
	Props.part(torso, Props.sphere_mesh(0.17, 12, 6), Props.fabric_mat(tunic.lightened(0.04)),
		Vector3(0, 0.42, 0), Vector3.ZERO, Vector3(1.18, 0.55, 0.76), "Shoulders")
	Props.part(torso, Props.cylinder_mesh(0.065, 0.075, 0.10, 10), Props.mat(skin),
		Vector3(0, 0.53, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "Neck")
	Props.part(torso, Props.cylinder_mesh(0.093, 0.093, 0.028, 12), Props.mat(trim),
		Vector3(0, 0.512, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "Collar")
	Props.part(torso, Props.cylinder_mesh(0.088, 0.1, 0.035, 12), Props.fabric_mat(tunic.darkened(0.14)),
		Vector3(0, 0.49, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "Neckline")
	# costura central e bordado discreto
	Props.part(torso, Props.box_mesh(Vector3(0.014, 0.30, 0.02)), Props.fabric_mat(tunic.darkened(0.12)),
		Vector3(0, 0.265, -0.147), Vector3.ZERO, Vector3.ONE, "FrontSeam")
	for i in 3:
		Props.part(torso, Props.box_mesh(Vector3(0.018, 0.018, 0.016)), Props.mat(trim),
			Vector3(0.055 + i * 0.024, 0.325 - i * 0.024, -0.155), Vector3(0, 0, 45), Vector3.ONE, "Embroidery")
	# cinto e fivela
	Props.part(torso, Props.cylinder_mesh(0.168, 0.175, 0.06, 16), Props.mat(trim.darkened(0.12)),
		Vector3(0, 0.10, 0), Vector3.ZERO, Vector3(1, 1, 0.82), "Belt")
	Props.part(torso, Props.box_mesh(Vector3(0.075, 0.065, 0.03)), Props.mat(trim),
		Vector3(0, 0.10, -0.135), Vector3.ZERO, Vector3.ONE, "Buckle")
	Props.part(torso, Props.box_mesh(Vector3(0.045, 0.13, 0.02)), Props.mat(trim.darkened(0.08)),
		Vector3(0.03, 0.03, -0.14), Vector3(0, 0, 4), Vector3.ONE, "BeltTail")
	for i in 4:
		var angle := -0.9 + i * 0.6
		Props.part(torso, Props.box_mesh(Vector3(0.025, 0.075, 0.018)), Props.mat(trim.darkened(0.16)),
			Vector3(sin(angle) * 0.17, 0.10, -cos(angle) * 0.14), Vector3(0, rad_to_deg(angle), 0), Vector3.ONE, "BeltLoop")
	# faixa transversal (vestido/robe)
	if outfit != "tunic":
		Props.part(torso, Props.box_mesh(Vector3(0.075, 0.56, 0.022)), Props.fabric_mat(sash),
			Vector3(0, 0.28, -0.145), Vector3(0, 0, 32), Vector3.ONE, "Sash")
		Props.part(torso, Props.sphere_mesh(0.05, 8, 5), Props.fabric_mat(sash.darkened(0.06)),
			Vector3(-0.13, 0.47, -0.12), Vector3.ZERO, Vector3(1.3, 0.8, 0.6), "SashKnotChest")
	else:
		Props.part(torso, Props.box_mesh(Vector3(0.05, 0.42, 0.02)), Props.mat(trim),
			Vector3(0, 0.27, -0.15), Vector3(0, 0, 0), Vector3.ONE, "TunicBand")
	# alça de couro do pastor (Davi e viajantes usam cinto simples)
	if jewelry:
		for i in 5:
			var angle := lerpf(-0.55, 0.55, float(i) / 4.0)
			Props.part(torso, Props.sphere_mesh(0.014, 6, 4), Props.mat(trim),
				Vector3(sin(angle) * 0.11, 0.475 - cos(angle) * 0.018, -0.155 - cos(angle) * 0.015), Vector3.ZERO, Vector3.ONE, "")
		Props.part(torso, Props.sphere_mesh(0.03, 8, 5), Props.mat(Color("#7fb0d8")),
			Vector3(0, 0.425, -0.17), Vector3.ZERO, Vector3(1, 1.2, 0.6), "Pendant")
	Props.part(torso, Props.sphere_mesh(0.055, 8, 5), Props.mat(tunic.darkened(0.08)),
		Vector3(0.19, 0.05, -0.05), Vector3.ZERO, Vector3(0.9, 0.8, 0.5), "Pouch")

# ---------------------------------------------------------------- braços

func _build_arms() -> void:
	arm_l = _pivot(hips, Vector3(-0.255, 0.45, 0), "ArmL")
	arm_r = _pivot(hips, Vector3(0.255, 0.45, 0), "ArmR")
	_build_arm(arm_l, true)
	_build_arm(arm_r, false)

func _build_arm(arm: Node3D, is_left: bool) -> void:
	var long_sleeve := outfit != "tunic"
	Props.part(arm, Props.sphere_mesh(0.08, 9, 5), Props.fabric_mat(tunic),
		Vector3(0, -0.005, 0), Vector3.ZERO, Vector3(0.98, 0.88, 0.88), "ShoulderCloth")
	Props.part(arm, Props.capsule_mesh(0.24, 0.062, 9), Props.fabric_mat(tunic) if long_sleeve else Props.mat(skin, 0.72),
		Vector3(0, -0.12, 0), Vector3.ZERO, Vector3(0.9, 1, 0.9), "UpperArm")
	var elbow := _pivot(arm, Vector3(0, -0.215, 0), "Elbow")
	Props.part(elbow, Props.capsule_mesh(0.20, 0.055, 9), Props.fabric_mat(tunic) if long_sleeve else Props.mat(skin, 0.72),
		Vector3(0, -0.10, 0), Vector3.ZERO, Vector3(0.9, 1, 0.9), "Forearm")
	if long_sleeve:
		Props.part(elbow, Props.cylinder_mesh(0.066, 0.062, 0.05, 10), Props.mat(trim),
			Vector3(0, -0.185, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "Cuff")
	else:
		Props.part(elbow, Props.cylinder_mesh(0.07, 0.068, 0.04, 10), Props.fabric_mat(tunic.darkened(0.08)),
			Vector3(0, -0.005, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "SleeveHem")
	if long_sleeve:
		Props.part(arm, Props.cylinder_mesh(0.069, 0.066, 0.022, 10), Props.fabric_mat(tunic.darkened(0.06)),
			Vector3(0, -0.075, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "SleeveFold")
	Props.part(elbow, Props.sphere_mesh(0.058, 8, 5), Props.mat(skin),
		Vector3(0, -0.235, 0), Vector3.ZERO, Vector3(1.05, 0.95, 0.75), "Palm")
	for i in 3:
		Props.part(elbow, Props.capsule_mesh(0.05, 0.014, 6), Props.mat(skin),
			Vector3(-0.028 + i * 0.028, -0.29, -0.012), Vector3(0, 0, -4 + i * 4), Vector3.ONE, "")
	Props.part(elbow, Props.capsule_mesh(0.055, 0.017, 6), Props.mat(skin),
		Vector3(-0.052 if is_left else 0.052, -0.245, -0.03), Vector3(0, 0, 38 if is_left else -38), Vector3.ONE, "Thumb")
	if jewelry:
		Props.part(elbow, Props.cylinder_mesh(0.068, 0.068, 0.028, 10), Props.mat(trim),
			Vector3(0, -0.215, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "Bracelet")
	if is_left:
		elbow_l = elbow
	else:
		elbow_r = elbow

# ---------------------------------------------------------------- capa

func _build_cloak() -> void:
	if cloak.a <= 0.01:
		return
	Props.part(torso, Props.cylinder_mesh(0.20, 0.32, 0.74, 14), Props.fabric_mat(cloak),
		Vector3(0, 0.11, 0.155), Vector3.ZERO, Vector3(1, 1, 0.55), "Cloak")
	Props.part(torso, Props.cylinder_mesh(0.325, 0.325, 0.045, 14), Props.fabric_mat(cloak.darkened(0.08)),
		Vector3(0, -0.25, 0.155), Vector3.ZERO, Vector3(1, 1, 0.55), "CloakHem")
	Props.part(torso, Props.cylinder_mesh(0.19, 0.225, 0.14, 14), Props.mat(cloak.lightened(0.03)),
		Vector3(0, 0.42, 0.035), Vector3.ZERO, Vector3(1, 1, 0.66), "CloakShoulder")
	Props.part(torso, Props.sphere_mesh(0.035, 8, 5), Props.mat(trim),
		Vector3(-0.11, 0.46, -0.12), Vector3.ZERO, Vector3.ONE, "Clasp")

# ---------------------------------------------------------------- cabeça

func _build_head() -> void:
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.80, 0)
	hips.add_child(head)

	Props.part(head, Props.sphere_mesh(0.235, 18, 10), Props.mat(skin), Vector3.ZERO, Vector3.ZERO, Vector3(1, 1.02, 0.98), "Skull")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.052, 8, 5), Props.mat(skin),
			Vector3(side * 0.228, -0.005, 0.005), Vector3.ZERO, Vector3(0.5, 1.0, 0.75), "Ear")
		Props.part(head, Props.sphere_mesh(0.027, 6, 4), Props.mat(skin.darkened(0.12)),
			Vector3(side * 0.242, -0.005, 0.0), Vector3.ZERO, Vector3(0.4, 0.9, 0.6), "EarInner")
	Props.part(head, Props.sphere_mesh(0.055, 8, 5), Props.mat(skin),
		Vector3(0, -0.14, -0.11), Vector3.ZERO, Vector3(1.25, 0.9, 0.9), "Chin")
	_build_face()
	_build_hair()
	_build_headwear()

func _build_face() -> void:
	# olhos expressivos, com pálpebra e cílios
	for side in [-1, 1]:
		var eye := Node3D.new()
		eye.name = "EyeL" if side < 0 else "EyeR"
		eye.position = Vector3(side * 0.083, 0.022, -0.198)
		head.add_child(eye)
		Props.part(eye, Props.sphere_mesh(0.048, 12, 7), Props.unshaded(Color("#fffdf4")),
			Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.08, 0.5), "Sclera")
		Props.part(eye, Props.sphere_mesh(0.031, 10, 6), Props.unshaded(iris),
			Vector3(0, -0.002, -0.026), Vector3.ZERO, Vector3(1, 1, 0.45), "Iris")
		Props.part(eye, Props.sphere_mesh(0.016, 8, 5), Props.unshaded(Color("#16100c")),
			Vector3(0, -0.004, -0.041), Vector3.ZERO, Vector3(1, 1, 0.35), "Pupil")
		Props.part(eye, Props.sphere_mesh(0.009, 6, 4), Props.unshaded(Color("#ffffff")),
			Vector3(0.009, 0.011, -0.05), Vector3.ZERO, Vector3.ONE, "Glint")
		# pálpebra superior e vinco
		Props.part(head, Props.sphere_mesh(0.052, 12, 6), Props.mat(skin, 0.72),
			Vector3(side * 0.083, 0.055, -0.2), Vector3(-14, 0, side * -3), Vector3(1.02, 0.34, 0.6), "Eyelid")
		Props.part(head, Props.box_mesh(Vector3(0.072, 0.009, 0.014)), Props.mat(skin.darkened(0.08)),
			Vector3(side * 0.083, 0.082, -0.211), Vector3(0, 0, side * -3), Vector3.ONE, "EyelidCrease")
		if side < 0:
			eye_l = eye
		else:
			eye_r = eye
	# sobrancelhas em arco (dois segmentos)
	for side in [-1, 1]:
		Props.part(head, Props.box_mesh(Vector3(0.052, 0.019, 0.024)), Props.mat(hair.darkened(0.04)),
			Vector3(side * 0.062, 0.103, -0.204), Vector3(0, 0, -side * 4), Vector3.ONE, "Brow")
		Props.part(head, Props.box_mesh(Vector3(0.04, 0.015, 0.022)), Props.mat(hair.darkened(0.04)),
			Vector3(side * 0.107, 0.096, -0.198), Vector3(0, 0, -side * 14), Vector3.ONE, "BrowTip")
	# cílios (feminino)
	if gender == "female":
		for side in [-1, 1]:
			for i in 3:
				Props.part(head, Props.box_mesh(Vector3(0.028, 0.008, 0.011)), Props.mat(hair.darkened(0.02)),
					Vector3(side * (0.061 + i * 0.022), 0.066 - i * 0.005, -0.212), Vector3(0, 0, -side * (16 + i * 7)))
	# nariz com ponte, ponta e narinas
	Props.part(head, Props.sphere_mesh(0.024, 8, 5), Props.mat(skin.darkened(0.03)),
		Vector3(0, 0.0, -0.229), Vector3.ZERO, Vector3(0.55, 1.9, 0.65), "NoseBridge")
	Props.part(head, Props.sphere_mesh(0.031, 9, 6), Props.mat(skin.darkened(0.05)),
		Vector3(0, -0.032, -0.235), Vector3.ZERO, Vector3(0.95, 0.8, 0.75), "Nose")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.012, 6, 4), Props.mat(skin.darkened(0.28)),
			Vector3(side * 0.02, -0.044, -0.231), Vector3(0, 0, side * 18), Vector3(1.1, 0.65, 0.5), "Nostril")
	# boca com lábios e cantos de sorriso
	Props.part(head, Props.sphere_mesh(0.032, 9, 5), Props.unshaded(Color("#9d5148")),
		Vector3(0, -0.078, -0.224), Vector3.ZERO, Vector3(1.45, 0.34, 0.32), "Mouth")
	Props.part(head, Props.sphere_mesh(0.022, 7, 4), Props.unshaded(Color("#b45f55")),
		Vector3(0, -0.092, -0.221), Vector3.ZERO, Vector3(1.25, 0.3, 0.28), "LowerLip")
	Props.part(head, Props.sphere_mesh(0.009, 6, 4), Props.unshaded(Color("#7d3f3a")),
		Vector3(0, -0.078, -0.239), Vector3.ZERO, Vector3(2.4, 0.28, 0.2), "MouthLine")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.007, 5, 3), Props.unshaded(Color("#8c4a42")),
			Vector3(side * 0.045, -0.072, -0.222), Vector3.ZERO, Vector3(1, 0.8, 0.4), "SmileCorner")
	# bochechas e queixo
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.045, 7, 4), Props.mat(skin.lightened(0.10) if gender == "female" else skin, 0.72),
			Vector3(side * 0.13, -0.052, -0.188), Vector3.ZERO, Vector3(1, 0.5, 0.28), "Cheek")
	# brincos discretos para quem usa joias
	if jewelry:
		for side in [-1, 1]:
			Props.part(head, Props.sphere_mesh(0.012, 6, 4), Props.mat(trim),
				Vector3(side * 0.244, -0.028, 0.005), Vector3.ZERO, Vector3(1, 1.8, 0.8), "Earring")

func _build_hair() -> void:
	var color := hair
	if hair_style == "bald":
		for side in [-1, 1]:
			Props.part(head, Props.sphere_mesh(0.15, 8, 5), Props.mat(color),
				Vector3(side * 0.13, -0.02, 0.1), Vector3.ZERO, Vector3(0.55, 0.7, 0.9), "HairSide")
		return
	Props.part(head, Props.sphere_mesh(0.242, 16, 9), Props.mat(color),
		Vector3(0, 0.06, 0.058), Vector3.ZERO, Vector3(1.03, 0.92, 0.98), "Hair")
	Props.part(head, Props.sphere_mesh(0.11, 10, 5), Props.mat(color.darkened(0.03)),
		Vector3(0, 0.16, 0.005), Vector3.ZERO, Vector3(1.5, 0.55, 1.15), "HairTop")
	# linha do cabelo e costeletas
	for i in 7:
		var t := float(i) / 6.0
		var x := lerpf(-0.17, 0.17, t)
		var z := -0.205 + absf(x) * 0.42
		Props.part(head, Props.sphere_mesh(0.026, 7, 4), Props.mat(color.darkened(0.02)),
			Vector3(x, 0.128 - absf(x) * 0.12, z), Vector3(0, 0, 0), Vector3(1.2, 0.6, 0.8), "Hairline")
	for side in [-1, 1]:
		Props.part(head, Props.capsule_mesh(0.09, 0.021, 6), Props.mat(color.darkened(0.03)),
			Vector3(side * 0.205, 0.035, -0.085), Vector3(6, 0, side * 5), Vector3(1, 1, 0.7), "Sideburn")
	# fios do topo
	for i in 4:
		var t := float(i) / 3.0
		Props.part(head, Props.capsule_mesh(0.23, 0.012, 6), Props.mat(color.lightened(0.04 - t * 0.04)),
			Vector3(lerpf(-0.11, 0.11, t), 0.235, 0.01), Vector3(78, 0, lerpf(16, -16, t)), Vector3(1, 1, 0.7), "HairStrand")
	# franja
	var fringe := Props.part(head, Props.sphere_mesh(0.10, 9, 6), Props.mat(color.darkened(0.03)),
		Vector3(0, 0.155, -0.158), Vector3(-12, 0, 0), Vector3(1.62, 0.4, 0.55), "Fringe")
	fringe.rotation_degrees.x = -12
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.06, 8, 5), Props.mat(color.darkened(0.04)),
			Vector3(side * 0.195, 0.045, -0.12), Vector3.ZERO, Vector3(0.7, 1.5, 0.7), "HairSide")
	if hair_style == "curly":
		# cachos em espiral por cima e nas laterais
		for i in 26:
			var angle := TAU * fmod(float(i) * 0.61803398875, 1.0)
			var elevation := float(i) / 25.0
			var y := lerpf(-0.09, 0.25, elevation)
			var radius := sqrt(maxf(0.02, 1.0 - pow(y / 0.27, 2.0))) * 0.252
			var x := cos(angle) * radius
			var z := sin(angle) * radius * 0.98 + 0.05
			if z < -0.11 and y < 0.13:
				continue
			Props.part(head, Props.sphere_mesh(0.055 + 0.012 * (1.0 - elevation), 7, 4),
				Props.mat(color.lightened(0.02 if i % 2 == 0 else -0.02)),
				Vector3(x, y, z), Vector3(0, rad_to_deg(angle), 0), Vector3(1.15, 0.85, 1.0), "Curl")
	if hair_style == "long" or hair_style == "braid" or hair_style == "bun":
		Props.part(head, Props.box_mesh(Vector3(0.35, 0.36, 0.10)), Props.mat(color.darkened(0.04)),
			Vector3(0, -0.17, 0.155), Vector3(5, 0, 0), Vector3.ONE, "HairBack")
		for side in [-1, 1]:
			Props.part(head, Props.capsule_mesh(0.36, 0.045, 8), Props.mat(color.lightened(0.02)),
				Vector3(side * 0.205, -0.19, 0.045), Vector3(0, 0, side * 4), Vector3(1, 1, 0.75), "HairStrand")
		Props.part(head, Props.sphere_mesh(0.085, 8, 5), Props.mat(color.darkened(0.03)),
			Vector3(0, -0.33, 0.18), Vector3.ZERO, Vector3(1.5, 0.8, 0.6), "HairEnd")
	if hair_style == "braid":
		for i in 5:
			Props.part(head, Props.sphere_mesh(0.062 - i * 0.007, 8, 5), Props.mat(color.lightened(0.02 * i)),
				Vector3(0.19 + i * 0.006, -0.20 - i * 0.085, 0.10 - i * 0.02), Vector3(0, 0, i * 12),
				Vector3(0.9, 1.25, 0.9), "Braid%d" % i)
		Props.part(head, Props.box_mesh(Vector3(0.06, 0.035, 0.05)), Props.mat(trim),
			Vector3(0.20, -0.585, 0.0), Vector3.ZERO, Vector3.ONE, "BraidTie")
	if hair_style == "bun":
		Props.part(head, Props.sphere_mesh(0.105, 10, 6), Props.mat(color.darkened(0.02)),
			Vector3(0, 0.02, 0.235), Vector3.ZERO, Vector3(1, 1, 0.85), "Bun")
		Props.part(head, Props.cylinder_mesh(0.09, 0.095, 0.04, 10), Props.mat(trim),
			Vector3(0, 0.08, 0.225), Vector3(18, 0, 0), Vector3.ONE, "BunBand")
		Props.part(head, Props.capsule_mesh(0.16, 0.012, 6), Props.mat(color.lightened(0.03)),
			Vector3(0.02, 0.02, 0.30), Vector3(0, 0, 28), Vector3.ONE, "BunPin")

func _build_headwear() -> void:
	match headwear:
		"headband":
			var band := Props.part(head, Props.cylinder_mesh(0.247, 0.247, 0.045, 16), Props.mat(trim),
				Vector3(0, 0.088, 0.01), Vector3(0, 0, 0), Vector3(1, 1, 1.02), "Headwear")
			band.name = "Headwear"
			Props.part(head, Props.sphere_mesh(0.045, 7, 4), Props.mat(trim.darkened(0.08)),
				Vector3(0, 0.086, 0.255), Vector3.ZERO, Vector3.ONE, "BandKnot")
		"turban":
			var turban := Node3D.new()
			turban.name = "Headwear"
			turban.position = Vector3(0, 0.13, 0.01)
			head.add_child(turban)
			Props.part(turban, Props.cylinder_mesh(0.252, 0.258, 0.075, 16), Props.mat(veil),
				Vector3(0, 0.0, 0), Vector3(0, 6, 0), Vector3(1, 1, 1.02))
			Props.part(turban, Props.cylinder_mesh(0.225, 0.252, 0.07, 16), Props.mat(veil.lightened(0.06)),
				Vector3(0, 0.07, -0.005), Vector3(0, -8, 0), Vector3(1, 1, 1.02))
			Props.part(turban, Props.cylinder_mesh(0.256, 0.256, 0.028, 16), Props.mat(veil.darkened(0.12)),
				Vector3(0, 0.005, 0), Vector3(7, 0, 4), Vector3(1, 1, 1.02), "TurbanWrap")
			Props.part(turban, Props.cylinder_mesh(0.238, 0.246, 0.026, 16), Props.mat(veil.darkened(0.08)),
				Vector3(0, 0.072, -0.004), Vector3(-5, 0, -6), Vector3(1, 1, 1.02), "TurbanWrap")
			Props.part(turban, Props.sphere_mesh(0.19, 12, 6), Props.mat(veil.darkened(0.04)),
				Vector3(0, 0.10, 0.01), Vector3.ZERO, Vector3(1.05, 0.55, 1.0))
			Props.part(turban, Props.sphere_mesh(0.055, 8, 5), Props.mat(trim),
				Vector3(0.16, 0.03, -0.16), Vector3.ZERO, Vector3(1.2, 0.8, 0.6), "TurbanJewel")
			Props.part(turban, Props.box_mesh(Vector3(0.09, 0.26, 0.03)), Props.mat(veil.darkened(0.08)),
				Vector3(0.20, -0.12, 0.12), Vector3(0, 0, -8), Vector3.ONE, "TurbanTail")
		"veil":
			var cloth := Node3D.new()
			cloth.name = "Headwear"
			head.add_child(cloth)
			Props.part(cloth, Props.sphere_mesh(0.252, 14, 8), Props.mat(veil),
				Vector3(0, 0.10, 0.075), Vector3.ZERO, Vector3(1.03, 0.72, 0.9), "Veil")
			for side in [-1, 1]:
				Props.part(cloth, Props.box_mesh(Vector3(0.085, 0.40, 0.16)), Props.mat(veil),
					Vector3(side * 0.232, -0.16, 0.04), Vector3(0, 0, side * 4), Vector3.ONE, "VeilSide")
			Props.part(cloth, Props.box_mesh(Vector3(0.34, 0.36, 0.07)), Props.mat(veil.darkened(0.04)),
				Vector3(0, -0.13, 0.21), Vector3(4, 0, 0), Vector3.ONE, "VeilBack")
			Props.part(cloth, Props.cylinder_mesh(0.252, 0.252, 0.04, 16), Props.mat(trim),
				Vector3(0, 0.13, 0.01), Vector3.ZERO, Vector3(1.0, 1, 1.0), "VeilTrim")
			Props.part(cloth, Props.sphere_mesh(0.028, 6, 4), Props.mat(trim),
				Vector3(0, 0.13, -0.258), Vector3.ZERO, Vector3(1.4, 0.8, 0.5), "VeilJewel")
		"hood":
			Props.part(head, Props.sphere_mesh(0.255, 12, 8), Props.mat(veil),
				Vector3(0, 0.04, 0.06), Vector3.ZERO, Vector3(1.04, 1.0, 1.05), "Headwear")
			Props.part(head, Props.box_mesh(Vector3(0.40, 0.38, 0.09)), Props.mat(veil.darkened(0.05)),
				Vector3(0, -0.15, 0.16), Vector3(5, 0, 0), Vector3.ONE, "HoodBack")

func add_hat(color := Color("#b8644a")) -> void:
	if hat and is_instance_valid(hat):
		return
	if head == null:
		veil = color
		headwear = "turban"
		return
	hat = Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0, 0.17, 0)
	head.add_child(hat)
	Props.part(hat, Props.cylinder_mesh(0.34, 0.36, 0.05, 12), Props.mat(color), Vector3.ZERO)
	Props.part(hat, Props.cylinder_mesh(0.18, 0.24, 0.18, 12), Props.mat(color.darkened(0.06)), Vector3(0, 0.1, 0))

func add_beard(color := Color("#8a8a8a")) -> void:
	if head == null:
		return
	Props.part(head, Props.sphere_mesh(0.175, 10, 6), Props.mat(color), Vector3(0, -0.175, -0.06),
		Vector3.ZERO, Vector3(1.0, 1.05, 0.72), "Beard")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.045, 7, 4), Props.mat(color.darkened(0.03)),
			Vector3(side * 0.045, -0.072, -0.215), Vector3(0, 0, side * 12), Vector3(1.3, 0.5, 0.5), "Moustache")
	Props.part(head, Props.sphere_mesh(0.06, 7, 4), Props.mat(color.darkened(0.05)),
		Vector3(0, -0.30, -0.05), Vector3.ZERO, Vector3(1.3, 0.8, 0.8), "BeardTip")

func set_locomotion(new_speed: float, grounded: bool, vertical := 0.0) -> void:
	speed = new_speed
	on_floor = grounded
	vertical_speed = vertical

func play_interact() -> void:
	interact_time = 0.7

func play_cheer(duration := 1.4) -> void:
	cheer_time = duration

func _process(delta: float) -> void:
	if not built:
		return
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
	var hip_bob := absf(sin(phase)) * 0.032 * walk_blend + sin(idle_t) * 0.005
	var leg_swing := sway * 0.72
	var arm_swing := -sway * 0.58

	if not on_floor:
		leg_swing = 0.35 if vertical_speed > 0.0 else 0.15
		arm_swing = -0.9
		hip_bob = 0.05

	if cheer_time > 0.0:
		arm_swing = -2.4
		hip_bob += absf(sin(_time * 9.0)) * 0.06

	if interact_time > 0.0 and elbow_r:
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.35, minf(1.0, delta * 14.0))
		arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_swing, minf(1.0, delta * 10.0))
		elbow_r.rotation.x = lerpf(elbow_r.rotation.x, -0.55, minf(1.0, delta * 12.0))
	else:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_swing, minf(1.0, delta * 10.0))
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -arm_swing, minf(1.0, delta * 10.0))
		if elbow_l:
			elbow_l.rotation.x = lerpf(elbow_l.rotation.x, 0.18 + absf(arm_swing) * 0.25, minf(1.0, delta * 8.0))
		if elbow_r:
			elbow_r.rotation.x = lerpf(elbow_r.rotation.x, 0.18 + absf(arm_swing) * 0.25, minf(1.0, delta * 8.0))

	arm_l.rotation.z = lerpf(arm_l.rotation.z, 0.08 + sin(idle_t) * 0.02, minf(1.0, delta * 6.0))
	arm_r.rotation.z = lerpf(arm_r.rotation.z, -0.08 - sin(idle_t) * 0.02, minf(1.0, delta * 6.0))

	leg_l.rotation.x = lerpf(leg_l.rotation.x, leg_swing, minf(1.0, delta * 12.0))
	leg_r.rotation.x = lerpf(leg_r.rotation.x, -leg_swing, minf(1.0, delta * 12.0))
	if knee_l:
		knee_l.rotation.x = lerpf(knee_l.rotation.x, maxf(0.0, -leg_swing) * 1.15 + 0.04, minf(1.0, delta * 12.0))
		knee_r.rotation.x = lerpf(knee_r.rotation.x, maxf(0.0, leg_swing) * 1.15 + 0.04, minf(1.0, delta * 12.0))
	if ankle_l:
		ankle_l.rotation.x = lerpf(ankle_l.rotation.x, -maxf(0.0, -leg_swing) * 0.55, minf(1.0, delta * 10.0))
		ankle_r.rotation.x = lerpf(ankle_r.rotation.x, -maxf(0.0, leg_swing) * 0.55, minf(1.0, delta * 10.0))

	hips.position.y = lerpf(hips.position.y, HIP_Y + hip_bob, minf(1.0, delta * 10.0))
	hips.rotation.x = lerpf(hips.rotation.x, -0.06 * walk_blend, minf(1.0, delta * 8.0))
	if skirt:
		skirt.rotation.x = lerpf(skirt.rotation.x, 0.05 * walk_blend, minf(1.0, delta * 6.0))
		skirt.rotation.z = lerpf(skirt.rotation.z, sin(phase) * 0.02 * walk_blend, minf(1.0, delta * 6.0))
	if head:
		head.rotation.y = sin(idle_t * 0.5) * 0.06
		head.rotation.x = sin(idle_t * 0.8) * 0.025
		torso.rotation.x = lerpf(torso.rotation.x, 0.015 * walk_blend + sin(_time * 1.3) * 0.004, minf(1.0, delta * 6.0))

	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.2, 4.8)
		_eye_scale = 0.15
	_eye_scale = lerpf(_eye_scale, 1.0, minf(1.0, delta * 18.0))
	if eye_l and eye_r:
		eye_l.scale.y = _eye_scale
		eye_r.scale.y = _eye_scale
