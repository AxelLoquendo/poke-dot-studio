@tool
extends ScriptCommand
class_name ScriptCmdSetVar

@export var var_name: String = ""
@export var value: float = 0.0
@export var is_add: bool = false

func execute(context: ScriptExecutionContext) -> bool:
	if is_add:
		var cur: float = float(context.get_variable(var_name, 0))
		context.set_variable(var_name, cur + value)
	else:
		context.set_variable(var_name, value)
	return true
