extends Node
## Datos temporales del flujo "Nueva partida". No es el save.

var player_name: String = "Rojo"
var is_male: bool = true

## Plantillas de PlayerData (asigna en el inspector del autoload o carga por ruta).
@export var male_player_data: PlayerData
@export var female_player_data: PlayerData

@export var start_map_id: MapSection.MapID
@export var start_position: Vector2i = Vector2i(5, 5)


func reset() -> void:
	player_name = "Rojo"
	is_male = true


func build_start_data() -> GameStartData:
	var data: GameStartData = GameStartData.new()
	data.start_map_id = start_map_id
	data.start_position = start_position
	var base: PlayerData = male_player_data if is_male else female_player_data
	if base != null:
		var pd: PlayerData = base.duplicate(true) as PlayerData
		# Si CharacterBase tiene nombre:
		if "character_name" in pd:
			pd.character_name = player_name
		elif pd.get("name") != null:
			pd.set("name", player_name)
		data.player_data = pd
	return data
