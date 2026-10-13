extends RefCounted
class_name MapEventResolver
## Evalúa MapEvent al terminar un paso o al pulsar A.


static func events_on_tile(map_root: Node, tile: Vector2i) -> Array[MapEvent]:
	var result: Array[MapEvent] = []
	if map_root == null:
		return result
	_collect_recursive(map_root, tile, result)
	return result


static func _collect_recursive(node: Node, tile: Vector2i, out: Array[MapEvent]) -> void:
	if node is MapEvent:
		var ev: MapEvent = node as MapEvent
		if ev.get_tile() == tile:
			out.append(ev)
	for child: Node in node.get_children():
		_collect_recursive(child, tile, out)


static func find_warp_by_id(map_root: Node, warp_id: int) -> MapEvent:
	if map_root == null:
		return null
	return _find_warp_recursive(map_root, warp_id)


static func _find_warp_recursive(node: Node, warp_id: int) -> MapEvent:
	if node is MapEvent:
		var ev: MapEvent = node as MapEvent
		if ev.kind == MapEvent.Kind.WARP and ev.warp_id == warp_id:
			return ev
	for child: Node in node.get_children():
		var found: MapEvent = _find_warp_recursive(child, warp_id)
		if found != null:
			return found
	return null


static func player_tile(player: Node2D) -> Vector2i:
	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	var pos: Vector2 = player.global_position
	if controller != null:
		pos = controller.get_character_position()
	return Vector2i(
		int(round(pos.x / CharacterController.TILE_SIZE)),
		int(round(pos.y / CharacterController.TILE_SIZE))
	)


static func facing_tile(player: Node2D) -> Vector2i:
	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	var facing: Vector2 = Vector2.DOWN
	if controller != null and controller.last_direction != Vector2.ZERO:
		facing = controller.last_direction
	return player_tile(player) + Vector2i(int(facing.x), int(facing.y))


## Llamar al terminar un paso del player.
static func try_step(player: Node2D, factory: MapFactory) -> bool:
	if player == null or factory == null or factory.current_map == null:
		return false
	if player.has_method("set_script_locked") and player.get("_script_locked") == true:
		return false

	var tile: Vector2i = player_tile(player)
	var events: Array[MapEvent] = events_on_tile(factory.current_map, tile)

	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.COORD:
			continue
		if not ev.condition_ok():
			continue
		if ev.script_file.is_empty():
			continue
		_run_script(player, factory.current_map, ev.script_file)
		return true

	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.WARP:
			continue
		if not ev.condition_ok():
			continue
		_start_warp(player, factory, ev)
		return true

	return false


## Llamar al pulsar A (después o antes de NPCs).
static func try_interact(player: Node2D, factory: MapFactory) -> bool:
	if player == null or factory == null or factory.current_map == null:
		return false

	var tile: Vector2i = facing_tile(player)
	var events: Array[MapEvent] = events_on_tile(factory.current_map, tile)

	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.BG:
			continue
		if not ev.condition_ok():
			continue
		if ev.bg_kind == MapEvent.BgKind.HIDDEN_ITEM:
			if ev.is_hidden_item_taken():
				continue
			if not ev.hidden_item_flag.is_empty():
				ScriptExecutionContext.global_flags[ev.hidden_item_flag] = true
		if ev.script_file.is_empty():
			continue
		_run_script(player, factory.current_map, ev.script_file)
		return true

	return false


static func _run_script(player: Node2D, map_node: Node, path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("MapEventResolver: no existe el script %s" % path)
		return
	if player.has_method("set_script_locked"):
		player.call("set_script_locked", true)

	var file_cmd: ScriptCmdTextFile = ScriptCmdTextFile.new()
	file_cmd.script_file_path = path
	var runner: ScriptRunner = ScriptRunner.new()
	runner.name = "ScriptRunner"
	# Host persistente: el mapa puede cambiar en un warp de script
	var host: Node = player.get_tree().get_first_node_in_group(&"map_factory")
	if host == null:
		host = map_node
	host.add_child(runner)
	runner.script_finished.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("set_script_locked"):
			player.call("set_script_locked", false)
		if is_instance_valid(runner):
			runner.queue_free()
	, CONNECT_ONE_SHOT)
	runner.start_script([file_cmd], null, player, map_node)


static func _start_warp(player: Node2D, factory: MapFactory, ev: MapEvent) -> void:
	if ev.dest_map == MapSection.MapID.NONE:
		push_error("MapEventResolver: dest_map no configurado")
		return
	if player.has_method("set_script_locked"):
		player.call("set_script_locked", true)
	_warp_async(player, factory, ev)


static func _warp_async(player: Node2D, factory: MapFactory, ev: MapEvent) -> void:
	var duration: float = ev.warp_fade_duration
	await FadeScreen.fade_out(duration)

	factory.load_cluster(ev.dest_map, ev.dest_tile_fallback, player)

	var dest_map_node: Map = factory.current_map
	var dest_ev: MapEvent = find_warp_by_id(dest_map_node, ev.dest_warp_id)
	var arrival: Vector2i = ev.dest_tile_fallback
	var facing: Vector2 = ev.arrival_facing

	if dest_ev != null:
		arrival = dest_ev.get_tile()
		# Preferir facing del warp de llegada si se exporta distinto de cero
		if dest_ev.arrival_facing != Vector2.ZERO:
			facing = dest_ev.arrival_facing

	var controller: CharacterController = \
		player.get_node_or_null("CharacterController") as CharacterController
	if controller != null:
		var world: Vector2 = Vector2(arrival) * CharacterController.TILE_SIZE
		# Si el mapa no está en (0,0), sumar origen del mapa
		if dest_map_node != null:
			world = dest_map_node.global_position + Vector2(arrival) * CharacterController.TILE_SIZE
		controller.teleport_to(world)
		if facing != Vector2.ZERO:
			controller.look_direction(facing)
		MapCollisionSystem.init_entity_state(controller, controller.get_character_position())

	await FadeScreen.fade_in(duration)

	if is_instance_valid(player) and player.has_method("set_script_locked"):
		player.call("set_script_locked", false)
