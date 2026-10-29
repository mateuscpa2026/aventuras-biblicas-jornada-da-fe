extends Node
## Teste funcional headless: dados, cadeias de missões, conclusão de capítulos,
## persistência, recarga e recuperação de save corrompido.
## Executar: godot --headless --path . res://tests/smoke_test.tscn

var failures := 0
var checks := 0
var _snapshot := {}

func _ready() -> void:
	await get_tree().process_frame
	_snapshot_save()
	print("[test] === Aventuras Bíblicas — teste funcional ===")
	_test_data()
	_test_audio()
	await _test_characters_and_badge()
	await _test_player_looks()
	await _test_story_cast()
	await _test_intro_overlay()
	await _test_camera_look()
	await _test_quiz_dialog()
	await _test_mission_chains()
	_test_persistence()
	_test_reload_scroll_sync()
	_test_corrupt_save()
	_restore_save()
	_stop_all_audio()
	print("[test] === %d checagens, %d falhas ===" % [checks, failures])
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _stop_all_audio() -> void:
	if Audio._music_tween and Audio._music_tween.is_valid():
		Audio._music_tween.kill()
	for child in Audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	Audio._current_music = ""

# ------------------------------------------------------------------ utilidades

func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("[test] ok   ", message)
	else:
		failures += 1
		printerr("[test] FAIL ", message)

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
	print("[test] save original restaurado")

func _json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

# ------------------------------------------------------------------ dados

