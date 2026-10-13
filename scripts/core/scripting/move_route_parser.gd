extends RefCounted
class_name MoveRouteParser

static func parse(tokens: Array) -> MoveRoute:
	var route: MoveRoute = MoveRoute.new()
	route.loop = false
	for raw: Variant in tokens:
		var token: String = str(raw).strip_edges().to_lower()
		if token.is_empty():
			continue
		var cmd: MoveCommand = _one(token)
		if cmd != null:
			route.commands.append(cmd)
	return route

static func _one(token: String) -> MoveCommand:
	var cmd: MoveCommand = MoveCommand.new()
	match token:
		"walk_up", "up":
			cmd.type = MoveCommand.Type.MOVE_UP
		"walk_down", "down":
			cmd.type = MoveCommand.Type.MOVE_DOWN
		"walk_left", "left":
			cmd.type = MoveCommand.Type.MOVE_LEFT
		"walk_right", "right":
			cmd.type = MoveCommand.Type.MOVE_RIGHT
		"face_up":
			cmd.type = MoveCommand.Type.TURN_UP
		"face_down":
			cmd.type = MoveCommand.Type.TURN_DOWN
		"face_left":
			cmd.type = MoveCommand.Type.TURN_LEFT
		"face_right":
			cmd.type = MoveCommand.Type.TURN_RIGHT
		"face_player":
			cmd.type = MoveCommand.Type.FACE_PLAYER
		_:
			if token.begins_with("wait_"):
				cmd.type = MoveCommand.Type.WAIT
				cmd.parameter = float(token.substr(5))
			else:
				push_warning("MoveRouteParser: '%s' desconocido" % token)
				return null
	return cmd
