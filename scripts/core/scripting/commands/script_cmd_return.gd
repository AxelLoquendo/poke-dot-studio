@tool
extends ScriptCommand
class_name ScriptCmdReturn
func execute(context: ScriptExecutionContext) -> bool:
	if context.runner != null:
		context.runner.end_script()
	return true
