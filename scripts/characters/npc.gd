class_name NPCCharacter
extends Interactable
## Personagem com diálogo, entregas e acompanhamento (ex.: viajantes, moradores).

@export var npc_id := ""
@export var display_name := "Morador"
@export var colors: Dictionary = {}
@export var can_follow := false
@export var follow_mission := ""
@export var escort_event := ""
@export var escort_target: Node3D
@export var escort_hint := ""
@export var delivery_item := ""
@export var delivery_event := ""
@export var delivery_mission := ""
@export var delivery_label := "item"

var rig: StylizedRig
var following := false
var arrived := false
var _talked := false
var _speed := 0.0
var _name_label: Label3D

func _ready() -> void:
	super()
	interact_radius = 3.2
	rig = StylizedRig.new()
	rig.name = "Visual"
	rig.configure(colors)
	add_child(rig)
	if colors.has("hat"):
		rig.add_hat(colors["hat"])
	if colors.has("beard"):
		rig.add_beard(colors["beard"])
	rig.scale = Vector3.ONE * float(colors.get("scale", 1.0))
	prompt_height = 2.72 * float(colors.get("scale", 1.0))

	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.text = display_name
	_name_label.font_size = 48
	_name_label.pixel_size = 0.0060
	_name_label.outline_size = 14
	_name_label.outline_modulate = Color("#3b2a1c")
	_name_label.modulate = Color("#fff6e0")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.position = Vector3(0, 2.2, 0)
	add_child(_name_label)

	Dialogue.dialogue_finished.connect(_on_dialogue_finished)

func get_prompt(_player: Node3D) -> String:
	if following:
		return "Seguindo você"
	if delivery_item != "" and delivery_mission != "" and Missions.is_active(delivery_mission):
		if Game.get_carry(delivery_item) > 0:
			return "Entregar " + delivery_label
		return "Falar com " + display_name
	if can_follow and not arrived and (follow_mission == "" or Missions.is_active(follow_mission)) and _talked:
		return "Convidar " + display_name
	return "Falar com " + display_name

func interact(player: Node3D) -> void:
	if following:
		rig.play_cheer(0.8)
		Game.toast("%s está seguindo você!" % display_name, "➜")
		return
	if delivery_item != "" and delivery_mission != "" and Missions.is_active(delivery_mission):
		if Game.get_carry(delivery_item) > 0:
			_deliver(delivery_event)
			return
		Game.toast("Traga %s do mercado primeiro." % delivery_label, "✥")
	if can_follow and _talked and not arrived and (follow_mission == "" or Missions.is_active(follow_mission)):
		_start_follow()
		return
	if Dialogue.has_npc(npc_id):
		_face_player(player)
		rig.play_interact()
		Audio.play_sfx("interact", 1.0, 0.6)
		Dialogue.start(npc_id)
		return
	if can_follow and (follow_mission == "" or Missions.is_active(follow_mission)):
		_start_follow()
		return
	rig.play_cheer(0.7)
	Game.toast("%s sorri para você." % display_name, "☺")

func _deliver(event_name: String) -> void:
	if not Game.take_carry(delivery_item, 1):
		return
	rig.play_cheer(1.2)
	Audio.play_sfx("deliver")
	if event_name != "":
		Missions.notify_event(event_name, 1, {"npc": npc_id})
	var definition := Missions.get_def(delivery_mission)
	var target := int(definition.get("target", 3))
	var progress := Missions.get_progress(delivery_mission)
	if progress < target:
		Game.toast("%s entregue! (%d/%d)" % [delivery_label.capitalize(), progress, target], "✥")
	else:
		Game.toast("Tudo entregue! %s agradece com um sorriso." % display_name, "♥")

func _start_follow() -> void:
	following = true
	Audio.play_sfx("interact")
	rig.play_cheer(0.8)
	if escort_hint != "":
		Game.toast(escort_hint, "➜")
	else:
		Game.toast("%s vai com você!" % display_name, "➜")

func _arrive() -> void:
	if arrived:
		return
	arrived = true
	following = false
	_speed = 0.0
	if is_instance_valid(escort_target):
		global_position = escort_target.global_position + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
	rig.play_cheer(2.0)
	Audio.play_sfx("deliver")
	if escort_event != "":
		Missions.notify_event(escort_event, 1, {"npc": npc_id})
	Game.toast("%s chegou! Que alegria!" % display_name, "✦")

func _on_dialogue_finished(finished_id: String) -> void:
	if finished_id != npc_id:
		return
	_talked = true
	if can_follow and not following and not arrived and (follow_mission == "" or Missions.is_active(follow_mission)):
		_start_follow()

func _face_player(player: Node3D) -> void:
	if player == null:
		return
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		rotation.y = atan2(-direction.x, -direction.z)

func _process(delta: float) -> void:
	_speed = 0.0
	var player := Game.get_player()
	if following:
		var arrived_now := false
		if is_instance_valid(escort_target) and global_position.distance_to(escort_target.global_position) < 3.2:
			_arrive()
			arrived_now = true
		if not arrived_now and player:
			var to_player := player.global_position - global_position
			to_player.y = 0.0
			var distance := to_player.length()
			if distance > 2.6:
				var direction := to_player.normalized()
				global_position += direction * minf(distance, 3.8 * delta)
				_speed = 3.8
				rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 9.0))
	elif player and not arrived:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() < 4.8:
			var target_yaw := atan2(-to_player.x, -to_player.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * 4.0))
	if rig:
		rig.set_locomotion(_speed, true, 0.0)
