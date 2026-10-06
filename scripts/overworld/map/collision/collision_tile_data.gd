class_name CollisionTileData
extends RefCounted
## Lee custom data de una celda de Behaviour/Collision.
## Contrato:
##   bloqueo: bool
##   cambiar_nivel_altura: bool
##   nivel_altura: int
##   no_block: bool

const KEY_BLOQUEO: StringName = &"bloqueo"
const KEY_CAMBIAR_NIVEL: StringName = &"cambiar_nivel_altura"
const KEY_NIVEL: StringName = &"nivel_altura"
const KEY_NO_BLOCK: StringName = &"no_block"

var empty: bool = true
var bloqueo: bool = false
var cambiar_nivel_altura: bool = false
var nivel_altura: int = 0
var no_block: bool = false


static func from_layer(layer: TileMapLayer, cell: Vector2i) -> CollisionTileData:
	var result: CollisionTileData = CollisionTileData.new()
	if layer == null or layer.tile_set == null:
		return result

	var source_id: int = layer.get_cell_source_id(cell)
	if source_id == -1:
		return result

	var source: TileSetSource = layer.tile_set.get_source(source_id)
	var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
	if atlas_source == null:
		return result

	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(cell)
	var alternative: int = layer.get_cell_alternative_tile(cell)
	if not atlas_source.has_tile(atlas_coords):
		return result

	var tile_data: TileData = atlas_source.get_tile_data(atlas_coords, alternative)
	if tile_data == null:
		return result

	result.empty = false
	result.bloqueo = bool(tile_data.get_custom_data(KEY_BLOQUEO))
	result.cambiar_nivel_altura = bool(tile_data.get_custom_data(KEY_CAMBIAR_NIVEL))
	result.nivel_altura = int(tile_data.get_custom_data(KEY_NIVEL))
	result.no_block = bool(tile_data.get_custom_data(KEY_NO_BLOCK))
	return result
