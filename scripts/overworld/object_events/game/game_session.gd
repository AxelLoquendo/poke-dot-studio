class_name GameSession
extends Node

@export var start_data: GameStartData

@onready var player: Node2D = $Player
@onready var map_factory: MapFactory = $MapFactory

var _signpost: LocationSignpost
var _pause_menu: PauseMenu
var play_seconds: float = 0.0
var party: Party = Party.new()

func _ready() -> void:
	_ensure_message_ui()
	_ensure_signpost()
	_ensure_pause_menu()
	add_to_group(&"game_session")

	if SessionBoot.start_data != null:
		start_data = SessionBoot.start_data
		SessionBoot.start_data = null

	play_seconds = SessionBoot.loaded_play_seconds
	SessionBoot.loaded_play_seconds = 0.0

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
	party.add(Pokemon.create(&"BULBASAUR", 5))
	party.add(Pokemon.create(&"SPRIGATITO", 5))

func _process(delta: float) -> void:
	if MessageService.is_active():
		return
	if _pause_menu != null and _pause_menu.is_open():
		return
	play_seconds += delta


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


func _ensure_pause_menu() -> void:
	_pause_menu = PauseMenu.new()
	_pause_menu.name = "PauseMenu"
	add_child(_pause_menu)


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
	DayNightManager.set_outdoor(not mapa.attributes.is_indoor)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("buttonStart"):
		if MessageService.is_active():
			return
		if _pause_menu != null and _pause_menu.is_open():
			return
		if _pause_menu != null:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()
