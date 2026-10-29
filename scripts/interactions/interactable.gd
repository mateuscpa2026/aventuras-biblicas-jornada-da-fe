class_name Interactable
extends Node3D
## Base de tudo com que o jogador pode interagir (E).

@export var prompt_text := "Interagir"
@export var interact_radius := 3.0
@export var active := true

func _ready() -> void:
	add_to_group("interactable")

func can_interact(_player: Node3D) -> bool:
	return active and visible

func get_prompt(_player: Node3D) -> String:
	return prompt_text

func interact(_player: Node3D) -> void:
	pass
