class_name MapAttributes
extends Resource

@export var map_id: MapSection.MapID
@export var region_id: MapSection.RegionID
@export var map_name: String = ""
@export var map_music: SFXGame.MapMusicID = SFXGame.MapMusicID.BGM_NONE
@export var map_size: Vector2i
#@export var battle_scene: BattleBackground.Background
@export var show_location_name: bool = false
@export var location_style: LocationStyle = LocationStyle.HGSS
@export var location_type: LocationType = LocationType.DEFAULT
@export var is_indoor: bool = false
@export var allow_dig_escape_rope: bool = false
@export var allow_fly: bool = false
@export var requires_flash: bool = false
@export var weather: WeatherID.Id = WeatherID.Id.NONE
@export_range(0, 9) var weather_intensity: int = 0
#@export var grass_encounters: WildEncounterTable

@export var connections: Array[MapConnectionEntry] = []

@export_group("Map Script")
@export_file("*.txt") var map_script: String = ""  ## compat: se trata como ON_LOAD
@export var map_scripts: Array[MapScriptEntry] = []

enum LocationStyle {
	HGSS,
	PLATINUM,
	DP,
	ORAS,
	XY,
}

enum LocationType {
	DEFAULT,
	TOWN,
	CITY,
	ROUTE,
	FOREST,
	CAVE,
	LAKE,
	PARK,
	SEA,
}
