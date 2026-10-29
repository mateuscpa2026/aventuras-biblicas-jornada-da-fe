extends Node
## Teste de integração das cinco cenas de mundo: instancia cada cena, confere
## jogador, colisão básica, NPCs, diálogo, pergaminhos, pedra da memória e a
## cadeia de missões até concluir o capítulo.
## Executar: godot --headless --path . res://tests/world_test.tscn

const WORLDS := ["eden", "ark", "david", "moses", "jesus"]

var checks := 0
var failures := 0
var _snapshot := {}
var _quiz_requests: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_snapshot_save()
	Game.quiz_requested.connect(_on_quiz_requested)
	print("[world] === teste de integração das cenas ===")
	SaveSystem.new_game(false)
	Missions.reset_runtime()
	for world_id in WORLDS:
		await _test_world(world_id)
	_restore_save()
	_silence_audio()
	print("[world] === %d checagens, %d falhas ===" % [checks, failures])
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _silence_audio() -> void:
	if Audio._music_tween and Audio._music_tween.is_valid():
		Audio._music_tween.kill()
	for child in Audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	Audio._current_music = ""

func _on_quiz_requested(quiz_id: String) -> void:
	_quiz_requests.append(quiz_id)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("[world] ok   ", message)
	else:
		failures += 1
		printerr("[world] FAIL ", message)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _snapshot_save() -> void:
	for path in [SaveSystem.SAVE_PATH, SaveSystem.BACKUP_PATH, SaveSystem.TEMP_PATH]:
		_snapshot[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null

func _restore_save() -> void:
	for path in _snapshot.keys():
		var content = _snapshot[path]
		if content == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file:
				file.store_string(str(content))
				file.close()
	if FileAccess.file_exists(SaveSystem.TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.TEMP_PATH))
	print("[world] save original restaurado")

func _find(root: Node, kind: String) -> Array:
	var result: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if kind == "npc" and node is NPCCharacter:
			result.append(node)
		elif kind == "animal" and node is AnimalCharacter:
			result.append(node)
		elif kind == "scroll" and node is ScrollPickup:
			result.append(node)
		elif kind == "quiz" and node is QuizStation:
			result.append(node)
		elif kind == "prop" and node is SimpleProp:
			result.append(node)
		elif kind == "interactable" and node is Interactable:
			result.append(node)
		stack.append_array(node.get_children())
	return result

func _json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _count_bodies_under(root: Node, marker: String) -> int:
	var total := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var parent := node.get_parent()
		if node is StaticBody3D and parent != null and parent.get_node_or_null(marker) != null:
			total += 1
		stack.append_array(node.get_children())
	return total

func _count_hill_bodies(root: Node) -> int:
	var total := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var parent := node.get_parent()
		if node is StaticBody3D and parent != null and str(parent.name).begins_with("Hill"):
			total += 1
		stack.append_array(node.get_children())
	return total

func _first_bush(root: Node) -> Node3D:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Node3D and node.get_node_or_null("BushLight") != null:
			return node
		stack.append_array(node.get_children())
	return null

func _bush_body(bush: Node) -> StaticBody3D:
	for child in bush.get_children():
		if child is StaticBody3D:
			return child
	return null

func _final_mission_id(world_id: String) -> String:
	var missions = _json("res://data/missions/%s.json" % world_id)
	if typeof(missions) != TYPE_ARRAY:
		return ""
	for mission in missions:
		if bool(mission.get("is_final", false)):
			return str(mission.get("id", ""))
	return ""

# ------------------------------------------------------------------ um mundo

