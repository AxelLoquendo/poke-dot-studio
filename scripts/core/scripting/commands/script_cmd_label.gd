@tool
extends ScriptCommand
class_name ScriptCmdLabel
@export var label_name: String = ""
func execute(_context: ScriptExecutionContext) -> bool:
	return true
func get_display_text() -> String:
	return "label %s" % label_name
