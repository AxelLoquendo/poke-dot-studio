class_name TileBehaviorReader
extends RefCounted

const KEY_COMPORTAMIENTO: StringName = &"comportamiento"
const TILE_SIZE: float = 16.0


static func get_behavior_at_world(world_pos: Vector2) -> int:
	for e: Dictionary in MapCollisionSystem.get_registered_maps():
		var mapa: Map = e.get("map") as Map
		if mapa == null or mapa.attributes == null:
			continue
		if not _world_in_map(mapa, world_pos):
			continue
		return _read_from_map(mapa, world_pos)
	return TileBehaviorId.Id.NONE


static func _read_from_map(mapa: Map, world_pos: Vector2) -> int:
	var tileset_root: Node = mapa.get_node_or_null("Tileset")
	if tileset_root == null:
		return TileBehaviorId.Id.NONE

	var layers: Array[TileMapLayer] = []
	for child: Node in tileset_root.get_children():
		var layer: TileMapLayer = child as TileMapLayer
		if layer != null:
			layers.append(layer)

	# De la última hija a la primera (suele ser la capa más "arriba")
	for i: int in range(layers.size() - 1, -1, -1):
		var layer: TileMapLayer = layers[i]
		var id: int = _read_layer_cell(layer, world_pos)
		if id != TileBehaviorId.Id.NONE:
			return id
	return TileBehaviorId.Id.NONE


static func _read_layer_cell(layer: TileMapLayer, world_pos: Vector2) -> int:
	if layer == null or layer.tile_set == null:
		return TileBehaviorId.Id.NONE

	var local_pos: Vector2 = layer.to_local(world_pos)
	var cell: Vector2i = layer.local_to_map(local_pos)
	var source_id: int = layer.get_cell_source_id(cell)
	if source_id == -1:
		return TileBehaviorId.Id.NONE

	var source: TileSetSource = layer.tile_set.get_source(source_id)
	var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
	if atlas_source == null:
		return TileBehaviorId.Id.NONE

	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(cell)
	var alternative: int = layer.get_cell_alternative_tile(cell)
	if not atlas_source.has_tile(atlas_coords):
		return TileBehaviorId.Id.NONE

	var tile_data: TileData = atlas_source.get_tile_data(atlas_coords, alternative)
	if tile_data == null:
		return TileBehaviorId.Id.NONE

	return int(tile_data.get_custom_data(KEY_COMPORTAMIENTO))


static func _world_in_map(mapa: Map, world_pos: Vector2) -> bool:
	var origin: Vector2 = mapa.global_position
	var size_px: Vector2 = Vector2(mapa.attributes.map_size) * TILE_SIZE
	return (
		world_pos.x >= origin.x
		and world_pos.y >= origin.y
		and world_pos.x < origin.x + size_px.x
		and world_pos.y < origin.y + size_px.y
	)
