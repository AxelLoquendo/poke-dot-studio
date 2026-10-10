@tool
extends Node2D

@export var data: NPCData:
	set(value):
		data = value
		_aplicar_data()

@onready var state: CharacterStates = $CharacterState
@onready var controller: CharacterController = $CharacterController
@onready var npc_controller: NpcController = $NpcController
@onready var move_route_controller: MoveRouteController = $MoveRouteController
@onready var character_visual: Character = $Character

var _script_locked: bool = false
var _script_running: bool = false


func _ready() -> void:
	add_to_group(&"npc")
	_aplicar_data()
	if Engine.is_editor_hint():
		return
	move_route_controller.setup(controller)
	_aplicar_walk()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _script_locked:
		return
	npc_controller.process_behavior(delta)
	state.process_state(delta)
	controller.process_movement(delta)


func _aplicar_data() -> void:
	var visual: Character = character_visual
	if visual == null:
		visual = get_node_or_null("Character") as Character
	if visual == null:
		return
	if data == null:
		return
	visual.data = data
	if Engine.is_editor_hint():
		return
	if npc_controller != null:
		npc_controller.set_npc_data(data)


func _aplicar_walk() -> void:
	if Engine.is_editor_hint():
		return
	if data == null or controller == null:
		return
	if data.walk <= 0.0:
		return
	controller.set_move_speed(data.walk * CharacterController.TILE_SIZE)


# ============================================================
# INTERACCIÓN / SCRIPTS
# ============================================================

func can_interact() -> bool:
	if _script_running or _script_locked:
		return false
	if data == null:
		return false
	return not data.script_file.is_empty()


func interact(player: Node2D) -> void:
	if not can_interact():
		return
	_run_script(player)


func _run_script(player: Node2D) -> void:
	_script_running = true
	_script_locked = true
	if npc_controller != null:
		npc_controller.pause_behavior(true)
	# Mirar al jugador YA, antes del script
	face_towards(player.global_position)
	if move_route_controller != null and move_route_controller.has_method("stop"):
		move_route_controller.call("stop")

	var file_cmd: ScriptCmdTextFile = ScriptCmdTextFile.new()
	file_cmd.script_file_path = data.script_file
	var runner: ScriptRunner = ScriptRunner.new()
	runner.name = "ScriptRunner"
	add_child(runner)
	runner.script_finished.connect(_on_script_finished.bind(runner), CONNECT_ONE_SHOT)
	runner.start_script([file_cmd], self, player, get_parent())


func _on_script_finished(runner: ScriptRunner) -> void:
	_script_running = false
	_script_locked = false
	if npc_controller != null:
		npc_controller.pause_behavior(false)
	if is_instance_valid(runner):
		runner.queue_free()


func face_towards(world_pos: Vector2) -> void:
	if controller == null:
		return
	var delta: Vector2 = world_pos - global_position
	var dir: Vector2 = Vector2.ZERO
	if absf(delta.x) > absf(delta.y):
		dir = Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT
	else:
		dir = Vector2.DOWN if delta.y > 0.0 else Vector2.UP
	controller.look_direction(dir)


func set_script_locked(locked: bool) -> void:
	_script_locked = locked


func get_script_id() -> StringName:
	if data != null and data.id != &"":
		return data.id
	return StringName(name)


func get_tile_position() -> Vector2i:
	return Vector2i(
		int(round(global_position.x / CharacterController.TILE_SIZE)),
		int(round(global_position.y / CharacterController.TILE_SIZE))
	)
