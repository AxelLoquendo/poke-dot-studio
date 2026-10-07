class_name MapFactory
extends Node
## Carga el mapa actual y sus vecinos con offset (conexión continua).

signal cluster_loaded(current: Map)

var current_map: Map = null
var current_map_id: MapSection.MapID = MapSection.MapID.NONE
## MapSection.MapID -> Map
var loaded_maps: Dictionary = {}

func load_cluster(map_id: MapSection.MapID, cell: Vector2i, player: Node2D) -> void:
	_unload_all(player)
	var mapa: Map = _instantiate_map(map_id)
	if mapa == null:
		return
	mapa.position = Vector2.ZERO
	add_child(mapa)
	loaded_maps[map_id] = mapa
	current_map = mapa
	current_map_id = map_id
	MapCollisionSystem.set_active_map(mapa)
	_load_neighbors(mapa)
	_place_player(mapa, player, cell)
	var player_controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if player_controller != null:
		MapCollisionSystem.init_entity_state(player_controller, player.global_position)
	_init_npcs(mapa)
	cluster_loaded.emit(mapa)

func _load_neighbors(center: Map) -> void:
	if center.attributes == null:
		return
	for entry: MapConnectionEntry in center.attributes.connections:
		if entry == null or entry.target_map == MapSection.MapID.NONE:
			continue
		if loaded_maps.has(entry.target_map):
			continue
		var size_neighbor: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_neighbor.x <= 0:
			push_warning("MapFactory: sin map_size para %s" % str(entry.target_map))
			continue
		var neighbor: Map = _instantiate_map(entry.target_map)
		if neighbor == null:
			continue
		neighbor.position = MapConnectionResolver.world_neighbor_from_current(entry.side, entry.edge_offset, center.attributes.map_size, size_neighbor)
		add_child(neighbor)
		loaded_maps[entry.target_map] = neighbor
		_init_npcs(neighbor)

func _instantiate_map(map_id: MapSection.MapID) -> Map:
	var path: String = MapSection.MAP_SCENES.get(map_id, "")
	if path.is_empty():
		push_error("MapFactory: sin ruta para %s" % str(map_id))
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("MapFactory: no se pudo cargar %s" % path)
		return null
	var instancia: Node = packed.instantiate()
	var mapa: Map = instancia as Map
	if mapa == null:
		instancia.queue_free()
		push_error("MapFactory: la escena no es Map")
		return null
	return mapa

func _place_player(mapa: Map, player: Node2D, cell: Vector2i) -> void:
	var contenedor: Node = mapa.get_node_or_null("EventObject")
	if contenedor == null:
		contenedor = mapa
	if player.get_parent() != contenedor:
		player.reparent(contenedor)
	var world_pos: Vector2 = mapa.global_position + Vector2(cell) * 16.0
	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		controller.teleport_to(world_pos)
	else:
		player.global_position = world_pos

func _init_npcs(mapa: Map) -> void:
	if not mapa.is_inside_tree():
		return
	for node: Node in mapa.get_tree().get_nodes_in_group(&"Npc"):
		if not mapa.is_ancestor_of(node):
			continue
		var controller: CharacterController = \
			node.get_node_or_null("CharacterController") as CharacterController
		if controller == null:
			continue
		# Colisión de altura del mapa centro solo por ahora
		MapCollisionSystem.init_entity_state(controller, controller.get_character_position())

func _unload_all(player: Node2D) -> void:
	if player.get_parent() != null and player.get_parent() != self:
		player.reparent(self)
	MapCollisionSystem.clear_active_map()
	for id: Variant in loaded_maps.keys():
		var mapa: Map = loaded_maps[id] as Map
		if mapa != null:
			mapa.queue_free()
	loaded_maps.clear()
	current_map = null
	current_map_id = MapSection.MapID.NONE
