class_name DialogueBox
extends Control
## Tela de diálogo com efeito de digitação, referências e escolhas.
## Diferencia falas, paráfrases e explicações para não atribuir textos inventados à Bíblia.

signal closed

const TYPE_SPEED := 52.0

var _dim: ColorRect
var _panel: PanelContainer
var _name_badge: PanelContainer
var _name_label: Label
var _role_label: Label
var _kind_badge: PanelContainer
var _kind_label: Label
var _text_label: Label
var _reference_label: Label
var _hint_label: Label
var _next_button: Button
var _choices_box: VBoxContainer

var _payload: Dictionary = {}
var _lines: Array = []
var _index := 0
var _typing := false
var _full_text := ""
var _visible_chars := 0.0
var _showing_reply := false
var _open := false

func _ready() -> void:
	UIKit.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	_dim = UIKit.dim(self)
	_dim.process_mode = Node.PROCESS_MODE_ALWAYS
	_dim.gui_input.connect(_on_outside_input)

	var holder := UIKit.vbox(0)
	holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	holder.offset_left = 54
	holder.offset_right = -54
	holder.offset_top = -470
	holder.offset_bottom = -24
	holder.alignment = BoxContainer.ALIGNMENT_END
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)

	_panel = UIKit.panel(UIKit.CARD, 26, 22, Color("#e0cfa8"))
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.gui_input.connect(_on_panel_input)
	holder.add_child(_panel)

	var box := UIKit.vbox(9)
	_panel.add_child(box)

	var header := UIKit.hbox(10)
	_name_badge = UIKit.badge("", UIKit.AMBER, UIKit.INK, 19)
	_name_label = _name_badge.get_child(0) as Label
	header.add_child(_name_badge)
	_role_label = UIKit.label("", 15, UIKit.MUTED, 500)
	header.add_child(_role_label)
	header.add_child(UIKit.stretch_spacer())
	_kind_badge = UIKit.badge("Conversa", UIKit.PAPER, UIKit.INK, 12)
	_kind_label = _kind_badge.get_child(0) as Label
	header.add_child(_kind_badge)
	var close_button := UIKit.button("Fechar", "ghost", 16)
	close_button.custom_minimum_size = Vector2(96, 38)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(_close)
	header.add_child(close_button)
	box.add_child(header)
	box.add_child(UIKit.divider(Color("#eadcbd"), 1))

	_text_label = UIKit.label("", 22, UIKit.INK, 500, true)
	_text_label.custom_minimum_size = Vector2(0, 86)
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_text_label)

	_reference_label = UIKit.label("", 14, UIKit.BLUE, 600, true)
	_reference_label.visible = false
	_reference_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_reference_label)

	_choices_box = UIKit.vbox(8)
	_choices_box.visible = false
	box.add_child(_choices_box)

	var footer := UIKit.hbox(12)
	_hint_label = UIKit.label("", 14, UIKit.MUTED, 500, true)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_hint_label)
	_next_button = UIKit.button("Continuar", "primary", 18)
	_next_button.custom_minimum_size = Vector2(190, 46)
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next_button.pressed.connect(_advance)
	footer.add_child(_next_button)
	box.add_child(footer)

func open(payload: Dictionary) -> bool:
	var lines = payload.get("lines", [])
	if typeof(lines) != TYPE_ARRAY or lines.is_empty():
		return false
	_payload = payload
	_lines = lines
	_index = 0
	_showing_reply = false
	_typing = false
	_open = true
	visible = true
	_name_label.text = str(payload.get("name", ""))
	_role_label.text = str(payload.get("role", ""))
	_show_line()
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	return true

func is_open() -> bool:
	return _open

