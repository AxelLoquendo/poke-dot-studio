@tool
extends ScriptCommand
class_name ScriptCmdFade

@export var fade_out: bool = true
@export var duration: float = 0.4
@export var color: Color = Color.BLACK


func execute(context: ScriptExecutionContext) -> bool:
	context.is_waiting = true
	_run(context)
	return false


func _run(context: ScriptExecutionContext) -> void:
	if fade_out:
		await FadeScreen.fade_out(duration, color)
	else:
		await FadeScreen.fade_in(duration, color)
	context.complete_async()
