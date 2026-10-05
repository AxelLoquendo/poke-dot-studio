extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var npc_controller: NpcController = $NpcController
@onready var move_route_controller: MoveRouteController = $MoveRouteController
@onready var character_visual: Character = $Character


func _ready() -> void:
	move_route_controller.setup(controller)
	_aplicar_walk()

func _physics_process(delta: float) -> void:
	npc_controller.process_behavior(delta)
	state.process_state(delta)
	controller.process_movement(delta)

func _aplicar_walk() -> void:
	if character_visual == null or character_visual.data == null:
		return
	var data: NPCData = character_visual.data as NPCData
	if data == null:
		return
	if data.walk <= 0.0:
		return
	# walk en tiles/s → px/s
	controller.set_move_speed(data.walk * CharacterController.TILE_SIZE)
