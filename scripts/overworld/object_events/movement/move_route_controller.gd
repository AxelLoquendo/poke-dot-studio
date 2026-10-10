class_name MoveRouteController
extends Node

var character_controller: CharacterController
var route: MoveRoute
var current_command: int = 0
var executing: bool = false
var retry_pending: bool = false
var pending_direction: Vector2 = Vector2.ZERO
var _paused: bool = false
var _run_id: int = 0

const BLOCK_RETRY_DELAY: float = 0.25


func setup(controller: CharacterController) -> void:
	if character_controller != null:
		if character_controller.movement_finished.is_connected(_on_movement_finished):
			character_controller.movement_finished.disconnect(_on_movement_finished)
		if character_controller.movement_blocked.is_connected(_on_movement_blocked):
			character_controller.movement_blocked.disconnect(_on_movement_blocked)
	character_controller = controller
	if character_controller != null:
		character_controller.movement_finished.connect(_on_movement_finished)
		character_controller.movement_blocked.connect(_on_movement_blocked)


func start_route(new_route: MoveRoute) -> void:
	if character_controller == null or new_route == null:
		return
	if new_route.commands.is_empty():
		return
	route = new_route
	current_command = 0
	executing = true
	retry_pending = false
	pending_direction = Vector2.ZERO
	_paused = false
	_run_id += 1
	call_deferred("execute_next_command")


func stop_route() -> void:
	executing = false
	retry_pending = false
	pending_direction = Vector2.ZERO
	_paused = false
	_run_id += 1
	route = null
	current_command = 0


func pause_route() -> void:
	_paused = route != null
	executing = false
	retry_pending = false
	pending_direction = Vector2.ZERO
	_run_id += 1


func has_route() -> bool:
	return route != null


func complete_current_command() -> void:
	if route == null:
		return
	current_command += 1
	pending_direction = Vector2.ZERO


func resume_route() -> void:
	if not _paused or route == null:
		return
	_paused = false
	executing = true
	retry_pending = false
	call_deferred("execute_next_command")


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
	pending_direction = Vector2.ZERO
	match command.type:
		MoveCommand.Type.MOVE_UP:
			_request_and_remember(Vector2.UP)
		MoveCommand.Type.MOVE_DOWN:
			_request_and_remember(Vector2.DOWN)
		MoveCommand.Type.MOVE_LEFT:
			_request_and_remember(Vector2.LEFT)
		MoveCommand.Type.MOVE_RIGHT:
			_request_and_remember(Vector2.RIGHT)
		MoveCommand.Type.MOVE_RANDOM:
			var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
			_request_and_remember(directions.pick_random())
		MoveCommand.Type.MOVE_FORWARD:
			_request_and_remember(character_controller.last_direction)
		MoveCommand.Type.MOVE_BACKWARD:
			_request_and_remember(-character_controller.last_direction)
		MoveCommand.Type.MOVE_TOWARD_PLAYER:
			var toward: Vector2 = get_direction_to_player()
			if toward == Vector2.ZERO:
				_advance_command()
			else:
				_request_and_remember(toward)
		MoveCommand.Type.MOVE_AWAY_FROM_PLAYER:
			var away: Vector2 = get_direction_away_from_player()
			if away == Vector2.ZERO:
				_advance_command()
			else:
				_request_and_remember(away)
		MoveCommand.Type.TURN_UP:
			character_controller.look_direction(Vector2.UP)
			_advance_command()
		MoveCommand.Type.TURN_DOWN:
			character_controller.look_direction(Vector2.DOWN)
			_advance_command()
		MoveCommand.Type.TURN_LEFT:
			character_controller.look_direction(Vector2.LEFT)
			_advance_command()
		MoveCommand.Type.TURN_RIGHT:
			character_controller.look_direction(Vector2.RIGHT)
			_advance_command()
		MoveCommand.Type.WAIT:
			start_wait(command.parameter)
		_:
			_advance_command()


func _request_and_remember(direction: Vector2) -> void:
	pending_direction = direction
	character_controller.request_move(direction)


func _advance_command() -> void:
	if not executing:
		return
	current_command += 1
	pending_direction = Vector2.ZERO
	call_deferred("execute_next_command")


func _on_movement_finished() -> void:
	if not executing:
		return
	pending_direction = Vector2.ZERO
	_advance_command()


func _on_movement_blocked() -> void:
	if not executing or retry_pending:
		return
	if pending_direction == Vector2.ZERO:
		return
	retry_pending = true
	_retry_after_block()


func _retry_after_block() -> void:
	var id: int = _run_id
	await get_tree().create_timer(BLOCK_RETRY_DELAY).timeout
	retry_pending = false
	if not executing or id != _run_id:
		return
	if pending_direction == Vector2.ZERO:
		return
	character_controller.request_move(pending_direction)


func start_wait(duration: float) -> void:
	var id: int = _run_id
	var wait_time: float = maxf(duration, 0.01)
	await get_tree().create_timer(wait_time).timeout
	if not executing or id != _run_id:
		return
	_advance_command()


func get_direction_to_player() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	var player_controller: CharacterController = player.get_node_or_null("CharacterController") as CharacterController
	if player_controller == null or character_controller == null:
		return Vector2.ZERO
	var offset: Vector2 = player_controller.get_character_position() - character_controller.get_character_position()
	if absf(offset.x) > absf(offset.y):
		return Vector2.RIGHT if offset.x > 0.0 else Vector2.LEFT
	if offset.y != 0.0:
		return Vector2.DOWN if offset.y > 0.0 else Vector2.UP
	return Vector2.ZERO


func get_direction_away_from_player() -> Vector2:
	var toward: Vector2 = get_direction_to_player()
	if toward == Vector2.ZERO:
		return Vector2.ZERO
	return -toward
