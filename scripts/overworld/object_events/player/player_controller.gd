class_name PlayerController
extends Node2D

@onready var character_controller: CharacterController = $"../CharacterController"


func update_input() -> void:
	character_controller.set_direction(get_direction())


func get_direction() -> Vector2:
	if Input.is_action_pressed("Up"):
		return Vector2.UP

	if Input.is_action_pressed("Down"):
		return Vector2.DOWN

	if Input.is_action_pressed("Left"):
		return Vector2.LEFT

	if Input.is_action_pressed("Right"):
		return Vector2.RIGHT

	return Vector2.ZERO
