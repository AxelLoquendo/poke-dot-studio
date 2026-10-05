class_name MapManager
extends Node

signal map_changed(mapa: Map)
signal map_unloaded

var current_map: Map = null


func change_map(
	map_id: Variant,
	cell: Vector2i,
	player: Node2D
) -> void:
	_unload_current()

	var path: String = _resolve_path(map_id)
	if path.is_empty():
		push_error("MapManager: sin ruta para %s" % str(map_id))
		return

	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("MapManager: no se pudo cargar %s" % path)
		return

	var instancia: Node = packed.instantiate()
	var mapa: Map = instancia as Map
	if mapa == null:
		instancia.queue_free()
		push_error("MapManager: la escena no es Map")
		return

	add_child(mapa)
	current_map = mapa

	_place_player(mapa, player, cell)
	map_changed.emit(mapa)


func _unload_current() -> void:
	if current_map == null:
		return
	# El player no se borra: se saca del mapa antes
	current_map.queue_free()
	current_map = null
	map_unloaded.emit()


func _place_player(mapa: Map, player: Node2D, cell: Vector2i) -> void:
	var contenedor: Node = mapa.get_node_or_null("EventObject")
	if contenedor == null:
		push_warning("MapManager: sin EventObject, usando raíz del mapa")
		contenedor = mapa

	if player.get_parent() != contenedor:
		player.reparent(contenedor)

	player.position = Vector2(cell) * 16.0


func _resolve_path(map_id: Variant) -> String:
	if map_id is MapSection.MapID:
		return MapSection.MAP_SCENES.get(map_id, "")
	return ""
