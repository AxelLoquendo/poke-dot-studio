extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var npc_controller: NpcController = $NpcController


func _physics_process(delta: float) -> void:
	npc_controller.process_behavior(delta)
	state.process_state(delta)
	controller.process_movement(delta)
