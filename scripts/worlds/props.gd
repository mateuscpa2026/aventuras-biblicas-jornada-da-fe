class_name Props
## Construtor de cenário procedural: árvores, casas, arca, poço, alvos etc.
## Tudo é feito com malhas primitivas e materiais compartilhados (baixo custo).
## Para trocar por modelos finais, substitua as funções por instâncias de .glb.

static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}
static var _grain: Dictionary = {}

# ---------------------------------------------------------------- materiais

static func mat(color: Color, roughness := 0.9, emission := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%.2f" % [color.to_html(true), roughness, emission, alpha]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = 0.0
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = alpha
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = m
	return m

static func fabric_mat(color: Color, roughness := 0.94) -> StandardMaterial3D:
	var key := "fabric|%s|%.2f" % [color.to_html(true), roughness]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("fabric", 0.055, 118, 0.84, 1.0)
	m.roughness = roughness
	m.metallic = 0.0
	m.uv1_scale = Vector3(3.0, 3.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = m
	return m

static func fur_mat(color: Color, roughness := 1.0) -> StandardMaterial3D:
	var key := "fur|%s|%.2f" % [color.to_html(true), roughness]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("fur", 0.16, 41, 0.80, 1.0)
	m.roughness = roughness
	m.metallic = 0.0
	m.uv1_scale = Vector3(4.0, 4.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = m
	return m

static func _grain_texture(kind: String, frequency: float, noise_seed: int,
		low: float, high: float) -> NoiseTexture2D:
	if _grain.has(kind):
		return _grain[kind]
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	noise.fractal_octaves = 3
	noise.seed = noise_seed
	var ramp := Gradient.new()
	ramp.set_color(0, Color(low, low, low))
	ramp.set_color(1, Color(high, high, high))
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	texture.color_ramp = ramp
	_grain[kind] = texture
	return texture

static func unshaded(color: Color, emission := 1.0) -> StandardMaterial3D:
	var key := "unshaded|%s|%.2f" % [color.to_html(true), emission]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = emission
	_materials[key] = m
	return m

static func leaf_mat(color: Color) -> StandardMaterial3D:
	var key := "leaf|%s" % color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("leaf", 0.075, 173, 0.74, 1.0)
	m.roughness = 0.92
	m.metallic = 0.0
	m.uv1_scale = Vector3(2.4, 2.4, 2.4)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.backlight_enabled = true
	m.backlight = color.lightened(0.18)
	_materials[key] = m
	return m

static func bark_mat(color: Color) -> StandardMaterial3D:
	var key := "bark|%s" % color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("bark", 0.035, 89, 0.66, 1.0)
	m.roughness = 1.0
	m.metallic = 0.0
	m.uv1_scale = Vector3(7.0, 1.4, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = m
	return m

static func stone_mat(color: Color) -> StandardMaterial3D:
	var key := "stone|%s" % color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("stone", 0.11, 61, 0.72, 1.0)
	m.roughness = 0.95
	m.metallic = 0.0
	m.uv1_scale = Vector3(2.6, 2.6, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = m
	return m

static func skin_mat(color: Color) -> StandardMaterial3D:
	var key := "skin|%s" % color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("skin", 0.045, 209, 0.95, 1.0)
	m.roughness = 0.66
	m.metallic = 0.0
	m.uv1_scale = Vector3(2.2, 2.2, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = m
	return m

static func ground_mat(color: Color) -> StandardMaterial3D:
	var key := "ground|%s" % color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	# contraste baixo: evita o aspecto de "mármore" no chão grande
	m.albedo_texture = _grain_texture("ground", 0.07, 301, 0.86, 1.0)
	m.roughness = 1.0
	m.metallic = 0.0
	m.uv1_scale = Vector3(78.0, 78.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.normal_enabled = true
	m.normal_texture = _ground_normal()
	m.normal_scale = 0.38
	m.uv1_triplanar = false
	_materials[key] = m
	return m

static func hair_mat(color: Color) -> StandardMaterial3D:
	var key := "hair|%s" % color.to_html(true)
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _grain_texture("hair", 0.22, 233, 0.78, 1.0)
	m.roughness = 0.82
	m.metallic = 0.0
	# textura alongada na vertical lê como fios de cabelo
	m.uv1_scale = Vector3(7.0, 2.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = m
	return m

static func _ground_normal() -> NoiseTexture2D:
	if _grain.has("ground_normal"):
		return _grain["ground_normal"]
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	noise.fractal_octaves = 4
	noise.seed = 411
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.as_normal_map = true
	texture.bump_strength = 3.0
	texture.noise = noise
	_grain["ground_normal"] = texture
	return texture

# ---------------------------------------------------------------- malhas

static func sphere_mesh(radius := 1.0, segments := 12, rings := 6) -> SphereMesh:
	var key := "s|%.3f|%d|%d" % [radius, segments, rings]
	if _meshes.has(key):
		return _meshes[key]
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = segments
	m.rings = rings
	_meshes[key] = m
	return m

static func box_mesh(size: Vector3) -> BoxMesh:
	var key := "b|%s" % str(size)
	if _meshes.has(key):
		return _meshes[key]
	var m := BoxMesh.new()
	m.size = size
	_meshes[key] = m
	return m

static func cylinder_mesh(top_radius: float, bottom_radius: float, height: float, segments := 12) -> CylinderMesh:
	var key := "c|%.3f|%.3f|%.3f|%d" % [top_radius, bottom_radius, height, segments]
	if _meshes.has(key):
		return _meshes[key]
	var m := CylinderMesh.new()
	m.top_radius = top_radius
	m.bottom_radius = bottom_radius
	m.height = height
	m.radial_segments = segments
	m.rings = 2
	_meshes[key] = m
	return m

static func capsule_mesh(height := 0.5, radius := 0.12, segments := 8) -> CapsuleMesh:
	var key := "k|%.3f|%.3f|%d" % [height, radius, segments]
	if _meshes.has(key):
		return _meshes[key]
	var m := CapsuleMesh.new()
	m.height = height
	m.radius = radius
	m.radial_segments = segments
	m.rings = 3
	_meshes[key] = m
	return m

static func torus_mesh(inner_radius: float, outer_radius: float, rings := 24, ring_segments := 8) -> TorusMesh:
	var key := "t|%.3f|%.3f|%d|%d" % [inner_radius, outer_radius, rings, ring_segments]
	if _meshes.has(key):
		return _meshes[key]
	var m := TorusMesh.new()
	m.inner_radius = inner_radius
	m.outer_radius = outer_radius
	m.rings = rings
	m.ring_segments = ring_segments
	_meshes[key] = m
	return m

# ---------------------------------------------------------------- helpers

static func xf(position: Vector3, rotation_deg := Vector3.ZERO, scale := Vector3.ONE) -> Transform3D:
	var basis := Basis.from_euler(Vector3(deg_to_rad(rotation_deg.x),
		deg_to_rad(rotation_deg.y), deg_to_rad(rotation_deg.z)))
	return Transform3D(basis * Basis.from_scale(scale), position)

static func segment_xf(start: Vector3, end: Vector3, thickness := 1.0) -> Transform3D:
	var direction := end - start
	var length := direction.length()
	if length < 0.001:
		return Transform3D(Basis.IDENTITY, start)
	var basis := Basis(Quaternion(Vector3.UP, direction / length)) * Basis.from_scale(Vector3(thickness, length, thickness))
	return Transform3D(basis, (start + end) * 0.5)

static func add_merged(root: Node3D, parts: Array, material: Material, node_name := "") -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for item in parts:
		var mesh: Mesh = item[0]
		var xform: Transform3D = item[1]
		for surface in mesh.get_surface_count():
			builder.append_from(mesh, surface, xform)
	var merged := builder.commit()
	var instance := MeshInstance3D.new()
	instance.mesh = merged
	instance.material_override = material
	if node_name != "":
		instance.name = node_name
	root.add_child(instance)
	return instance

static func part(parent: Node3D, mesh: Mesh, material: Material, position := Vector3.ZERO,
		rotation_deg := Vector3.ZERO, scale := Vector3.ONE, node_name := "") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation_degrees = rotation_deg
	instance.scale = scale
	if node_name != "":
		instance.name = node_name
	parent.add_child(instance)
	return instance

static func collider_box(parent: Node3D, size: Vector3, position := Vector3.ZERO, rotation_deg := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = position
	shape.rotation_degrees = rotation_deg
	body.add_child(shape)
	parent.add_child(body)
	return body

static func collider_cylinder(parent: Node3D, radius: float, height: float, position := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	shape.position = position
	body.add_child(shape)
	parent.add_child(body)
	return body

static func marker(parent: Node3D, position: Vector3, node_name := "Marker") -> Node3D:
	var node := Node3D.new()
	node.name = node_name
	node.position = position
	parent.add_child(node)
	return node

# ---------------------------------------------------------------- vegetação

static func tree(scale_factor := 1.0, leaf_color := Color("#4f9a54"), trunk_color := Color("#7a5230")) -> Node3D:
	var root := Node3D.new()
	root.name = "Tree"
	var trunk_parts: Array = []
	var dark: Array = []
	var base: Array = []
	var light: Array = []

	trunk_parts.append([cylinder_mesh(0.17, 0.27, 1.35, 12), xf(Vector3(0, 0.67, 0))])
	trunk_parts.append([cylinder_mesh(0.135, 0.175, 1.15, 12),
		xf(Vector3(0.05, 1.9, 0.01), Vector3(0, 0, -2.5))])
	trunk_parts.append([cylinder_mesh(0.095, 0.14, 1.0, 10),
		xf(Vector3(0.12, 2.95, -0.02), Vector3(0, 0, -4))])
	for i in 4:
		var angle := TAU * float(i) / 4.0 + 0.55
		trunk_parts.append([sphere_mesh(0.22, 8, 5),
			xf(Vector3(cos(angle) * 0.22, 0.09, sin(angle) * 0.22),
				Vector3(0, rad_to_deg(angle), 0), Vector3(1.55, 0.45, 0.55))])
	var branch_base := Vector3(0.12, 2.55, 0)
	for end in [Vector3(1.05, 3.75, 0.2), Vector3(-0.95, 3.6, 0.35), Vector3(0.2, 3.85, -1.0),
			Vector3(-0.15, 3.55, 1.0), Vector3(0.75, 3.05, -0.7), Vector3(-0.7, 3.15, -0.65)]:
		trunk_parts.append([cylinder_mesh(0.04, 0.085, 1.0, 7), segment_xf(branch_base, end)])
	add_merged(root, trunk_parts, bark_mat(trunk_color), "Bark")

	var crown := [
		[Vector3(0.1, 4.55, 0.0), Vector3(1.35, 1.0, 1.25)],
		[Vector3(1.05, 4.15, 0.25), Vector3(1.05, 0.85, 1.0)],
		[Vector3(-0.85, 4.2, 0.35), Vector3(1.0, 0.8, 0.95)],
		[Vector3(0.25, 4.1, -1.0), Vector3(0.95, 0.8, 1.05)],
		[Vector3(-0.1, 4.0, 1.05), Vector3(1.0, 0.85, 0.9)],
		[Vector3(1.25, 3.65, -0.35), Vector3(0.8, 0.65, 0.85)],
		[Vector3(-1.15, 3.7, -0.3), Vector3(0.85, 0.6, 0.8)],
		[Vector3(0.55, 3.55, 0.9), Vector3(0.8, 0.65, 0.8)],
		[Vector3(-0.5, 3.6, -0.85), Vector3(0.75, 0.6, 0.8)],
		[Vector3(0.0, 3.45, 0.0), Vector3(1.15, 0.65, 1.1)],
		[Vector3(0.75, 4.7, -0.5), Vector3(0.75, 0.6, 0.7)],
		[Vector3(-0.6, 4.65, 0.55), Vector3(0.7, 0.55, 0.65)],
	]
	var sphere := sphere_mesh(1.0, 12, 8)
	for i in crown.size():
		var spot: Vector3 = crown[i][0]
		var size: Vector3 = crown[i][1]
		var target: Array = dark if i == 9 else base
		if i == 0 or i == 10 or i == 11:
			target = light
		target.append([sphere, xf(spot, Vector3(randf_range(-8, 8), randf_range(0, 360),
			randf_range(-8, 8)), size)])
	for i in 10:
		var angle := TAU * float(i) / 10.0 + 0.25
		var radius := randf_range(1.25, 1.7)
		var spot := Vector3(cos(angle) * radius, randf_range(3.55, 4.35), sin(angle) * radius)
		var puff := randf_range(0.3, 0.48)
		var target: Array = light if i % 2 == 0 else dark
		target.append([sphere, xf(spot, Vector3.ZERO, Vector3(puff, puff * 0.8, puff))])
	add_merged(root, dark, leaf_mat(leaf_color.darkened(0.14)), "LeavesDark")
	add_merged(root, base, leaf_mat(leaf_color), "Leaves")
	add_merged(root, light, leaf_mat(leaf_color.lightened(0.1)), "LeavesLight")

	collider_cylinder(root, 0.34, 2.8, Vector3(0, 1.4, 0))
	root.scale = Vector3.ONE * scale_factor
	return root

static func pine(scale_factor := 1.0, leaf_color := Color("#3f7d55")) -> Node3D:
	var root := Node3D.new()
	root.name = "Pine"
	var trunk_parts: Array = []
	var dark: Array = []
	var base: Array = []
	var light: Array = []

	trunk_parts.append([cylinder_mesh(0.15, 0.24, 1.8, 10), xf(Vector3(0, 0.9, 0))])
	trunk_parts.append([cylinder_mesh(0.08, 0.15, 3.6, 9), xf(Vector3(0, 3.0, 0))])
	for i in 3:
		var angle := TAU * float(i) / 3.0 + 0.4
		trunk_parts.append([sphere_mesh(0.2, 7, 4),
			xf(Vector3(cos(angle) * 0.2, 0.07, sin(angle) * 0.2),
				Vector3(0, rad_to_deg(angle), 0), Vector3(1.6, 0.4, 0.55))])
	add_merged(root, trunk_parts, bark_mat(Color("#6b4a2c")), "Bark")

	var spray := sphere_mesh(1.0, 10, 6)
	var core := cylinder_mesh(0.0, 1.0, 1.0, 12)
	var tiers := 7
	for i in tiers:
		var t := float(i) / float(tiers - 1)
		var y := lerpf(1.45, 4.55, t)
		var radius := lerpf(1.5, 0.34, pow(t, 0.9))
		var target: Array = base
		if t < 0.35:
			target = dark
		elif t > 0.7:
			target = light
		target.append([core, xf(Vector3(0, y, 0), Vector3.ZERO,
			Vector3(radius * 0.58, 0.62, radius * 0.58))])
		var sprays := 7 - int(t * 3.0)
		for s in sprays:
			var angle := TAU * float(s) / float(sprays) + i * 0.55
			var tilt := -10.0 - t * 6.0
			target.append([spray, xf(Vector3(cos(angle) * radius * 0.52, y - 0.12,
				sin(angle) * radius * 0.52), Vector3(tilt, rad_to_deg(angle) + 90.0, 0),
				Vector3(radius * 0.55, 0.11, radius * 0.2))])
			target.append([spray, xf(Vector3(cos(angle) * radius * 0.9, y - 0.3,
				sin(angle) * radius * 0.9), Vector3(-16, rad_to_deg(angle) + 90.0, 0),
				Vector3(radius * 0.32, 0.08, radius * 0.16))])
	for i in 2:
		var cone := cylinder_mesh(0.0, 0.26 - i * 0.09, 0.7 - i * 0.12, 10)
		light.append([cone, xf(Vector3(0, 4.9 + i * 0.4, 0))])
	add_merged(root, dark, leaf_mat(leaf_color.darkened(0.16)), "NeedlesDark")
	add_merged(root, base, leaf_mat(leaf_color), "Needles")
	add_merged(root, light, leaf_mat(leaf_color.lightened(0.12)), "NeedlesLight")

	collider_cylinder(root, 0.3, 3.2, Vector3(0, 1.6, 0))
	root.scale = Vector3.ONE * scale_factor
	return root

static func palm(scale_factor := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Palm"
	var bark: Array = []
	var green: Array = []
	var green_light: Array = []

	var points: Array[Vector3] = []
	for i in 9:
		var t := float(i) / 8.0
		points.append(Vector3(0.6 * t * t, 4.15 * t, 0.1 * sin(t * 2.4)))
	for i in points.size() - 1:
		var t0 := float(i) / 8.0
		var t1 := float(i + 1) / 8.0
		bark.append([cylinder_mesh(0.14 - 0.055 * t1, 0.155 - 0.055 * t0, 1.0, 10),
			segment_xf(points[i], points[i + 1])])
		bark.append([cylinder_mesh(0.163 - 0.055 * t1, 0.163 - 0.055 * t1, 0.045, 10),
			xf(points[i + 1], Vector3.ZERO)])
	for i in 4:
		var angle := TAU * float(i) / 4.0 + 0.3
		bark.append([sphere_mesh(0.19, 7, 4),
			xf(Vector3(cos(angle) * 0.15, 0.07, sin(angle) * 0.15),
				Vector3(0, rad_to_deg(angle), 0), Vector3(1.4, 0.4, 0.5))])
	add_merged(root, bark, bark_mat(Color("#96704a")), "Bark")

	var crown: Vector3 = points[points.size() - 1]
	var leaflet := box_mesh(Vector3(0.055, 0.014, 1.0))
	var rachis := cylinder_mesh(0.018, 0.034, 1.0, 6)
	for f in 9:
		var yaw := TAU * float(f) / 9.0 + randf_range(-0.09, 0.09)
		var length := randf_range(1.6, 1.95)
		var lift := randf_range(0.15, 0.5)
		var dir := Vector3(sin(yaw), 0, cos(yaw))
		var side := Vector3(cos(yaw), 0, -sin(yaw))
		var previous := crown
		for s in 6:
			var t: float = float(s + 1) / 6.0
			var point := crown + dir * length * t + Vector3.UP * (lift * sin(t * 2.4) - 0.7 * t * t)
			green.append([rachis, segment_xf(previous, point)])
			previous = point
			var leaflet_length := lerpf(0.46, 0.26, t)
			for side_sign in [-1.0, 1.0]:
				var sign_value := float(side_sign)
				var leaf_yaw := rad_to_deg(yaw) + sign_value * lerpf(46.0, 62.0, t)
				var leaf_pos := point + side * sign_value * leaflet_length * 0.42 + Vector3.UP * (-0.03 - t * 0.05)
				green.append([leaflet, xf(leaf_pos, Vector3(-18.0 - t * 14.0, leaf_yaw, sign_value * -16.0),
					Vector3(1.0, 1.0, leaflet_length))])
		green_light.append([leaflet, xf(previous + dir * 0.18 + Vector3.UP * -0.06,
			Vector3(-28, rad_to_deg(yaw), 0), Vector3(0.9, 1.0, 0.34))])
	add_merged(root, green, leaf_mat(Color("#4e9455")), "Fronds")
	add_merged(root, green_light, leaf_mat(Color("#68ac63")), "FrondTips")

	var nuts: Array = []
	for i in 3:
		var angle := TAU * float(i) / 3.0 + 0.5
		nuts.append([sphere_mesh(0.135, 8, 6),
			xf(crown + Vector3(cos(angle) * 0.16, -0.16 - i * 0.03, sin(angle) * 0.16))])
	add_merged(root, nuts, mat(Color("#7a5230")), "Coconuts")

	collider_cylinder(root, 0.3, 3.1, Vector3(0.2, 1.55, 0))
	root.scale = Vector3.ONE * scale_factor
	return root

static func bush(scale_factor := 1.0, color := Color("#4c8a4f")) -> Node3D:
	var root := Node3D.new()
	root.name = "Bush"
	var dark: Array = []
	var base: Array = []
	var light: Array = []
	var berries: Array = []
	var sphere := sphere_mesh(1.0, 10, 6)
	var spots := [
		[Vector3(0, 0.42, 0), Vector3(0.66, 0.5, 0.6)],
		[Vector3(0.42, 0.38, 0.18), Vector3(0.46, 0.4, 0.45)],
		[Vector3(-0.38, 0.35, -0.2), Vector3(0.42, 0.36, 0.4)],
		[Vector3(0.1, 0.63, -0.12), Vector3(0.4, 0.36, 0.38)],
		[Vector3(-0.18, 0.55, 0.3), Vector3(0.36, 0.32, 0.34)],
		[Vector3(0.5, 0.24, -0.22), Vector3(0.32, 0.26, 0.3)],
		[Vector3(-0.52, 0.22, 0.24), Vector3(0.3, 0.24, 0.28)],
		[Vector3(0.02, 0.2, 0.38), Vector3(0.34, 0.26, 0.3)],
	]
	for i in spots.size():
		var target: Array = base
		if i >= 5:
			target = dark
		elif i == 3:
			target = light
		target.append([sphere, xf(spots[i][0], Vector3(0, randf_range(0, 360), 0), spots[i][1])])
	for i in 5:
		var angle := TAU * float(i) / 5.0 + 0.6
		var berry := randf_range(0.03, 0.045)
		berries.append([sphere, xf(Vector3(cos(angle) * 0.4, randf_range(0.35, 0.62),
			sin(angle) * 0.34), Vector3.ZERO, Vector3(berry, berry, berry))])
	add_merged(root, dark, leaf_mat(color.darkened(0.16)), "BushDark")
	add_merged(root, base, leaf_mat(color), "Bush")
	add_merged(root, light, leaf_mat(color.lightened(0.12)), "BushLight")
	add_merged(root, berries, mat(Color("#b85f45"), 0.55, 0.1), "Berries")
	root.scale = Vector3.ONE * scale_factor
	return root

static func flower_patch(color := Color("#f2b544"), scale_factor := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Flowers"
	var stems: Array = []
	var petals: Array = []
	var centers: Array = []
	var stem_mesh := cylinder_mesh(0.012, 0.018, 1.0, 5)
	var leaf_mesh := sphere_mesh(1.0, 6, 4)
	var petal_mesh := sphere_mesh(1.0, 6, 4)
	for i in 4:
		var center := Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		var height := randf_range(0.32, 0.52)
		stems.append([stem_mesh, segment_xf(center, center + Vector3(randf_range(-0.05, 0.05), height, 0))])
		for leaf_i in 2:
			var angle := leaf_i * PI + randf_range(-0.4, 0.4)
			stems.append([leaf_mesh, xf(center + Vector3(cos(angle) * 0.08, height * 0.4, sin(angle) * 0.08),
				Vector3(-14, rad_to_deg(angle), 0), Vector3(0.11, 0.012, 0.05))])
		var blossom := center + Vector3(0, height, 0)
		for p in 7:
			var angle := TAU * float(p) / 7.0 + i * 0.4
			petals.append([petal_mesh, xf(blossom + Vector3(cos(angle) * 0.085, 0.01, sin(angle) * 0.085),
				Vector3(0, rad_to_deg(angle), 12), Vector3(0.075, 0.02, 0.045))])
		centers.append([petal_mesh, xf(blossom, Vector3.ZERO, Vector3(0.045, 0.03, 0.045))])
	add_merged(root, stems, leaf_mat(Color("#4f8b4c")), "Stems")
	add_merged(root, petals, leaf_mat(color), "Petals")
	add_merged(root, centers, mat(Color("#f7d35c"), 0.8, 0.1), "Centers")
	root.scale = Vector3.ONE * scale_factor
	return root

static func grass_tuft(scale_factor := 1.0, color := Color("#5d9b52")) -> Node3D:
	var root := Node3D.new()
	root.name = "Grass"
	var blades: Array = []
	var blade := cylinder_mesh(0.0, 0.028, 1.0, 5)
	for i in 9:
		var angle := TAU * float(i) / 9.0 + randf_range(-0.2, 0.2)
		var radius := randf_range(0.02, 0.13)
		var height := randf_range(0.32, 0.58)
		var start := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var end := start + Vector3(cos(angle) * 0.12, height, sin(angle) * 0.12)
		blades.append([blade, segment_xf(start, end)])
	add_merged(root, blades, leaf_mat(color), "Blades")
	root.scale = Vector3.ONE * scale_factor
	return root

static func rock(scale_factor := 1.0, color := Color("#8d8b83")) -> Node3D:
	var root := Node3D.new()
	root.name = "Rock"
	var stone: Array = []
	var moss: Array = []
	var sphere := sphere_mesh(1.0, 9, 6)
	stone.append([sphere, xf(Vector3(0, 0.34, 0), Vector3(randf_range(-8, 8), randf_range(0, 360), 0),
		Vector3(0.95, 0.62, 0.8))])
	for i in 4:
		var angle := TAU * float(i) / 4.0 + 0.35
		var size := randf_range(0.3, 0.46)
		stone.append([sphere, xf(Vector3(cos(angle) * 0.5, size * 0.45, sin(angle) * 0.4),
			Vector3(randf_range(-12, 12), randf_range(0, 360), 0), Vector3(size, size * 0.65, size * 0.9))])
	moss.append([sphere, xf(Vector3(-0.25, 0.58, 0.15), Vector3.ZERO, Vector3(0.42, 0.08, 0.34))])
	moss.append([sphere, xf(Vector3(0.38, 0.3, 0.28), Vector3.ZERO, Vector3(0.22, 0.05, 0.2))])
	add_merged(root, stone, stone_mat(color), "Stone")
	add_merged(root, moss, leaf_mat(color.lerp(Color("#6f9450"), 0.6)), "Moss")
	root.scale = Vector3.ONE * scale_factor
	collider_cylinder(root, 0.62, 0.8, Vector3(0, 0.4, 0))
	return root

# ---------------------------------------------------------------- construções

static func fence(length := 6.0, color := Color("#a8794b")) -> Node3D:
	var root := Node3D.new()
	root.name = "Fence"
	var posts := int(length / 1.5) + 1
	for i in posts:
		part(root, box_mesh(Vector3(0.14, 1.0, 0.14)), mat(color.darkened(0.1)),
			Vector3(-length * 0.5 + i * (length / maxf(1.0, posts - 1.0)), 0.5, 0))
	for y in [0.35, 0.72]:
		part(root, box_mesh(Vector3(length, 0.1, 0.08)), mat(color), Vector3(0, y, 0))
	collider_box(root, Vector3(length, 1.0, 0.2), Vector3(0, 0.5, 0))
	return root

static func house(width := 4.4, height := 2.7, depth := 3.8,
		wall := Color("#f0dfba"), roof := Color("#b8644a")) -> Node3D:
	var root := Node3D.new()
	root.name = "House"
	part(root, box_mesh(Vector3(width, height, depth)), mat(wall), Vector3(0, height * 0.5, 0))
	var half_w := width * 0.5
	var angle := 34.0
	var slab_len := (half_w + 0.35) / cos(deg_to_rad(angle))
	var roof_y := height + sin(deg_to_rad(angle)) * slab_len * 0.5 - 0.05
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(slab_len, 0.16, depth + 0.6)), mat(roof),
			Vector3(side * (half_w + 0.05) * 0.5, roof_y, 0), Vector3(0, 0, -side * angle))
	var door := Vector3(width * 0.18, height * 0.42, 0.08)
	part(root, box_mesh(door), mat(Color("#7a5230")), Vector3(0, door.y * 0.5, depth * 0.5 + 0.04))
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(0.5, 0.55, 0.08)), mat(Color("#f7d98b"), 0.7, 0.35),
			Vector3(side * width * 0.28, height * 0.6, depth * 0.5 + 0.04))
		part(root, box_mesh(Vector3(0.62, 0.08, 0.16)), mat(Color("#8a5a3a")), Vector3(side * width * 0.28, height * 0.6 - 0.33, depth * 0.5 + 0.08))
	part(root, box_mesh(Vector3(0.55, 1.2, 0.55)), mat(Color("#9c6a4b")), Vector3(width * 0.3, height + 1.0, -depth * 0.2))
	collider_box(root, Vector3(width, height, depth), Vector3(0, height * 0.5, 0))
	return root

static func tent(color := Color("#c9a06a"), pole_color := Color("#7a5230")) -> Node3D:
	var root := Node3D.new()
	root.name = "Tent"
	part(root, cylinder_mesh(0.08, 2.0, 2.3, 8), mat(color), Vector3(0, 1.15, 0))
	part(root, box_mesh(Vector3(0.85, 1.15, 0.12)), mat(color.darkened(0.28)), Vector3(0, 0.58, 1.1))
	part(root, cylinder_mesh(0.05, 0.05, 2.9, 6), mat(pole_color), Vector3(0, 1.45, 0))
	part(root, box_mesh(Vector3(0.7, 0.5, 0.05)), mat(color.lightened(0.15)), Vector3(0.38, 2.6, 0))
	collider_cylinder(root, 1.2, 2.0, Vector3(0, 1.0, 0))
	return root

static func stall(a := Color("#d9694f"), b := Color("#f2e3c6")) -> Node3D:
	var root := Node3D.new()
	root.name = "Stall"
	var wood := Color("#9c6a4b")
	for x in [-1.3, 1.3]:
		for z in [-0.9, 0.9]:
			part(root, box_mesh(Vector3(0.14, 2.4, 0.14)), mat(wood), Vector3(x, 1.2, z))
	part(root, box_mesh(Vector3(3.0, 0.16, 1.8)), mat(Color("#b98a62")), Vector3(0, 1.0, 0))
	for i in 8:
		var color := a if i % 2 == 0 else b
		part(root, box_mesh(Vector3(0.42, 0.08, 2.2)), mat(color),
			Vector3(-1.54 + i * 0.44, 2.55, 0), Vector3(0, 0, 6))
	for i in 3:
		part(root, sphere_mesh(0.12, 6, 4), mat([Color("#e8846b"), Color("#f2b544"), Color("#7fb069")][i]),
			Vector3(-0.7 + i * 0.7, 1.18, 0.2))
	part(root, box_mesh(Vector3(0.9, 0.5, 0.6)), mat(Color("#8a5a3a")), Vector3(1.0, 1.33, 0.1))
	collider_box(root, Vector3(3.0, 1.1, 1.8), Vector3(0, 0.55, 0))
	return root

static func well() -> Node3D:
	var root := Node3D.new()
	root.name = "Well"
	var stone := Color("#9a978d")
	part(root, cylinder_mesh(0.95, 1.0, 0.8, 14), mat(stone), Vector3(0, 0.4, 0))
	part(root, cylinder_mesh(0.72, 0.72, 0.06, 14), mat(Color("#4f7f9a"), 0.15, 0.1, 0.9), Vector3(0, 0.78, 0))
	for x in [-0.8, 0.8]:
		part(root, box_mesh(Vector3(0.14, 2.0, 0.14)), mat(Color("#7a5230")), Vector3(x, 1.6, 0))
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(1.0, 0.12, 1.1)), mat(Color("#b8644a")),
			Vector3(side * 0.42, 2.62, 0), Vector3(0, 0, -side * 32))
	part(root, cylinder_mesh(0.02, 0.02, 1.4, 6), mat(Color("#6b4a2c")), Vector3(0, 2.2, 0), Vector3(0, 0, 90))
	part(root, cylinder_mesh(0.16, 0.13, 0.24, 8), mat(Color("#8a5a3a")), Vector3(0, 1.9, 0))
	collider_cylinder(root, 1.0, 1.0, Vector3(0, 0.5, 0))
	return root

static func crate(color := Color("#b98a62")) -> Node3D:
	var root := Node3D.new()
	root.name = "Crate"
	part(root, box_mesh(Vector3(0.9, 0.9, 0.9)), mat(color), Vector3(0, 0.45, 0))
	for i in 3:
		part(root, box_mesh(Vector3(0.94, 0.1, 0.94)), mat(color.darkened(0.13)), Vector3(0, 0.16 + i * 0.3, 0))
	collider_box(root, Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0))
	return root

static func barrel(color := Color("#a8753f")) -> Node3D:
	var root := Node3D.new()
	root.name = "Barrel"
	part(root, cylinder_mesh(0.34, 0.3, 1.0, 10), mat(color), Vector3(0, 0.5, 0))
	for y in [0.25, 0.75]:
		part(root, cylinder_mesh(0.36, 0.36, 0.08, 10), mat(Color("#6b4a2c")), Vector3(0, y, 0))
	collider_cylinder(root, 0.34, 1.0, Vector3(0, 0.5, 0))
	return root

static func brazier() -> Node3D:
	var root := Node3D.new()
	root.name = "Brazier"
	part(root, cylinder_mesh(0.28, 0.42, 0.9, 10), mat(Color("#7c7061")), Vector3(0, 0.45, 0))
	part(root, cylinder_mesh(0.58, 0.32, 0.35, 10), mat(Color("#5d5347")), Vector3(0, 1.05, 0))
	var flame := Node3D.new()
	flame.name = "Flame"
	root.add_child(flame)
	part(flame, cylinder_mesh(0.0, 0.26, 0.55, 8), unshaded(Color("#ff9a3c")), Vector3(0, 1.45, 0))
	part(flame, sphere_mesh(0.19, 8, 4), unshaded(Color("#ffe28a")), Vector3(0, 1.32, 0))
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 1.7, 0)
	light.light_color = Color("#ffb066")
	light.light_energy = 0.9
	light.omni_range = 5.0
	flame.add_child(light)
	collider_cylinder(root, 0.5, 1.2, Vector3(0, 0.6, 0))
	return root

static func banner(color := Color("#f2b544")) -> Node3D:
	var root := Node3D.new()
	root.name = "Banner"
	part(root, cylinder_mesh(0.05, 0.05, 2.6, 6), mat(Color("#7a5230")), Vector3(0, 1.3, 0))
	part(root, box_mesh(Vector3(0.72, 0.9, 0.04)), mat(color), Vector3(0.4, 2.1, 0))
	part(root, sphere_mesh(0.08, 6, 4), mat(color.lightened(0.2)), Vector3(0, 2.65, 0))
	collider_cylinder(root, 0.08, 2.2, Vector3(0, 1.1, 0))
	return root

static func hay() -> Node3D:
	var root := Node3D.new()
	root.name = "Hay"
	part(root, cylinder_mesh(0.7, 0.75, 0.8, 10), mat(Color("#d9b45c")), Vector3(0, 0.45, 0), Vector3(0, 0, 90))
	part(root, cylinder_mesh(0.7, 0.75, 0.8, 10), mat(Color("#e0bd68")), Vector3(0.4, 0.45, 0.2), Vector3(0, 20, 90))
	collider_cylinder(root, 0.6, 0.8, Vector3(0, 0.4, 0))
	return root

static func ark() -> Node3D:
	var root := Node3D.new()
	root.name = "Ark"
	var wood := Color("#9d6b3f")
	var wood_dark := Color("#7a4f2c")
	part(root, box_mesh(Vector3(12.0, 1.0, 4.6)), mat(wood_dark), Vector3(0, 0.5, 0))
	part(root, box_mesh(Vector3(13.2, 1.1, 5.4)), mat(wood), Vector3(0, 1.4, 0))
	part(root, box_mesh(Vector3(13.8, 0.35, 5.9)), mat(wood_dark), Vector3(0, 2.1, 0))
	for side in [-1, 1]:
		part(root, sphere_mesh(1.0, 10, 6), mat(wood), Vector3(side * 6.6, 1.45, 0), Vector3.ZERO, Vector3(0.75, 1.05, 2.7))
		# amurada
		part(root, box_mesh(Vector3(13.0, 0.14, 0.14)), mat(wood_dark), Vector3(0, 3.1, side * 2.8))
		for i in 7:
			part(root, box_mesh(Vector3(0.12, 1.0, 0.12)), mat(wood_dark), Vector3(-5.4 + i * 1.8, 2.6, side * 2.8))
	part(root, box_mesh(Vector3(6.6, 2.4, 4.3)), mat(wood), Vector3(0, 3.5, 0))
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(4.2, 0.16, 4.8)), mat(wood_dark), Vector3(side * 1.85, 4.95, 0), Vector3(0, 0, -side * 34))
	for i in 3:
		part(root, box_mesh(Vector3(0.7, 0.5, 0.08)), mat(Color("#f7d98b"), 0.7, 0.3), Vector3(-1.7 + i * 1.7, 3.7, -2.18))
	part(root, box_mesh(Vector3(2.0, 2.2, 0.2)), mat(wood_dark), Vector3(0, 2.15, -2.55))
	part(root, box_mesh(Vector3(1.6, 1.9, 0.1)), mat(Color("#5a3a22")), Vector3(0, 2.0, -2.62))
	# rampa de acesso
	part(root, box_mesh(Vector3(2.4, 0.18, 4.6)), mat(wood_dark), Vector3(0, 0.9, -4.6), Vector3(-16, 0, 0))
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(0.12, 0.5, 4.4)), mat(wood), Vector3(side * 1.2, 1.2, -4.6), Vector3(-16, 0, 0))
	# pista de entrega
	marker(root, Vector3(0, 0.1, -4.2), "ArkDoor")
	collider_box(root, Vector3(13.6, 3.2, 5.9), Vector3(0, 1.8, 0))
	return root

