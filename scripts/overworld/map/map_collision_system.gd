class_name MapCollisionSystem
extends RefCounted

static var _collision_layer: TileMapLayer = null


static func set_active_map(mapa: Map) -> void:
	_collision_layer = null
	if mapa == null:
		return
	_collision_layer = mapa.get_node_or_null("Behaviour/Collision") as TileMapLayer


static func clear_active_map() -> void:
	_collision_layer = null


static func get_tile_data_at_world(world_pos: Vector2) -> CollisionTileData:
	if _collision_layer == null:
		return CollisionTileData.new()
	var local_pos: Vector2 = _collision_layer.to_local(world_pos)
	var cell: Vector2i = _collision_layer.local_to_map(local_pos)
	return CollisionTileData.from_layer(_collision_layer, cell)


static func can_enter(
	height_level: int,
	elevated: bool,
	from_world: Vector2,
	to_world: Vector2
) -> bool:
	var to_data: CollisionTileData = get_tile_data_at_world(to_world)
	var from_data: CollisionTileData = get_tile_data_at_world(from_world)

	# Destino bloqueado
	if not to_data.empty and to_data.bloqueo:
		return false

	# Desde conector: puedes cambiar de nivel (un solo paso de transición)
	if from_data.cambiar_nivel_altura:
		return true

	# Camino elevado (encima del puente)
	if elevated:
		if to_data.empty:
			# vacío = suelo nivel 0 → solo si tu nivel es 0
			return height_level == 0
		if to_data.cambiar_nivel_altura:
			return true
		if to_data.no_block:
			return true
		# Suelo normal: solo el mismo nivel
		return height_level == to_data.nivel_altura

	# No elevated
	if to_data.empty:
		return height_level == 0

	if to_data.cambiar_nivel_altura:
		return true

	if to_data.no_block:
		return true  # pasar por debajo

	return height_level == to_data.nivel_altura

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
		return

	if to_data.cambiar_nivel_altura:
		# Conector: no fuerza nivel; sales del modo puente
		controller.elevated = false
		controller.update_render_layer()
		return

	if to_data.no_block:
		# Encima si venías del conector o ya estabas elevated
		if from_data.cambiar_nivel_altura or controller.elevated:
			controller.elevated = true
			# Opcional: anclar nivel del puente
			if to_data.nivel_altura > 0:
				controller.height_level = to_data.nivel_altura
		else:
			controller.elevated = false  # por debajo
		controller.update_render_layer()
		return

	# Suelo normal
	controller.height_level = to_data.nivel_altura
	controller.elevated = false
	controller.update_render_layer()

static func init_entity_state(controller: CharacterController, world_pos: Vector2) -> void:
	var data: CollisionTileData = get_tile_data_at_world(world_pos)
	if data.empty:
		controller.height_level = 0
		controller.elevated = false
		return

	if data.no_block:
		controller.height_level = data.nivel_altura
		controller.elevated = data.nivel_altura > 0
		return

	if data.cambiar_nivel_altura:
		controller.elevated = false
		return

	controller.height_level = data.nivel_altura
	controller.elevated = false

## Solo elevated + z_index según destino (no cambia height_level aún)
static func preview_render_state(
	controller: CharacterController,
	from_world: Vector2,
	to_world: Vector2
) -> void:
	var will_elevate: bool = _will_be_elevated(
		controller,
		from_world,
		to_world
	)

	# Saliendo del puente: no tocar elevated/z hasta el final del paso
	if controller.elevated and not will_elevate:
		return

	# Subiendo al puente: elevar ya
	if not controller.elevated and will_elevate:
		controller.elevated = true
		controller.update_render_layer()
		return

	# Resto (suelo, debajo, seguir elevated): aplicar ya
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

	# Suelo normal
	return false
