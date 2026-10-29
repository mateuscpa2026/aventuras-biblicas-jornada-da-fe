class_name AnimalCharacter
extends Interactable
## Animal com comportamento de passeio, cuidado e acompanhamento até um destino.

@export var kind := "sheep"
@export var colors: Dictionary = {}
@export var can_follow := false
@export var care_event := "care_animal"
@export var escort_event := ""
@export var escort_target: Node3D
@export var escort_hint := ""
@export var home_radius := 3.0
@export var move_speed := 1.0
@export var animal_name := ""

const KIND_LABELS := {
	"sheep": "ovelha", "rabbit": "coelho", "deer": "cervo", "bird": "passarinho",
	"donkey": "jumentinho", "goat": "cabrito", "fish": "peixinho",
}

var rig: AnimalRig
var following := false
var delivered := false
var cared := false
var _home := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _wander_clock := 0.0
var _speed := 0.0
var _time := 0.0

func _ready() -> void:
	super()
	if animal_name == "":
		animal_name = KIND_LABELS.get(kind, "animal")
	interact_radius = 3.1
	prompt_height = 1.7
	_home = global_position
	_wander_target = _home
	rig = AnimalRig.new()
	rig.name = "Visual"
	rig.setup(kind, colors)
	add_child(rig)
	prompt_text = ("Chamar a " if can_follow else "Cuidar da ") + animal_name
	if kind == "fish":
		active = false
		interact_radius = 0.1
		wander_radius_setup(1.4)
	elif kind == "bird":
		home_radius = 5.0

func wander_radius_setup(radius: float) -> void:
	home_radius = radius

func get_prompt(_player: Node3D) -> String:
	if following:
		return "Seguindo você"
	if delivered or cared:
		return "Dar carinho"
	return prompt_text

func interact(player: Node3D) -> void:
	if delivered:
		rig.cheer(0.8)
		Game.toast("%s está feliz aqui!" % animal_name.capitalize(), "♡")
		return
	if following:
		rig.cheer(0.8)
		Game.toast("%s está seguindo você!" % animal_name.capitalize(), "♡")
		return
	if can_follow:
		_start_follow()
		return
	if cared:
		rig.cheer(0.8)
		Game.toast("Você já cuidou de %s. Ele está feliz!" % animal_name, "♡")
		return
	cared = true
	rig.cheer(1.0)
	Audio.play_sfx("success", randf_range(1.05, 1.2), 0.7)
	Missions.notify_event(care_event, 1, {"animal": kind})
	Game.toast("Você cuidou de %s!" % animal_name, "♡")
	var player_character := player as PlayerCharacter
	if player_character:
		player_character.play_interact_animation()

func _start_follow() -> void:
	following = true
	Audio.play_sfx("interact")
	rig.cheer(0.8)
	if escort_hint != "":
		Game.toast(escort_hint, "➜")
	else:
		Game.toast("%s vai seguir você!" % animal_name.capitalize(), "➜")

func _arrive() -> void:
	following = false
	delivered = true
	cared = true
	_speed = 0.0
	if is_instance_valid(escort_target):
		global_position = escort_target.global_position + Vector3(randf_range(-0.7, 0.7), 0, randf_range(-0.7, 0.7))
	rig.cheer(1.6)
	Audio.play_sfx("deliver")
	if escort_event != "":
		Missions.notify_event(escort_event, 1, {"animal": kind})
	Game.toast("%s chegou ao destino! Muito bem!" % animal_name.capitalize(), "✦")

func _process(delta: float) -> void:
	_time += delta
	_speed = 0.0
	if following:
		_follow(delta)
	elif kind == "fish":
		_speed = 0.6
		var angle := _time * 0.55
		global_position = _home + Vector3(cos(angle) * 1.3, sin(_time * 1.3) * 0.08, sin(angle) * 1.3)
		rotation.y = -angle
	elif not delivered:
		_wander(delta)
	if rig:
		rig.set_motion(_speed)

func _follow(delta: float) -> void:
	if is_instance_valid(escort_target) and global_position.distance_to(escort_target.global_position) < 3.0:
		_arrive()
		return
	var player := Game.get_player()
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if distance > 2.4:
		var direction := to_player.normalized()
		global_position += direction * minf(distance, 3.6 * delta)
		_speed = 3.6
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 9.0))

func _wander(delta: float) -> void:
	_wander_clock -= delta
	var to_target := _wander_target - global_position
	to_target.y = 0.0
	if _wander_clock <= 0.0 or to_target.length() < 0.4:
		_wander_clock = randf_range(3.5, 7.5)
		var angle := randf() * TAU
		var distance := randf_range(0.5, maxf(1.0, home_radius))
		_wander_target = _home + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		return
	var direction := to_target.normalized()
	var step := minf(to_target.length(), move_speed * 0.55 * delta)
	global_position += direction * step
	_speed = move_speed * 0.55
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 5.0))
