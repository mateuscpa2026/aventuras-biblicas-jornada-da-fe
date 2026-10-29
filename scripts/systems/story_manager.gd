extends Node
## Livro de histórias / colecionáveis bíblicos.
## Os textos em data/bible_stories/stories.json são paráfrases educativas originais,
## com referência verificável. Veja docs/CONTEUDO_BIBLICO.md.

signal story_unlocked(story: Dictionary)

const STORIES_PATH := "res://data/bible_stories/stories.json"

var stories: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(STORIES_PATH):
		push_error("Arquivo de histórias não encontrado: " + STORIES_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(STORIES_PATH))
	if typeof(parsed) == TYPE_ARRAY:
		for story in parsed:
			if typeof(story) == TYPE_DICTIONARY and story.has("id"):
				stories[str(story["id"])] = story
	else:
		push_error("data/bible_stories/stories.json inválido.")

func get_story(story_id: String) -> Dictionary:
	return stories.get(story_id, {})

func get_world_stories(world_id: String) -> Array:
	var result: Array = []
	for story in stories.values():
		if str(story.get("world", "")) == world_id:
			result.append(story)
	return result

## Passagens abertas por um pergaminho (coleção temática).
func get_scroll_stories(scroll_id: String) -> Array:
	var result: Array = []
	for story in stories.values():
		if str(story.get("scroll", story.get("id", ""))) == scroll_id:
			result.append(story)
	return result

func unlock_bundle(scroll_id: String) -> Array:
	var unlocked: Array = []
	for story in get_scroll_stories(scroll_id):
		if unlock(str(story["id"])):
			unlocked.append(str(story["id"]))
	return unlocked

## Pergaminhos coletados: cada pergaminho é a passagem-âncora da sua coleção.
func count_unlocked_scrolls(world_id: String) -> int:
	var total := 0
	for story in get_world_stories(world_id):
		var story_id := str(story.get("id", ""))
		if str(story.get("scroll", story_id)) == story_id and SaveSystem.has_story(story_id):
			total += 1
	return total

func count_unlocked(world_id: String) -> int:
	var total := 0
	for story in get_world_stories(world_id):
		if SaveSystem.has_story(str(story["id"])):
			total += 1
	return total

func is_unlocked(story_id: String) -> bool:
	return SaveSystem.has_story(story_id)

func unlock(story_id: String) -> bool:
	if story_id == "" or SaveSystem.has_story(story_id):
		return false
	if not stories.has(story_id):
		push_warning("História desconhecida: " + story_id)
		return false
	SaveSystem.add_story(story_id)
	SaveSystem.write()
	story_unlocked.emit(stories[story_id])
	return true
