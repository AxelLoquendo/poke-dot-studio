@tool
extends ScriptCommand
class_name ScriptCmdWaitMovement

@export var target_token: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	var body: Node2D = _target(context)
	if body == null:
		return true
	var mrc: MoveRouteController = body.get_node_or_null("MoveRouteController") as MoveRouteController
	if mrc == null or not mrc.executing:
		return true
	context.is_waiting = true
	mrc.route_finished.connect(context.complete_async, CONNECT_ONE_SHOT)
	return false

func _target(context: ScriptExecutionContext) -> Node2D:
	var t: String = target_token.strip_edges().to_lower()
	if t.is_empty() or t == "event" or t == "npc":
		return context.npc
	if t == "player":
		return context.player
	return context.find_character_by_id(StringName(target_token)) as Node2D
