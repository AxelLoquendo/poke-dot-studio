class_name CharacterStates
extends Node

@onready var controller: CharacterController = $"../CharacterController"
@onready var animation_controller: CharacterAnimatedController = $"../CharacterAnimatedController"

enum State {
	IDLE,
	WALK,
	RUN,
}

var current_state: State = State.IDLE
var previous_state: State = State.IDLE


func process_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			idle(delta)

		State.WALK:
			walk(delta)

		State.RUN:
			run(delta)

	if current_state != previous_state:
		on_state_changed()

	previous_state = current_state


func change_state(new_state: State) -> void:
	current_state = new_state


func on_state_changed() -> void:
	match current_state:
		State.IDLE:
			animation_controller.play_idle_animation(controller.last_direction)

		State.WALK:
			pass

		State.RUN:
			pass


func idle(_delta: float) -> void:
	if controller.moving:
		change_state(State.WALK)
	else:
		animation_controller.play_idle_animation(controller.last_direction)


func walk(_delta: float) -> void:
	if controller.moving:
		return

	change_state(State.IDLE)


func run(_delta: float) -> void:
	pass
