extends Node2D
class_name PartySlot
## Slot visual del party (gráficos PE).

const PANEL_PATH: String = "res://assets/ui/Party/panel_rect.png"
const PANEL_SEL_PATH: String = "res://assets/ui/Party/panel_rect_sel.png"
const PANEL_FAINT_PATH: String = "res://assets/ui/Party/panel_rect_faint.png"
const PANEL_FAINT_SEL_PATH: String = "res://assets/ui/Party/panel_rect_faint_sel.png"
const BALL_PATH: String = "res://assets/ui/Party/icon_ball.png"
const BALL_SEL_PATH: String = "res://assets/ui/Party/icon_ball_sel.png"

@onready var box: Sprite2D = $Box
@onready var ball: Sprite2D = $Box/Ball
@onready var icon_mon: Sprite2D = $Box/Icon_Mon
@onready var icon_held: Sprite2D = $Box/Icon_Mon/Icon_Held
@onready var name_label: Label = $Box/Name_Mon
@onready var gender_label: Label = $Box/Gender
@onready var hp_back: Sprite2D = $Box/HpBar
@onready var hp_fill: Sprite2D = $Box/HpBar/ProgressBar
@onready var hp_number: Label = $Box/HpBar/HpNumber
@onready var level_label: Label = $Box/Nivel/Number
@onready var status: Sprite2D = $Status

var _selected: bool = false
var _fainted: bool = false
var _hp_fill_full_width: float = 96.0


func _ready() -> void:
	if hp_fill != null and hp_fill.texture != null:
		_hp_fill_full_width = float(hp_fill.texture.get_width())
	if icon_mon != null:
		icon_mon.hframes = 2
		icon_mon.frame = 0
		icon_mon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if icon_held != null:
		icon_held.visible = false
	if status != null:
		status.visible = false


func bind(mon: Pokemon) -> void:
	visible = mon != null
	if mon == null:
		return

	name_label.text = mon.display_name()
	level_label.text = str(mon.level)

	var mx: int = maxi(1, mon.max_hp())
	var hp: int = clampi(mon.hp, 0, mx)
	hp_number.text = "%d/%d" % [hp, mx]
	_fainted = hp <= 0
	_set_hp_ratio(float(hp) / float(mx))

	icon_mon.texture = PokemonGraphics.load_icon(mon.species_key, mon.form, mon.shiny)
	icon_mon.hframes = 2
	icon_mon.frame = 0

	if mon.held_item != &"" and icon_held != null:
		icon_held.visible = true
		# icon_item del UI; más adelante el sprite del item real
	else:
		if icon_held != null:
			icon_held.visible = false

	# Género aún no está en Pokemon: ocultar o dejar vacío
	if gender_label != null:
		gender_label.text = ""

	_apply_panel_texture()


func set_selected(on: bool) -> void:
	_selected = on
	_apply_panel_texture()
	if ball != null:
		var path: String = BALL_SEL_PATH if on else BALL_PATH
		if ResourceLoader.exists(path):
			ball.texture = load(path) as Texture2D


func _set_hp_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if hp_fill == null:
		return
	# Escala horizontal del fill (overlay_hp)
	hp_fill.scale.x = ratio
	hp_fill.visible = ratio > 0.0


func _apply_panel_texture() -> void:
	if box == null:
		return
	var path: String
	if _fainted:
		path = PANEL_FAINT_SEL_PATH if _selected else PANEL_FAINT_PATH
	else:
		path = PANEL_SEL_PATH if _selected else PANEL_PATH
	if ResourceLoader.exists(path):
		box.texture = load(path) as Texture2D
