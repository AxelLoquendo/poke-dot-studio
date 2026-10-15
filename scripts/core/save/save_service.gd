extends Node
## Autoload SaveService

const SAVE_PATH: String = "user://save_0.tres"
const SAVE_VERSION: int = 1

signal save_completed(ok: bool)
signal load_completed(ok: bool)


func has_save() -> bool:
	return ResourceLoader.exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func save_game(from_session: Node) -> bool:
	var data: SaveData = _capture(from_session)
	if data == null:
		push_error("SaveService: capture null (revisa Player / MapFactory)")
		save_completed.emit(false)
		return false

	var err: Error = ResourceSaver.save(data, SAVE_PATH)
	if err != OK:
		push_error("SaveService: ResourceSaver error %s → %s" % [str(err), SAVE_PATH])
		save_completed.emit(false)
		return false

	save_completed.emit(true)
	return true


func load_game() -> SaveData:
	if not has_save():
		load_completed.emit(false)
		return null
	var res: Resource = load(SAVE_PATH) as Resource
	if res is SaveData:
		load_completed.emit(true)
		return res as SaveData
	push_error("SaveService: no es SaveData válido")
	load_completed.emit(false)
	return null


func _capture(session: Node) -> SaveData:
	if session == null:
		push_error("SaveService: session null")
		return null

	# Player: hijo o grupo
	var player: Node2D = session.get_node_or_null("Player") as Node2D
	if player == null:
		player = session.get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		push_error("SaveService: no hay Player")
		return null

	# MapFactory: sin forzar cast (Node basta)
	var factory: Node = session.get_node_or_null("MapFactory")
	if factory == null:
		factory = session.get_tree().get_first_node_in_group(&"map_factory")
	if factory == null:
		push_error("SaveService: no hay MapFactory")
		return null

	var data: SaveData = SaveData.new()
	data.version = SAVE_VERSION
	data.is_male = NewGameState.is_male

	var tile: float = 16.0
	if CharacterController != null:
		tile = float(CharacterController.TILE_SIZE)
	data.position = Vector2i(
		int(round(player.global_position.x / tile)),
		int(round(player.global_position.y / tile))
	)

	var map_id: int = 0
	if factory.has_method("get_current_map_id"):
		map_id = int(factory.call("get_current_map_id"))
	elif "current_map_id" in factory:
		map_id = int(factory.get("current_map_id"))
	data.map_id = map_id

	var character: Character = player.get_node_or_null("Character") as Character
	if character != null and character.data is PlayerData:
		var pd: PlayerData = (character.data as PlayerData).duplicate(true) as PlayerData
		if pd.name.strip_edges().is_empty():
			pd.name = NewGameState.player_name
		data.player_name = pd.name
		data.player_data = pd
		data.money = pd.money
	else:
		data.player_name = NewGameState.player_name
		# Sin PlayerData igual guardamos mapa/posición/nombre
		data.player_data = null
		push_warning("SaveService: sin PlayerData en Character (se guarda igual)")

	if not data.player_name.is_empty():
		NewGameState.player_name = data.player_name

	print("SaveService: map=%s pos=%s name=%s" % [data.map_id, data.position, data.player_name])
	return data


func to_start_data(save: SaveData) -> GameStartData:
	var gs: GameStartData = GameStartData.new()
	gs.start_map_id = save.map_id as MapSection.MapID
	gs.start_position = save.position
	if save.player_data != null:
		var pd: PlayerData = save.player_data.duplicate(true) as PlayerData
		if pd.name.strip_edges().is_empty():
			pd.name = save.player_name
		gs.player_data = pd
	return gs
