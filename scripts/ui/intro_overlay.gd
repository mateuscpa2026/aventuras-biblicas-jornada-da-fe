class_name IntroOverlay
extends Control
## Cartão de abertura de cada capítulo, com objetivo, paráfrase bíblica e os
## personagens principais em retratos 3D.

signal started

const PORTRAIT_SIZE := 240
const PORTRAIT_HEIGHT := 132

var _badge_label: Label
var _title: Label
var _subtitle: Label
var _intro: Label
var _goal: Label
var _verse: Label
var _verse_ref: Label
var _cast_box: HBoxContainer
var _cast_previews: Array[Dictionary] = []
var _card: PanelContainer
var _open := false
var _time := 0.0

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
	_card = UIKit.panel(UIKit.CARD, 28, 30, Color("#e0cfa8"))
	_card.custom_minimum_size = Vector2(960, 0)
	center.add_child(_card)
	var box := UIKit.vbox(10)
	_card.add_child(box)

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
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))

	var body := UIKit.hbox(22)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(body)

	var text_col := UIKit.vbox(8)
	text_col.custom_minimum_size = Vector2(480, 0)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(text_col)

	_intro = UIKit.label("", 20, UIKit.INK, 500, true)
	text_col.add_child(_intro)

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
	text_col.add_child(goal_card)

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
	text_col.add_child(verse_card)

	var cast_col := UIKit.vbox(5)
	cast_col.custom_minimum_size = Vector2(330, 0)
	body.add_child(cast_col)
	cast_col.add_child(UIKit.label("NESTA HISTÓRIA", 12, UIKit.AMBER_DEEP, 700))
	cast_col.add_child(UIKit.label("Personagens principais do capítulo", 11, UIKit.MUTED, 500, true))
	_cast_box = UIKit.hbox(10)
	_cast_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	cast_col.add_child(_cast_box)

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
	_build_cast(chapter)
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _build_cast(chapter: Dictionary) -> void:
	_clear_cast()
	_time = 0.0
	var accent := Color.from_string(str(chapter.get("color", "#58a86b")), UIKit.GREEN)
	var member_ids: Array = chapter.get("cast", [])
	if member_ids.is_empty():
		_cast_box.add_child(UIKit.label("Personagens desta história", 12, UIKit.MUTED, 500))
		return
	for member_id in member_ids:
		if StoryCast.is_valid(str(member_id)):
			_build_cast_card(str(member_id), accent)
	for entry in _cast_previews:
		entry["viewport"].render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _build_cast_card(member_id: String, accent: Color) -> void:
	var member := StoryCast.member(member_id)
	var card := UIKit.panel(Color("#fbf3e0"), 16, 8, Color("#e6d7b5"), false)
	card.custom_minimum_size = Vector2(0, 216)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_cast_box.add_child(card)
	var box := UIKit.vbox(2)
	card.add_child(box)

	var preview := SubViewportContainer.new()
	preview.custom_minimum_size = Vector2(PORTRAIT_HEIGHT, PORTRAIT_HEIGHT)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.stretch = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(preview)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(PORTRAIT_SIZE, PORTRAIT_SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.msaa_3d = Viewport.MSAA_4X
	preview.add_child(viewport)

	_add_backdrop(viewport, accent)

	var rig := StylizedRig.new()
	rig.configure(StoryCast.look(member_id))
	viewport.add_child(rig)
	if member.get("look", {}).has("beard"):
		rig.add_beard(member["look"]["beard"])

	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0, 1.36, -1.6)
	camera.rotation_degrees = Vector3(0, 180, 0)
	camera.current = true
	viewport.add_child(camera)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32, 30, 0)
	key.light_color = Color("#fff3d8")
	key.light_energy = 1.2
	key.shadow_enabled = false
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, -128, 0)
	fill.light_color = Color("#d8e9ff")
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	viewport.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(24, 176, 0)
	rim.light_color = Color("#ffe2b0")
	rim.light_energy = 0.42
	rim.shadow_enabled = false
	viewport.add_child(rim)

	var name_label := UIKit.label(str(member.get("name", "")), 17, UIKit.INK, 700)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var role_label := UIKit.label(str(member.get("role", "")), 11, UIKit.MUTED, 500, true)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	role_label.custom_minimum_size = Vector2(0, 30)
	box.add_child(role_label)

	_cast_previews.append({"viewport": viewport, "rig": rig, "index": _cast_previews.size()})

func _add_backdrop(viewport: SubViewport, accent: Color) -> void:
	for entry in [
		[0.585, accent.darkened(0.06), 0.64],
		[0.55, accent.lightened(0.55), 0.62],
	]:
		var disc := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = float(entry[0])
		mesh.bottom_radius = float(entry[0])
		mesh.height = 0.04
		mesh.radial_segments = 40
		disc.mesh = mesh
		disc.rotation_degrees = Vector3(90, 0, 0)
		disc.position = Vector3(0, 1.36, float(entry[2]))
		var material := StandardMaterial3D.new()
		material.albedo_color = entry[1]
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disc.material_override = material
		viewport.add_child(disc)

func _clear_cast() -> void:
	for entry in _cast_previews:
		var viewport: SubViewport = entry["viewport"]
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_cast_previews.clear()
	for child in _cast_box.get_children():
		_cast_box.remove_child(child)
		child.queue_free()

func _stop_previews() -> void:
	for entry in _cast_previews:
		var viewport: SubViewport = entry["viewport"]
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _start() -> void:
	if not _open:
		return
	_open = false
	visible = false
	_stop_previews()
	Audio.play_sfx("click")
	started.emit()

func close() -> void:
	_open = false
	visible = false
	_stop_previews()

func skip() -> void:
	_start()

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for entry in _cast_previews:
		var rig: Node3D = entry["rig"]
		if is_instance_valid(rig):
			rig.rotation.y = sin(_time * 0.8 + float(entry["index"]) * 1.3) * 0.16

func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_start()
