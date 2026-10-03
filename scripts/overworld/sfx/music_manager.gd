extends Node
class_name MusicManager
## Sistema global de reproducción de música.
##
## Debe registrarse como Autoload.
## Utiliza un único AudioStreamPlayer para la BGM.
##
## SFXGame se encarga del catálogo.
## MusicManager se encarga de reproducirlo.

var _reproductor: AudioStreamPlayer

var _ruta_actual: String = ""
var _duracion_total: float = 0.0
var _silencio_a_cortar: float = 0.0

func _ready() -> void:
	_reproductor = AudioStreamPlayer.new()
	_reproductor.name = "BGMPlayer"
	_reproductor.bus = &"Music"
	add_child(_reproductor)

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
# REPRODUCCIÓN
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

# ============================================================
# API DE CATÁLOGO
# ============================================================
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
# ESTADO
# ============================================================
func esta_sonando() -> bool:
	return _reproductor.playing

func ruta_actual() -> String:
	return _ruta_actual
