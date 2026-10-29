class_name BookPanel
extends Control
## Livro de histórias: pergaminhos colecionados, referências e explicações.

signal closed

const WORLD_TITLES := {
	"eden": "Jardim do Éden",
	"ark": "Arca de Noé",
	"david": "Davi e Golias",
	"moses": "Moisés e o Mar Vermelho",
	"jesus": "Ensinamentos de Jesus",
}
const WORLD_SHORT := {
	"eden": "Éden",
	"ark": "Arca",
	"david": "Davi",
	"moses": "Moisés",
	"jesus": "Jesus",
}

var _filter := "all"
var _selected := ""
var _tabs_box: VBoxContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _count_label: PanelContainer
var _title_label: Label

func _ready() -> void:
	UIKit.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Story.story_unlocked.connect(_on_story_unlocked)

func _build() -> void:
	UIKit.dim(self)
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)
	var card := UIKit.panel(UIKit.CARD, 28, 24, Color("#e0cfa8"))
	card.custom_minimum_size = Vector2(1040, 0)
	center.add_child(card)
	var box := UIKit.vbox(12)
	card.add_child(box)

	var header := UIKit.hbox(14)
	header.add_child(UIKit.icon_circle("▤", UIKit.PAPER, UIKit.AMBER_DEEP, 52, 24))
	var head_text := UIKit.vbox(0)
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label = UIKit.label("Livro de histórias", 30, UIKit.INK, 700)
	head_text.add_child(_title_label)
	head_text.add_child(UIKit.label("Cada pergaminho abre uma coleção de passagens e ensinamentos.", 14, UIKit.MUTED, 500))
	header.add_child(head_text)
	_count_label = UIKit.badge("0 de %d" % Story.stories.size(), UIKit.PAPER, UIKit.INK, 14)
	header.add_child(_count_label)
	var close_button := UIKit.button("Fechar", "ghost", 17)
	close_button.custom_minimum_size = Vector2(96, 44)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(_close)
	header.add_child(close_button)
	box.add_child(header)
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))

	var body := UIKit.hbox(20)
	box.add_child(body)
	_tabs_box = UIKit.vbox(6)
	_tabs_box.custom_minimum_size = Vector2(186, 0)
	_tabs_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(_tabs_box)

	var right := UIKit.vbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 440)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(_scroll)
	_content = UIKit.vbox(10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

	var footer := UIKit.label("Encontre os 15 pergaminhos explorando os mundos. Cada um abre novas passagens para sempre.", 13, UIKit.MUTED, 500)
	box.add_child(footer)

func open(world_id := "") -> void:
	_selected = ""
	_filter = world_id if WORLD_TITLES.has(world_id) else "all"
	visible = true
	_refresh_tabs()
	_refresh_content()
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)

func _refresh_tabs() -> void:
	for child in _tabs_box.get_children():
		_tabs_box.remove_child(child)
		child.queue_free()
	_tabs_box.add_child(UIKit.label("MUNDOS", 12, UIKit.GREEN, 700))
	var entries: Array = [["all", "Todas as histórias"]]
	for world_id in WORLD_TITLES.keys():
		entries.append([world_id, WORLD_SHORT[world_id]])
	for entry in entries:
		var id: String = entry[0]
		var label_text: String = entry[1]
		var selected := id == _filter
		var button := UIKit.button(("• " + label_text) if selected else label_text,
			"soft" if selected else "ghost", 15)
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_select_filter.bind(id))
		_tabs_box.add_child(button)

func _select_filter(world_id: String) -> void:
	_filter = world_id
	_selected = ""
	Audio.play_sfx("click")
	_refresh_tabs()
	_refresh_content()

func _refresh_content() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var total: int = Story.stories.size()
	var badge_label := _count_label.get_child(0) as Label
	if badge_label:
		badge_label.text = "%d de %d" % [SaveSystem.get_storybook().size(), total]
	if _selected != "":
		_build_detail(Story.get_story(_selected))
		return
	var count := 0
	for story in Story.stories.values():
		if typeof(story) != TYPE_DICTIONARY:
			continue
		if _filter != "all" and str(story.get("world", "")) != _filter:
			continue
		count += 1
		_content.add_child(_story_card(story))
	if count == 0:
		var empty := UIKit.panel(UIKit.PAPER, 18, 22)
		var empty_box := UIKit.vbox(8)
		empty_box.add_child(UIKit.label("Nenhuma história por aqui ainda.", 20, UIKit.INK, 700))
		empty_box.add_child(UIKit.label("Explore o mundo para encontrar pergaminhos brilhantes.", 15, UIKit.MUTED, 500, true))
		var show_all := UIKit.button("Ver todas as histórias", "soft", 16)
		show_all.custom_minimum_size = Vector2(240, 44)
		show_all.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		show_all.pressed.connect(_select_filter.bind("all"))
		empty_box.add_child(show_all)
		empty.add_child(empty_box)
		_content.add_child(empty)

