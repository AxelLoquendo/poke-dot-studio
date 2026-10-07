class_name MapConnectionEntry
extends Resource
## Un vecino visto desde el mapa que posee este MapAttributes.

enum Side {NORTH, SOUTH, EAST, WEST}

@export var target_map: MapSection.MapID = MapSection.MapID.NONE
@export var side: MapConnectionEntry.Side = MapConnectionEntry.Side.NORTH
@export var edge_offset: int = 0
