extends WorldBase
## Vila de Jesus: levar pães, reencontrar a ovelha perdida, escolher perdoar e
## convidar os moradores para ouvir Jesus no monte.

var _mount_marker: Node3D

func _get_spawn_position() -> Vector3:
	return Vector3(0, 0.2, 16)

func _build_world() -> void:
	_build_environment()
	_build_scenery()
	_build_village()
	_build_mount()
	_build_characters()
	_build_activities()
	EnvBuilder.inner_bounds(self, 56.0)

func _build_environment() -> void:
	var env := EnvBuilder.setup(self, {
		"sky_top": Color("#7fb9db"),
		"sky_horizon": Color("#ffe9c8"),
		"ground_bottom": Color("#7fa878"),
		"ground_horizon": Color("#f2ecd8"),
		"ambient": Color("#f2e8d2"),
		"ambient_energy": 0.74,
		"sun_rotation": Vector3(-50, -32, 0),
		"sun_color": Color("#fff2cf"),
		"sun_energy": 1.22,
		"fog_density": 0.0014,
		"fog_color": Color("#f2e9d6"),
	})
	set_environment(env["environment"] as WorldEnvironment, env["sun"] as DirectionalLight3D)
	EnvBuilder.ground(self, Color("#8fbd7d"), 130.0)
	EnvBuilder.hills(self, Color("#93bb84"), 16, 42.0, 68.0)
	EnvBuilder.clouds(self, 9, 21.0)

func _build_scenery() -> void:
	var tree_spots := [
		[Vector3(-18, 0, 6), 1.1], [Vector3(18, 0, 8), 1.05], [Vector3(-20, 0, 17), 1.0],
		[Vector3(21, 0, 17), 1.15], [Vector3(12, 0, -6), 0.9], [Vector3(-12, 0, -6), 0.95],
		[Vector3(11, 0, 24), 1.0],
	]
	for spot in tree_spots:
		add_prop(Props.tree(float(spot[1]), Color("#6a9c55"), Color("#6b4a2e")),
			spot[0], Vector3(0, randf_range(0, 360), 0))

	var palm_spots := [Vector3(-16, 0, -1), Vector3(16, 0, 2)]
	for position in palm_spots:
		add_prop(Props.palm(0.9), position)

	for position in [
		Vector3(-8, 0, 14), Vector3(8, 0, 15), Vector3(-11, 0, -3), Vector3(11, 0, -2),
		Vector3(-3, 0, 11), Vector3(4, 0, 12),
	]:
		add_prop(Props.bush(randf_range(0.7, 1.0), Color("#5d8f52")), position)

	EnvBuilder.forest(self, 32, 33.0, 45.0, Color("#6a9c55"), "mixed")
	EnvBuilder.ground_cover(self, Color("#79ab63"), 520, 27.0)
	EnvBuilder.ground_cover(self, Color("#79ab63"), 250, 14.0, 0.09, 0.2)
	EnvBuilder.path(self, [Vector3(0, 0, 11), Vector3(0, 0, 6), Vector3(0, 0, 2),
		Vector3(0, 0, -1)], 2.2, Color("#9b825a"), Color("#8fbd7d"))
	EnvBuilder.path(self, [Vector3(-8, 0, 12), Vector3(-2, 0, 10), Vector3(4, 0, 11)],
		1.2, Color("#9b825a"), Color("#8fbd7d"))

	var flower_colors := [Color("#e8846b"), Color("#f2b544"), Color("#d98fb8")]
	for i in 12:
		add_prop(Props.flower_patch(flower_colors[i % flower_colors.size()], 1.0),
			Vector3(randf_range(-22, 22), 0, randf_range(0, 19)))

	for i in 12:
		add_prop(Props.grass_tuft(randf_range(0.8, 1.2)), Vector3(randf_range(-24, 24), 0, randf_range(-6, 20)))

	for position in [Vector3(-21, 0, -5), Vector3(23, 0, 4), Vector3(-23, 0, 12), Vector3(7, 0, 19)]:
		add_prop(Props.rock(randf_range(0.8, 1.2), Color("#9a978d")), position, Vector3(0, randf_range(0, 360), 0))

	add_prop(Props.signpost("Vila de Jesus", Color("#7f9fd4")), Vector3(3.4, 0, 12), Vector3(0, -16, 0))

