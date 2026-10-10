@tool
extends ScriptCommand
class_name ScriptCmdWeather
@export var weather_name: String = "none"
@export var intensity: int = 5
func execute(_context: ScriptExecutionContext) -> bool:
	var id: WeatherID.Id = _parse(weather_name)
	WeatherManager.set_weather(id, intensity if id != WeatherID.Id.NONE else 0, true)
	return true
func _parse(value: String) -> WeatherID.Id:
	match value.to_lower():
		"rain", "lluvia": return WeatherID.Id.RAIN
		"storm", "tormenta": return WeatherID.Id.STORM
		"snow", "nieve": return WeatherID.Id.SNOW
		"blizzard": return WeatherID.Id.BLIZZARD
		"sandstorm", "arena": return WeatherID.Id.SANDSTORM
		"fog", "niebla": return WeatherID.Id.FOG
		"sun", "sol": return WeatherID.Id.SUN
		"heavy_rain", "heavyrain": return WeatherID.Id.HEAVY_RAIN
		_: return WeatherID.Id.NONE
