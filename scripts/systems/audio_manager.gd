extends Node
## Áudio: música ambiente por mundo e efeitos sonoros.
## Os arquivos em assets/audio são provisórios e podem ser substituídos mantendo os nomes.

const SFX_NAMES := ["click", "collect", "success", "interact", "jump", "wrong", "throw", "deliver"]
const MUSIC_BY_WORLD := {
	"eden": "res://assets/audio/music/trilha_eden.wav",
	"ark": "res://assets/audio/music/trilha_arca.wav",
	"david": "res://assets/audio/music/trilha_davi.wav",
	"moses": "res://assets/audio/music/trilha_moises.wav",
	"jesus": "res://assets/audio/music/trilha_jesus.wav",
	"menu": "res://assets/audio/music/trilha_menu.wav",
}

var _music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _current_music := ""
var _music_tween: Tween

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.name = "MusicPlayer"
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPlayer%d" % i
		add_child(p)
		_sfx_players.append(p)
	for sfx_name in SFX_NAMES:
		var path := "res://assets/audio/sfx/%s.wav" % sfx_name
		if ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)
	Settings.changed.connect(_apply_volumes)
	_apply_volumes()

func _exit_tree() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	_music = null
	_sfx_players.clear()
	_sfx_streams.clear()

func _apply_volumes() -> void:
	if _music:
		_music.volume_db = _linear_to_db(Settings.volume_master * Settings.volume_music)

func _linear_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)

func play_music(world_id: String) -> void:
	var path: String = MUSIC_BY_WORLD.get(world_id, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	if _current_music == path:
		return
	_current_music = path
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	var use_fade := _music.playing
	var next_player := AudioStreamPlayer.new()
	next_player.name = "MusicNext"
	next_player.stream = stream
	next_player.volume_db = -60.0
	add_child(next_player)
	next_player.play()
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	var target_db := _linear_to_db(Settings.volume_master * Settings.volume_music)
	_music_tween.tween_property(next_player, "volume_db", target_db, 1.4)
	if use_fade:
		var old_player := _music
		_music_tween.tween_property(old_player, "volume_db", -60.0, 1.0)
		_music_tween.chain().tween_callback(old_player.queue_free)
	_music = next_player

func stop_music(fade := true) -> void:
	_current_music = ""
	if _music:
		if fade:
			var t := create_tween()
			t.tween_property(_music, "volume_db", -60.0, 0.6)
			t.tween_callback(_music.stop)
		else:
			_music.stop()

func play_sfx(sfx_name: String, pitch := 1.0, volume := 1.0) -> void:
	var stream = _sfx_streams.get(sfx_name)
	if stream == null:
		return
	var player := _pick_sfx_player()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = _linear_to_db(Settings.volume_master * Settings.volume_sfx * volume)
	player.play()

func _pick_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]
