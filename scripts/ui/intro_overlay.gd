class_name IntroOverlay
extends Control
## Cartão de abertura de cada capítulo, com objetivo e paráfrase bíblica.

signal started

var _badge_label: Label
var _title: Label
var _subtitle: Label
var _intro: Label
var _goal: Label
var _verse: Label
var _verse_ref: Label
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
	card.custom_minimum_size = Vector2(780, 0)
	center.add_child(card)
	var box := UIKit.vbox(10)
	card.add_child(box)

	var header := UIKit.hbox(10)
	var badge := UIKit.badge("CAPÍTULO 1 DE 5", UIKit.AMBER, UIKit.INK, 13)
	_badge_label = badge.get_child(0) as Label
	header.add_child(badge)
	header.add_child(UIKit.label("JORNADA DA FÉ", 12, UIKit.MUTED, 600))
	header.add_child(UIKit.stretch_spacer())
	header.add_child(UIKit.label("✦", 22, UIKit.AMBER, 700))
	box.add_child(header)

	_title = UIKit.label("", 42, UIKit.INK, 700, true)
	box.add_child(_title)
	_subtitle = UIKit.label("", 19, UIKit.GREEN, 600)
	box.add_child(_subtitle)
	box.add_child(UIKit.spacer(2))
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))
	_intro = UIKit.label("", 20, UIKit.INK, 500, true)
	box.add_child(_intro)

	var goal_card := UIKit.panel(UIKit.PAPER, 18, 14)
	var goal_row := UIKit.hbox(12)
	goal_row.add_child(UIKit.icon_circle("◎", UIKit.AMBER, UIKit.INK, 42, 20))
	var goal_box := UIKit.vbox(2)
	goal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_box.add_child(UIKit.label("SEU OBJETIVO", 12, UIKit.AMBER_DEEP, 700))
	_goal = UIKit.label("", 18, UIKit.INK, 600, true)
	goal_box.add_child(_goal)
	goal_row.add_child(goal_box)
	goal_card.add_child(goal_row)
	box.add_child(goal_card)

	var verse_card := UIKit.panel(Color("#f4f7e6"), 18, 14, Color("#dbe4c4"))
	var verse_row := UIKit.hbox(12)
	var quote := UIKit.label("❝", 30, UIKit.GREEN_LIGHT, 700)
	quote.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	verse_row.add_child(quote)
	var verse_box := UIKit.vbox(2)
	verse_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_verse = UIKit.label("", 18, UIKit.INK, 500, true)
	verse_box.add_child(_verse)
	_verse_ref = UIKit.label("", 13, UIKit.MUTED, 600)
	verse_box.add_child(_verse_ref)
	verse_row.add_child(verse_box)
	verse_card.add_child(verse_row)
	box.add_child(verse_card)

	box.add_child(UIKit.spacer(2))
	var footer := UIKit.hbox(14)
	var hints := UIKit.vbox(2)
	hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints.add_child(UIKit.label("WASD mover  ·  Mouse olhar  ·  Shift correr", 13, UIKit.MUTED, 500))
	hints.add_child(UIKit.label("Espaço pular  ·  E interagir  ·  Esc pausar", 13, UIKit.MUTED, 500))
	footer.add_child(hints)
	var start_button := UIKit.button("Começar a explorar", "primary", 20)
	start_button.custom_minimum_size = Vector2(280, 52)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	start_button.pressed.connect(_start)
	footer.add_child(start_button)
	box.add_child(footer)

func show_chapter(chapter: Dictionary) -> void:
	if chapter.is_empty():
		return
	_open = true
	visible = true
	_badge_label.text = "CAPÍTULO %d DE 5" % int(chapter.get("order", 1))
	_title.text = str(chapter.get("title", ""))
	_subtitle.text = str(chapter.get("subtitle", ""))
	_intro.text = str(chapter.get("intro", ""))
	_goal.text = str(chapter.get("goal", ""))
	_verse.text = "“%s”" % str(chapter.get("verse_text", ""))
	var kind := str(chapter.get("verse_kind", "paráfrase"))
	var kind_label := "paráfrase" if kind == "paráfrase" else kind
	_verse_ref.text = "%s  ·  %s" % [str(chapter.get("verse_ref", "")), kind_label]
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _start() -> void:
	if not _open:
		return
	_open = false
	visible = false
	Audio.play_sfx("click")
	started.emit()

func close() -> void:
	_open = false
	visible = false

func skip() -> void:
	_start()

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_start()
