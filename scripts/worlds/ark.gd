extends WorldBase
## Arca de Noé: reunir os animais, organizar provisões, achar pergaminhos e
## resolver o desafio da porta. A chuva e o arco-íris só aparecem ao concluir.

var _ark_door: Node3D
var _supplies: Node3D
var _rain: CPUParticles3D
var _rainbow: Node3D

func _get_spawn_position() -> Vector3:
	return Vector3(0, 0.2, 15)

func _build_world() -> void:
	_build_environment()
	_build_scenery()
	_build_ark()
	_build_characters()
	_build_activities()
	_build_weather()
	EnvBuilder.inner_bounds(self, 54.0)
	Missions.world_completed.connect(_on_world_completed)
	if Missions.is_world_done():
		_rainbow.visible = true

func _build_environment() -> void:
	var env := EnvBuilder.setup(self, {
		"sky_top": Color("#6f9fc0"),
		"sky_horizon": Color("#d9e6ea"),
		"ground_bottom": Color("#8c9d86"),
		"ground_horizon": Color("#e7e3cf"),
		"ambient": Color("#e3ecf2"),
		"ambient_energy": 0.7,
		"sun_rotation": Vector3(-38, -52, 0),
		"sun_color": Color("#f2f4e8"),
		"sun_energy": 1.0,
		"fog_density": 0.003,
		"fog_color": Color("#cfdde6"),
	})
	set_environment(env["environment"] as WorldEnvironment, env["sun"] as DirectionalLight3D)
	EnvBuilder.ground(self, Color("#8fae7f"), 130.0)
	EnvBuilder.hills(self, Color("#7e9f78"), 15, 44.0, 70.0)
	EnvBuilder.clouds(self, 14, 17.0)

func _build_scenery() -> void:
	var tree_spots := [
		[Vector3(16, 0, 8), 1.1], [Vector3(-17, 0, 4), 1.15], [Vector3(15, 0, -6), 0.95],
		[Vector3(-15, 0, -7), 1.0], [Vector3(21, 0, -2), 1.2], [Vector3(-22, 0, 12), 1.05],
	]
	for spot in tree_spots:
		add_prop(Props.tree(float(spot[1]), Color("#5c8f57")), spot[0], Vector3(0, randf_range(0, 360), 0))

	var pine_spots := [Vector3(-10, 0, -20), Vector3(10, 0, -20), Vector3(22, 0, 10), Vector3(-22, 0, -2)]
	for position in pine_spots:
		add_prop(Props.pine(1.2, Color("#3f7d55")), position)

	var bush_spots := [
		Vector3(-6, 0, 8), Vector3(6, 0, 9), Vector3(-11, 0, 1), Vector3(11, 0, 0),
		Vector3(-8, 0, -9), Vector3(9, 0, -8), Vector3(13, 0, 6),
	]
	for position in bush_spots:
		add_prop(Props.bush(randf_range(0.8, 1.1), Color("#4c7f50")), position)

	EnvBuilder.forest(self, 32, 33.0, 45.0, Color("#5c8f57"), "mixed")
	EnvBuilder.ground_cover(self, Color("#6f9c5a"), 520, 27.0)
	EnvBuilder.ground_cover(self, Color("#6f9c5a"), 240, 14.0, 0.09, 0.2)
	EnvBuilder.path(self, [Vector3(0, 0, 11), Vector3(0, 0, 5), Vector3(0, 0, -2),
		Vector3(0, 0, -10)], 2.4, Color("#997e57"), Color("#8fae7f"))

	for i in 12:
		add_prop(Props.grass_tuft(randf_range(0.9, 1.3), Color("#7d9d5f")),
			Vector3(randf_range(-24, 24), 0, randf_range(-16, 20)))

	for position in [Vector3(-14, 0, 13), Vector3(18, 0, -12), Vector3(-20, 0, -14), Vector3(13, 0, 14)]:
		add_prop(Props.rock(randf_range(0.9, 1.4)), position, Vector3(0, randf_range(0, 360), 0))

	var fence_positions := [
		[Vector3(-8, 0, 12), Vector3(0, 90, 0)],
		[Vector3(8, 0, 12), Vector3(0, 90, 0)],
		[Vector3(-14, 0, 6), Vector3(0, 0, 0)],
	]
	for entry in fence_positions:
		add_prop(Props.fence(7.0), entry[0], entry[1])

	add_prop(Props.hay(), Vector3(-6, 0, -4))
	add_prop(Props.hay(), Vector3(9, 0, 5), Vector3(0, 30, 0))
	add_prop(Props.barrel(), Vector3(7.5, 0, 2))
	add_prop(Props.barrel(Color("#8a6a44")), Vector3(8.5, 0, 3))
	add_prop(Props.crate(), Vector3(-9, 0, 1))
	add_prop(Props.signpost("Arca de Noé", Color("#c98a4b")), Vector3(3.2, 0, 12), Vector3(0, -18, 0))

