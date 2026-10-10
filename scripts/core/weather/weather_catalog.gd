class_name WeatherCatalog
extends Object
## Catálogo de climas. Fuente única de verdad para WeatherData.

static var _cache: Dictionary = {}   ## WeatherID.Id → WeatherData


static func get_data(id: WeatherID.Id) -> WeatherData:
	if _cache.has(id):
		return _cache[id] as WeatherData
	var data: WeatherData = _build(id)
	_cache[id] = data
	return data


static func _build(id: WeatherID.Id) -> WeatherData:
	var data: WeatherData = WeatherData.new()
	data.id = id

	match id:
		WeatherID.Id.NONE:
			data.category = WeatherData.Category.NONE

		WeatherID.Id.RAIN:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-120.0, 480.0)
			data.particle_opacity_delta = -40.0
			data.max_particles = 40
			data.tone = Color(-0.05, -0.05, 0.0, 0.15)

		WeatherID.Id.HEAVY_RAIN:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-160.0, 640.0)
			data.particle_opacity_delta = -50.0
			data.max_particles = 55
			data.tone = Color(-0.08, -0.08, 0.0, 0.25)

		WeatherID.Id.STORM:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-180.0, 720.0)
			data.particle_opacity_delta = -60.0
			data.max_particles = 60
			data.tone = Color(-0.1, -0.1, 0.0, 0.35)
			data.has_lightning = true

		WeatherID.Id.SNOW:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-20.0, 80.0)
			data.particle_opacity_delta = -15.0
			data.max_particles = 35
			data.tone = Color(0.05, 0.05, 0.1, 0.1)

		WeatherID.Id.BLIZZARD:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-200.0, 120.0)
			data.particle_opacity_delta = -25.0
			data.max_particles = 50
			data.tone = Color(0.08, 0.08, 0.12, 0.3)
			# tile_delta se rellena cuando haya texturas

		WeatherID.Id.SANDSTORM:
			data.category = WeatherData.Category.SAND
			data.particle_delta = Vector2(-280.0, 40.0)
			data.max_particles = 45
			data.tone = Color(0.15, 0.08, -0.05, 0.25)

		WeatherID.Id.FOG:
			data.category = WeatherData.Category.FOG
			data.tone = Color(0.1, 0.1, 0.12, 0.4)
			# principalmente tiles

		WeatherID.Id.HAIL:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-40.0, 360.0)
			data.particle_opacity_delta = -30.0
			data.max_particles = 40
			data.tone = Color(0.05, 0.05, 0.1, 0.2)

		WeatherID.Id.SUN:
			data.category = WeatherData.Category.SUN
			data.tone = Color(0.12, 0.08, -0.02, 0.0)

	return data
