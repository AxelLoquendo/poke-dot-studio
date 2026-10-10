class_name MapManager
extends Node
## Carga de un solo mapa (warps / indoor). El overworld continuo usa MapFactory.

signal map_changed(mapa: Map)
signal map_unloaded

var current_map: Map = null


func change_map(
	map_id: Variant,
	cell: Vector2i,
	player: Node2D
) -> void:
	# 1) Sacar al player del mapa que se va a destruir
	if player.get_parent() != null and player.get_parent() != self:
		player.reparent(self)

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

	MapCollisionSystem.set_active_map(mapa)
	add_child(mapa)
	current_map = mapa

	_place_player(mapa, player, cell)

	var player_controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if player_controller != null:
		MapCollisionSystem.init_entity_state(
			player_controller,
			player.global_position
		)

	_init_map_entities(mapa)
	map_changed.emit(mapa)

func _init_map_entities(mapa: Map) -> void:
	var groups: Array[StringName] = [&"Npc"]
	for group: StringName in groups:
		for node: Node in mapa.get_tree().get_nodes_in_group(group):
			# Solo los que están bajo este mapa
			if not mapa.is_ancestor_of(node):
				continue
			var controller: CharacterController = \
				node.get_node_or_null("CharacterController") as CharacterController
			if controller == null:
				continue
			MapCollisionSystem.init_entity_state(
				controller,
				controller.get_character_position()
			)

func _unload_current() -> void:
	if current_map == null:
		return
	# 3) Limpiar capa de colisión
	MapCollisionSystem.clear_active_map()
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

	var world_pos: Vector2 = Vector2(cell) * 16.0

	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		controller.teleport_to(world_pos)
	else:
		player.position = world_pos


func _resolve_path(map_id: Variant) -> String:
	if map_id is MapSection.MapID:
		return str(MapSection.MAP_SCENES.get(map_id, ""))
	return ""
