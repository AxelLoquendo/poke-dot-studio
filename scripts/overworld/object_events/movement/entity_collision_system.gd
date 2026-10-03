class_name EntityCollisionSystem
extends RefCounted

const TILE_SIZE: float = 16.0


static func to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(roundi(world_pos.x / TILE_SIZE), roundi(world_pos.y / TILE_SIZE))

static func is_position_occupied(position: Vector2, excluded_character: CharacterController = null) -> bool:
	var target_tile: Vector2i = to_tile(position)
	var groups: Array[StringName] = [&"Player", &"Npc"]
	for group: StringName in groups:
		var entities: Array[Node] = Engine.get_main_loop().root.get_tree().get_nodes_in_group(group)
		for entity: Node in entities:
			var controller: CharacterController = \
				entity.get_node_or_null("CharacterController") as CharacterController
			if controller == null:
				continue
			if controller == excluded_character:
				continue
			# Casilla lógica actual (en movimiento = origen hasta que termina)
			if to_tile(controller.current_position) == target_tile:
				return true
			# Destino reservado mientras camina
			if controller.moving and to_tile(controller.target_position) == target_tile:
				return true
	return false
