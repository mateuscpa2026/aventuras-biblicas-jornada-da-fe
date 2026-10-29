class_name SettingsPanel
extends Control
## Configurações de áudio, câmera e vídeo, com salvamento automático.

signal closed

var _syncing := false
var _master_slider: HSlider
var _master_value: Label
var _music_slider: HSlider
var _music_value: Label
var _sfx_slider: HSlider
var _sfx_value: Label
var _sensitivity_slider: HSlider
var _sensitivity_value: Label
var _resolution_button: Button
var _fullscreen_button: Button
var _quality_button: Button

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
	var card := UIKit.panel(UIKit.CARD, 28, 28, Color("#e0cfa8"))
	card.custom_minimum_size = Vector2(800, 0)
	center.add_child(card)
	var box := UIKit.vbox(14)
	card.add_child(box)

	var header := UIKit.hbox(12)
	header.add_child(UIKit.icon_circle("✧", UIKit.PAPER, UIKit.AMBER_DEEP, 50, 24))
	var head_text := UIKit.vbox(0)
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_text.add_child(UIKit.label("Configurações", 32, UIKit.INK, 700))
	head_text.add_child(UIKit.label("Ajuste o jogo do seu jeitinho. As mudanças são salvas automaticamente.", 14, UIKit.MUTED, 500))
	header.add_child(head_text)
	box.add_child(header)
	box.add_child(UIKit.divider(Color("#eadcbd"), 2))

	var columns := UIKit.hbox(28)
	box.add_child(columns)

	var left := UIKit.vbox(12)
	left.custom_minimum_size = Vector2(0, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	left.add_child(_section("SOM"))
	_master_slider = UIKit.slider(Settings.volume_master, 0.0, 1.0, 0.05)
	_master_value = UIKit.label("", 14, UIKit.GREEN, 700)
	left.add_child(_slider_row("Volume geral", _master_slider, _master_value))
	_music_slider = UIKit.slider(Settings.volume_music, 0.0, 1.0, 0.05)
	_music_value = UIKit.label("", 14, UIKit.GREEN, 700)
	left.add_child(_slider_row("Música", _music_slider, _music_value))
	_sfx_slider = UIKit.slider(Settings.volume_sfx, 0.0, 1.0, 0.05)
	_sfx_value = UIKit.label("", 14, UIKit.GREEN, 700)
	left.add_child(_slider_row("Efeitos e sons", _sfx_slider, _sfx_value))

	left.add_child(UIKit.spacer(2))
	left.add_child(_section("CÂMERA"))
	_sensitivity_slider = UIKit.slider(Settings.mouse_sensitivity, 0.05, 0.8, 0.01)
	_sensitivity_value = UIKit.label("", 14, UIKit.GREEN, 700)
	left.add_child(_slider_row("Sensibilidade do mouse", _sensitivity_slider, _sensitivity_value))
	left.add_child(UIKit.label("Arraste para deixar a câmera mais calma ou mais rápida.", 12, UIKit.MUTED, 500, true))

	var right := UIKit.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	right.add_child(_section("TELA"))
	_resolution_button = UIKit.button("", "soft", 17)
	_resolution_button.custom_minimum_size = Vector2(0, 46)
	_resolution_button.pressed.connect(_cycle_resolution)
	right.add_child(_resolution_button)
	_fullscreen_button = UIKit.button("", "soft", 17)
	_fullscreen_button.custom_minimum_size = Vector2(0, 46)
	_fullscreen_button.pressed.connect(_toggle_fullscreen)
	right.add_child(_fullscreen_button)
	_quality_button = UIKit.button("", "soft", 17)
	_quality_button.custom_minimum_size = Vector2(0, 46)
	_quality_button.pressed.connect(_cycle_quality)
	right.add_child(_quality_button)

	right.add_child(UIKit.spacer(2))
	right.add_child(_section("ACESSIBILIDADE"))
	var tip := UIKit.panel(Color("#f4f7e6"), 16, 12, Color("#dbe4c4"))
	var tip_box := UIKit.vbox(4)
	tip_box.add_child(UIKit.label("Textos grandes, botões amplos e desafios sem punição.", 14, UIKit.INK, 500, true))
	tip_box.add_child(UIKit.label("Você pode rever histórias e revisitar capítulos quando quiser.", 13, UIKit.MUTED, 500, true))
	tip.add_child(tip_box)
	right.add_child(tip)

	var footer := UIKit.hbox(12)
	var note := UIKit.label("Aperte Esc para voltar", 13, UIKit.MUTED, 500)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(note)
	var back := UIKit.button("Voltar", "primary", 19)
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(_close)
	footer.add_child(back)
	box.add_child(footer)

	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

func _section(text: String) -> Label:
	var node := UIKit.label(text, 13, UIKit.GREEN, 700)
	return node

func _slider_row(title: String, slider: HSlider, value_label: Label) -> VBoxContainer:
	var box := UIKit.vbox(3)
	var row := UIKit.hbox(8)
	row.add_child(UIKit.label(title, 16, UIKit.INK, 600))
	row.add_child(UIKit.stretch_spacer())
	row.add_child(value_label)
	box.add_child(row)
	box.add_child(slider)
	return box

func open() -> void:
	visible = true
	_sync()
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)

