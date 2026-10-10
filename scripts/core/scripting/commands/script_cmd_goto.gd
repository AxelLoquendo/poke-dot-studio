@tool
extends ScriptCommand
class_name ScriptCmdGoto
@export var target_label: String = ""
func execute(context: ScriptExecutionContext) -> bool:
	if context.runner != null:
		context.runner.jump_to_label(target_label)
	return true
