class_name MessageWindow
extends NinePatchRect
## Speech PE: contenido clippeado al body blanco del skin.

signal typing_finished

const PAUSE_FRAME_W: int = 20
const PAUSE_FRAME_H: int = 28
const PAUSE_FRAME_COUNT: int = 4
const PAUSE_FPS: float = 5.0
const INNER_PAD: float = 4.0

var content: Control
var text_label: RichTextLabel
var shadow_label: RichTextLabel
var pause_arrow: TextureRect
var _skin: PeWindowSkin
var _pause_atlas: AtlasTexture

var _full_text: String = ""
var _visible_chars: float = 0.0
var _typing: bool = false
var _text_speed: float = MessageConfig.TEXT_SPEED_MEDIUM
var _pause_frame: float = 0.0
var _base_color: Color = MessageConfig.DARK_TEXT_MAIN
var _shadow_color: Color = MessageConfig.DARK_TEXT_SHADOW


func setup() -> void:
	var rect: Rect2 = MessageConfig.message_rect()
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex: Texture2D = MessageConfig.load_speech_texture()
	_skin = PeWindowSkin.from_texture(tex)
	_skin.apply_to(self)
	var colors: Dictionary = resolve_text_colors(tex)
	_base_color = colors["base"]
	_shadow_color = colors["shadow"]
	visible = false

	# Área blanca = body del nine-patch (entre márgenes). clip_contents = nada se sale.
	content = Control.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.clip_contents = true
	add_child(content)
	_layout_content()

	shadow_label = _make_label("ShadowLabel")
	shadow_label.add_theme_color_override("default_color", _shadow_color)
	content.add_child(shadow_label)

	text_label = _make_label("TextLabel")
	text_label.add_theme_color_override("default_color", _base_color)
	content.add_child(text_label)

	_setup_pause_arrow()


func _layout_content() -> void:
	var ml: float = float(_skin.margin_left)
	var mt: float = float(_skin.margin_top)
	var mr: float = float(_skin.margin_right)
	var mb: float = float(_skin.margin_bottom)
	content.position = Vector2(ml, mt)
	content.size = Vector2(size.x - ml - mr, size.y - mt - mb)


func _make_label(node_name: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.name = node_name
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = INNER_PAD
	label.offset_top = INNER_PAD
	label.offset_right = -INNER_PAD
	label.offset_bottom = -INNER_PAD
	label.bbcode_enabled = false
	label.scroll_active = false
	label.fit_content = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = MessageConfig.load_font()
	if font != null:
		label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", MessageConfig.FONT_SIZE)
	return label


func _setup_pause_arrow() -> void:
	var full: Texture2D = MessageConfig.load_pause_arrow()
	_pause_atlas = AtlasTexture.new()
	_pause_atlas.atlas = full
	_pause_atlas.region = Rect2(0, 0, PAUSE_FRAME_W, PAUSE_FRAME_H)
	pause_arrow = TextureRect.new()
	pause_arrow.name = "PauseArrow"
	pause_arrow.texture = _pause_atlas
	pause_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pause_arrow.stretch_mode = TextureRect.STRETCH_KEEP
	pause_arrow.size = Vector2(PAUSE_FRAME_W, PAUSE_FRAME_H)
	pause_arrow.visible = false
	pause_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pause_arrow)  # fuera del content (sobre el borde inferior)
	_place_pause_arrow()


func _place_pause_arrow() -> void:
	if pause_arrow == null:
		return
	pause_arrow.position = Vector2(
		size.x - float(PAUSE_FRAME_W) - float(_skin.margin_right) * 0.35,
		size.y - float(PAUSE_FRAME_H) - 4.0
	)


static func resolve_text_colors(tex: Texture2D) -> Dictionary:
	var base: Color = MessageConfig.DARK_TEXT_MAIN
	var shadow: Color = MessageConfig.DARK_TEXT_SHADOW
	if tex == null:
		return {"base": base, "shadow": shadow}
	var img: Image = tex.get_image()
	if img == null:
		return {"base": base, "shadow": shadow}
	var cx: int = 40 if tex.get_width() == 96 else tex.get_width() / 2
	var cy: int = 24 if tex.get_height() == 48 else tex.get_height() / 2
	var pixel: Color = img.get_pixel(clampi(cx, 0, tex.get_width() - 1), clampi(cy, 0, tex.get_height() - 1))
	var lum: float = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
	if lum < 160.0 / 255.0:
		base = MessageConfig.LIGHT_TEXT_MAIN
		shadow = MessageConfig.LIGHT_TEXT_SHADOW
	return {"base": base, "shadow": shadow}


func is_typing() -> bool:
	return _typing


func display_text(text: String) -> void:
	_layout_content()
	_full_text = text
	_visible_chars = 0.0
	_typing = true
	visible = true
	# Sombra solo Y
	shadow_label.position = Vector2(0, 2)
	shadow_label.text = _full_text
	text_label.position = Vector2.ZERO
	text_label.text = _full_text
	_apply_visible_count(0)
	pause_arrow.visible = false
	_pause_frame = 0.0
	_place_pause_arrow()


func _apply_visible_count(count: int) -> void:
	text_label.visible_characters = count
	shadow_label.visible_characters = count


func skip_typing() -> void:
	if _typing:
		_finish_typing()


func hide_window() -> void:
	visible = false
	_typing = false
	pause_arrow.visible = false


func _finish_typing() -> void:
	_typing = false
	_apply_visible_count(-1)
	pause_arrow.visible = true
	_pause_frame = 0.0
	typing_finished.emit()


func _process(delta: float) -> void:
	if _typing:
		_advance_typing(delta)
		return
	_advance_pause_arrow(delta)


func _advance_typing(delta: float) -> void:
	var cps: float = 40.0 if _text_speed <= 0.0 else 1.0 / _text_speed
	_visible_chars += cps * delta
	var count: int = int(_visible_chars)
	_apply_visible_count(count)
	if count >= _full_text.length():
		_finish_typing()


func _advance_pause_arrow(delta: float) -> void:
	if not pause_arrow.visible or _pause_atlas == null:
		return
	_pause_frame += delta * PAUSE_FPS
	var idx: int = int(_pause_frame) % PAUSE_FRAME_COUNT
	_pause_atlas.region = Rect2(idx * PAUSE_FRAME_W, 0, PAUSE_FRAME_W, PAUSE_FRAME_H)
