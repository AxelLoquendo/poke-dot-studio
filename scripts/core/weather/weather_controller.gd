extends Node
class_name MapWeatherController
## Lee MapAttributes.weather y notifica a WeatherManager.
## Solo aplica si el mapa padre es el current.

const DEFAULT_INTENSITY: int = 5


func on_map_attributes_ready(map: Map) -> void:
	if map == null or map.attributes == null:
		return
	# En cluster: vecinos también hacen ready; no deben tocar el clima global
	if not map.is_current:
		return
	_aplicar(map.attributes)


func activar() -> void:
	var map: Map = get_parent() as Map
	if map == null or map.attributes == null:
		return
	_aplicar(map.attributes)


func _aplicar(attributes: MapAttributes) -> void:
	var intensity: int = attributes.weather_intensity
	if attributes.weather != WeatherID.Id.NONE and intensity <= 0:
		intensity = DEFAULT_INTENSITY
	WeatherManager.set_weather(attributes.weather, intensity, true)
