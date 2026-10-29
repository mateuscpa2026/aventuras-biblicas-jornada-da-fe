extends Node
## Cérebro do jogo: menu, carregamento dos mundos, pausa, diálogos, quiz e conclusão.
## A cena principal é apenas este nó; o restante é montado em código para manter o fluxo simples.

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const TOAST_SCENE := preload("res://scenes/ui/toast_layer.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/dialogue_box.tscn")
const INTRO_SCENE := preload("res://scenes/ui/intro_overlay.tscn")
const QUIZ_SCENE := preload("res://scenes/ui/quiz_dialog.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_panel.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const BOOK_SCENE := preload("res://scenes/ui/book_panel.tscn")
const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const CHAPTERS_SCENE := preload("res://scenes/ui/chapter_select.tscn")
const CHARACTER_SCENE := preload("res://scenes/ui/character_select.tscn")
const COMPLETE_SCENE := preload("res://scenes/ui/chapter_complete.tscn")

var world_host: Node3D
var menu_stage: Node3D
var menu_camera: Camera3D
var menu_hero: StylizedRig
var ui_layer: CanvasLayer
var menu_layer: CanvasLayer
var overlay_layer: CanvasLayer
var toast_layer: CanvasLayer
var fade_layer: CanvasLayer

var hud: GameHUD
var toast: ToastLayer
var dialogue_box: DialogueBox
var intro: IntroOverlay
var quiz: QuizDialog
var settings_panel: SettingsPanel
var pause_menu: PauseMenu
var book: BookPanel
var main_menu: MainMenuScreen
var chapter_select: ChapterSelectScreen
var character_select: CharacterSelectScreen
var chapter_complete: ChapterCompleteScreen

var world: Node3D = null
var current_chapter: Dictionary = {}
var game_active := false
var modal_stack: Array[String] = []
var pending_chapter_complete := ""
var _transitioning := false
var _menu_time := 0.0
var _fade: ColorRect

var _capture_mode := false
var _capture_dir := ""
var _capture_world := ""
var _save_snapshot: Dictionary = {}

func _ready() -> void:
	Game.set_main(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_world_host()
	_build_menu_stage()
	_build_ui()
	_connect_signals()
	_handle_capture_args()
	if _capture_mode:
		_run_capture()
	else:
		_show_menu()

# ------------------------------------------------------------------ montagem

func _build_world_host() -> void:
	world_host = Node3D.new()
	world_host.name = "WorldHost"
	add_child(world_host)

func _build_menu_stage() -> void:
	seed(11)
	menu_stage = Node3D.new()
	menu_stage.name = "MenuStage"
	add_child(menu_stage)

	EnvBuilder.setup(menu_stage, {
		"sky_top": Color("#7cc7e8"),
		"sky_horizon": Color("#ffeccd"),
		"ground_bottom": Color("#88ad7f"),
		"ground_horizon": Color("#f1ead3"),
		"ambient": Color("#f4e8cf"),
		"ambient_energy": 0.75,
		"sun_rotation": Vector3(-45, -28, 0),
		"sun_color": Color("#fff0c6"),
		"sun_energy": 1.25,
		"fog_density": 0.0012,
		"fog_color": Color("#f6ecd7"),
	})
	EnvBuilder.ground(menu_stage, Color("#7cba77"), 160.0)
	EnvBuilder.hills(menu_stage, Color("#8fbf8a"), 15, 36.0, 64.0)
	EnvBuilder.clouds(menu_stage, 10, 19.0)

	var tree_spots := [
		[Vector3(10.5, 0, -1.5), 1.15],
		[Vector3(13.0, 0, -8.0), 1.0],
		[Vector3(7.5, 0, -11.0), 0.9],
		[Vector3(-1.0, 0, 5.0), 1.0],
		[Vector3(11.5, 0, 3.5), 0.85],
	]
	for spot in tree_spots:
		var tree := Props.tree(spot[1], Color("#4f9a54"))
		tree.position = spot[0]
		menu_stage.add_child(tree)

	var pine_positions := [Vector3(14.5, 0, -13.0), Vector3(0.5, 0, -15.0)]
	for position in pine_positions:
		var pine := Props.pine(1.15)
		pine.position = position
		menu_stage.add_child(pine)

	var palm_positions := [Vector3(10.2, 0, 7.5), Vector3(13.4, 0, 1.0)]
	for position in palm_positions:
		var palm := Props.palm(0.85)
		palm.position = position
		menu_stage.add_child(palm)

	for position in [Vector3(5.2, 0, 3.8), Vector3(8.4, 0, 2.1), Vector3(4.0, 0, 0.0)]:
		var bush := Props.bush(0.9)
		bush.position = position
		menu_stage.add_child(bush)
	for position in [Vector3(5.4, 0, 3.9), Vector3(7.2, 0, 4.4), Vector3(4.7, 0, 1.7), Vector3(8.8, 0, 4.2)]:
		var flowers := Props.flower_patch([Color("#f2b544"), Color("#e8846b"), Color("#f7d35c")][randi() % 3], 1.1)
		flowers.position = position
		menu_stage.add_child(flowers)
	for position in [Vector3(11.0, 0, -4.0), Vector3(3.4, 0, -6.5)]:
		var rock := Props.rock(0.8)
		rock.position = position
		menu_stage.add_child(rock)

	for i in 9:
		var stone := Props.part(menu_stage, Props.box_mesh(Vector3(1.5, 0.06, 0.95)),
			Props.mat(Color("#e8d6ab"), 1.0), Vector3(4.6 + sin(float(i)) * 0.35, 0.035, 6.4 - i * 1.55),
			Vector3(0, sin(float(i)) * 8.0, 0))
		stone.name = "Path%d" % i

	var ark := Props.ark()
	ark.position = Vector3(5.0, 0.3, -13.0)
	ark.rotation_degrees.y = 160.0
	ark.scale = Vector3.ONE * 0.85
	menu_stage.add_child(ark)

	var hero := StylizedRig.new()
	hero.name = "MenuHero"
	PlayerLooks.apply(hero, SaveSystem.get_player_look())
	menu_hero = hero
	hero.position = Vector3(6.0, 0, 1.8)
	hero.rotation.y = PI
	menu_stage.add_child(hero)

	var sheep := AnimalRig.new()
	sheep.setup("sheep")
	sheep.position = Vector3(7.5, 0, 2.9)
	sheep.rotation.y = deg_to_rad(-30.0)
	menu_stage.add_child(sheep)

	var rabbit := AnimalRig.new()
	rabbit.setup("rabbit")
	rabbit.position = Vector3(4.7, 0, 2.9)
	rabbit.rotation.y = deg_to_rad(20.0)
	menu_stage.add_child(rabbit)

	var flies := Props.fireflies(24, Vector3(4.0, 1.4, 3.0))
	flies.position = Vector3(6.2, 1.0, 2.0)
	menu_stage.add_child(flies)

	menu_camera = Camera3D.new()
	menu_camera.name = "MenuCamera"
	menu_camera.fov = 55.0
	menu_camera.current = true
	menu_stage.add_child(menu_camera)
	menu_camera.position = Vector3(-1.8, 3.8, 12.5)
	menu_camera.look_at(Vector3(4.6, 1.5, -1.0), Vector3.UP)

func _build_ui() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.name = "MenuLayer"
	menu_layer.layer = 5
	add_child(menu_layer)
	main_menu = MENU_SCENE.instantiate() as MainMenuScreen
	menu_layer.add_child(main_menu)
	chapter_select = CHAPTERS_SCENE.instantiate() as ChapterSelectScreen
	menu_layer.add_child(chapter_select)
	character_select = CHARACTER_SCENE.instantiate() as CharacterSelectScreen
	menu_layer.add_child(character_select)

	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = HUD_SCENE.instantiate() as GameHUD
	ui_layer.add_child(hud)
	hud.visible = false

	overlay_layer = CanvasLayer.new()
	overlay_layer.name = "OverlayLayer"
	overlay_layer.layer = 20
	overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay_layer)
	intro = INTRO_SCENE.instantiate() as IntroOverlay
	overlay_layer.add_child(intro)
	dialogue_box = DIALOGUE_SCENE.instantiate() as DialogueBox
	overlay_layer.add_child(dialogue_box)
	quiz = QUIZ_SCENE.instantiate() as QuizDialog
	overlay_layer.add_child(quiz)
	chapter_complete = COMPLETE_SCENE.instantiate() as ChapterCompleteScreen
	overlay_layer.add_child(chapter_complete)
	book = BOOK_SCENE.instantiate() as BookPanel
	overlay_layer.add_child(book)
	pause_menu = PAUSE_SCENE.instantiate() as PauseMenu
	overlay_layer.add_child(pause_menu)
	settings_panel = SETTINGS_SCENE.instantiate() as SettingsPanel
	overlay_layer.add_child(settings_panel)

	toast_layer = CanvasLayer.new()
	toast_layer.name = "ToastLayer"
	toast_layer.layer = 30
	toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(toast_layer)
	toast = TOAST_SCENE.instantiate() as ToastLayer
	toast_layer.add_child(toast)

	fade_layer = CanvasLayer.new()
	fade_layer.name = "FadeLayer"
	fade_layer.layer = 40
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color(0.992, 0.973, 0.914, 1.0)
	UIKit.full_rect(_fade)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.visible = false
	fade_layer.add_child(_fade)

func _connect_signals() -> void:
	main_menu.new_game_requested.connect(_on_new_game)
	main_menu.continue_requested.connect(_on_continue)
	main_menu.chapters_requested.connect(_on_menu_chapters)
	main_menu.book_requested.connect(_on_menu_book)
	main_menu.settings_requested.connect(_on_menu_settings)
	main_menu.explorer_requested.connect(_on_menu_explorer)
	main_menu.quit_requested.connect(_on_quit)

	chapter_select.chapter_chosen.connect(_on_chapter_chosen)
	chapter_select.back_requested.connect(_on_chapter_select_back)

	character_select.begin_requested.connect(_on_character_begin)
	character_select.changed.connect(_on_character_changed)
	character_select.back_requested.connect(_on_character_back)
	SaveSystem.player_look_changed.connect(_on_player_look_changed)

	Game.quiz_requested.connect(_on_quiz_requested)
	Game.chapter_completed.connect(_on_chapter_completed)
	Dialogue.dialogue_started.connect(_on_dialogue_started)
	dialogue_box.closed.connect(_on_dialogue_box_closed)
	intro.started.connect(_on_intro_started)
	quiz.closed.connect(_on_quiz_closed)
	book.closed.connect(_on_book_closed)
	pause_menu.resume_requested.connect(_on_resume)
	pause_menu.book_requested.connect(_on_pause_book)
	pause_menu.settings_requested.connect(_on_pause_settings)
	pause_menu.menu_requested.connect(_on_pause_menu)
	settings_panel.closed.connect(_on_settings_closed)
	chapter_complete.next_requested.connect(_on_complete_next)
	chapter_complete.menu_requested.connect(_on_complete_menu)

# ------------------------------------------------------------------ fluxo

func begin_world(world_id: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	modal_stack.clear()
	_hide_all_overlays()
	main_menu.hide_menu()
	chapter_select.hide_screen()
	game_active = true
	_apply_mouse()
	await _fade_to(1.0, 0.25)
	_load_world(world_id)
	await _fade_to(0.0, 0.35)
	_transitioning = false
	_apply_mouse()

func _load_world(world_id: String) -> void:
	_clear_world()
	var chapter := Game.get_chapter(world_id)
	if chapter.is_empty():
		push_error("Capítulo desconhecido: " + world_id)
		Game.toast("Não encontramos este capítulo.", "✦")
		_show_menu()
		return
	var path := str(chapter.get("scene", ""))
	if path == "" or not ResourceLoader.exists(path):
		push_error("Cena do capítulo não encontrada: " + path)
		Game.toast("O cenário deste capítulo ainda não está disponível.", "✦")
		_show_menu()
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Não foi possível carregar a cena: " + path)
		_show_menu()
		return
	_dispose_menu_stage()
	hud.visible = false
	world = packed.instantiate() as Node3D
	if world == null:
		_show_menu()
		return
	world.name = "World_" + world_id
	world_host.add_child(world)

func on_world_ready(_world: Node3D, chapter: Dictionary) -> void:
	current_chapter = chapter
	main_menu.hide_menu()
	chapter_select.hide_screen()
	hud.setup(chapter)
	hud.visible = true
	hud.set_prompt("")
	hud.set_aiming(false)
	pause_menu.set_chapter(chapter)
	var player := Game.get_player() as PlayerCharacter
	if player:
		player.prompt_changed.connect(hud.set_prompt)
		player.aiming_changed.connect(hud.set_aiming)
	_open_modal("intro")
	intro.show_chapter(chapter)

func back_to_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	_apply_mouse()
	await _fade_to(1.0, 0.25)
	_show_menu()
	await _fade_to(0.0, 0.35)
	_transitioning = false
	_apply_mouse()

func _show_menu() -> void:
	game_active = false
	get_tree().paused = false
	modal_stack.clear()
	pending_chapter_complete = ""
	_hide_all_overlays()
	current_chapter = {}
	if is_instance_valid(hud):
		hud.visible = false
		hud.set_prompt("")
		hud.set_aiming(false)
	_clear_world()
	Game.clear_carry()
	Missions.reset_runtime()
	if not is_instance_valid(menu_stage):
		_build_menu_stage()
	if is_instance_valid(menu_stage):
		menu_stage.visible = true
		if menu_camera:
			menu_camera.current = true
	if is_instance_valid(main_menu):
		main_menu.show_menu()
	if is_instance_valid(chapter_select):
		chapter_select.hide_screen()
	if is_instance_valid(character_select):
		character_select.hide_screen()
	Audio.play_music("menu")
	_apply_mouse()

func _clear_world() -> void:
	if is_instance_valid(world):
		world_host.remove_child(world)
		world.queue_free()
	world = null
	Game.set_player(null)

func _dispose_menu_stage() -> void:
	if is_instance_valid(menu_stage):
		remove_child(menu_stage)
		menu_stage.queue_free()
	menu_stage = null
	menu_camera = null
	menu_hero = null

func _hide_all_overlays() -> void:
	if is_instance_valid(intro):
		intro.visible = false
	if is_instance_valid(dialogue_box):
		dialogue_box.visible = false
	if is_instance_valid(quiz):
		quiz.visible = false
	if is_instance_valid(book):
		book.visible = false
	if is_instance_valid(pause_menu):
		pause_menu.close()
	if is_instance_valid(chapter_complete):
		chapter_complete.visible = false
	if is_instance_valid(settings_panel):
		settings_panel.visible = false
	if is_instance_valid(character_select):
		character_select.hide_screen()

# ------------------------------------------------------------------ modais

func _open_modal(name: String) -> void:
	if not modal_stack.has(name):
		modal_stack.append(name)
	get_tree().paused = true
	_set_player_control(false)
	_apply_mouse()

func _close_modal(name: String) -> void:
	modal_stack.erase(name)
	if modal_stack.is_empty():
		get_tree().paused = false
		if game_active:
			_set_player_control(true)
	_apply_mouse()

func _set_player_control(value: bool) -> void:
	var player := Game.get_player() as PlayerCharacter
	if player:
		player.set_controlled(value)
	_apply_mouse()

func _apply_mouse() -> void:
	if _capture_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if game_active and modal_stack.is_empty() and not _transitioning:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ------------------------------------------------------------------ menus

func _on_new_game() -> void:
	main_menu.hide_menu()
	character_select.open(true)

func _on_continue() -> void:
	Game.continue_game()

func _on_menu_chapters() -> void:
	chapter_select.show_screen()

func _on_menu_explorer() -> void:
	main_menu.hide_menu()
	character_select.open(false)

func _on_character_begin(look_id: String) -> void:
	SaveSystem.set_player_look(look_id)
	character_select.hide_screen()
	Game.start_new_game()

func _on_character_changed(look_id: String) -> void:
	SaveSystem.set_player_look(look_id)
	character_select.hide_screen()
	main_menu.show_menu()

func _on_character_back() -> void:
	character_select.hide_screen()
	main_menu.show_menu()

func _on_player_look_changed(_look_id: String) -> void:
	if is_instance_valid(menu_hero):
		PlayerLooks.apply(menu_hero, SaveSystem.get_player_look())
	if is_instance_valid(main_menu):
		main_menu.refresh()

func _on_chapter_select_back() -> void:
	chapter_select.hide_screen()
	main_menu.show_menu()

func _on_chapter_chosen(world_id: String) -> void:
	if not SaveSystem.is_chapter_unlocked(world_id):
		return
	chapter_select.hide_screen()
	main_menu.hide_menu()
	Missions.reset_runtime()
	Game.clear_carry()
	begin_world(world_id)

func _on_menu_book() -> void:
	var world_id := SaveSystem.get_last_world() if SaveSystem.has_save() else "eden"
	book.open(world_id)

func _on_menu_settings() -> void:
	settings_panel.open()

func _on_quit() -> void:
	get_tree().quit()

# ------------------------------------------------------------------ pausa

func _on_resume() -> void:
	pause_menu.close()
	Audio.play_sfx("click")
	_close_modal("pause")

func _on_pause_book() -> void:
	pause_menu.close()
	_open_modal("book")
	book.open(Game.current_world)

func _on_pause_settings() -> void:
	pause_menu.close()
	_open_modal("settings")
	settings_panel.open()

func _on_pause_menu() -> void:
	pause_menu.close()
	Game.go_to_menu()

func _on_book_closed() -> void:
	var was_modal := modal_stack.has("book")
	if was_modal:
		_close_modal("book")
	if modal_stack.has("pause"):
		pause_menu.open()
	elif not was_modal:
		_apply_mouse()

func _on_settings_closed() -> void:
	var was_modal := modal_stack.has("settings")
	if was_modal:
		_close_modal("settings")
	if modal_stack.has("pause"):
		pause_menu.open()
	elif not was_modal:
		_apply_mouse()

# ------------------------------------------------------------------ diálogos e quiz

func _on_dialogue_started(payload: Dictionary) -> void:
	_open_modal("dialogue")
	if not dialogue_box.open(payload):
		_close_modal("dialogue")

func _on_dialogue_box_closed() -> void:
	_close_modal("dialogue")

func _on_intro_started() -> void:
	Audio.play_sfx("click")
	_close_modal("intro")

func _on_quiz_requested(quiz_id: String) -> void:
	_open_modal("quiz")
	if not quiz.open(quiz_id):
		_close_modal("quiz")
		Game.toast("Este desafio ainda não está disponível.", "✦")

func _on_quiz_closed(_passed: bool) -> void:
	_close_modal("quiz")
	if pending_chapter_complete != "":
		_maybe_show_complete()

# ------------------------------------------------------------------ conclusão

func _on_chapter_completed(world_id: String) -> void:
	pending_chapter_complete = world_id
	await get_tree().create_timer(0.45).timeout
	_maybe_show_complete()

func _maybe_show_complete() -> void:
	if pending_chapter_complete == "":
		return
	if modal_stack.has("quiz") or modal_stack.has("dialogue") or modal_stack.has("pause"):
		return
	var world_id := pending_chapter_complete
	pending_chapter_complete = ""
	var chapter := Game.get_chapter(world_id)
	if chapter.is_empty():
		return
	current_chapter = chapter
	chapter_complete.show_chapter(chapter)
	_open_modal("complete")

func _on_complete_next() -> void:
	var world_id := str(current_chapter.get("id", ""))
	chapter_complete.close()
	_close_modal("complete")
	var next := Game.next_chapter(world_id)
	if next.is_empty():
		Game.go_to_menu()
	else:
		begin_world(str(next.get("id", "")))

func _on_complete_menu() -> void:
	chapter_complete.close()
	Game.go_to_menu()

# ------------------------------------------------------------------ entrada

func _unhandled_input(event: InputEvent) -> void:
	if _capture_mode:
		return
	if event.is_action_pressed("pause"):
		if not game_active:
			return
		if modal_stack.is_empty():
			_open_modal("pause")
			pause_menu.open()
			Audio.play_sfx("click")
			get_viewport().set_input_as_handled()
		elif modal_stack.has("pause"):
			_on_resume()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if game_active and modal_stack.is_empty():
			_open_modal("book")
			book.open(Game.current_world)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if game_active or not is_instance_valid(menu_camera) or not is_instance_valid(menu_stage):
		return
	if not menu_stage.visible:
		return
	_menu_time += delta
	var base := Vector3(-1.8, 3.8, 12.5)
	menu_camera.position = base + Vector3(sin(_menu_time * 0.18) * 0.85, sin(_menu_time * 0.27) * 0.08, sin(_menu_time * 0.12) * 0.25)
	menu_camera.look_at(Vector3(4.6, 1.5, -1.0), Vector3.UP)

# ------------------------------------------------------------------ transições

func _fade_to(target_alpha: float, duration: float) -> void:
	if not is_instance_valid(_fade):
		return
	_fade.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", target_alpha, duration)
	await tween.finished
	if target_alpha <= 0.01:
		_fade.visible = false

# ------------------------------------------------------------------ captura de tela (verificação)

func _handle_capture_args() -> void:
	var args: Array = []
	args.append_array(OS.get_cmdline_args())
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if str(arg).begins_with("--capture="):
			_capture_mode = true
			_capture_dir = str(arg).substr("--capture=".length())
		elif str(arg).begins_with("--capture-world="):
			_capture_world = str(arg).substr("--capture-world=".length())
	if not _capture_mode:
		return
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	for path in [SaveSystem.SAVE_PATH, SaveSystem.BACKUP_PATH]:
		_save_snapshot[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null

func _run_capture() -> void:
	await get_tree().process_frame
	_show_menu()
	await _wait(0.9)
	if _capture_world == "":
		await _capture("01_menu")

		main_menu.hide_menu()
		character_select.open(true)
		await _wait(0.6)
		await _capture("01b_explorador")
		character_select.hide_screen()
		main_menu.show_menu()

		chapter_select.show_screen()
		await _wait(0.4)
		await _capture("02_capitulos")
		chapter_select.hide_screen()

		book.open("eden")
		await _wait(0.4)
		await _capture("03_livro")
		book.visible = false

		settings_panel.open()
		await _wait(0.4)
		await _capture("04_configuracoes")
		settings_panel.visible = false

	var worlds: Array = ["eden", "ark", "david", "moses", "jesus"]
	if _capture_world != "":
		worlds = [_capture_world]
	for world_id in worlds:
		_hide_all_overlays()
		main_menu.hide_menu()
		chapter_select.hide_screen()
		game_active = true
		_load_world(world_id)
		await _wait(1.2)
		await _capture("05_" + world_id + "_intro")
		if intro.visible:
			intro.skip()
		await _wait(0.9)
		await _capture("06_" + world_id + "_mundo")
		_show_menu()
		await _wait(0.35)

	_restore_save()
	get_tree().quit()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _capture_dir.path_join(name + ".png")
	var error := image.save_png(path)
	print("[capture] ", path, " -> ", error_string(error))

func _restore_save() -> void:
	for path in _save_snapshot.keys():
		var content = _save_snapshot[path]
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
	print("[capture] progresso original restaurado")
