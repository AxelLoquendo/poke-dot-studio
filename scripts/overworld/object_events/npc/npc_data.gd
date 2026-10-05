class_name NPCData
extends CharacterBase

@export var behavior: Behavior = Behavior.NONE
@export var move_route: MoveRoute
## Tiles por segundo
@export var walk: float = 4.0

enum Behavior {
	NONE,
	LOOK_AROUND,
	WANDER,
	PATROL,
	FOLLOW,
}