func _build_ark() -> void:
	var ark := Props.ark()
	add_prop(ark, Vector3(0, 0.3, -18), Vector3(0, 180, 0))
	_ark_door = ark.get_node_or_null("ArkDoor") as Node3D
	_supplies = Props.marker(self, Vector3(5.2, 0.1, -11.5), "Supplies")

func _build_characters() -> void:
	add_npc("noe", StoryCast.display_name("noe"), Vector3(2, 0, -9),
		StoryCast.look("noe"), Vector3(0, 0, 15))
	add_npc("sem", StoryCast.display_name("sem"), Vector3(-3.5, 0, -3),
		StoryCast.look("sem"), Vector3(0, 0, 15))

	var animals := [
		["sheep", Vector3(6, 0, 1), "Leve a ovelha até a porta da arca."],
		["rabbit", Vector3(-6, 0, 4), "Leve o coelho até a porta da arca."],
		["goat", Vector3(8, 0, -5), "Leve o cabrito até a porta da arca."],
		["donkey", Vector3(-8, 0, -3), "Leve o jumentinho até a porta da arca."],
	]
	for entry in animals:
		var animal := add_animal(str(entry[0]), entry[1])
		animal.can_follow = true
		animal.escort_target = _ark_door
		animal.escort_event = "animal_delivered"
		animal.escort_hint = str(entry[2])

func _build_activities() -> void:
	var crates := [
		Vector3(-8, 0, -5), Vector3(8.5, 0, -7), Vector3(-4, 0, 8),
	]
	for position in crates:
		var crate := add_simple_prop("supply_stored", position, "Organizar provisões", Props.crate())
		crate.move_to = _supplies
		crate.sound = "interact"
		crate.toast_text = "Provisões guardadas junto da arca!"

	add_scroll("arca_construcao", Vector3(-11, 1.0, 0), "ark_pergaminhos")
	add_scroll("diluvio", Vector3(11, 1.0, -3), "ark_pergaminhos")
	add_scroll("arco_iris", Vector3(0, 1.0, 11), "ark_pergaminhos")

	add_quiz_station("ark_final", Vector3(-4.5, 0, -11), "Examinar a pedra", "ark_memoria")

func _build_weather() -> void:
	_rain = Props.rain(Vector3(60, 14, 60))
	_rain.amount = 260
	_rain.emitting = false
	add_child(_rain)

	_rainbow = Node3D.new()
	_rainbow.name = "Rainbow"
	add_child(_rainbow)
	var colors := [
		Color("#e57373"), Color("#f2b544"), Color("#f7e07a"),
		Color("#7fc78a"), Color("#6fa8dc"), Color("#8f7fd0"),
	]
	var radius := 26.0
	for band in colors.size():
		var band_radius := radius - band * 0.95
		for step in 30:
			var angle := lerpf(deg_to_rad(16.0), deg_to_rad(164.0), float(step) / 29.0)
			var point := Vector3(cos(angle) * band_radius, sin(angle) * band_radius - 4.0, 0)
			Props.part(_rainbow, Props.sphere_mesh(0.8, 8, 4), Props.unshaded(colors[band], 0.6),
				point, Vector3.ZERO, Vector3(1.0, 1.0, 0.55))
	_rainbow.position = Vector3(0, 0, -46)
	_rainbow.visible = false

func _on_world_completed(completed_world: String) -> void:
	if completed_world != world_id:
		return
	_rainbow.visible = true
	_rain.emitting = true
	Game.toast("O arco-íris brilha no céu: a promessa de Deus!", "⌒")
