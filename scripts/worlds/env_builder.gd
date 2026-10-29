class_name EnvBuilder
## Céu, sol, neblina, chão e montanhas distantes — tudo reutilizável entre mundos.

static func setup(root: Node3D, cfg: Dictionary) -> Dictionary:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = cfg.get("sky_top", Color("#78c3e8"))
	sky_mat.sky_horizon_color = cfg.get("sky_horizon", Color("#dff2f2"))
	sky_mat.ground_bottom_color = cfg.get("ground_bottom", Color("#a8b9a0"))
	sky_mat.ground_horizon_color = cfg.get("ground_horizon", Color("#e8efdc"))
	sky_mat.sun_angle_max = 9.0
	sky_mat.sun_curve = 0.06
	sky_mat.sky_curve = 0.08
	sky_mat.sky_energy_multiplier = 0.8

	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = cfg.get("ambient", Color("#d8e6d5"))
	env.ambient_light_sky_contribution = 0.45
	env.ambient_light_energy = float(cfg.get("ambient_energy", 0.65)) * 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_white = 1.0
	env.tonemap_exposure = float(cfg.get("exposure", 1.0)) * 0.95
	var fog_density := float(cfg.get("fog_density", 0.0))
	if fog_density > 0.0:
		env.fog_enabled = true
		env.fog_light_color = cfg.get("fog_color", Color("#d9e6ef"))
		env.fog_density = fog_density
		env.fog_sky_affect = 0.0
		env.fog_aerial_perspective = 0.0

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	root.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = cfg.get("sun_rotation", Vector3(-52, -38, 0))
	sun.light_color = cfg.get("sun_color", Color("#fff2d1"))
	sun.light_energy = float(cfg.get("sun_energy", 1.15)) * 0.45
	sun.light_angular_distance = 0.8
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	sun.shadow_enabled = Settings.shadow_enabled()
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = Settings.shadow_max_distance()
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.4
	sun.shadow_blur = 1.4
	root.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-22, 140, 0)
	fill.light_color = cfg.get("fill_color", Color("#cfe3ff"))
	fill.light_energy = float(cfg.get("fill_energy", 0.22)) * 0.5
	fill.shadow_enabled = false
	root.add_child(fill)

	return {"environment": world_env, "sun": sun}

static func ground(root: Node3D, color: Color, size := 150.0) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var material := Props.ground_mat(color)
	plane.material = material
	var mesh := MeshInstance3D.new()
	mesh.name = "Ground"
	mesh.mesh = plane
	root.add_child(mesh)

	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.6, size)
	shape.shape = box
	shape.position = Vector3(0, -0.3, 0)
	body.add_child(shape)
	root.add_child(body)

static func hills(root: Node3D, base_color: Color, count := 14, radius_min := 45.0, radius_max := 75.0) -> void:
	for i in count:
		var angle := TAU * float(i) / float(count) + randf_range(-0.12, 0.12)
		var distance := randf_range(radius_min, radius_max)
		var hill := Node3D.new()
		hill.name = "Hill%d" % i
		hill.position = Vector3(cos(angle) * distance, -2.0, sin(angle) * distance)
		var sx := randf_range(10.0, 20.0)
		var sy := randf_range(5.0, 12.0)
		var sz := randf_range(10.0, 20.0)
		Props.part(hill, Props.sphere_mesh(1.0, 10, 5), Props.mat(base_color.lightened(randf_range(-0.05, 0.08)), 1.0),
			Vector3.ZERO, Vector3(0, randf_range(0, 360), 0), Vector3(sx, sy, sz))
		shadows_off(hill)
		root.add_child(hill)

static func clouds(root: Node3D, count := 8, height := 22.0) -> void:
	for i in count:
		var cloud := Props.cloud(randf_range(1.2, 2.4))
		cloud.position = Vector3(randf_range(-70, 70), height + randf_range(-3, 6), randf_range(-70, 70))
		root.add_child(cloud)