func _test_world(world_id: String) -> void:
	print("[world] --- ", world_id, " ---")
	SaveSystem.new_game(false)
	Missions.reset_runtime()
	_quiz_requests.clear()

	var packed: PackedScene = load("res://scenes/worlds/%s.tscn" % world_id)
	expect(packed != null, "%s: cena carrega" % world_id)
	if packed == null:
		return
	var world = packed.instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame

	expect(str(world.world_id) == world_id, "%s: mundo se identifica" % world_id)
	expect(not world.chapter.is_empty(), "%s: capítulo carregado" % world_id)
	expect(Missions.current_world == world_id, "%s: missões carregadas com o mundo" % world_id)
	expect(Dialogue.current_world == world_id, "%s: diálogos carregados com o mundo" % world_id)

	var player: PlayerCharacter = world.player
	expect(is_instance_valid(player), "%s: jogador existe" % world_id)
	expect(Game.get_player() == player, "%s: jogador registrado no sistema" % world_id)
	if is_instance_valid(player):
		var camera := player.get_camera()
		expect(camera != null and camera.far > 0.0, "%s: câmera em terceira pessoa pronta" % world_id)
		var start := player.global_position
		player.global_position = world.spawn_position + Vector3(0, 4.0, 0)
		player.velocity = Vector3.ZERO
		await _wait(1.4)
		expect(player.is_on_floor(), "%s: jogador cai e pousa no chão" % world_id)
		expect(player.global_position.y < start.y + 1.6, "%s: jogador não atravessa o cenário" % world_id)

	var bush_bodies := _count_bodies_under(world, "BushLight")
	expect(bush_bodies >= 6, "%s: arbustos têm colisores sólidos (%d)" % [world_id, bush_bodies])
	var hill_bodies := _count_hill_bodies(world)
	expect(hill_bodies >= 12, "%s: montanhas têm colisores sólidos (%d)" % [world_id, hill_bodies])
	var bush := _first_bush(world)
	expect(bush != null, "%s: cena tem vegetação para testar" % world_id)
	if bush != null:
		await get_tree().physics_frame
		var from: Vector3 = bush.global_position + Vector3(0, 2.0, 0)
		var to: Vector3 = bush.global_position + Vector3(0, -1.0, 0)
		var hit := get_viewport().world_3d.direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(from, to))
		expect(not hit.is_empty() and hit["collider"] == _bush_body(bush),
			"%s: raio para cima do arbusto bate no colisor dele" % world_id)

	var interactables := _find(world, "interactable")
	expect(interactables.size() >= 6, "%s: cena tem objetos interativos (%d)" % [world_id, interactables.size()])

	var npcs := _find(world, "npc")
	expect(npcs.size() >= 2, "%s: pelo menos 2 NPCs (%d)" % [world_id, npcs.size()])
	var npc_ids := {}
	for npc in npcs:
		npc_ids[npc.npc_id] = true
		expect(Dialogue.has_npc(npc.npc_id), "%s: NPC %s tem diálogo" % [world_id, npc.npc_id])
		expect(str(npc.display_name) != "", "%s: NPC %s tem nome visível" % [world_id, npc.npc_id])
	expect(npc_ids.size() == npcs.size(), "%s: NPCs têm identificadores únicos" % world_id)
	for member_id in world.chapter.get("cast", []):
		expect(npc_ids.has(str(member_id)), "%s: personagem principal %s está no mundo" % [world_id, member_id])

	var talker = null
	for npc in npcs:
		if Dialogue.has_npc(npc.npc_id) and not npc.can_follow:
			talker = npc
			break
	if talker == null and not npcs.is_empty():
		talker = npcs[0]
	if talker != null:
		talker.interact(player)
		expect(Dialogue.is_active, "%s: interagir com %s abre o diálogo" % [world_id, talker.npc_id])
		Dialogue.finish()
		expect(not Dialogue.is_active, "%s: diálogo pode ser encerrado" % world_id)
		expect(talker._talked, "%s: conversa é registrada no NPC" % world_id)

	var animals := _find(world, "animal")
	if world_id != "moses":
		expect(animals.size() >= 1, "%s: cena tem animais (%d)" % [world_id, animals.size()])
	else:
		expect(npcs.size() >= 4, "moses: cena tem viajantes para escoltar (%d)" % npcs.size())

	for animal in animals:
		var rig: AnimalRig = animal.rig
		if rig == null:
			continue
		expect(rig.built, "%s: %s tem corpo montado" % [world_id, animal.kind])
		expect(rig.head != null, "%s: %s tem cabeça" % [world_id, animal.kind])
		expect(rig.find_child("Eye", true, false) != null, "%s: %s tem olhos" % [world_id, animal.kind])
		if animal.kind != "fish" and animal.kind != "bird":
			expect(rig.legs.size() == 4, "%s: %s tem quatro patas" % [world_id, animal.kind])
		expect(animal.animal_name != "" and animal.prompt_text != "",
			"%s: %s tem nome e ação de cuidado" % [world_id, animal.kind])
		if animal.can_follow:
			expect(animal.interact_radius > 0.5, "%s: %s pode ser chamado" % [world_id, animal.kind])

	var scrolls := _find(world, "scroll")
	expect(scrolls.size() == 3, "%s: 3 pergaminhos na cena (%d)" % [world_id, scrolls.size()])
	var collect_mission := ""
	for scroll in scrolls:
		var story_id: String = scroll.story_id
		expect(Story.stories.has(story_id), "%s: pergaminho %s tem história" % [world_id, story_id])
		expect(Story.get_scroll_stories(story_id).size() >= 3,
			"%s: coleção de %s reúne 3+ passagens" % [world_id, story_id])
		if collect_mission == "":
			collect_mission = scroll.required_mission
		expect(scroll.required_mission == collect_mission and collect_mission != "",
			"%s: pergaminho %s protegido pela missão de colecionáveis" % [world_id, story_id])
		expect(not scroll.active and not scroll.visible, "%s: pergaminho %s começa escondido" % [world_id, story_id])
	expect(not Missions.get_def(collect_mission).is_empty(), "%s: missão %s existe" % [world_id, collect_mission])

	var stations := _find(world, "quiz")
	expect(stations.size() >= 1, "%s: pedra da memória presente" % world_id)
	var station: QuizStation = stations[0] if not stations.is_empty() else null
	var quizzes = _json("res://data/quizzes.json")
	if station != null:
		expect(station.quiz_id == "%s_final" % world_id, "%s: pedra usa o quiz final" % world_id)
		expect(typeof(quizzes) == TYPE_DICTIONARY and quizzes.has(station.quiz_id),
			"%s: quiz %s existe no banco de perguntas" % [world_id, station.quiz_id])
		if station.required_mission != "":
			expect(station.get_prompt(null) == "A pedra adormecida", "%s: pedra começa adormecida" % world_id)

	# Cadeia real: completa as missões anteriores até liberar os pergaminhos.
	var advanced := await _advance_until(collect_mission)
	expect(advanced, "%s: missões anteriores são concluídas pelo fluxo" % world_id)
	for scroll in scrolls:
		expect(scroll.active and scroll.visible, "%s: pergaminho %s aparece quando a missão começa" % [world_id, scroll.story_id])

	var unlocked_before := Story.count_unlocked(world_id)
	for scroll in scrolls:
		var story_id: String = scroll.story_id
		scroll.interact(player)
		expect(Story.is_unlocked(story_id), "%s: interagir guarda a história %s" % [world_id, story_id])
	var world_stories := Story.get_world_stories(world_id)
	expect(Story.count_unlocked(world_id) == unlocked_before + world_stories.size(),
		"%s: os 3 pergaminhos abriram as %d passagens do mundo" % [world_id, world_stories.size()])
	var all_unlocked := true
	for story in world_stories:
		if not Story.is_unlocked(str(story["id"])):
			all_unlocked = false
	expect(all_unlocked, "%s: todas as passagens da coleção foram guardadas" % world_id)
	expect(Missions.is_mission_completed(collect_mission), "%s: missão de pergaminhos concluída ao pegar os 3" % world_id)

	if station != null:
		if station.required_mission != "":
			expect(Missions.is_mission_completed(station.required_mission) == false,
				"%s: desafio final ainda não estava concluído" % world_id)
			expect(station.get_prompt(null) != "A pedra adormecida", "%s: pedra desperta depois dos pergaminhos" % world_id)
		station.interact(player)
		expect(_quiz_requests.has(station.quiz_id), "%s: pedra abre o quiz %s" % [world_id, station.quiz_id])

	var final_id := _final_mission_id(world_id)
	var final_def: Dictionary = Missions.get_def(final_id)
	expect(not final_def.is_empty(), "%s: missão final %s existe" % [world_id, final_id])
	if final_def.is_empty():
		world.queue_free()
		await get_tree().process_frame
		return
	await _advance_until(final_id)
	expect(Missions.is_active(final_id) or Missions.is_mission_completed(final_id),
		"%s: missão final fica disponível" % world_id)
	if Missions.is_active(final_id):
		var payload: Dictionary = final_def.get("match", {}).duplicate(true)
		Missions.notify_event(str(final_def["event"]), int(final_def["target"]), payload)
	expect(Missions.is_mission_completed(final_id), "%s: missão final concluída" % world_id)
	expect(SaveSystem.is_chapter_completed(world_id), "%s: capítulo marcado como concluído" % world_id)
	await _complete_remaining()
	expect(Missions.is_world_done(), "%s: todos os objetivos do mundo concluídos" % world_id)
	if world_id != "jesus":
		var next := Game.next_chapter(world_id)
		expect(not next.is_empty() and SaveSystem.is_chapter_unlocked(str(next["id"])),
			"%s: próximo capítulo desbloqueado" % world_id)

	world.queue_free()
	await get_tree().process_frame
	Audio.stop_music(false)
