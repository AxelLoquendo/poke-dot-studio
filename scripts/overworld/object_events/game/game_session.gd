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
	map_factory.cluster_loaded.connect(_on_cluster_loaded)
	map_factory.current_changed.connect(_on_current_changed)
	map_factory.load_cluster(start_data.start_map_id, start_data.start_position, player)
	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		controller.movement_finished.connect(_on_player_step_finished)
	if FadeScreen.is_covered():
		await FadeScreen.fade_in(0.4)
	if SessionBoot.start_data != null:
		start_data = SessionBoot.start_data
		SessionBoot.start_data = null
	if start_data == null:
		push_error("GameSession: falta GameStartData")
		return

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

func _on_cluster_loaded(mapa: Map) -> void:
	_apply_day_night_for_map(mapa)
	if _signpost != null:
		_signpost.try_show_for_map(mapa)
	MapScriptService.trigger(mapa, MapScriptEntry.Trigger.ON_LOAD, player)
	MapScriptService.trigger(mapa, MapScriptEntry.Trigger.ON_TRANSITION, player)


func _on_current_changed(mapa: Map) -> void:
	_apply_day_night_for_map(mapa)
	if _signpost != null:
		_signpost.try_show_for_map(mapa)
	MapScriptService.trigger(mapa, MapScriptEntry.Trigger.ON_TRANSITION, player)


func _apply_day_night_for_map(mapa: Map) -> void:
	if mapa == null or mapa.attributes == null:
		DayNightManager.set_outdoor(true)
		return
	# Interiores: sin tinte (como v2)
	DayNightManager.set_outdoor(not mapa.attributes.is_indoor)
