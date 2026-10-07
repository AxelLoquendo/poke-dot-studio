@tool
extends Node2D

@export var data: NPCData:
	set(value):
		data = value
		_aplicar_data()

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var npc_controller: NpcController = $NpcController
@onready var move_route_controller: MoveRouteController = $MoveRouteController
@onready var character_visual: Character = $Character

func _ready() -> void:
	_aplicar_data()
	if Engine.is_editor_hint():
		return
	move_route_controller.setup(controller)
	_aplicar_walk()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	npc_controller.process_behavior(delta)
	state.process_state(delta)
	controller.process_movement(delta)

func _aplicar_data() -> void:
	# En editor @onready puede no estar listo aún
	var visual: Character = character_visual
	if visual == null:
		visual = get_node_or_null("Character") as Character
	if visual == null:
		return
	if data == null:
		return
	visual.data = data
	if Engine.is_editor_hint():
		return
	if npc_controller != null:
		npc_controller.set_npc_data(data)

func _aplicar_walk() -> void:
	if Engine.is_editor_hint():
		return
	if data == null or controller == null:
		return
	if data.walk <= 0.0:
		return
	controller.set_move_speed(data.walk * CharacterController.TILE_SIZE)
