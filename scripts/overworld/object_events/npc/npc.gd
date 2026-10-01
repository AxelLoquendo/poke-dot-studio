extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var npc_controller: NpcController = $NpcController
@onready var move_route_controller: MoveRouteController = $MoveRouteController

func _ready() -> void:
	move_route_controller.setup(controller)

func _physics_process(delta: float) -> void:
	npc_controller.process_behavior(delta)
	state.process_state(delta)
	controller.process_movement(delta)
