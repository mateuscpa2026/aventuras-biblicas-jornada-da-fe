class_name UIKit
## Kit visual compartilhado: cores, fontes e componentes com aparência acolhedora.

const INK := Color("#2a3a31")
const INK_DEEP := Color("#1c2b23")
const CREAM := Color("#fff8e8")
const PAPER := Color("#f7e9c9")
const CARD := Color("#fffdf6")
const GREEN := Color("#3f6b4f")
const GREEN_LIGHT := Color("#6fb07a")
const AMBER := Color("#f2b544")
const AMBER_DEEP := Color("#c9872b")
const CORAL := Color("#e8846b")
const BLUE := Color("#5b8fd6")
const MUTED := Color("#718077")
const DIM := Color(0.06, 0.12, 0.09, 0.55)

static var _fonts: Dictionary = {}

static func font(weight := 500) -> Font:
	var key := str(weight)
	if _fonts.has(key):
		return _fonts[key]
	var path := "res://assets/fonts/Baloo2-Variable.ttf"
	if not ResourceLoader.exists(path):
		return ThemeDB.fallback_font
	var variation := FontVariation.new()
	variation.base_font = load(path)
	variation.variation_opentype = {"wght": float(weight)}
	_fonts[key] = variation
	return variation

static func label(text: String, size := 22, color := INK, weight := 500, wrap := false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font(weight))
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func title(text: String, size := 44) -> Label:
	var node := label(text, size, INK, 700)
	node.add_theme_color_override("font_shadow_color", Color(1, 0.95, 0.8, 0.45))
	node.add_theme_constant_override("shadow_offset_x", 0)
	node.add_theme_constant_override("shadow_offset_y", 3)
	node.add_theme_constant_override("shadow_outline_size", 2)
	return node

static func panel(bg := CARD, radius := 22, padding := 24, border := Color(0, 0, 0, 0), shadow := true) -> PanelContainer:
	var node := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	if border.a > 0.0:
		style.set_border_width_all(2)
		style.border_color = border
	if shadow:
		style.shadow_color = Color(0.12, 0.16, 0.12, 0.22)
		style.shadow_size = 14
		style.shadow_offset = Vector2(0, 6)
	node.add_theme_stylebox_override("panel", style)
	return node

static func button(text: String, kind := "primary", font_size := 24) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_ALL
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = Vector2(0, 54)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_override("font", font(600))
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", INK if kind == "primary" else GREEN if kind == "soft" else INK)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_color_override("font_focus_color", INK)

	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	match kind:
		"primary":
			normal = _pill(AMBER, Color(0, 0, 0, 0), 0)
			hover = _pill(AMBER.lightened(0.1), Color(0, 0, 0, 0), 0)
			pressed = _pill(AMBER.darkened(0.08), Color(0, 0, 0, 0), 0)
		"soft":
			normal = _pill(CREAM, Color("#dcc9a0"), 2)
			hover = _pill(Color("#fffdf4"), AMBER, 2)
			pressed = _pill(PAPER, AMBER, 2)
		"ghost":
			normal = _pill(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 0)
			hover = _pill(Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0), 0)
			pressed = _pill(Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.0), 0)
		"danger":
			normal = _pill(CORAL, Color(0, 0, 0, 0), 0)
			hover = _pill(CORAL.lightened(0.08), Color(0, 0, 0, 0), 0)
			pressed = _pill(CORAL.darkened(0.08), Color(0, 0, 0, 0), 0)
		_:
			normal = _pill(CREAM, Color("#dcc9a0"), 2)
			hover = _pill(Color("#fffdf4"), AMBER, 2)
			pressed = _pill(PAPER, AMBER, 2)

	node.add_theme_stylebox_override("normal", normal)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_stylebox_override("disabled", _pill(Color("#e8e0cd"), Color("#ddd2ba"), 2))
	node.add_theme_color_override("font_disabled_color", Color(0.35, 0.38, 0.34, 0.65))
	var focus := _pill(Color(1, 1, 1, 0.0), AMBER, 3)
	focus.set_content_margin_all(6)
	node.add_theme_stylebox_override("focus", focus)
	return node

static func _pill(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(24)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	if border_width > 0:
		style.set_border_width_all(border_width)
		style.border_color = border
	return style

static func badge(text: String, bg: Color, fg := INK, font_size := 13) -> PanelContainer:
	var node := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	node.add_theme_stylebox_override("panel", style)
	node.add_child(label(text, font_size, fg, 700))
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return node

static func vbox(separation := 12) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node

static func hbox(separation := 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node

static func spacer(height := 12) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	return node

static func stretch_spacer() -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node

static func dim(parent: Control) -> ColorRect:
	var node := ColorRect.new()
	node.color = DIM
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(node)
	return node

static func full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func centered_panel(width: float, padding := 32, bg := CARD) -> PanelContainer:
	var node := panel(bg, 26, padding)
	node.custom_minimum_size = Vector2(width, 0)
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return node

static func progress_bar(value: float, max_value: float, color := AMBER) -> ProgressBar:
	var node := ProgressBar.new()
	node.max_value = maxf(0.001, max_value)
	node.value = value
	node.show_percentage = false
	node.custom_minimum_size = Vector2(0, 10)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.15, 0.22, 0.17, 0.12)
	background.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	node.add_theme_stylebox_override("background", background)
	node.add_theme_stylebox_override("fill", fill)
	return node

static func slider(value: float, min_value := 0.0, max_value := 1.0, step := 0.05) -> HSlider:
	var node := HSlider.new()
	node.min_value = min_value
	node.max_value = max_value
	node.step = step
	node.value = value
	node.custom_minimum_size = Vector2(260, 36)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return node

static func scroll_content(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var content := UIKit.vbox(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll

static func icon_circle(text: String, bg: Color, fg := INK, size := 46, font_size := 22) -> PanelContainer:
	var node := PanelContainer.new()
	node.custom_minimum_size = Vector2(size, size)
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(int(size * 0.5))
	node.add_theme_stylebox_override("panel", style)
	var label_node := label(text, font_size, fg, 700)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(label_node)
	return node

static func divider(color := Color("#e0d3b4"), height := 2) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.custom_minimum_size = Vector2(0, height)
	return node

static func style_panel(panel: PanelContainer, bg: Color, radius := 20,
		border := Color(0, 0, 0, 0), padding := 0, border_width := 2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	if padding > 0:
		style.set_content_margin_all(padding)
	if border.a > 0.0:
		style.set_border_width_all(border_width)
		style.border_color = border
	panel.add_theme_stylebox_override("panel", style)
