class_name MapBorderController
extends Node

const TILE_SIZE: float = 16.0
const MARGEN_CELDAS: int = 2
const PATTERN_SIZE: int = 2  # 2x2

@export var border_layer_path: NodePath = NodePath("../Behaviour/Borde")

## Esquina superior izquierda del patrón 2x2 en la capa Borde (celdas del TileMap).
@export var pattern_origin: Vector2i = Vector2i.ZERO

var _mapa: Map
var _layer: TileMapLayer
## [local_x][local_y] -> datos del tile (source, atlas, alternative)
var _pattern: Array = []  # Array de 4 entradas
var _activo: bool = false

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
	_activo = not _pattern.is_empty()

func on_map_attributes_ready(mapa: Map) -> void:
	_mapa = mapa
	if _layer != null:
		_resolver_patron()
		_activo = not _pattern.is_empty()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _activo:
		return
	_actualizar()

func _resolver_patron() -> void:
	_pattern.clear()
	if _layer == null:
		return
	# Leer bloque 2x2 desde pattern_origin
	for ly: int in range(PATTERN_SIZE):
		for lx: int in range(PATTERN_SIZE):
			var celda: Vector2i = pattern_origin + Vector2i(lx, ly)
			var source_id: int = _layer.get_cell_source_id(celda)
			if source_id == -1:
				push_warning("MapBorderController: falta tile en el patrón 2x2 en celda %s" % str(celda))
				_pattern.clear()
				return
			_pattern.append({"source_id": source_id, "atlas": _layer.get_cell_atlas_coords(celda), "alternative": _layer.get_cell_alternative_tile(celda),})

func _tile_del_patron(celda_mundo: Vector2i) -> Dictionary:
	# Repetición del 2x2 (módulo; en GDScript % con negativos es truculento)
	var mx: int = posmod(celda_mundo.x, PATTERN_SIZE)
	var my: int = posmod(celda_mundo.y, PATTERN_SIZE)
	var indice: int = my * PATTERN_SIZE + mx
	return _pattern[indice]

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
	var celda_min: Vector2i = Vector2i(floori(rect_visible.position.x / TILE_SIZE) - MARGEN_CELDAS, floori(rect_visible.position.y / TILE_SIZE) - MARGEN_CELDAS)
	var celda_max: Vector2i = Vector2i(ceili(rect_visible.end.x / TILE_SIZE) + MARGEN_CELDAS, ceili(rect_visible.end.y / TILE_SIZE) + MARGEN_CELDAS)
	for y: int in range(celda_min.y, celda_max.y):
		for x: int in range(celda_min.x, celda_max.x):
			var celda: Vector2i = Vector2i(x, y)
			if _dentro_del_mapa(celda, map_size):
				if _layer.get_cell_source_id(celda) != -1:
					_layer.erase_cell(celda)
				continue
			var tile: Dictionary = _tile_del_patron(celda)
			_layer.set_cell(celda, tile["source_id"] as int, tile["atlas"] as Vector2i, tile["alternative"] as int)

func _dentro_del_mapa(celda: Vector2i, map_size: Vector2i) -> bool:
	return (celda.x >= 0 and celda.y >= 0 and celda.x < map_size.x and celda.y < map_size.y)

func _rect_visible_en_mapa(camara: Camera2D) -> Rect2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = (viewport_size / camara.zoom) * 0.5
	var centro_local: Vector2 = _mapa.to_local(camara.get_screen_center_position())
	return Rect2(centro_local - half, half * 2.0)
