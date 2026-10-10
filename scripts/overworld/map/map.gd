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
		_conectar_senales()
		queue_redraw()
		_notify_attributes_changed()

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
var _last_signature: String = ""


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint() and not has_meta(META_SKIP_PREVIEW):
		_conectar_senales()
		_last_signature = _layout_signature()
		call_deferred("_refresh_connection_previews")
	elif not Engine.is_editor_hint():
		call_deferred("_notify_attributes_changed")


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if has_meta(META_SKIP_PREVIEW) or _preview_busy:
		return

	var signature: String = _layout_signature()
	if signature == _last_signature:
		return

	var solo_offset: bool = _solo_cambio_offset(_last_signature, signature)
	_last_signature = signature
	queue_redraw()

	if _preview_nodes.is_empty() or not solo_offset:
		call_deferred("_refresh_connection_previews")
	else:
		_sync_preview_positions()


func _solo_cambio_offset(antes: String, ahora: String) -> bool:
	var a: PackedStringArray = antes.split("|")
	var b: PackedStringArray = ahora.split("|")
	if a.size() != b.size():
		return false
	for i: int in a.size():
		if i == 0:
			if a[i] != b[i]:
				return false
			continue
		var pa: PackedStringArray = a[i].split(":")
		var pb: PackedStringArray = b[i].split(":")
		if pa.size() < 3 or pb.size() < 3:
			return false
		if pa[0] != pb[0] or pa[1] != pb[1]:
			return false
	return true


func _conectar_senales() -> void:
	if not Engine.is_editor_hint() or attributes == null:
		return
	if not attributes.changed.is_connected(_on_attributes_changed):
		attributes.changed.connect(_on_attributes_changed)
	for entry: MapConnectionEntry in attributes.connections:
		if entry == null:
			continue
		if not entry.changed.is_connected(_on_connection_changed):
			entry.changed.connect(_on_connection_changed)


func _on_attributes_changed() -> void:
	_conectar_senales()
	queue_redraw()


func _on_connection_changed() -> void:
	queue_redraw()
	if has_meta(META_SKIP_PREVIEW) or _preview_busy:
		return
	if _preview_nodes.is_empty():
		call_deferred("_refresh_connection_previews")
	else:
		_sync_preview_positions()


func _layout_signature() -> String:
	if attributes == null:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	parts.append(str(attributes.map_size))
	for entry: MapConnectionEntry in attributes.connections:
		if entry == null:
			parts.append("-")
			continue
		parts.append("%s:%s:%s" % [
			str(entry.target_map),
			str(entry.side),
			str(entry.edge_offset),
		])
	return "|".join(parts)


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
		var weather: MapWeatherController = get_node_or_null("MapWeatherController") as MapWeatherController
		if weather != null:
			weather.activar()


func _sync_preview_positions() -> void:
	if attributes == null:
		return
	for entry: MapConnectionEntry in attributes.connections:
		if entry == null or not _preview_nodes.has(entry.target_map):
			continue
		var node: Node2D = _preview_nodes[entry.target_map] as Node2D
		if not is_instance_valid(node):
			continue
		var size_neighbor: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_neighbor.x <= 0 or size_neighbor.y <= 0:
			continue
		node.position = MapConnectionResolver.world_neighbor_from_current(
			entry.side,
			entry.edge_offset,
			attributes.map_size,
			size_neighbor
		)
	queue_redraw()


func _refresh_connection_previews() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if has_meta(META_SKIP_PREVIEW) or _preview_busy:
		return

	_preview_busy = true
	await _clear_connection_previews_async()

	if not is_inside_tree() or attributes == null or attributes.connections.is_empty():
		_preview_busy = false
		queue_redraw()
		return

	for entry: MapConnectionEntry in attributes.connections:
		if entry == null or entry.target_map == MapSection.MapID.NONE:
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
	_last_signature = _layout_signature()
	queue_redraw()


func _strip_preview_runtime(vecino: Map) -> void:
	var music: Node = vecino.get_node_or_null("MapMusicController")
	if music != null:
		music.queue_free()
	var border: Node = vecino.get_node_or_null("MapBorderController")
	if border != null:
		border.queue_free()
	var weather: Node = vecino.get_node_or_null("MapWeatherController")
	if weather != null:
		weather.queue_free()
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
		if is_instance_valid(child) and child.has_meta(META_PREVIEW) and not pending.has(child):
			pending.append(child)

	for n: Node in pending:
		if not is_instance_valid(n):
			continue
		if n.get_parent() == self:
			remove_child(n)
		n.queue_free()

	if is_inside_tree():
		await get_tree().process_frame


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if attributes == null or attributes.map_size.x <= 0 or attributes.map_size.y <= 0:
		return

	draw_rect(
		Rect2(Vector2.ZERO, Vector2(attributes.map_size) * TILE_SIZE),
		Color.RED,
		false,
		2.0
	)
	if has_meta(META_SKIP_PREVIEW):
		return
	_draw_connection_outlines()


func _draw_connection_outlines() -> void:
	if attributes == null:
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
		draw_rect(Rect2(pos, Vector2(size_neighbor) * TILE_SIZE), Color(0.2, 0.85, 1.0, 0.9), false, 2.0)
		draw_circle(pos, 3.0, Color(0.2, 0.85, 1.0, 1.0))