func _test_data() -> void:
	print("[test] --- integridade dos dados ---")
	var chapters = _json("res://data/chapters.json")
	expect(typeof(chapters) == TYPE_ARRAY, "chapters.json é uma lista")
	expect(typeof(chapters) == TYPE_ARRAY and chapters.size() == 5, "existem 5 capítulos")
	var ids: Array = []
	var scenes_ok := true
	if typeof(chapters) == TYPE_ARRAY:
		for chapter in chapters:
			ids.append(str(chapter.get("id", "")))
			var scene := str(chapter.get("scene", ""))
			if scene == "" or not ResourceLoader.exists(scene):
				scenes_ok = false
			for key in ["title", "subtitle", "intro", "goal", "teaching", "verse_ref", "verse_text", "verse_kind"]:
				if str(chapter.get(key, "")).strip_edges() == "":
					failures += 1
					printerr("[test] FAIL capítulo %s sem campo %s" % [chapter.get("id", "?"), key])
				checks += 1
	expect(scenes_ok, "todas as cenas de capítulo existem")
	expect(ids == ["eden", "ark", "david", "moses", "jesus"], "ordem dos capítulos correta")

	var expected_cast := {
		"eden": ["adao", "eva"],
		"ark": ["noe", "sem"],
		"david": ["davi", "samuel"],
		"moses": ["moises", "miria"],
		"jesus": ["jesus", "maria"],
	}
	if typeof(chapters) == TYPE_ARRAY:
		for chapter in chapters:
			var world_id := str(chapter.get("id", ""))
			var cast: Array = chapter.get("cast", [])
			expect(cast.size() == 2, "%s destaca dois personagens principais" % world_id)
			for member_id in cast:
				expect(StoryCast.is_valid(str(member_id)), "%s: personagem %s registrado" % [world_id, member_id])
			if expected_cast.has(world_id):
				expect(cast == expected_cast[world_id], "%s: personagens bíblicos corretos" % world_id)
		expect(StoryCast.names_of_chapter(chapters[0]) == "Adão e Eva", "nomes dos personagens são legíveis")

	var stories = _json("res://data/bible_stories/stories.json")
	expect(typeof(stories) == TYPE_ARRAY, "stories.json é uma lista")
	var story_ids: Array = []
	var stories_ok := true
	var scroll_bundles := {}
	if typeof(stories) == TYPE_ARRAY:
		expect(stories.size() >= 50, "existem %d passagens bíblicas (mínimo 50)" % stories.size())
		for story in stories:
			var sid := str(story.get("id", ""))
			story_ids.append(sid)
			if not ids.has(str(story.get("world", ""))):
				stories_ok = false
			for key in ["title", "reference", "paraphrase", "explanation", "icon"]:
				if str(story.get(key, "")).strip_edges() == "":
					stories_ok = false
			if str(story.get("paraphrase", "")) == str(story.get("explanation", "")):
				stories_ok = false
			var scroll_id := str(story.get("scroll", sid))
			scroll_bundles[scroll_id] = int(scroll_bundles.get(scroll_id, 0)) + 1
	expect(stories_ok, "histórias têm referência, paráfrase e explicação distintas")
	expect(scroll_bundles.size() == 15, "15 pergaminhos abrem as coleções (%d)" % scroll_bundles.size())
	for scroll_id in scroll_bundles:
		expect(story_ids.has(str(scroll_id)), "coleção %s tem passagem-âncora" % scroll_id)
		expect(int(scroll_bundles[scroll_id]) >= 3, "coleção %s reúne 3+ passagens" % scroll_id)
	for world_id in ids:
		var world_count := 0
		for story in stories:
			if str(story.get("world", "")) == world_id:
				world_count += 1
		expect(world_count >= 10, "%s tem 10+ passagens (%d)" % [world_id, world_count])

	var quizzes = _json("res://data/quizzes.json")
	expect(typeof(quizzes) == TYPE_DICTIONARY, "quizzes.json é um dicionário")

	for world_id in ids:
		var missions = _json("res://data/missions/%s.json" % world_id)
		expect(typeof(missions) == TYPE_ARRAY and missions.size() > 0, "missões de %s carregam" % world_id)
		if typeof(missions) != TYPE_ARRAY:
			continue
		var mission_ids: Array = []
		for mission in missions:
			mission_ids.append(str(mission.get("id", "")))
		var has_final := false
		for mission in missions:
			var mid := str(mission.get("id", ""))
			expect(str(mission.get("event", "")) != "", "%s tem evento" % mid)
			expect(int(mission.get("target", 0)) >= 1, "%s tem alvo válido" % mid)
			expect(str(mission.get("title", "")) != "" and str(mission.get("objective", "")) != "", "%s tem título/objetivo" % mid)
			for required in mission.get("requires", []):
				expect(mission_ids.has(str(required)), "%s depende de missão existente (%s)" % [mid, required])
			var match: Dictionary = mission.get("match", {})
			if match.has("quiz"):
				expect(quizzes.has(str(match["quiz"])), "%s referencia quiz existente" % mid)
			if match.has("npc"):
				var dialogues = _json("res://data/dialogues/%s.json" % world_id)
				expect(dialogues.get("npcs", {}).has(str(match["npc"])), "%s referencia NPC com diálogo" % mid)
			if str(mission.get("reward_story", "")) != "":
				expect(story_ids.has(str(mission["reward_story"])), "%s recompensa história existente" % mid)
			if bool(mission.get("is_final", false)):
				has_final = true
		expect(has_final, "%s tem missão final" % world_id)

		var dialogues = _json("res://data/dialogues/%s.json" % world_id)
		expect(typeof(dialogues) == TYPE_DICTIONARY and dialogues.has("npcs"), "diálogos de %s carregam" % world_id)
		var npcs: Dictionary = dialogues.get("npcs", {}) if typeof(dialogues) == TYPE_DICTIONARY else {}
		expect(npcs.size() >= 2, "%s tem pelo menos 2 NPCs com diálogo" % world_id)
		for npc_id in npcs.keys():
			var lines: Array = npcs[npc_id].get("lines", [])
			expect(lines.size() >= 2, "%s/%s tem falas" % [world_id, npc_id])
			for line in lines:
				if str(line.get("text", "")).strip_edges() == "":
					failures += 1
					printerr("[test] FAIL fala vazia em %s/%s" % [world_id, npc_id])
				checks += 1

# ------------------------------------------------------------------ áudio

