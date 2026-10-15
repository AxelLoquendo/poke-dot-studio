extends Resource
class_name NewGameConfig
## Dúo de protagonistas + spawn. Editable en el inspector al abrir el .tres.

@export var male_player_data: PlayerData
@export var female_player_data: PlayerData
@export var default_male_name: String = "Rojo"
@export var default_female_name: String = "Hoja"
@export var start_map_id: MapSection.MapID
@export var start_position: Vector2i = Vector2i(5, 5)
