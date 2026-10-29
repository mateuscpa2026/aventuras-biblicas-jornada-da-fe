class_name PromptBadge
extends Node3D
## Botão flutuante de interação: pílula com a tecla E e a ação, desenhada em um
## SubViewport e exibida como Sprite3D com billboard (sempre de frente para a câmera).

const VIEW_HEIGHT := 104
const FONT_SIZE := 32
const PILL_HEIGHT := 84

var _viewport: SubViewport
var _sprite: Sprite3D
var _pill: PanelContainer
var _label: Label
var _text := ""
var _time := 0.0
var _base_y := 0.0
var _shown := false

func _ready() -> void:
	_base_y = position.y
	_build()

func _build() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.size = Vector2i(460, VIEW_HEIGHT)
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)

	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	_pill = PanelContainer.new()
	_pill.name = "Pill"
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.12, 0.09, 0.94)
	style.set_corner_radius_all(PILL_HEIGHT / 2)
	style.set_border_width_all(3)
	style.border_color = UIKit.AMBER
	style.content_margin_left = 14
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.03, 0.06, 0.04, 0.45)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	_pill.add_theme_stylebox_override("panel", style)
	center.add_child(_pill)

	var row := UIKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UIKit.icon_circle("E", UIKit.AMBER, UIKit.INK, 48, 28))
	_label = UIKit.label("", FONT_SIZE, UIKit.CREAM, 700)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_label)
	_pill.add_child(row)

	_sprite = Sprite3D.new()
	_sprite.name = "Badge"
	_sprite.texture = _viewport.get_texture()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.no_depth_test = true
	_sprite.render_priority = 20
	_sprite.pixel_size = 0.0042
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sprite.visible = false
	add_child(_sprite)

func show_text(text: String) -> void:
	if not is_inside_tree():
		return
	if text.strip_edges() == "":
		hide_badge()
		return
	if _sprite == null:
		_build()
	visible = true
	_shown = true
	if text != _text:
		_text = text
		_label.text = text
		_resize()
	_sprite.visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func hide_badge() -> void:
	_shown = false
	visible = false
	if _sprite:
		_sprite.visible = false
	if _viewport:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func has_text(text: String) -> bool:
	return _text == text

func set_height(height: float) -> void:
	_base_y = height
	position.y = height

func _resize() -> void:
	var text_width := UIKit.font(700).get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var pill_width := 48.0 + 10.0 + text_width + 34.0 + 6.0
	var width := clampi(int(ceil(pill_width + 30.0)), 280, 1000)
	_viewport.size = Vector2i(width, VIEW_HEIGHT)

func _process(delta: float) -> void:
	if not _shown or _sprite == null:
		return
	_time += delta
	position.y = _base_y + sin(_time * 3.2) * 0.018
	var pulse := 1.0 + sin(_time * 3.2 + 0.8) * 0.015
	_sprite.scale = Vector3(pulse, pulse, 1.0)
