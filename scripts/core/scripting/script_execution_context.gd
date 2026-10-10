extends RefCounted
class_name ScriptExecutionContext
## Contexto de ejecución: nodos + flags + variables locales.

var npc: Node2D = null
var player: Node2D = null
var map: Node = null
var is_waiting: bool = false
var variables: Dictionary = {}
var runner: ScriptRunner = null

## Flags de partida (más adelante → SaveService / GameFlags).
static var global_flags: Dictionary = {}


func _init(npc_node: Node2D = null, player_node: Node2D = null, map_node: Node = null) -> void:
	npc = npc_node
	player = player_node
	map = map_node


func set_variable(var_name: String, value: Variant) -> void:
	variables[var_name] = value


func get_variable(var_name: String, default_value: Variant = null) -> Variant:
	return variables.get(var_name, default_value)


func set_global_flag(flag_name: String, value: Variant) -> void:
	global_flags[flag_name] = value


func get_global_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return global_flags.get(flag_name, default_value)


func complete_async() -> void:
	if runner != null:
		runner.on_async_complete()


## Busca un CharacterController en el grupo "npc" / "player" por id exportado.
func find_character_by_id(character_id: StringName) -> Node:
	if character_id == &"":
		return null
	var tree: SceneTree = _tree()
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(&"npc"):
		if _node_id(node) == character_id:
			return node
	for node: Node in tree.get_nodes_in_group(&"player"):
		if _node_id(node) == character_id:
			return node
	return null


func _tree() -> SceneTree:
	if npc != null:
		return npc.get_tree()
	if player != null:
		return player.get_tree()
	if map != null:
		return map.get_tree()
	return null


func _node_id(node: Node) -> StringName:
	if node == null:
		return &""
	if node.has_method("get_script_id"):
		return node.call("get_script_id") as StringName
	if "npc_id" in node:
		return node.get("npc_id") as StringName
	return StringName(node.name)