func _test_audio() -> void:
	print("[test] --- áudio provisório ---")
	for sfx_name in ["click", "collect", "success", "interact", "jump", "wrong", "throw", "deliver"]:
		var path := "res://assets/audio/sfx/%s.wav" % sfx_name
		expect(ResourceLoader.exists(path), "efeito %s existe" % sfx_name)
		var stream = load(path) if ResourceLoader.exists(path) else null
		expect(stream is AudioStreamWAV and stream.get_length() > 0.02, "efeito %s carrega" % sfx_name)
	var music_files := {
		"menu": "trilha_menu", "eden": "trilha_eden", "ark": "trilha_arca",
		"david": "trilha_davi", "moses": "trilha_moises", "jesus": "trilha_jesus",
	}
	for world_id in music_files:
		var path := "res://assets/audio/music/%s.wav" % music_files[world_id]
		expect(ResourceLoader.exists(path), "música %s existe" % world_id)
		var stream = load(path) if ResourceLoader.exists(path) else null
		expect(stream is AudioStreamWAV and stream.get_length() >= 10.0, "música %s carrega em loop" % world_id)

	if ResourceLoader.exists("res://assets/audio/music/trilha_eden.wav"):
		Audio.play_music("eden")
		expect(Audio._current_music != "", "música de Éden inicia")
		var music_stream: AudioStream = Audio._music.stream
		if music_stream is AudioStreamWAV:
			expect(music_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "música em loop contínuo")
			var frames := int(round(music_stream.get_length() * music_stream.mix_rate))
			expect(abs(music_stream.loop_end - frames) <= 2, "loop cobre a música inteira (%d amostras)" % music_stream.loop_end)
		Audio.play_sfx("click")
		Audio.stop_music(false)
		_stop_all_audio()

# ------------------------------------------------------------------ personagens

func _test_characters_and_badge() -> void:
	print("[test] --- personagens e botão de interação ---")
	var male := StylizedRig.new()
	male.configure({"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband"})
	add_child(male)
	await get_tree().process_frame
	expect(male.built, "boneco masculino é construído")
	expect(male.find_child("Skirt", true, false) != null, "túnica masculina tem saia curta")
	expect(male.find_child("Headwear", true, false) != null, "homem com faixa na cabeça")
	expect(male.find_child("Veil", true, false) == null, "homem sem véu")
	expect(male.find_child("Sole", true, false) != null, "sandálias com sola")
	male.queue_free()

	var female := StylizedRig.new()
	female.configure({"gender": "female", "outfit": "dress", "hair_style": "braid", "headwear": "veil", "jewelry": true})
	add_child(female)
	await get_tree().process_frame
	expect(female.outfit == "dress", "roupa feminina é vestido comprido")
	expect(female.find_child("Braid*", true, false) != null, "trança no cabelo feminino")
	expect(female.find_child("Veil", true, false) != null, "véu feminino")
	expect(female.find_child("Bracelet", true, false) != null, "bracelete feminino")
	expect(female.find_child("Toe", true, false) != null, "dedos aparecem nas sandálias")
	female.queue_free()

	var elder := StylizedRig.new()
	elder.configure({"gender": "male", "outfit": "robe", "headwear": "turban", "veil": Color("#d9c8a3")})
	add_child(elder)
	await get_tree().process_frame
	elder.add_beard(Color("#eee7d8"))
	expect(elder.find_child("Headwear", true, false) != null, "turbante do ancião")
	expect(elder.find_child("TurbanWrap", true, false) != null, "voltas do turbante")
	expect(elder.find_child("Beard", true, false) != null, "barba do ancião")
	elder.queue_free()

	var interactable := Interactable.new()
	interactable.name = "TestInteractable"
	add_child(interactable)
	interactable.show_prompt("Falar com Adão")
	await get_tree().process_frame
	expect(interactable.prompt_badge != null, "interação cria botão flutuante")
	expect(interactable.prompt_badge.visible, "botão flutuante fica visível")
	expect(interactable.prompt_badge.has_text("Falar com Adão"), "botão mostra a ação do NPC")
	interactable.hide_prompt()
	expect(not interactable.prompt_badge.visible, "botão some ao sair de perto")
	interactable.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------ escolha do explorador

