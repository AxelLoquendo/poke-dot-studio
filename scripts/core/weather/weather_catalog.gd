class_name WeatherCatalog
extends Object
## Catálogo de climas. Valores de movimiento y graphics idénticos a Pokémon Essentials.

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

		# Essentials: Rain  particle (-600, 2400)  last graphic = splash
		WeatherID.Id.RAIN:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-600.0, 2400.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tone = Color(-0.5, -0.5, -0.5, 10.0 / 255.0)  # approx tone at full strength
			data.particle_textures = [
				_load_tex("rain_1.png"),
				_load_tex("rain_2.png"),
				_load_tex("rain_3.png"),
				_load_tex("rain_4.png"),  # splash
			]

		# Essentials: HeavyRain usa graphics de storm y mismos deltas
		WeatherID.Id.HEAVY_RAIN:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-3600.0, 3600.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tone = Color(-0.75, -0.75, -0.75, 10.0 / 255.0)
			data.particle_textures = [
				_load_tex("storm_1.png"),
				_load_tex("storm_2.png"),
				_load_tex("storm_3.png"),
				_load_tex("storm_4.png"),
			]

		# Essentials: Storm  (-3600, 3600) + lightning flash
		WeatherID.Id.STORM:
			data.category = WeatherData.Category.RAIN
			data.particle_delta = Vector2(-3600.0, 3600.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tone = Color(-0.75, -0.75, -0.75, 10.0 / 255.0)
			data.has_lightning = true
			data.particle_textures = [
				_load_tex("storm_1.png"),
				_load_tex("storm_2.png"),
				_load_tex("storm_3.png"),
				_load_tex("storm_4.png"),
			]

		# Essentials: Snow usa hail_1/2/3 y delta (-240, 240)
		WeatherID.Id.SNOW:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-240.0, 240.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tone = Color(0.5, 0.5, 0.5, 0.0)
			data.particle_textures = [
				_load_tex("hail_1.png"),
				_load_tex("hail_2.png"),
				_load_tex("hail_3.png"),
			]

		# Essentials: Blizzard particles + tile
		WeatherID.Id.BLIZZARD:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-720.0, 240.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tile_delta = Vector2(-1200.0, 600.0)
			data.tone = Color(0.75, 0.75, 0.75, 0.0)
			data.particle_textures = [
				_load_tex("blizzard_1.png"),
				_load_tex("blizzard_2.png"),
				_load_tex("blizzard_3.png"),
				_load_tex("blizzard_4.png"),
			]
			data.tile_textures = [
				_load_tex("blizzard_tile.png"),
			]

		# Essentials: Sandstorm
		WeatherID.Id.SANDSTORM:
			data.category = WeatherData.Category.SAND
			data.particle_delta = Vector2(-1200.0, 640.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tile_delta = Vector2(-800.0, 400.0)
			data.tone = Color(0.5, 0.0, -0.5, 0.0)
			data.particle_textures = [
				_load_tex("sandstorm_1.png"),
				_load_tex("sandstorm_2.png"),
				_load_tex("sandstorm_3.png"),
				_load_tex("sandstorm_4.png"),
			]
			data.tile_textures = [
				_load_tex("sandstorm_tile.png"),
			]

		# Essentials: Fog solo tile
		WeatherID.Id.FOG:
			data.category = WeatherData.Category.FOG
			data.max_particles = 0
			data.tile_delta = Vector2(-32.0, 0.0)
			data.tone = Color(0.0, 0.0, 0.0, 0.0)
			data.tile_textures = [
				_load_tex("fog_tile.png"),
			]

		# Hail propio (no está en PE overworld base; usamos hail + caída más vertical)
		WeatherID.Id.HAIL:
			data.category = WeatherData.Category.SNOW
			data.particle_delta = Vector2(-120.0, 720.0)
			data.particle_opacity_delta = 0.0
			data.max_particles = 60
			data.tone = Color(0.4, 0.4, 0.5, 0.0)
			data.particle_textures = [
				_load_tex("hail_1.png"),
				_load_tex("hail_2.png"),
				_load_tex("hail_3.png"),
			]

		# Essentials: Sun solo tone (pulsa en el renderer)
		WeatherID.Id.SUN:
			data.category = WeatherData.Category.SUN
			data.max_particles = 0
			data.tone = Color(64.0 / 255.0, 64.0 / 255.0, 32.0 / 255.0, 0.0)

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
