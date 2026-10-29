extends WorldBase
## Deserto e Mar Vermelho: guiar viajantes, acender braseiros na ordem certa,
## achar pergaminhos e atravessar o mar quando o caminho se abrir.

var _beacons: Array[BrazierBeacon] = []
var _next_beacon := 1
var _camp: Node3D
var _sea_left: Node3D
var _sea_right: Node3D
var _sea_barrier: StaticBody3D
var _dry_path: MeshInstance3D
var _sea_open := false
var _crossed_once := false

func _get_spawn_position() -> Vector3:
	return Vector3(0, 0.2, 17)

func _build_world() -> void:
	_build_environment()
	_build_scenery()
	_build_camp()
	_build_characters()
	_build_beacons()
	_build_collectibles()
	_build_sea()
	EnvBuilder.inner_bounds(self, 60.0)
	Missions.mission_started.connect(_on_mission_started)
	if Missions.is_mission_completed("moses_travessia"):
		_crossed_once = true
		_open_sea(false)
	elif Missions.is_active("moses_travessia"):
		_open_sea(false)
	if Missions.is_mission_completed("moses_braseiros"):
		for beacon in _beacons:
			beacon.set_lit(true)
		_next_beacon = 4

func _build_environment() -> void:
	var env := EnvBuilder.setup(self, {
		"sky_top": Color("#7fb4d9"),
		"sky_horizon": Color("#ffd9a0"),
		"ground_bottom": Color("#c9a468"),
		"ground_horizon": Color("#f4e2bd"),
		"ambient": Color("#f5e3c2"),
		"ambient_energy": 0.78,
		"sun_rotation": Vector3(-40, -60, 0),
		"sun_color": Color("#ffddaa"),
		"sun_energy": 1.25,
		"fog_density": 0.0015,
		"fog_color": Color("#f0d9b5"),
	})
	set_environment(env["environment"] as WorldEnvironment, env["sun"] as DirectionalLight3D)
	EnvBuilder.ground(self, Color("#d9b878"), 150.0)
	EnvBuilder.hills(self, Color("#cfa96a"), 18, 46.0, 74.0)
	EnvBuilder.clouds(self, 7, 23.0)

func _build_scenery() -> void:
	var palm_spots := [
		[Vector3(-14, 0, 10), 1.0], [Vector3(15, 0, 9), 1.1], [Vector3(-20, 0, -6), 0.9],
		[Vector3(22, 0, -4), 1.0], [Vector3(-10, 0, -18), 1.15], [Vector3(11, 0, -19), 0.95],
		[Vector3(-9, 0, -50), 1.1], [Vector3(9, 0, -51), 1.0],
	]
	for spot in palm_spots:
		add_prop(Props.palm(float(spot[1])), spot[0], Vector3(0, randf_range(0, 360), 0))

	var rock_spots := [
		Vector3(-17, 0, 2), Vector3(18, 0, 3), Vector3(-22, 0, -12), Vector3(16, 0, -12),
		Vector3(-4, 0, 12), Vector3(5, 0, 13), Vector3(-13, 0, -24), Vector3(13, 0, -26),
		Vector3(-18, 0, 16), Vector3(21, 0, 16), Vector3(-6, 0, -52), Vector3(6, 0, -54),
	]
	for position in rock_spots:
		add_prop(Props.rock(randf_range(1.0, 1.7), Color("#b39876")), position, Vector3(0, randf_range(0, 360), 0))

	for i in 20:
		add_prop(Props.grass_tuft(randf_range(0.6, 0.9), Color("#a9a05e")),
			Vector3(randf_range(-28, 28), 0, randf_range(-22, 22)))

	for i in 10:
		var position := Vector3(randf_range(-26, 26), 0, randf_range(2, 16))
		if position.distance_to(Vector3(0, 0, 9)) < 4.5:
			continue
		add_prop(Props.bush(randf_range(0.6, 0.85), Color("#8f9a56")), position)

	# oásis de palmeiras no perímetro, deixando livre o caminho para o mar
	EnvBuilder.forest(self, 30, 34.0, 47.0, Color("#8f9a56"), "desert", 270.0, 27.0)
	EnvBuilder.meadow(self, Color("#c9a86a"), 40, 28.0)

	# Caminho de pedras do acampamento em direção ao mar.
	for i in 10:
		Props.part(self, Props.box_mesh(Vector3(1.6, 0.06, 0.9)), Props.mat(Color("#c9ac7c"), 1.0),
			Vector3(randf_range(-0.5, 0.5), 0.03, 4.0 - i * 2.4), Vector3(0, randf_range(-8, 8), 0))

	add_prop(Props.signpost("Acampamento", Color("#d97b4b")), Vector3(3.4, 0, 14), Vector3(0, -16, 0))
	add_prop(Props.signpost("Mar Vermelho", Color("#4f9fd0")), Vector3(4.2, 0, -14), Vector3(0, -12, 0))

