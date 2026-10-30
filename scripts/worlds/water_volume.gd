class_name WaterVolume
extends Node3D
## Volume de água de uma lagoa: informa ao jogador onde a água começa e quanto
## do corpo ficou submerso. O espelho d'água sobe e desce alguns milímetros.

var surface_y := 0.0
var radius := 4.0
var depth := 1.0
var lip_y := 0.0
var basin_radius := 4.6
var basin_depth := 1.15
var surface: Node3D
var _time := 0.0

func _ready() -> void:
	add_to_group("water")

func _process(delta: float) -> void:
	if surface == null:
		return
	_time += delta
	surface.position.y = surface_y + sin(_time * 1.6) * 0.008

## Metros de corpo abaixo da superfície (0 quando está fora d'água).
func submersion(point: Vector3) -> float:
	var flat := Vector2(point.x - global_position.x, point.z - global_position.z)
	if flat.length() > radius:
		return 0.0
	return clampf(surface_y - point.y, 0.0, depth)

## Altura do fundo da bacia naquele ponto: é o mesmo perfil que o EnvBuilder
## esculpe na malha, então os peixes acompanham o declive sem furar o lodo.
func floor_y(point: Vector3) -> float:
	var flat := Vector2(point.x - global_position.x, point.z - global_position.z).length()
	if flat >= basin_radius:
		return lip_y
	var t := 1.0 - flat / basin_radius
	return lip_y - basin_depth * (t * t * (3.0 - 2.0 * t))