## Conclui missões secundárias que ficaram abertas depois do desafio final.
func _complete_remaining() -> void:
	for _step in 12:
		var pick: Dictionary = {}
		for mission in Missions.get_active():
			if str(mission.get("event", "")) == "collect_scroll":
				continue
			pick = mission
			break
		if pick.is_empty():
			return
		var payload: Dictionary = pick.get("match", {}).duplicate(true)
		Missions.notify_event(str(pick["event"]), int(pick["target"]), payload)
		await get_tree().process_frame

## Completa missões ativas que não sejam a de colecionáveis até a missão alvo
## começar. Usa os próprios eventos declarados em data/missions.
func _advance_until(target_mission: String) -> bool:
	for _step in 16:
		if Missions.is_active(target_mission) or Missions.is_mission_completed(target_mission):
			return true
		var pick: Dictionary = {}
		for mission in Missions.get_active():
			var mission_id := str(mission.get("id", ""))
			if mission_id == target_mission:
				continue
			if str(mission.get("event", "")) == "collect_scroll":
				continue
			pick = mission
			break
		if pick.is_empty():
			return false
		var payload: Dictionary = pick.get("match", {}).duplicate(true)
		Missions.notify_event(str(pick["event"]), int(pick["target"]), payload)
		await get_tree().process_frame
	return Missions.is_active(target_mission) or Missions.is_mission_completed(target_mission)
