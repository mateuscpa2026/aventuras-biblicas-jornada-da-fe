class_name SlingshotStand
extends Interactable
## Barraca de treino com a funda (Davi). Ativa o modo de mira do jogador.

func _ready() -> void:
	super()
	prompt_text = "Treinar com a funda"
	interact_radius = 3.2
	prompt_height = 2.3
	_build_visual()

func _build_visual() -> void:
	var wood := Color("#9c6a4b")
	Props.part(self, Props.box_mesh(Vector3(1.4, 0.16, 0.8)), Props.mat(wood), Vector3(0, 0.9, 0))
	for x in [-0.6, 0.6]:
		for z in [-0.3, 0.3]:
			Props.part(self, Props.box_mesh(Vector3(0.12, 0.9, 0.12)), Props.mat(wood.darkened(0.1)),
				Vector3(x, 0.45, z))
	Props.part(self, Props.box_mesh(Vector3(1.0, 0.06, 0.4)), Props.mat(Color("#c9a06a")), Vector3(0, 0.98, 0))
	for side in [-1, 1]:
		Props.part(self, Props.cylinder_mesh(0.055, 0.075, 1.1, 8), Props.mat(wood),
			Vector3(side * 0.32, 1.55, 0), Vector3(0, 0, side * 14))
	Props.part(self, Props.box_mesh(Vector3(0.75, 0.05, 0.05)), Props.mat(Color("#7a4f2c")), Vector3(0, 2.05, 0))
	Props.part(self, Props.sphere_mesh(0.14, 8, 4), Props.mat(Color("#8d8b83")), Vector3(0, 1.65, 0))
	var sign := Props.signpost("ALVOS", Color("#f2c14e"))
	sign.position = Vector3(0.95, 0, 0.2)
	sign.rotation_degrees.y = -35
	add_child(sign)
	Props.collider_box(self, Vector3(1.5, 1.0, 0.9), Vector3(0, 0.5, 0))

func interact(player: Node3D) -> void:
	var player_character := player as PlayerCharacter
	if player_character == null:
		return
	Audio.play_sfx("click")
	player_character.play_interact_animation()
	player_character.set_aiming(true)
	Game.toast("Mire nos 3 alvos e clique para lançar. Aperte E para sair da mira.", "✧")
