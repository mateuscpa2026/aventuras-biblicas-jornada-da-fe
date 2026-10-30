class_name PlayerCharacter
extends CharacterBody3D
## Explorador em terceira pessoa: movimento relativo à câmera, corrida, salto,
## interação (E), mira com funda e animação procedural.

signal prompt_changed(text: String)
signal aiming_changed(active: bool)

const WALK_SPEED := 4.3
const RUN_SPEED := 7.2
const ACCELERATION := 24.0
const DECELERATION := 28.0
const AIR_ACCELERATION := 9.0
const JUMP_VELOCITY := 6.4
const GRAVITY := 18.0
const THROW_SPEED := 27.0

var input_enabled := true
var aiming := false
var rig: StylizedRig
var camera_rig: PlayerCamera
var selected: Interactable = null
var spawn_point := Vector3(0, 0.1, 0)
var _focus_clock := 0.0
var _last_prompt := ""
var _fall_guard := 0.0
var _wade := 0.0
var _water_clock := 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(52.0)
	_build_collision()

	rig = StylizedRig.new()
	rig.name = "Rig"
	PlayerLooks.apply(rig, SaveSystem.get_player_look())
	add_child(rig)

	camera_rig = PlayerCamera.new()
	camera_rig.name = "CameraRig"
	camera_rig.position = Vector3(0, 1.38, 0)
	add_child(camera_rig)

	Settings.changed.connect(_apply_settings)
	_apply_settings()
	Game.set_player(self)

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	shape.name = "Collision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.62
	shape.shape = capsule
	shape.position = Vector3(0, 0.81, 0)
	add_child(shape)

func _apply_settings() -> void:
	if camera_rig and camera_rig.camera:
		camera_rig.camera.far = Settings.camera_far()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -0.6

	_water_clock -= delta
	if _water_clock <= 0.0:
		_water_clock = 0.15
		_update_wade()

	var input_dir := Vector2.ZERO
	if input_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y)
	if direction.length() > 0.01:
		direction = direction.rotated(Vector3.UP, camera_rig.get_view_yaw()).normalized()
	else:
		direction = Vector3.ZERO

	var speed_cap := WALK_SPEED
	if input_enabled and Input.is_action_pressed("run"):
		speed_cap = RUN_SPEED
	if aiming:
		speed_cap *= 0.45
	if not is_on_floor():
		speed_cap *= 0.85
	if _wade > 0.02:
		speed_cap *= lerpf(0.8, 0.42, clampf(_wade / 0.95, 0.0, 1.0))

	var target_velocity := direction * speed_cap
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	var rate := ACCELERATION
	if direction == Vector3.ZERO:
		rate = DECELERATION
	if not is_on_floor():
		rate = AIR_ACCELERATION
	horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if input_enabled and is_on_floor() and not aiming and Input.is_action_just_pressed("jump"):
		# na água funda o salto quase não sobe: o personagem está pesado
		velocity.y = JUMP_VELOCITY * (1.0 - 0.7 * clampf(_wade / 0.95, 0.0, 1.0))
		Audio.play_sfx("jump", randf_range(0.95, 1.05))

	move_and_slide()

	if direction.length() > 0.05:
		var target_yaw := atan2(-direction.x, -direction.z)
		rig.rotation.y = lerp_angle(rig.rotation.y, target_yaw, minf(1.0, delta * 11.0))
	elif aiming:
		rig.rotation.y = lerp_angle(rig.rotation.y, camera_rig.get_view_yaw(), minf(1.0, delta * 11.0))

	rig.set_locomotion(horizontal.length(), is_on_floor(), velocity.y)

	_focus_clock -= delta
	if _focus_clock <= 0.0:
		_focus_clock = 0.12
		_update_focus()

	if global_position.y < -16.0:
		global_position = spawn_point
		velocity = Vector3.ZERO

## Quanto de água há sobre os pés do personagem (0 = em terra firme).
func _update_wade() -> void:
	var deepest := 0.0
	for node in get_tree().get_nodes_in_group("water"):
		var water := node as WaterVolume
		if water:
			deepest = maxf(deepest, water.submersion(global_position))
	_wade = deepest

func _update_focus() -> void:
	var text := ""
	var previous := selected
	selected = null
	if input_enabled:
		if aiming:
			text = "[Clique] Lançar pedra    [E] Sair da mira"
		else:
			selected = _find_nearest()
			if selected:
				selected.show_prompt(selected.get_prompt(self))
	if previous and is_instance_valid(previous) and previous != selected:
		previous.hide_prompt()
	if text != _last_prompt:
		_last_prompt = text
		prompt_changed.emit(text)

func _clear_selection() -> void:
	if selected and is_instance_valid(selected):
		selected.hide_prompt()
	selected = null

func _find_nearest() -> Interactable:
	var best: Interactable = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		var interactable := node as Interactable
		if interactable == null or not is_instance_valid(interactable):
			continue
		if not interactable.can_interact(self):
			continue
		var distance := global_position.distance_to(interactable.global_position)
		if distance <= interactable.interact_radius and distance < best_distance:
			best = interactable
			best_distance = distance
	return best

## O disparo acontece em `_input` para que nenhum elemento da HUD (a mira, por
## exemplo) engula o clique antes de chegar ao jogador.
func _input(event: InputEvent) -> void:
	if not aiming or not input_enabled or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		throw_pebble()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or get_tree().paused:
		return
	if event.is_action_pressed("interact"):
		if aiming:
			set_aiming(false)
		elif selected and is_instance_valid(selected):
			selected.interact(self)

func set_controlled(value: bool) -> void:
	input_enabled = value
	if camera_rig:
		camera_rig.set_enabled(value)
	if not value:
		velocity.x = 0.0
		velocity.z = 0.0
		_clear_selection()
		set_aiming(false)
		if _last_prompt != "":
			_last_prompt = ""
			prompt_changed.emit("")

func set_aiming(value: bool) -> void:
	if not input_enabled:
		value = false
	if aiming == value:
		return
	aiming = value
	camera_rig.set_aiming(value)
	_clear_selection()
	aiming_changed.emit(value)
	_last_prompt = ""
	_update_focus()

func play_interact_animation() -> void:
	if rig:
		rig.play_interact()

func throw_pebble() -> void:
	var camera: Camera3D = camera_rig.camera
	var forward := -camera.global_transform.basis.z.normalized()
	var start := camera.global_position + forward * 1.0
	var aim := camera.global_position + forward * 45.0
	# Ajuda de mira: se a mira está quase na argola, a pedra vai no centro dela.
	var best_dot := 0.988
	for node in get_tree().get_nodes_in_group("target_ring"):
		var target := node as TargetRing
		if target == null or target.is_hit:
			continue
		var offset := target.global_position - camera.global_position
		var distance := offset.length()
		if distance < 1.0:
			continue
		var alignment := forward.dot(offset / distance)
		if alignment > best_dot:
			best_dot = alignment
			aim = target.global_position
	if best_dot <= 0.988:
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, aim, 1)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			aim = hit["position"]
	var pebble := Pebble.new()
	get_parent().add_child(pebble)
	pebble.global_position = start
	pebble.launch(Pebble.solve_arc(start, aim, THROW_SPEED))
	Audio.play_sfx("throw", randf_range(0.9, 1.1))
	rig.play_interact()

func get_camera() -> Camera3D:
	return camera_rig.camera if camera_rig else null

func set_spawn_point(position: Vector3) -> void:
	spawn_point = position
