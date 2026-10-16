extends Control
class_name PartyPanel

const ICON_FRAME: int = 64

var name_label: Label
var level_label: Label
var hp_label: Label
var hp_bar: ProgressBar
var icon: Sprite2D
var _selected: bool = false
var _built: bool = false


func build_ui() -> void:
	if _built:
		return
	_built = true

	var font: Font = null
	if MessageConfig != null:
		font = MessageConfig.load_font()

	var bg: ColorRect = ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.15, 0.15, 0.2, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	icon = Sprite2D.new()
	icon.name = "Icon"
	icon.centered = false
	icon.position = Vector2(8, 10)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.region_enabled = true
	icon.region_rect = Rect2(0, 0, ICON_FRAME, ICON_FRAME)
	add_child(icon)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(80, 8)
	name_label.size = Vector2(150, 28)
	if font != null:
		name_label.add_theme_font_override("font", font)
		name_label.add_theme_font_size_override("font_size", 22)
	add_child(name_label)

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.position = Vector2(80, 34)
	level_label.size = Vector2(80, 24)
	if font != null:
		level_label.add_theme_font_override("font", font)
		level_label.add_theme_font_size_override("font_size", 18)
	add_child(level_label)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HpBar"
	hp_bar.position = Vector2(80, 58)
	hp_bar.size = Vector2(100, 12)
	hp_bar.show_percentage = false
	hp_bar.max_value = 1
	hp_bar.value = 1
	add_child(hp_bar)

	hp_label = Label.new()
	hp_label.name = "HpLabel"
	hp_label.position = Vector2(185, 52)
	hp_label.size = Vector2(50, 24)
	if font != null:
		hp_label.add_theme_font_override("font", font)
		hp_label.add_theme_font_size_override("font_size", 16)
	add_child(hp_label)


func bind(mon: Pokemon) -> void:
	if not _built:
		build_ui()
	visible = mon != null
	if mon == null:
		icon.texture = null
		return

	name_label.text = mon.display_name()
	level_label.text = "Nv.%d" % mon.level
	var mx: int = maxi(1, mon.max_hp())
	hp_label.text = "%d/%d" % [mon.hp, mx]
	hp_bar.max_value = mx
	hp_bar.value = mon.hp

	_set_icon_texture(PokemonGraphics.load_icon(mon.species_key, mon.form, mon.shiny))


func set_selected(on: bool) -> void:
	_selected = on
	modulate = Color(1.25, 1.25, 1.0) if on else Color.WHITE


func _set_icon_texture(tex: Texture2D) -> void:
	icon.texture = tex
	if tex == null:
		return
	# Hoja PE: normalmente 128x64 → frame 0 = (0,0,64,64)
	var w: int = tex.get_width()
	var h: int = tex.get_height()
	var fw: int = ICON_FRAME
	var fh: int = ICON_FRAME
	if w < fw:
		fw = w
	if h < fh:
		fh = h
	icon.region_enabled = true
	icon.region_rect = Rect2(0, 0, fw, fh)
