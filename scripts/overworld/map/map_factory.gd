class_name MapFactory
extends Node
## Overworld continuo: current completo + vecinos precargados (vista).

signal cluster_loaded(current: Map)
signal current_changed(mapa: Map)

const TILE_SIZE: float = 16.0

var current_map: Map = null
var current_map_id: MapSection.MapID = MapSection.MapID.NONE
## MapSection.MapID -> Map
var loaded_maps: Dictionary = {}


func load_cluster(
	map_id: MapSection.MapID,
	cell: Vector2i,
	player: Node2D
) -> void:
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

	# Primero todos en pausa
	for id: Variant in loaded_maps.keys():
		var m: Map = loaded_maps[id] as Map
		if m != null:
			m.set_as_current(false)

	# Current activo (diferido: NPCs ya en grupo)
	mapa.set_as_current.call_deferred(true)

	var player_controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if player_controller != null:
		MapCollisionSystem.init_entity_state(
			player_controller,
			player.global_position
		)

	_init_npcs_current(mapa)
	cluster_loaded.emit(mapa)


func update_current_from_player(player: Node2D) -> void:
	if player == null or loaded_maps.is_empty():
		return
	var nuevo_id: MapSection.MapID = _mapa_id_en_posicion(player.global_position)
	if nuevo_id == MapSection.MapID.NONE or nuevo_id == current_map_id:
		return
	_promover_a_current(nuevo_id, player)


func _promover_a_current(nuevo_id: MapSection.MapID, player: Node2D) -> void:
	var nuevo: Map = loaded_maps.get(nuevo_id) as Map
	if nuevo == null:
		return

	if current_map != null:
		current_map.set_as_current(false)

	current_map = nuevo
	current_map_id = nuevo_id
	MapCollisionSystem.set_active_map(nuevo)
	_reparent_player_keep_global(player, nuevo)

	nuevo.set_as_current(true)
	_init_npcs_current(nuevo)
	_refrescar_vecinos(nuevo)
	current_changed.emit(nuevo)


func _aplicar_estados_current() -> void:
	for id: Variant in loaded_maps.keys():
		var m: Map = loaded_maps[id] as Map
		if m == null:
			continue
		m.set_as_current(m == current_map)


func _load_neighbors(center: Map) -> void:
	if center.attributes == null:
		return
	for entry: MapConnectionEntry in center.attributes.connections:
		if entry == null or entry.target_map == MapSection.MapID.NONE:
			continue
		if loaded_maps.has(entry.target_map):
			continue

		var size_neighbor: Vector2i = MapConnectionResolver.get_map_size(entry.target_map)
		if size_neighbor.x <= 0 or size_neighbor.y <= 0:
			push_warning("MapFactory: sin map_size para %s" % str(entry.target_map))
			continue

		var neighbor: Map = _instantiate_map(entry.target_map)
		if neighbor == null:
			continue

		neighbor.position = MapConnectionResolver.world_neighbor_from_current(
			entry.side,
			entry.edge_offset,
			center.attributes.map_size,
			size_neighbor
		)
		add_child(neighbor)
		loaded_maps[entry.target_map] = neighbor
		neighbor.set_as_current(false)


func _refrescar_vecinos(center: Map) -> void:
	_load_neighbors(center)

	var keep: Dictionary = {}
	keep[current_map_id] = true
	if center.attributes != null:
		for entry: MapConnectionEntry in center.attributes.connections:
			if entry != null and entry.target_map != MapSection.MapID.NONE:
				keep[entry.target_map] = true

	var a_quitar: Array = []
	for id: Variant in loaded_maps.keys():
		if not keep.has(id):
			a_quitar.append(id)
	for id: Variant in a_quitar:
		var m: Map = loaded_maps[id] as Map
		if m != null:
			m.queue_free()
		loaded_maps.erase(id)


func _mapa_id_en_posicion(world_pos: Vector2) -> MapSection.MapID:
	for id: Variant in loaded_maps.keys():
		var m: Map = loaded_maps[id] as Map
		if m == null or m.attributes == null:
			continue
		var origin: Vector2 = m.global_position
		var size_px: Vector2 = Vector2(m.attributes.map_size) * TILE_SIZE
		if Rect2(origin, size_px).has_point(world_pos):
			return id as MapSection.MapID
	return MapSection.MapID.NONE


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
	_reparent_player_keep_global(player, mapa)
	var world_pos: Vector2 = mapa.global_position + Vector2(cell) * TILE_SIZE
	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		controller.teleport_to(world_pos)
	else:
		player.global_position = world_pos


func _reparent_player_keep_global(player: Node2D, mapa: Map) -> void:
	var contenedor: Node = mapa.get_node_or_null("EventObject")
	if contenedor == null:
		contenedor = mapa
	var g: Vector2 = player.global_position
	if player.get_parent() != contenedor:
		player.reparent(contenedor)
	player.global_position = g


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

func _init_npcs_current(mapa: Map) -> void:
	if not mapa.is_inside_tree():
		return
	for node: Node in mapa.get_tree().get_nodes_in_group(&"Npc"):
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
