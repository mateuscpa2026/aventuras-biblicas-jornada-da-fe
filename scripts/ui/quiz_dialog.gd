class_name QuizDialog
extends Control
## Desafio de memória bíblica: sem punição, com dicas e nova tentativa.

signal closed(passed: bool)

const QUIZZES_PATH := "res://data/quizzes.json"

var _quizzes: Dictionary = {}
var _quiz_id := ""
var _quiz: Dictionary = {}
var _questions: Array = []
var _index := 0
var _passed := false
var _transitioning := false
var _open := false

var _title_label: Label
var _intro_label: Label
var _progress_label: Label
var _progress_bar: ProgressBar
var _question_label: Label
var _options_box: VBoxContainer
var _feedback_label: Label
var _reference_label: Label
var _play_box: VBoxContainer
var _complete_box: VBoxContainer
var _complete_text: Label
var _continue_button: Button
var _close_button: Button

func _ready() -> void:
	UIKit.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_data()
	_build()

func _load_data() -> void:
	if not FileAccess.file_exists(QUIZZES_PATH):
		push_error("data/quizzes.json não encontrado.")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(QUIZZES_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_quizzes = parsed

func _build() -> void:
	UIKit.dim(self)
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)
	var card := UIKit.panel(UIKit.CARD, 28, 30, Color("#e0cfa8"))
	card.custom_minimum_size = Vector2(860, 0)
	center.add_child(card)
	var box := UIKit.vbox(12)
	card.add_child(box)

	var header := UIKit.hbox(14)
	header.add_child(UIKit.icon_circle("?", UIKit.AMBER, UIKit.INK, 52, 26))
	var head_text := UIKit.vbox(2)
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label = UIKit.label("Desafio da memória", 30, UIKit.INK, 700, true)
	_intro_label = UIKit.label("", 15, UIKit.MUTED, 500, true)
	head_text.add_child(_title_label)
	head_text.add_child(_intro_label)
	header.add_child(head_text)
	_close_button = UIKit.button("Sair", "ghost", 17)
	_close_button.custom_minimum_size = Vector2(96, 42)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_button.pressed.connect(_close)
	header.add_child(_close_button)
	box.add_child(header)
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))

	_play_box = UIKit.vbox(12)
	box.add_child(_play_box)

	var progress_row := UIKit.hbox(10)
	_progress_label = UIKit.label("Pergunta 1 de 3", 14, UIKit.GREEN, 700)
	progress_row.add_child(_progress_label)
	progress_row.add_child(UIKit.stretch_spacer())
	_progress_bar = UIKit.progress_bar(0, 3, UIKit.AMBER)
	_progress_bar.custom_minimum_size = Vector2(220, 10)
	progress_row.add_child(_progress_bar)
	_play_box.add_child(progress_row)

	_question_label = UIKit.label("", 24, UIKit.INK, 700, true)
	_question_label.custom_minimum_size = Vector2(0, 58)
	_question_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_play_box.add_child(_question_label)

	_options_box = UIKit.vbox(10)
	_play_box.add_child(_options_box)

	_feedback_label = UIKit.label("", 17, UIKit.GREEN, 600, true)
	_feedback_label.visible = false
	_play_box.add_child(_feedback_label)
	_reference_label = UIKit.label("", 13, UIKit.BLUE, 600, true)
	_reference_label.visible = false
	_play_box.add_child(_reference_label)

	_complete_box = UIKit.vbox(10)
	_complete_box.visible = false
	box.add_child(_complete_box)
	_complete_box.add_child(UIKit.spacer(6))
	_complete_box.add_child(UIKit.icon_circle("★", Color("#ffe7b0"), UIKit.AMBER_DEEP, 64, 30))
	var complete_title := UIKit.label("Desafio concluído!", 32, UIKit.INK, 700)
	complete_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_box.add_child(complete_title)
	_complete_text = UIKit.label("", 18, UIKit.MUTED, 500, true)
	_complete_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_box.add_child(_complete_text)

	var footer := UIKit.hbox(12)
	var hint := UIKit.label("Sem pressa. Errar faz parte de aprender — você pode tentar de novo.", 13, UIKit.MUTED, 500, true)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(hint)
	_continue_button = UIKit.button("Guardar e continuar", "primary", 19)
	_continue_button.custom_minimum_size = Vector2(250, 48)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_continue_button.visible = false
	_continue_button.pressed.connect(_close)
	footer.add_child(_continue_button)
	box.add_child(footer)

