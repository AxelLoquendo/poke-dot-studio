@tool
extends ScriptCommand
class_name ScriptCmdLock
@export var lock_player: bool = true
func execute(context: ScriptExecutionContext) -> bool:
	# Convención: el player/controller expone set_script_locked(bool)
	if context.player != null and context.player.has_method("set_script_locked"):
		context.player.call("set_script_locked", lock_player)
	return true
