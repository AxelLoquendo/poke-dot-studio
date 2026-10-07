@tool
extends Node2D
class_name Map

const TILE_SIZE: float = 16.0
const PREVIEW_MODULATE: Color = Color(1.0, 1.0, 1.0, 0.85)
const META_PREVIEW: StringName = &"_connection_preview"
const META_SKIP_PREVIEW: StringName = &"_skip_connection_preview"

@export var attributes: MapAttributes:
	set(value):
		attributes = value
		queue_redraw()
		_notify_attributes_changed()
		if Engine.is_editor_hint() and not _preview_busy:
			call_deferred("_refresh_connection_previews")

@export var refresh_connection_previews: bool = false:
	set(value):
		if not value:
			return
		refresh_connection_previews = false
		if Engine.is_editor_hint() and not _preview_busy:
			call_deferred("_refresh_connection_previews")

var is_current: bool = false
var _preview_nodes: Dictionary = {}
var _preview_busy: bool = false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint() and not has_meta(META_SKIP_PREVIEW):
		call_deferred("_refresh_connection_previews")


func _notify_attributes_changed() -> void:
	if Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	for child: Node in get_children():
		if child.has_method("on_map_attributes_ready"):
			child.call("on_map_attributes_ready", self)


func set_as_current(activo: bool) -> void:
	is_current = activo
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group(&"Npc"):
		if not is_ancestor_of(node):
			continue
		node.process_mode = (
			Node.PROCESS_MODE_ALWAYS if activo else Node.PROCESS_MODE_DISABLED
		)
	if activo:
		var music: MapMusicController = get_node_or_null("MapMusicController") as MapMusicController
		if music != null:
			music.activar()


func _refresh_connection_previews() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	if has_meta(META_SKIP_PREVIEW):
		return
	if _preview_busy:
		return

	_preview_busy = true

	# 1) Quitar previews viejos de forma segura
	await _clear_connection_previews_async()

	if not is_inside_tree():
		_preview_busy = false
		return

	if attributes == null or attributes.connections.is_empty():
		_preview_busy = false
		queue_redraw()
		return

	for entry: MapConnectionEntry in attributes.connections:
		if entry == null:
			continue
		if entry.target_map == MapSection.MapID.NONE:
			continue
		if entry.target_map == attributes.map_id:
			continue

		var path: String = MapSection.MAP_SCENES.get(entry.target_map, "") as String
		if path.is_empty() or not ResourceLoader.exists(path):
			continue

		var size_neighbor: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_neighbor.x <= 0 or size_neighbor.y <= 0:
			continue

		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue

		var instancia: Node = packed.instantiate()
		var vecino: Map = instancia as Map
		if vecino == null:
			instancia.queue_free()
			continue

		vecino.set_meta(META_PREVIEW, true)
		vecino.set_meta(META_SKIP_PREVIEW, true)
		vecino.name = "Preview_%s" % str(entry.target_map)
		vecino.position = MapConnectionResolver.world_neighbor_from_current(
			entry.side,
			entry.edge_offset,
			attributes.map_size,
			size_neighbor
		)
		vecino.modulate = PREVIEW_MODULATE
		vecino.process_mode = Node.PROCESS_MODE_DISABLED

		_strip_preview_runtime(vecino)

		add_child(vecino)
		vecino.owner = null
		_preview_nodes[entry.target_map] = vecino

	_preview_busy = false
	queue_redraw()


func _strip_preview_runtime(vecino: Map) -> void:
	var music: Node = vecino.get_node_or_null("MapMusicController")
	if music != null:
		music.queue_free()

	var border: Node = vecino.get_node_or_null("MapBorderController")
	if border != null:
		border.queue_free()

	var events: Node = vecino.get_node_or_null("EventObject")
	if events != null:
		events.visible = false
		events.process_mode = Node.PROCESS_MODE_DISABLED

	var trigger: Node = vecino.get_node_or_null("Trigger")
	if trigger != null:
		trigger.visible = false
		trigger.process_mode = Node.PROCESS_MODE_DISABLED


func _clear_connection_previews_async() -> void:
	var pending: Array[Node] = []

	for key: Variant in _preview_nodes.keys():
		var n: Node = _preview_nodes[key] as Node
		if is_instance_valid(n):
			pending.append(n)
	_preview_nodes.clear()

	for child: Node in get_children():
		if not is_instance_valid(child):
			continue
		if child.has_meta(META_PREVIEW):
			if not pending.has(child):
				pending.append(child)

	for n: Node in pending:
		if not is_instance_valid(n):
			continue
		var parent: Node = n.get_parent()
		if parent == self:
			remove_child(n)
		n.queue_free()

	# Dejar que el árbol termine de sacar nodos
	await get_tree().process_frame


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if attributes == null:
		return
	if attributes.map_size.x <= 0 or attributes.map_size.y <= 0:
		return

	var size: Vector2 = Vector2(attributes.map_size) * TILE_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), Color.RED, false, 2.0)

	if has_meta(META_SKIP_PREVIEW):
		return

	_draw_connection_outlines()


func _draw_connection_outlines() -> void:
	if attributes == null or attributes.connections.is_empty():
		return

	for entry: MapConnectionEntry in attributes.connections:
		if entry == null or entry.target_map == MapSection.MapID.NONE:
			continue

		var size_neighbor: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_neighbor.x <= 0 or size_neighbor.y <= 0:
			continue

		var pos: Vector2 = MapConnectionResolver.world_neighbor_from_current(
			entry.side,
			entry.edge_offset,
			attributes.map_size,
			size_neighbor
		)
		var rect_size: Vector2 = Vector2(size_neighbor) * TILE_SIZE
		draw_rect(Rect2(pos, rect_size), Color(0.2, 0.85, 1.0, 0.9), false, 2.0)
		draw_circle(pos, 3.0, Color(0.2, 0.85, 1.0, 1.0))
