extends Node
## Configurações do jogador: áudio, vídeo, qualidade e sensibilidade.

signal changed

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const QUALITY_NAMES := ["Baixa", "Média", "Alta"]

var volume_master := 0.9
var volume_music := 0.55
var volume_sfx := 0.8
var mouse_sensitivity := 0.22
var resolution_index := 0
var fullscreen := true
var quality := 1

func _ready() -> void:
	_load()
	if DisplayServer.get_name() != "headless":
		apply_display()

func _load() -> void:
	var stored := SaveSystem.get_settings()
	if stored.is_empty():
		return
	volume_master = clampf(float(stored.get("volume_master", volume_master)), 0.0, 1.0)
	volume_music = clampf(float(stored.get("volume_music", volume_music)), 0.0, 1.0)
	volume_sfx = clampf(float(stored.get("volume_sfx", volume_sfx)), 0.0, 1.0)
	mouse_sensitivity = clampf(float(stored.get("mouse_sensitivity", mouse_sensitivity)), 0.05, 0.8)
	resolution_index = clampi(int(stored.get("resolution_index", resolution_index)), 0, RESOLUTIONS.size() - 1)
	fullscreen = bool(stored.get("fullscreen", fullscreen))
	quality = clampi(int(stored.get("quality", quality)), 0, 2)

func save() -> void:
	var values := {
		"volume_master": volume_master,
		"volume_music": volume_music,
		"volume_sfx": volume_sfx,
		"mouse_sensitivity": mouse_sensitivity,
		"resolution_index": resolution_index,
		"fullscreen": fullscreen,
		"quality": quality,
	}
	SaveSystem.set_settings(values)
	SaveSystem.write()

func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(RESOLUTIONS[resolution_index])

func apply_all() -> void:
	apply_display()
	changed.emit()

func set_volume_master(value: float) -> void:
	volume_master = clampf(value, 0.0, 1.0)
	changed.emit()

func set_volume_music(value: float) -> void:
	volume_music = clampf(value, 0.0, 1.0)
	changed.emit()

func set_volume_sfx(value: float) -> void:
	volume_sfx = clampf(value, 0.0, 1.0)
	changed.emit()

func set_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.05, 0.8)
	changed.emit()

func set_quality(value: int) -> void:
	quality = clampi(value, 0, 2)
	changed.emit()

func set_resolution(value: int) -> void:
	resolution_index = clampi(value, 0, RESOLUTIONS.size() - 1)
	apply_display()
	changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_display()
	changed.emit()

func shadow_enabled() -> bool:
	return quality >= 1

func shadow_max_distance() -> float:
	return [34.0, 34.0, 58.0][quality]

func camera_far() -> float:
	return [140.0, 220.0, 320.0][quality]
