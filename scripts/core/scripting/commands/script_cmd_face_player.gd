@tool
extends ScriptCommand
class_name ScriptCmdFacePlayer
func execute(context: ScriptExecutionContext) -> bool:
	if context.npc == null or context.player == null:
		return true
	if context.npc.has_method("face_towards"):
		context.npc.call("face_towards", context.player.global_position)
	elif context.npc.has_method("mirar_hacia"):
		context.npc.call("mirar_hacia", context.player.global_position)
	return true
