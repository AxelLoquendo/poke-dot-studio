class_name NameWindow
extends NinePatchRect
## Placa de nombre estilo Sky / fangames PE (encima del speech, izquierda).

var name_label: Label


func setup() -> void:
	texture = MessageConfig.load_speech_texture()
	patch_margin_left = 12
	patch_margin_top = 10
	patch_margin_right = 12
	patch_margin_bottom = 10
	visible = false
	size = Vector2(120, 36)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.offset_left = 10.0
	name_label.offset_top = 2.0
	name_label.offset_right = -10.0
	name_label.offset_bottom = -2.0
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = MessageConfig.load_font()
	if font != null:
		name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
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
	size = Vector2(text_w + 28.0, 36.0)
	position = Vector2(16.0, message_rect.position.y - size.y - 2.0)
	visible = true


func hide_window() -> void:
	visible = false
