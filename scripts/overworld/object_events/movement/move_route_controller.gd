class_name MoveRouteController
extends Node

# ============================================================
# VARIABLES
# ============================================================
var character_controller: CharacterController
var route: MoveRoute
var current_command: int = 0
var executing: bool = false

func setup(controller: CharacterController) -> void:
	if character_controller != null:
		character_controller.movement_finished.disconnect(_on_movement_finished)
	character_controller = controller
	if character_controller != null:
		character_controller.movement_finished.connect(_on_movement_finished)

func start_route(new_route: MoveRoute) -> void:
	if character_controller == null:
		return
	if new_route == null:
		return
	if new_route.commands.is_empty():
		return

	route = new_route
	current_command = 0
	executing = true
	execute_next_command()

func stop_route() -> void:
	executing = false
	route = null
	current_command = 0

func execute_next_command() -> void:
	if not executing:
		return
	if route == null:
		stop_route()
		return
	if current_command >= route.commands.size():
		if route.loop:
			current_command = 0
		else:
			stop_route()
			return
	var command: MoveCommand = route.commands[current_command]
	execute_command(command)

func execute_command(command: MoveCommand) -> void:
	match command.type:
		MoveCommand.Type.MOVE_UP:
			character_controller.request_move(Vector2.UP)
		MoveCommand.Type.MOVE_DOWN:
			character_controller.request_move(Vector2.DOWN)
		MoveCommand.Type.MOVE_LEFT:
			character_controller.request_move(Vector2.LEFT)
		MoveCommand.Type.MOVE_RIGHT:
			character_controller.request_move(Vector2.RIGHT)
		MoveCommand.Type.MOVE_RANDOM:
			var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			character_controller.request_move(directions.pick_random())
		MoveCommand.Type.MOVE_FORWARD:
			character_controller.request_move(character_controller.last_direction)
		MoveCommand.Type.MOVE_TOWARD_PLAYER:
			var direction: Vector2 = get_direction_to_player()
			if direction == Vector2.ZERO:
				finish_command()
			else:
				character_controller.request_move(direction)
		MoveCommand.Type.MOVE_AWAY_FROM_PLAYER:
			var direction: Vector2 = get_direction_away_from_player()
			if direction == Vector2.ZERO:
				finish_command()
			else:
				character_controller.request_move(direction)
		MoveCommand.Type.TURN_UP:
			character_controller.look_direction(Vector2.UP)
			finish_command()
		MoveCommand.Type.MOVE_BACKWARD:
			character_controller.request_move(-character_controller.last_direction)
		MoveCommand.Type.TURN_DOWN:
			character_controller.look_direction(Vector2.DOWN)
			finish_command()
		MoveCommand.Type.TURN_LEFT:
			character_controller.look_direction(Vector2.LEFT)
			finish_command()
		MoveCommand.Type.TURN_RIGHT:
			character_controller.look_direction(Vector2.RIGHT)
			finish_command()
		MoveCommand.Type.WAIT:
			start_wait(command.parameter)
		_:
			finish_command()

func finish_command() -> void:
	if not executing:
		return
	current_command += 1
	execute_next_command()

func _on_movement_finished() -> void:
	if not executing:
		return
	finish_command()

func start_wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if not executing:
		return
	finish_command()

func get_direction_to_player() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	var player_controller: CharacterController = \
		player.get_node("CharacterController") as CharacterController
	if player_controller == null:
		return Vector2.ZERO
	var player_position: Vector2 = player_controller.get_character_position()
	var character_position: Vector2 = character_controller.get_character_position()
	var offset: Vector2 = player_position - character_position
	if abs(offset.x) > abs(offset.y):
		return Vector2.RIGHT if offset.x > 0.0 else Vector2.LEFT
	if offset.y != 0.0:
		return Vector2.DOWN if offset.y > 0.0 else Vector2.UP
	return Vector2.ZERO

func get_direction_away_from_player() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D

	if player == null:
		return Vector2.ZERO

	var player_controller: CharacterController = \
		player.get_node("CharacterController") as CharacterController

	if player_controller == null:
		return Vector2.ZERO

	var player_position: Vector2 = player_controller.get_character_position()
	var character_position: Vector2 = character_controller.get_character_position()

	var offset: Vector2 = player_position - character_position

	if offset == Vector2.ZERO:
		return Vector2.ZERO

	if abs(offset.x) > abs(offset.y):
		return Vector2.LEFT if offset.x > 0.0 else Vector2.RIGHT

	return Vector2.UP if offset.y > 0.0 else Vector2.DOWN
