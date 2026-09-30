class_name CharacterAnimatedController
extends Node2D

@onready var character: Node2D = $"../Character"

# ============================================================
# VARIABLES
# ============================================================

var step: int = 0

# ============================================================
# ESTADOS DE ANIMACIÓN
# ============================================================

enum AnimStates {
	IDLE_DOWN,
	IDLE_UP,
	IDLE_LEFT,
	IDLE_RIGHT,

	FIRST_STEP_DOWN,
	FIRST_STEP_UP,
	FIRST_STEP_LEFT,
	FIRST_STEP_RIGHT,

	SECOND_STEP_DOWN,
	SECOND_STEP_UP,
	SECOND_STEP_LEFT,
	SECOND_STEP_RIGHT,
}

const Anim: Dictionary = {
	AnimStates.IDLE_DOWN: "Idle_Down",
	AnimStates.IDLE_UP: "Idle_Up",
	AnimStates.IDLE_LEFT: "Idle_Left",
	AnimStates.IDLE_RIGHT: "Idle_Right",

	AnimStates.FIRST_STEP_DOWN: "First_Step_Down",
	AnimStates.FIRST_STEP_UP: "First_Step_Up",
	AnimStates.FIRST_STEP_LEFT: "First_Step_Left",
	AnimStates.FIRST_STEP_RIGHT: "First_Step_Right",

	AnimStates.SECOND_STEP_DOWN: "Second_Step_Down",
	AnimStates.SECOND_STEP_UP: "Second_Step_Up",
	AnimStates.SECOND_STEP_LEFT: "Second_Step_Left",
	AnimStates.SECOND_STEP_RIGHT: "Second_Step_Right",
}

# ============================================================
# ANIMACIÓN DE CAMINATA
# ============================================================

func play_step_animation(direction: Vector2) -> void:
	step += 1
	character.play_animation(get_step_animation(direction))

func get_step_animation(direction: Vector2) -> String:
	var animation_state: AnimStates

	if step % 2 == 1:
		animation_state = get_first_step_animation(direction)
	else:
		animation_state = get_second_step_animation(direction)

	return Anim[animation_state]

func get_first_step_animation(direction: Vector2) -> AnimStates:
	match direction:
		Vector2.DOWN:
			return AnimStates.FIRST_STEP_DOWN
		Vector2.UP:
			return AnimStates.FIRST_STEP_UP
		Vector2.LEFT:
			return AnimStates.FIRST_STEP_LEFT
		Vector2.RIGHT:
			return AnimStates.FIRST_STEP_RIGHT

	return AnimStates.IDLE_DOWN

func get_second_step_animation(direction: Vector2) -> AnimStates:
	match direction:
		Vector2.DOWN:
			return AnimStates.SECOND_STEP_DOWN
		Vector2.UP:
			return AnimStates.SECOND_STEP_UP
		Vector2.LEFT:
			return AnimStates.SECOND_STEP_LEFT
		Vector2.RIGHT:
			return AnimStates.SECOND_STEP_RIGHT

	return AnimStates.IDLE_DOWN

# ============================================================
# ANIMACIÓN IDLE
# ============================================================

func play_idle_animation(direction: Vector2) -> void:
	character.play_animation(get_idle_animation(direction))

func get_idle_animation(direction: Vector2) -> String:
	match direction:
		Vector2.DOWN:
			return Anim[AnimStates.IDLE_DOWN]
		Vector2.UP:
			return Anim[AnimStates.IDLE_UP]
		Vector2.LEFT:
			return Anim[AnimStates.IDLE_LEFT]
		Vector2.RIGHT:
			return Anim[AnimStates.IDLE_RIGHT]

	return Anim[AnimStates.IDLE_DOWN]
