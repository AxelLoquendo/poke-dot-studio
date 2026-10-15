extends Node
## Autoload MusicManager
## BGM y ME no comparten player: el ME no mata la música del mapa.

const SFX_POOL_SIZE: int = 4
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

var _bgm: AudioStreamPlayer
var _me: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

var _ruta_actual: String = ""
var _duracion_total: float = 0.0
var _silencio_a_cortar: float = 0.0
var _bgm_pos_guardada: float = 0.0
var _bgm_pausada_por_me: bool = false


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "BGMPlayer"
	_bgm.bus = _resolver_bus(BUS_MUSIC)
	add_child(_bgm)

	_me = AudioStreamPlayer.new()
	_me.name = "MEPlayer"
	_me.bus = _resolver_bus(BUS_MUSIC)  # ME es jingle musical
	_me.finished.connect(_on_me_finished)
	add_child(_me)

	for i: int in range(SFX_POOL_SIZE):
		var se: AudioStreamPlayer = AudioStreamPlayer.new()
		se.name = "SFXPlayer_%d" % i
		se.bus = _resolver_bus(BUS_SFX)
		add_child(se)
		_sfx_players.append(se)


func _process(_delta: float) -> void:
	if _bgm.stream == null or _ruta_actual.is_empty():
		return
	if _silencio_a_cortar <= 0.0:
		return
	if not _bgm.playing:
		return
	var posicion: float = _bgm.get_playback_position()
	if posicion >= _duracion_total - _silencio_a_cortar - 0.02:
		_bgm.seek(0.0)


func reproducir(ruta: String, cortar_silencio: float = 0.0) -> void:
	if ruta == _ruta_actual and _bgm.playing:
		_silencio_a_cortar = maxf(cortar_silencio, 0.0)
		return
	if ruta.is_empty():
		detener()
		return
	if not ResourceLoader.exists(ruta):
		push_warning("MusicManager: no existe: %s" % ruta)
		return
	var nueva: AudioStream = load(ruta) as AudioStream
	if nueva == null:
		return
	_bgm_pausada_por_me = false
	_ruta_actual = ruta
	_duracion_total = nueva.get_length()
	_silencio_a_cortar = maxf(cortar_silencio, 0.0)
	_bgm.stream = nueva
	_bgm.volume_db = 0.0
	_bgm.play()


func detener() -> void:
	_bgm.stop()
	_bgm.stream = null
	_ruta_actual = ""
	_duracion_total = 0.0
	_silencio_a_cortar = 0.0
	_bgm_pausada_por_me = false


func reproducir_mapa(id: SFXGame.MapMusicID) -> void:
	if id == SFXGame.MapMusicID.BGM_NONE:
		detener()
		return
	reproducir(SFXGame.map_music_path(id), SFXGame.DEFAULT_TRIM_END)


func reproducir_batalla(id: SFXGame.BattleMusicID) -> void:
	reproducir(SFXGame.battle_music_path(id), SFXGame.DEFAULT_TRIM_END)


## ME: no usa el player de BGM; al terminar reanuda el mapa.
func reproducir_efecto_musical(id: SFXGame.MusicEffectID) -> void:
	var ruta: String = SFXGame.music_effect_path(id)
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		push_warning("MusicManager: ME inexistente")
		return
	var stream: AudioStream = load(ruta) as AudioStream
	if stream == null:
		return
	# Pausar BGM sin olvidar la pista
	if _bgm.playing:
		_bgm_pos_guardada = _bgm.get_playback_position()
		_bgm.stop()
		_bgm_pausada_por_me = true
	_me.stream = stream
	_me.volume_db = 0.0
	_me.play()


func _on_me_finished() -> void:
	if not _bgm_pausada_por_me:
		return
	_bgm_pausada_por_me = false
	if _bgm.stream == null or _ruta_actual.is_empty():
		return
	_bgm.play(_bgm_pos_guardada)


func reproducir_se(id: SFXGame.SoundEffectID) -> void:
	var ruta: String = SFXGame.sound_effect_path(id)
	if not SFXGame.path_exists(ruta):
		return
	var stream: AudioStream = load(ruta) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_libre()
	player.stream = stream
	player.play()


func _sfx_libre() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]


func esta_sonando() -> bool:
	return _bgm.playing


func ruta_actual() -> String:
	return _ruta_actual


func _resolver_bus(preferido: StringName) -> StringName:
	if AudioServer.get_bus_index(preferido) >= 0:
		return preferido
	# No mezclar Music/SFX en Master en silencio: avisar
	push_warning("MusicManager: falta bus '%s' → Master. Crea buses Music y SFX." % preferido)
	return &"Master"
