extends Node
## Coordena capítulos, progresso, troca de mundos e itens carregados.

signal chapter_completed(world_id: String)
signal quiz_requested(quiz_id: String)
signal toast_requested(text: String, icon: String)
signal carry_changed
signal checkpoint_saved

const CHAPTERS_PATH := "res://data/chapters.json"

var chapters: Array[Dictionary] = []
var current_world := ""
var main: Node = null
var player: Node3D = null
var carried: Dictionary = {}

func _ready() -> void:
	_load_chapters()
	Missions.world_completed.connect(_on_world_completed)

func _load_chapters() -> void:
	chapters.clear()
	if not FileAccess.file_exists(CHAPTERS_PATH):
		push_error("data/chapters.json não encontrado.")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CHAPTERS_PATH))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("data/chapters.json inválido.")
		return
	for raw in parsed:
		if typeof(raw) != TYPE_DICTIONARY or not raw.has("id"):
			continue
		chapters.append(raw)
	chapters.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))

func set_main(node: Node) -> void:
	main = node

func get_chapter(world_id: String) -> Dictionary:
	for chapter in chapters:
		if str(chapter.get("id", "")) == world_id:
			return chapter
	return {}

func next_chapter(world_id: String) -> Dictionary:
	var index := -1
	for i in chapters.size():
		if str(chapters[i].get("id", "")) == world_id:
			index = i
			break
	if index >= 0 and index + 1 < chapters.size():
		return chapters[index + 1]
	return {}

func is_unlocked(world_id: String) -> bool:
	return SaveSystem.is_chapter_unlocked(world_id)

func is_completed(world_id: String) -> bool:
	return SaveSystem.is_chapter_completed(world_id)

func start_new_game() -> void:
	SaveSystem.new_game(true)
	Missions.reset_runtime()
	carried.clear()
	carry_changed.emit()
	if main:
		main.begin_world("eden")

func continue_game() -> void:
	Missions.reset_runtime()
	var world_id := SaveSystem.get_last_world()
	if get_chapter(world_id).is_empty() or not is_unlocked(world_id):
		world_id = "eden"
	if main:
		main.begin_world(world_id)

func go_to_menu() -> void:
	current_world = ""
	player = null
	if main:
		main.back_to_menu()

func set_player(value: Node3D) -> void:
	player = value

func get_player() -> Node3D:
	if is_instance_valid(player):
		return player
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		player = nodes[0]
		return player
	return null

func _on_world_completed(world_id: String) -> void:
	SaveSystem.complete_chapter(world_id)
	SaveSystem.set_last_world(world_id)
	var next := next_chapter(world_id)
	if not next.is_empty():
		SaveSystem.unlock_chapter(str(next["id"]))
	SaveSystem.write()
	chapter_completed.emit(world_id)
	Audio.play_sfx("success")

func register_world_entered(world_id: String) -> void:
	current_world = world_id
	SaveSystem.set_last_world(world_id)
	SaveSystem.write()
	Audio.play_music(world_id)

func save_checkpoint() -> void:
	if current_world == "":
		return
	SaveSystem.set_last_world(current_world)
	if SaveSystem.write():
		checkpoint_saved.emit()

func add_carry(item_id: String, amount := 1) -> void:
	carried[item_id] = int(carried.get(item_id, 0)) + amount
	carry_changed.emit()

func take_carry(item_id: String, amount := 1) -> bool:
	var current := int(carried.get(item_id, 0))
	if current < amount:
		return false
	if current - amount <= 0:
		carried.erase(item_id)
	else:
		carried[item_id] = current - amount
	carry_changed.emit()
	return true

func get_carry(item_id: String) -> int:
	return int(carried.get(item_id, 0))

func clear_carry() -> void:
	carried.clear()
	carry_changed.emit()

func open_quiz(quiz_id: String) -> void:
	quiz_requested.emit(quiz_id)

func toast(text: String, icon := "✦") -> void:
	toast_requested.emit(text, icon)

func set_current_world(world_id: String) -> void:
	current_world = world_id
