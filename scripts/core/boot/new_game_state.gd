extends Node
## Autoload NewGameState

const CONFIG_PATH: String = "res://data/resources/boot/new_game_config.tres"

var player_name: String = "Rojo"
var is_male: bool = true
var config: NewGameConfig


func _ready() -> void:
	if ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH) as NewGameConfig
	else:
		push_error("NewGameState: falta %s" % CONFIG_PATH)


func reset() -> void:
	is_male = true
	if config != null:
		player_name = config.default_male_name
	else:
		player_name = "Rojo"


func get_player_template() -> PlayerData:
	if config == null:
		return null
	return config.male_player_data if is_male else config.female_player_data


func build_start_data() -> GameStartData:
	var data: GameStartData = GameStartData.new()
	if config != null:
		data.start_map_id = config.start_map_id
		data.start_position = config.start_position
	var base: PlayerData = get_player_template()
	if base != null:
		var pd: PlayerData = base.duplicate(true) as PlayerData
		pd.name = player_name
		data.player_data = pd
	return data
