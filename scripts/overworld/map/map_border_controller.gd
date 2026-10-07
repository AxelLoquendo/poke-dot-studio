class_name MapBorderController
extends Node

const TILE_SIZE: float = 16.0
const MARGEN_CELDAS: int = 2
const PATTERN_SIZE: int = 2

@export var border_layer_path: NodePath = NodePath("../Behaviour/Borde")
@export var pattern_origin: Vector2i = Vector2i.ZERO

var _mapa: Map
var _layer: TileMapLayer
var _pattern: Array = []
var _activo: bool = false

## Rects locales (celdas) de mapas conectados: no pintar borde ahí
var _rects_conectados: Array[Rect2i] = []

## Evitar repintar si la cámara no cambió de rango de celdas
var _ultima_celda_min: Vector2i = Vector2i(2147483647, 2147483647)
var _ultima_celda_max: Vector2i = Vector2i(2147483647, 2147483647)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_mapa = get_parent() as Map
	if _mapa == null:
		push_warning("MapBorderController: el padre no es Map")
		return
	_layer = get_node_or_null(border_layer_path) as TileMapLayer
	if _layer == null:
		push_warning("MapBorderController: no se encontró layer de borde")
		return
	_resolver_patron()
	_reconstruir_rects_conectados()
	_activo = not _pattern.is_empty()


func on_map_attributes_ready(mapa: Map) -> void:
	_mapa = mapa
	if _layer != null:
		_resolver_patron()
		_reconstruir_rects_conectados()
		_activo = not _pattern.is_empty()
		# Forzar repintado tras reconstruir
		_ultima_celda_min = Vector2i(2147483647, 2147483647)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _activo:
		return
	_actualizar()


func _resolver_patron() -> void:
	_pattern.clear()
	if _layer == null:
		return
	for ly: int in range(PATTERN_SIZE):
		for lx: int in range(PATTERN_SIZE):
			var celda: Vector2i = pattern_origin + Vector2i(lx, ly)
			var source_id: int = _layer.get_cell_source_id(celda)
			if source_id == -1:
				push_warning(
					"MapBorderController: falta tile en el patrón 2x2 en celda %s" % str(celda)
				)
				_pattern.clear()
				return
			_pattern.append({
				"source_id": source_id,
				"atlas": _layer.get_cell_atlas_coords(celda),
				"alternative": _layer.get_cell_alternative_tile(celda),
			})


func _reconstruir_rects_conectados() -> void:
	_rects_conectados.clear()
	if _mapa == null or _mapa.attributes == null:
		return
	for entry: MapConnectionEntry in _mapa.attributes.connections:
		if entry == null or entry.target_map == MapSection.MapID.NONE:
			continue
		# UNA sola vez por vecino, no por celda/frame
		var size_n: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_n.x <= 0 or size_n.y <= 0:
			continue
		var origin: Vector2i = MapConnectionResolver.tiles_neighbor_from_current(
			entry.side,
			entry.edge_offset,
			_mapa.attributes.map_size,
			size_n
		)
		_rects_conectados.append(Rect2i(origin, size_n))


func _tile_del_patron(celda: Vector2i) -> Dictionary:
	var mx: int = posmod(celda.x, PATTERN_SIZE)
	var my: int = posmod(celda.y, PATTERN_SIZE)
	return _pattern[my * PATTERN_SIZE + mx]


func _actualizar() -> void:
	if _mapa == null or _mapa.attributes == null:
		return
	var map_size: Vector2i = _mapa.attributes.map_size
	if map_size.x <= 0 or map_size.y <= 0:
		return
	var camara: Camera2D = get_viewport().get_camera_2d()
	if camara == null:
		return

	var rect_visible: Rect2 = _rect_visible_en_mapa(camara)
	var celda_min: Vector2i = Vector2i(
		floori(rect_visible.position.x / TILE_SIZE) - MARGEN_CELDAS,
		floori(rect_visible.position.y / TILE_SIZE) - MARGEN_CELDAS
	)
	var celda_max: Vector2i = Vector2i(
		ceili(rect_visible.end.x / TILE_SIZE) + MARGEN_CELDAS,
		ceili(rect_visible.end.y / TILE_SIZE) + MARGEN_CELDAS
	)

	if celda_min == _ultima_celda_min and celda_max == _ultima_celda_max:
		return
	_ultima_celda_min = celda_min
	_ultima_celda_max = celda_max

	for y: int in range(celda_min.y, celda_max.y):
		for x: int in range(celda_min.x, celda_max.x):
			var celda: Vector2i = Vector2i(x, y)

			if _dentro_del_mapa(celda, map_size):
				if _layer.get_cell_source_id(celda) != -1:
					_layer.erase_cell(celda)
				continue

			if _es_celda_de_mapa_conectado(celda):
				if _layer.get_cell_source_id(celda) != -1:
					_layer.erase_cell(celda)
				continue

			var tile: Dictionary = _tile_del_patron(celda)
			_layer.set_cell(
				celda,
				tile["source_id"] as int,
				tile["atlas"] as Vector2i,
				tile["alternative"] as int
			)


func _es_celda_de_mapa_conectado(celda: Vector2i) -> bool:
	for rect: Rect2i in _rects_conectados:
		if rect.has_point(celda):
			return true
	return false


func _dentro_del_mapa(celda: Vector2i, map_size: Vector2i) -> bool:
	return (
		celda.x >= 0
		and celda.y >= 0
		and celda.x < map_size.x
		and celda.y < map_size.y
	)


func _rect_visible_en_mapa(camara: Camera2D) -> Rect2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = (viewport_size / camara.zoom) * 0.5
	var centro_local: Vector2 = _mapa.to_local(camara.get_screen_center_position())
	return Rect2(centro_local - half, half * 2.0)
