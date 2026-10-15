extends CanvasLayer
class_name PauseMenu
## Menú de pausa estilo PE (ventana arriba-derecha).

signal closed

enum Cmd {
	POKEDEX,
	PARTY,
	BAG,
	POKEGEAR,
	TRAINER,
	SAVE,
	OPTIONS,
	QUIT,
}

const LAYER: int = 90

var _root: Control
var _panel: NinePatchRect
var _rows: VBoxContainer
var _commands: Array[Dictionary] = []
var _index: int = 0
var _open: bool = false
var _busy: bool = false
var _arrow_tex: Texture2D


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_arrow_tex = MessageConfig.load_sel_arrow()
	if _arrow_tex == null:
		_arrow_tex = MessageConfig.load_pause_arrow()
	_build()


func is_open() -> bool:
	return _open


func open_menu() -> void:
	if _open or _busy:
		return
	if MessageService.is_active():
		return
	_open = true
	_busy = false
	_build_commands()
	_rebuild_rows()
	_index = 0
	_select(_index)
	visible = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)
	_lock_player(true)


func close_menu() -> void:
	if not _open:
		return
	_open = false
	visible = false
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	_lock_player(false)
	closed.emit()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_panel = NinePatchRect.new()
	_panel.texture = MessageConfig.load_choice_texture()
	_panel.patch_margin_left = 14
	_panel.patch_margin_top = 14
	_panel.patch_margin_right = 14
	_panel.patch_margin_bottom = 14
	_root.add_child(_panel)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 0)
	_panel.add_child(_rows)


func _build_commands() -> void:
	_commands.clear()
	_commands.append({"id": Cmd.POKEDEX, "title": "Pokédex"})
	_commands.append({"id": Cmd.PARTY, "title": "Pokémon"})
	_commands.append({"id": Cmd.BAG, "title": "Mochila"})
	_commands.append({"id": Cmd.POKEGEAR, "title": "Pokégear"})
	var tname: String = "Jugador"
	if NewGameState != null and not str(NewGameState.player_name).is_empty():
		tname = NewGameState.player_name
	_commands.append({"id": Cmd.TRAINER, "title": tname})
	_commands.append({"id": Cmd.SAVE, "title": "Guardar"})
	_commands.append({"id": Cmd.OPTIONS, "title": "Opciones"})
	_commands.append({"id": Cmd.QUIT, "title": "Salir"})


func _clear_rows() -> void:
	while _rows.get_child_count() > 0:
		var c: Node = _rows.get_child(0)
		_rows.remove_child(c)
		c.free()


func _rebuild_rows() -> void:
	_clear_rows()
	var font: Font = MessageConfig.load_font()
	var max_w: float = float(PauseMenuConfig.MIN_WIDTH)

	for cmd: Dictionary in _commands:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var arrow: TextureRect = TextureRect.new()
		arrow.name = "Arrow"
		arrow.custom_minimum_size = Vector2(16, PauseMenuConfig.LINE_H)
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if _arrow_tex != null:
			arrow.texture = _arrow_tex
		arrow.visible = false
		arrow.modulate.a = 0.0
		row.add_child(arrow)

		var lab: Label = Label.new()
		lab.name = "Label"
		lab.text = str(cmd["title"])
		if font != null:
			lab.add_theme_font_override("font", font)
		lab.add_theme_font_size_override("font_size", PauseMenuConfig.FONT_SIZE)
		lab.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
		lab.add_theme_color_override("font_shadow_color", MessageConfig.DARK_TEXT_SHADOW)
		lab.add_theme_constant_override("shadow_offset_x", 0)
		lab.add_theme_constant_override("shadow_offset_y", 2)
		lab.custom_minimum_size = Vector2(0, PauseMenuConfig.LINE_H)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lab)

		_rows.add_child(row)
		if font != null:
			max_w = maxf(
				max_w,
				font.get_string_size(
					lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, PauseMenuConfig.FONT_SIZE
				).x + 40.0
			)

	var h: float = float(_commands.size() * PauseMenuConfig.LINE_H + PauseMenuConfig.PAD * 2)
	var w: float = max_w + float(PauseMenuConfig.PAD * 2)
	_panel.size = Vector2(w, h)
	_panel.position = Vector2(float(MessageConfig.SCREEN_WIDTH) - w, PauseMenuConfig.TOP_Y)
	_rows.position = Vector2(float(PauseMenuConfig.PAD), float(PauseMenuConfig.PAD))
	_rows.size = Vector2(w - float(PauseMenuConfig.PAD * 2), h - float(PauseMenuConfig.PAD * 2))


