extends WorldBase
## Campos de Davi: reunir ovelhas no curral, conversar com Davi e treinar a
## pontaria com a funda em argolas grandes (sem violência).

var _pen: Node3D

func _get_spawn_position() -> Vector3:
	return Vector3(0, 0.2, 15)

func _build_world() -> void:
	_build_environment()
	_build_scenery()
	_build_pen()
	_build_characters()
	_build_activities()
	EnvBuilder.inner_bounds(self, 54.0)

func _build_environment() -> void:
	var env := EnvBuilder.setup(self, {
		"sky_top": Color("#7fb9d9"),
		"sky_horizon": Color("#ffe6b3"),
		"ground_bottom": Color("#b9a85e"),
		"ground_horizon": Color("#f6e8c6"),
		"ambient": Color("#f4e9c8"),
		"ambient_energy": 0.75,
		"sun_rotation": Vector3(-55, -20, 0),
		"sun_color": Color("#fff0c0"),
		"sun_energy": 1.3,
		"fog_density": 0.0018,
		"fog_color": Color("#f2e4c0"),
	})
	set_environment(env["environment"] as WorldEnvironment, env["sun"] as DirectionalLight3D)
	EnvBuilder.ground(self, Color("#a3944c"), 140.0)
	EnvBuilder.hills(self, Color("#b09a55"), 16, 44.0, 72.0)
	EnvBuilder.clouds(self, 8, 21.0)

func _build_scenery() -> void:
	var tree_spots := [
		[Vector3(17, 0, 7), 1.1], [Vector3(-18, 0, -1), 1.0], [Vector3(20, 0, -8), 0.9],
		[Vector3(-21, 0, 12), 1.15], [Vector3(9, 0, 13), 0.95], [Vector3(-9, 0, 14), 0.9],
	]
	for spot in tree_spots:
		add_prop(Props.tree(float(spot[1]), Color("#7f9e52"), Color("#6b4a2e")),
			spot[0], Vector3(0, randf_range(0, 360), 0))

	var palm_spots := [Vector3(22, 0, 4), Vector3(-23, 0, -8)]
	for position in palm_spots:
		add_prop(Props.palm(0.85), position)

	for position in [Vector3(-3, 0, 8), Vector3(13, 0, 0), Vector3(-13, 0, 9), Vector3(5, 0, 11)]:
		add_prop(Props.bush(randf_range(0.6, 0.9), Color("#8b8c4c")), position)

	for i in 18:
		add_prop(Props.grass_tuft(randf_range(0.9, 1.4), Color("#9c9450")),
			Vector3(randf_range(-26, 26), 0, randf_range(-18, 20)))

	for position in [
		Vector3(-20, 0, 3), Vector3(16, 0, -13), Vector3(-7, 0, -12), Vector3(21, 0, 14),
		Vector3(-16, 0, -14), Vector3(3, 0, -18),
	]:
		add_prop(Props.rock(randf_range(0.9, 1.4), Color("#a09582")), position, Vector3(0, randf_range(0, 360), 0))

	add_prop(Props.tent(), Vector3(-19, 0, 8))
	add_prop(Props.tent(Color("#d9c08a")), Vector3(19, 0, 11), Vector3(0, 25, 0))
	add_prop(Props.hay(), Vector3(3, 0, 6))
	add_prop(Props.hay(), Vector3(-4, 0, 6), Vector3(0, 40, 0))
	add_prop(Props.banner(Color("#d9a441")), Vector3(2.2, 0, -6))
	add_prop(Props.banner(Color("#c98a4b")), Vector3(-2.2, 0, -6))
	add_prop(Props.signpost("Curral", Color("#d9a441")), Vector3(-8, 0, 6), Vector3(0, 95, 0))
	add_prop(Props.signpost("Treino com a funda", Color("#c98a4b")), Vector3(3, 0, -4), Vector3(0, -10, 0))

func _build_pen() -> void:
	add_prop(Props.fence(8.0), Vector3(-16, 0, -2), Vector3(0, 90, 0))
	add_prop(Props.fence(8.0), Vector3(-8, 0, -2), Vector3(0, 90, 0))
	add_prop(Props.fence(8.0), Vector3(-12, 0, -6))
	_pen = Props.marker(self, Vector3(-12, 0.1, -3), "Pen")

func _build_characters() -> void:
	add_npc("davi", "Davi", Vector3(0, 0, -1), {
		"skin": Color("#d9a47c"), "hair": Color("#a85f34"), "tunic": Color("#b98a62"),
		"trim": Color("#d9a441"), "pants": Color("#7a5f42"), "shoe": Color("#4d3a2a"),
		"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband",
		"cloak": Color("#8a5a3a"), "sash": Color("#d9a441"),
	}, Vector3(0, 0, 15))
	add_npc("eli", "Eli", Vector3(-6.5, 0, 4), {
		"skin": Color("#b98a63"), "hair": Color("#5a4632"), "beard": Color("#5a4632"),
		"tunic": Color("#8a9e6a"), "trim": Color("#c9a06a"), "pants": Color("#6b5a4a"),
		"shoe": Color("#4d3a2a"), "scale": 1.03,
		"gender": "male", "outfit": "robe", "hair_style": "short", "headwear": "turban",
		"veil": Color("#c9b08a"), "sash": Color("#c9a06a"),
	}, Vector3(0, 0, 15))

	var sheep_spots := [Vector3(6, 0, 5), Vector3(-2, 0, 10), Vector3(12, 0, -2)]
	for position in sheep_spots:
		var sheep := add_animal("sheep", position)
		sheep.can_follow = true
		sheep.escort_target = _pen
		sheep.escort_event = "sheep_penned"
		sheep.escort_hint = "Leve a ovelha até o curral de madeira."
		sheep.move_speed = 1.2

	add_animal("bird", Vector3(-11, 0.2, 11))

func _build_activities() -> void:
	add_scroll("davi_pastor", Vector3(13, 1.0, 8), "david_pergaminhos")
	add_scroll("davi_golias", Vector3(-18, 1.0, -7), "david_pergaminhos")
	add_scroll("coragem_fe", Vector3(7, 1.0, -13), "david_pergaminhos")

	var stand := SlingshotStand.new()
	stand.position = Vector3(0, 0, -8)
	add_child(stand)

	var target_positions := [Vector3(-5, 2.7, -20), Vector3(0, 2.9, -22), Vector3(5, 2.7, -20)]
	for position in target_positions:
		var target := TargetRing.new()
		target.hit_radius = 1.15
		target.required_mission = "david_alvos"
		target.position = position
		add_child(target)

	add_quiz_station("david_final", Vector3(14, 0, -12), "Desafio extra: pedra da coragem")
	add_prop(Props.signpost("Alvos", Color("#f2c14e")), Vector3(0, 0, -15))