static func inner_bounds(root: Node3D, radius := 58.0) -> void:
	var body := StaticBody3D.new()
	body.name = "Bounds"
	body.collision_layer = 1
	body.collision_mask = 0
	var thickness := 2.0
	for i in 4:
		var angle := TAU * i / 4.0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(radius * 2.0, 20.0, thickness)
		shape.shape = box
		shape.position = Vector3(cos(angle) * radius, 10.0, sin(angle) * radius)
		shape.rotation_degrees = Vector3(0, rad_to_deg(angle) + 90.0, 0)
		body.add_child(shape)
	root.add_child(body)

## Cinturão de mata no perímetro do mundo: fecha o horizonte sem invadir a área jogável.
## style: "mixed" (árvores, pinheiros e arbustos), "dry" (árvores e palmeiras) ou
## "desert" (só palmeiras e arbustos). gap_deg abre uma clareira (ex.: caminho do mar).
static func forest(root: Node3D, count := 30, radius_min := 34.0, radius_max := 46.0,
		leaf_color := Color("#4f9a54"), style := "mixed", gap_deg := -1.0, gap_width := 0.0) -> void:
	for i in count:
		var angle := TAU * float(i) / float(count) + randf_range(-0.09, 0.09)
		var degrees := rad_to_deg(angle)
		if gap_deg >= 0.0 and absf(wrapf(degrees - gap_deg, -180.0, 180.0)) < gap_width:
			continue
		var distance := randf_range(radius_min, radius_max)
		var tint := leaf_color.lightened(randf_range(-0.07, 0.09))
		var piece: Node3D
		var roll := randf()
		match style:
			"desert":
				piece = Props.palm(randf_range(0.85, 1.15))
			"dry":
				if roll < 0.45:
					piece = Props.palm(randf_range(0.85, 1.05))
				else:
					piece = Props.tree(randf_range(0.9, 1.2), tint, Color("#6b4a2e"))
			_:
				if roll < 0.24:
					piece = Props.pine(randf_range(1.0, 1.3), tint.darkened(0.12))
				elif roll < 0.34:
					piece = Props.palm(randf_range(0.85, 1.05))
				else:
					piece = Props.tree(randf_range(0.95, 1.3), tint)
		piece.position = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		piece.rotation.y = randf_range(0.0, TAU)
		shadows_off(piece)
		root.add_child(piece)
	for i in int(count * 0.55):
		var angle := TAU * float(i) / float(count * 0.55) + randf_range(-0.22, 0.22)
		var degrees := rad_to_deg(angle)
		if gap_deg >= 0.0 and absf(wrapf(degrees - gap_deg, -180.0, 180.0)) < gap_width:
			continue
		var distance := randf_range(radius_min - 2.0, radius_max + 2.0)
		var bush := Props.bush(randf_range(0.7, 1.1), leaf_color.darkened(randf_range(0.0, 0.1)))
		bush.position = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		bush.rotation.y = randf_range(0.0, TAU)
		shadows_off(bush)
		root.add_child(bush)

## Cenário distante não entra no mapa de sombras: metade dos draw calls da mata.
static func shadows_off(node: Node) -> void:
	for child in node.find_children("*", "GeometryInstance3D", true, false):
		(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Manchas de vegetação rasteira: quebram a planície e dão escala ao chão.
## A lente fica 1 cm acima do chão (encostada, gerava z-fighting) e não nasce
## perto do ponto de partida, onde pareceria um degrau aos pés do jogador.
static func meadow(root: Node3D, color: Color, count := 44, radius := 26.0) -> void:
	var disc := Props.sphere_mesh(1.0, 14, 8)
	var tones := [color.darkened(0.1), color.darkened(0.04), color.lightened(0.02)]
	var keep_clear := Vector2(0.0, 15.0)
	var batches: Array = [[], [], []]
	for i in count:
		var angle := randf_range(0.0, TAU)
		var distance := sqrt(randf()) * radius
		var spot := Vector3(cos(angle) * distance, 0.05, sin(angle) * distance)
		if Vector2(spot.x, spot.z).distance_to(keep_clear) < 5.5:
			continue
		var size := randf_range(0.5, 1.1)
		batches[i % 3].append([disc, Props.xf(spot, Vector3(0, randf_range(0.0, 360.0), 0),
			Vector3(size, 0.04, size * randf_range(0.7, 1.15)))])
	for i in 3:
		var batch := Props.add_merged(root, batches[i], Props.ground_mat(tones[i]), "Meadow%d" % i)
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
