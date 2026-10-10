extends Node
class_name ScriptRunner
## Ejecuta una lista de ScriptCommand en secuencia (estilo pokeemerald).

signal script_started
signal script_finished
signal command_executed(command: ScriptCommand)

var commands: Array[ScriptCommand] = []
var context: ScriptExecutionContext = null
var is_running: bool = false
var current_index: int = 0
var labels: Dictionary = {}


func _ready() -> void:
	set_process(false)


func start_script(
	script_commands: Array[ScriptCommand],
	npc_node: Node2D = null,
	player_node: Node2D = null,
	map_node: Node = null
) -> void:
	if is_running:
		push_warning("ScriptRunner: ya hay un script en ejecución")
		return
	commands = script_commands.duplicate()
	_rebuild_labels()
	context = ScriptExecutionContext.new(npc_node, player_node, map_node)
	context.runner = self
	current_index = 0
	is_running = true
	script_started.emit()
	set_process(true)
	_execute_current_command()


func stop_script() -> void:
	is_running = false
	set_process(false)
	commands.clear()
	context = null


func end_script() -> void:
	if is_running:
		_finish_script()


func _process(_delta: float) -> void:
	if not is_running or context == null:
		set_process(false)
		return
	if context.is_waiting:
		return
	_execute_current_command()


func _execute_current_command() -> void:
	if current_index >= commands.size():
		_finish_script()
		return

	var command: ScriptCommand = commands[current_index]
	if command == null or not command.enabled:
		current_index += 1
		_execute_current_command()
		return

	var inline: Array[ScriptCommand] = command.get_inline_commands(context)
	if not inline.is_empty():
		commands.remove_at(current_index)
		for i: int in range(inline.size() - 1, -1, -1):
			commands.insert(current_index, inline[i])
		_rebuild_labels()
		_execute_current_command()
		return

	var completed: bool = command.execute(context)
	command_executed.emit(command)
	if not is_running:
		return

	if completed:
		current_index += 1
		if not context.is_waiting:
			_execute_current_command()


func on_async_complete() -> void:
	if is_running and context != null and context.is_waiting:
		context.is_waiting = false
		current_index += 1
		_execute_current_command()


func jump_to_label(label_name: String) -> bool:
	if not labels.has(label_name):
		push_error("ScriptRunner: etiqueta no encontrada '%s'" % label_name)
		return false
	current_index = int(labels[label_name])
	return true


func _rebuild_labels() -> void:
	labels.clear()
	for i: int in range(commands.size()):
		var command: ScriptCommand = commands[i]
		if command is ScriptCmdLabel:
			labels[(command as ScriptCmdLabel).label_name] = i


func _finish_script() -> void:
	is_running = false
	set_process(false)
	script_finished.emit()
