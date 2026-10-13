extends CanvasLayer
class_name LocationSignpost

const APPEAR_TIME: float = 0.4
const LINGER_TIME: float = 1.6
const LAYER_INDEX: int = 90

## Ajuste fino del texto dentro del banner (depende del PNG).
const TEXT_OFFSET: Vector2 = Vector2(12, 6)

var _root: Control
var _banner: TextureRect
var _label: Label
var _tween: Tween
var _last_name: String = ""
var _showing: bool = false


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_banner = TextureRect.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.stretch_mode = TextureRect.STRETCH_KEEP
	_root.add_child(_banner)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font: Font = MessageConfig.load_font()
	if font != null:
		_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", MessageConfig.FONT_SIZE)
	_label.add_theme_color_override("font_color", MessageConfig.DARK_TEXT_MAIN)
	_label.add_theme_color_override("font_shadow_color", MessageConfig.DARK_TEXT_SHADOW)
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_root.add_child(_label)


func try_show_for_map(mapa: Map) -> void:
	if mapa == null or mapa.attributes == null:
		return
	if not mapa.attributes.show_location_name:
		return
	var nombre: String = mapa.attributes.map_name.strip_edges()
	if nombre.is_empty():
		return
	if nombre == _last_name:
		return
	var tex: Texture2D = LocationSignpostConfig.texture_for(mapa.attributes.location_style, mapa.attributes.location_type)
	if tex == null:
		return
	_last_name = nombre
	show_name(nombre, tex)


func show_name(nombre: String, tex: Texture2D) -> void:
	_kill_tween()
	_showing = true
	_label.text = nombre
	_banner.texture = tex

	var size: Vector2 = tex.get_size()
	_banner.size = size
	_label.position = TEXT_OFFSET
	_label.size = size - TEXT_OFFSET * 2.0

	_root.size = size
	_root.position = Vector2(0.0, -size.y)
	visible = true

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_root, "position:y", 0.0, APPEAR_TIME).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_interval(LINGER_TIME)
	_tween.tween_property(_root, "position:y", -size.y, APPEAR_TIME).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(_hide_done)


func hide_immediate() -> void:
	_kill_tween()
	_hide_done()


func _hide_done() -> void:
	_showing = false
	visible = false


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _process(_delta: float) -> void:
	if _showing and MessageService.is_active():
		hide_immediate()