func _build_camp() -> void:
	_camp = Props.marker(self, Vector3(0, 0.1, 9), "Camp")
	add_prop(Props.tent(), Vector3(-6.5, 0, 9))
	add_prop(Props.tent(Color("#d9c08a")), Vector3(6.5, 0, 10), Vector3(0, 20, 0))
	add_prop(Props.tent(Color("#c9a06a")), Vector3(-9.5, 0, 13), Vector3(0, -18, 0))
	add_prop(Props.tent(Color("#e0c79a")), Vector3(9.5, 0, 13), Vector3(0, 30, 0))
	add_prop(Props.crate(), Vector3(-3.5, 0, 11))
	add_prop(Props.barrel(), Vector3(3.5, 0, 12))
	add_prop(Props.hay(), Vector3(-4.5, 0, 6), Vector3(0, 25, 0))
	add_prop(Props.banner(Color("#d97b4b")), Vector3(2.4, 0, 7))
	add_prop(Props.banner(Color("#f2c14e")), Vector3(-2.4, 0, 7))
	add_prop(Props.fireflies(20, Vector3(8, 2, 8)), Vector3(0, 1.0, 9))

func _build_characters() -> void:
	add_npc("moises", StoryCast.display_name("moises"), Vector3(2, 0, 5),
		StoryCast.look("moises"), Vector3(0, 0, 17))
	add_npc("miria", StoryCast.display_name("miria"), Vector3(-3.5, 0, 6),
		StoryCast.look("miria"), Vector3(0, 0, 17))

	var travelers := [
		["viajante_1", "Rute", Vector3(-20, 0, -4), {
			"gender": "female", "outfit": "dress", "hair_style": "braid", "headwear": "veil",
			"jewelry": true, "tunic": Color("#a8896a"), "veil": Color("#e8d6ab"),
		}],
		["viajante_2", "Aarão", Vector3(19, 0, -1), {
			"gender": "male", "outfit": "robe", "hair_style": "short", "headwear": "turban",
			"beard": Color("#5a4632"), "tunic": Color("#8a7a5a"), "veil": Color("#d9c9a8"),
		}],
		["viajante_3", "Miri", Vector3(13, 0, 13), {
			"gender": "female", "outfit": "dress", "hair_style": "long", "headwear": "headband",
			"jewelry": true, "tunic": Color("#a8a06a"),
		}],
	]
	for entry in travelers:
		var look := {
			"skin": Color("#c98d63"), "hair": Color("#4a2f20"), "tunic": Color("#a8a06a"),
			"trim": Color("#d97b4b"), "pants": Color("#7a6a4a"), "shoe": Color("#4d3a2a"),
		}
		var extra: Dictionary = entry[3]
		look.merge(extra, true)
		var traveler := add_npc(str(entry[0]), str(entry[1]), entry[2], look, Vector3(0, 0, 9))
		traveler.can_follow = true
		traveler.follow_mission = "moses_povo"
		traveler.escort_target = _camp
		traveler.escort_event = "traveler_arrived"
		traveler.escort_hint = "Siga até o acampamento com %s." % str(entry[1])

func _build_beacons() -> void:
	var defs := [
		[1, "Sol", Vector3(-8, 0, -8)],
		[2, "Lua", Vector3(0, 0, -11)],
		[3, "Estrela", Vector3(8, 0, -8)],
	]
	for entry in defs:
		var beacon := BrazierBeacon.new()
		beacon.order_index = int(entry[0])
		beacon.beacon_name = str(entry[1])
		beacon.position = entry[2]
		add_child(beacon)
		_beacons.append(beacon)

func try_light_beacon(beacon: BrazierBeacon) -> void:
	if beacon == null or beacon.lit:
		return
	if beacon.order_index != _next_beacon:
		Audio.play_sfx("wrong", 0.9, 0.6)
		Game.toast("A ordem é Sol, Lua e Estrela. Vamos tentar de novo!", "✧")
		for other in _beacons:
			other.set_lit(false)
		_next_beacon = 1
		return
	beacon.set_lit(true)
	_next_beacon += 1
	Audio.play_sfx("success", 1.0, 0.7)
	if _next_beacon > _beacons.size():
		Missions.notify_event("beacon_lit", 3, {})
		Game.toast("Os três braseiros iluminam o caminho até o mar!", "✦")
	else:
		Game.toast("Braseiro do %s aceso! (%d/%d)" % [beacon.beacon_name, _next_beacon - 1, _beacons.size()], "✦")

