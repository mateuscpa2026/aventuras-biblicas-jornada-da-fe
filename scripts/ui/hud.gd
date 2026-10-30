class_name GameHUD
extends Control
## HUD infantil: capítulo, objetivos, pergaminhos, prompt de interação e mira.

const CARRY_NAMES := {
	"pao": "pão",
	"cesta_paes": "cesta de pães",
	"madeira": "madeira",
	"provisao": "provisão",
	"pedra": "pedra",
	"flor": "flor",
}

var _world_id := ""
var _chapter_order := 0
var _chapter_eyebrow: Label
var _chapter_title: Label
var _chapter_subtitle: Label
var _chapter_icon: PanelContainer
var _chapter_icon_label: Label
var _mission_list: VBoxContainer
var _scrolls_label: Label
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _carry_panel: PanelContainer
var _carry_label: Label
var _crosshair: Control

func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	Missions.mission_list_changed.connect(refresh_missions)
	Missions.mission_progress.connect(_on_mission_progress)
	Missions.mission_completed.connect(_on_mission_completed)
	Story.story_unlocked.connect(_on_story_unlocked)
	Game.carry_changed.connect(refresh_carry)
	Game.chapter_completed.connect(_on_chapter_completed)

func _build() -> void:
	var top := UIKit.hbox(18)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 20
	top.offset_bottom = 20
	add_child(top)

	var left := UIKit.vbox(10)
	left.custom_minimum_size = Vector2(336, 0)
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(left)

	var chapter_card := UIKit.panel(Color(1, 0.99, 0.95, 0.98), 20, 14, Color("#e3d2ac"))
	var chapter_row := UIKit.hbox(12)
	_chapter_icon = UIKit.icon_circle("1", UIKit.AMBER, UIKit.INK, 46, 22)
	_chapter_icon_label = _chapter_icon.get_child(0) as Label
	chapter_row.add_child(_chapter_icon)
	var chapter_text := UIKit.vbox(0)
	_chapter_eyebrow = UIKit.label("CAPÍTULO 1", 12, UIKit.MUTED, 700)
	_chapter_title = UIKit.label("Jardim do Éden", 21, UIKit.INK, 700)
	_chapter_subtitle = UIKit.label("A criação", 14, UIKit.MUTED, 500)
	chapter_text.add_child(_chapter_eyebrow)
	chapter_text.add_child(_chapter_title)
	chapter_text.add_child(_chapter_subtitle)
	chapter_row.add_child(chapter_text)
	chapter_card.add_child(chapter_row)
	left.add_child(chapter_card)

	var mission_card := UIKit.panel(Color(1, 0.99, 0.95, 0.98), 18, 14, Color("#e3d2ac"))
	var mission_box := UIKit.vbox(9)
	var mission_header := UIKit.hbox(6)
	mission_header.add_child(UIKit.label("OBJETIVOS", 12, UIKit.GREEN, 700))
	mission_header.add_child(UIKit.stretch_spacer())
	mission_header.add_child(UIKit.label("siga as pistas", 12, UIKit.MUTED, 500))
	mission_box.add_child(mission_header)
	_mission_list = UIKit.vbox(10)
	mission_box.add_child(_mission_list)
	mission_card.add_child(mission_box)
	left.add_child(mission_card)

	top.add_child(UIKit.stretch_spacer())

	var right := UIKit.vbox(10)
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var scrolls := UIKit.panel(Color(1, 0.99, 0.95, 0.98), 18, 12, Color("#e3d2ac"))
	var scroll_row := UIKit.hbox(10)
	scroll_row.add_child(UIKit.icon_circle("▤", UIKit.PAPER, UIKit.AMBER_DEEP, 42, 20))
	var scroll_text := UIKit.vbox(0)
	_scrolls_label = UIKit.label("0 / 0", 19, UIKit.INK, 700)
	scroll_text.add_child(_scrolls_label)
	scroll_text.add_child(UIKit.label("Histórias", 12, UIKit.MUTED, 500))
	scroll_row.add_child(scroll_text)
	scrolls.add_child(scroll_row)
	right.add_child(scrolls)
	top.add_child(right)

	var bottom := UIKit.vbox(8)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_left = -350
	bottom.offset_right = 350
	bottom.offset_top = -150
	bottom.offset_bottom = -26
	bottom.alignment = BoxContainer.ALIGNMENT_END
	add_child(bottom)

	_prompt_panel = UIKit.panel(Color(0.09, 0.15, 0.11, 0.88), 20, 11)
	_prompt_panel.visible = false
	_prompt_label = UIKit.label("", 20, UIKit.CREAM, 600)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_panel.add_child(_prompt_label)
	bottom.add_child(_prompt_panel)

	_crosshair = Control.new()
	_crosshair.name = "Crosshair"
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -18
	_crosshair.offset_right = 18
	_crosshair.offset_top = -18
	_crosshair.offset_bottom = 18
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.visible = false
	add_child(_crosshair)
	_add_crosshair_parts(Color(0.1, 0.14, 0.1, 0.55), 2)
	_add_crosshair_parts(Color("#ffe28a"), 0)
	var dot := ColorRect.new()
	dot.color = UIKit.AMBER
	dot.position = Vector2(15, 15)
	dot.size = Vector2(6, 6)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.add_child(dot)

	var hint := UIKit.panel(Color(0.09, 0.15, 0.11, 0.6), 14, 8)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 24
	hint.offset_top = -62
	hint.offset_bottom = -24
	hint.offset_right = 24
	add_child(hint)
	hint.add_child(UIKit.label("WASD mover  ·  Mouse olhar  ·  Shift correr  ·  Espaço pular  ·  E interagir", 13, UIKit.CREAM, 500))

	_carry_panel = UIKit.panel(Color(1, 0.99, 0.95, 0.98), 16, 10, Color("#e3d2ac"))
	_carry_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_carry_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_carry_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_carry_panel.offset_left = -24
	_carry_panel.offset_right = -24
	_carry_panel.offset_top = -74
	_carry_panel.offset_bottom = -24
	_carry_panel.visible = false
	add_child(_carry_panel)
	_carry_label = UIKit.label("", 15, UIKit.INK, 600)
	_carry_panel.add_child(_carry_label)

