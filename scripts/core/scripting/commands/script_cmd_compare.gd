@tool
extends ScriptCommand
class_name ScriptCmdCompare

@export var var_name: String = ""
@export var op: String = "=="
@export var expected: float = 0.0
@export var target_label: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	var left: float = float(context.get_variable(var_name, 0))
	var ok: bool = false
	match op:
		"==", "=": ok = is_equal_approx(left, expected)
		"!=": ok = not is_equal_approx(left, expected)
		">": ok = left > expected
		"<": ok = left < expected
		">=": ok = left >= expected
		"<=": ok = left <= expected
	if ok and context.runner != null:
		context.runner.jump_to_label(target_label)
	return true
