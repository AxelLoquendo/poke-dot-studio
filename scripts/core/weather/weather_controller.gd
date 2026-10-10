extends Node
class_name MapWeatherController
## Lee MapAttributes.weather y notifica a WeatherManager.
## No dibuja ni gestiona partículas.

func on_map_attributes_ready(map: Map) -> void:
	if map == null or map.attributes == null:
		return
	_aplicar(map.attributes)


func activar() -> void:
	var map: Map = get_parent() as Map
	if map == null or map.attributes == null:
		return
	_aplicar(map.attributes)


func _aplicar(attributes: MapAttributes) -> void:
	WeatherManager.set_weather(
		attributes.weather,
		attributes.weather_intensity,
		true
	)
