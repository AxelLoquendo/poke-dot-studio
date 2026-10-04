@tool
extends Node2D
class_name Map

@export var attributes: MapAttributes:
	set(value):
		attributes = value
		queue_redraw()

func _ready() -> void:
	queue_redraw()

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
