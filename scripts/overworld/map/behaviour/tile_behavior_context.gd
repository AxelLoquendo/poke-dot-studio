class_name TileBehaviorContext
extends RefCounted

var controller: CharacterController
var from_world: Vector2 = Vector2.ZERO
var to_world: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var from_behavior: int = TileBehaviorId.Id.NONE
var to_behavior: int = TileBehaviorId.Id.NONE
var jump_animation_played: bool = false
