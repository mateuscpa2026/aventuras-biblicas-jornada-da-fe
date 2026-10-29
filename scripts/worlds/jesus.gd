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
		[Vector3(0, 0, 20), 1.0],
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

	var flower_colors := [Color("#e8846b"), Color("#f2b544"), Color("#d98fb8")]
	for i in 12:
		add_prop(Props.flower_patch(flower_colors[i % flower_colors.size()], 1.0),
			Vector3(randf_range(-22, 22), 0, randf_range(0, 19)))

	for i in 12:
		add_prop(Props.grass_tuft(randf_range(0.8, 1.2)), Vector3(randf_range(-24, 24), 0, randf_range(-6, 20)))

	for position in [Vector3(-21, 0, -5), Vector3(23, 0, 4), Vector3(-23, 0, 12), Vector3(7, 0, 19)]:
		add_prop(Props.rock(randf_range(0.8, 1.2), Color("#9a978d")), position, Vector3(0, randf_range(0, 360), 0))

	for i in 9:
		Props.part(self, Props.box_mesh(Vector3(1.5, 0.07, 0.9)), Props.mat(Color("#e0d3ae"), 1.0),
			Vector3(randf_range(-0.5, 0.5), 0.035, 13.0 - i * 1.6), Vector3(0, randf_range(-7, 7), 0))

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

	for i in 4:
		var position := Vector3(-2, 0, 18) + Vector3(0, 0, -i * 1.2)
		Props.part(self, Props.box_mesh(Vector3(2.2, 0.07, 1.0)), Props.mat(Color("#d9cba6"), 1.0),
			position, Vector3(0, 0, 0))

func _build_mount() -> void:
	# Plataforma do monte e rampa caminhável.
	var grass := Props.mat(Color("#7fae6a"), 1.0)
	Props.part(self, Props.cylinder_mesh(7.0, 7.4, 2.0, 24), grass, Vector3(0, 1.0, -16))
	Props.part(self, Props.cylinder_mesh(7.02, 7.02, 0.1, 24), Props.mat(Color("#8fbd7d"), 1.0), Vector3(0, 2.02, -16))
	Props.collider_cylinder(self, 7.0, 2.0, Vector3(0, 1.0, -16))

	Props.part(self, Props.box_mesh(Vector3(5.0, 0.35, 10.8)), Props.mat(Color("#a8946b"), 1.0),
		Vector3(0, 1.0, -5.2), Vector3(10.9, 0, 0))
	Props.collider_box(self, Vector3(5.0, 0.35, 10.8), Vector3(0, 1.0, -5.2), Vector3(10.9, 0, 0))

	for side in [-1, 1]:
		Props.part(self, Props.box_mesh(Vector3(0.12, 0.7, 10.6)), Props.mat(Color("#7c4f32")),
			Vector3(side * 2.55, 1.35, -5.2), Vector3(10.9, 0, 0))
	for step in 5:
		var t := float(step) / 4.0
		var z := lerpf(0.0, -10.2, t)
		var y := lerpf(0.1, 2.0, t)
		Props.part(self, Props.sphere_mesh(0.28, 7, 4), Props.mat(Color("#9a978d")),
			Vector3(2.7, y + 0.15, z), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))

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
