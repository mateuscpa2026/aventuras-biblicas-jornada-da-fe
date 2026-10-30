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
	env.ambient_light_energy = float(cfg.get("ambient_energy", 0.65)) * 0.22
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
	sun.light_energy = float(cfg.get("sun_energy", 1.15)) * 0.6
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
	# Malha subdividida para pintar manchas de tom direto nos vértices: sem lentes
	# sobrepostas, não há z-fighting nem sombras estranhas no meio do campo.
	plane.subdivide_width = 72
	plane.subdivide_depth = 72
	var arrays := plane.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	colors.resize(verts.size())
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.03
	noise.fractal_octaves = 4
	noise.seed = 733
	# duas escalas: mancha larga bem suave + granulado fino. Só a larga, com
	# amplitude alta, virava polígonos escuros do tamanho de um campo de futebol.
	var detail := FastNoiseLite.new()
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail.frequency = 0.26
	detail.fractal_octaves = 3
	detail.seed = 917
	for i in verts.size():
		var point := verts[i]
		var tone := 1.0 + noise.get_noise_2d(point.x, point.z) * 0.055 \
			+ detail.get_noise_2d(point.x, point.z) * 0.07
		colors[i] = Color(tone, tone, tone)
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := Props.ground_mat(color)
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.name = "Ground"
	instance.mesh = mesh
	# Um plano do tamanho do mundo dentro do mapa de sombra vira uma mancha escura
	# gigante com bordas serrilhadas; o chão não precisa projetar sombra.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)

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

## Caminho de terra batida ligando os pontos do mundo, rente ao chão.
## É uma fita única: tiles sobrepostos z-fightavam a distância e viravam faixas escuras.
## As bordas recebem a cor do capim em vertex color, então a trilha se dissolve no
## campo em vez de aparecer como uma placa reta sobre a grama.
static func path(root: Node3D, points: Array, width := 1.6, color := Color("#8a7448"),
		blend := Color("#6fae66")) -> void:
	if points.size() < 2:
		return
	# estende 12 m para trás do primeiro ponto: a trilha nasce fora do quadro, em
	# vez de aparecer como uma placa solta no meio do campo na frente do jogador
	var extended: Array = [points[0]]
	var back := (points[0] as Vector3 - points[1] as Vector3)
	back.y = 0.0
	if back.length() > 0.01:
		extended = [(points[0] as Vector3) + back.normalized() * 12.0]
	extended.append_array(points)
	points = extended
	var columns := [-1.0, -0.58, 0.0, 0.58, 1.0]
	var tones := [blend, color.lerp(blend, 0.4), color, color.lerp(blend, 0.4), blend]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var run := 0.0
	var total := 0.0
	for i in points.size() - 1:
		total += (points[i] as Vector3).distance_to(points[i + 1] as Vector3)
	for i in points.size():
		var here: Vector3 = points[i]
		here.y = 0.0
		var direction: Vector3
		if i == 0:
			direction = (points[1] as Vector3 - points[0] as Vector3)
		elif i == points.size() - 1:
			direction = (points[i] as Vector3 - points[i - 1] as Vector3)
		else:
			direction = (points[i + 1] as Vector3 - points[i - 1] as Vector3)
		direction.y = 0.0
		direction = direction.normalized()
		var side := direction.cross(Vector3.UP).normalized()
		# só a ponta oposta ao início afina: a trilha começa larga sob os pés do jogador
		var tip := clampf((total - run) / 2.8, 0.3, 1.0)
		# borda levemente ondulada em vez de régua: trilha pisada não tem lados retos
		var wobble := sin(run * 0.85 + 1.3) * 0.14 + sin(run * 2.6 + 0.4) * 0.06
		var half := width * 0.5 * tip * (1.0 + wobble)
		for c in columns.size():
			verts.append(here + side * half * float(columns[c]) + Vector3.UP * 0.03)
			normals.append(Vector3.UP)
			uvs.append(Vector2((float(columns[c]) + 1.0) * 0.5, run))
			colors.append(tones[c])
		if i < points.size() - 1:
			var a := i * columns.size()
			var b := (i + 1) * columns.size()
			for c in columns.size() - 1:
				# ordem horária vista de cima: no Godot essa é a face da frente.
				# Invertida, a fita recebia luz pelo verso e saía preta.
				indices.append_array([a + c, b + c, a + c + 1, a + c + 1, b + c, b + c + 1])
			var next_point: Vector3 = points[i + 1]
			next_point.y = 0.0
			run += here.distance_to(next_point)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, Props.path_mat(color))
	var instance := MeshInstance3D.new()
	instance.name = "Path"
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)

