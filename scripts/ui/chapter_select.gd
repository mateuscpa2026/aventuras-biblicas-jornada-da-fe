class_name ChapterSelectScreen
extends Control
## Mapa dos capítulos, com bloqueio, conclusão e recompensa de revisita.

signal chapter_chosen(world_id: String)
signal back_requested

var _cards_box: HBoxContainer
var _progress_label: PanelContainer

func _ready() -> void:
	UIKit.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UIKit.CREAM
	UIKit.full_rect(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var band := ColorRect.new()
	band.color = Color("#f2e6c8")
	band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	band.offset_bottom = 8
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)

	var margin := MarginContainer.new()
	UIKit.full_rect(margin)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var content := UIKit.vbox(14)
	margin.add_child(content)

	var header := UIKit.hbox(16)
	var back := UIKit.button("◀ Voltar", "ghost", 16)
	back.custom_minimum_size = Vector2(130, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_on_back)
	header.add_child(back)
	var head_text := UIKit.vbox(0)
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_text.add_child(UIKit.label("Mapa da jornada", 36, UIKit.INK, 700))
	head_text.add_child(UIKit.label("Escolha um capítulo para explorar. Você pode revisitar os que já concluiu.", 15, UIKit.MUTED, 500))
	header.add_child(head_text)
	_progress_label = UIKit.badge("0 de 5", Color("#dcefdc"), Color("#2f5c3b"), 14)
	header.add_child(_progress_label)
	content.add_child(header)
	content.add_child(UIKit.divider(Color("#e6d7b5"), 2))

	_cards_box = UIKit.hbox(14)
	_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(_cards_box)

	var footer := UIKit.hbox(10)
	footer.add_child(UIKit.label("Concluir um capítulo desbloqueia a próxima história.", 13, UIKit.MUTED, 500))
	footer.add_child(UIKit.stretch_spacer())
	footer.add_child(UIKit.label("✦  Cinco jornadas, uma só fé", 13, UIKit.AMBER_DEEP, 600))
	content.add_child(footer)

func show_screen() -> void:
	visible = true
	refresh()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_screen() -> void:
	visible = false

func refresh() -> void:
	if not is_instance_valid(_cards_box):
		return
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	var completed := 0
	for chapter in Game.chapters:
		var world_id := str(chapter.get("id", ""))
		if SaveSystem.is_chapter_completed(world_id):
			completed += 1
		_cards_box.add_child(_chapter_card(chapter))
	var badge_label := _progress_label.get_child(0) as Label
	if badge_label:
		badge_label.text = "%d de 5 concluídos" % completed

func _chapter_glyph(world_id: String) -> String:
	match world_id:
		"eden": return "❀"
		"ark": return "⚓"
		"david": return "◎"
		"moses": return "≈"
		"jesus": return "♥"
		_: return "✦"

func _chapter_card(chapter: Dictionary) -> Control:
	var world_id := str(chapter.get("id", ""))
	var accent := Color.from_string(str(chapter.get("color", "#58a86b")), UIKit.GREEN)
	var unlocked := SaveSystem.is_chapter_unlocked(world_id)
	var done := SaveSystem.is_chapter_completed(world_id)
	var card := UIKit.panel(UIKit.CARD if unlocked else Color("#f3eee2"), 22, 0,
		Color("#e6d7b5") if unlocked else Color("#e6dfcf"))
	card.custom_minimum_size = Vector2(0, 416)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	var box := UIKit.vbox(0)
	card.add_child(box)

	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 100)
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = accent if unlocked else Color("#d6d0c1")
	band_style.corner_radius_top_left = 22
	band_style.corner_radius_top_right = 22
	band.add_theme_stylebox_override("panel", band_style)
	var band_box := UIKit.vbox(2)
	band_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var glyph := UIKit.label(_chapter_glyph(world_id), 34, UIKit.CREAM if unlocked else Color("#f2ede0"), 700)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band_box.add_child(glyph)
	var number := UIKit.label("CAPÍTULO %d" % int(chapter.get("order", 1)), 11,
		Color(1, 1, 1, 0.9) if unlocked else Color(1, 1, 1, 0.7), 700)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band_box.add_child(number)
	band.add_child(band_box)
	box.add_child(band)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 14)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(pad)
	var inner := UIKit.vbox(6)
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(inner)

	var title := UIKit.label(str(chapter.get("title", "")), 20, UIKit.INK if unlocked else UIKit.MUTED, 700, true)
	title.custom_minimum_size = Vector2(0, 52)
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	inner.add_child(title)
	var subtitle := UIKit.label(str(chapter.get("subtitle", "")), 13, UIKit.MUTED, 500, true)
	subtitle.custom_minimum_size = Vector2(0, 38)
	inner.add_child(subtitle)
	inner.add_child(UIKit.stretch_spacer())

	var status_text := "BLOQUEADO"
	var status_bg := Color("#e6dfcf")
	var status_fg := UIKit.MUTED
	if done:
		status_text = "CONCLUÍDO"
		status_bg = Color("#dcefdc")
		status_fg = Color("#2f5c3b")
	elif unlocked:
		status_text = "DISPONÍVEL"
		status_bg = Color("#ffe7b0")
		status_fg = Color("#7a4f12")
	inner.add_child(UIKit.badge(status_text, status_bg, status_fg, 11))

	var total_stories: int = Story.get_world_stories(world_id).size()
	var found := Story.count_unlocked(world_id)
	var stories_label := UIKit.label("%d / %d histórias" % [found, total_stories], 12, UIKit.MUTED, 600)
	inner.add_child(stories_label)

	var action := UIKit.button("Jogar", "primary", 17)
	if done:
		action.text = "Revisitar"
	elif not unlocked:
		action.text = "Bloqueado"
	action.custom_minimum_size = Vector2(0, 44)
	action.disabled = not unlocked
	action.pressed.connect(_on_chapter_pressed.bind(world_id))
	inner.add_child(action)
	return card

func _on_chapter_pressed(world_id: String) -> void:
	if not SaveSystem.is_chapter_unlocked(world_id):
		Audio.play_sfx("wrong", 0.9, 0.5)
		return
	Audio.play_sfx("click")
	chapter_chosen.emit(world_id)

func _on_back() -> void:
	Audio.play_sfx("click")
	back_requested.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()
