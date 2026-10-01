extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var player_controller: PlayerController = $PlayerController


func _physics_process(delta: float) -> void:
	player_controller.update_input()
	state.process_state(delta)
	controller.process_movement(delta)
