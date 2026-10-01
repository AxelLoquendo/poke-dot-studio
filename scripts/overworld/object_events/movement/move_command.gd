class_name MoveCommand
extends Resource

enum Type {
	MOVE_UP,
	MOVE_DOWN,
	MOVE_LEFT,
	MOVE_RIGHT,

	MOVE_RANDOM,
	MOVE_TOWARD_PLAYER,
	MOVE_AWAY_FROM_PLAYER,
	MOVE_FORWARD,
	MOVE_BACKWARD,

	TURN_UP,
	TURN_DOWN,
	TURN_LEFT,
	TURN_RIGHT,

	WAIT,
}

@export var type: Type = Type.MOVE_DOWN
@export var parameter: float = 0.0
