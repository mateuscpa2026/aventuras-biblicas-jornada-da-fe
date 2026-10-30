extends WorldBase
## Jardim do Éden: cuidar dos animais, regar mudinhas, achar pergaminhos e
## resolver o desafio da pedra da memória.

const LAKE_CENTER := Vector3(-11.0, 0.0, -13.0)
const LAKE_RADIUS := 4.6
const LAKE_DEPTH := 1.15
const LAKE_AVOID := Vector3(-11.0, -13.0, 6.4)

func _get_spawn_position() -> Vector3:
	return Vector3(0, 0.2, 14)

func _build_world() -> void:
	_build_environment()
	_build_scenery()
	_build_characters()
	_build_activities()
	EnvBuilder.inner_bounds(self, 54.0)

func _build_environment() -> void:
	var env := EnvBuilder.setup(self, {
		"sky_top": Color("#4a9fd4"),
		"sky_horizon": Color("#ffe2ad"),
		"ground_bottom": Color("#5f9f58"),
		"ground_horizon": Color("#f0e0b8"),
		"ambient": Color("#f6e8ce"),
		"ambient_energy": 0.72,
		"sun_rotation": Vector3(-48, -30, 0),
		"sun_color": Color("#fff1c8"),
		"sun_energy": 1.25,
		"fog_density": 0.0,
		"fog_color": Color("#f3ecd9"),
	})
	set_environment(env["environment"] as WorldEnvironment, env["sun"] as DirectionalLight3D)
	EnvBuilder.ground(self, Color("#6fae66"), 130.0)
	EnvBuilder.pond(self, LAKE_CENTER, LAKE_RADIUS, LAKE_DEPTH, Color("#6fae66"), 130.0)
	EnvBuilder.hills(self, Color("#79b871"), 16, 42.0, 68.0)
	EnvBuilder.clouds(self, 9, 20.0)

func _build_scenery() -> void:
	var tree_spots := [
		[Vector3(15, 0, 6), 1.15], [Vector3(18, 0, -6), 1.0], [Vector3(-17, 0, 9), 1.1],
		[Vector3(-19, 0, -6), 0.95], [Vector3(9, 0, 13), 1.0], [Vector3(-9, 0, 15), 0.9],
		[Vector3(20, 0, 12), 1.2], [Vector3(-20, 0, 16), 1.05],
	]
	for spot in tree_spots:
		add_prop(Props.tree(float(spot[1]), Color("#4f9a54")), spot[0], Vector3(0, randf_range(0, 360), 0))

	var pine_spots := [Vector3(22, 0, -2), Vector3(-23, 0, 2), Vector3(6, 0, -20)]
	for position in pine_spots:
		add_prop(Props.pine(1.1), position)

	var palm_spots := [Vector3(18, 0, 16), Vector3(-14, 0, 18), Vector3(12, 0, -15)]
	for position in palm_spots:
		add_prop(Props.palm(0.9), position)

	var bush_spots := [
		Vector3(6, 0, 8), Vector3(-7, 0, 9), Vector3(11, 0, 2), Vector3(-12, 0, 4),
		Vector3(3, 0, -8), Vector3(-4, 0, -7), Vector3(16, 0, -1), Vector3(-16, 0, 12),
	]
	for position in bush_spots:
		add_prop(Props.bush(randf_range(0.75, 1.1)), position)

	EnvBuilder.forest(self, 34, 33.0, 45.0, Color("#4f9a54"), "mixed")
	EnvBuilder.ground_cover(self, Color("#5c9a53"), 600, 27.0, 0.16, 0.4, LAKE_AVOID)
	EnvBuilder.ground_cover(self, Color("#5c9a53"), 260, 14.0, 0.09, 0.2, LAKE_AVOID)
	EnvBuilder.path(self, [Vector3(0, 0, 10), Vector3(2, 0, 6), Vector3(-1, 0, 1),
		Vector3(-6, 0, -5), Vector3(-10.2, 0, -7.9)], 1.5, Color("#9a8258"), Color("#6fae66"))

	var flower_colors := [Color("#f2b544"), Color("#e8846b"), Color("#f7d35c"), Color("#d98fb8")]
	for i in 16:
		var position := Vector3(randf_range(-24, 24), 0, randf_range(-18, 20))
		if position.distance_to(Vector3(-11, 0, -13)) < 6.5:
			continue
		add_prop(Props.flower_patch(flower_colors[i % flower_colors.size()], 1.1), position)

	for i in 14:
		var tuft := Vector3(randf_range(-26, 26), 0, randf_range(-20, 22))
		if Vector2(tuft.x - LAKE_AVOID.x, tuft.z - LAKE_AVOID.y).length() < LAKE_AVOID.z:
			continue
		add_prop(Props.grass_tuft(randf_range(0.8, 1.2)), tuft)

	var rock_spots := [Vector3(-16, 0, -12), Vector3(20, 0, 3), Vector3(-22, 0, 8), Vector3(14, 0, 10), Vector3(-6, 0, -18)]
	for position in rock_spots:
		add_prop(Props.rock(randf_range(0.8, 1.3)), position, Vector3(0, randf_range(0, 360), 0))

	# Cachoeira na borda oposta, entre pedras: a água cai rente à beira e some na
	# espuma. O espelho e a bacia vêm do EnvBuilder.pond.
	add_prop(Props.water_wall(2.6, 2.2, 0.45), Vector3(-11, 0.96, -16.9))
	var cliff := [
		[Vector3(-2.9, 0, 0.2), 1.9], [Vector3(3.0, 0, 0.0), 2.0], [Vector3(-1.4, 0, -0.9), 1.6],
		[Vector3(1.6, 0, -1.0), 1.7], [Vector3(0, 1.5, -0.4), 1.5], [Vector3(-5.0, 0, 0.6), 1.25],
		[Vector3(5.1, 0, 0.4), 1.15], [Vector3(0, 2.3, 1.3), 1.1],
	]
	for entry in cliff:
		add_prop(Props.rock(float(entry[1])), Vector3(-11, 0, -18.3) + (entry[0] as Vector3),
			Vector3(0, randf_range(0, 360), 0))
	for i in 7:
		var angle := TAU * i / 7.0
		add_prop(Props.rock(randf_range(0.5, 0.85)), Vector3(-11 + cos(angle) * 5.1, 0, -13 + sin(angle) * 5.1),
			Vector3(0, randf_range(0, 360), 0))
	add_prop(Props.fireflies(26, Vector3(9, 2, 9)), Vector3(-11, 1.0, -12))

	add_prop(Props.signpost("Jardim do Éden", Color("#58a86b")), Vector3(2.8, 0, 11), Vector3(0, -20, 0))

