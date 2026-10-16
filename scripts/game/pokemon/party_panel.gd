extends Control
class_name PartyPanel

var name_label: Label
var level_label: Label
var hp_label: Label
var hp_bar: ProgressBar
var _selected: bool = false
var _built: bool = false


func build_ui() -> void:
	if _built:
		return
	_built = true

	var font: Font = null
	if MessageConfig != null:
		font = MessageConfig.load_font()

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(12, 8)
	name_label.size = Vector2(180, 28)
	if font != null:
		name_label.add_theme_font_override("font", font)
		name_label.add_theme_font_size_override("font_size", 22)
	add_child(name_label)

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.position = Vector2(12, 34)
	level_label.size = Vector2(80, 24)
	if font != null:
		level_label.add_theme_font_override("font", font)
		level_label.add_theme_font_size_override("font_size", 18)
	add_child(level_label)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HpBar"
	hp_bar.position = Vector2(12, 58)
	hp_bar.size = Vector2(140, 12)
	hp_bar.show_percentage = false
	hp_bar.max_value = 1
	hp_bar.value = 1
	add_child(hp_bar)

	hp_label = Label.new()
	hp_label.name = "HpLabel"
	hp_label.position = Vector2(160, 52)
	hp_label.size = Vector2(70, 24)
	if font != null:
		hp_label.add_theme_font_override("font", font)
		hp_label.add_theme_font_size_override("font_size", 16)
	add_child(hp_label)

	# Fondo simple; luego puedes poner TextureRect con panel_rect.png
	var bg: ColorRect = ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.15, 0.15, 0.2, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func bind(mon: Pokemon) -> void:
	if not _built:
		build_ui()
	visible = mon != null
	if mon == null:
		return
	name_label.text = mon.display_name()
	level_label.text = "Nv.%d" % mon.level
	var mx: int = maxi(1, mon.max_hp())
	hp_label.text = "%d/%d" % [mon.hp, mx]
	hp_bar.max_value = mx
	hp_bar.value = mon.hp


func set_selected(on: bool) -> void:
	_selected = on
	modulate = Color(1.25, 1.25, 1.0) if on else Color.WHITE
