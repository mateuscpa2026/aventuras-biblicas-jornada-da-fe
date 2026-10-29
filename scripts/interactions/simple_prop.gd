class_name SimpleProp
extends Interactable
## Objeto interativo simples: caixas, mudinhas, pães, braseiros...
## Envia um evento para o sistema de missões e pode sumir/mover.

@export var event_name := ""
@export var payload: Dictionary = {}
@export var hide_on_use := true
@export var carry_item := ""
@export var toast_text := ""
@export var sound := "collect"
@export var move_to: Node3D

var used := false

func _ready() -> void:
	super()
	prompt_height = 1.6

func interact(_player: Node3D) -> void:
	if used:
		return
	used = true
	active = false
	Audio.play_sfx(sound)

	if carry_item != "":
		Game.add_carry(carry_item, 1)
		Game.toast(toast_text if toast_text != "" else "Você pegou um item.", "✥")
	else:
		Missions.notify_event(event_name, 1, payload)
		if toast_text != "":
			Game.toast(toast_text, "✦")

	if move_to and is_instance_valid(move_to):
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position", move_to.global_position + Vector3(0, 0.4, 0), 0.9) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "scale", Vector3.ONE * 0.4, 0.9)
		if hide_on_use:
			tween.chain().tween_callback(hide)
	elif hide_on_use:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.22)
		tween.parallel().tween_property(self, "position", position + Vector3(0, 0.6, 0), 0.22)
		tween.tween_callback(hide)
