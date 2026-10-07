@tool
extends Node2D
class_name Map

const TILE_SIZE: float = 16.0

@export var attributes: MapAttributes:
	set(value):
		attributes = value
		queue_redraw()
		_notify_attributes_changed()

func _ready() -> void:
	queue_redraw()

func _notify_attributes_changed() -> void:
	if Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	for child: Node in get_children():
		if child.has_method("on_map_attributes_ready"):
			child.call("on_map_attributes_ready", self)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if attributes == null:
		return
	if attributes.map_size.x <= 0 or attributes.map_size.y <= 0:
		return
	var size: Vector2 = Vector2(attributes.map_size) * TILE_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), Color.RED, false, 2.0)
	_draw_connections()

func _draw_connections() -> void:
	if attributes.connections.is_empty():
		return
	for entry: MapConnectionEntry in attributes.connections:
		if entry == null:
			continue
		if entry.target_map == MapSection.MapID.NONE:
			continue
		var size_neighbor: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_neighbor.x <= 0 or size_neighbor.y <= 0:
			continue
		var pos: Vector2 = MapConnectionResolver.world_neighbor_from_current(entry.side, entry.edge_offset, attributes.map_size, size_neighbor)
		var rect_size: Vector2 = Vector2(size_neighbor) * TILE_SIZE
		draw_rect(Rect2(pos, rect_size), Color(0.2, 0.85, 1.0, 1.0), false, 2.0)
		# Esquina para ver el origen del vecino
		draw_circle(pos, 3.0, Color(0.2, 0.85, 1.0, 1.0))
