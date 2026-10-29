class_name MainMenuScreen
extends Control
## Menu principal com diorama 3D ao fundo (construído pelo Main).

signal new_game_requested
signal continue_requested
signal chapters_requested
signal book_requested
signal settings_requested
signal explorer_requested
signal quit_requested

var _new_button: Button
var _continue_button: Button
var _explorer_button: Button
var _progress_label: Label
var _confirming := false
var _confirm_timer := 0.0

func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	refresh()

func _build() -> void:
	var left_bg := ColorRect.new()
	left_bg.color = Color(0.992, 0.973, 0.914, 0.995)
	left_bg.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left_bg.offset_right = 592
	left_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_bg)

	var accent := ColorRect.new()
	accent.color = UIKit.AMBER
	accent.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	accent.offset_left = 592
	accent.offset_right = 596
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	margin.offset_right = 592
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var content := UIKit.vbox(10)
	margin.add_child(content)

	var badge_row := UIKit.hbox(10)
	badge_row.add_child(UIKit.badge("UM JOGO PARA TODA A FAMÍLIA", Color("#ffe7b0"), Color("#7a4f12"), 12))
	_explorer_button = _chip("Explorador: " + PlayerLooks.name_of(PlayerLooks.DEFAULT_ID))
	_explorer_button.pressed.connect(_request.bind("explorer_requested"))
	badge_row.add_child(_explorer_button)
	content.add_child(badge_row)
	content.add_child(UIKit.spacer(4))

	var word_one := UIKit.label("Aventuras", 52, UIKit.INK, 700)
	word_one.add_theme_constant_override("line_spacing", -8)
	content.add_child(word_one)
	var word_two := UIKit.label("Bíblicas", 52, UIKit.GREEN, 700)
	content.add_child(word_two)
	var subtitle := UIKit.label("Jornada da Fé", 27, UIKit.AMBER_DEEP, 600)
	content.add_child(subtitle)
	content.add_child(UIKit.spacer(4))
	var description := UIKit.label("Explore cinco mundos cheios de histórias, animais e descobertas. Ajude personagens, encontre pergaminhos e aprenda sobre fé, coragem e amor.",
		16, UIKit.MUTED, 500, true)
	description.custom_minimum_size = Vector2(460, 0)
	content.add_child(description)
	content.add_child(UIKit.spacer(10))

	_new_button = UIKit.button("Novo jogo", "primary", 23)
	_new_button.custom_minimum_size = Vector2(0, 52)
	_new_button.pressed.connect(_on_new_game)
	content.add_child(_new_button)

	_continue_button = UIKit.button("Continuar", "soft", 20)
	_continue_button.custom_minimum_size = Vector2(0, 50)
	_continue_button.pressed.connect(_on_continue)
	content.add_child(_continue_button)

	var row_one := UIKit.hbox(10)
	var chapters := UIKit.button("Capítulos", "soft", 18)
	chapters.custom_minimum_size = Vector2(0, 50)
	chapters.pressed.connect(_request.bind("chapters_requested"))
	row_one.add_child(chapters)
	var book := UIKit.button("Livro de histórias", "soft", 18)
	book.custom_minimum_size = Vector2(0, 50)
	book.pressed.connect(_request.bind("book_requested"))
	row_one.add_child(book)
	content.add_child(row_one)

	var row_two := UIKit.hbox(10)
	var settings := UIKit.button("Configurações", "ghost", 17)
	settings.custom_minimum_size = Vector2(0, 46)
	settings.pressed.connect(_request.bind("settings_requested"))
	row_two.add_child(settings)
	var quit := UIKit.button("Sair", "ghost", 17)
	quit.custom_minimum_size = Vector2(0, 46)
	quit.pressed.connect(_request.bind("quit_requested"))
	row_two.add_child(quit)
	content.add_child(row_two)

	content.add_child(UIKit.spacer(6))
	_progress_label = UIKit.label("", 13, UIKit.MUTED, 500, true)
	content.add_child(_progress_label)
	content.add_child(UIKit.stretch_spacer())

	var tip := UIKit.panel(Color(0.11, 0.17, 0.13, 0.86), 22, 16, Color(0, 0, 0, 0))
	tip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	tip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tip.offset_left = -24
	tip.offset_right = -24
	tip.offset_top = -24
	tip.offset_bottom = -24
	add_child(tip)
	var tip_row := UIKit.hbox(12)
	tip_row.add_child(UIKit.icon_circle("✦", Color(1, 1, 1, 0.12), UIKit.AMBER, 40, 20))
	var tip_text := UIKit.vbox(2)
	tip_text.add_child(UIKit.label("DICA DE EXPLORADOR", 11, UIKit.AMBER, 700))
	var tip_label := UIKit.label("Aperte E para conversar com os personagens e pegar pergaminhos.", 14, UIKit.CREAM, 500, true)
	tip_label.custom_minimum_size = Vector2(300, 0)
	tip_text.add_child(tip_label)
	tip_row.add_child(tip_text)
	tip.add_child(tip_row)

