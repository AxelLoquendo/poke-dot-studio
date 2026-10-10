extends CanvasLayer
## Render visual del clima de overworld (partículas, tiles, tone).
##
## Autoload: WeatherRenderer
## No decide qué clima hay; solo reacciona a WeatherManager.

const MAX_PARTICLES: int = 60
const LAYER_INDEX: int = 90

var _tone_rect: ColorRect
var _particle_root: Node2D
var _tile_root: Node2D

var _particles: Array[Sprite2D] = []
var _lifetimes: Array[float] = []
var _tiles: Array[Sprite2D] = []

var _active_data: WeatherData
var _active_max: int = 0
var _tile_x: float = 0.0
var _tile_y: float = 0.0
var _tiles_wide: int = 0
var _tiles_tall: int = 0

var _time_until_flash: float = 0.0
var _base_tone_alpha: float = 0.0
var _viewport_size: Vector2 = Vector2(512.0, 384.0)


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	_viewport_size = get_viewport().get_visible_rect().size

	_tone_rect = ColorRect.new()
	_tone_rect.name = "WeatherTone"
	_tone_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tone_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tone_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(_tone_rect)

	_particle_root = Node2D.new()
	_particle_root.name = "Particles"
	add_child(_particle_root)

	_tile_root = Node2D.new()
	_tile_root.name = "Tiles"
	add_child(_tile_root)

	_ensure_particle_pool()

	WeatherManager.weather_changed.connect(_on_weather_changed)
	WeatherManager.weather_intensity_changed.connect(_on_intensity_changed)
	_apply_weather(WeatherManager.get_current_id(), WeatherManager.get_current_intensity())


func _process(delta: float) -> void:
	if _active_data == null or _active_data.id == WeatherID.Id.NONE:
		return
	_update_particles(delta)
	_update_tiles(delta)
	_update_lightning(delta)


# ============================================================
# CAMBIO DE CLIMA
# ============================================================

func _on_weather_changed(_old_id: WeatherID.Id, new_id: WeatherID.Id) -> void:
	_apply_weather(new_id, WeatherManager.get_current_intensity())
	if WeatherManager.is_transitioning():
		WeatherManager.notify_transition_finished()


func _on_intensity_changed(_old_v: int, new_v: int) -> void:
	_active_max = _intensity_to_max(new_v, _active_data)
	_setup_tone()
	_refresh_particle_visibility()


func _apply_weather(id: WeatherID.Id, intensity: int) -> void:
	_active_data = WeatherCatalog.get_data(id)
	_active_max = _intensity_to_max(intensity, _active_data)
	_tile_x = 0.0
	_tile_y = 0.0
	_time_until_flash = 0.0
	_setup_tone()
	_setup_particles()
	_setup_tiles()


func _intensity_to_max(intensity: int, data: WeatherData) -> int:
	if data == null or data.id == WeatherID.Id.NONE:
		return 0
	if data.max_particles <= 0:
		return 0
	return int(round(float(data.max_particles) * float(intensity) / 9.0))


# ============================================================
# TONE
# ============================================================

func _setup_tone() -> void:
	if _active_data == null or _active_data.id == WeatherID.Id.NONE:
		_tone_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		_base_tone_alpha = 0.0
		return
	var t: Color = _active_data.tone
	var strength: float = 1.0
	if _active_data.max_particles > 0:
		strength = float(_active_max) / float(_active_data.max_particles)
	elif _active_data.tile_textures.size() > 0:
		strength = float(WeatherManager.get_current_intensity()) / 9.0
	_base_tone_alpha = clampf(t.a * strength, 0.0, 0.6)
	_tone_rect.color = Color(t.r, t.g, t.b, _base_tone_alpha)


# ============================================================
# PARTÍCULAS
# ============================================================

func _ensure_particle_pool() -> void:
	while _particles.size() < MAX_PARTICLES:
		var s: Sprite2D = Sprite2D.new()
		s.visible = false
		s.centered = true
		_particle_root.add_child(s)
		_particles.append(s)
		_lifetimes.append(0.0)


func _setup_particles() -> void:
	_ensure_particle_pool()
	for i: int in range(MAX_PARTICLES):
		_assign_particle_texture(i)
		if i < _active_max:
			_reset_particle(i)
		else:
			_particles[i].visible = false
			_lifetimes[i] = 0.0


func _refresh_particle_visibility() -> void:
	for i: int in range(MAX_PARTICLES):
		if i < _active_max:
			if not _particles[i].visible:
				_reset_particle(i)
		else:
			_particles[i].visible = false
			_lifetimes[i] = 0.0


func _assign_particle_texture(index: int) -> void:
	var s: Sprite2D = _particles[index]
	if _active_data == null or _active_data.particle_textures.is_empty():
		s.texture = null
		return
	var textures: Array[Texture2D] = _active_data.particle_textures
	if _active_data.category == WeatherData.Category.RAIN and _active_data.splash_texture != null:
		if index % 2 == 1:
			s.texture = _active_data.splash_texture
		else:
			s.texture = textures[index % textures.size()]
	else:
		s.texture = textures[index % textures.size()]