func _test_player_looks() -> void:
	print("[test] --- escolha do explorador ---")
	var ids := PlayerLooks.ids()
	expect(ids.size() == 4, "existem 4 exploradores para escolher")
	expect(ids.has(PlayerLooks.DEFAULT_ID), "explorador padrão está na lista")
	var unique := {}
	for id in ids:
		unique[id] = true
	expect(unique.size() == ids.size(), "cada explorador tem identificador próprio")
	expect(PlayerLooks.is_valid(ids[0]) and not PlayerLooks.is_valid("ninguem"), "validação de explorador")
	var boys := []
	var girls := []
	for id in ids:
		var gender := str(PlayerLooks.colors(id).get("gender", ""))
		expect(gender == "male" or gender == "female", "%s tem gênero definido" % id)
		if gender == "male":
			boys.append(id)
		else:
			girls.append(id)
	expect(boys.size() == 2 and girls.size() == 2, "dois meninos e duas meninas para escolher")
	var names := {}
	for id in ids:
		var display := PlayerLooks.name_of(id)
		expect(display != "" and display != "Explorador", "%s tem nome bíblico" % id)
		names[display] = true
	expect(names.size() == 4, "os nomes bíblicos são diferentes entre si")
	expect(names.has("Josué") and names.has("Daniel"), "os meninos têm nomes bíblicos")
	expect(names.has("Ester") and names.has("Sara"), "as meninas têm nomes bíblicos")

	for id in ids:
		var colors := PlayerLooks.colors(id)
		expect(colors.has("skin") and colors.has("hair") and colors.has("tunic") and colors.has("iris"),
			"%s tem cores de pele, cabelo, olhos e roupa" % id)
		expect(colors.has("gender") and colors.has("outfit"), "%s tem vestimenta definida" % id)
		var rig := StylizedRig.new()
		PlayerLooks.apply(rig, id)
		add_child(rig)
		await get_tree().process_frame
		expect(rig.built, "%s é construído na prévia 3D" % id)
		expect(rig.gender == str(colors["gender"]), "%s usa o gênero correto" % id)
		expect(rig.outfit == str(colors["outfit"]), "%s usa a roupa correta" % id)
		expect(rig.find_child("Head", true, false) != null, "%s tem cabeça visível" % id)
		rig.queue_free()
		await get_tree().process_frame

	var original := SaveSystem.get_player_look()
	SaveSystem.set_player_look(ids[1])
	expect(SaveSystem.get_player_look() == ids[1], "escolha fica guardada no save")
	SaveSystem.set_player_look("nao_existe")
	expect(SaveSystem.get_player_look() == PlayerLooks.DEFAULT_ID, "explorador inválido volta ao padrão")
	SaveSystem.set_player_look(original)

	var screen := CharacterSelectScreen.new()
	add_child(screen)
	await get_tree().process_frame
	screen.open(false)
	expect(screen.visible, "tela de escolha abre")
	expect(screen._cards.size() == 4, "a tela mostra um cartão por explorador")
	expect(screen._previews.size() == 4, "cada cartão tem prévia 3D própria")
	expect(screen._previews[0]["viewport"].render_target_update_mode == SubViewport.UPDATE_ALWAYS,
		"prévias são renderizadas ao abrir")
	screen._select(ids[2])
	expect(screen._selected == ids[2], "criança pode trocar a seleção")
	expect(screen._checks[ids[2]].visible, "marca aparece no explorador escolhido")
	expect(not screen._checks[ids[0]].visible, "marca antiga some")
	var emitted := []
	screen.changed.connect(func(look_id): emitted.append(look_id))
	screen._on_confirm()
	expect(emitted.size() == 1 and emitted[0] == ids[2], "confirmar avisa o explorador escolhido")
	screen.hide_screen()
	expect(not screen.visible, "tela de escolha fecha")
	expect(screen._previews[0]["viewport"].render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"prévias param de renderizar ao fechar")
	screen.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------ personagens da história

