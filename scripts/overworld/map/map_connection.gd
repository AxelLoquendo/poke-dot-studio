class_name MapConnection
extends Resource

enum Side {NORTH, SOUTH, EAST, WEST}

@export var map_a: MapSection.MapID = MapSection.MapID.NONE
@export var map_b: MapSection.MapID = MapSection.MapID.NONE
@export var side_on_a: MapConnection.Side = MapConnection.Side.NORTH
@export var edge_offset: int = 0
