class_name GameSession
extends Node

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_manager: MapManager = $MapManager
@onready var map_factory: MapFactory = $MapFactory

func _ready() -> void:
	if start_data == null:
		push_error("GameSession: falta GameStartData")
		return
	_aplicar_datos_player()
	map_manager.change_map(start_data.start_map_id, start_data.start_position, player)
	map_factory.load_cluster(start_data.start_map_id, start_data.start_position, player)

func _aplicar_datos_player() -> void:
	if start_data.player_data == null:
		return
	var character: Character = player.get_node_or_null("Character") as Character
	if character != null:
		character.data = start_data.player_data