func _add_crosshair_parts(color: Color, grow: float) -> void:
	var parts := [
		Rect2(14 - grow, 0, 8 + grow * 2, 10),
		Rect2(14 - grow, 26, 8 + grow * 2, 10),
		Rect2(0, 14 - grow, 10, 8 + grow * 2),
		Rect2(26, 14 - grow, 10, 8 + grow * 2),
	]
	for rect in parts:
		var line := ColorRect.new()
		line.color = color
		line.position = rect.position
		line.size = rect.size
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair.add_child(line)

func setup(chapter: Dictionary) -> void:
	_world_id = str(chapter.get("id", ""))
	_chapter_order = int(chapter.get("order", 1))
	var accent := Color.from_string(str(chapter.get("color", "#58a86b")), UIKit.GREEN)
	_chapter_eyebrow.text = "CAPÍTULO %d" % _chapter_order
	_chapter_title.text = str(chapter.get("title", ""))
	_chapter_subtitle.text = str(chapter.get("subtitle", ""))
	_chapter_icon_label.text = _chapter_glyph(_world_id)
	UIKit.style_panel(_chapter_icon, accent, 23)
	_chapter_icon_label.add_theme_color_override("font_color", UIKit.CREAM)
	refresh_story_count()
	refresh_missions()
	refresh_carry()

func _chapter_glyph(world_id: String) -> String:
	match world_id:
		"eden": return "❀"
		"ark": return "⚓"
		"david": return "◎"
		"moses": return "≈"
		"jesus": return "♥"
		_: return "✦"

func refresh_missions() -> void:
	if not is_instance_valid(_mission_list):
		return
	for child in _mission_list.get_children():
		child.queue_free()
	var active := Missions.get_active()
	if active.is_empty():
		var done := UIKit.label("Tudo em ordem por aqui. Continue explorando!", 15, UIKit.MUTED, 500, true)
		_mission_list.add_child(done)
		return
	var shown := 0
	for mission in active:
		if shown >= 3:
			break
		shown += 1
		var row := UIKit.vbox(3)
		var title := UIKit.label(str(mission.get("title", "")), 17, UIKit.INK, 700, true)
		row.add_child(title)
		var objective := UIKit.label(str(mission.get("objective", "")), 14, UIKit.MUTED, 500, true)
		row.add_child(objective)
		var progress := int(mission.get("progress", 0))
		var target := int(mission.get("target", 1))
		var progress_row := UIKit.hbox(8)
		var bar := UIKit.progress_bar(progress, target, UIKit.AMBER)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 8
		progress_row.add_child(bar)
		var count := UIKit.label("%d/%d" % [progress, target], 14, UIKit.GREEN, 700)
		progress_row.add_child(count)
		row.add_child(progress_row)
		_mission_list.add_child(row)
		if shown < active.size() and shown < 3:
			_mission_list.add_child(UIKit.divider(Color("#e9dcc0"), 1))

func refresh_story_count() -> void:
	if not is_instance_valid(_scrolls_label) or _world_id == "":
		return
	var total := Story.get_world_stories(_world_id).size()
	var found := Story.count_unlocked(_world_id)
	_scrolls_label.text = "%d / %d" % [found, total]

func refresh_carry() -> void:
	if not is_instance_valid(_carry_panel):
		return
	var parts: Array[String] = []
	for item_id in Game.carried.keys():
		var amount := int(Game.carried[item_id])
		if amount <= 0:
			continue
		var label_text: String = CARRY_NAMES.get(str(item_id), str(item_id))
		parts.append("%d × %s" % [amount, label_text])
	_carry_label.text = "Carregando: " + "  ·  ".join(parts)
	_carry_panel.visible = not parts.is_empty()

func set_prompt(text: String) -> void:
	if not is_instance_valid(_prompt_panel):
		return
	_prompt_label.text = text
	_prompt_panel.visible = text.strip_edges() != ""

func set_aiming(active: bool) -> void:
	if is_instance_valid(_crosshair):
		_crosshair.visible = active

func _on_mission_progress(_mission: Dictionary, _progress: int, _target: int) -> void:
	refresh_missions()

func _on_mission_completed(mission: Dictionary) -> void:
	refresh_missions()
	Game.toast("Missão concluída: " + str(mission.get("title", "")), "✔")

func _on_story_unlocked(_story: Dictionary) -> void:
	refresh_story_count()

func _on_chapter_completed(_world_id: String) -> void:
	refresh_missions()
