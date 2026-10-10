extends Node
## Reproducción global de BGM y efectos de sonido (SE).
##
## Autoload: MusicManager
## Catálogo de rutas: SFXGame
## BGM y SE usan players distintos (la música no se corta al bump).

const SFX_POOL_SIZE: int = 4
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

var _reproductor: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

var _ruta_actual: String = ""
var _duracion_total: float = 0.0
var _silencio_a_cortar: float = 0.0


func _ready() -> void:
	_reproductor = AudioStreamPlayer.new()
	_reproductor.name = "BGMPlayer"
	_reproductor.bus = _resolver_bus(BUS_MUSIC)
	add_child(_reproductor)

	for i: int in range(SFX_POOL_SIZE):
		var se: AudioStreamPlayer = AudioStreamPlayer.new()
		se.name = "SFXPlayer_%d" % i
		se.bus = _resolver_bus(BUS_SFX)
		add_child(se)
		_sfx_players.append(se)


func _process(_delta: float) -> void:
	if _reproductor.stream == null:
		return
	if _ruta_actual.is_empty():
		return
	if _silencio_a_cortar <= 0.0:
		return
	var posicion: float = _reproductor.get_playback_position()
	if posicion >= _duracion_total - _silencio_a_cortar - 0.02:
		_reproductor.seek(0.0)


# ============================================================
# BGM
# ============================================================

func reproducir(ruta: String, cortar_silencio: float = 0.0) -> void:
	if ruta == _ruta_actual:
		_silencio_a_cortar = maxf(cortar_silencio, 0.0)
		return
	if ruta.is_empty():
		detener()
		return
	if not ResourceLoader.exists(ruta):
		push_warning("MusicManager: no existe el recurso: %s" % ruta)
		return
	var nueva: AudioStream = load(ruta) as AudioStream
	if nueva == null:
		push_warning("MusicManager: no se pudo cargar el recurso: %s" % ruta)
		return
	_ruta_actual = ruta
	_duracion_total = nueva.get_length()
	_silencio_a_cortar = maxf(cortar_silencio, 0.0)
	_reproductor.stream = nueva
	_reproductor.volume_db = 0.0
	_reproductor.play()


func detener() -> void:
	_reproductor.stop()
	_reproductor.stream = null
	_reproductor.volume_db = 0.0
	_ruta_actual = ""
	_duracion_total = 0.0
	_silencio_a_cortar = 0.0


func reproducir_mapa(id: SFXGame.MapMusicID) -> void:
	if id == SFXGame.MapMusicID.BGM_NONE:
		detener()
		return
	reproducir(SFXGame.map_music_path(id), SFXGame.DEFAULT_TRIM_END)


func reproducir_batalla(id: SFXGame.BattleMusicID) -> void:
	reproducir(SFXGame.battle_music_path(id), SFXGame.DEFAULT_TRIM_END)


func reproducir_efecto_musical(id: SFXGame.MusicEffectID) -> void:
	reproducir(SFXGame.music_effect_path(id), 0.0)


# ============================================================
# SFX (efectos de sonido)
# ============================================================

func reproducir_se(id: SFXGame.SoundEffectID) -> void:
	var ruta: String = SFXGame.sound_effect_path(id)
	if not SFXGame.path_exists(ruta):
		push_warning("MusicManager: SE inexistente id=%s ruta=%s" % [str(id), ruta])
		return
	var stream: AudioStream = load(ruta) as AudioStream
	if stream == null:
		push_warning("MusicManager: no se pudo cargar SE: %s" % ruta)
		return
	var player: AudioStreamPlayer = _sfx_libre()
	player.stream = stream
	player.play()


func _sfx_libre() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]


# ============================================================
# ESTADO BGM
# ============================================================

func esta_sonando() -> bool:
	return _reproductor.playing


func ruta_actual() -> String:
	return _ruta_actual


func _resolver_bus(preferido: StringName) -> StringName:
	if AudioServer.get_bus_index(preferido) >= 0:
		return preferido
	return &"Master"
