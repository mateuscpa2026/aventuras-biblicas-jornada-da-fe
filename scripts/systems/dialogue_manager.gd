extends Node
## Diálogos carregados de data/dialogues/<mundo>.json (fáceis de revisar e traduzir).

signal dialogue_started(data: Dictionary)
signal dialogue_finished(npc_id: String)

var npcs: Dictionary = {}
var current_world := ""
var active_npc := ""
var is_active := false

func load_world(world_id: String) -> void:
	current_world = world_id
	npcs.clear()
	active_npc = ""
	is_active = false
	var path := "res://data/dialogues/%s.json" % world_id
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Formato inválido em " + path)
		return
	var list = parsed.get("npcs", {})
	if typeof(list) == TYPE_DICTIONARY:
		npcs = list

func has_npc(npc_id: String) -> bool:
	return npcs.has(npc_id)

func get_npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})

func start(npc_id: String) -> bool:
	if is_active or not npcs.has(npc_id):
		return false
	var data: Dictionary = npcs[npc_id]
	var lines = data.get("lines", [])
	if typeof(lines) != TYPE_ARRAY or lines.is_empty():
		return false
	active_npc = npc_id
	is_active = true
	var payload := data.duplicate(true)
	payload["npc_id"] = npc_id
	dialogue_started.emit(payload)
	return true

func finish() -> void:
	if not is_active:
		return
	var npc_id := active_npc
	is_active = false
	active_npc = ""
	dialogue_finished.emit(npc_id)
	Missions.notify_event("talk", 1, {"npc": npc_id})

func notify_choice(tag: String) -> void:
	if tag != "":
		Missions.notify_event("choice", 1, {"tag": tag})
