extends Node
## Un solo slot. Formato: FileAccess store_var (Resource).

const SAVE_PATH: String = "user://save_0.dat"
const SAVE_VERSION: int = 1

signal save_completed(ok: bool)
signal load_completed(ok: bool)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_game(from_session: Node) -> bool:
	var data: SaveData = _capture(from_session)
	if data == null:
		save_completed.emit(false)
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveService: no se pudo escribir %s" % SAVE_PATH)
		save_completed.emit(false)
		return false
	f.store_var(data, true)
	f.close()
	save_completed.emit(true)
	return true


func load_game() -> SaveData:
	if not has_save():
		load_completed.emit(false)
		return null
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		load_completed.emit(false)
		return null
	var data: Variant = f.get_var(true)
	f.close()
	if data is SaveData:
		load_completed.emit(true)
		return data as SaveData
	push_error("SaveService: archivo corrupto o versión incompatible")
	load_completed.emit(false)
	return null


func _capture(session: Node) -> SaveData:
	if session == null:
		return null
	var player: Node2D = session.get_node_or_null("Player") as Node2D
	var factory: MapFactory = session.get_node_or_null("MapFactory") as MapFactory
	if player == null or factory == null:
		return null

	var data: SaveData = SaveData.new()
	data.version = SAVE_VERSION
	data.player_name = NewGameState.player_name
	data.is_male = NewGameState.is_male
	data.position = Vector2i(
		int(round(player.global_position.x / CharacterController.TILE_SIZE)),
		int(round(player.global_position.y / CharacterController.TILE_SIZE))
	)
	# Mapa actual
	if factory.has_method("get_current_map_id"):
		data.map_id = int(factory.call("get_current_map_id"))
	elif factory.get("current_map_id") != null:
		data.map_id = int(factory.get("current_map_id"))
	else:
		# Fallback: SessionBoot / start
		if SessionBoot.start_data != null:
			data.map_id = int(SessionBoot.start_data.start_map_id)

	var character: Character = player.get_node_or_null("Character") as Character
	if character != null and character.data is PlayerData:
		var pd: PlayerData = (character.data as PlayerData).duplicate(true) as PlayerData
		pd.name = data.player_name
		data.player_data = pd
		data.money = pd.money
	return data


## Construye GameStartData para Continuar / carga.
func to_start_data(save: SaveData) -> GameStartData:
	var gs: GameStartData = GameStartData.new()
	gs.start_map_id = save.map_id as MapSection.MapID
	gs.start_position = save.position
	if save.player_data != null:
		gs.player_data = save.player_data.duplicate(true) as PlayerData
	return gs