static func bridge(length := 6.0, width := 2.2) -> Node3D:
	var root := Node3D.new()
	root.name = "Bridge"
	var wood := Color("#b3855a")
	part(root, box_mesh(Vector3(width, 0.16, length)), mat(wood), Vector3(0, 0.55, 0))
	for i in int(length):
		part(root, box_mesh(Vector3(width, 0.04, 0.12)), mat(wood.darkened(0.08)), Vector3(0, 0.64, -length * 0.5 + 0.5 + i))
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(0.1, 0.1, length)), mat(Color("#8a5a3a")), Vector3(side * width * 0.48, 1.15, 0))
		for i in 3:
			part(root, box_mesh(Vector3(0.1, 0.7, 0.1)), mat(Color("#8a5a3a")),
				Vector3(side * width * 0.48, 0.85, -length * 0.4 + i * length * 0.4))
	collider_box(root, Vector3(width, 0.3, length), Vector3(0, 0.5, 0))
	return root

static func water_disc(radius: float, color := Color("#6fb3c9")) -> Node3D:
	var root := Node3D.new()
	root.name = "Water"
	part(root, cylinder_mesh(radius, radius, 0.06, 32), mat(color, 0.1, 0.15, 0.75), Vector3.ZERO)
	return root

static func water_wall(width: float, height: float, depth: float) -> Node3D:
	var root := Node3D.new()
	root.name = "WaterWall"
	var water := mat(Color("#4f9fd0"), 0.15, 0.25, 0.7)
	part(root, box_mesh(Vector3(width, height, depth)), water, Vector3.ZERO)
	for i in 5:
		part(root, cylinder_mesh(0.0, 0.5 + i * 0.15, 1.0, 7), mat(Color("#d9f2ff"), 0.2, 0.5, 0.8),
			Vector3(randf_range(-width * 0.45, width * 0.45), -height * 0.5 + 0.4, randf_range(-depth * 0.4, depth * 0.4)))
	return root

