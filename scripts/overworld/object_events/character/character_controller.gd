class_name CharacterController
extends Node2D

@onready var entity_root: Node2D = get_parent() as Node2D
@onready var character: Node2D = $"../Character"
@onready var animation_controller: CharacterAnimatedController = $"../CharacterAnimatedController"
@onready var bump_player: AudioStreamPlayer = get_node_or_null("BumpSound") as AudioStreamPlayer

@export var bump_sound: AudioStream

signal movement_finished
signal movement_blocked

const TILE_SIZE: float = 16.0
const MOVE_SPEED: float = 64.0
const HOLD_THRESHOLD: float = 0.12
const BUMP_COOLDOWN: float = 0.25
const BUMP_ANIM_SPEED: float = 1.0
const Z_GROUND: int = 0
const Z_ELEVATED: int = 3

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
var bump_cooldown: float = 0.0
var move_speed: float = MOVE_SPEED
var height_level: int = 0
var elevated: bool = false
var ledge_hop: bool = false
const HOP_HEIGHT: float = 11.0
## Pico del arco (0–1). ~0.35–0.4 = sobre la casilla del ledge
const HOP_PEAK: float = 0.38
const HOP_SPEED_MULT: float = 1.6

func _ready() -> void:
	entity_root.global_position = snap_to_grid(entity_root.global_position)
	character.position = Vector2.ZERO
	current_position = entity_root.global_position
	initial_position = entity_root.global_position
	target_position = entity_root.global_position

func set_move_speed(speed: float) -> void:
	if speed <= 0.0:
		return
	move_speed = speed

func is_bumping() -> bool:
	return bump_cooldown > 0.0


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
	var was_bumping: bool = bump_cooldown > 0.0
	if bump_cooldown > 0.0:
		bump_cooldown = maxf(bump_cooldown - delta, 0.0)
		if was_bumping and bump_cooldown <= 0.0 and not moving:
			animation_controller.play_idle_animation(last_direction)
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
	initial_position = entity_root.global_position
	var step: MoveStepResult = CollisionFacade.resolve_move(self, direction)
	if step.blocked:
		_play_bump()
		movement_blocked.emit()
		return false

	target_position = step.target_world
	ledge_hop = step.hop

	MapCollisionSystem.preview_render_state(self, initial_position, target_position)
	move_progress = 0.0
	moving = true

	var ctx: TileBehaviorContext = TileBehaviorSystem.build_context(
		self,
		initial_position,
		step.behavior_world
	)
	TileBehaviorSystem.on_step_start(ctx)
	if ctx.jump_animation_played:
		ledge_hop = true

	animation_controller.play_step_animation(direction)
	return true


func _play_bump() -> void:
	if bump_cooldown > 0.0:
		return
	_play_bump_animation()
	if entity_root.is_in_group("Player"):
		_play_bump_sound()
	bump_cooldown = BUMP_COOLDOWN


func _play_bump_animation() -> void:
	var sprite: AnimatedSprite2D = character.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null:
		animation_controller.play_step_animation(direction)
		return
	sprite.speed_scale = BUMP_ANIM_SPEED
	animation_controller.play_step_animation(direction)
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
	var dist: float = initial_position.distance_to(target_position)
	if dist < 0.001:
		dist = TILE_SIZE
	var speed: float = move_speed
	if ledge_hop:
		speed *= HOP_SPEED_MULT
	move_progress += (speed * delta) / dist
	move_progress = minf(move_progress, 1.0)
	entity_root.global_position = initial_position.lerp(target_position, _ease_move(move_progress))
	if ledge_hop:
		character.position = Vector2(0.0, -_hop_height(move_progress))
	else:
		character.position = Vector2.ZERO

	if move_progress >= 1.0:
		entity_root.global_position = target_position
		character.position = Vector2.ZERO
		current_position = target_position
		moving = false
		ledge_hop = false
		MapCollisionSystem.apply_cell_state(self, initial_position, target_position)
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

func get_character_position() -> Vector2:
	return entity_root.global_position

@warning_ignore("shadowed_variable_base_class")
func snap_to_grid(position: Vector2) -> Vector2:
	return Vector2(
		round(position.x / TILE_SIZE) * TILE_SIZE,
		round(position.y / TILE_SIZE) * TILE_SIZE
	)

func update_render_layer() -> void:
	if entity_root == null:
		return
	if elevated:
		entity_root.z_index = Z_ELEVATED
	else:
		entity_root.z_index = Z_GROUND

func teleport_to(world_pos: Vector2) -> void:
	var snapped: Vector2 = snap_to_grid(world_pos)
	entity_root.global_position = snapped
	character.position = Vector2.ZERO
	current_position = snapped
	initial_position = snapped
	target_position = snapped
	moving = false
	move_progress = 0.0
	external_move = false
	waiting_for_move = false
	hold_time = 0.0

func _ease_move(t: float) -> float:
	if not ledge_hop:
		return t
	# Un poco más de empuje al inicio, frenado al aterrizar
	return t * t * (3.0 - 2.0 * t)  # smoothstep

func _hop_height(t: float) -> float:
	# Dos parábolas: subida hasta HOP_PEAK, bajada hasta 1
	var peak: float = HOP_PEAK
	if t <= peak:
		var u: float = t / peak
		return HOP_HEIGHT * (1.0 - (1.0 - u) * (1.0 - u))
	var v: float = (t - peak) / (1.0 - peak)
	return HOP_HEIGHT * (1.0 - v * v)
