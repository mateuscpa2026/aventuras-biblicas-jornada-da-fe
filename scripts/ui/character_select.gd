class_name CharacterSelectScreen
extends Control
## Escolha do explorador que a criança vai guiar, com prévia 3D de cada um.

signal begin_requested(look_id: String)
signal changed(look_id: String)
signal back_requested

const PREVIEW_SIZE := 400

var _selected := ""
var _start_mode := true
var _cards: Dictionary = {}
var _previews: Array[Dictionary] = []
var _checks: Dictionary = {}
var _title: Label
var _hint: Label
var _confirm: Button
var _time := 0.0

func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	visible = false

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.992, 0.973, 0.914, 1.0)
	UIKit.full_rect(background)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var decor := ColorRect.new()
	decor.color = Color(0.247, 0.42, 0.31, 0.08)
	decor.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	decor.offset_bottom = 128
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decor)

	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)

	var panel := UIKit.panel(UIKit.CARD, 28, 30)
	panel.custom_minimum_size = Vector2(1064, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	var content := UIKit.vbox(14)
	panel.add_child(content)

	var header := UIKit.hbox(14)
	var mark := UIKit.icon_circle("★", Color("#ffe7b0"), Color("#7a4f12"), 46, 22)
	header.add_child(mark)
	var titles := UIKit.vbox(0)
	_title = UIKit.label("Quem vai caminhar com você?", 30, UIKit.INK, 700)
	titles.add_child(_title)
	_hint = UIKit.label("Escolha seu explorador. Ele acompanha você pelos cinco mundos.", 14, UIKit.MUTED, 500)
	titles.add_child(_hint)
	header.add_child(titles)
	content.add_child(header)
	content.add_child(UIKit.divider(Color("#eadcbd"), 2))

	var row := UIKit.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(row)
	for look in PlayerLooks.LOOKS:
		var card := _build_card(look)
		row.add_child(card)

	var footer := UIKit.hbox(12)
	var back := UIKit.button("Voltar", "ghost", 17)
	back.custom_minimum_size = Vector2(150, 50)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_on_back)
	footer.add_child(back)
	footer.add_child(UIKit.stretch_spacer())
	var note := UIKit.label("Você pode trocar de explorador no menu quando quiser.", 12, UIKit.MUTED, 500)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(note)
	_confirm = UIKit.button("Começar jornada", "primary", 20)
	_confirm.custom_minimum_size = Vector2(280, 50)
	_confirm.size_flags_horizontal = Control.SIZE_SHRINK_END
	_confirm.pressed.connect(_on_confirm)
	footer.add_child(_confirm)
	content.add_child(footer)

func _build_card(look: Dictionary) -> Button:
	var look_id := str(look["id"])
	var card := Button.new()
	card.name = "Card_" + look_id
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.custom_minimum_size = Vector2(232, 340)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("normal", _card_style(UIKit.CARD, Color("#e4d6b6"), 2))
	card.add_theme_stylebox_override("hover", _card_style(Color("#fffdf6"), UIKit.AMBER, 2))
	card.add_theme_stylebox_override("pressed", _card_style(Color("#fff6df"), UIKit.AMBER_DEEP, 2))
	card.add_theme_stylebox_override("focus", _card_style(Color(0, 0, 0, 0), UIKit.AMBER, 3))
	card.pressed.connect(_select.bind(look_id))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var box := UIKit.vbox(4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var preview := SubViewportContainer.new()
	preview.custom_minimum_size = Vector2(0, 214)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.stretch = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(preview)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(PREVIEW_SIZE, PREVIEW_SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.msaa_3d = Viewport.MSAA_4X
	preview.add_child(viewport)

	var rig := StylizedRig.new()
	rig.name = "Preview_" + look_id
	PlayerLooks.apply(rig, look_id)
	viewport.add_child(rig)

	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.position = Vector3(0, 0.92, -3.05)
	camera.rotation_degrees = Vector3(-1.1, 180, 0)
	camera.current = true
	viewport.add_child(camera)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, 34, 0)
	key.light_color = Color("#fff3d8")
	key.light_energy = 1.15
	key.shadow_enabled = false
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12, -128, 0)
	fill.light_color = Color("#d8e9ff")
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	viewport.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(22, 178, 0)
	rim.light_color = Color("#ffe2b0")
	rim.light_energy = 0.4
	rim.shadow_enabled = false
	viewport.add_child(rim)
	_previews.append({"viewport": viewport, "rig": rig, "index": _previews.size()})

	var name_label := UIKit.label(str(look["name"]), 24, UIKit.INK, 700)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var tag := UIKit.label(str(look["tag"]), 13, UIKit.MUTED, 500)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tag)

	var check := PanelContainer.new()
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	check.offset_left = -44
	check.offset_top = 10
	check.offset_right = -10
	check.offset_bottom = 44
	var check_style := StyleBoxFlat.new()
	check_style.bg_color = UIKit.AMBER
	check_style.set_corner_radius_all(16)
	check.add_theme_stylebox_override("panel", check_style)
	var check_text := UIKit.label("✓", 17, UIKit.INK, 700)
	check_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check.add_child(check_text)
	check.visible = false
	card.add_child(check)
	_checks[look_id] = check
	_cards[look_id] = card
	return card

func _card_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(20)
	style.set_border_width_all(width)
	style.border_color = border
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	if bg.a > 0.0:
		style.shadow_color = Color(0.12, 0.16, 0.12, 0.14)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 4)
	return style

func open(start_mode: bool) -> void:
	_start_mode = start_mode
	_selected = SaveSystem.get_player_look()
	_title.text = "Quem vai caminhar com você?" if start_mode else "Escolha seu explorador"
	_hint.text = "Escolha seu explorador. Ele acompanha você pelos cinco mundos." if start_mode \
		else "A troca vale para todas as histórias desta jornada."
	_confirm.text = "Começar jornada" if start_mode else "Usar este explorador"
	_refresh()
	visible = true
	for entry in _previews:
		entry["viewport"].render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_time = 0.0
	if _cards.has(_selected):
		_cards[_selected].grab_focus()

func hide_screen() -> void:
	visible = false
	for entry in _previews:
		entry["viewport"].render_target_update_mode = SubViewport.UPDATE_DISABLED

func _select(look_id: String) -> void:
	if not PlayerLooks.is_valid(look_id):
		return
	Audio.play_sfx("click")
	_selected = look_id
	_refresh()

func _refresh() -> void:
	for look_id in _cards.keys():
		if not _cards.has(look_id):
			continue
		var card: Button = _cards[look_id]
		if look_id == _selected:
			card.add_theme_stylebox_override("normal", _card_style(Color("#fff7e2"), UIKit.AMBER_DEEP, 3))
		else:
			card.add_theme_stylebox_override("normal", _card_style(UIKit.CARD, Color("#e4d6b6"), 2))
		_checks[look_id].visible = look_id == _selected

func _on_confirm() -> void:
	Audio.play_sfx("click")
	if _start_mode:
		begin_requested.emit(_selected)
	else:
		changed.emit(_selected)

func _on_back() -> void:
	Audio.play_sfx("click")
	back_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		_on_back()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for entry in _previews:
		var rig: Node3D = entry["rig"]
		if is_instance_valid(rig):
			rig.rotation.y = sin(_time * 0.9 + float(entry["index"]) * 1.25) * 0.32