func open(quiz_id: String) -> bool:
	if not _quizzes.has(quiz_id):
		push_error("Quiz não encontrado: " + quiz_id)
		return false
	_quiz_id = quiz_id
	_quiz = _quizzes[quiz_id]
	_questions = _quiz.get("questions", [])
	if _questions.is_empty():
		return false
	_index = 0
	_passed = false
	_transitioning = false
	_open = true
	visible = true
	_title_label.text = str(_quiz.get("title", "Desafio da memória"))
	_intro_label.text = str(_quiz.get("intro", ""))
	_complete_box.visible = false
	_play_box.visible = true
	_continue_button.visible = false
	_close_button.text = "Sair"
	_show_question()
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	return true

func _show_question() -> void:
	_clear_options()
	_feedback_label.visible = false
	_reference_label.visible = false
	_continue_button.visible = false
	_progress_label.text = "Pergunta %d de %d" % [_index + 1, _questions.size()]
	_progress_bar.max_value = maxf(1.0, float(_questions.size()))
	_progress_bar.value = _index
	var question: Dictionary = _questions[_index]
	_question_label.text = str(question.get("q", ""))
	var options = question.get("options", [])
	if typeof(options) != TYPE_ARRAY:
		return
	for i in options.size():
		var button := UIKit.button(str(options[i]), "soft", 19)
		button.custom_minimum_size = Vector2(0, 50)
		button.pressed.connect(_answer.bind(i))
		_options_box.add_child(button)

func _answer(index: int) -> void:
	if not _open or _transitioning:
		return
	var question: Dictionary = _questions[_index]
	var correct := int(question.get("answer", -1))
	Audio.play_sfx("click")
	if index == correct:
		_transitioning = true
		Audio.play_sfx("success")
		_feedback_label.text = "Muito bem! Você lembrou direitinho."
		_feedback_label.add_theme_color_override("font_color", UIKit.GREEN)
		_feedback_label.visible = true
		var reference := str(question.get("reference", ""))
		_reference_label.text = ("Referência: %s" % reference) if reference != "" else ""
		_reference_label.visible = reference != ""
		var buttons := _options_box.get_children()
		for i in buttons.size():
			var button := buttons[i] as Button
			if button == null:
				continue
			button.disabled = true
			if i == correct:
				button.text = "✔  " + button.text
		_progress_bar.value = _index + 1
		var timer := get_tree().create_timer(1.2)
		timer.timeout.connect(_next_question)
	else:
		Audio.play_sfx("wrong", 0.9, 0.6)
		var hint := str(question.get("hint", "Pense com calma e tente outra opção."))
		_feedback_label.text = "Quase! " + hint
		_feedback_label.add_theme_color_override("font_color", UIKit.AMBER_DEEP)
		_feedback_label.visible = true

func _next_question() -> void:
	if not _open:
		return
	_transitioning = false
	_index += 1
	if _index >= _questions.size():
		_complete()
	else:
		_show_question()

func _complete() -> void:
	_play_box.visible = false
	_complete_box.visible = true
	_continue_button.visible = true
	_close_button.text = "Fechar"
	_passed = true
	_complete_text.text = "Você recordou a história e guardou mais um ensinamento no coração. O pergaminho desta aventura já está no seu livro."
	Missions.notify_event("quiz_complete", 1, {"quiz": _quiz_id})
	Audio.play_sfx("success")

func _clear_options() -> void:
	for child in _options_box.get_children():
		_options_box.remove_child(child)
		child.queue_free()

func _close() -> void:
	if not _open:
		return
	_open = false
	_transitioning = false
	visible = false
	closed.emit(_passed)

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
