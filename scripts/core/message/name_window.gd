class_name NameWindow
extends NinePatchRect

var name_label: Label
var shadow_label: Label
var _skin: PeWindowSkin


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = MessageConfig.load_speech_texture()
	_skin = PeWindowSkin.from_texture(tex)
	_skin.apply_to(self)
	visible = false
	size = Vector2(160, 48)

	shadow_label = _make_label("ShadowLabel")
	shadow_label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_SHADOW)
	add_child(shadow_label)

	name_label = _make_label("NameLabel")
	name_label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
	add_child(name_label)


func _make_label(node_name: String) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18.0
	label.offset_top = 8.0
	label.offset_right = -18.0
	label.offset_bottom = -8.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = false
	var font: Font = MessageConfig.load_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 22)
	return label


func show_name(speaker: String, message_rect: Rect2) -> void:
	if speaker.is_empty():
		hide_window()
		return
	name_label.text = speaker
	shadow_label.text = speaker
	shadow_label.position = Vector2(0, 2)  # sombra solo Y
	var font: Font = name_label.get_theme_font("font")
	var fsize: int = name_label.get_theme_font_size("font_size")
	var text_w: float = 64.0
	if font != null:
		text_w = font.get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	# Ancho = texto + márgenes generosos del skin
	var pad: float = 48.0
	size = Vector2(maxi(int(text_w + pad), 96), 48)
	position = Vector2(16.0, message_rect.position.y - size.y)
	visible = true


func hide_window() -> void:
	visible = false
