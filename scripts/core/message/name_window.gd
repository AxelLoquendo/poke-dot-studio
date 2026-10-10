class_name NameWindow
extends NinePatchRect

const INNER_PAD: float = 4.0

var name_label: Label
var _skin: PeWindowSkin


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skin = PeWindowSkin.from_texture(MessageConfig.load_speech_texture())
	_skin.apply_to(self)
	visible = false
	size = Vector2(160.0, _box_height())

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.offset_left = float(_skin.margin_left) + INNER_PAD
	name_label.offset_top = float(_skin.margin_top)
	name_label.offset_right = -(float(_skin.margin_right) + INNER_PAD)
	name_label.offset_bottom = -float(_skin.margin_bottom)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.clip_text = true
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var font: Font = MessageConfig.load_font()
	if font != null:
		name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", MessageConfig.FONT_SIZE)
	name_label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
	name_label.add_theme_color_override("font_shadow_color", MessageConfig.DARK_TEXT_SHADOW)
	name_label.add_theme_constant_override("shadow_offset_x", 0)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(name_label)


func show_name(speaker: String, message_rect: Rect2) -> void:
	if speaker.is_empty():
		hide_window()
		return
	name_label.text = speaker
	var font: Font = name_label.get_theme_font("font")
	var fsize: int = name_label.get_theme_font_size("font_size")
	var text_w: float = 48.0
	if font != null:
		text_w = font.get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var total_w: float = float(_skin.margin_left + _skin.margin_right) + INNER_PAD * 2.0 + text_w
	size = Vector2(total_w, _box_height())
	position = Vector2(16.0, message_rect.position.y - size.y)
	visible = true


func hide_window() -> void:
	visible = false


func _box_height() -> float:
	return float(_skin.margin_top + _skin.margin_bottom + MessageConfig.LINE_HEIGHT)
