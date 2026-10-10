class_name MapSection
extends RefCounted

enum MapID {
	NONE,
	MAPSEC_PUEBLO_INICIO,
	MAPSEC_RUTA_1,
	MAPSEC_CIUDAD_LUGANO,
	MAPSEC_RUTA_2,
	MAPSEC_AFUERAS_ZONA_SAFARI,
	MAPSEC_PUEBLO_MACABEO,
	MAPSEC_PARQUE_NATURAL,
	MAPSEC_RUTA_3,
	MAPSEC_MESETA_A_IL_EXTERIOR,
	MAPSEC_RUTA_4,
	MAPSEC_RUTA_5,
	MAPSEC_RUTA_6,
	MAPSEC_RUTA_7,
	MAPSEC_FRENTE_DE_BATALLA,
	MAPSEC_RUTA_8,
	MAPSEC_ISLA_ORIGEN,
	MAPSEC_ISLA_DYSON,
	MAPSEC_REGION_TIALL,
	MAPSEC_MAPA_DE_SCRIPTS,
	MAPSEC_EVENTS_UTILITIES,
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
	MapID.MAPSEC_AFUERAS_ZONA_SAFARI: "res://scenes/overworld/map/afueras_zona_safari/afueras_zona_safari.tscn",
	MapID.MAPSEC_PUEBLO_MACABEO: "res://scenes/overworld/map/pueblo_macabeo/pueblo_macabeo.tscn",
	MapID.MAPSEC_PARQUE_NATURAL: "res://scenes/overworld/map/parque_natural/parque_natural.tscn",
	MapID.MAPSEC_RUTA_3: "res://scenes/overworld/map/ruta_3/ruta_3.tscn",
	MapID.MAPSEC_MESETA_A_IL_EXTERIOR: "res://scenes/overworld/map/meseta_añil_exterior/meseta_añil_exterior.tscn",
	MapID.MAPSEC_RUTA_4: "res://scenes/overworld/map/ruta_4/ruta_4.tscn",
	MapID.MAPSEC_RUTA_5: "res://scenes/overworld/map/ruta_5/ruta_5.tscn",
	MapID.MAPSEC_RUTA_6: "res://scenes/overworld/map/ruta_6/ruta_6.tscn",
	MapID.MAPSEC_RUTA_7: "res://scenes/overworld/map/ruta_7/ruta_7.tscn",
	MapID.MAPSEC_FRENTE_DE_BATALLA: "res://scenes/overworld/map/frente_de_batalla/frente_de_batalla.tscn",
	MapID.MAPSEC_RUTA_8: "res://scenes/overworld/map/ruta_8/ruta_8.tscn",
	MapID.MAPSEC_ISLA_ORIGEN: "res://scenes/overworld/map/isla_origen/isla_origen.tscn",
	MapID.MAPSEC_ISLA_DYSON: "res://scenes/overworld/map/isla_dyson/isla_dyson.tscn",
	MapID.MAPSEC_REGION_TIALL: "res://scenes/overworld/map/region_tiall/region_tiall.tscn",
	MapID.MAPSEC_MAPA_DE_SCRIPTS: "res://scenes/overworld/map/mapa_de_scripts/mapa_de_scripts.tscn",
	MapID.MAPSEC_EVENTS_UTILITIES: "res://scenes/overworld/map/events_utilities/events_utilities.tscn",
}