func _sync() -> void:
	_syncing = true
	_master_slider.value = Settings.volume_master
	_music_slider.value = Settings.volume_music
	_sfx_slider.value = Settings.volume_sfx
	_sensitivity_slider.value = Settings.mouse_sensitivity
	_update_audio_labels()
	_update_video_buttons()
	_syncing = false

func _update_audio_labels() -> void:
	_master_value.text = "%d%%" % roundi(Settings.volume_master * 100.0)
	_music_value.text = "%d%%" % roundi(Settings.volume_music * 100.0)
	_sfx_value.text = "%d%%" % roundi(Settings.volume_sfx * 100.0)
	var word := "Média"
	if Settings.mouse_sensitivity <= 0.18:
		word = "Baixa"
	elif Settings.mouse_sensitivity > 0.4:
		word = "Alta"
	_sensitivity_value.text = "%s · %d%%" % [word, roundi(Settings.mouse_sensitivity / 0.8 * 100.0)]

func _update_video_buttons() -> void:
	var resolution: Vector2i = Settings.RESOLUTIONS[Settings.resolution_index]
	_resolution_button.text = "Resolução: %d × %d" % [resolution.x, resolution.y]
	_fullscreen_button.text = "Tela cheia: %s" % ("Ativada" if Settings.fullscreen else "Desativada")
	_quality_button.text = "Qualidade gráfica: %s" % Settings.QUALITY_NAMES[Settings.quality]

func _on_master_changed(value: float) -> void:
	if _syncing:
		return
	Settings.set_volume_master(value)
	_update_audio_labels()

func _on_music_changed(value: float) -> void:
	if _syncing:
		return
	Settings.set_volume_music(value)
	_update_audio_labels()

func _on_sfx_changed(value: float) -> void:
	if _syncing:
		return
	Settings.set_volume_sfx(value)
	_update_audio_labels()

func _on_sensitivity_changed(value: float) -> void:
	if _syncing:
		return
	Settings.set_sensitivity(value)
	_update_audio_labels()

func _cycle_resolution() -> void:
	Audio.play_sfx("click")
	Settings.set_resolution((Settings.resolution_index + 1) % Settings.RESOLUTIONS.size())
	_update_video_buttons()
	Settings.save()

func _toggle_fullscreen() -> void:
	Audio.play_sfx("click")
	Settings.set_fullscreen(not Settings.fullscreen)
	_update_video_buttons()
	Settings.save()

func _cycle_quality() -> void:
	Audio.play_sfx("click")
	Settings.set_quality((Settings.quality + 1) % 3)
	_update_video_buttons()
	Settings.save()

func _close() -> void:
	Settings.save()
	visible = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