func _select(i: int) -> void:
	if _rows.get_child_count() == 0:
		return
	_index = clampi(i, 0, _rows.get_child_count() - 1)
	for r: int in _rows.get_child_count():
		var row: HBoxContainer = _rows.get_child(r) as HBoxContainer
		if row == null:
			continue
		var arrow: TextureRect = row.get_node_or_null("Arrow") as TextureRect
		if arrow == null:
			continue
		var on: bool = (r == _index)
		arrow.visible = on
		arrow.modulate.a = 1.0 if on else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _busy:
		return
	if event.is_action_pressed("Up"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_select(posmod(_index - 1, _commands.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_select(posmod(_index + 1, _commands.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_activate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("buttonStart"):
		close_menu()
		get_viewport().set_input_as_handled()


func _activate() -> void:
	_busy = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
	var id: int = int(_commands[_index]["id"])
	match id:
		Cmd.QUIT:
			await _quit_flow()
		Cmd.TRAINER:
			await _stub("Tarjeta de entrenador (próximamente).")
		Cmd.POKEDEX:
			await _stub("Pokédex (próximamente).")
		Cmd.PARTY:
			await _stub("Equipo (próximamente).")
		Cmd.BAG:
			await _stub("Mochila (próximamente).")
		Cmd.POKEGEAR:
			await _stub("Pokégear (próximamente).")
		Cmd.SAVE:
			await _save_flow()
		Cmd.OPTIONS:
			await _options_flow()
		_:
			pass
	if _open:
		_busy = false


func _stub(msg: String) -> void:
	visible = false
	_ensure_message_ui()
	MessageService.show_texts([msg])
	await MessageService.message_finished
	if _open:
		visible = true
		_select(_index)


func _quit_flow() -> void:
	visible = false
	_ensure_message_ui()
	MessageService.show_texts(
		["¿Seguro que quieres salir del juego?"],
		"",
		["SÍ", "NO"]
	)
	await MessageService.message_finished
	if MessageService.get_last_choice() == 0:
		close_menu()
		get_tree().quit()
		return
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
	if _open:
		visible = true
		_select(_index)


func _lock_player(locked: bool) -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	if player.has_method("set_script_locked"):
		player.call("set_script_locked", locked)
	elif player.get("_script_locked") != null:
		player.set("_script_locked", locked)


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	var host: Node = get_tree().current_scene
	if host != null:
		host.add_child(ui)
	else:
		add_child(ui)

func _save_flow() -> void:
	visible = false
	_ensure_message_ui()
	var session: Node = get_tree().get_first_node_in_group(&"game_session")
	if session == null:
		session = get_tree().current_scene
	var ok: bool = SaveService.save_game(session)
	if ok:
		MusicManager.reproducir_efecto_musical(SFXGame.MusicEffectID.ME_GUI_SAVE_GAME)
		MessageService.show_texts(["¡Partida guardada!"])
	else:
		MessageService.show_texts(["No se pudo guardar."])
	await MessageService.message_finished
	if _open:
		visible = true
		_select(_index)


func _options_flow() -> void:
	visible = false
	var opts: OptionsMenu = OptionsMenu.new()
	get_tree().current_scene.add_child(opts)
	opts.open_menu()
	await opts.closed
	opts.queue_free()
	if _open:
		visible = true
		_select(_index)
