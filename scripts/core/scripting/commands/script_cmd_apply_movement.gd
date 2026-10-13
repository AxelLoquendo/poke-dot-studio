@tool
extends ScriptCommand
class_name ScriptCmdApplyMovement

@export var target_token: String = ""
@export var route_tokens: PackedStringArray = PackedStringArray()

func execute(context: ScriptExecutionContext) -> bool:
	var body: Node2D = _target(context)
	if body == null:
		push_error("applymovement: no hay objetivo")
		return true
	var mrc: MoveRouteController = _ensure_mrc(body)
	if mrc == null:
		return true
	var route: MoveRoute = MoveRouteParser.parse(Array(route_tokens))
	if route.commands.is_empty():
		return true
	mrc.start_route(route)
	return true

func _target(context: ScriptExecutionContext) -> Node2D:
	var t: String = target_token.strip_edges().to_lower()
	if t.is_empty() or t == "event" or t == "npc":
		return context.npc
	if t == "player":
		return context.player
	return context.find_character_by_id(StringName(target_token)) as Node2D

func _ensure_mrc(body: Node2D) -> MoveRouteController:
	var cc: CharacterController = body.get_node_or_null("CharacterController") as CharacterController
	if cc == null:
		return null
	var mrc: MoveRouteController = body.get_node_or_null("MoveRouteController") as MoveRouteController
	if mrc == null:
		mrc = MoveRouteController.new()
		mrc.name = "MoveRouteController"
		body.add_child(mrc)
	mrc.setup(cc)
	return mrc
