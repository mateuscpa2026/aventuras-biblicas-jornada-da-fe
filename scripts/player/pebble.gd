class_name Pebble
extends Node3D
## Pedrinha da funda: voa em arco e acerta os alvos (sem violência).

const GRAVITY := 9.5

var velocity := Vector3.ZERO
var life := 4.5
var _spin := Vector3.ZERO
var _resolved := false

## Velocidade inicial que leva a pedra do ponto `from` até `to` em um arco baixo.
## É a "ajuda de mira": a pedra cai onde a criança aponta, não abaixo do alvo.
static func solve_arc(from: Vector3, to: Vector3, speed: float) -> Vector3:
	var delta := to - from
	var flat := Vector3(delta.x, 0.0, delta.z)
	var distance := flat.length()
	if distance < 0.05:
		return Vector3.UP * speed
	var s2 := speed * speed
	var disc := s2 * s2 - GRAVITY * (GRAVITY * distance * distance + 2.0 * delta.y * s2)
	if disc <= 0.0:
		# Longe demais para esta velocidade: segue reto com leve elevação.
		return (flat / distance * speed + Vector3.UP * speed * 0.18).normalized() * speed
	var angle := atan2(s2 - sqrt(disc), GRAVITY * distance)
	var direction := flat / distance
	return (direction * cos(angle) + Vector3.UP * sin(angle)) * speed

func _ready() -> void:
	add_to_group("pebble")
	Props.part(self, Props.sphere_mesh(0.1, 10, 7), Props.stone_mat(Color("#8d8b83")),
		Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.8, 1.3))
	_spin = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 12.0

func launch(new_velocity: Vector3) -> void:
	velocity = new_velocity

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	life -= delta
	velocity.y -= 9.5 * delta
	global_position += velocity * delta
	rotation += _spin * delta

	for node in get_tree().get_nodes_in_group("target_ring"):
		var target := node as TargetRing
		if target == null or target.is_hit:
			continue
		if global_position.distance_to(target.global_position) <= target.hit_radius:
			_resolved = true
			target.hit_target()
			queue_free()
			return

	if global_position.y <= 0.06 or life <= 0.0:
		_resolved = true
		queue_free()
