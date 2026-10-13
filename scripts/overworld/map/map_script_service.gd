extends RefCounted
class_name MapScriptService
## Ejecuta scripts de mapa. Host del runner: MapFactory (sobrevive warps).


static func trigger(mapa: Map, trigger: MapScriptEntry.Trigger, player: Node2D) -> void:
	if mapa == null or mapa.attributes == null:
		return
	var attrs: MapAttributes = mapa.attributes

	for entry: MapScriptEntry in attrs.map_scripts:
		if entry == null:
			continue
		if entry.trigger != trigger:
			continue
		if entry.script_file.is_empty():
			continue
		if not entry.condition_matches():
			continue
		_run(entry.script_file, player, mapa)

	# Compat: map_script suelto = ON_LOAD
	if trigger == MapScriptEntry.Trigger.ON_LOAD and not attrs.map_script.is_empty():
		_run(attrs.map_script, player, mapa)


static func _run(path: String, player: Node2D, mapa: Map) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("MapScriptService: no existe %s" % path)
		return
	if player != null and player.has_method("set_script_locked"):
		player.call("set_script_locked", true)

	var file_cmd: ScriptCmdTextFile = ScriptCmdTextFile.new()
	file_cmd.script_file_path = path
	var runner: ScriptRunner = ScriptRunner.new()
	runner.name = "MapScriptRunner"

	var host: Node = player.get_tree().get_first_node_in_group(&"map_factory")
	if host == null:
		host = mapa
	host.add_child(runner)

	runner.script_finished.connect(func() -> void:
		if is_instance_valid(player) and player.has_method("set_script_locked"):
			player.call("set_script_locked", false)
		if is_instance_valid(runner):
			runner.queue_free()
	, CONNECT_ONE_SHOT)

	runner.start_script([file_cmd], null, player, mapa)