func _story_card(story: Dictionary) -> Control:
	var story_id := str(story.get("id", ""))
	var unlocked := SaveSystem.has_story(story_id)
	var world_id := str(story.get("world", ""))
	var accent := Color.from_string(str(story.get("color", "#f2b544")), UIKit.AMBER)
	var card := UIKit.panel(UIKit.CARD if unlocked else Color("#f2ecdc"), 18, 14,
		Color(0, 0, 0, 0) if unlocked else Color("#e6dcc4"))
	var row := UIKit.hbox(14)
	row.add_child(UIKit.icon_circle(str(story.get("icon", "?")), accent if unlocked else Color("#d9d0bb"),
		UIKit.CREAM if unlocked else UIKit.MUTED, 48, 22))
	var text_box := UIKit.vbox(2)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := str(story.get("title", "")) if unlocked else "História ainda não encontrada"
	var title_label := UIKit.label(title, 19, UIKit.INK if unlocked else UIKit.MUTED, 700, true)
	text_box.add_child(title_label)
	var sub := ""
	if unlocked:
		sub = "%s  ·  %s" % [str(story.get("reference", "")), WORLD_TITLES.get(world_id, "")]
	else:
		sub = "%s  ·  procure um pergaminho" % WORLD_TITLES.get(world_id, "Explore o mundo")
	var sub_label := UIKit.label(sub, 12, UIKit.BLUE if unlocked else UIKit.MUTED, 600, true)
	text_box.add_child(sub_label)
	if unlocked:
		var preview := str(story.get("paraphrase", ""))
		if preview.length() > 150:
			preview = preview.substr(0, 147) + "..."
		text_box.add_child(UIKit.label(preview, 13, UIKit.MUTED, 500, true))
	row.add_child(text_box)
	var action := UIKit.button("Ler" if unlocked else "Bloqueado", "soft" if unlocked else "ghost", 15)
	action.custom_minimum_size = Vector2(100, 40)
	action.size_flags_horizontal = Control.SIZE_SHRINK_END
	if unlocked:
		action.pressed.connect(_open_story.bind(story_id))
	else:
		action.disabled = true
	row.add_child(action)
	card.add_child(row)
	return card

func _open_story(story_id: String) -> void:
	_selected = story_id
	Audio.play_sfx("click")
	_refresh_content()
	_scroll.scroll_vertical = 0

func _build_detail(story: Dictionary) -> void:
	if story.is_empty():
		_selected = ""
		_refresh_content()
		return
	var world_id := str(story.get("world", ""))
	var header := UIKit.hbox(10)
	var back := UIKit.button("◀ Voltar", "ghost", 15)
	back.custom_minimum_size = Vector2(116, 40)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_back_to_list)
	header.add_child(back)
	var title := UIKit.label(str(story.get("title", "")), 25, UIKit.INK, 700, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UIKit.badge("PARÁFRASE", Color("#dce8f8"), Color("#33567f"), 12))
	_content.add_child(header)
	_content.add_child(UIKit.label("Referência: %s  ·  %s" % [str(story.get("reference", "")), WORLD_TITLES.get(world_id, "")],
		14, UIKit.BLUE, 600, true))
	_content.add_child(UIKit.divider(Color("#eadcbd"), 2))
	_content.add_child(UIKit.label(str(story.get("paraphrase", "")), 19, UIKit.INK, 500, true))

	var learn := UIKit.panel(UIKit.PAPER, 18, 16)
	var learn_box := UIKit.vbox(4)
	learn_box.add_child(UIKit.label("O QUE APRENDEMOS", 12, UIKit.AMBER_DEEP, 700))
	learn_box.add_child(UIKit.label(str(story.get("explanation", "")), 17, UIKit.INK, 500, true))
	learn.add_child(learn_box)
	_content.add_child(learn)
	_content.add_child(UIKit.label("Texto em paráfrase educativa, com referência bíblica verificável. Não é uma citação literal.",
		12, UIKit.MUTED, 500, true))
	_content.add_child(UIKit.spacer(6))
	var read_another := UIKit.button("Ler outra história", "soft", 16)
	read_another.custom_minimum_size = Vector2(230, 44)
	read_another.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	read_another.pressed.connect(_back_to_list)
	_content.add_child(read_another)

func _back_to_list() -> void:
	_selected = ""
	_refresh_content()
	_scroll.scroll_vertical = 0

func _on_story_unlocked(_story: Dictionary) -> void:
	if visible:
		_refresh_content()

func _close() -> void:
	visible = false
	_selected = ""
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
