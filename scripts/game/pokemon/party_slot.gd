extends Node2D
class_name PartySlot

const UI: String = "res://assets/ui/Party/"
const BALL_PATH: String = UI + "icon_ball.png"
const BALL_SEL_PATH: String = UI + "icon_ball_sel.png"
const BLANK_PATH: String = UI + "panel_blank.png"
## PE: cambia de frame cada 4 * 60/20 = 12 frames a 60 fps.
const ICON_FRAME_TIME: float = 12.0 / 60.0

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

var slot_index: int = 0
var _selected: bool = false
var _preselected: bool = false
var _switching: bool = false
var _fainted: bool = false
var _empty: bool = true
var _icon_base: Vector2 = Vector2.ZERO
var _icon_timer: float = 0.0
var _icon_frame: int = 0


func _ready() -> void:
	if icon_mon != null:
		icon_mon.hframes = 2
		icon_mon.frame = 0
		icon_mon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon_base = icon_mon.position
	if icon_held != null:
		icon_held.visible = false
	if status != null:
		status.visible = false


func _process(delta: float) -> void:
	if icon_mon == null or not icon_mon.visible or icon_mon.texture == null:
		return
	_icon_timer += delta
	if _icon_timer >= ICON_FRAME_TIME:
		_icon_timer = 0.0
		_icon_frame = (_icon_frame + 1) % 2
		icon_mon.frame = _icon_frame
	# PE: seleccionado → x+4, y = -2 (frame 0) o +6 (frame 1)
	if _selected:
		var bob_y: float = -2.0 if _icon_frame == 0 else 6.0
		icon_mon.position = _icon_base + Vector2(4.0, bob_y)
	else:
		icon_mon.position = _icon_base


func setup(index: int) -> void:
	slot_index = index
	position = Vector2(
		float((index % 2) * 256),
		float((16 * (index % 2)) + (96 * int(index / 2.0)))
	)


func bind(mon: Pokemon) -> void:
	_empty = mon == null
	if mon == null:
		_show_empty()
		return

	visible = true
	_set_content_visible(true)
	if name_label != null:
		name_label.text = mon.display_name()
	if level_label != null:
		level_label.text = str(mon.level)

	var mx: int = maxi(1, mon.max_hp())
	var hp: int = clampi(mon.hp, 0, mx)
	if hp_number != null:
		hp_number.text = "%d/%d" % [hp, mx]
	_fainted = hp <= 0
	_set_hp_ratio(float(hp) / float(mx))

	if icon_mon != null:
		icon_mon.texture = PokemonGraphics.load_icon(mon.species_key, mon.form, mon.shiny)
		icon_mon.hframes = 2
		icon_mon.frame = _icon_frame
	if icon_held != null:
		icon_held.visible = mon.held_item != &""
	if gender_label != null:
		gender_label.text = ""
	_apply_panel_texture()


func set_selected(on: bool) -> void:
	_selected = on
	_apply_panel_texture()
	if ball != null and not _empty:
		var path: String = BALL_SEL_PATH if on else BALL_PATH
		if ResourceLoader.exists(path):
			ball.texture = load(path) as Texture2D


func set_switching(on: bool, preselected: bool = false) -> void:
	_switching = on
	_preselected = preselected
	_apply_panel_texture()


func _show_empty() -> void:
	visible = true
	_fainted = false
	_selected = false
	_preselected = false
	_switching = false
	if box != null and ResourceLoader.exists(BLANK_PATH):
		box.texture = load(BLANK_PATH) as Texture2D
		box.visible = true
	_set_content_visible(false)


func _set_content_visible(on: bool) -> void:
	if ball != null:
		ball.visible = on
	if icon_mon != null:
		icon_mon.visible = on
	if icon_held != null and not on:
		icon_held.visible = false
	if name_label != null:
		name_label.visible = on
	if gender_label != null:
		gender_label.visible = on
	if hp_back != null:
		hp_back.visible = on
	if hp_fill != null:
		hp_fill.visible = on
	if hp_number != null:
		hp_number.visible = on
	if level_label != null and level_label.get_parent() != null:
		level_label.get_parent().visible = on
	if status != null:
		status.visible = false


func _set_hp_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if hp_fill == null:
		return
	hp_fill.scale.x = ratio
	hp_fill.visible = ratio > 0.0


func _kind() -> String:
	return "round" if slot_index == 0 else "rect"


func _apply_panel_texture() -> void:
	if box == null or _empty:
		return
	var kind: String = _kind()
	var path: String
	if _selected and _preselected:
		path = UI + "panel_%s_swap_sel2.png" % kind
	elif _selected and _switching:
		path = UI + "panel_%s_swap_sel.png" % kind
	elif _selected and _fainted:
		path = UI + "panel_%s_faint_sel.png" % kind
	elif _selected:
		path = UI + "panel_%s_sel.png" % kind
	elif _preselected:
		path = UI + "panel_%s_swap.png" % kind
	elif _fainted:
		path = UI + "panel_%s_faint.png" % kind
	else:
		path = UI + "panel_%s.png" % kind
	if ResourceLoader.exists(path):
		box.texture = load(path) as Texture2D
	if hp_back != null:
		var hp_path: String = UI + "overlay_hp_back.png"
		if _preselected or (_selected and _switching):
			hp_path = UI + "overlay_hp_back_swap.png"
		elif _fainted:
			hp_path = UI + "overlay_hp_back_faint.png"
		if ResourceLoader.exists(hp_path):
			hp_back.texture = load(hp_path) as Texture2D