func _test_story_cast() -> void:
	print("[test] --- personagens principais ---")
	expect(StoryCast.ids().size() == 10, "dez personagens principais registrados")
	var names := {}
	for member_id in StoryCast.ids():
		var member := StoryCast.member(member_id)
		expect(str(member.get("name", "")) != "", "%s tem nome bíblico" % member_id)
		expect(str(member.get("role", "")) != "", "%s tem papel na história" % member_id)
		var look: Dictionary = StoryCast.look(member_id)
		expect(look.has("skin") and look.has("tunic") and look.has("gender"), "%s tem visual completo" % member_id)
		var rig := StylizedRig.new()
		rig.configure(look)
		add_child(rig)
		await get_tree().process_frame
		expect(rig.built and rig.find_child("Head", true, false) != null, "%s monta o retrato 3D" % member_id)
		rig.queue_free()
		await get_tree().process_frame
		names[str(member.get("name", ""))] = true
	expect(names.size() == 10, "os dez personagens têm nomes diferentes")
	expect(StoryCast.names_of(["adao", "eva"]) == "Adão e Eva", "dois nomes são unidos por 'e'")
	expect(StoryCast.names_of(["adao", "eva", "noe"]) == "Adão, Eva e Noé", "três nomes usam vírgula e 'e'")
	expect(StoryCast.names_of([]) == "", "lista vazia não gera texto")
	expect(not StoryCast.is_valid("ninguem"), "personagem desconhecido é recusado")

func _cast_labels(overlay: IntroOverlay) -> Array:
	var texts := []
	for card in overlay._cast_box.get_children():
		for node in card.find_children("*", "Label", true, false):
			if node is Label:
				texts.append(node.text)
	return texts

func _test_intro_overlay() -> void:
	print("[test] --- abertura com personagens ---")
	var overlay := IntroOverlay.new()
	add_child(overlay)
	await get_tree().process_frame
	overlay.show_chapter(Game.get_chapter("eden"))
	await get_tree().process_frame
	expect(overlay.visible, "abertura do capítulo aparece")
	expect(overlay._cast_box.get_child_count() == 2, "abertura mostra dois retratos")
	expect(overlay._cast_previews.size() == 2, "retratos têm prévias 3D próprias")
	var always := true
	for entry in overlay._cast_previews:
		if entry["viewport"].render_target_update_mode != SubViewport.UPDATE_ALWAYS:
			always = false
		expect(entry["rig"].built, "retrato 3D do personagem é montado")
	expect(always, "retratos renderizam ao abrir")
	var texts := _cast_labels(overlay)
	expect(texts.has("Adão") and texts.has("Eva"), "nomes dos personagens aparecem")
	expect(overlay._card.get_combined_minimum_size().y <= 700.0,
		"cartão cabe na tela de 720p (%.0f px)" % overlay._card.get_combined_minimum_size().y)

	overlay.show_chapter(Game.get_chapter("david"))
	await get_tree().process_frame
	texts = _cast_labels(overlay)
	expect(texts.has("Davi") and texts.has("Samuel"), "trocar de capítulo troca os personagens")
	expect(overlay._cast_box.get_child_count() == 2, "retratos antigos são substituídos")
	overlay.skip()
	expect(not overlay.visible, "abertura fecha ao começar")
	var disabled := true
	for entry in overlay._cast_previews:
		if entry["viewport"].render_target_update_mode != SubViewport.UPDATE_DISABLED:
			disabled = false
	expect(disabled, "retratos param de renderizar ao fechar")
	overlay.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------ câmera

