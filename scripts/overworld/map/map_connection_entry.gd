class_name MapConnectionEntry
extends Resource
## Vecino visto desde el MapAttributes de este mapa.

enum Side {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

@export var target_map: MapSection.MapID = MapSection.MapID.NONE:
	set(value):
		if target_map == value:
			return
		target_map = value
		emit_changed()

@export var side: MapConnectionEntry.Side = MapConnectionEntry.Side.NORTH:
	set(value):
		if side == value:
			return
		side = value
		emit_changed()

@export var edge_offset: int = 0:
	set(value):
		if edge_offset == value:
			return
		edge_offset = value
		emit_changed()