## Capim espalhado em lote: um único mesh por tom, então sai barato.
## Lagoa com bacia de verdade: o miolo do chão é rebaixado, a colisão vira um
## fundo em declive e a beira ganha areia, juncos e pedras. Devolve o volume de
## água para o jogador saber onde está submerso.
static func pond(root: Node3D, center: Vector3, radius := 4.6, depth := 1.15,
		grass := Color("#6fae66"), ground_size := 130.0) -> WaterVolume:
	var cut := radius - 0.2
	_cut_ground(root, center, cut)
	_split_ground_collision(root, center, cut)

	var bed := _pond_bed(center, radius, depth, radius + 2.4, grass, ground_size)
	var bed_instance := MeshInstance3D.new()
	bed_instance.name = "PondBed"
	bed_instance.mesh = bed
	root.add_child(bed_instance)
	var bed_body := StaticBody3D.new()
	bed_body.name = "PondBedCollision"
	bed_body.collision_layer = 1
	bed_body.collision_mask = 0
	var bed_shape := CollisionShape3D.new()
	bed_shape.shape = bed.create_trimesh_shape()
	bed_body.add_child(bed_shape)
	root.add_child(bed_body)

	var water_y := POND_LIP - POND_WATERLINE
	var lake := WaterVolume.new()
	lake.name = "Lake"
	lake.position = Vector3(center.x, 0.0, center.z)
	lake.surface_y = water_y
	lake.radius = radius * 0.8
	lake.depth = depth - POND_WATERLINE
	lake.lip_y = POND_LIP
	lake.basin_radius = radius
	lake.basin_depth = depth
	lake.surface = Props.water_surface(lake.radius)
	lake.surface.position.y = water_y
	lake.add_child(lake.surface)
	root.add_child(lake)

	_pond_shore(root, center, radius, depth, lake.radius, water_y)
	return lake

const POND_LIP := 0.02
const POND_WATERLINE := 0.14

## Perfil do fundo: bacia suave (inclinação máxima ~20°, sempre caminhável) e
## uma beirada que desce alguns milímetros para se fundir com o campo.
static func _pond_height(distance: float, radius: float, depth: float) -> float:
	if distance < radius:
		var t := 1.0 - distance / radius
		return POND_LIP - depth * (t * t * (3.0 - 2.0 * t))
	var fade := clampf((distance - radius) / 1.8, 0.0, 1.0)
	return lerpf(POND_LIP, 0.006, fade)

## Recorta o chão em volta da bacia: triângulos que encostam no buraco saem da
## malha, senão uma laje plana ficaria pairando sobre a água.
static func _cut_ground(root: Node3D, center: Vector3, cut: float) -> void:
	var instance := root.get_node_or_null("Ground") as MeshInstance3D
	if instance == null or not (instance.mesh is ArrayMesh):
		return
	var mesh := instance.mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		return
	var kept := PackedInt32Array()
	for i in range(0, indices.size(), 3):
		var a := verts[indices[i]]
		var b := verts[indices[i + 1]]
		var c := verts[indices[i + 2]]
		var min_x := minf(a.x, minf(b.x, c.x))
		var max_x := maxf(a.x, maxf(b.x, c.x))
		var min_z := minf(a.z, minf(b.z, c.z))
		var max_z := maxf(a.z, maxf(b.z, c.z))
		var touches := max_x >= center.x - cut and min_x <= center.x + cut \
			and max_z >= center.z - cut and min_z <= center.z + cut
		if not touches:
			kept.append(indices[i])
			kept.append(indices[i + 1])
			kept.append(indices[i + 2])
	arrays[Mesh.ARRAY_INDEX] = kept
	var cut_mesh := ArrayMesh.new()
	cut_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	cut_mesh.surface_set_material(0, mesh.surface_get_material(0))
	instance.mesh = cut_mesh

