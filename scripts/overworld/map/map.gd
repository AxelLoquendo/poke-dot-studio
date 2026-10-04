@tool
extends Node2D
class_name Map

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
	var tile_size: float = 16.0
	var size: Vector2 = Vector2(attributes.map_size) * tile_size
	draw_rect(Rect2(Vector2.ZERO, size), Color.RED, false, 2.0)
