class_name MessageWindow
extends NinePatchRect
## Ventana de speech estilo PE (solo presentación + typewriter).

signal typing_finished
signal advance_requested

var text_label: RichTextLabel
var pause_arrow: TextureRect

var _full_text: String = ""
var _visible_chars: float = 0.0
var _typing: bool = false
var _text_speed: float = MessageConfig.TEXT_SPEED_MEDIUM
var _arrow_bob: float = 0.0
var _arrow_base_y: float = 0.0


func setup() -> void:
	var rect: Rect2 = MessageConfig.message_rect()
	position = rect.position
	size = rect.size
	texture = MessageConfig.load_speech_texture()
	patch_margin_left = 14
	patch_margin_top = 14
	patch_margin_right = 14
	patch_margin_bottom = 14
	visible = false

	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_label.offset_left = float(MessageConfig.BORDER_X / 2)
	text_label.offset_top = float(MessageConfig.BORDER_Y / 2) - 4.0
	text_label.offset_right = -float(MessageConfig.BORDER_X / 2)
	text_label.offset_bottom = -float(MessageConfig.BORDER_Y / 2)
	text_label.bbcode_enabled = false
	text_label.scroll_active = false
	text_label.fit_content = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = MessageConfig.load_font()
	if font != null:
		text_label.add_theme_font_override("normal_font", font)
	text_label.add_theme_font_size_override("normal_font_size", MessageConfig.FONT_SIZE)
	text_label.add_theme_color_override("default_color", MessageConfig.DARK_TEXT_MAIN)
	add_child(text_label)

	pause_arrow = TextureRect.new()
	pause_arrow.name = "PauseArrow"
	pause_arrow.texture = MessageConfig.load_pause_arrow()
	pause_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pause_arrow.stretch_mode = TextureRect.STRETCH_KEEP
	pause_arrow.custom_minimum_size = Vector2(16, 16)
	pause_arrow.size = Vector2(16, 16)
	pause_arrow.visible = false
	pause_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pause_arrow)
	_place_pause_arrow()


func _place_pause_arrow() -> void:
	if pause_arrow == null:
		return
	pause_arrow.position = Vector2(size.x - 28.0, size.y - 24.0)
	_arrow_base_y = pause_arrow.position.y


func is_typing() -> bool:
	return _typing


func display_text(text: String) -> void:
	_full_text = text
	_visible_chars = 0.0
	_typing = true
	visible = true
	text_label.text = _full_text
	text_label.visible_characters = 0
	if pause_arrow:
		pause_arrow.visible = false
	_place_pause_arrow()


func skip_typing() -> void:
	if not _typing:
		return
	_finish_typing()


func hide_window() -> void:
	visible = false
	_typing = false
	if pause_arrow:
		pause_arrow.visible = false


func _finish_typing() -> void:
	_typing = false
	text_label.visible_characters = -1
	if pause_arrow and pause_arrow.texture != null:
		pause_arrow.visible = true
	typing_finished.emit()


func _process(delta: float) -> void:
	if _typing:
		var cps: float = 40.0
		if _text_speed > 0.0:
			cps = 1.0 / _text_speed
		_visible_chars += cps * delta
		var count: int = int(_visible_chars)
		text_label.visible_characters = count
		if count >= _full_text.length():
			_finish_typing()
		return
	if pause_arrow != null and pause_arrow.visible:
		_arrow_bob += delta * 6.0
		pause_arrow.position.y = _arrow_base_y + sin(_arrow_bob) * 2.0