## Troca a laje única do chão por quatro lajes em volta do buraco: o miolo fica
## livre para o colisor da bacia, e o jogador desce até o fundo.
static func _split_ground_collision(root: Node3D, center: Vector3, cut: float) -> void:
	var body := root.get_node_or_null("GroundCollision") as StaticBody3D
	if body == null or body.get_child_count() == 0:
		return
	var shape_node := body.get_child(0) as CollisionShape3D
	var box := shape_node.shape as BoxShape3D if shape_node else null
	if box == null:
		return
	var half_x := box.size.x * 0.5
	var half_z := box.size.z * 0.5
	var top := box.size.y * 0.5
	var rects := [
		Vector4(-half_x, center.x - cut, -half_z, half_z),
		Vector4(center.x + cut, half_x, -half_z, half_z),
		Vector4(center.x - cut, center.x + cut, -half_z, center.z - cut),
		Vector4(center.x - cut, center.x + cut, center.z + cut, half_z),
	]
	shape_node.shape = null
	body.remove_child(shape_node)
	shape_node.queue_free()
	for rect in rects:
		var size := Vector3(rect.y - rect.x, box.size.y, rect.w - rect.z)
		if size.x <= 0.01 or size.z <= 0.01:
			continue
		var piece := CollisionShape3D.new()
		var piece_box := BoxShape3D.new()
		piece_box.size = size
		piece.shape = piece_box
		piece.position = Vector3((rect.x + rect.y) * 0.5, -top, (rect.z + rect.w) * 0.5)
		body.add_child(piece)

## Malha da bacia: areia seca na beirada, areia molhada na linha d'água e lodo no
## fundo, tudo em cor de vértice para o material continuar sendo o do chão.
static func _pond_bed(center: Vector3, radius: float, depth: float, half: float,
		grass: Color, ground_size: float) -> ArrayMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2(half * 2.0, half * 2.0)
	plane.subdivide_width = 44
	plane.subdivide_depth = 44
	plane.center_offset = Vector3(center.x, 0.0, center.z)
	var arrays := plane.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var colors := PackedColorArray()
	colors.resize(verts.size())
	var dry := Color("#c9bb90")
	var sand := Color("#d6c39b")
	var wet := Color("#9f8c6c")
	var silt := Color("#6b6150")
	for i in verts.size():
		var point := verts[i]
		var delta := Vector2(point.x - center.x, point.z - center.z)
		var distance := delta.length()
		var height := _pond_height(distance, radius, depth)
		verts[i] = Vector3(point.x, height, point.z)
		var normal := Vector3.UP
		if distance < radius and distance > 0.001:
			var t := 1.0 - distance / radius
			var slope := -6.0 * depth * t * (1.0 - t) / radius
			var direction := delta / distance
			normal = Vector3(-slope * direction.x, 1.0, -slope * direction.y).normalized()
		normals[i] = normal
		var drop := POND_LIP - height
		var tone := 0.97 + sin(point.x * 1.7 + point.z * 0.9) * 0.02
		var color := grass.lerp(dry, smoothstep(0.01, 0.05, drop))
		color = color.lerp(sand, smoothstep(0.04, 0.1, drop))
		color = color.lerp(wet, smoothstep(POND_WATERLINE - 0.02, POND_WATERLINE + 0.08, drop))
		color = color.lerp(silt, smoothstep(0.6, 1.0, drop))
		colors[i] = Color(color.r * tone, color.g * tone, color.b * tone)
		uvs[i] = Vector2((point.x + ground_size * 0.5) / ground_size,
			(point.z + ground_size * 0.5) / ground_size)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, Props.pond_mat())
	return mesh

