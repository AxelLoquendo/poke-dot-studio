@tool
extends ScriptCommand
class_name ScriptCmdWarp

@export var map_token: String = ""
@export var cell: Vector2i = Vector2i.ZERO
@export var facing: Vector2 = Vector2.ZERO
@export var fade_duration: float = 0.4


func execute(context: ScriptExecutionContext) -> bool:
	context.is_waiting = true
	_run(context)
	return false


func _run(context: ScriptExecutionContext) -> void:
	var player: Node2D = context.player
	if player == null:
		push_error("ScriptCmdWarp: sin player")
		context.complete_async()
		return

	var map_id: MapSection.MapID = _resolve_map_id(map_token)
	if map_id == MapSection.MapID.NONE:
		push_error("ScriptCmdWarp: mapa desconocido '%s'" % map_token)
		context.complete_async()
		return

	var factory: MapFactory = _find_map_factory(player)
	if factory == null:
		push_error("ScriptCmdWarp: no se encontró MapFactory")
		context.complete_async()
		return

	await FadeScreen.fade_out(fade_duration)

	# CRÍTICO: el runner vive bajo el NPC; el unload lo mata.
	# Lo movemos a MapFactory antes de destruir el mapa.
	var runner: ScriptRunner = context.runner
	if runner != null and is_instance_valid(runner):
		if runner.get_parent() != factory:
			runner.reparent(factory)

	# El NPC/mapa van a dejar de existir
	context.npc = null
	context.map = null

	factory.load_cluster(map_id, cell, player)

	if facing != Vector2.ZERO:
		var controller: CharacterController = \
			player.get_node_or_null("CharacterController") as CharacterController
		if controller != null:
			controller.look_direction(facing)

	await FadeScreen.fade_in(fade_duration)
	context.complete_async()


func _find_map_factory(from: Node) -> MapFactory:
	var node: Node = from
	while node != null:
		var child: Node = node.get_node_or_null("MapFactory")
		if child is MapFactory:
			return child as MapFactory
		if node is MapFactory:
			return node as MapFactory
		node = node.get_parent()
	var tree: SceneTree = from.get_tree()
	if tree != null:
		return tree.get_first_node_in_group(&"map_factory") as MapFactory
	return null


static func _resolve_map_id(token: String) -> MapSection.MapID:
	var key: String = token.strip_edges().to_upper()
	if key.is_empty():
		return MapSection.MapID.NONE
	if not key.begins_with("MAPSEC_"):
		key = "MAPSEC_" + key
	for enum_name: String in MapSection.MapID.keys():
		if enum_name == key:
			return MapSection.MapID[enum_name]
	return MapSection.MapID.NONE


static func _resolve_facing(token: String) -> Vector2:
	match token.strip_edges().to_lower():
		"up", "arriba", "0":
			return Vector2.UP
		"down", "abajo", "1":
			return Vector2.DOWN
		"left", "izquierda", "2":
			return Vector2.LEFT
		"right", "derecha", "3":
			return Vector2.RIGHT
		_:
			return Vector2.ZERO
