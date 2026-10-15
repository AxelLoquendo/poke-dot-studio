extends Control
class_name LoadMenuScene

signal continue_pressed
signal new_game_pressed
signal options_pressed
signal quit_pressed

enum Cmd { CONTINUE, NEW_GAME, OPTIONS, QUIT }

var _commands: Array[Dictionary] = []
var _index: int = 0
var _panels: Array[Control] = []
var _bg: TextureRect
var _panels_tex: Texture2D
var _busy: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_bg()
	_panels_tex = load(LoadMenuConfig.PANELS_PATH) as Texture2D
	_build_commands()
	_build_panels()
	_select(0)
	await FadeScreen.fade_in(0.4)
	_busy = false


func _build_bg() -> void:
	_bg = TextureRect.new()
	_bg.name = "Bg"
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP
	if ResourceLoader.exists(LoadMenuConfig.BG_PATH):
		_bg.texture = load(LoadMenuConfig.BG_PATH) as Texture2D
	add_child(_bg)


func _build_commands() -> void:
	var has_save: bool = _has_save()
	_commands.clear()
	_commands.append({
		"id": Cmd.CONTINUE,
		"title": "  Continuar",
		"is_continue": true,
		"enabled": has_save,
	})
	_commands.append({
		"id": Cmd.NEW_GAME,
		"title": "  Nueva partida",
		"is_continue": false,
		"enabled": true,
	})
	_commands.append({
		"id": Cmd.OPTIONS,
		"title": "  Opciones",
		"is_continue": false,
		"enabled": true,
	})
	_commands.append({
		"id": Cmd.QUIT,
		"title": "  Cerrar juego",
		"is_continue": false,
		"enabled": true,
	})
	_index = 0
	for i: int in _commands.size():
		if bool(_commands[i]["enabled"]):
			_index = i
			break


func _has_save() -> bool:
	return false


func _build_panels() -> void:
	for p: Control in _panels:
		p.queue_free()
	_panels.clear()
	var y: float = LoadMenuConfig.PANEL_START_Y
	for i: int in _commands.size():
		var cmd: Dictionary = _commands[i]
		if bool(cmd["is_continue"]) and not bool(cmd["enabled"]):
			cmd["is_continue"] = false
			_commands[i] = cmd
		var panel: Control = _make_panel(cmd, false)
		panel.position = Vector2(LoadMenuConfig.PANEL_X, y)
		add_child(panel)
		_panels.append(panel)
		var h: float = float(LoadMenuConfig.PANEL_CONTINUE_H) if bool(cmd["is_continue"]) \
			else float(LoadMenuConfig.PANEL_NEW_H)
		y += h


func _make_panel(cmd: Dictionary, selected: bool) -> Control:
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_continue: bool = bool(cmd["is_continue"])
	var h: int = LoadMenuConfig.PANEL_CONTINUE_H if is_continue else LoadMenuConfig.PANEL_NEW_H
	root.size = Vector2(float(LoadMenuConfig.PANEL_W), float(h))
	var tr: TextureRect = TextureRect.new()
	tr.name = "Skin"
	tr.position = Vector2.ZERO
	tr.size = root.size
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.texture = _atlas_for(is_continue, selected)
	root.add_child(tr)
	var label: Label = Label.new()
	label.name = "Title"
	label.position = LoadMenuConfig.TITLE_OFFSET
	label.size = Vector2(float(LoadMenuConfig.PANEL_W) - 32.0, float(h) - 8.0)
	label.text = str(cmd["title"])
	var font: Font = MessageConfig.load_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", LoadMenuConfig.FONT_SIZE)
	var col: Color = LoadMenuConfig.TEXT_COLOR if bool(cmd["enabled"]) else LoadMenuConfig.TEXT_DISABLED
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_shadow_color", LoadMenuConfig.TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(label)
	return root


func _atlas_for(is_continue: bool, selected: bool) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = _panels_tex
	if is_continue:
		var src_y: int = LoadMenuConfig.PANEL_CONTINUE_H if selected else 0
		atlas.region = Rect2(0, src_y, LoadMenuConfig.PANEL_W, LoadMenuConfig.PANEL_CONTINUE_H)
	else:
		var src_y: int = LoadMenuConfig.PANEL_NONCONTINUE_SRC_Y
		if selected:
			src_y += LoadMenuConfig.PANEL_NEW_H
		atlas.region = Rect2(0, src_y, LoadMenuConfig.PANEL_W, LoadMenuConfig.PANEL_NEW_H)
	return atlas


func _select(new_index: int) -> void:
	_index = clampi(new_index, 0, _commands.size() - 1)
	for i: int in _panels.size():
		var cmd: Dictionary = _commands[i]
		var selected: bool = (i == _index)
		var skin: TextureRect = _panels[i].get_node("Skin") as TextureRect
		if skin != null:
			skin.texture = _atlas_for(bool(cmd["is_continue"]), selected)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Down"):
		_move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Up"):
		_move(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _move(dir: int) -> void:
	var next: int = _index
	for _i: int in _commands.size():
		next = posmod(next + dir, _commands.size())
		if bool(_commands[next]["enabled"]):
			break
	if next != _index:
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_select(next)


func _confirm() -> void:
	var cmd: Dictionary = _commands[_index]
	if not bool(cmd["enabled"]):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_BUZZER)
		return
	_busy = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
	match int(cmd["id"]):
		Cmd.CONTINUE:
			continue_pressed.emit()
			_busy = false
		Cmd.NEW_GAME:
			new_game_pressed.emit()
			NewGameState.reset()
			await FadeScreen.fade_out(0.4)
			get_tree().change_scene_to_file("res://scenes/boot/intro.tscn")
		Cmd.OPTIONS:
			options_pressed.emit()
			push_warning("LoadMenu: Opciones todavía no implementadas")
			_busy = false
		Cmd.QUIT:
			quit_pressed.emit()
			get_tree().quit()