func _show_line() -> void:
	if _index < 0 or _index >= _lines.size():
		_close()
		return
	var line: Dictionary = _lines[_index]
	if typeof(line) != TYPE_DICTIONARY:
		_close()
		return
	_name_label.text = str(line.get("speaker", _payload.get("name", "")))
	_full_text = str(line.get("text", ""))
	_text_label.text = ""
	_visible_chars = 0.0
	_typing = true
	_showing_reply = false
	_next_button.visible = false
	_clear_choices()
	var kind := str(line.get("kind", "fala"))
	_set_kind(kind)
	var reference := str(line.get("reference", ""))
	_reference_label.visible = reference != ""
	_reference_label.text = _reference_text(kind, reference)
	_update_hint()

func _process(delta: float) -> void:
	if not _open or not _typing:
		return
	_visible_chars += delta * TYPE_SPEED
	var count := int(_visible_chars)
	if count >= _full_text.length():
		_finish_typing()
	else:
		_text_label.text = _full_text.substr(0, count)

func _finish_typing() -> void:
	_typing = false
	_text_label.text = _full_text
	var line: Dictionary = _lines[_index]
	var choices = line.get("choices", [])
	if typeof(choices) == TYPE_ARRAY and not choices.is_empty():
		_build_choices(choices)
		_next_button.visible = false
	else:
		_next_button.text = "Concluir" if _index >= _lines.size() - 1 else "Continuar"
		_next_button.visible = true
	_update_hint()

func _update_hint() -> void:
	_hint_label.text = "Clique ou pressione Espaço  ·  %d de %d  ·  Esc fecha" % [_index + 1, _lines.size()]

func _build_choices(choices: Array) -> void:
	_clear_choices()
	_choices_box.visible = true
	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		var button := UIKit.button(str(choice.get("text", "Escolher")), "soft", 18)
		button.pressed.connect(_select_choice.bind(choice))
		_choices_box.add_child(button)

func _clear_choices() -> void:
	if not is_instance_valid(_choices_box):
		return
	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	_choices_box.visible = false

func _select_choice(choice: Dictionary) -> void:
	Audio.play_sfx("click")
	var event_name := str(choice.get("event", ""))
	if event_name != "":
		Dialogue.notify_choice(event_name)
	var reply := str(choice.get("reply", ""))
	_clear_choices()
	if reply == "":
		_next_line()
		return
	_showing_reply = true
	_full_text = reply
	_text_label.text = reply
	_typing = false
	_set_kind("fala")
	_reference_label.visible = false
	_next_button.text = "Concluir" if _index >= _lines.size() - 1 else "Continuar"
	_next_button.visible = true

func _advance() -> void:
	if not _open:
		return
	if _typing:
		_finish_typing()
		return
	if _choices_box.visible:
		return
	if _showing_reply:
		_showing_reply = false
		_next_line()
		return
	_next_line()

func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		Audio.play_sfx("click", 1.0, 0.5)
		_show_line()

func _close() -> void:
	if not _open:
		return
	_open = false
	_typing = false
	_clear_choices()
	visible = false
	if Dialogue.is_active:
		Dialogue.finish()
	closed.emit()

func _set_kind(kind: String) -> void:
	var text := "Conversa"
	var bg := UIKit.PAPER
	var fg := UIKit.INK
	match kind:
		"paráfrase":
			text = "Paráfrase bíblica"
			bg = Color("#dce8f8")
			fg = Color("#33567f")
		"citação", "citacao":
			text = "Citação bíblica"
			bg = Color("#ffe7b0")
			fg = Color("#7a4f12")
		"explicação", "explicacao":
			text = "Explicação"
			bg = Color("#dcefdc")
			fg = Color("#2f5c3b")
	_kind_label.text = text
	_kind_label.add_theme_color_override("font_color", fg)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	_kind_badge.add_theme_stylebox_override("panel", style)

func _reference_text(kind: String, reference: String) -> String:
	if reference == "":
		return ""
	if kind == "paráfrase":
		return "Referência: %s  ·  texto em paráfrase" % reference
	if kind == "citação" or kind == "citacao":
		return "Citação bíblica: %s" % reference
	return "Referência: %s" % reference

func _on_outside_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