## Beira da lagoa: juncos em touceiras dentro da água rasa, pedras na areia e
## vitórias-régias boiando. Nada disso precisa de colisor — o jogador atravessa.
static func _pond_shore(root: Node3D, center: Vector3, radius: float, depth: float,
		water_radius: float, water_y: float) -> void:
	var reeds := Node3D.new()
	reeds.name = "PondReeds"
	root.add_child(reeds)
	# juncos crescem em touceiras, não em círculo: cada grupo ocupa um trecho da beira
	var clumps := 5
	for i in clumps:
		var base_angle := TAU * (float(i) + randf_range(-0.15, 0.15)) / float(clumps)
		for j in randi_range(3, 5):
			var angle := base_angle + randf_range(-0.28, 0.28)
			var distance := radius * randf_range(0.72, 0.9)
			var spot := Vector3(center.x + cos(angle) * distance, 0.0, center.z + sin(angle) * distance)
			spot.y = _pond_height(distance, radius, depth)
			var reed := Props.reed(randf_range(0.7, 1.35))
			reed.position = spot
			reeds.add_child(reed)
	var stones := Node3D.new()
	stones.name = "PondStones"
	root.add_child(stones)
	for i in 10:
		var angle := TAU * randf_range(0.0, 1.0)
		var distance := radius * randf_range(0.95, 1.1)
		var spot := Vector3(center.x + cos(angle) * distance, 0.0, center.z + sin(angle) * distance)
		spot.y = _pond_height(distance, radius, depth)
		var stone := Props.rock(randf_range(0.22, 0.45))
		stone.position = spot
		stones.add_child(stone)
	for i in 22:
		var angle := TAU * float(i) / 22.0 + randf_range(-0.12, 0.12)
		var distance := radius * randf_range(0.9, 1.08)
		var spot := Vector3(center.x + cos(angle) * distance, 0.0, center.z + sin(angle) * distance)
		spot.y = _pond_height(distance, radius, depth)
		var pebble := Props.rock(randf_range(0.1, 0.2))
		pebble.position = spot
		stones.add_child(pebble)
	for i in 5:
		var angle := TAU * (float(i) + 0.3) / 5.0
		var distance := water_radius * randf_range(0.25, 0.75)
		var pad := Props.lily_pad(randf_range(0.16, 0.26))
		pad.position = Vector3(center.x + cos(angle) * distance, water_y + 0.012,
			center.z + sin(angle) * distance)
		root.add_child(pad)

