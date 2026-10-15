extends Node
## Opciones persistentes (no son el save de partida).

const PATH: String = "user://settings.cfg"

enum TextSpeed { SLOW, MEDIUM, FAST }

var text_speed: TextSpeed = TextSpeed.MEDIUM
var bgm_volume: float = 1.0  # 0.0–1.0
var se_volume: float = 1.0


func _ready() -> void:
	load_settings()
	apply_audio()


func text_delay() -> float:
	match text_speed:
		TextSpeed.SLOW:
			return MessageConfig.TEXT_SPEED_SLOW
		TextSpeed.FAST:
			return MessageConfig.TEXT_SPEED_FAST
		_:
			return MessageConfig.TEXT_SPEED_MEDIUM


func apply_audio() -> void:
	_set_bus_volume(&"Music", bgm_volume)
	_set_bus_volume(&"SFX", se_volume)


func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		# No tocar Master como fallback de SFX/Music (se pisan entre sí)
		push_warning("GameSettings: bus '%s' no existe" % bus_name)
		return
	var v: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(v) if v > 0.001 else -80.0)

func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "bgm", bgm_volume)
	cfg.set_value("audio", "se", se_volume)
	cfg.set_value("text", "speed", int(text_speed))
	cfg.save(PATH)


func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	bgm_volume = float(cfg.get_value("audio", "bgm", 1.0))
	se_volume = float(cfg.get_value("audio", "se", 1.0))
	text_speed = int(cfg.get_value("text", "speed", int(TextSpeed.MEDIUM))) as TextSpeed