func _reset_particle(index: int) -> void:
	var s: Sprite2D = _particles[index]
	if s.texture == null or index >= _active_max:
		s.visible = false
		_lifetimes[index] = 0.0
		return

	s.visible = true
	s.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var pdelta: Vector2 = _active_data.particle_delta
	var tw: float = float(s.texture.get_width())
	var th: float = float(s.texture.get_height())

	# Splash de lluvia
	if _active_data.category == WeatherData.Category.RAIN \
			and index % 2 == 1 \
			and _active_data.splash_texture != null:
		s.position = Vector2(
			randf_range(-tw, _viewport_size.x + tw),
			randf_range(-th, _viewport_size.y + th)
		)
		_lifetimes[index] = randf_range(0.3, 0.5)
		return

	var gradient: float = 0.0
	if absf(pdelta.y) > 0.001:
		gradient = pdelta.x / pdelta.y

	if absf(gradient) >= 1.0:
		s.position.x = _viewport_size.x + randf() * _viewport_size.x
		s.position.y = randf_range(0.0, _viewport_size.y + th)
		var distance: float = s.position.x + tw + randf() * _viewport_size.x * 1.6
		_lifetimes[index] = absf(distance / pdelta.x) if absf(pdelta.x) > 0.001 else 2.0
	else:
		s.position.x = randf_range(-tw, _viewport_size.x + tw)
		s.position.y = -th - randf() * _viewport_size.y
		var distance_y: float = _viewport_size.y * 0.5 + th + randf() * _viewport_size.y * 1.6
		_lifetimes[index] = absf(distance_y / pdelta.y) if absf(pdelta.y) > 0.001 else 2.0


func _update_particles(delta: float) -> void:
	if _active_data == null:
		return
	var pdelta: Vector2 = _active_data.particle_delta
	var op_delta: float = _active_data.particle_opacity_delta

	for i: int in range(_active_max):
		var s: Sprite2D = _particles[i]
		if not s.visible or s.texture == null:
			continue

		_lifetimes[i] -= delta
		if _lifetimes[i] <= 0.0:
			_reset_particle(i)
			continue

		if _active_data.category == WeatherData.Category.RAIN \
				and i % 2 == 1 \
				and _active_data.splash_texture != null:
			s.modulate.a = 1.0 if _lifetimes[i] < 0.2 else 0.0
			continue

		s.position += pdelta * delta

		if _active_data.id == WeatherID.Id.SNOW or _active_data.id == WeatherID.Id.BLIZZARD:
			s.position.x += pdelta.x * (s.position.y / (_viewport_size.y * 3.0)) * delta
			s.position.x += float([2, 1, 0, -1][randi() % 4]) * pdelta.x / 8.0 * delta

		if op_delta != 0.0:
			s.modulate.a = clampf(s.modulate.a + op_delta * delta / 255.0, 0.0, 1.0)

		if s.modulate.a < 0.25 \
				or s.position.x < -float(s.texture.get_width()) \
				or s.position.y > _viewport_size.y + float(s.texture.get_height()):
			_reset_particle(i)


# ============================================================
# TILES
# ============================================================

func _setup_tiles() -> void:
	for t: Sprite2D in _tiles:
		t.queue_free()
	_tiles.clear()
	_tiles_wide = 0
	_tiles_tall = 0

	if _active_data == null or _active_data.tile_textures.is_empty():
		return

	var tex: Texture2D = _active_data.tile_textures[0]
	if tex == null:
		return
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return

	_tiles_wide = int(ceil(_viewport_size.x / tw)) + 2
	_tiles_tall = int(ceil(_viewport_size.y / th)) + 2

	var show: bool = _active_max > 0 or WeatherManager.get_current_intensity() > 0
	for i: int in range(_tiles_wide * _tiles_tall):
		var s: Sprite2D = Sprite2D.new()
		s.texture = _active_data.tile_textures[i % _active_data.tile_textures.size()]
		s.centered = false
		s.modulate.a = 1.0 if show else 0.0
		_tile_root.add_child(s)
		_tiles.append(s)


func _update_tiles(delta: float) -> void:
	if _tiles_wide <= 0 or _active_data == null or _active_data.tile_textures.is_empty():
		return
	var tex: Texture2D = _active_data.tile_textures[0]
	if tex == null:
		return
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	var tdelta: Vector2 = _active_data.tile_delta

	_tile_x += tdelta.x * delta
	_tile_y += tdelta.y * delta

	while _tile_x < -tw:
		_tile_x += tw
	while _tile_x > 0.0:
		_tile_x -= tw
	while _tile_y < -th:
		_tile_y += th
	while _tile_y > 0.0:
		_tile_y -= th

	var show: bool = _active_max > 0 or WeatherManager.get_current_intensity() > 0
	for i: int in range(_tiles.size()):
		var col: int = i % _tiles_wide
		var row: int = int(i / _tiles_wide)
		_tiles[i].position = Vector2(_tile_x + float(col) * tw, _tile_y + float(row) * th)
		_tiles[i].modulate.a = 1.0 if show else 0.0


# ============================================================
# RAYOS (Storm)
# ============================================================

func _update_lightning(delta: float) -> void:
	if _active_data == null or not _active_data.has_lightning:
		return
	_time_until_flash -= delta
	if _time_until_flash > 0.0:
		return
	var flash: Tween = create_tween()
	flash.tween_property(_tone_rect, "color:a", 0.75, 0.05)
	flash.tween_property(_tone_rect, "color:a", _base_tone_alpha, 0.2)
	_time_until_flash = randf_range(0.5, 6.0)
