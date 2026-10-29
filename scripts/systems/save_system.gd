extends Node
## Salvamento local em JSON, com validação e backup automático.
## Arquivo: %APPDATA%/Godot/app_userdata/Aventuras Biblicas.../jornada_da_fe_save.json

const SAVE_PATH := "user://jornada_da_fe_save.json"
const TEMP_PATH := "user://jornada_da_fe_save.tmp"
const BACKUP_PATH := "user://jornada_da_fe_save.backup.json"
const SAVE_VERSION := 1

var data: Dictionary = {}
var last_error := ""

func _ready() -> void:
	data = _default_data()
	if has_save():
		load_game()

func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"unlocked_chapters": ["eden"],
		"completed_chapters": [],
		"missions_completed": {},
		"storybook": [],
		"settings": {},
		"last_world": "eden",
		"created_at": Time.get_datetime_string_from_system(),
	}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)

func load_game() -> bool:
	last_error = ""
	for path in [SAVE_PATH, BACKUP_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var parsed = _read_json(path)
		if parsed != null:
			data = _sanitize(parsed)
			return true
		last_error = "O arquivo de salvamento estava corrompido."
	if not has_save():
		data = _default_data()
		return false
	data = _default_data()
	return false

func new_game(keep_settings := true) -> void:
	var settings: Dictionary = data.get("settings", {}) if keep_settings else {}
	data = _default_data()
	data["settings"] = settings
	write()

func write() -> bool:
	last_error = ""
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível gravar o progresso (%s)." % error_string(FileAccess.get_open_error())
		return false
	file.store_string(text)
	file.close()

	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if old != null:
			var old_text := old.get_as_text()
			old.close()
			var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup != null:
				backup.store_string(old_text)
				backup.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if rename_error != OK:
		last_error = "Não foi possível concluir o salvamento (%s)." % error_string(rename_error)
		return false
	return true

func _read_json(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	return json.data

func _sanitize(raw: Dictionary) -> Dictionary:
	var clean := _default_data()
	clean["version"] = SAVE_VERSION
	if raw.has("created_at") and typeof(raw["created_at"]) == TYPE_STRING:
		clean["created_at"] = raw["created_at"]

	var unlocked = raw.get("unlocked_chapters", [])
	if typeof(unlocked) == TYPE_ARRAY:
		var list: Array[String] = []
		for item in unlocked:
			if typeof(item) == TYPE_STRING and not list.has(item):
				list.append(item)
		if not list.has("eden"):
			list.push_front("eden")
		clean["unlocked_chapters"] = list

	var completed = raw.get("completed_chapters", [])
	if typeof(completed) == TYPE_ARRAY:
		var list: Array[String] = []
		for item in completed:
			if typeof(item) == TYPE_STRING and not list.has(item):
				list.append(item)
		clean["completed_chapters"] = list

	var missions = raw.get("missions_completed", {})
	if typeof(missions) == TYPE_DICTIONARY:
		var safe_missions := {}
		for world in missions.keys():
			if typeof(world) != TYPE_STRING or typeof(missions[world]) != TYPE_ARRAY:
				continue
			var ids: Array[String] = []
			for mission_id in missions[world]:
				if typeof(mission_id) == TYPE_STRING:
					ids.append(mission_id)
			safe_missions[world] = ids
		clean["missions_completed"] = safe_missions

	for key in ["storybook"]:
		var items = raw.get(key, [])
		if typeof(items) == TYPE_ARRAY:
			var list: Array[String] = []
			for item in items:
				if typeof(item) == TYPE_STRING and not list.has(item):
					list.append(item)
			clean[key] = list

	var settings = raw.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		clean["settings"] = settings.duplicate(true)

	var last_world = raw.get("last_world", "eden")
	if typeof(last_world) == TYPE_STRING and last_world != "":
		clean["last_world"] = last_world
	return clean

func is_chapter_unlocked(world_id: String) -> bool:
	return data.get("unlocked_chapters", []).has(world_id)

func unlock_chapter(world_id: String) -> void:
	var unlocked: Array = data.get("unlocked_chapters", [])
	if not unlocked.has(world_id):
		unlocked.append(world_id)
		data["unlocked_chapters"] = unlocked

func is_chapter_completed(world_id: String) -> bool:
	return data.get("completed_chapters", []).has(world_id)

func complete_chapter(world_id: String) -> void:
	var completed: Array = data.get("completed_chapters", [])
	if not completed.has(world_id):
		completed.append(world_id)
		data["completed_chapters"] = completed

func get_completed_missions(world_id: String) -> Array[String]:
	var result: Array[String] = []
	var all: Dictionary = data.get("missions_completed", {})
	var items = all.get(world_id, [])
	if typeof(items) == TYPE_ARRAY:
		for item in items:
			if typeof(item) == TYPE_STRING:
				result.append(item)
	return result

func set_completed_missions(world_id: String, ids: Array) -> void:
	var all: Dictionary = data.get("missions_completed", {})
	var safe: Array[String] = []
	for item in ids:
		if typeof(item) == TYPE_STRING:
			safe.append(item)
	all[world_id] = safe
	data["missions_completed"] = all

func add_story(story_id: String) -> void:
	var list: Array = data.get("storybook", [])
	if not list.has(story_id):
		list.append(story_id)
		data["storybook"] = list

func has_story(story_id: String) -> bool:
	return data.get("storybook", []).has(story_id)

func get_storybook() -> Array:
	return data.get("storybook", []).duplicate()

func set_last_world(world_id: String) -> void:
	data["last_world"] = world_id

func get_last_world() -> String:
	return str(data.get("last_world", "eden"))

func get_settings() -> Dictionary:
	var s = data.get("settings", {})
	return s.duplicate(true) if typeof(s) == TYPE_DICTIONARY else {}

func set_settings(values: Dictionary) -> void:
	data["settings"] = values.duplicate(true)
