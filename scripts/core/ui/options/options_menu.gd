extends CanvasLayer
class_name OptionsMenu
## Opciones mínimas: velocidad texto, BGM, SE.

signal closed

const LAYER: int = 92

var _labels: Array[String] = ["Vel. texto", "Música", "Efectos", "¡Listo!"]
var _index: int = 0
var _root: Control
var _panel: NinePatchRect
var _list: VBoxContainer
var _open: bool = false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func is_open() -> bool:
	return _open


func open_menu() -> void:
	_open = true
	_index = 0
	_refresh()
	visible = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func close_menu() -> void:
	_open = false
	visible = false
	GameSettings.save_settings()
	GameSettings.apply_audio()
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	closed.emit()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_panel = NinePatchRect.new()
	_panel.texture = MessageConfig.load_choice_texture()
	_panel.patch_margin_left = 14
	_panel.patch_margin_top = 14
	_panel.patch_margin_right = 14
	_panel.patch_margin_bottom = 14
	_panel.position = Vector2(120, 80)
	_panel.size = Vector2(272, 160)
	_root.add_child(_panel)
	_list = VBoxContainer.new()
	_list.position = Vector2(16, 16)
	_panel.add_child(_list)


func _refresh() -> void:
	for c: Node in _list.get_children():
		_list.remove_child(c)
		c.free()
	var font: Font = MessageConfig.load_font()
	var values: Array[String] = [
		_speed_name(),
		"%d%%" % int(GameSettings.bgm_volume * 100.0),
		"%d%%" % int(GameSettings.se_volume * 100.0),
		"",
	]
	for i: int in _labels.size():
		var lab: Label = Label.new()
		var prefix: String = ">" if i == _index else " "
		lab.text = "%s %s  %s" % [prefix, _labels[i], values[i]]
		if font:
			lab.add_theme_font_override("font", font)
		lab.add_theme_font_size_override("font_size", 24)
		lab.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
		_list.add_child(lab)


func _speed_name() -> String:
	match GameSettings.text_speed:
		GameSettings.TextSpeed.SLOW:
			return "Lenta"
		GameSettings.TextSpeed.FAST:
			return "Rápida"
		_:
			return "Media"


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("Up"):
		_index = posmod(_index - 1, _labels.size())
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_refresh()
	elif event.is_action_pressed("Down"):
		_index = posmod(_index + 1, _labels.size())
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_refresh()
	elif event.is_action_pressed("Left"):
		_nudge(-1)
	elif event.is_action_pressed("Right"):
		_nudge(1)
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		if _index == 3:
			close_menu()
		else:
			_nudge(1)
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		close_menu()
	get_viewport().set_input_as_handled()


func _nudge(dir: int) -> void:
	match _index:
		0:
			var s: int = int(GameSettings.text_speed)
			s = posmod(s + dir, 3)
			GameSettings.text_speed = s as GameSettings.TextSpeed
		1:
			GameSettings.bgm_volume = clampf(GameSettings.bgm_volume + dir * 0.1, 0.0, 1.0)
			GameSettings.apply_audio()
		2:
			GameSettings.se_volume = clampf(GameSettings.se_volume + dir * 0.1, 0.0, 1.0)
			GameSettings.apply_audio()
		_:
			return
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
	_refresh()