func _build_village() -> void:
	add_prop(Props.house(4.6, 2.7, 3.8), Vector3(-13, 0, 4), Vector3(0, 22, 0))
	add_prop(Props.house(4.2, 2.5, 3.6, Color("#e8cf9f"), Color("#a85f45")), Vector3(13, 0, 3), Vector3(0, -18, 0))
	add_prop(Props.house(4.4, 2.6, 3.7, Color("#efdcb6"), Color("#b8644a")), Vector3(-15, 0, 15), Vector3(0, 10, 0))
	add_prop(Props.house(4.0, 2.4, 3.4, Color("#ead2a6"), Color("#a85f45")), Vector3(15, 0, 16), Vector3(0, -12, 0))

	add_prop(Props.well(), Vector3(-5, 0, 11))
	add_prop(Props.stall(), Vector3(7, 0, 9), Vector3(0, 8, 0))
	add_prop(Props.stall(Color("#7f9fd4"), Color("#f2e3c6")), Vector3(-9, 0, 8), Vector3(0, -12, 0))
	add_prop(Props.crate(), Vector3(10, 0, 6))
	add_prop(Props.barrel(), Vector3(11, 0, 5))
	add_prop(Props.banner(Color("#7f9fd4")), Vector3(2.4, 0, 4))
	add_prop(Props.banner(Color("#f2c14e")), Vector3(-2.4, 0, 4))

func _build_mount() -> void:
	# Colina do sermão: barranco de grama e pedra em volta da mesa, e uma trilha
	# de terra irregular subindo. Antes era um cilindro com uma tábua lisa por
	# rampa — a silhueta reta era o que mais destoava do resto do mapa.
	Props.part(self, Props.cylinder_mesh(6.9, 6.9, 2.0, 22), Props.terrain_mat(Color("#6f9a5f")),
		Vector3(0, 1.0, -16))
	Props.part(self, Props.cylinder_mesh(7.02, 7.02, 0.1, 26), Props.terrain_mat(Color("#8fbd7d")),
		Vector3(0, 2.03, -16))
	Props.collider_cylinder(self, 7.0, 2.0, Vector3(0, 1.0, -16))

	var lump := Props.organic_mesh(1.0, 11, 7, 0.2, 2.2, 401)
	var bank: Array = []
	for i in 18:
		var angle := TAU * float(i) / 18.0 + 0.19
		var radius := 6.5 + randf_range(-0.2, 0.3)
		var height := randf_range(1.9, 2.4)
		bank.append([lump, Props.xf(
			Vector3(cos(angle) * radius, height * 0.5 - 0.08, -16.0 + sin(angle) * radius),
			Vector3(0, randf_range(0, 360), 0),
			Vector3(randf_range(1.2, 1.55), height * 0.5, randf_range(1.2, 1.55)))])
	Props.add_merged(self, bank, Props.terrain_mat(Color("#7ba368")), "MountBank")

	var foot: Array = []
	for i in 9:
		var angle := TAU * float(i) / 9.0 + 0.44
		if absf(cos(angle)) < 0.3:
			continue  # deixa livre a entrada da trilha na frente
		foot.append([lump, Props.xf(
			Vector3(cos(angle) * 7.7, 0.1, -16.0 + sin(angle) * 7.7),
			Vector3(0, randf_range(0, 360), 0),
			Vector3(randf_range(0.7, 1.15), randf_range(0.4, 0.7), randf_range(0.7, 1.15)))])
	Props.add_merged(self, foot, Props.terrain_mat(Color("#93b47c")), "MountFoot")

	# trilha de terra: lombadas irregulares sobre a rampa de colisão lisa
	Props.collider_box(self, Vector3(5.0, 0.35, 10.8), Vector3(0, 0.98, -5.2), Vector3(10.9, 0, 0))
	var trail: Array = []
	for i in 15:
		var t := float(i) / 14.0
		var z := lerpf(0.9, -10.3, t)
		var y := lerpf(0.02, 2.02, t)
		trail.append([lump, Props.xf(
			Vector3(randf_range(-0.18, 0.18), y - 0.1, z),
			Vector3(0, randf_range(-18, 18), 0),
			Vector3(randf_range(1.5, 1.9), 0.12, randf_range(0.75, 1.0)))])
	Props.add_merged(self, trail, Props.terrain_mat(Color("#ac9468")), "MountTrail")

	var edge: Array = []
	for side in [-1, 1]:
		for i in 7:
			var t := float(i) / 6.0
			edge.append([lump, Props.xf(
				Vector3(side * randf_range(2.55, 3.05), lerpf(0.06, 2.0, t) - 0.12,
					lerpf(0.8, -10.2, t) + randf_range(-0.3, 0.3)),
				Vector3(0, randf_range(0, 360), 0),
				Vector3(randf_range(0.5, 0.85), randf_range(0.3, 0.55), randf_range(0.5, 0.85)))])
	Props.add_merged(self, edge, Props.terrain_mat(Color("#7ba368")), "MountEdges")

	for i in 9:
		var angle := TAU * float(i) / 9.0 + 0.8
		add_prop(Props.grass_tuft(randf_range(0.9, 1.4), Color("#86ab66")),
			Vector3(cos(angle) * 6.4, 2.03, -16.0 + sin(angle) * 6.4))
	for i in 5:
		add_prop(Props.flower_patch([Color("#e8846b"), Color("#f2b544"), Color("#d98fb8")][i % 3], 0.9),
			Vector3(randf_range(-5.6, 5.6), 2.03, -16.0 + randf_range(-5.6, 5.6)))

	add_prop(Props.banner(Color("#7f9fd4")), Vector3(-3.2, 0, -1))
	add_prop(Props.banner(Color("#f2c14e")), Vector3(3.2, 0, -1))
	add_prop(Props.bush(0.9, Color("#5d8f52")), Vector3(-5.5, 2.0, -17))
	add_prop(Props.flower_patch(Color("#e8846b"), 1.0), Vector3(5.5, 2.0, -17))

	_mount_marker = Props.marker(self, Vector3(0, 2.05, -18), "MountMarker")

