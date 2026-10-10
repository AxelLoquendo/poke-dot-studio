@tool
extends ScriptCommand
class_name ScriptCmdSetFlag
@export var flag_name: String = ""
@export var value: bool = true
func execute(context: ScriptExecutionContext) -> bool:
	context.set_global_flag(flag_name, value)
	return true
