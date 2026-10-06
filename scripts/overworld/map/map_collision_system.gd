class_name MapCollisionSystem
extends RefCounted
## Colisión de tiles del mapa activo (Behaviour/Collision).
## Custom data: bloqueo, cambiar_nivel_altura, nivel_altura, no_block.

static var _collision_layer: TileMapLayer = null


static func set_active_map(mapa: Map) -> void:
	_collision_layer = null
	if mapa == null:
		return
	_collision_layer = mapa.get_node_or_null("Behaviour/Collision") as TileMapLayer


static func clear_active_map() -> void:
	_collision_layer = null


static func get_collision_layer() -> TileMapLayer:
	return _collision_layer


static func get_tile_data_at_world(world_pos: Vector2) -> CollisionTileData:
	if _collision_layer == null:
		return CollisionTileData.new()
	var local_pos: Vector2 = _collision_layer.to_local(world_pos)
	var cell: Vector2i = _collision_layer.local_to_map(local_pos)
	return CollisionTileData.from_layer(_collision_layer, cell)


static func can_enter(
	height_level: int,
	_elevated: bool,
	_from_world: Vector2,
	to_world: Vector2
) -> bool:
	var data: CollisionTileData = get_tile_data_at_world(to_world)

	# Convención: vacío = caminable
	if data.empty:
		return true

	if data.bloqueo:
		return false

	# Puente: no bloquea por diferencia de nivel
	if data.no_block:
		return true

	# Conector: siempre se puede pisar
	if data.cambiar_nivel_altura:
		return true

	# Suelo normal: mismo nivel
	return height_level == data.nivel_altura


static func apply_cell_state(controller: CharacterController, world_pos: Vector2) -> void:
	var data: CollisionTileData = get_tile_data_at_world(world_pos)
	if data.empty:
		return

	if data.bloqueo:
		return

	if data.cambiar_nivel_altura:
		# Conector: no fuerza nivel
		return

	if data.no_block:
		# Puente: elevated según el nivel con el que llegamos
		controller.elevated = controller.height_level > 0
		return

	# Suelo normal
	controller.height_level = data.nivel_altura
	controller.elevated = false


static func init_entity_state(controller: CharacterController, world_pos: Vector2) -> void:
	var data: CollisionTileData = get_tile_data_at_world(world_pos)
	if data.empty:
		controller.height_level = 0
		controller.elevated = false
		return

	if data.no_block:
		controller.height_level = data.nivel_altura
		controller.elevated = true
		return

	if data.cambiar_nivel_altura:
		controller.elevated = false
		return

	controller.height_level = data.nivel_altura
	controller.elevated = false
