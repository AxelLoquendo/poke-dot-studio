class_name GameSession
extends Node

const DIALOGUE_BOX_SCENE: PackedScene = preload("res://scenes/ui/dialogue_box/dialogue_box.tscn")

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_factory: MapFactory = $MapFactory


func _ready() -> void:
	_ensure_dialogue_box()
	if start_data == null:
		push_error("GameSession: falta GameStartData")
		return
	_aplicar_datos_player()
	map_factory.load_cluster(
		start_data.start_map_id,
		start_data.start_position,
		player
	)
	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		controller.movement_finished.connect(_on_player_step_finished)


func _ensure_dialogue_box() -> void:
	if DialogueManager.box != null and is_instance_valid(DialogueManager.box):
		return
	var existing: Node = get_tree().get_first_node_in_group(&"dialogue_box")
	if existing != null:
		return
	var box: Node = DIALOGUE_BOX_SCENE.instantiate()
	add_child(box)


func _on_player_step_finished() -> void:
	map_factory.update_current_from_player(player)


func _aplicar_datos_player() -> void:
	if start_data.player_data == null:
		return
	var character: Character = player.get_node_or_null("Character") as Character
	if character != null:
		character.data = start_data.player_data
