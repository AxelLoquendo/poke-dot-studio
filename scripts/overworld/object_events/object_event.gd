extends Node
class_name EventObjects

enum Obj_Event {
	NONE,
	OBJ_EVENT_GFX_PROF_OAK,
	# Valtherion
	OBJ_EVENT_GFX_KAEL_EB,
	OBJ_EVENT_GFX_KAIDA_EB,
	# Kanto
	OBJ_EVENT_GFX_RED_FRLG,
	OBJ_EVENT_GFX_LEAF_FRLG,
	# Johtod
	OBJ_EVENT_GFX_ECO_HGSS,
	OBJ_EVENT_GFX_CRISTI_GPC,
	OBJ_EVENT_GFX_LYRA_HGSS,
	# Hoenn
	OBJ_EVENT_GFX_BRUNO_RSB,
	OBJ_EVENT_GFX_AURA_RSB,
	# Sinnoh
	OBJ_EVENT_GFX_LEON_DP,
	OBJ_EVENT_GFX_MAYA_DP,
	# Unova
	OBJ_EVENT_GFX_LUCHO_BW,
	OBJ_EVENT_GFX_LIZA_BW,
	OBJ_EVENT_GFX_RISSO_B2W2,
	OBJ_EVENT_GFX_NANCI_B2W2,
}

const ow_sprites: Dictionary = {
	Obj_Event.NONE: "",
	Obj_Event.OBJ_EVENT_GFX_PROF_OAK: "res://assets/object_events/npc/profesor_oak.png",
	Obj_Event.OBJ_EVENT_GFX_KAEL_EB: "res://game/assets/object_events/player/male/kael/normal.png",
	Obj_Event.OBJ_EVENT_GFX_KAIDA_EB: "res://game/assets/object_events/player/female/kaida/normal.png",
	Obj_Event.OBJ_EVENT_GFX_RED_FRLG: "res://assets/object_events/player/male/red/normal.png",
	Obj_Event.OBJ_EVENT_GFX_LEAF_FRLG: "res://assets/object_events/player/female/leaf/normal.png",
	Obj_Event.OBJ_EVENT_GFX_ECO_HGSS: "res://assets/object_events/player/male/eco/normal.png",
	Obj_Event.OBJ_EVENT_GFX_CRISTI_GPC: "res://assets/object_events/player/female/cristi/normal.png",
	Obj_Event.OBJ_EVENT_GFX_LYRA_HGSS: "res://assets/object_events/player/female/lyra/normal.png",
	Obj_Event.OBJ_EVENT_GFX_BRUNO_RSB: "res://assets/object_events/player/male/bruno/normal.png",
	Obj_Event.OBJ_EVENT_GFX_AURA_RSB: "res://assets/object_events/player/female/aura/normal.png",
	Obj_Event.OBJ_EVENT_GFX_LEON_DP: "res://assets/object_events/player/male/leon/normal.png",
	Obj_Event.OBJ_EVENT_GFX_MAYA_DP: "res://assets/object_events/player/female/maya/normal.png",
	Obj_Event.OBJ_EVENT_GFX_LUCHO_BW: "res://assets/object_events/player/male/lucho/normal.png",
	Obj_Event.OBJ_EVENT_GFX_LIZA_BW: "res://assets/object_events/player/female/liza/normal.png",
	Obj_Event.OBJ_EVENT_GFX_RISSO_B2W2: "res://assets/object_events/player/male/risso/normal.png",
	Obj_Event.OBJ_EVENT_GFX_NANCI_B2W2: "res://assets/object_events/player/female/nanci/normal.png",

}


const trainer_sprites: Dictionary = {
	Obj_Event.NONE: "",
	Obj_Event.OBJ_EVENT_GFX_KAEL_EB: "res://game/assets/trainers/Kael.png",
	Obj_Event.OBJ_EVENT_GFX_KAIDA_EB: "res://game/assets/trainers/Kaida.png",
}
