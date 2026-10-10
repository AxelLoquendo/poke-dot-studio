class_name ChoiceWindow
extends NinePatchRect

signal choice_confirmed(index: int)

const ARROW_SLOT_W: float = 16.0

var choice_list: VBoxContainer
var _skin: PeWindowSkin
var _choices: PackedStringArray = PackedStringArray()
var _index: int = 0
var _active: bool = false
var _sel_arrow: Texture2D


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = MessageConfig.load_choice_texture()
	_skin = PeWindowSkin.from_texture(tex)
	_skin.apply_to(self)
	visible = false
	_sel_arrow = MessageConfig.load_sel_arrow()

	choice_list = VBoxContainer.new()
	choice_list.name = "ChoiceList"
	choice_list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var off: Vector2 = _skin.content_offset()
	var rb: Vector2 = _skin.content_margin_right_bottom()
	choice_list.offset_left = off.x
	choice_list.offset_top = off.y - 2.0
	choice_list.offset_right = -rb.x
	choice_list.offset_bottom = -rb.y
	choice_list.add_theme_constant_override("separation", 0)
	choice_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(choice_list)


func is_active() -> bool:
	return _active


func show_choices(choices: PackedStringArray, message_rect: Rect2) -> void:
	_choices = choices
	_index = 0
	_active = true
	_clear_rows()
	var text_width: float = _measure_widest(choices)
	_build_rows(choices)
	_place_window(text_width, choices.size(), message_rect)
	_refresh()


func _clear_rows() -> void:
	while choice_list.get_child_count() > 0:
		var old: Node = choice_list.get_child(0)
		choice_list.remove_child(old)
		old.free()


func _measure_widest(choices: PackedStringArray) -> float:
	var font: Font = MessageConfig.load_font()
	var max_w: float = 48.0
	if font == null:
		return max_w
	for choice: String in choices:
		max_w = maxf(max_w, font.get_string_size(choice, HORIZONTAL_ALIGNMENT_LEFT, -1, MessageConfig.FONT_SIZE).x)
	return max_w


func _build_rows(choices: PackedStringArray) -> void:
	var font: Font = MessageConfig.load_font()
	for i: int in range(choices.size()):
		choice_list.add_child(_make_row(choices[i], font, i == 0))


func _make_row(text: String, font: Font, selected: bool) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, MessageConfig.LINE_HEIGHT)
	row.add_theme_constant_override("separation", 4)
	row.add_child(_make_arrow(selected))
	row.add_child(_make_label(text, font))
	return row


func _make_arrow(selected: bool) -> TextureRect:
	var arrow: TextureRect = TextureRect.new()
	arrow.name = "Arrow"
	arrow.custom_minimum_size = Vector2(ARROW_SLOT_W, MessageConfig.LINE_HEIGHT)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _sel_arrow != null:
		arrow.texture = _sel_arrow
	arrow.modulate.a = 1.0 if selected else 0.0
	return arrow


func _make_label(text: String, font: Font) -> Label:
	var label: Label = Label.new()
	label.name = "Text"
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", MessageConfig.FONT_SIZE)
	label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
	label.add_theme_color_override("font_shadow_color", MessageConfig.DARK_TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _place_window(text_width: float, count: int, message_rect: Rect2) -> void:
	size = Vector2(
		float(_skin.margin_left + _skin.margin_right) + text_width + ARROW_SLOT_W + 12.0,
		float(_skin.margin_top + _skin.margin_bottom) + float(count) * float(MessageConfig.LINE_HEIGHT)
	)
	position = Vector2(
		message_rect.position.x + message_rect.size.x - size.x,
		message_rect.position.y - size.y
	)
	if position.y < 0.0:
		position.y = message_rect.position.y + message_rect.size.y
	visible = true


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
			arrow.modulate.a = 1.0 if i == _index else 0.0


func handle_input(event: InputEvent) -> bool:
	if not _active:
		return false
	if event.is_action_pressed("Up"):
		_index = (_index - 1 + _choices.size()) % _choices.size()
		_refresh()
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		return true
	if event.is_action_pressed("Down"):
		_index = (_index + 1) % _choices.size()
		_refresh()
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		return true
	if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		var idx: int = _index
		hide_window()
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		choice_confirmed.emit(idx)
		return true
	return false
