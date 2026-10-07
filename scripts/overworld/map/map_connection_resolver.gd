class_name MapConnectionResolver
extends RefCounted

const TILE_SIZE: float = 16.0


static func tiles_neighbor_from_current(side: MapConnectionEntry.Side, edge_offset: int, size_current: Vector2i, size_neighbor: Vector2i) -> Vector2i:
	match side:
		MapConnectionEntry.Side.NORTH:
			return Vector2i(edge_offset, -size_neighbor.y)
		MapConnectionEntry.Side.SOUTH:
			return Vector2i(edge_offset, size_current.y)
		MapConnectionEntry.Side.EAST:
			return Vector2i(size_current.x, edge_offset)
		MapConnectionEntry.Side.WEST:
			return Vector2i(-size_neighbor.x, edge_offset)
	return Vector2i.ZERO

static func world_neighbor_from_current(side: MapConnectionEntry.Side, edge_offset: int, size_current: Vector2i, size_neighbor: Vector2i) -> Vector2:
	var tiles: Vector2i = tiles_neighbor_from_current(side, edge_offset, size_current, size_neighbor)
	return Vector2(tiles) * TILE_SIZE

## Carga temporal de la escena solo para leer map_size.
static func get_map_size(map_id: MapSection.MapID) -> Vector2i:
	var path: String = MapSection.MAP_SCENES.get(map_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return Vector2i.ZERO
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return Vector2i.ZERO
	var instancia: Node = packed.instantiate()
	var mapa: Map = instancia as Map
	var size: Vector2i = Vector2i.ZERO
	if mapa != null and mapa.attributes != null:
		size = mapa.attributes.map_size
	instancia.free()
	return size
