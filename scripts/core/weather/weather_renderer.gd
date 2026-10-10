extends CanvasLayer
## Render visual del clima de overworld (estilo Pokémon Essentials).
##
## Autoload: WeatherRenderer
## Partículas: entran por arriba/derecha, salen por abajo/izquierda.
## Lluvia: índices pares = gota, impares = splash (último bitmap).

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
	# Essentials: (power + 1) * MAX_SPRITES / 10
	return clampi(int((intensity + 1) * MAX_PARTICLES / 10), 0, MAX_PARTICLES)


# ============================================================
# TONE
# ============================================================

func _setup_tone() -> void:
	if _active_data == null or _active_data.id == WeatherID.Id.NONE:
		_tone_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		_base_tone_alpha = 0.0
		return
	var t: Color = _active_data.tone
	var strength: float = float(WeatherManager.get_current_intensity()) / 9.0
	_base_tone_alpha = clampf(absf(t.a) * strength, 0.0, 0.55)
	# ColorRect mezcla; valores negativos de tone se interpretan como oscurecer
	var r: float = clampf(0.5 + t.r * 0.5, 0.0, 1.0)
	var g: float = clampf(0.5 + t.g * 0.5, 0.0, 1.0)
	var b: float = clampf(0.5 + t.b * 0.5, 0.0, 1.0)
	_tone_rect.color = Color(r, g, b, _base_tone_alpha)


# ============================================================
# PARTÍCULAS
# ============================================================

func _ensure_particle_pool() -> void:
	while _particles.size() < MAX_PARTICLES:
		var s: Sprite2D = Sprite2D.new()
		s.visible = false
		s.centered = false
		_particle_root.add_child(s)
		_particles.append(s)
		_lifetimes.append(0.0)


func _setup_particles() -> void:
	_ensure_particle_pool()
	for i: int in range(MAX_PARTICLES):
		_assign_particle_texture(i)
		if i < _active_max and _has_particles():
			_reset_particle(i)
		else:
			_particles[i].visible = false
			_lifetimes[i] = 0.0


func _has_particles() -> bool:
	return _active_data != null and not _active_data.particle_textures.is_empty()


func _is_rain_category() -> bool:
	return _active_data != null and _active_data.category == WeatherData.Category.RAIN


func _is_splash_index(index: int) -> bool:
	# Essentials: Rain + índice impar → splash (último bitmap)
	return _is_rain_category() and index % 2 == 1 and _active_data.particle_textures.size() >= 2


func _refresh_particle_visibility() -> void:
	for i: int in range(MAX_PARTICLES):
		if i < _active_max and _has_particles():
			if not _particles[i].visible:
				_reset_particle(i)
		else:
			_particles[i].visible = false
			_lifetimes[i] = 0.0


func _assign_particle_texture(index: int) -> void:
	var s: Sprite2D = _particles[index]
	if not _has_particles():
		s.texture = null
		return
	var textures: Array[Texture2D] = _active_data.particle_textures
	if _is_splash_index(index):
		# Último bitmap = splash (como Essentials)
		s.texture = textures[textures.size() - 1]
	elif _is_rain_category() and textures.size() >= 2:
		# Gotas: todos menos el último
		var drop_count: int = textures.size() - 1
		s.texture = textures[index % drop_count]
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
	var tw: float = float(s.texture.get_width())
	var th: float = float(s.texture.get_height())
	var w: float = _viewport_size.x
	var h: float = _viewport_size.y

	# --- Splash (lluvia, índice impar) ---
	if _is_splash_index(index):
		s.position = Vector2(
			randf_range(-tw, w + tw),
			randf_range(-th, h + th)
		)
		_lifetimes[index] = randf_range(0.3, 0.5)
		return

	var pdelta: Vector2 = _active_data.particle_delta
	var x_speed: float = pdelta.x
	var y_speed: float = pdelta.y
	var gradient: float = 0.0
	if absf(y_speed) > 0.001:
		gradient = x_speed / y_speed

	if absf(gradient) >= 1.0:
		# Entra por la derecha (Essentials)
		s.position.x = w + randf() * w
		var denom: float = gradient if absf(gradient) > 0.001 else 1.0
		s.position.y = h - randf() * (h + th - w / denom)
		var distance: float = s.position.x - w * 0.5 + tw + randf() * w * 1.6
		_lifetimes[index] = absf(distance / x_speed) if absf(x_speed) > 0.001 else 2.0
	else:
		# Entra por arriba (Essentials)
		s.position.x = -tw + randf() * (w + tw - gradient * h)
		s.position.y = -th - randf() * h
		var distance_y: float = -s.position.y + h * 0.5 + randf() * h * 1.6
		_lifetimes[index] = absf(distance_y / y_speed) if absf(y_speed) > 0.001 else 2.0


func _update_particles(delta: float) -> void:
	if not _has_particles():
		return
	var pdelta: Vector2 = _active_data.particle_delta
	var op_delta: float = _active_data.particle_opacity_delta  # escala 0–255 / s (Essentials)

	for i: int in range(_active_max):
		var s: Sprite2D = _particles[i]
		if not s.visible or s.texture == null:
			continue

		_lifetimes[i] -= delta
		if _lifetimes[i] <= 0.0:
			_reset_particle(i)
			continue

		# Splash: visible solo los últimos 0.2 s
		if _is_splash_index(i):
			s.modulate.a = 1.0 if _lifetimes[i] < 0.2 else 0.0
			continue

		var dist: Vector2 = pdelta * delta
		s.position += dist

		# Drift extra (Snow / Blizzard) — como Essentials
		if _active_data.id == WeatherID.Id.SNOW or _active_data.id == WeatherID.Id.BLIZZARD:
			s.position.x += dist.x * (s.position.y / (_viewport_size.y * 3.0))
			s.position.x += float([2, 1, 0, -1][randi() % 4]) * dist.x / 8.0
			s.position.y += float([2, 1, 1, 0, 0, -1][i % 6]) * dist.y / 10.0

		# Opacidad (Essentials trabaja en 0–255)
		if op_delta != 0.0:
			s.modulate.a = clampf(s.modulate.a + (op_delta * delta) / 255.0, 0.0, 1.0)

		var tw: float = float(s.texture.get_width())
		# Reset solo si sale por izquierda o abajo, o muy transparente
		if s.modulate.a < 0.25 \
				or s.position.x < -tw \
				or s.position.y > _viewport_size.y:
			_reset_particle(i)


# ============================================================
# TILES (fog / sand / blizzard)
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

	var show: bool = WeatherManager.get_current_intensity() > 0
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

	var show: bool = WeatherManager.get_current_intensity() > 0
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
	if WeatherManager.get_current_intensity() <= 0:
		return
	_time_until_flash -= delta
	if _time_until_flash > 0.0:
		return
	var flash: Tween = create_tween()
	flash.tween_property(_tone_rect, "color:a", 0.75, 0.05)
	flash.tween_property(_tone_rect, "color:a", _base_tone_alpha, 0.2)
	_time_until_flash = randf_range(0.5, 6.0)
