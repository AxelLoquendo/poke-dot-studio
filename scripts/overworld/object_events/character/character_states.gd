class_name CharacterStates
extends Node

@onready var controller: CharacterController = $"../CharacterController"
@onready var animation_controller: CharacterAnimatedController = $"../CharacterAnimatedController"

enum State { IDLE, WALK, RUN, LOCKED }

var current_state: State = State.IDLE
var previous_state: State = State.IDLE


func process_state(_delta: float) -> void:
	match current_state:
		State.IDLE:
			idle()
		State.WALK:
			walk()
		State.RUN:
			run()
		State.LOCKED:
			locked()
	if current_state != previous_state:
		on_state_changed()
	previous_state = current_state


func change_state(new_state: State) -> void:
	current_state = new_state


func is_locked() -> bool:
	return current_state == State.LOCKED


func on_state_changed() -> void:
	match current_state:
		State.IDLE, State.LOCKED:
			if not controller.is_bumping():
				animation_controller.play_idle_animation(controller.last_direction)
		State.WALK:
			pass
		State.RUN:
			pass


func idle() -> void:
	if controller.moving:
		change_state(State.WALK)
		return
	if controller.is_bumping():
		return
	animation_controller.play_idle_animation(controller.last_direction)


func walk() -> void:
	if controller.moving:
		return
	change_state(State.IDLE)


func run() -> void:
	pass


func locked() -> void:
	# Congelado: solo idle en la dirección actual. No pasa a WALK.
	if controller.is_bumping():
		return
	animation_controller.play_idle_animation(controller.last_direction)