## Chão rente ao chão, com a opção de manter um círculo livre (a lagoa):
## `avoid` traz (x, z, raio) e nada de capim nasce lá dentro.
static func ground_cover(root: Node3D, color: Color, count := 120, radius := 26.0,
		min_height := 0.16, max_height := 0.4, avoid := Vector3.ZERO) -> void:
	var blade := Props.cylinder_mesh(0.0, 0.022, 1.0, 4)
	var batches: Array = [[], [], []]
	var keep_clear := Vector2(0.0, 15.0)
	for i in count:
		var angle := randf_range(0.0, TAU)
		var distance := sqrt(randf()) * radius
		var spot := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		if Vector2(spot.x, spot.z).distance_to(keep_clear) < 3.5:
			continue
		if avoid.z > 0.0 and Vector2(spot.x - avoid.x, spot.z - avoid.y).length() < avoid.z:
			continue
		var blades := randi_range(5, 8)
		for b in blades:
			var lean := randf_range(0.06, 0.2)
			var heading := randf_range(0.0, TAU)
			var height := randf_range(min_height, max_height)
			var start := spot + Vector3(randf_range(-0.12, 0.12), 0.0, randf_range(-0.12, 0.12))
			var end := start + Vector3(cos(heading) * lean, height, sin(heading) * lean)
			batches[i % 3].append([blade, Props.segment_xf(start, end)])
	for i in 3:
		var batch := Props.add_merged(root, batches[i], Props.leaf_mat(color.lightened(-0.03 + i * 0.03)), "Cover%d" % i)
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func hills(root: Node3D, base_color: Color, count := 14, radius_min := 45.0, radius_max := 75.0,
		tree_style := "mixed") -> void:
	for i in count:
		var angle := TAU * float(i) / float(count) + randf_range(-0.12, 0.12)
		var distance := randf_range(radius_min, radius_max)
		var hill := Node3D.new()
		hill.name = "Hill%d" % i
		hill.position = Vector3(cos(angle) * distance, -2.0, sin(angle) * distance)
		var sx := randf_range(10.0, 20.0)
		var sy := randf_range(5.0, 12.0)
		var sz := randf_range(10.0, 20.0)
		var tone := base_color.lightened(randf_range(-0.07, 0.09))
		Props.part(hill, Props.organic_mesh(1.0, 26, 16, 0.22, 1.5, 40 + i), Props.terrain_mat(tone),
			Vector3.ZERO, Vector3(0, randf_range(0, 360), 0), Vector3(sx, sy, sz))
		# pedras e árvores no pé da encosta quebram o contorno liso
		var outcrop: Array = []
		var rock_mesh := Props.organic_mesh(1.0, 10, 7, 0.34, 2.0, 90 + i)
		for r in 3:
			var rock_angle := randf_range(0.0, TAU)
			var reach := randf_range(0.72, 0.92)
			var size := randf_range(0.05, 0.1)
			outcrop.append([rock_mesh, Props.xf(
				Vector3(cos(rock_angle) * reach, randf_range(0.05, 0.16), sin(rock_angle) * reach),
				Vector3(0, randf_range(0.0, 360.0), 0), Vector3(size, size * 0.8, size))])
		var rocks := Props.add_merged(hill, outcrop, Props.stone_mat(base_color.darkened(0.18)), "Outcrops")
		rocks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Silhueta de mata na encosta: copas fundidas, 3 draw calls no morro.
		var trunks: Array = []
		var needles: Array = []
		var leaves: Array = []
		var cone := Props.cylinder_mesh(0.0, 1.0, 1.0, 7)
		var crown := Props.sphere_mesh(1.0, 9, 6)
		var frond := Props.box_mesh(Vector3(1.0, 0.02, 0.2))
		var trunk_mesh := Props.cylinder_mesh(0.07, 0.1, 1.0, 5)
		var trees := 0 if tree_style == "none" else randi_range(8, 14)
		for t in trees:
			var tree_angle := randf_range(0.0, TAU)
			var reach := randf_range(0.42, 0.9)
			var height_on_hill := sy * sqrt(maxf(0.0, 1.0 - reach * reach)) * 0.92
			var spot := Vector3(cos(tree_angle) * reach * sx, height_on_hill - 0.4, sin(tree_angle) * reach * sz)
			var tree_height := randf_range(3.2, 7.0)
			var tree_width := tree_height * randf_range(0.3, 0.42)
			trunks.append([trunk_mesh, Props.xf(spot + Vector3.UP * (tree_height * 0.2),
				Vector3.ZERO, Vector3(1.0, tree_height * 0.45, 1.0))])
			if tree_style == "palm":
				var crown_spot := spot + Vector3.UP * (tree_height * 0.92)
				for f in 7:
					var yaw := TAU * float(f) / 7.0 + randf_range(-0.12, 0.12)
					var reach_leaf := randf_range(1.1, 1.7)
					leaves.append([frond, Props.xf(
						crown_spot + Vector3(cos(yaw) * reach_leaf * 0.5, -0.18, sin(yaw) * reach_leaf * 0.5),
						Vector3(0, -rad_to_deg(yaw), randf_range(-26.0, -14.0)),
						Vector3(reach_leaf, 1.0, randf_range(0.8, 1.2)))])
			elif randf() < 0.3:
				# folhosa: duas copas arredondadas em vez do cone do pinheiro
				leaves.append([crown, Props.xf(spot + Vector3.UP * (tree_height * 0.55),
					Vector3.ZERO, Vector3(tree_width, tree_height * 0.34, tree_width))])
				leaves.append([crown, Props.xf(spot + Vector3.UP * (tree_height * 0.76) +
					Vector3(tree_width * 0.3, 0, tree_width * 0.2), Vector3.ZERO,
					Vector3(tree_width * 0.66, tree_height * 0.24, tree_width * 0.66))])
			else:
				needles.append([cone, Props.xf(spot + Vector3.UP * (tree_height * 0.5),
					Vector3.ZERO, Vector3(tree_width, tree_height * 0.7, tree_width))])
				needles.append([cone, Props.xf(spot + Vector3.UP * (tree_height * 0.88),
					Vector3.ZERO, Vector3(tree_width * 0.68, tree_height * 0.48, tree_width * 0.68))])
		if not trunks.is_empty():
			Props.add_merged(hill, trunks, Props.bark_mat(Color("#5d4630")), "HillTrunks")
			if not needles.is_empty():
				var needles_mesh := Props.add_merged(hill, needles,
					Props.leaf_mat(base_color.lerp(Color("#3f6d42"), 0.62)), "HillPines")
				needles_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not leaves.is_empty():
				var leaves_mesh := Props.add_merged(hill, leaves,
					Props.leaf_mat(base_color.lerp(Color("#4f8a3e"), 0.5)), "HillCrowns")
				leaves_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape_node := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = minf(sx, sz) * 0.85
		cylinder.height = sy * 1.9
		shape_node.shape = cylinder
		body.add_child(shape_node)
		hill.add_child(body)
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