static func cloud(size := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Cloud"
	var white := unshaded(Color("#ffffff"), 0.35)
	for offset in [Vector3(0, 0, 0), Vector3(1.3, 0.2, 0.2), Vector3(-1.2, 0.1, -0.2), Vector3(0.3, 0.7, 0.1)]:
		var puff := part(root, sphere_mesh(1.0, 8, 5), white, offset, Vector3.ZERO, Vector3(1.3, 0.8, 1.0))
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.scale = Vector3.ONE * size
	return root

static func rain(area := Vector3(40, 10, 40)) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "Rain"
	particles.amount = 420
	particles.lifetime = 1.4
	particles.preprocess = 0.8
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = area * 0.5
	particles.direction = Vector3(0, -1, 0)
	particles.spread = 4.0
	particles.gravity = Vector3(0, -22, 0)
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 14.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	particles.position = Vector3(0, area.y * 0.5 + 6.0, 0)
	var drop := BoxMesh.new()
	drop.size = Vector3(0.03, 0.55, 0.03)
	particles.mesh = drop
	var drop_mat := mat(Color("#cfeaff"), 0.2, 0.1, 0.55)
	particles.material_override = drop_mat
	particles.emitting = false
	return particles

static func fireflies(count := 36, area := Vector3(10, 2.5, 10)) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "Fireflies"
	particles.amount = count
	particles.lifetime = 4.5
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = area * 0.5
	particles.gravity = Vector3(0, 0.05, 0)
	particles.initial_velocity_min = 0.1
	particles.initial_velocity_max = 0.6
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.0
	particles.mesh = sphere_mesh(0.06, 6, 3)
	particles.material_override = unshaded(Color("#fff3a1"), 2.2)
	return particles

static func target_ring(radius := 1.0, color := Color("#f2b544")) -> Node3D:
	var root := Node3D.new()
	root.name = "TargetRing"
	var segments := 14
	for i in segments:
		var angle := TAU * i / segments
		var pos := Vector3(cos(angle) * radius, sin(angle) * radius, 0)
		part(root, box_mesh(Vector3(0.16, 0.28, 0.16)), mat(color, 0.5, 0.25),
			pos, Vector3(0, 0, rad_to_deg(angle) + 90))
	part(root, sphere_mesh(0.16, 8, 4), mat(Color("#f7ead0"), 0.4, 0.2), Vector3.ZERO)
	for side in [-1, 1]:
		part(root, box_mesh(Vector3(0.12, 2.8, 0.12)), mat(Color("#8a5a3a")), Vector3(0, -radius - 1.4, 0.25 + side * 0.12))
	part(root, box_mesh(Vector3(1.8, 0.14, 0.14)), mat(Color("#8a5a3a")), Vector3(0, -radius - 2.7, 0.25))
	return root

static func scroll_visual() -> Node3D:
	var root := Node3D.new()
	root.name = "ScrollVisual"
	var paper := Color("#fff3d1")
	part(root, cylinder_mesh(0.07, 0.07, 0.55, 8), mat(paper, 0.8, 0.2), Vector3(0, 0, 0), Vector3(0, 0, 90))
	part(root, box_mesh(Vector3(0.5, 0.34, 0.015)), mat(paper, 0.8, 0.15), Vector3(0, 0, 0))
	for x in [-0.28, 0.28]:
		part(root, cylinder_mesh(0.055, 0.055, 0.1, 8), mat(Color("#c69a4b")), Vector3(x, 0, 0), Vector3(0, 0, 90))
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ffe6a1")
	glow.light_energy = 0.5
	glow.omni_range = 2.2
	root.add_child(glow)
	return root

static func bread_basket() -> Node3D:
	var root := Node3D.new()
	root.name = "BreadBasket"
	part(root, box_mesh(Vector3(0.62, 0.22, 0.42)), mat(Color("#b98a62")), Vector3(0, 0.11, 0))
	for x in [-0.3, 0.3]:
		part(root, box_mesh(Vector3(0.04, 0.3, 0.04)), mat(Color("#8a5a3a")), Vector3(x, 0.26, 0))
	part(root, box_mesh(Vector3(0.66, 0.04, 0.05)), mat(Color("#8a5a3a")), Vector3(0, 0.4, 0))
	for i in 3:
		part(root, sphere_mesh(0.15, 8, 4), mat(Color("#e0b46d")),
			Vector3(-0.18 + i * 0.18, 0.3, 0), Vector3.ZERO, Vector3(1.25, 0.8, 1.0))
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ffdca0")
	glow.light_energy = 0.35
	glow.omni_range = 1.8
	root.add_child(glow)
	return root

static func signpost(text: String, color := Color("#b98a62")) -> Node3D:
	var root := Node3D.new()
	root.name = "Signpost"
	part(root, box_mesh(Vector3(0.14, 1.5, 0.14)), mat(Color("#7a5230")), Vector3(0, 0.75, 0))
	part(root, box_mesh(Vector3(1.5, 0.6, 0.12)), mat(color), Vector3(0, 1.4, 0))
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.0045
	label.outline_size = 10
	label.outline_modulate = Color("#3b2a1c")
	label.modulate = Color("#fff6e0")
	label.position = Vector3(0, 1.4, 0.075)
	root.add_child(label)
	collider_cylinder(root, 0.12, 1.5, Vector3(0, 0.75, 0))
	return root
