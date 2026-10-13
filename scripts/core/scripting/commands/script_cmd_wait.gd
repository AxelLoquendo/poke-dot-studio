@tool
extends ScriptCommand
class_name ScriptCmdWait

@export var wait_for_input: bool = false
@export var duration: float = 0.0

func execute(context: ScriptExecutionContext) -> bool:
	context.is_waiting = true
	_run(context)
	return false

func _run(context: ScriptExecutionContext) -> void:
	if wait_for_input:
		await context.runner.get_tree().process_frame
		while not (Input.is_action_just_pressed("buttonA") or Input.is_action_just_pressed("ui_accept")):
			await context.runner.get_tree().process_frame
	elif duration > 0.0:
		await context.runner.get_tree().create_timer(duration).timeout
	context.complete_async()
