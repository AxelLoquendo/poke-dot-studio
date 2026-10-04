class_name MapSection
extends RefCounted

enum MapID {
	NONE,
	MAPSEC_PUEBLO_INICIO,
	MAPSEC_RUTA_1,
	MAPSEC_CIUDAD_LUGANO,
	MAPSEC_RUTA_2,
}

enum RegionID {
	NONE,
	KANTO,
	JHOTO,
	HOENN,
	SINNOH,
	TESELIA,
	KALOS,
	ALOLA,
	GALAR,
	PALDEA
}

const MAP_SCENES: Dictionary = {
	MapID.MAPSEC_PUEBLO_INICIO: "res://scenes/overworld/map/pueblo_inicio/pueblo_inicio.tscn",
	MapID.MAPSEC_RUTA_1: "res://scenes/overworld/map/ruta_1/ruta_1.tscn",
	MapID.MAPSEC_CIUDAD_LUGANO: "res://scenes/overworld/map/ciudad_lugano/ciudad_lugano.tscn",
	MapID.MAPSEC_RUTA_2: "res://scenes/overworld/map/ruta_2/ruta_2.tscn",
}
