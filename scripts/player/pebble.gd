class_name Pebble
extends Node3D
## Pedrinha da funda: voa em arco e acerta os alvos (sem violência).

var velocity := Vector3.ZERO
var life := 4.5
var _spin := Vector3.ZERO
var _resolved := false

func _ready() -> void:
	add_to_group("pebble")
	Props.part(self, Props.sphere_mesh(0.1, 8, 5), Props.mat(Color("#8d8b83"), 0.8),
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
