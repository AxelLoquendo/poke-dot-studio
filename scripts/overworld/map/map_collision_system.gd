class_name MapCollisionSystem
extends RefCounted
## Colisión de tiles. Soporta varios mapas cargados (cluster continuo).

## Entradas: { "map": Map, "layer": TileMapLayer }
static var _entries: Array[Dictionary] = []


static func clear_active_map() -> void:
	_entries.clear()


## Un solo mapa (warps / MapManager). Borra el resto.
static func set_active_map(mapa: Map) -> void:
	_entries.clear()
	register_map(mapa)


static func register_map(mapa: Map) -> void:
	if mapa == null:
		return
	for e: Dictionary in _entries:
		if e.get("map") == mapa:
			return
	var layer: TileMapLayer = mapa.get_node_or_null("Behaviour/Collision") as TileMapLayer
	if layer == null:
		push_warning("MapCollisionSystem: sin Behaviour/Collision")
		return
	_entries.append({ "map": mapa, "layer": layer })


static func unregister_map(mapa: Map) -> void:
	for i: int in range(_entries.size() - 1, -1, -1):
		if _entries[i].get("map") == mapa:
			_entries.remove_at(i)


static func get_registered_maps() -> Array[Dictionary]:
	return _entries


static func get_tile_data_at_world(world_pos: Vector2) -> CollisionTileData:
	for e: Dictionary in _entries:
		var mapa: Map = e.get("map") as Map
		var layer: TileMapLayer = e.get("layer") as TileMapLayer
		if mapa == null or layer == null:
			continue
		if not _world_in_map(mapa, world_pos):
			continue
		var local_pos: Vector2 = layer.to_local(world_pos)
		var cell: Vector2i = layer.local_to_map(local_pos)
		return CollisionTileData.from_layer(layer, cell)
	return CollisionTileData.new()


static func _world_in_map(mapa: Map, world_pos: Vector2) -> bool:
	if mapa.attributes == null:
		return false
	var origin: Vector2 = mapa.global_position
	var size_px: Vector2 = Vector2(mapa.attributes.map_size) * 16.0
	var rect: Rect2 = Rect2(origin, size_px)
	return (
		world_pos.x >= rect.position.x
		and world_pos.y >= rect.position.y
		and world_pos.x < rect.position.x + rect.size.x
		and world_pos.y < rect.position.y + rect.size.y
	)


static func can_enter(
	height_level: int,
	elevated: bool,
	from_world: Vector2,
	to_world: Vector2,
	controller: CharacterController = null
) -> bool:
	var to_data: CollisionTileData = get_tile_data_at_world(to_world)
	var from_data: CollisionTileData = get_tile_data_at_world(from_world)

	# --- Altura / bloqueo ---
	var height_ok: bool = false

	if not to_data.empty and to_data.bloqueo:
		return false

	if from_data.cambiar_nivel_altura:
		height_ok = true
	elif elevated:
		if to_data.empty:
			height_ok = height_level == 0
		elif to_data.cambiar_nivel_altura:
			height_ok = true
		elif to_data.no_block:
			height_ok = true
		else:
			height_ok = height_level == to_data.nivel_altura
	elif to_data.empty:
		height_ok = height_level == 0
	elif to_data.cambiar_nivel_altura:
		height_ok = true
	elif to_data.no_block:
		height_ok = true
	else:
		height_ok = height_level == to_data.nivel_altura

	if not height_ok:
		return false

	# --- Comportamiento (Tileset) ---
	var ctx: TileBehaviorContext = TileBehaviorSystem.build_context(
		controller,
		from_world,
		to_world
	)
	return TileBehaviorSystem.can_enter(ctx)


static func apply_cell_state(
	controller: CharacterController,
	from_world: Vector2,
	to_world: Vector2
) -> void:
	var to_data: CollisionTileData = get_tile_data_at_world(to_world)
	var from_data: CollisionTileData = get_tile_data_at_world(from_world)

	if not to_data.empty and to_data.bloqueo:
		return

	if to_data.empty:
		controller.height_level = 0
		controller.elevated = false
		controller.update_render_layer()
	elif to_data.cambiar_nivel_altura:
		controller.elevated = false
		controller.update_render_layer()
	elif to_data.no_block:
		if from_data.cambiar_nivel_altura or controller.elevated:
			controller.elevated = true
			if to_data.nivel_altura > 0:
				controller.height_level = to_data.nivel_altura
		else:
			controller.elevated = false
		controller.update_render_layer()
	else:
		controller.height_level = to_data.nivel_altura
		controller.elevated = false
		controller.update_render_layer()

	# Comportamiento al aterrizar (hierba, hielo, etc.)
	var ctx: TileBehaviorContext = TileBehaviorSystem.build_context(
		controller,
		from_world,
		to_world
	)
	TileBehaviorSystem.on_landed(ctx)


static func init_entity_state(controller: CharacterController, world_pos: Vector2) -> void:
	var data: CollisionTileData = get_tile_data_at_world(world_pos)
	if data.empty:
		controller.height_level = 0
		controller.elevated = false
		controller.update_render_layer()
		return

	if data.no_block:
		controller.height_level = data.nivel_altura
		controller.elevated = data.nivel_altura > 0
		controller.update_render_layer()
		return

	if data.cambiar_nivel_altura:
		controller.elevated = false
		controller.update_render_layer()
		return

	controller.height_level = data.nivel_altura
	controller.elevated = false
	controller.update_render_layer()


static func preview_render_state(
	controller: CharacterController,
	from_world: Vector2,
	to_world: Vector2
) -> void:
	var will_elevate: bool = _will_be_elevated(controller, from_world, to_world)

	if controller.elevated and not will_elevate:
		return

	if not controller.elevated and will_elevate:
		controller.elevated = true
		controller.update_render_layer()
		return

	controller.elevated = will_elevate
	controller.update_render_layer()


static func _will_be_elevated(
	controller: CharacterController,
	from_world: Vector2,
	to_world: Vector2
) -> bool:
	var to_data: CollisionTileData = get_tile_data_at_world(to_world)
	var from_data: CollisionTileData = get_tile_data_at_world(from_world)

	if to_data.empty or to_data.bloqueo:
		return false
	if to_data.cambiar_nivel_altura:
		return false
	if to_data.no_block:
		return from_data.cambiar_nivel_altura or controller.elevated
	return false
