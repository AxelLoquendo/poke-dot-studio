class_name NpcController
extends Node2D

@onready var character: Character = $"../Character"
@onready var character_controller: CharacterController = $"../CharacterController"

# ============================================================
# CONSTANTES
# ============================================================
const LOOK_AROUND_DELAY: float = 0.8
const WANDER_DELAY: float = 0.8

# ============================================================
# VARIABLES
# ============================================================
var npc_data: NPCData

var look_around_timer: float = 0.0
var wander_timer: float = 0.0

# ============================================================
# INICIALIZACIÓN
# ============================================================

func _ready() -> void:
	npc_data = character.data as NPCData

	character_controller.movement_finished.connect(_on_movement_finished)

# ============================================================
# COMPORTAMIENTO
# ============================================================

func process_behavior(delta: float) -> void:
	if npc_data == null:
		return

	match npc_data.behavior:
		NPCData.Behavior.NONE:
			process_none(delta)

		NPCData.Behavior.LOOK_AROUND:
			process_look_around(delta)

		NPCData.Behavior.WANDER:
			process_wander(delta)

		NPCData.Behavior.PATROL:
			process_patrol(delta)

		NPCData.Behavior.FOLLOW:
			process_follow(delta)

# ============================================================
# COMPORTAMIENTOS
# ============================================================

func process_none(_delta: float) -> void:
	pass


func process_look_around(delta: float) -> void:
	if look_around_timer > 0.0:
		look_around_timer -= delta
		return

	var directions: Array[Vector2] = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]

	var direction: Vector2 = directions.pick_random()

	character_controller.look_direction(direction)

	look_around_timer = LOOK_AROUND_DELAY


func process_wander(delta: float) -> void:
	if character_controller.moving:
		return

	if wander_timer > 0.0:
		wander_timer -= delta
		return

	var directions: Array[Vector2] = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]

	var direction: Vector2 = directions.pick_random()

	character_controller.request_move(direction)

	wander_timer = WANDER_DELAY

func process_patrol(_delta: float) -> void:
	pass


func process_follow(_delta: float) -> void:
	pass

# ============================================================
# MOVIMIENTO
# ============================================================

func _on_movement_finished() -> void:
	pass
