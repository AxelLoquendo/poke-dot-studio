class_name MoveStepResult
extends RefCounted
## Resultado de CollisionFacade.resolve_move.

var blocked: bool = false
var target_world: Vector2 = Vector2.ZERO
## Celda usada para TileBehavior (en ledge = casilla B del precipicio).
var behavior_world: Vector2 = Vector2.ZERO
var hop: bool = false
