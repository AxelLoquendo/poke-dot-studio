@tool
extends ScriptCommand
class_name ScriptCmdIfFlag
@export var flag_name: String = ""
@export var target_label: String = ""
@export var expected: bool = true
func execute(context: ScriptExecutionContext) -> bool:
	var value: bool = bool(context.get_global_flag(flag_name, false))
	if value == expected and context.runner != null:
		context.runner.jump_to_label(target_label)
	return true
