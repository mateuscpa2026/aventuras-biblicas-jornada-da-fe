class_name PlayerCamera
extends Node3D
## Câmera de terceira pessoa com mouse, zoom, mira e prevenção de paredes (SpringArm3D).

var yaw := 0.0
var pitch := -0.21
var target_yaw := 0.0
var target_pitch := -0.21
var spring: SpringArm3D
var camera: Camera3D
var pitch_pivot: Node3D
var enabled := true
var aiming := false
var default_length := 4.2
var target_length := 4.2
var target_fov := 68.0
var target_shoulder := 0.0

func _ready() -> void:
	pitch_pivot = Node3D.new()
	pitch_pivot.name = "PitchPivot"
	add_child(pitch_pivot)

	spring = SpringArm3D.new()
	spring.name = "SpringArm"
	spring.spring_length = default_length
	spring.margin = 0.25
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
	spring.shape = sphere
	spring.collision_mask = 1
	pitch_pivot.add_child(spring)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = target_fov
	camera.far = Settings.camera_far()
	camera.current = true
	spring.add_child(camera)
	rotation.y = yaw
	pitch_pivot.rotation.x = pitch

func _input(event: InputEvent) -> void:
	if not enabled or get_tree().paused:
		return
	# Olha mesmo se o sistema recusar a captura do cursor: o foco do jogo já
	# é controlado por enabled, então isso é só uma rede de segurança.
	if event is InputEventMouseMotion:
		var sensitivity := Settings.mouse_sensitivity * 0.01
		target_yaw -= event.relative.x * sensitivity
		target_pitch = clampf(target_pitch - event.relative.y * sensitivity, deg_to_rad(-58.0), deg_to_rad(26.0))
	elif event is InputEventMouseButton and event.pressed and not aiming:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_length = clampf(target_length - 0.45, 2.6, 6.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_length = clampf(target_length + 0.45, 2.6, 6.5)

func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 16.0))
	pitch_pivot.rotation.x = lerpf(pitch_pivot.rotation.x, target_pitch, minf(1.0, delta * 16.0))
	spring.spring_length = lerpf(spring.spring_length, target_length, minf(1.0, delta * 8.0))
	camera.fov = lerpf(camera.fov, target_fov, minf(1.0, delta * 9.0))
	spring.position.x = lerpf(spring.position.x, target_shoulder, minf(1.0, delta * 8.0))

func set_aiming(value: bool) -> void:
	aiming = value
	target_length = 2.1 if value else default_length
	target_fov = 52.0 if value else 68.0
	target_shoulder = 0.42 if value else 0.0

func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		set_aiming(false)

func look_at_immediate(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0, direction.z)
	if flat.length() < 0.01:
		return
	target_yaw = atan2(-flat.x, -flat.z)
	yaw = target_yaw

func get_view_yaw() -> float:
	return rotation.y
