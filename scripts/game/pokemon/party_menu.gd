extends CanvasLayer
class_name PartyMenu

signal closed

const CANCEL_PATH: String = "res://assets/ui/Party/icon_cancel.png"
const CANCEL_SEL_PATH: String = "res://assets/ui/Party/icon_cancel_sel.png"
const LINE_H: int = 32
const CMD_PAD: int = 8

enum Mode { BROWSE, COMMAND, ITEM, SWITCH }

var party: Party
var _index: int = 0
var _cmd_index: int = 0
var _cmd_labels: Array[String] = []
var _slots: Array[PartySlot] = []
var _active: bool = false
var _mode: Mode = Mode.BROWSE
var _switch_from: int = -1

var _cancel: Sprite2D
var _msg_label: Label
var _cmd_root: Control
var _cmd_panel: NinePatchRect
var _cmd_rows: VBoxContainer
var _arrow_tex: Texture2D


func _ready() -> void:
	layer = 91
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_arrow_tex = MessageConfig.load_sel_arrow()
	_collect_slots()
	_build_command_window()


func open(p: Party) -> void:
	party = p
	_index = 0
	_cmd_index = 0
	_mode = Mode.BROWSE
	_switch_from = -1
	_active = true
	_collect_slots()
	for i: int in range(_slots.size()):
		_slots[i].setup(i)
	_hide_commands()
	_refresh()
	_set_help(_default_help())
	visible = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func close() -> void:
	if not _active:
		return
	_active = false
	_mode = Mode.BROWSE
	_switch_from = -1
	_hide_commands()
	visible = false
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	closed.emit()


func _default_help() -> String:
	if party != null and party.size() > 1:
		return "Elige un Pokémon."
	return "Elige un Pokémon o sal."


func _collect_slots() -> void:
	_slots.clear()
	var panels: Node = get_node_or_null("Panels")
	if panels == null:
		return
	for child: Node in panels.get_children():
		if child is PartySlot:
			_slots.append(child as PartySlot)
	_slots.sort_custom(func(a: Node, b: Node) -> bool: return str(a.name) < str(b.name))
	_cancel = get_node_or_null("Cancel") as Sprite2D
	var box_msg: Node = get_node_or_null("Box_Msg")
	if box_msg != null:
		_msg_label = box_msg.get_node_or_null("Text") as Label


func _build_command_window() -> void:
	_cmd_root = Control.new()
	_cmd_root.name = "CommandWindow"
	_cmd_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cmd_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd_root.visible = false
	add_child(_cmd_root)

	_cmd_panel = NinePatchRect.new()
	_cmd_panel.texture = MessageConfig.load_choice_texture()
	_cmd_panel.patch_margin_left = 16
	_cmd_panel.patch_margin_top = 16
	_cmd_panel.patch_margin_right = 16
	_cmd_panel.patch_margin_bottom = 16
	_cmd_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_cmd_root.add_child(_cmd_panel)

	_cmd_rows = VBoxContainer.new()
	_cmd_rows.add_theme_constant_override("separation", 0)
	_cmd_panel.add_child(_cmd_rows)


func _show_commands(labels: Array[String]) -> void:
	_cmd_labels = labels
	_cmd_index = 0
	while _cmd_rows.get_child_count() > 0:
		var c: Node = _cmd_rows.get_child(0)
		_cmd_rows.remove_child(c)
		c.free()

	var font: Font = MessageConfig.load_font()
	var max_w: float = 96.0
	for label: String in labels:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var arrow: TextureRect = TextureRect.new()
		arrow.name = "Arrow"
		arrow.custom_minimum_size = Vector2(16, LINE_H)
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if _arrow_tex != null:
			arrow.texture = _arrow_tex
		arrow.modulate.a = 0.0
		row.add_child(arrow)
		var lab: Label = Label.new()
		lab.name = "Label"
		lab.text = label
		if font != null:
			lab.add_theme_font_override("font", font)
			max_w = maxf(max_w, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 36.0)
		lab.add_theme_font_size_override("font_size", 24)
		lab.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
		lab.add_theme_color_override("font_shadow_color", MessageConfig.DARK_TEXT_SHADOW)
		lab.add_theme_constant_override("shadow_offset_x", 0)
		lab.add_theme_constant_override("shadow_offset_y", 2)
		lab.custom_minimum_size = Vector2(0, LINE_H)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lab)
		_cmd_rows.add_child(row)

	var h: float = float(labels.size() * LINE_H + CMD_PAD * 2)
	var w: float = max_w + float(CMD_PAD * 2)
	_cmd_panel.size = Vector2(w, h)
	# Abajo-derecha, como pbBottomRight de PE (pantalla 512×384)
	_cmd_panel.position = Vector2(512.0 - w - 8.0, 384.0 - h - 8.0)
	_cmd_rows.position = Vector2(float(CMD_PAD), float(CMD_PAD))
	_cmd_root.visible = true
	_select_command(0)


func _select_command(i: int) -> void:
	if _cmd_rows.get_child_count() == 0:
		return
	_cmd_index = clampi(i, 0, _cmd_rows.get_child_count() - 1)
	for r: int in _cmd_rows.get_child_count():
		var row: HBoxContainer = _cmd_rows.get_child(r) as HBoxContainer
		if row == null:
			continue
		var arrow: TextureRect = row.get_node_or_null("Arrow") as TextureRect
		if arrow == null:
			continue
		var on: bool = r == _cmd_index
		arrow.visible = on
		arrow.modulate.a = 1.0 if on else 0.0