func _chip(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_override("font", UIKit.font(600))
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("#7a4f12"))
	button.add_theme_color_override("font_hover_color", UIKit.INK)
	button.add_theme_color_override("font_pressed_color", UIKit.INK)
	button.add_theme_color_override("font_focus_color", UIKit.INK)
	var normal := _chip_style(Color("#ffe7b0"), Color(0, 0, 0, 0))
	var hover := _chip_style(Color("#ffd98a"), Color(0, 0, 0, 0))
	var pressed := _chip_style(Color("#f2c96f"), Color(0, 0, 0, 0))
	var focus := _chip_style(Color(0, 0, 0, 0), UIKit.AMBER_DEEP)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	return button

func _chip_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	if border.a > 0.0:
		style.set_border_width_all(1)
		style.border_color = border
	return style

func refresh() -> void:
	var has_save := SaveSystem.has_save()
	var last_world := SaveSystem.get_last_world()
	var chapter := Game.get_chapter(last_world)
	_continue_button.disabled = not has_save or chapter.is_empty()
	if has_save and not chapter.is_empty():
		_continue_button.text = "Continuar  ·  " + str(chapter.get("title", ""))
	else:
		_continue_button.text = "Continuar"
	if _explorer_button:
		_explorer_button.text = "Explorador: " + PlayerLooks.name_of(SaveSystem.get_player_look())
	var completed: Array = SaveSystem.data.get("completed_chapters", [])
	var stories := SaveSystem.get_storybook().size()
	if has_save:
		_progress_label.text = "%d de 5 capítulos concluídos  ·  %d de %d histórias encontradas" % [completed.size(), stories, Story.stories.size()]
	else:
		_progress_label.text = "Comece uma nova jornada pelo Jardim do Éden."

func show_menu() -> void:
	visible = true
	_confirming = false
	_confirm_timer = 0.0
	_new_button.text = "Novo jogo"
	refresh()
	_new_button.grab_focus()

func hide_menu() -> void:
	visible = false
	_confirming = false

func _request(signal_name: String) -> void:
	Audio.play_sfx("click")
	match signal_name:
		"chapters_requested":
			chapters_requested.emit()
		"book_requested":
			book_requested.emit()
		"settings_requested":
			settings_requested.emit()
		"explorer_requested":
			explorer_requested.emit()
		"quit_requested":
			quit_requested.emit()

func _on_new_game() -> void:
	Audio.play_sfx("click")
	if SaveSystem.has_save() and not _confirming:
		_confirming = true
		_confirm_timer = 0.0
		_new_button.text = "Recomeçar do início? Clique de novo"
		return
	_confirming = false
	_new_button.text = "Novo jogo"
	new_game_requested.emit()
func _on_continue() -> void:
	Audio.play_sfx("click")
	continue_requested.emit()

func _process(delta: float) -> void:
	if not visible or not _confirming:
		return
	_confirm_timer += delta
	if _confirm_timer > 5.0:
		_confirming = false
		_new_button.text = "Novo jogo"
