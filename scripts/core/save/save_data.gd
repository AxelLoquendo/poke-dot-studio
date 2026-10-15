extends Resource
class_name SaveData
## Snapshot serializable de una partida.

@export var version: int = 1
@export var player_name: String = ""
@export var is_male: bool = true
@export var map_id: int = 0
@export var map_name: String = ""
@export var position: Vector2i = Vector2i.ZERO
@export var money: int = 0
@export var play_seconds: float = 0.0
@export var player_data: PlayerData
