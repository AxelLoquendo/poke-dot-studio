class_name GameSession
extends Node

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_factory: MapFactory = $MapFactory

var _signpost: LocationSignpost


func _ready() -> void:
	_ensure_message_ui()
	_ensure_signpost()

	if start_data == null:
		push_error("GameSession: falta GameStartData")
		return

	_aplicar_datos_player()

	map_factory.cluster_loaded.connect(_on_map_announce)
	map_factory.current_changed.connect(_on_map_announce)

	map_factory.load_cluster(
		start_data.start_map_id,
		start_data.start_position,
		player
	)

	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		controller.movement_finished.connect(_on_player_step_finished)


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)


func _ensure_signpost() -> void:
	_signpost = LocationSignpost.new()
	_signpost.name = "LocationSignpost"
	add_child(_signpost)


func _on_map_announce(mapa: Map) -> void:
	if _signpost != null:
		_signpost.try_show_for_map(mapa)


func _on_player_step_finished() -> void:
	map_factory.update_current_from_player(player)
	MapEventResolver.try_step(player, map_factory)


func _aplicar_datos_player() -> void:
	if start_data.player_data == null:
		return
	var character: Character = player.get_node_or_null("Character") as Character
	if character != null:
		character.data = start_data.player_data
