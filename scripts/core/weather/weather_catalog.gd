class_name WeatherCatalog
extends Object
## Catálogo de climas. Fuente única de verdad para WeatherData.

const BASE_PATH: String = "res://assets/weather/"

static var _cache: Dictionary = {}


static func get_data(id: WeatherID.Id) -> WeatherData:
	if _cache.has(id):
		return _cache[id] as WeatherData
	var data: WeatherData = _build(id)
	_cache[id] = data
	return data


static func _load_tex(name: String) -> Texture2D:
	var path: String = BASE_PATH + name
	if not ResourceLoader.exists(path):
		push_warning("WeatherCatalog: no existe %s" % path)
		return null
	return load(path) as Texture2D


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
			data.particle_textures = [
				_load_tex("rain_1.png"),
				_load_tex("rain_2.png"),
				_load_tex("rain_3.png"),
				_load_tex("rain_4.png"),
			]

		WeatherID.Id.HEAVY_RAIN:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-160.0, 640.0)
			data.particle_opacity_delta = -50.0
			data.max_particles = 55
			data.tone = Color(-0.08, -0.08, 0.0, 0.25)
			data.particle_textures = [
				_load_tex("rain_1.png"),
				_load_tex("rain_2.png"),
				_load_tex("rain_3.png"),
				_load_tex("rain_4.png"),
			]

		WeatherID.Id.STORM:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-180.0, 720.0)
			data.particle_opacity_delta = -60.0
			data.max_particles = 60
			data.tone = Color(-0.1, -0.1, 0.0, 0.35)
			data.has_lightning = true
			data.particle_textures = [
				_load_tex("storm_1.png"),
				_load_tex("storm_2.png"),
				_load_tex("storm_3.png"),
				_load_tex("storm_4.png"),
			]

		WeatherID.Id.SNOW:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-20.0, 80.0)
			data.particle_opacity_delta = -15.0
			data.max_particles = 35
			data.tone = Color(0.05, 0.05, 0.1, 0.1)
			data.particle_textures = [
				_load_tex("blizzard_1.png"),
				_load_tex("blizzard_2.png"),
			]

		WeatherID.Id.BLIZZARD:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-200.0, 120.0)
			data.particle_opacity_delta = -25.0
			data.max_particles = 50
			data.tone = Color(0.08, 0.08, 0.12, 0.3)
			data.tile_delta = Vector2(-120.0, 40.0)
			data.particle_textures = [
				_load_tex("blizzard_1.png"),
				_load_tex("blizzard_2.png"),
				_load_tex("blizzard_3.png"),
				_load_tex("blizzard_4.png"),
			]
			data.tile_textures = [
				_load_tex("blizzard_tile.png"),
			]

		WeatherID.Id.SANDSTORM:
			data.category = WeatherData.Category.SAND
			data.particle_delta = Vector2(-280.0, 40.0)
			data.particle_opacity_delta = -20.0
			data.max_particles = 45
			data.tone = Color(0.15, 0.08, -0.05, 0.25)
			data.tile_delta = Vector2(-180.0, 20.0)
			data.particle_textures = [
				_load_tex("sandstorm_1.png"),
				_load_tex("sandstorm_2.png"),
				_load_tex("sandstorm_3.png"),
				_load_tex("sandstorm_4.png"),
			]
			data.tile_textures = [
				_load_tex("sandstorm_tile.png"),
			]

		WeatherID.Id.FOG:
			data.category = WeatherData.Category.FOG
			data.tone = Color(0.1, 0.1, 0.12, 0.4)
			data.tile_delta = Vector2(-30.0, 0.0)
			data.max_particles = 0
			data.tile_textures = [
				_load_tex("fog_tile.png"),
				_load_tex("fog_tile_2.png"),
			]

		WeatherID.Id.HAIL:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-40.0, 360.0)
			data.particle_opacity_delta = -30.0
			data.max_particles = 40
			data.tone = Color(0.05, 0.05, 0.1, 0.2)
			data.particle_textures = [
				_load_tex("hail_1.png"),
				_load_tex("hail_2.png"),
				_load_tex("hail_3.png"),
			]

		WeatherID.Id.SUN:
			data.category = WeatherData.Category.SUN
			data.tone = Color(0.12, 0.08, -0.02, 0.15)
			data.max_particles = 0

	# Filtrar texturas nulas por si falta algún archivo
	var clean_particles: Array[Texture2D] = []
	for t: Texture2D in data.particle_textures:
		if t != null:
			clean_particles.append(t)
	data.particle_textures = clean_particles

	var clean_tiles: Array[Texture2D] = []
	for t: Texture2D in data.tile_textures:
		if t != null:
			clean_tiles.append(t)
	data.tile_textures = clean_tiles

	return data
