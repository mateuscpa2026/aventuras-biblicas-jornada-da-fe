extends Node3D
## Ferramenta de inspeção: monta uma vitrine com todos os animais e salva um PNG.
## Uso: godot --path . tools/animal_preview.tscn -- /tmp/animais.png

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := "tmp/animais.png"
	var only := ""
	for arg in args:
		if str(arg).ends_with(".png"):
			out = str(arg)
		elif str(arg).begins_with("only="):
			only = str(arg).substr(5)
	_build(only)
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var image := get_viewport().get_texture().get_image()
	print("[preview] ", out, " -> ", error_string(image.save_png(out)))
	get_tree().quit()

func _build(only := "") -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#cfe6bf")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#f2ecd8")
	environment.ambient_light_energy = 0.85
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_energy = 1.15
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("#9fce7d")
	ground_mat.roughness = 1.0
	plane.material = ground_mat
	ground.mesh = plane
	add_child(ground)

	var colors := {
		"sheep": {"wool": Color("#f2ecdd"), "skin": Color("#3b3230"), "accent": Color("#d9c9ac")},
		"rabbit": {"wool": Color("#c9b29a"), "skin": Color("#b9a18c"), "accent": Color("#e8c3c3")},
		"deer": {"wool": Color("#b07a48"), "skin": Color("#7a4e2a"), "accent": Color("#f0e2cc")},
		"bird": {"wool": Color("#4d8fc4"), "skin": Color("#2f5f8f"), "accent": Color("#e8b45c")},
		"donkey": {"wool": Color("#9a938c"), "skin": Color("#6b625b"), "accent": Color("#c9c1b6")},
		"goat": {"wool": Color("#d9d1c2"), "skin": Color("#8b7f6d"), "accent": Color("#6b5a44")},
		"fish": {"wool": Color("#e08a44"), "skin": Color("#c46a2c"), "accent": Color("#f6d59a")},
	}
	var kinds := ["sheep", "rabbit", "deer", "bird", "donkey", "goat", "fish"]
	if only != "":
		kinds = only.split(",")
	var index := 0
	for kind in kinds:
		var rig := AnimalRig.new()
		rig.name = kind
		rig.setup(kind, colors.get(kind, {}))
		var column := index % 4
		var row := int(index / 4.0)
		add_child(rig)
		if only != "":
			rig.position = Vector3(float(index) * 2.4 - float(kinds.size() - 1) * 1.2, 0.55 if kind == "fish" else 0.0, 0)
		else:
			rig.position = Vector3(-3.9 + column * 2.6, 0.55 if kind == "fish" else 0.0, -2.4 + row * 3.6)
		index += 1

	var camera := Camera3D.new()
	if only != "":
		camera.position = Vector3(0, 1.0, -4.6)
		camera.rotation_degrees = Vector3(-6, 180, 0)
		camera.fov = 48
	else:
		camera.position = Vector3(0, 1.75, -8.6)
		camera.rotation_degrees = Vector3(-5, 180, 0)
		camera.fov = 46
	camera.current = true
	add_child(camera)
