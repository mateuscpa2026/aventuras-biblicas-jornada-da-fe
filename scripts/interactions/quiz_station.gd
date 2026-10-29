class_name QuizStation
extends Interactable
## Pedra da memória: abre o desafio de perguntas do capítulo.

@export var quiz_id := ""
@export var required_mission := ""
var _rune: MeshInstance3D
var _light: OmniLight3D
var _time := 0.0

func _ready() -> void:
	super()
	interact_radius = 3.6
	prompt_height = 2.7
	var stone := Props.rock(1.9, Color("#8d8b83"))
	stone.rotation_degrees.y = 20.0
	add_child(stone)
	_rune = Props.part(self, Props.cylinder_mesh(1.55, 1.55, 0.05, 24),
		Props.mat(Color("#f2c14e"), 0.4, 0.8, 0.85), Vector3(0, 0.03, 0))
	_light = OmniLight3D.new()
	_light.light_color = Color("#ffe2a1")
	_light.light_energy = 1.1
	_light.omni_range = 5.0
	_light.position = Vector3(0, 1.6, 0)
	add_child(_light)
	var sparkles := Props.fireflies(18, Vector3(3.5, 2.2, 3.5))
	sparkles.position = Vector3(0, 1.6, 0)
	add_child(sparkles)
	if required_mission != "":
		prompt_text = "Examinar a pedra"

func _process(delta: float) -> void:
	_time += delta
	if _rune:
		_rune.rotation.y += delta * 0.25
	if _light:
		_light.light_energy = 0.9 + sin(_time * 2.0) * 0.18
	_light.visible = get_prompt(null) != "A pedra adormecida"

func get_prompt(_player: Node3D) -> String:
	if required_mission != "":
		if Missions.is_mission_completed(required_mission):
			return "A pedra está em paz"
		if not Missions.is_active(required_mission):
			return "A pedra adormecida"
	return "Examinar a pedra"

func interact(_player: Node3D) -> void:
	if required_mission != "" and not Missions.is_active(required_mission):
		if Missions.is_mission_completed(required_mission):
			Game.toast("A pedra já cumpriu seu papel. Siga explorando!", "✦")
		else:
			Game.toast("A pedra dorme... complete os outros objetivos primeiro.", "✦")
			Audio.play_sfx("wrong", 0.9, 0.6)
		return
	Audio.play_sfx("interact")
	Game.open_quiz(quiz_id)
