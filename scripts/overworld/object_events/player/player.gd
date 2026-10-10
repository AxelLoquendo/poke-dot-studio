extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var player_controller: PlayerController = $PlayerController
@onready var character_visual: Character = $Character

var _script_locked: bool = false


func _ready() -> void:
	add_to_group(&"player")
	_aplicar_walk()


func _physics_process(delta: float) -> void:
	if _script_locked or MessageService.is_active():
		# Sigue animación idle si hace falta, pero sin input de movimiento
		if not _script_locked:
			pass
		state.process_state(delta)
		# No process_movement con input: limpiamos dirección
		controller.set_direction(Vector2.ZERO)
		controller.process_movement(delta)
		return
	player_controller.update_input()
	state.process_state(delta)
	controller.process_movement(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _script_locked or MessageService.is_active():
		return
	if not event.is_action_pressed("buttonA"):
		return
	if controller.moving:
		return
	var npc: Node2D = _find_facing_npc()
	if npc != null and npc.has_method("interact"):
		npc.call("interact", self)
		get_viewport().set_input_as_handled()


func set_script_locked(locked: bool) -> void:
	_script_locked = locked
	if locked:
		controller.set_direction(Vector2.ZERO)


func _aplicar_walk() -> void:
	if character_visual == null or character_visual.data == null:
		return
	var data: PlayerData = character_visual.data as PlayerData
	if data == null:
		return
	if data.walk <= 0.0:
		return
	controller.set_move_speed(data.walk * CharacterController.TILE_SIZE)


func _find_facing_npc() -> Node2D:
	var facing: Vector2 = controller.last_direction
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN
	var front: Vector2 = controller.get_character_position() + facing * CharacterController.TILE_SIZE
	var front_tile: Vector2i = Vector2i(
		int(round(front.x / CharacterController.TILE_SIZE)),
		int(round(front.y / CharacterController.TILE_SIZE))
	)
	for node: Node in get_tree().get_nodes_in_group(&"npc"):
		var npc: Node2D = node as Node2D
		if npc == null:
			continue
		if not npc.has_method("can_interact"):
			continue
		if not npc.call("can_interact"):
			continue
		var npc_tile: Vector2i
		if npc.has_method("get_tile_position"):
			npc_tile = npc.call("get_tile_position") as Vector2i
		else:
			npc_tile = Vector2i(
				int(round(npc.global_position.x / CharacterController.TILE_SIZE)),
				int(round(npc.global_position.y / CharacterController.TILE_SIZE))
			)
		if npc_tile == front_tile:
			return npc
	return null
