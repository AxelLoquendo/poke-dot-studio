class_name NPCData
extends CharacterBase

@export var behavior: Behavior = Behavior.NONE

enum Behavior {
	NONE,
	LOOK_AROUND,
	WANDER,
	PATROL,
	FOLLOW,
}
