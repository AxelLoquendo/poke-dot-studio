class_name NPCData
extends CharacterBase

@export var behavior: Behavior = Behavior.NONE
@export var move_route: MoveRoute
## Tiles por segundo
@export var walk: float = 4.0
## Script de overworld (.txt). Vacío = no interactúa por script.
@export_file("*.txt") var script_file: String = ""

enum Behavior {
	NONE,
	LOOK_AROUND,
	WANDER,
	PATROL,
	FOLLOW,
}
