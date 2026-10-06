class_name CollisionFacade
extends RefCounted
## Fachada: entidad OR tile.
## CharacterController solo habla con esta clase.


static func is_blocked(controller: CharacterController, target_world: Vector2) -> bool:
	if EntityCollisionSystem.is_position_occupied(target_world, controller):
		return true

	if not MapCollisionSystem.can_enter(
		controller.height_level,
		controller.elevated,
		controller.get_character_position(),
		target_world
	):
		return true

	return false
