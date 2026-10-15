@tool
extends ScriptCommand
class_name ScriptCmdSaveGame
## savegame [silent]
## Espera a que no haya diálogo activo; luego guarda.
## Por defecto: ME + "{nombre} guardó la partida."
## silent: solo guarda, sin mensaje.

@export var silent: bool = false


func execute(context: ScriptExecutionContext) -> bool:
	# Si aún hay texto en pantalla, esperar a que el jugador lo cierre
	if MessageService.is_active():
		if not MessageService.message_finished.is_connected(_on_dialog_done.bind(context)):
			MessageService.message_finished.connect(_on_dialog_done.bind(context), CONNECT_ONE_SHOT)
		context.is_waiting = true
		return false
	return _begin_save(context)


func _on_dialog_done(context: ScriptExecutionContext) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(0.05).timeout.connect(
			func() -> void:
				if _begin_save(context):
					context.complete_async(), CONNECT_ONE_SHOT
		)
	else:
		if _begin_save(context):
			context.complete_async()


func _begin_save(context: ScriptExecutionContext) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("savegame: no hay SceneTree")
		return true

	var session: Node = tree.get_first_node_in_group(&"game_session")
	if session == null:
		session = tree.current_scene

	var ok: bool = SaveService.save_game(session)

	if silent:
		if not ok:
			push_warning("savegame silent: falló")
		return true

	if ok:
		MusicManager.reproducir_efecto_musical(SFXGame.MusicEffectID.ME_GUI_SAVE_GAME)
		var n: String = NewGameState.player_name
		if n.is_empty():
			n = "Jugador"
		_show_and_wait(context, ["%s guardó la partida." % n])
		return false

	_show_and_wait(context, ["No se pudo guardar la partida."])
	return false


func _show_and_wait(context: ScriptExecutionContext, pages: Array[String]) -> void:
	if not MessageService.message_finished.is_connected(context.complete_async):
		MessageService.message_finished.connect(context.complete_async, CONNECT_ONE_SHOT)
	MessageService.show_texts(pages)
	context.is_waiting = true


func get_display_text() -> String:
	return "savegame" + (" silent" if silent else "")
