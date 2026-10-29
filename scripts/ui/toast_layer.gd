class_name ToastLayer
extends Control
## Mensagens curtas que aparecem no topo da tela sem interromper o jogo.

const MAX_TOASTS := 3

var _stack: VBoxContainer

func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stack = UIKit.vbox(8)
	_stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_stack.offset_left = 20
	_stack.offset_right = -20
	_stack.offset_top = 16
	_stack.offset_bottom = 280
	add_child(_stack)
	Game.toast_requested.connect(push)

func push(text: String, icon := "✦") -> void:
	if text.strip_edges() == "" or not is_inside_tree():
		return
	while _stack.get_child_count() >= MAX_TOASTS:
		var oldest := _stack.get_child(0)
		_stack.remove_child(oldest)
		oldest.queue_free()

	var row := UIKit.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var card := UIKit.panel(Color(0.11, 0.17, 0.13, 0.93), 18, 13, Color(0, 0, 0, 0), true)
	card.custom_minimum_size = Vector2(470, 0)
	var content := UIKit.hbox(12)
	var icon_label := UIKit.label(icon, 23, UIKit.AMBER, 700)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(icon_label)
	var text_label := UIKit.label(text, 19, UIKit.CREAM, 600, true)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(text_label)
	card.add_child(content)
	row.add_child(card)
	_stack.add_child(row)

	row.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(row, "modulate:a", 1.0, 0.18)
	tween.tween_interval(2.6)
	tween.tween_property(row, "modulate:a", 0.0, 0.32)
	tween.tween_callback(_dismiss.bind(row))

func _dismiss(row: Control) -> void:
	if is_instance_valid(row):
		row.queue_free()
