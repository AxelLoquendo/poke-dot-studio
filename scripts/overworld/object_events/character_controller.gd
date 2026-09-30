class_name CharacterController
extends Node2D

@onready var character: Node2D = $"../Character"
@onready var animation_controller: CharacterAnimatedController = $"../CharacterAnimatedController"

# ============================================================
# SEÑALES
# ============================================================

signal movement_finished

# ============================================================
# CONSTANTES
# ============================================================

const TILE_SIZE: float = 16.0
const MOVE_SPEED: float = 64.0
const HOLD_THRESHOLD: float = 0.12

# ============================================================
# VARIABLES
# ============================================================

var current_position: Vector2
var initial_position: Vector2
var target_position: Vector2

var moving: bool = false

var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN

var move_progress: float = 0.0

var input_direction: Vector2 = Vector2.ZERO
var hold_time: float = 0.0
var waiting_for_move: bool = false

# Indica que el movimiento fue solicitado directamente
# por otro controlador, como NpcController.
var external_move: bool = false

# ============================================================
# INICIALIZACIÓN
# ============================================================

func _ready() -> void:
	character.global_position = snap_to_grid(character.global_position)
	current_position = character.global_position
	initial_position = character.global_position
	target_position = character.global_position

# ============================================================
# DIRECCIÓN EXTERNA
# ============================================================

func set_direction(new_direction: Vector2) -> void:
	input_direction = new_direction

func get_direction() -> Vector2:
	return input_direction

# ============================================================
# SOLICITAR MOVIMIENTO DIRECTO
# ============================================================

func request_move(new_direction: Vector2) -> void:
	if moving:
		return

	if new_direction == Vector2.ZERO:
		return

	external_move = true

	direction = new_direction
	last_direction = new_direction

	start_move()

# ============================================================
# MOVIMIENTO
# ============================================================

func process_movement(delta: float) -> void:
	if moving:
		process_move(delta)
		return

	if waiting_for_move:
		process_input_hold(delta)
		return

	if external_move:
		return

	process_input()

func process_input() -> void:
	var new_direction: Vector2 = get_direction()

	if new_direction == Vector2.ZERO:
		return

	input_direction = new_direction

	if new_direction != last_direction:
		direction = new_direction
		last_direction = new_direction
		hold_time = 0.0
		waiting_for_move = true
		animation_controller.play_step_animation(direction)
		return

	direction = new_direction
	start_move()

func process_input_hold(delta: float) -> void:
	var current_direction: Vector2 = get_direction()

	if current_direction == Vector2.ZERO:
		waiting_for_move = false
		hold_time = 0.0
		return

	if current_direction != input_direction:
		input_direction = current_direction
		direction = current_direction
		last_direction = current_direction
		hold_time = 0.0
		animation_controller.play_step_animation(direction)
		return

	hold_time += delta

	if hold_time >= HOLD_THRESHOLD:
		waiting_for_move = false
		start_move()

func start_move() -> void:
	initial_position = character.global_position
	target_position = initial_position + direction * TILE_SIZE
	move_progress = 0.0
	moving = true
	animation_controller.play_step_animation(direction)

func process_move(delta: float) -> void:
	move_progress += (MOVE_SPEED * delta) / TILE_SIZE
	move_progress = min(move_progress, 1.0)
	character.global_position = initial_position.lerp(target_position, move_progress)
	if move_progress >= 1.0:
		character.global_position = target_position
		current_position = target_position
		moving = false
		movement_finished.emit()
		if external_move:
			external_move = false
			return
		var next_direction: Vector2 = get_direction()
		if next_direction != Vector2.ZERO:
			direction = next_direction
			last_direction = next_direction
			start_move()

func look_direction(new_direction: Vector2) -> void:
	if new_direction == Vector2.ZERO:
		return

	direction = new_direction
	last_direction = new_direction

	animation_controller.play_idle_animation(new_direction)

# ============================================================
# GRID
# ============================================================

func snap_to_grid(position: Vector2) -> Vector2:
	return Vector2(
		round(position.x / TILE_SIZE) * TILE_SIZE,
		round(position.y / TILE_SIZE) * TILE_SIZE
	)
