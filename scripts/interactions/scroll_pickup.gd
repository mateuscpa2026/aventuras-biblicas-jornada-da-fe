class_name ScrollPickup
extends Interactable
## Pergaminho colecionável: guarda uma história no livro.

@export var story_id := ""
@export var required_mission := ""
var _visual: Node3D
var _base_y := 0.0
var _time := 0.0

func _ready() -> void:
	super()
	if required_mission != "" and Missions.is_mission_completed(required_mission):
		queue_free()
		return
	if required_mission != "" and not Missions.is_active(required_mission):
		active = false
		visible = false
		Missions.mission_started.connect(_on_mission_started)
	prompt_text = "Pegar pergaminho"
	interact_radius = 3.2
	_base_y = position.y
	_visual = Props.scroll_visual()
	add_child(_visual)

func _on_mission_started(mission: Dictionary) -> void:
	if str(mission.get("id", "")) != required_mission:
		return
	visible = true
	active = true
	scale = Vector3.ONE * 0.2
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx("collect", 0.8, 0.35)

func _process(delta: float) -> void:
	_time += delta
	if _visual:
		_visual.position.y = sin(_time * 2.0) * 0.12
		_visual.rotation.y += delta * 0.9

func interact(_player: Node3D) -> void:
	if story_id == "":
		return
	var story := Story.get_story(story_id)
	var unlocked := Story.unlock_bundle(story_id)
	Missions.notify_event("collect_scroll", 1, {"story": story_id})
	Audio.play_sfx("collect")
	if not unlocked.is_empty() and not story.is_empty():
		var extra := unlocked.size() - 1
		var suffix := ("  ·  +%d histórias" % extra) if extra > 0 else ""
		Game.toast("Pergaminho guardado: " + str(story.get("title", "")) + suffix, "✦")
	else:
		Game.toast("Você já conhecia esta história.", "✦")
	queue_free()
