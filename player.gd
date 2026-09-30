extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	state.process_state(delta)
	controller.process_movement(delta)
