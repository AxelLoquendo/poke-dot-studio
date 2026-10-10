class_name MapAttributes
extends Resource

@export var map_id: MapSection.MapID
@export var region_id: MapSection.RegionID
@export var map_name: String = ""
@export var map_music: SFXGame.MapMusicID = SFXGame.MapMusicID.BGM_NONE
@export var map_size: Vector2i
#@export var battle_scene: BattleBackground.Background
@export var show_location_name: bool = false
@export var is_indoor: bool = false
@export var allow_dig_escape_rope: bool = false
@export var allow_fly: bool = false
@export var requires_flash: bool = false
@export var weather: WeatherID.Id = WeatherID.Id.NONE
@export_range(0, 9) var weather_intensity: int = 0
#@export var grass_encounters: WildEncounterTable

@export var connections: Array[MapConnectionEntry] = []
