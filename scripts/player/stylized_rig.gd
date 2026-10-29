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
	var covered := outfit == "tunic"
	Props.part(leg, Props.capsule_mesh(0.32, 0.085, 10),
		Props.fabric_mat(pants) if covered else Props.skin_mat(skin),
		Vector3(0, -0.16, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "Thigh")
	if not covered:
		Props.part(leg, Props.sphere_mesh(0.075, 9, 6), Props.skin_mat(skin),
			Vector3(0, -0.2, 0.012), Vector3.ZERO, Vector3(1.0, 1.25, 0.95), "ThighMuscle")
	var knee := _pivot(leg, Vector3(0, -0.32, 0), "Knee")
	Props.part(knee, Props.sphere_mesh(0.072, 9, 6), Props.fabric_mat(pants) if covered else Props.skin_mat(skin),
		Vector3.ZERO, Vector3.ZERO, Vector3(1, 1, 0.95), "Knee")
	Props.part(knee, Props.sphere_mesh(0.038, 7, 5), Props.skin_mat(skin.lightened(0.05)) if not covered else Props.fabric_mat(pants.lightened(0.05)),
		Vector3(0, 0.004, -0.058), Vector3.ZERO, Vector3(1.1, 1.0, 0.5), "Kneecap")
	Props.part(knee, Props.capsule_mesh(0.24, 0.062, 12), Props.skin_mat(skin),
		Vector3(0, -0.12, 0), Vector3.ZERO, Vector3(1, 1, 0.95), "Shin")
	# panturrilha atrás e crista da tíbia à frente
	Props.part(knee, Props.sphere_mesh(0.055, 8, 5), Props.skin_mat(skin),
		Vector3(0, -0.085, 0.03), Vector3.ZERO, Vector3(1.0, 1.7, 0.9), "Calf")
	Props.part(knee, Props.capsule_mesh(0.17, 0.013, 6), Props.skin_mat(skin.lightened(0.04)),
		Vector3(0, -0.12, -0.055), Vector3.ZERO, Vector3(1, 1, 0.6), "ShinBone")
	var ankle := _pivot(knee, Vector3(0, -0.24, 0), "Ankle")
	for side in [-1, 1]:
		Props.part(ankle, Props.sphere_mesh(0.022, 6, 4), Props.skin_mat(skin.lightened(0.03)),
			Vector3(side * 0.042, 0.018, 0.0), Vector3.ZERO, Vector3(0.9, 1.0, 0.8), "AnkleBone")
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
	Props.part(ankle, Props.sphere_mesh(0.072, 9, 5), Props.skin_mat(skin),
		Vector3(0, 0.012, -0.075), Vector3.ZERO, Vector3(0.85, 0.55, 1.55), "Foot")
	Props.part(ankle, Props.sphere_mesh(0.06, 8, 5), Props.skin_mat(skin),
		Vector3(0, 0.006, 0.035), Vector3.ZERO, Vector3(0.9, 0.65, 0.8), "Heel")
	Props.part(ankle, Props.sphere_mesh(0.05, 8, 5), Props.skin_mat(skin.darkened(0.04)),
		Vector3(0, -0.004, -0.06), Vector3.ZERO, Vector3(0.9, 0.4, 1.1), "Arch")
	Props.part(ankle, Props.box_mesh(Vector3(0.145, 0.022, 0.03)), Props.mat(shoe.darkened(0.06)),
		Vector3(0, 0.038, -0.135), Vector3(10, 0, 0), Vector3.ONE, "SandalStrap")
	Props.part(ankle, Props.box_mesh(Vector3(0.135, 0.018, 0.032)), Props.mat(shoe.darkened(0.02)),
		Vector3(0, 0.03, -0.06), Vector3(0, 34, 4), Vector3.ONE, "SandalCross")
	Props.part(ankle, Props.box_mesh(Vector3(0.15, 0.028, 0.06)), Props.mat(shoe),
		Vector3(0, 0.05, 0.0), Vector3.ZERO, Vector3.ONE, "AnkleStrap")
	Props.part(ankle, Props.sphere_mesh(0.012, 6, 4), Props.mat(trim.darkened(0.1)),
		Vector3(0.055, 0.05, -0.03), Vector3.ZERO, Vector3(1.4, 0.9, 0.7), "SandalBuckle")
	for i in 5:
		var toe_size := 0.019 - absf(i - 1.4) * 0.0022
		var toe_x := -0.052 + i * 0.026
		Props.part(ankle, Props.sphere_mesh(toe_size, 6, 4), Props.skin_mat(skin),
			Vector3(toe_x, 0.012 - i * 0.0008, -0.2 - absf(i - 1.5) * 0.004), Vector3.ZERO,
			Vector3(1, 0.75, 1.05), "Toe")
		Props.part(ankle, Props.sphere_mesh(toe_size * 0.52, 5, 3), Props.skin_mat(skin.lightened(0.14)),
			Vector3(toe_x, 0.022 - i * 0.0008, -0.212 - absf(i - 1.5) * 0.004), Vector3.ZERO,
			Vector3(0.9, 0.4, 0.9), "ToeNail")

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
	Props.part(torso, Props.cylinder_mesh(0.082, 0.095, 0.11, 12), Props.skin_mat(skin),
		Vector3(0, 0.53, 0), Vector3.ZERO, Vector3(1, 1, 0.92), "Neck")
	Props.part(torso, Props.cylinder_mesh(0.092, 0.105, 0.03, 12), Props.skin_mat(skin.darkened(0.02)),
		Vector3(0, 0.505, 0), Vector3.ZERO, Vector3(1, 1, 0.92), "NeckBase")
	Props.part(torso, Props.cylinder_mesh(0.093, 0.093, 0.028, 12), Props.mat(trim),
		Vector3(0, 0.512, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "Collar")
	Props.part(torso, Props.cylinder_mesh(0.088, 0.1, 0.035, 12), Props.fabric_mat(tunic.darkened(0.14)),
		Vector3(0, 0.49, 0), Vector3.ZERO, Vector3(1, 1, 0.9), "Neckline")
	# costura central, ombros e laterais
	Props.part(torso, Props.box_mesh(Vector3(0.014, 0.30, 0.02)), Props.fabric_mat(tunic.darkened(0.12)),
		Vector3(0, 0.265, -0.147), Vector3.ZERO, Vector3.ONE, "FrontSeam")
	for side in [-1, 1]:
		Props.part(torso, Props.box_mesh(Vector3(0.012, 0.26, 0.02)), Props.fabric_mat(tunic.darkened(0.1)),
			Vector3(side * 0.145, 0.27, 0), Vector3(0, side * 90, 0), Vector3.ONE, "SideSeam")
		Props.part(torso, Props.capsule_mesh(0.12, 0.008, 6), Props.fabric_mat(tunic.lightened(0.06)),
			Vector3(side * 0.115, 0.445, -0.07), Vector3(0, 0, side * 62), Vector3(1, 1, 0.5), "ShoulderSeam")
	# dobras suaves do tecido no peito
	for i in 2:
		Props.part(torso, Props.capsule_mesh(0.14, 0.007, 6), Props.fabric_mat(tunic.darkened(0.07)),
			Vector3((i - 0.5) * 0.07, 0.36, -0.148), Vector3(0, 0, (i - 0.5) * 18), Vector3(1, 1, 0.5), "ChestFold")
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
	Props.part(arm, Props.capsule_mesh(0.24, 0.062, 9), Props.fabric_mat(tunic) if long_sleeve else Props.skin_mat(skin),
		Vector3(0, -0.12, 0), Vector3.ZERO, Vector3(0.9, 1, 0.9), "UpperArm")
	var elbow := _pivot(arm, Vector3(0, -0.215, 0), "Elbow")
	Props.part(elbow, Props.capsule_mesh(0.20, 0.055, 9), Props.fabric_mat(tunic) if long_sleeve else Props.skin_mat(skin),
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
	# punho, palma, dorso e dedos articulados
	Props.part(elbow, Props.sphere_mesh(0.043, 8, 5), Props.skin_mat(skin.darkened(0.02)),
		Vector3(0, -0.202, 0), Vector3.ZERO, Vector3(1.0, 0.7, 0.9), "Wrist")
	Props.part(elbow, Props.sphere_mesh(0.058, 10, 6), Props.skin_mat(skin),
		Vector3(0, -0.238, -0.002), Vector3.ZERO, Vector3(1.05, 0.9, 0.74), "Palm")
	Props.part(elbow, Props.sphere_mesh(0.05, 9, 5), Props.skin_mat(skin.lightened(0.02)),
		Vector3(0, -0.24, -0.028), Vector3.ZERO, Vector3(1.0, 0.85, 0.4), "BackOfHand")
	for i in 4:
		var finger_x := -0.039 + i * 0.026
		var taper := 1.0 - absf(i - 1.2) * 0.1
		Props.part(elbow, Props.capsule_mesh(0.046 * taper, 0.0125 * taper, 6), Props.skin_mat(skin),
			Vector3(finger_x, -0.268, -0.012), Vector3(6, 0, -3 + i * 2), Vector3.ONE, "Knuckle")
		Props.part(elbow, Props.capsule_mesh(0.04 * taper, 0.0105 * taper, 6), Props.skin_mat(skin),
			Vector3(finger_x + 0.001, -0.296, -0.02), Vector3(10, 0, -3 + i * 2), Vector3.ONE, "Finger")
		Props.part(elbow, Props.sphere_mesh(0.0085 * taper, 5, 3), Props.skin_mat(skin.lightened(0.12)),
			Vector3(finger_x + 0.002, -0.311, -0.023), Vector3.ZERO, Vector3(0.9, 0.45, 1.0), "FingerNail")
	if is_left:
		Props.part(elbow, Props.capsule_mesh(0.042, 0.015, 6), Props.skin_mat(skin),
			Vector3(-0.052, -0.238, -0.018), Vector3(12, 0, 40), Vector3.ONE, "Thumb")
		Props.part(elbow, Props.capsule_mesh(0.034, 0.013, 6), Props.skin_mat(skin),
			Vector3(-0.066, -0.264, -0.03), Vector3(10, 0, 26), Vector3.ONE, "ThumbTip")
	else:
		Props.part(elbow, Props.capsule_mesh(0.042, 0.015, 6), Props.skin_mat(skin),
			Vector3(0.052, -0.238, -0.018), Vector3(12, 0, -40), Vector3.ONE, "Thumb")
		Props.part(elbow, Props.capsule_mesh(0.034, 0.013, 6), Props.skin_mat(skin),
			Vector3(0.066, -0.264, -0.03), Vector3(10, 0, -26), Vector3.ONE, "ThumbTip")
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
	head.scale = Vector3(0.93, 0.94, 0.93)
	hips.add_child(head)

	var skin_material := Props.skin_mat(skin)
	Props.part(head, Props.sphere_mesh(0.235, 20, 12), skin_material, Vector3.ZERO, Vector3.ZERO, Vector3(1, 1.01, 0.97), "Skull")
	# orelha com concha e lóbulo, encostada no crânio
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.05, 9, 6), skin_material,
			Vector3(side * 0.218, -0.004, 0.012), Vector3(0, side * 16, side * -6), Vector3(0.4, 1.0, 0.66), "Ear")
		Props.part(head, Props.sphere_mesh(0.036, 8, 5), Props.skin_mat(skin.darkened(0.09)),
			Vector3(side * 0.229, -0.002, 0.005), Vector3(0, side * 16, 0), Vector3(0.22, 0.8, 0.5), "EarInner")
		Props.part(head, Props.sphere_mesh(0.021, 7, 5), Props.skin_mat(skin.lightened(0.02)),
			Vector3(side * 0.214, -0.045, 0.012), Vector3.ZERO, Vector3(0.4, 0.5, 0.58), "EarLobe")
	Props.part(head, Props.sphere_mesh(0.048, 10, 6), skin_material,
		Vector3(0, -0.152, -0.102), Vector3.ZERO, Vector3(1.22, 0.78, 0.92), "Chin")
	Props.part(head, Props.sphere_mesh(0.045, 8, 5), skin_material,
		Vector3(0, 0.108, -0.158), Vector3.ZERO, Vector3(1.45, 0.62, 0.42), "Forehead")
	_build_face()
	_build_hair()
	_build_headwear()
	_optimize_head_shadows()

## Só o volume da cabeça entra no mapa de sombras; detalhes do rosto ficariam
## invisíveis a olho nu e custam dezenas de draw calls por personagem.
func _optimize_head_shadows() -> void:
	var keep := ["Skull", "Hair", "HairBackMass", "HairBack", "HairNape", "Headwear",
		"Veil", "TurbanWrap", "Beard"]
	for node in head.find_children("*", "MeshInstance3D", true, false):
		var piece := node as MeshInstance3D
		if str(piece.name) in keep:
			continue
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_face() -> void:
	var lip_color := skin.darkened(0.16).lerp(Color("#a55f56"), 0.34)
	if gender == "female":
		lip_color = lip_color.lerp(Color("#c07a70"), 0.2)
	# olhos: globo na superfície do crânio, esclera visível, íris e pálpebras
	for side in [-1, 1]:
		var socket := Node3D.new()
		socket.name = "EyeSocketL" if side < 0 else "EyeSocketR"
		socket.position = Vector3(side * 0.077, 0.02, -0.213)
		socket.rotation_degrees = Vector3(0, -side * 12, 0)
		head.add_child(socket)
		var eye := Node3D.new()
		eye.name = "EyeL" if side < 0 else "EyeR"
		socket.add_child(eye)
		Props.part(eye, Props.sphere_mesh(0.042, 20, 10), Props.unshaded(Color("#e3dbca")),
			Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.9, 0.35), "Sclera")
		Props.part(eye, Props.sphere_mesh(0.0312, 22, 10), Props.unshaded(iris.darkened(0.36)),
			Vector3(0, -0.001, -0.015), Vector3.ZERO, Vector3(1, 1, 0.012), "LimbalRing")
		Props.part(eye, Props.sphere_mesh(0.0295, 22, 10), Props.unshaded(iris),
			Vector3(0, -0.001, -0.0155), Vector3.ZERO, Vector3(1, 1, 0.012), "Iris")
		Props.part(eye, Props.sphere_mesh(0.0148, 20, 9), Props.unshaded(Color("#140f0b")),
			Vector3(0, -0.002, -0.0161), Vector3.ZERO, Vector3(1, 1, 0.012), "Pupil")
		Props.part(eye, Props.sphere_mesh(0.0058, 8, 5), Props.unshaded(Color("#ffffff")),
			Vector3(0.0085, 0.0095, -0.0164), Vector3.ZERO, Vector3(1, 1, 0.17), "Glint")
		# pálpebras ficam na órbita (não piscam junto com o globo)
		Props.part(socket, Props.sphere_mesh(0.046, 12, 6), Props.skin_mat(skin),
			Vector3(0, 0.037, 0.0), Vector3(-12, 0, 0), Vector3(1.02, 0.28, 0.4), "Eyelid")
		Props.part(socket, Props.sphere_mesh(0.041, 10, 5), Props.skin_mat(skin.darkened(0.03)),
			Vector3(0, -0.034, 0.0), Vector3(8, 0, 0), Vector3(1.0, 0.22, 0.4), "LowerEyelid")
		if side < 0:
			eye_l = eye
		else:
			eye_r = eye
	# sobrancelhas: uma mecha fina por lado, logo acima da pálpebra
	for side in [-1, 1]:
		Props.part(head, Props.capsule_mesh(0.042, 0.0048, 7), Props.hair_mat(hair.lightened(0.12)),
			Vector3(side * 0.077, 0.069, -0.212), Vector3(0, side * -14, side * -87), Vector3(1, 1, 0.7), "Brow")
	# cílios (feminino) discretos, apoiados na pálpebra
	if gender == "female":
		for side in [-1, 1]:
			Props.part(head, Props.box_mesh(Vector3(0.058, 0.0035, 0.006)), Props.unshaded(Color("#3a241a")),
				Vector3(side * 0.076, 0.0435, -0.2325), Vector3(0, side * 10, side * -2), Vector3.ONE, "LashLine")
			for i in 2:
				Props.part(head, Props.box_mesh(Vector3(0.015, 0.0035, 0.006)), Props.unshaded(Color("#3a241a")),
					Vector3(side * (0.104 + i * 0.011), 0.0455 + i * 0.003, -0.2205),
					Vector3(0, side * 22, -side * (22 + i * 8)), Vector3.ONE, "Lash")
	# nariz: dorso suave, ponta arredondada, asas e narinas na base
	Props.part(head, Props.sphere_mesh(0.024, 9, 6), Props.skin_mat(skin.darkened(0.02)),
		Vector3(0, 0.01, -0.228), Vector3(8, 0, 0), Vector3(0.62, 1.55, 0.5), "NoseBridge")
	Props.part(head, Props.sphere_mesh(0.029, 9, 6), Props.skin_mat(skin),
		Vector3(0, -0.028, -0.238), Vector3.ZERO, Vector3(0.74, 1.0, 0.58), "NoseDorsum")
	Props.part(head, Props.sphere_mesh(0.031, 10, 6), Props.skin_mat(skin.lightened(0.02)),
		Vector3(0, -0.05, -0.244), Vector3.ZERO, Vector3(1.05, 0.76, 0.66), "NoseTip")
	for side in [-1, 1]:
		Props.part(head, Props.sphere_mesh(0.016, 7, 5), Props.skin_mat(skin.darkened(0.01)),
			Vector3(side * 0.029, -0.052, -0.234), Vector3(0, side * 18, 0), Vector3(0.95, 0.8, 0.72), "NoseWing")
		Props.part(head, Props.sphere_mesh(0.0078, 6, 4), Props.mat(Color("#4a2a20"), 0.9),
			Vector3(side * 0.015, -0.0625, -0.258), Vector3(-24, side * 12, 0), Vector3(1.4, 0.5, 0.42), "Nostril")
	# filtro e boca com lábios discretos, abaixo do nariz
	Props.part(head, Props.box_mesh(Vector3(0.012, 0.018, 0.008)), Props.skin_mat(skin.darkened(0.03)),
		Vector3(0, -0.077, -0.221), Vector3.ZERO, Vector3.ONE, "Philtrum")
	Props.part(head, Props.sphere_mesh(0.026, 10, 6), Props.mat(lip_color, 0.85),
		Vector3(0, -0.0925, -0.22), Vector3.ZERO, Vector3(1.75, 0.3, 0.3), "UpperLip")
	Props.part(head, Props.sphere_mesh(0.02, 9, 5), Props.mat(lip_color.darkened(0.05), 0.85),
		Vector3(0, -0.1005, -0.219), Vector3.ZERO, Vector3(1.6, 0.3, 0.3), "LowerLip")
	Props.part(head, Props.box_mesh(Vector3(0.05, 0.004, 0.006)), Props.mat(Color("#5f332c"), 0.9),
		Vector3(0, -0.0965, -0.2295), Vector3.ZERO, Vector3.ONE, "MouthLine")
	if gender == "female":
		for side in [-1, 1]:
			Props.part(head, Props.sphere_mesh(0.024, 8, 4), Props.skin_mat(skin.lerp(Color("#d98f7d"), 0.32)),
				Vector3(side * 0.115, -0.052, -0.197), Vector3(0, side * 12, 0), Vector3(1.6, 0.62, 0.08), "Blush")
	# brincos discretos para quem usa joias
	if jewelry:
		for side in [-1, 1]:
			Props.part(head, Props.sphere_mesh(0.012, 6, 4), Props.mat(trim),
				Vector3(side * 0.238, -0.026, 0.012), Vector3.ZERO, Vector3(1, 1.8, 0.8), "Earring")

