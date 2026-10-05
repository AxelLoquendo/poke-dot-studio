extends Node2D

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var player_controller: PlayerController = $PlayerController
@onready var character_visual: Character = $Character


func _ready() -> void:
	_aplicar_walk()

func _physics_process(delta: float) -> void:
	player_controller.update_input()
	state.process_state(delta)
	controller.process_movement(delta)

func _aplicar_walk() -> void:
	if character_visual == null or character_visual.data == null:
		return
	var data: PlayerData = character_visual.data as PlayerData
	if data == null:
		return
	if data.walk <= 0.0:
		return
	controller.set_move_speed(data.walk * CharacterController.TILE_SIZE)
