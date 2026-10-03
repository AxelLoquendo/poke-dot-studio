class_name MapSection
extends RefCounted

enum MapID {
	MAPSEC_PALLET_TOWN,
	MAPSEC_ROUTE_1,
}

enum RegionID {
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
	MapID.MAPSEC_PALLET_TOWN: "res://maps/kanto/pallet_town.tscn",
	MapID.MAPSEC_ROUTE_1: "res://maps/kanto/route_1.tscn",
}