func _build_hair() -> void:
	var color := hair
	var hair_material := Props.hair_mat(color)
	if hair_style == "bald":
		for side in [-1, 1]:
			Props.part(head, Props.sphere_mesh(0.15, 8, 5), Props.hair_mat(color),
				Vector3(side * 0.13, -0.02, 0.1), Vector3.ZERO, Vector3(0.55, 0.7, 0.9), "HairSide")
		return
	Props.part(head, Props.sphere_mesh(0.242, 20, 11), hair_material,
		Vector3(0, 0.06, 0.058), Vector3.ZERO, Vector3(1.03, 0.92, 0.98), "Hair")
	# linha do cabelo junto ao crânio (fica sob a faixa/aba)
	for i in 7:
		var t := float(i) / 6.0
		var x := lerpf(-0.17, 0.17, t)
		var z := -0.203 + absf(x) * 0.4
		Props.part(head, Props.sphere_mesh(0.024, 8, 5), Props.hair_mat(color.darkened(0.01)),
			Vector3(x, 0.125 - absf(x) * 0.1, z), Vector3(0, 0, 0), Vector3(1.8, 0.16, 0.9), "Hairline")
	# costeletas e laterais
	for side in [-1, 1]:
		Props.part(head, Props.capsule_mesh(0.09, 0.018, 6), Props.hair_mat(color.darkened(0.03)),
			Vector3(side * 0.205, 0.02, -0.055), Vector3(6, 0, side * 5), Vector3(1, 1, 0.7), "Sideburn")
		Props.part(head, Props.sphere_mesh(0.05, 8, 5), Props.hair_mat(color.darkened(0.03)),
			Vector3(side * 0.2, 0.025, -0.03), Vector3.ZERO, Vector3(0.6, 1.1, 0.7), "HairSide")
	# cabelo curto: camadas sobrepostas dão volume à nuca e ao fundo da cabeça
	if hair_style == "short":
		Props.part(head, Props.sphere_mesh(0.205, 14, 8), Props.hair_mat(color.lightened(0.03)),
			Vector3(0, 0.02, 0.105), Vector3.ZERO, Vector3(1.0, 0.9, 0.95), "HairBackMass")
		# mechas finas na nuca: evitam o aspecto de capacete liso
		for i in 9:
			var t := float(i) / 8.0
			var yaw := lerpf(-1.45, 1.45, t)
			var spot := Vector3(sin(yaw) * 0.198, -0.05 + fmod(float(i) * 0.43, 1.0) * 0.135,
				0.105 + cos(yaw) * 0.198)
			Props.part(head, Props.capsule_mesh(0.2 + fmod(float(i) * 0.31, 1.0) * 0.07, 0.013, 6),
				Props.hair_mat(color.lightened(0.07 if i % 2 == 0 else -0.05)), spot,
				Vector3(-8, rad_to_deg(yaw), (t - 0.5) * 16.0), Vector3(1, 1, 0.55), "HairStrandBack")
		Props.part(head, Props.sphere_mesh(0.15, 12, 7), Props.hair_mat(color.darkened(0.02)),
			Vector3(0, -0.09, 0.12), Vector3.ZERO, Vector3(1.2, 0.66, 0.8), "HairNape")
	# franja em três mechas
	for i in 3:
		Props.part(head, Props.sphere_mesh(0.058, 9, 6), Props.hair_mat(color.darkened(0.03)),
			Vector3((i - 1) * 0.056, 0.16, -0.163 + absf(i - 1) * 0.012),
			Vector3(-12, (i - 1) * 18, 0), Vector3(1.3, 0.38, 0.5), "Fringe")
	if hair_style == "curly":
		# cachos em espiral por cima e nas laterais
		for i in 30:
			var angle := TAU * fmod(float(i) * 0.61803398875, 1.0)
			var elevation := float(i) / 29.0
			var y := lerpf(-0.09, 0.25, elevation)
			var radius := sqrt(maxf(0.02, 1.0 - pow(y / 0.27, 2.0))) * 0.252
			var x := cos(angle) * radius
			var z := sin(angle) * radius * 0.98 + 0.05
			if z < -0.11 and y < 0.13:
				continue
			Props.part(head, Props.sphere_mesh(0.055 + 0.012 * (1.0 - elevation), 8, 5),
				Props.hair_mat(color.lightened(0.03 if i % 2 == 0 else -0.03)),
				Vector3(x, y, z), Vector3(0, rad_to_deg(angle), 0), Vector3(1.15, 0.85, 1.0), "Curl")
		for i in 8:
			var yaw := TAU * float(i) / 8.0
			Props.part(head, Props.sphere_mesh(0.05, 7, 4), Props.hair_mat(color.lightened(0.05)),
				Vector3(cos(yaw) * 0.2, 0.02 + fmod(float(i) * 0.37, 1.0) * 0.14, sin(yaw) * 0.2 + 0.04),
				Vector3.ZERO, Vector3(1, 0.9, 1), "CurlTip")
	if hair_style == "long" or hair_style == "braid" or hair_style == "bun":
		Props.part(head, Props.box_mesh(Vector3(0.35, 0.36, 0.10)), Props.hair_mat(color.darkened(0.04)),
			Vector3(0, -0.17, 0.155), Vector3(5, 0, 0), Vector3.ONE, "HairBack")
		# camada externa de mechas longas sobre as costas
		for i in 5:
			var t := float(i) / 4.0
			Props.part(head, Props.capsule_mesh(0.4, 0.028, 7), Props.hair_mat(color.lightened(0.02 - t * 0.05)),
				Vector3(lerpf(-0.15, 0.15, t), -0.19, 0.19 + absf(t - 0.5) * 0.03),
				Vector3(4, 0, lerpf(-5, 5, t)), Vector3(1, 1, 0.8), "HairLock")
		for side in [-1, 1]:
			Props.part(head, Props.capsule_mesh(0.36, 0.045, 8), Props.hair_mat(color.lightened(0.02)),
				Vector3(side * 0.205, -0.19, 0.045), Vector3(0, 0, side * 4), Vector3(1, 1, 0.75), "HairStrand")
			Props.part(head, Props.capsule_mesh(0.22, 0.03, 7), Props.hair_mat(color.lightened(0.04)),
				Vector3(side * 0.215, -0.3, -0.02), Vector3(0, 0, side * 7), Vector3(1, 1, 0.7), "HairLock")
		Props.part(head, Props.sphere_mesh(0.085, 9, 6), Props.hair_mat(color.darkened(0.03)),
			Vector3(0, -0.33, 0.18), Vector3.ZERO, Vector3(1.5, 0.8, 0.6), "HairEnd")
	if hair_style == "braid":
		for i in 7:
			Props.part(head, Props.sphere_mesh(0.062 - i * 0.006, 8, 5), Props.hair_mat(color.lightened(0.02 * i)),
				Vector3(0.19 + i * 0.006, -0.20 - i * 0.085, 0.10 - i * 0.02), Vector3(0, 0, i * 12),
				Vector3(0.9, 1.25, 0.9), "Braid%d" % i)
		Props.part(head, Props.box_mesh(Vector3(0.06, 0.035, 0.05)), Props.mat(trim),
			Vector3(0.20, -0.77, -0.04), Vector3.ZERO, Vector3.ONE, "BraidTie")
	if hair_style == "bun":
		Props.part(head, Props.sphere_mesh(0.105, 10, 6), Props.hair_mat(color.darkened(0.02)),
			Vector3(0, 0.02, 0.235), Vector3.ZERO, Vector3(1, 1, 0.85), "Bun")
		Props.part(head, Props.cylinder_mesh(0.09, 0.095, 0.04, 10), Props.mat(trim),
			Vector3(0, 0.08, 0.225), Vector3(18, 0, 0), Vector3.ONE, "BunBand")
		Props.part(head, Props.capsule_mesh(0.16, 0.012, 6), Props.hair_mat(color.lightened(0.03)),
			Vector3(0.02, 0.02, 0.30), Vector3(0, 0, 28), Vector3.ONE, "BunPin")

func _build_headwear() -> void:
	match headwear:
		"headband":
			var band := Props.part(head, Props.cylinder_mesh(0.248, 0.248, 0.038, 16), Props.mat(trim),
				Vector3(0, 0.13, 0.01), Vector3(0, 0, 0), Vector3(1, 1, 1.02), "Headwear")
			band.name = "Headwear"
			for side in [-1, 1]:
				Props.part(head, Props.sphere_mesh(0.016, 6, 4), Props.mat(trim.darkened(0.12)),
					Vector3(side * 0.244, 0.128, -0.035), Vector3(0, side * 80, 0), Vector3(1, 1.6, 0.8), "BandBead")
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