func _build_characters() -> void:
	add_npc("jesus", StoryCast.display_name("jesus"), Vector3(0, 2.0, -16.5),
		StoryCast.look("jesus"), Vector3(0, 0, 16))

	var maria := add_npc("maria", StoryCast.display_name("maria"), Vector3(4, 0, 7),
		StoryCast.look("maria"), Vector3(0, 0, 16))
	maria.delivery_item = "pao"
	maria.delivery_event = "bread_delivered"
	maria.delivery_mission = "jesus_paes"
	maria.delivery_label = "pão"
	maria.can_follow = true
	maria.follow_mission = "jesus_monte"
	maria.escort_target = _mount_marker
	maria.escort_event = "villager_arrived"
	maria.escort_hint = "Vamos subir ao monte juntos!"

	var samaritano := add_npc("samaritano", "Samuel", Vector3(-7, 0, 3), {
		"skin": Color("#c98d63"), "hair": Color("#3a2a1c"), "tunic": Color("#a8845f"),
		"trim": Color("#7f9fd4"), "pants": Color("#6b5a4a"), "shoe": Color("#4d3a2a"),
		"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband",
	}, Vector3(0, 0, 16))
	samaritano.can_follow = true
	samaritano.follow_mission = "jesus_monte"
	samaritano.escort_target = _mount_marker
	samaritano.escort_event = "villager_arrived"
	samaritano.escort_hint = "Samuel vai subir ao monte com você."

	var amigo := add_npc("amigo", "Mateus", Vector3(-4, 0, 6), {
		"skin": Color("#b98a63"), "hair": Color("#4a3020"), "tunic": Color("#b98a62"),
		"trim": Color("#d9b96a"), "pants": Color("#6b5a4a"), "shoe": Color("#4d3a2a"),
		"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "none",
		"cloak": Color("#8a6a4a"),
	}, Vector3(0, 0, 16))
	amigo.can_follow = true
	amigo.follow_mission = "jesus_monte"
	amigo.escort_target = _mount_marker
	amigo.escort_event = "villager_arrived"
	amigo.escort_hint = "Mateus vai com você para o monte."

	var pastor := add_npc("pastor", "Joel", Vector3(10, 0, -1), {
		"skin": Color("#c98d63"), "hair": Color("#3a2a1c"), "beard": Color("#3a2a1c"),
		"tunic": Color("#8a9e6a"), "trim": Color("#d9b96a"), "pants": Color("#7a5f42"),
		"shoe": Color("#4d3a2a"),
		"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband",
		"cloak": Color("#6f8a5a"),
	}, Vector3(14, 0, -6))

	var sheep := add_animal("sheep", Vector3(14, 0, -6))
	sheep.can_follow = true
	sheep.escort_target = pastor
	sheep.escort_event = "sheep_returned"
	sheep.escort_hint = "A ovelha vai seguir você até o pastor Joel."
	sheep.animal_name = "ovelha perdida"

	add_animal("bird", Vector3(-11, 0.2, 14))
	add_animal("donkey", Vector3(12, 0, 12))

func _build_activities() -> void:
	var bread_positions := [Vector3(7, 1.25, 9), Vector3(9, 1.25, 7), Vector3(5, 1.25, 11)]
	for position in bread_positions:
		var basket := add_simple_prop("", position, "Pegar pão", Props.bread_basket())
		basket.carry_item = "pao"
		basket.toast_text = "Pão quentinho na sua cesta!"
		basket.sound = "collect"

	add_scroll("bom_samaritano", Vector3(-14, 1.0, 10), "jesus_pergaminhos")
	add_scroll("ovelha_perdida", Vector3(16, 1.0, 3), "jesus_pergaminhos")
	add_scroll("filho_prodigo", Vector3(-3, 1.0, -7), "jesus_pergaminhos")

	add_quiz_station("jesus_final", Vector3(4.5, 2.02, -17.5), "Desafio extra: pedra do amor")
