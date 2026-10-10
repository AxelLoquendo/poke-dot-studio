extends Node
## Estado global del clima de overworld.
##
## Autoload: WeatherManager
## No dibuja nada. Solo mantiene tipo/intensidad y notifica cambios.

signal weather_changed(old_id: WeatherID.Id, new_id: WeatherID.Id)
signal weather_intensity_changed(old_value: int, new_value: int)

var _current_id: WeatherID.Id = WeatherID.Id.NONE
var _current_intensity: int = 0
var _target_id: WeatherID.Id = WeatherID.Id.NONE
var _target_intensity: int = 0
var _is_transitioning: bool = false


func get_current_id() -> WeatherID.Id:
	return _current_id


func get_current_intensity() -> int:
	return _current_intensity


func get_current_data() -> WeatherData:
	return WeatherCatalog.get_data(_current_id)


func is_transitioning() -> bool:
	return _is_transitioning


func set_weather(id: WeatherID.Id, intensity: int = 0, fade: bool = true) -> void:
	intensity = clampi(intensity, 0, 9)
	if id == WeatherID.Id.NONE:
		intensity = 0

	if id == _current_id and intensity == _current_intensity and not _is_transitioning:
		return

	var old_id: WeatherID.Id = _current_id
	var old_intensity: int = _current_intensity

	# Aplicar estado lógico YA, para que el renderer lea valores correctos
	_current_id = id
	_current_intensity = intensity
	_target_id = id
	_target_intensity = intensity

	if fade and old_id != id:
		_is_transitioning = true
	else:
		_is_transitioning = false

	weather_changed.emit(old_id, id)
	if old_intensity != intensity:
		weather_intensity_changed.emit(old_intensity, intensity)


func clear_weather(fade: bool = true) -> void:
	set_weather(WeatherID.Id.NONE, 0, fade)


func notify_transition_finished() -> void:
	_is_transitioning = false
	_target_id = _current_id
	_target_intensity = _current_intensity