func _build_characters() -> void:
	add_npc("adao", StoryCast.display_name("adao"), Vector3(2.5, 0, 3),
		StoryCast.look("adao"), Vector3(0, 0, 14))
	add_npc("eva", StoryCast.display_name("eva"), Vector3(-4.5, 0, -1),
		StoryCast.look("eva"), Vector3(0, 0, 14))

	var animals := [
		["sheep", Vector3(5, 0, -2), 3.5],
		["rabbit", Vector3(-1.5, 0, 6), 2.2],
		["deer", Vector3(-8, 0, 3), 4.0],
		["bird", Vector3(9, 0.2, 5), 5.0],
		["donkey", Vector3(9, 0, -6), 3.0],
	]
	for entry in animals:
		var animal := add_animal(str(entry[0]), entry[1])
		animal.home_radius = float(entry[2])

	# Peixes nadando fundo, abaixo do espelho d'água.
	var fish := add_animal("fish", Vector3(-11.0, -0.65, -13.0))
	fish.wander_radius_setup(0.7)
	var koi := add_animal("fish", Vector3(-10.6, -0.62, -13.6), {"body": Color("#7fb2d6")})
	koi.wander_radius_setup(0.4)

func _build_activities() -> void:
	var plants := [
		[Vector3(-5.5, 0, 7.5), Color("#f2b544")],
		[Vector3(7.5, 0, 6.5), Color("#e8846b")],
		[Vector3(-9.5, 0, -3.5), Color("#d98fb8")],
	]
	for entry in plants:
		var plant := add_simple_prop("water_plant", entry[0], "Regar a mudinha",
			Props.flower_patch(entry[1], 1.35))
		plant.sound = "interact"
		plant.toast_text = "A mudinha agradeceu a água!"

	add_scroll("criacao", Vector3(13, 1.0, -9), "eden_pergaminhos")
	add_scroll("eden_jardim", Vector3(-15, 1.0, 5), "eden_pergaminhos")
	add_scroll("eden_animais", Vector3(4, 1.0, 13), "eden_pergaminhos")

	add_quiz_station("eden_final", Vector3(-11, 0, -20.5), "Examinar a pedra", "eden_memoria")
