extends Node
## Sistema de missões reutilizável.
## Cada missão escuta um evento de jogo e conclui apenas ao atingir o objetivo.

signal mission_started(mission: Dictionary)
signal mission_progress(mission: Dictionary, progress: int, target: int)
signal mission_completed(mission: Dictionary)
signal mission_list_changed
signal world_completed(world_id: String)

var current_world := ""
var _defs: Dictionary = {}
var _active: Array[String] = []
var _progress: Dictionary = {}
var _completed: Array[String] = []
var _syncing_collect := false

func load_world(world_id: String) -> void:
	current_world = world_id
	_defs.clear()
	_active.clear()
	_progress.clear()
	_completed = SaveSystem.get_completed_missions(world_id)
	var path := "res://data/missions/%s.json" % world_id
	if not FileAccess.file_exists(path):
		push_error("Missões não encontradas para o mundo: " + world_id)
		mission_list_changed.emit()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Formato inválido em " + path)
		mission_list_changed.emit()
		return
	for raw in parsed:
		if typeof(raw) != TYPE_DICTIONARY or not raw.has("id"):
			continue
		var mission: Dictionary = raw.duplicate(true)
		mission["target"] = maxi(1, int(mission.get("target", 1)))
		mission["requires"] = mission.get("requires", [])
		mission["match"] = mission.get("match", {})
		_defs[str(mission["id"])] = mission
	_refresh()
	mission_list_changed.emit()

func _refresh() -> void:
	for mission_id in _defs.keys():
		var mission: Dictionary = _defs[mission_id]
		if _completed.has(mission_id) or _active.has(mission_id):
			continue
		if _requirements_met(mission):
			_start(mission_id)
	_sync_collect_missions()

## Pergaminhos já guardados contam novamente após recarregar o jogo, evitando
## que a missão de colecionáveis fique presa com progresso zerado.
func _sync_collect_missions() -> void:
	if _syncing_collect or current_world == "":
		return
	_syncing_collect = true
	for mission_id in _active.duplicate():
		var mission: Dictionary = _defs.get(mission_id, {})
		if str(mission.get("event", "")) != "collect_scroll":
			continue
		var target := int(mission.get("target", 1))
		var collected := Story.count_unlocked_scrolls(current_world)
		if collected <= 0:
			continue
		var value := mini(target, collected)
		if value <= int(_progress.get(mission_id, 0)):
			continue
		_progress[mission_id] = value
		mission_progress.emit(mission, value, target)
		if value >= target:
			_complete(mission)
	_syncing_collect = false

func _requirements_met(mission: Dictionary) -> bool:
	for required in mission.get("requires", []):
		if not _completed.has(str(required)):
			return false
	return true

func _start(mission_id: String) -> void:
	_active.append(mission_id)
	_progress[mission_id] = 0
	mission_started.emit(_defs[mission_id])
	mission_list_changed.emit()

func notify_event(event_name: String, amount := 1, payload := {}) -> void:
	if current_world == "" or amount <= 0:
		return
	for mission_id in _active.duplicate():
		var mission: Dictionary = _defs.get(mission_id, {})
		if mission.is_empty():
			continue
		if str(mission.get("event", "")) != event_name:
			continue
		if not _matches(mission.get("match", {}), payload):
			continue
		_progress[mission_id] = int(_progress.get(mission_id, 0)) + amount
		var target := int(mission.get("target", 1))
		mission_progress.emit(mission, _progress[mission_id], target)
		if _progress[mission_id] >= target:
			_complete(mission)

func _matches(filters: Dictionary, payload: Dictionary) -> bool:
	for key in filters.keys():
		if str(payload.get(str(key), "")) != str(filters[key]):
			return false
	return true

func _complete(mission: Dictionary) -> void:
	var mission_id := str(mission["id"])
	_active.erase(mission_id)
	if not _completed.has(mission_id):
		_completed.append(mission_id)
	SaveSystem.set_completed_missions(current_world, _completed)
	SaveSystem.write()
	var reward = mission.get("reward_story", "")
	if typeof(reward) == TYPE_STRING and reward != "":
		Story.unlock(reward)
	mission_completed.emit(mission)
	mission_list_changed.emit()
	_refresh()
	if bool(mission.get("is_final", false)):
		world_completed.emit(current_world)

func is_active(mission_id: String) -> bool:
	return _active.has(mission_id)

func is_mission_completed(mission_id: String) -> bool:
	return _completed.has(mission_id)

func is_world_done() -> bool:
	if _defs.is_empty():
		return false
	for mission_id in _defs.keys():
		if not _completed.has(mission_id):
			return false
	return true

func get_def(mission_id: String) -> Dictionary:
	return _defs.get(mission_id, {})

func get_active() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mission_id in _active:
		var mission: Dictionary = _defs.get(mission_id, {})
		if mission.is_empty():
			continue
		var copy := mission.duplicate(true)
		copy["progress"] = int(_progress.get(mission_id, 0))
		result.append(copy)
	return result

func get_progress(mission_id: String) -> int:
	return int(_progress.get(mission_id, 0))

func get_completed_ids() -> Array[String]:
	return _completed.duplicate()

func reset_runtime() -> void:
	current_world = ""
	_defs.clear()
	_active.clear()
	_progress.clear()
	_completed.clear()
	mission_list_changed.emit()