func _hide_commands() -> void:
	if _cmd_root != null:
		_cmd_root.visible = false
	_cmd_labels.clear()


func _refresh() -> void:
	var count: int = party.size() if party != null else 0
	for i: int in range(_slots.size()):
		var mon: Pokemon = party.get_at(i) if party != null else null
		_slots[i].bind(mon)
		var is_sel: bool = _active and _mode != Mode.COMMAND and _mode != Mode.ITEM \
			and i == _index and i < count
		_slots[i].set_selected(is_sel)
		if _mode == Mode.SWITCH:
			_slots[i].set_switching(true, i == _switch_from)
		else:
			_slots[i].set_switching(false, false)
	var on_cancel: bool = _active and _mode == Mode.BROWSE and _index >= count
	if _cancel != null:
		var path: String = CANCEL_SEL_PATH if on_cancel else CANCEL_PATH
		if ResourceLoader.exists(path):
			_cancel.texture = load(path) as Texture2D


func _set_help(text: String) -> void:
	if _msg_label != null:
		_msg_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _mode == Mode.COMMAND or _mode == Mode.ITEM:
		_input_commands(event)
		return
	_input_browse(event)


func _input_browse(event: InputEvent) -> void:
	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()
		return

	var count: int = party.size() if party != null else 0
	var moved: bool = false
	if event.is_action_pressed("ui_down") or event.is_action_pressed("Down"):
		if _index < count:
			_index = mini(_index + 2, count)
		moved = true
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("Up"):
		if _index >= count:
			_index = maxi(count - 1, 0)
		else:
			_index = maxi(_index - 2, 0)
		moved = true
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		_index = mini(_index + 1, count)
		moved = true
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("Left"):
		_index = maxi(_index - 1, 0)
		moved = true
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		if _index >= count:
			_on_cancel()
		elif _mode == Mode.SWITCH:
			_finish_switch(_index)
		else:
			_open_commands(_index)
		get_viewport().set_input_as_handled()
		return

	if moved:
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_refresh()
		get_viewport().set_input_as_handled()


func _input_commands(event: InputEvent) -> void:
	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
		_leave_commands()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("Up"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_select_command(posmod(_cmd_index - 1, _cmd_labels.size()))
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("Down"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_select_command(posmod(_cmd_index + 1, _cmd_labels.size()))
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		_activate_command()
		get_viewport().set_input_as_handled()


func _on_cancel() -> void:
	if _mode == Mode.SWITCH:
		_mode = Mode.BROWSE
		_switch_from = -1
		_set_help(_default_help())
		_refresh()
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
		return
	close()


func _leave_commands() -> void:
	_hide_commands()
	_mode = Mode.BROWSE
	_set_help(_default_help())
	_refresh()


func _open_commands(pkmn_index: int) -> void:
	var mon: Pokemon = party.get_at(pkmn_index)
	if mon == null:
		return
	var labels: Array[String] = ["Resumen"]
	if party.size() > 1:
		labels.append("Cambiar")
	labels.append("Objeto")
	labels.append("Salir")
	_mode = Mode.COMMAND
	_set_help("¿Qué hacer con %s?" % mon.display_name())
	_refresh()
	_show_commands(labels)


func _activate_command() -> void:
	if _cmd_index < 0 or _cmd_index >= _cmd_labels.size():
		_leave_commands()
		return
	var picked: String = _cmd_labels[_cmd_index]
	if _mode == Mode.ITEM:
		_activate_item(picked)
		return
	match picked:
		"Resumen":
			_set_help("Resumen (próximamente).")
			_leave_commands()
		"Cambiar":
			_hide_commands()
			_mode = Mode.SWITCH
			_switch_from = _index
			_set_help("¿Mover a dónde?")
			_refresh()
		"Objeto":
			_mode = Mode.ITEM
			_set_help("¿Qué hacer con un objeto?")
			_show_commands(["Dar", "Quitar", "Salir"])
		_:
			_leave_commands()


func _activate_item(picked: String) -> void:
	var mon: Pokemon = party.get_at(_index) if party != null else null
	match picked:
		"Dar":
			_set_help("Mochila (próximamente).")
			_leave_commands()
		"Quitar":
			if mon == null or mon.held_item == &"":
				_set_help("Este Pokémon no lleva ningún objeto.")
			else:
				var item_name: String = String(mon.held_item)
				if PokemonDB != null:
					var data: ItemData = PokemonDB.item(mon.held_item)
					if data != null:
						item_name = str(data.name)
				mon.held_item = &""
				_set_help("Recibiste %s." % item_name)
			_leave_commands()
		_:
			_leave_commands()


func _finish_switch(to_index: int) -> void:
	if _switch_from < 0 or to_index == _switch_from:
		_mode = Mode.BROWSE
		_switch_from = -1
		_set_help(_default_help())
		_refresh()
		return
	if party != null:
		party.swap(_switch_from, to_index)
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
	_index = to_index
	_mode = Mode.BROWSE
	_switch_from = -1
	_set_help(_default_help())
	_refresh()
