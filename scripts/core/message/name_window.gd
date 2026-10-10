class_name NameWindow
extends NinePatchRect

const MARGIN_L: int = 14
const MARGIN_T: int = 10
const MARGIN_R: int = 14
const MARGIN_B: int = 10
const INNER_PAD: float = 6.0
const BOX_HEIGHT: float = 40.0

var name_label: Label


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture = MessageConfig.load_speech_texture()
	patch_margin_left = MARGIN_L
	patch_margin_top = MARGIN_T
	patch_margin_right = MARGIN_R
	patch_margin_bottom = MARGIN_B
	visible = false
	size = Vector2(96.0, BOX_HEIGHT)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.offset_left = float(MARGIN_L) + INNER_PAD
	name_label.offset_top = float(MARGIN_T)
	name_label.offset_right = -(float(MARGIN_R) + INNER_PAD)
	name_label.offset_bottom = -float(MARGIN_B)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.clip_text = false
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
	var total_w: float = float(MARGIN_L + MARGIN_R) + INNER_PAD * 2.0 + text_w + 4.0
	size = Vector2(maxf(total_w, 80.0), BOX_HEIGHT)
	position = Vector2(16.0, message_rect.position.y - size.y)
	visible = true


func hide_window() -> void:
	visible = false
