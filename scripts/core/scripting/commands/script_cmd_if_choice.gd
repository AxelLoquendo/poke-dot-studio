@tool
extends ScriptCommand
class_name ScriptCmdIfChoice
@export var expected_choice: String = "0"
@export var target_label: String = ""
func execute(context: ScriptExecutionContext) -> bool:
	var last: String = str(context.get_variable("last_choice", ""))
	if last == expected_choice and context.runner != null:
		context.runner.jump_to_label(target_label)
	return true
