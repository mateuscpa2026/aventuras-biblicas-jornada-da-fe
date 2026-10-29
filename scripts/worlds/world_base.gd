class_name WorldBase
extends Node3D
## Base de todos os mundos: prepara ambiente, jogador, missões e diálogos.

@export var world_id := "eden"
@export var spawn_position := Vector3(0, 0.1, 0)

var chapter: Dictionary = {}
var player: PlayerCharacter
var world_environment: WorldEnvironment
var sun: DirectionalLight3D

func _ready() -> void:
	seed(hash(world_id))
	chapter = Game.get_chapter(world_id)
	Dialogue.load_world(world_id)
	Missions.load_world(world_id)
	spawn_position = _get_spawn_position()
	_build_world()
	_setup_player()
	Game.register_world_entered(world_id)
	Settings.changed.connect(_apply_quality)
	_apply_quality()
	if Game.main and Game.main.has_method("on_world_ready"):
		Game.main.on_world_ready(self, chapter)

func _get_spawn_position() -> Vector3:
	return spawn_position

func _build_world() -> void:
	pass

func set_environment(environment: WorldEnvironment, sun_light: DirectionalLight3D) -> void:
	world_environment = environment
	sun = sun_light

func _setup_player() -> void:
	player = get_node_or_null("Player") as PlayerCharacter
	if player:
		Game.set_player(player)
		player.global_position = spawn_position
		player.set_spawn_point(spawn_position)
		player.set_controlled(false)

func _apply_quality() -> void:
	if sun:
		sun.shadow_enabled = Settings.shadow_enabled()
		sun.directional_shadow_max_distance = Settings.shadow_max_distance()
	if player:
		var camera := player.get_camera()
		if camera:
			camera.far = Settings.camera_far()

func add_npc(npc_id: String, display_name: String, position: Vector3, body_colors := {}, look_at := Vector3.ZERO) -> NPCCharacter:
	var npc := preload("res://scenes/characters/npc.tscn").instantiate() as NPCCharacter
	npc.npc_id = npc_id
	npc.display_name = display_name
	npc.colors = body_colors
	npc.position = position
	add_child(npc)
	if look_at != Vector3.ZERO:
		npc.look_at(Vector3(look_at.x, position.y, look_at.z))
	return npc

func add_animal(kind: String, position: Vector3, colors := {}) -> AnimalCharacter:
	var animal := preload("res://scenes/characters/animal.tscn").instantiate() as AnimalCharacter
	animal.kind = kind
	animal.colors = colors
	animal.position = position
	add_child(animal)
	return animal

func add_scroll(story_id: String, position: Vector3, required_mission := "") -> ScrollPickup:
	if Story.is_unlocked(story_id):
		return null
	var scroll := preload("res://scenes/interactions/scroll_pickup.tscn").instantiate() as ScrollPickup
	scroll.story_id = story_id
	scroll.required_mission = required_mission
	scroll.position = position
	add_child(scroll)
	return scroll

func add_prop(prop: Node3D, position: Vector3, rotation_deg := Vector3.ZERO) -> Node3D:
	prop.position = position
	prop.rotation_degrees = rotation_deg
	add_child(prop)
	return prop

func add_simple_prop(event_name: String, position: Vector3, label: String, visual: Node3D, payload := {}, hide_on_use := true) -> SimpleProp:
	var prop := preload("res://scenes/interactions/simple_prop.tscn").instantiate() as SimpleProp
	prop.event_name = event_name
	prop.prompt_text = label
	prop.payload = payload
	prop.hide_on_use = hide_on_use
	prop.position = position
	if visual:
		prop.add_child(visual)
	add_child(prop)
	return prop

func add_quiz_station(quiz_id: String, position: Vector3, label := "Examinar a pedra", required_mission := "") -> QuizStation:
	var station := preload("res://scenes/interactions/quiz_station.tscn").instantiate() as QuizStation
	station.quiz_id = quiz_id
	station.prompt_text = label
	station.required_mission = required_mission
	station.position = position
	add_child(station)
	return station

func add_marker(position: Vector3, marker_name := "Marker") -> Node3D:
	return Props.marker(self, position, marker_name)