func _push_mouse_motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _push_wheel(button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _test_camera_look() -> void:
	print("[test] --- câmera com mouse ---")
	var camera := PlayerCamera.new()
	add_child(camera)
	await get_tree().process_frame
	expect(camera.camera != null and camera.camera.current, "câmera de terceira pessoa fica ativa")

	var start_yaw := camera.target_yaw
	var start_pitch := camera.target_pitch
	_push_mouse_motion(Vector2(160, 0))
	await get_tree().process_frame
	expect(not is_equal_approx(camera.target_yaw, start_yaw), "mouse na horizontal gira a câmera")
	expect(camera.target_yaw < start_yaw, "arrastar para a direita gira para a direita")
	expect(is_equal_approx(camera.target_pitch, start_pitch), "girar na horizontal não inclina a câmera")

	_push_mouse_motion(Vector2(0, 90))
	await get_tree().process_frame
	expect(camera.target_pitch < start_pitch, "mouse para baixo inclina a câmera")

	_push_mouse_motion(Vector2(0, 4000))
	await get_tree().process_frame
	expect(is_equal_approx(camera.target_pitch, deg_to_rad(-58.0)), "inclinação para baixo respeita o limite")
	_push_mouse_motion(Vector2(0, -8000))
	await get_tree().process_frame
	expect(is_equal_approx(camera.target_pitch, deg_to_rad(26.0)), "inclinação para cima respeita o limite")

	var yaw_before_pause := camera.target_yaw
	camera.set_enabled(false)
	_push_mouse_motion(Vector2(200, 0))
	await get_tree().process_frame
	expect(is_equal_approx(camera.target_yaw, yaw_before_pause), "controles desligados não giram a câmera")
	camera.set_enabled(true)

	var length_before := camera.target_length
	_push_wheel(MOUSE_BUTTON_WHEEL_UP)
	await get_tree().process_frame
	expect(camera.target_length < length_before, "roda do mouse aproxima a câmera")
	camera.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------ quiz

func _test_quiz_dialog() -> void:
	print("[test] --- desafio da memória (interface) ---")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/quizzes.json"))
	expect(typeof(parsed) == TYPE_DICTIONARY, "quizzes.json carrega para o teste de interface")
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("eden_final"):
		return
	var quiz: Dictionary = parsed["eden_final"]
	var questions: Array = quiz.get("questions", [])

	var dialog := QuizDialog.new()
	add_child(dialog)
	await get_tree().process_frame
	expect(dialog.open("eden_final"), "quiz de Éden abre")
	expect(dialog.visible, "tela do quiz fica visível")
	expect(dialog._options_box.get_child_count() == (questions[0].get("options", []) as Array).size(),
		"quiz mostra todas as opções da primeira pergunta")

	var wrong: int = (int(questions[0].get("answer", 0)) + 1) % max(1, dialog._options_box.get_child_count())
	dialog._answer(wrong)
	expect(dialog._index == 0 and not dialog._passed, "resposta errada não avança nem encerra")
	expect(dialog._feedback_label.visible, "resposta errada mostra uma dica")

	for i in questions.size():
		dialog._answer(int(questions[i].get("answer", -1)))
		await get_tree().create_timer(1.45).timeout
		if i + 1 < questions.size():
			expect(dialog._index == i + 1, "pergunta %d avança após acertar" % (i + 1))
	expect(dialog._passed, "quiz conclui ao acertar todas as perguntas")
	expect(dialog._complete_box.visible, "tela de conclusão do quiz aparece")

	var closed_state := {"called": false, "passed": false}
	dialog.closed.connect(func(passed: bool) -> void:
		closed_state["called"] = true
		closed_state["passed"] = passed
	)
	dialog._close()
	expect(closed_state["called"] and closed_state["passed"], "quiz fecha informando sucesso")
	expect(not dialog.visible, "quiz some da tela ao fechar")
	dialog.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------ missões

func _test_mission_chains() -> void:
	print("[test] --- cadeias de missões ---")
	SaveSystem.new_game(false)
	Missions.reset_runtime()

	await _run_world("eden", [
		["eden_animais", "care_animal", 5, {}],
		["eden_flores", "water_plant", 3, {}],
		["eden_pergaminhos", "collect_scroll", 3, {}],
		["eden_memoria", "quiz_complete", 1, {"quiz": "eden_final"}],
	], ["criacao", "eden_jardim", "eden_animais"])
	expect(SaveSystem.is_chapter_completed("eden"), "capítulo Éden concluído")
	expect(SaveSystem.is_chapter_unlocked("ark"), "Arca desbloqueada após Éden")

	await _run_world("ark", [
		["ark_animais", "animal_delivered", 4, {}],
		["ark_provisoes", "supply_stored", 3, {}],
		["ark_pergaminhos", "collect_scroll", 3, {}],
		["ark_memoria", "quiz_complete", 1, {"quiz": "ark_final"}],
	], ["arca_construcao", "diluvio", "arco_iris"])
	expect(SaveSystem.is_chapter_unlocked("david"), "Davi desbloqueado após Arca")

	await _run_world("david", [
		["david_conversa", "talk", 1, {"npc": "davi"}],
		["david_ovelhas", "sheep_penned", 3, {}],
		["david_pergaminhos", "collect_scroll", 3, {}],
		["david_alvos", "target_hit", 3, {}],
	], ["davi_pastor", "davi_golias", "coragem_fe"])
	expect(SaveSystem.is_chapter_unlocked("moses"), "Moisés desbloqueado após Davi")

	await _run_world("moses", [
		["moses_povo", "traveler_arrived", 3, {}],
		["moses_braseiros", "beacon_lit", 3, {}],
		["moses_pergaminhos", "collect_scroll", 3, {}],
		["moses_travessia", "sea_crossed", 1, {}],
	], ["moses_chamado", "mar_vermelho", "povo_liberdade"])
	expect(SaveSystem.is_chapter_unlocked("jesus"), "Jesus desbloqueado após Moisés")

	await _run_world("jesus", [
		["jesus_paes", "bread_delivered", 3, {}],
		["jesus_ovelha", "sheep_returned", 1, {}],
		["jesus_perdao", "choice", 1, {"tag": "perdoar"}],
		["jesus_pergaminhos", "collect_scroll", 3, {}],
		["jesus_monte", "villager_arrived", 3, {}],
	], ["bom_samaritano", "ovelha_perdida", "filho_prodigo"])
	expect(SaveSystem.is_chapter_completed("jesus"), "capítulo Jesus concluído")
	expect(Missions.is_world_done(), "todos os objetivos do último mundo concluídos")
	expect(Story.count_unlocked("jesus") == Story.get_world_stories("jesus").size(),
		"todas as histórias de Jesus desbloqueadas (%d)" % Story.get_world_stories("jesus").size())

func _run_world(world_id: String, steps: Array, scroll_stories: Array) -> void:
	Missions.load_world(world_id)
	expect(Missions.current_world == world_id, "%s carregado no gerenciador" % world_id)
	var active := Missions.get_active()
	expect(active.size() >= 1, "%s começa com missão ativa" % world_id)

	var scroll_index := 0
	for step in steps:
		var mission_id: String = step[0]
		var event_name: String = step[1]
		var times: int = step[2]
		var payload: Dictionary = step[3]
		expect(Missions.is_active(mission_id), "%s ativa antes do evento %s" % [mission_id, event_name])
		var def := Missions.get_def(mission_id)
		expect(int(def.get("target", 0)) == times, "%s tem alvo %d" % [mission_id, times])
		for i in times:
			if event_name == "collect_scroll":
				var story_id := str(scroll_stories[mini(scroll_index, scroll_stories.size() - 1)])
				Story.unlock_bundle(story_id)
				scroll_index += 1
			Missions.notify_event(event_name, 1, payload)
		expect(Missions.is_mission_completed(mission_id), "%s concluída após %d eventos" % [mission_id, times])
	expect(Missions.is_world_done(), "%s totalmente concluído" % world_id)
	var world_stories := Story.get_world_stories(world_id)
	var all_unlocked := world_stories.size() >= 10
	for story in world_stories:
		if not Story.is_unlocked(str(story["id"])):
			all_unlocked = false
	expect(all_unlocked, "%s: os 3 pergaminhos abrem todas as %d passagens" % [world_id, world_stories.size()])

	# Eventos duplicados depois da conclusão não devem alterar nada.
	Missions.notify_event("care_animal", 5, {})
	expect(Missions.is_world_done(), "%s permanece concluído após eventos extras" % world_id)

# ------------------------------------------------------------------ persistência

func _test_persistence() -> void:
	print("[test] --- persistência e recarga ---")
	expect(SaveSystem.write(), "gravação do save funciona")
	expect(SaveSystem.last_error == "", "gravação sem erro")
	SaveSystem.data = {}
	SaveSystem.load_game()
	expect(SaveSystem.is_chapter_completed("eden"), "Éden concluído persistiu após reload")
	expect(SaveSystem.is_chapter_completed("jesus"), "Jesus concluído persistiu após reload")
	expect(SaveSystem.is_chapter_unlocked("jesus"), "capítulos desbloqueados persistiram")
	expect(SaveSystem.get_completed_missions("moses").size() == 4, "missões de Moisés persistiram")
	expect(SaveSystem.get_storybook().size() == Story.stories.size() and Story.stories.size() >= 50,
		"%d histórias no livro persistiram" % Story.stories.size())
	expect(SaveSystem.get_last_world() == "jesus", "último mundo salvo é Jesus")

	Missions.load_world("eden")
	expect(Missions.is_world_done(), "Éden recarregado não reabre missões concluídas")

# ------------------------------------------------------------------ recarga com colecionáveis

func _test_reload_scroll_sync() -> void:
	print("[test] --- retomada de missão de colecionáveis ---")
	SaveSystem.new_game(false)
	Missions.reset_runtime()
	Missions.load_world("eden")
	Missions.notify_event("care_animal", 5, {})
	expect(Missions.is_mission_completed("eden_animais"), "Éden: animais concluídos")
	expect(Missions.is_active("eden_pergaminhos"), "missão de pergaminhos começa após animais")

	Story.unlock_bundle("criacao")
	Story.unlock_bundle("eden_jardim")
	Missions.notify_event("collect_scroll", 2, {})
	expect(Missions.get_progress("eden_pergaminhos") == 2, "progresso de pergaminhos é 2")
	expect(Story.count_unlocked("eden") > 2, "2 pergaminhos abrem mais de 2 passagens")

	# Simula sair e voltar com os pergaminhos já guardados.
	Missions.reset_runtime()
	Missions.load_world("eden")
	expect(Missions.get_progress("eden_pergaminhos") == 2, "progresso reconstruído do livro após recarregar")
	expect(not Missions.is_mission_completed("eden_pergaminhos"), "missão segue aberta com 2/3")

	Story.unlock_bundle("eden_animais")
	Missions.reset_runtime()
	Missions.load_world("eden")
	expect(Missions.is_mission_completed("eden_pergaminhos"), "missão de pergaminhos completa ao ter os 3 guardados")
	expect(Story.count_unlocked("eden") == Story.get_world_stories("eden").size(),
		"as 11 passagens de Éden ficam guardadas após os 3 pergaminhos")
	expect(Missions.is_active("eden_memoria"), "desafio final abre depois dos pergaminhos")

# ------------------------------------------------------------------ save corrompido

func _test_corrupt_save() -> void:
	print("[test] --- save corrompido ---")
	var file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
	expect(file != null, "consegue preparar arquivo corrompido")
	if file:
		file.store_string("{ isto não é json")
		file.close()
	if FileAccess.file_exists(SaveSystem.BACKUP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.BACKUP_PATH))
	var loaded := SaveSystem.load_game()
	expect(not loaded, "save corrompido é rejeitado")
	expect(SaveSystem.last_error != "", "erro de save corrompido é registrado")
	expect(SaveSystem.data.get("unlocked_chapters", []) == ["eden"], "progresso volta ao padrão seguro")
