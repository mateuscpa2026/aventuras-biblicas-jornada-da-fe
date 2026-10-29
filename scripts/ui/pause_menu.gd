class_name PauseMenu
extends Control
## Menu de pausa com acesso ao livro, configurações e retorno ao mapa.

signal resume_requested
signal book_requested
signal settings_requested
signal menu_requested

var _subtitle: Label
var _menu_button: Button
var _confirm_timer := 0.0
var _confirming := false

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
	card.custom_minimum_size = Vector2(470, 0)
	center.add_child(card)
	var box := UIKit.vbox(12)
	card.add_child(box)

	box.add_child(UIKit.icon_circle("☾", UIKit.PAPER, UIKit.AMBER_DEEP, 62, 30))
	var title := UIKit.label("Um momento de descanso", 30, UIKit.INK, 700)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_subtitle = UIKit.label("", 15, UIKit.MUTED, 500, true)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))

	var resume := UIKit.button("Continuar explorando", "primary", 21)
	resume.pressed.connect(_on_resume)
	box.add_child(resume)
	var book := UIKit.button("Livro de histórias", "soft", 19)
	book.pressed.connect(_on_book)
	box.add_child(book)
	var settings := UIKit.button("Configurações", "soft", 19)
	settings.pressed.connect(_on_settings)
	box.add_child(settings)
	_menu_button = UIKit.button("Menu principal", "soft", 19)
	_menu_button.pressed.connect(_on_menu)
	box.add_child(_menu_button)

	box.add_child(UIKit.spacer(2))
	var hint := UIKit.label("Esc para continuar   ·   o progresso das missões concluídas fica salvo", 12, UIKit.MUTED, 500, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

func set_chapter(chapter: Dictionary) -> void:
	if chapter.is_empty():
		_subtitle.text = "O jogo está pausado."
	else:
		_subtitle.text = "Capítulo %d · %s" % [int(chapter.get("order", 1)), str(chapter.get("title", ""))]

func open() -> void:
	visible = true
	_confirming = false
	_confirm_timer = 0.0
	_menu_button.text = "Menu principal"
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)

func close() -> void:
	visible = false
	_confirming = false
	_confirm_timer = 0.0

func _on_resume() -> void:
	Audio.play_sfx("click")
	resume_requested.emit()

func _on_book() -> void:
	Audio.play_sfx("click")
	book_requested.emit()

func _on_settings() -> void:
	Audio.play_sfx("click")
	settings_requested.emit()

func _on_menu() -> void:
	Audio.play_sfx("click")
	if not _confirming:
		_confirming = true
		_confirm_timer = 0.0
		_menu_button.text = "Tem certeza? Voltar ao menu"
		return
	menu_requested.emit()

func _reset_confirm() -> void:
	if not is_instance_valid(_menu_button):
		return
	_confirming = false
	_menu_button.text = "Menu principal"

func _process(delta: float) -> void:
	if not visible or not _confirming:
		return
	_confirm_timer += delta
	if _confirm_timer > 5.0:
		_confirm_timer = 0.0
		_reset_confirm()
