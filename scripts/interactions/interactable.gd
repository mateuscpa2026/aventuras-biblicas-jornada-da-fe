class_name Interactable
extends Node3D
## Base de tudo com que o jogador pode interagir (E).
## O convite aparece como um botão flutuante acima do objeto/personagem.

@export var prompt_text := "Interagir"
@export var interact_radius := 3.0
@export var active := true
@export var prompt_height := 2.2

var prompt_badge: PromptBadge

func _ready() -> void:
	add_to_group("interactable")

func can_interact(_player: Node3D) -> bool:
	return active and visible

func get_prompt(_player: Node3D) -> String:
	return prompt_text

func interact(_player: Node3D) -> void:
	pass

func show_prompt(text: String) -> void:
	if text.strip_edges() == "":
		hide_prompt()
		return
	if prompt_badge == null or not is_instance_valid(prompt_badge):
		prompt_badge = PromptBadge.new()
		prompt_badge.name = "PromptBadge"
		prompt_badge.position = Vector3(0, prompt_height, 0)
		add_child(prompt_badge)
	prompt_badge.show_text(text)

func hide_prompt() -> void:
	if prompt_badge and is_instance_valid(prompt_badge):
		prompt_badge.hide_badge()
