class_name TargetRing
extends Node3D
## Argola de treino. Acerte com a funda — sem violência, apenas precisão.

signal hit

@export var hit_radius := 1.0
@export var ring_color := Color("#f2b544")
@export var required_mission := ""
var is_hit := false
var _visual: Node3D
var _toast_clock := 0.0

func _ready() -> void:
	add_to_group("target_ring")
	_visual = Props.target_ring(maxf(0.5, hit_radius - 0.15), ring_color)
	add_child(_visual)

func _process(delta: float) -> void:
	_toast_clock = maxf(0.0, _toast_clock - delta)

func hit_target() -> void:
	if is_hit:
		return
	if required_mission != "" and not Missions.is_active(required_mission):
		_practice_throw()
		return
	is_hit = true
	hit.emit()
	Audio.play_sfx("success", 1.25, 0.8)
	_set_all_materials(Color("#7fc78a"))
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3.ONE * 1.18, 0.12)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.25)
	Missions.notify_event("target_hit", 1, {})
	if Missions.is_active("david_alvos"):
		Game.toast("Alvo acertado! Muito bem!", "✧")

## Fora do desafio a argola não consome o acerto: só responde e ensina o porquê.
func _practice_throw() -> void:
	Audio.play_sfx("click", 1.1, 0.55)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3.ONE * 1.12, 0.1)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.2)
	if _toast_clock <= 0.0:
		_toast_clock = 6.0
		Game.toast("Boa pontaria! Os alvos contam ponto quando o desafio do Davi começar.", "✧")

func _set_all_materials(color: Color) -> void:
	var material := Props.mat(color, 0.4, 0.35)
	_apply_material(self, material)

func _apply_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material(child, material)
