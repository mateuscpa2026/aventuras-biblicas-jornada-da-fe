class_name ChapterCompleteScreen
extends Control
## Tela de conclusão do capítulo, com ensinamento, versículo e recompensas.

signal next_requested
signal menu_requested

var _chapter: Dictionary = {}
var _badge_label: Label
var _title: Label
var _subtitle: Label
var _teaching: Label
var _verse: Label
var _verse_ref: Label
var _story_stat: Label
var _mission_stat: Label
var _reward_title: Label
var _reward_text: Label
var _next_button: Button
var _open := false

func _ready() -> void:
	UIKit.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	UIKit.dim(self)
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)
	var card := UIKit.panel(UIKit.CARD, 28, 30, Color("#e0cfa8"))
	card.custom_minimum_size = Vector2(760, 0)
	center.add_child(card)
	var box := UIKit.vbox(11)
	card.add_child(box)

	var top_row := UIKit.hbox(10)
	var badge := UIKit.badge("CAPÍTULO CONCLUÍDO", Color("#dcefdc"), Color("#2f5c3b"), 13)
	top_row.add_child(badge)
	_badge_label = badge.get_child(0) as Label
	top_row.add_child(UIKit.stretch_spacer())
	var stars := UIKit.label("✦  ✦  ✦", 20, UIKit.AMBER, 700)
	top_row.add_child(stars)
	box.add_child(top_row)

	_title = UIKit.label("", 38, UIKit.INK, 700, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_subtitle = UIKit.label("", 16, UIKit.MUTED, 500, true)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))

	var stats := UIKit.hbox(10)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	var story_box := _stat_box("0 / 0", "Histórias", UIKit.AMBER)
	_story_stat = story_box.get_child(0).get_child(0) as Label
	stats.add_child(story_box)
	var mission_box := _stat_box("0", "Missões concluídas", UIKit.GREEN)
	_mission_stat = mission_box.get_child(0).get_child(0) as Label
	stats.add_child(mission_box)
	var world_box := _stat_box("✦", "Mundo concluído", UIKit.BLUE)
	stats.add_child(world_box)
	box.add_child(stats)

	var learn := UIKit.panel(UIKit.PAPER, 18, 14)
	var learn_box := UIKit.vbox(3)
	learn_box.add_child(UIKit.label("O QUE APRENDEMOS", 12, UIKit.AMBER_DEEP, 700))
	_teaching = UIKit.label("", 17, UIKit.INK, 500, true)
	learn_box.add_child(_teaching)
	learn.add_child(learn_box)
	box.add_child(learn)

	var verse_card := UIKit.panel(Color("#f4f7e6"), 18, 14, Color("#dbe4c4"))
	var verse_row := UIKit.hbox(12)
	var quote := UIKit.label("❝", 28, UIKit.GREEN_LIGHT, 700)
	quote.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	verse_row.add_child(quote)
	var verse_box := UIKit.vbox(2)
	_verse = UIKit.label("", 17, UIKit.INK, 500, true)
	verse_box.add_child(_verse)
	_verse_ref = UIKit.label("", 12, UIKit.MUTED, 600)
	verse_box.add_child(_verse_ref)
	verse_row.add_child(verse_box)
	verse_card.add_child(verse_row)
	box.add_child(verse_card)

	var reward := UIKit.panel(Color("#fff3d6"), 18, 12, Color("#f0dcaa"))
	var reward_row := UIKit.hbox(12)
	reward_row.add_child(UIKit.icon_circle("★", UIKit.AMBER, UIKit.INK, 40, 19))
	var reward_box := UIKit.vbox(1)
	_reward_title = UIKit.label("NOVA JORNADA DESBLOQUEADA", 11, UIKit.AMBER_DEEP, 700)
	_reward_text = UIKit.label("", 16, UIKit.INK, 600, true)
	reward_box.add_child(_reward_title)
	reward_box.add_child(_reward_text)
	reward_row.add_child(reward_box)
	reward.add_child(reward_row)
	box.add_child(reward)

	var footer := UIKit.hbox(12)
	var menu_button := UIKit.button("Mapa dos capítulos", "soft", 17)
	menu_button.custom_minimum_size = Vector2(0, 48)
	menu_button.pressed.connect(_on_menu)
	footer.add_child(menu_button)
	_next_button = UIKit.button("Continuar jornada", "primary", 19)
	_next_button.custom_minimum_size = Vector2(0, 48)
	_next_button.pressed.connect(_on_next)
	footer.add_child(_next_button)
	box.add_child(footer)

func _stat_box(value: String, label_text: String, color: Color) -> PanelContainer:
	var panel := UIKit.panel(UIKit.CREAM, 16, 10, Color("#eadcbd"))
	panel.custom_minimum_size = Vector2(180, 0)
	var box := UIKit.vbox(0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var value_label := UIKit.label(value, 22, color, 700)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value_label)
	var text_label := UIKit.label(label_text, 11, UIKit.MUTED, 600)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text_label)
	panel.add_child(box)
	return panel

func show_chapter(chapter: Dictionary) -> void:
	if chapter.is_empty():
		return
	_chapter = chapter
	var world_id := str(chapter.get("id", ""))
	_open = true
	visible = true
	_badge_label.text = "CAPÍTULO %d CONCLUÍDO" % int(chapter.get("order", 1))
	_title.text = str(chapter.get("title", ""))
	_subtitle.text = "Você completou: %s" % str(chapter.get("subtitle", ""))
	_teaching.text = str(chapter.get("teaching", ""))
	_verse.text = "“%s”" % str(chapter.get("verse_text", ""))
	var kind := "paráfrase" if str(chapter.get("verse_kind", "paráfrase")) == "paráfrase" else str(chapter.get("verse_kind", ""))
	_verse_ref.text = "%s  ·  %s" % [str(chapter.get("verse_ref", "")), kind]
	var total_stories: int = Story.get_world_stories(world_id).size()
	_story_stat.text = "%d / %d" % [Story.count_unlocked(world_id), total_stories]
	_mission_stat.text = str(SaveSystem.get_completed_missions(world_id).size())
	var next := Game.next_chapter(world_id)
	if next.is_empty():
		_reward_title.text = "JORNADA COMPLETA"
		_reward_text.text = "Você visitou todos os mundos e guardou todas as histórias no coração. Obrigado por caminhar conosco!"
		_next_button.text = "Voltar ao início"
	else:
		_reward_title.text = "NOVA JORNADA DESBLOQUEADA"
		_reward_text.text = "%s  ·  %s" % [str(next.get("title", "")), str(next.get("subtitle", ""))]
		_next_button.text = "Continuar jornada"
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func close() -> void:
	visible = false
	_open = false

func _on_next() -> void:
	if not _open:
		return
	Audio.play_sfx("click")
	_open = false
	if Game.next_chapter(str(_chapter.get("id", ""))).is_empty():
		menu_requested.emit()
	else:
		next_requested.emit()

func _on_menu() -> void:
	if not _open:
		return
	Audio.play_sfx("click")
	_open = false
	menu_requested.emit()
