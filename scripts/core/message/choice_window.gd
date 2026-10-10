class_name ChoiceWindow
extends NinePatchRect
## Ventana de comandos estilo PE (choice skin, encima-derecha del mensaje).

signal choice_confirmed(index: int)

var choice_list: VBoxContainer

var _choices: PackedStringArray = PackedStringArray()
var _index: int = 0
var _active: bool = false
var _sel_arrow: Texture2D


func setup() -> void:
	texture = MessageConfig.load_choice_texture()
	patch_margin_left = 12
	patch_margin_top = 12
	patch_margin_right = 12
	patch_margin_bottom = 12
	visible = false
	_sel_arrow = MessageConfig.load_sel_arrow()

	choice_list = VBoxContainer.new()
	choice_list.name = "ChoiceList"
	choice_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_list.offset_left = 12.0
	choice_list.offset_top = 10.0
	choice_list.offset_right = -12.0
	choice_list.offset_bottom = -10.0
	choice_list.add_theme_constant_override("separation", 2)
	choice_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(choice_list)


func is_active() -> bool:
	return _active


func show_choices(choices: PackedStringArray, message_rect: Rect2) -> void:
	_choices = choices
	_index = 0
	_active = true
	for c: Node in choice_list.get_children():
		c.queue_free()
	var font: Font = MessageConfig.load_font()
	var max_w: float = 40.0
	for i: int in range(choices.size()):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var arrow: TextureRect = TextureRect.new()
		arrow.name = "Arrow"
		arrow.custom_minimum_size = Vector2(14, 14)
		arrow.size = Vector2(14, 14)
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if _sel_arrow != null:
			arrow.texture = _sel_arrow
		arrow.visible = (i == 0)
		var label: Label = Label.new()
		label.name = "Text"
		label.text = choices[i]
		if font != null:
			label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", MessageConfig.FONT_SIZE)
		label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
		if font != null:
			var tw: float = font.get_string_size(choices[i], HORIZONTAL_ALIGNMENT_LEFT, -1, MessageConfig.FONT_SIZE).x
			max_w = maxf(max_w, tw)
		row.add_child(arrow)
		row.add_child(label)
		choice_list.add_child(row)

	var row_h: float = float(MessageConfig.LINE_HEIGHT)
	var h: float = float(MessageConfig.BORDER_Y) + float(choices.size()) * row_h
	var w: float = max_w + 40.0 + float(MessageConfig.BORDER_X)
	size = Vector2(w, h)
	position = Vector2(
		message_rect.position.x + message_rect.size.x - size.x,
		message_rect.position.y - size.y
	)
	if position.y < 0.0:
		position.y = message_rect.position.y + message_rect.size.y
	visible = true
	_refresh()


func hide_window() -> void:
	_active = false
	visible = false


func _refresh() -> void:
	for i: int in range(choice_list.get_child_count()):
		var row: HBoxContainer = choice_list.get_child(i) as HBoxContainer
		if row == null:
			continue
		var arrow: TextureRect = row.get_node_or_null("Arrow") as TextureRect
		if arrow != null:
			arrow.visible = (i == _index)


func handle_input(event: InputEvent) -> bool:
	if not _active:
		return false
	if event.is_action_pressed("Up"):
		_index = (_index - 1 + _choices.size()) % _choices.size()
		_refresh()
		return true
	if event.is_action_pressed("Down"):
		_index = (_index + 1) % _choices.size()
		_refresh()
		return true
	if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		var idx: int = _index
		hide_window()
		choice_confirmed.emit(idx)
		return true
	return false
