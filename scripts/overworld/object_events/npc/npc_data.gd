class_name NPCData
extends CharacterBase

@export var behavior: Behavior = Behavior.NONE
@export var move_route: MoveRoute

enum Behavior {
	NONE,
	LOOK_AROUND,
	WANDER,
	PATROL,
	FOLLOW,
}
