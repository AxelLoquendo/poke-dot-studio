class_name CharacterController
extends Node2D

@onready var character: Node2D = $"../Character"
@onready var animation_controller: CharacterAnimatedController = $"../CharacterAnimatedController"

## Opcional: arrastra el AudioStreamPlayer hijo, o créalo en código.
@onready var bump_player: AudioStreamPlayer = get_node_or_null("BumpSound") as AudioStreamPlayer

@export var bump_sound: AudioStream

signal movement_finished
signal movement_blocked

const TILE_SIZE: float = 16.0
const MOVE_SPEED: float = 64.0
const HOLD_THRESHOLD: float = 0.12
## Mismo ritmo aproximado que un paso (16/64 = 0.25 s)
const BUMP_COOLDOWN: float = 0.25
const BUMP_ANIM_SPEED: float = 0.1

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

var external_move: bool = false
var depth_priority: int = 2

var bump_cooldown: float = 0.0

func _ready() -> void:
	character.global_position = snap_to_grid(character.global_position)
	current_position = character.global_position
	initial_position = character.global_position
	target_position = character.global_position
	update_depth()

func set_direction(new_direction: Vector2) -> void:
	input_direction = new_direction

func get_direction() -> Vector2:
	return input_direction

func request_move(new_direction: Vector2) -> void:
	if moving:
		return
	if new_direction == Vector2.ZERO:
		return
	external_move = true
	direction = new_direction
	last_direction = new_direction
	if not start_move():
		external_move = false

func process_movement(delta: float) -> void:
	if bump_cooldown > 0.0:
		bump_cooldown = maxf(bump_cooldown - delta, 0.0)
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

func start_move() -> bool:
	initial_position = character.global_position
	target_position = initial_position + direction * TILE_SIZE
	if EntityCollisionSystem.is_position_occupied(target_position, self):
		_play_bump()
		movement_blocked.emit()
		return false
	move_progress = 0.0
	moving = true
	animation_controller.play_step_animation(direction)
	return true

func _play_bump() -> void:
	if bump_cooldown > 0.0:
		return
	_play_bump_animation()
	if get_parent().is_in_group("Player"):
		_play_bump_sound()
	bump_cooldown = BUMP_COOLDOWN

func _play_bump_animation() -> void:
	var sprite: AnimatedSprite2D = character.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null:
		animation_controller.play_step_animation(direction)
		return
	sprite.speed_scale = BUMP_ANIM_SPEED
	animation_controller.play_step_animation(direction)
	# Restaurar velocidad al terminar (o tras el cooldown)
	_restore_anim_speed_after_bump(sprite)

func _restore_anim_speed_after_bump(sprite: AnimatedSprite2D) -> void:
	await get_tree().create_timer(BUMP_COOLDOWN).timeout
	if is_instance_valid(sprite):
		sprite.speed_scale = 1.0

func _play_bump_sound() -> void:
	if bump_sound == null:
		return
	if bump_player == null:
		bump_player = AudioStreamPlayer.new()
		bump_player.name = "BumpSound"
		add_child(bump_player)
	bump_player.stream = bump_sound
	bump_player.play()

func process_move(delta: float) -> void:
	move_progress += (MOVE_SPEED * delta) / TILE_SIZE
	move_progress = minf(move_progress, 1.0)
	character.global_position = initial_position.lerp(target_position, move_progress)
	update_depth()
	if move_progress >= 1.0:
		character.global_position = target_position
		current_position = target_position
		moving = false
		update_depth()
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

func update_depth() -> void:
	character.z_index = depth_priority + int(character.global_position.y)

func get_character_position() -> Vector2:
	return character.global_position

@warning_ignore("shadowed_variable_base_class")
func snap_to_grid(position: Vector2) -> Vector2:
	return Vector2(round(position.x / TILE_SIZE) * TILE_SIZE, round(position.y / TILE_SIZE) * TILE_SIZE)