func _build_collectibles() -> void:
	add_scroll("moses_chamado", Vector3(-14, 1.0, 6), "moses_pergaminhos")
	add_scroll("mar_vermelho", Vector3(15, 1.0, 1), "moses_pergaminhos")
	add_scroll("povo_liberdade", Vector3(0, 1.0, 15), "moses_pergaminhos")
	add_quiz_station("moses_final", Vector3(-14, 0, 1), "Desafio extra: pedra da travessia")

func _build_sea() -> void:
	var water := Props.mat(Color("#4f9fd0"), 0.15, 0.1, 0.85)
	Props.part(self, Props.box_mesh(Vector3(120, 0.08, 32)), water, Vector3(0, 0.05, -37))

	_dry_path = Props.part(self, Props.box_mesh(Vector3(7.0, 0.14, 32)), Props.mat(Color("#d9b878"), 1.0),
		Vector3(0, 0.1, -37))
	_dry_path.visible = false

	_sea_left = Node3D.new()
	_sea_left.name = "SeaLeft"
	_sea_left.position = Vector3(-3.4, 2.3, -37)
	add_child(_sea_left)
	Props.part(_sea_left, Props.box_mesh(Vector3(6.8, 4.6, 32)), water, Vector3.ZERO)

	_sea_right = Node3D.new()
	_sea_right.name = "SeaRight"
	_sea_right.position = Vector3(3.4, 2.3, -37)
	add_child(_sea_right)
	Props.part(_sea_right, Props.box_mesh(Vector3(6.8, 4.6, 32)), water, Vector3.ZERO)

	for wall in [_sea_left, _sea_right]:
		for i in 4:
			Props.part(wall, Props.sphere_mesh(0.35, 8, 4), Props.unshaded(Color("#d9f2ff"), 0.7),
				Vector3(randf_range(-2.6, 2.6), 2.35, randf_range(-15, 15)), Vector3.ZERO, Vector3(1.4, 0.5, 1.4))

	_sea_barrier = StaticBody3D.new()
	_sea_barrier.name = "SeaBarrier"
	_sea_barrier.collision_layer = 1
	_sea_barrier.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16, 4.6, 1.2)
	shape.shape = box
	shape.position = Vector3(0, 2.3, 0)
	_sea_barrier.add_child(shape)
	_sea_barrier.position = Vector3(0, 0, -22.5)
	add_child(_sea_barrier)

	# Margem distante e área de chegada.
	add_prop(Props.banner(Color("#4f9fd0")), Vector3(-4, 0, -47))
	add_prop(Props.banner(Color("#f2c14e")), Vector3(4, 0, -47))
	add_prop(Props.signpost("Outra margem", Color("#4f9fd0")), Vector3(5.5, 0, -49), Vector3(0, -20, 0))

	var area := Area3D.new()
	area.name = "CrossingArea"
	area.collision_layer = 0
	area.collision_mask = 2
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(16, 6, 5)
	area_shape.shape = area_box
	area_shape.position = Vector3(0, 3, 0)
	area.add_child(area_shape)
	area.position = Vector3(0, 0, -49)
	add_child(area)
	area.body_entered.connect(_on_crossing_area_entered)

func _open_sea(animate: bool) -> void:
	if _sea_open:
		return
	_sea_open = true
	if _dry_path:
		_dry_path.visible = true
	if is_instance_valid(_sea_barrier):
		_sea_barrier.queue_free()
		_sea_barrier = null
	if not animate:
		if _sea_left:
			_sea_left.position.x = -11.0
		if _sea_right:
			_sea_right.position.x = 11.0
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sea_left, "position:x", -11.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_sea_right, "position:x", 11.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	Game.toast("O mar se abre! Caminhe em terra seca.", "≈")
	Audio.play_sfx("success", 0.9, 0.85)

func _on_mission_started(mission: Dictionary) -> void:
	if str(mission.get("id", "")) == "moses_travessia":
		_open_sea(true)

func _on_crossing_area_entered(body: Node3D) -> void:
	if _crossed_once or body != Game.get_player():
		return
	if not Missions.is_active("moses_travessia"):
		return
	_crossed_once = true
	Missions.notify_event("sea_crossed", 1, {})
	Audio.play_sfx("success", 1.15, 0.9)
	Game.toast("Você atravessou o mar em terra seca!", "✦")
