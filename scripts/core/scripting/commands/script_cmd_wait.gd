@tool
extends ScriptCommand
class_name ScriptCmdWait
@export var wait_for_input: bool = true
@export var duration: float = 0.0
func execute(context: ScriptExecutionContext) -> bool:
	if wait_for_input:
		# Reutiliza advance del diálogo: esperamos un toque A vía DialogueManager inactivo
		# Versión simple: wait por timer si duration > 0
		if duration > 0.0 and context.runner != null:
			context.is_waiting = true
			var tree: SceneTree = context.runner.get_tree()
			if tree != null:
				tree.create_timer(duration).timeout.connect(context.complete_async, CONNECT_ONE_SHOT)
			return false
	return true
