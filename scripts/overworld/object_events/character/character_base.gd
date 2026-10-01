class_name CharacterBase
extends Resource

@export var id: StringName = ""
@export var ow: EventObjects.Obj_Event = EventObjects.Obj_Event.NONE
@export var name: String
@export var money: int = 0
@export var shadow_type: shadow = shadow.NONE
@export var shadow_coor: Vector2

enum shadow {NONE, S, M, L, XL}

const shadow_sprites: Dictionary = {
	shadow.NONE: "",
	shadow.S: "res://assets/object_events/shadow/shadow_small.png",
	shadow.M: "res://assets/object_events/shadow/shadow_medium.png",
	shadow.L: "res://assets/object_events/shadow/shadow_large.png",
	shadow.XL: "res://assets/object_events/shadow/shadow_extra_large.png"
}
