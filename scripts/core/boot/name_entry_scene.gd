extends Control
class_name NameEntryScene
## Entrada de nombre estilo PE PokemonEntryScene2 (simplificado).

const DIR: String = "res://assets/ui/Naming/"
const MAX_LEN: int = 7

const ROWS: int = 13
const COLS: int = 5
const GRID_X: float = 52.0
const GRID_Y: float = 180.0
const CELL_W: float = 32.0
const CELL_H: float = 38.0

## MAYUS / minus (PE @@Characters recortado)
const CHARS: Array[String] = [
	"ABCDEFGHIJ ,.KLMNOPQRST '-UVWXYZ     ♂♀             0123456789   ",
	"abcdefghij ,.klmnopqrst '-uvwxyz     ♂♀             0123456789   ",
]

@onready var bg: TextureRect = $Bg
@onready var preview: TextureRect = $Preview
@onready var name_label: Label = $NameLabel
@onready var help_label: Label = $HelpLabel
@onready var cursor: TextureRect = $Cursor
@onready var tab: TextureRect = $Tab

var _mode: int = 0
var _cursor: int = 0  # 0..64 grid, -1 OK, -2 BACK (simplificado: últimos dos “celdas” lógicas)
var _text: String = ""
var _busy: bool = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_text = "Rojo" if NewGameState.is_male else "Hoja"
	_setup_visuals()
	_rebuild_grid_labels()
	_update_name()
	_update_cursor()
	await FadeScreen.fade_in(0.4)
	_busy = false


func _setup_visuals() -> void:
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	var bg_path: String = DIR + "bg_2.png"
	if not ResourceLoader.exists(bg_path):
		bg_path = DIR + "bg.png"
	if ResourceLoader.exists(bg_path):
		bg.texture = load(bg_path) as Texture2D

	# Sprite del jugador (intro boy/girl)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP
	var face: String = "res://assets/Pictures/introBoy.png" if NewGameState.is_male \
		else "res://assets/Pictures/introGirl.png"
	if ResourceLoader.exists(face):
		preview.texture = load(face) as Texture2D
		preview.size = preview.texture.get_size()
	preview.position = Vector2(40, 40)

	help_label.text = "¿Cómo te llamas?"
	help_label.position = Vector2(160, 24)

	name_label.position = Vector2(172, 70)
	var font: Font = MessageConfig.load_font()
	if font != null:
		name_label.add_theme_font_override("font", font)
		help_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 24)
	help_label.add_theme_font_size_override("font_size", 24)

	if ResourceLoader.exists(DIR + "cursor_1.png"):
		cursor.texture = load(DIR + "cursor_1.png") as Texture2D
	cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor.stretch_mode = TextureRect.STRETCH_KEEP

	if ResourceLoader.exists(DIR + "overlay_tab_1.png"):
		tab.texture = load(DIR + "overlay_tab_%d.png" % (_mode + 1)) as Texture2D
	tab.position = Vector2(22, 162)
	tab.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tab.stretch_mode = TextureRect.STRETCH_KEEP


func _char_at(index: int) -> String:
	var s: String = CHARS[_mode]
	if index < 0 or index >= s.length():
		return " "
	return s.substr(index, 1)


func _rebuild_grid_labels() -> void:
	# Borra labels viejos del grid
	for c: Node in get_children():
		if c.name.begins_with("Cell_"):
			c.queue_free()
	var font: Font = MessageConfig.load_font()
	for i: int in mini(CHARS[_mode].length(), ROWS * COLS):
		var ch: String = _char_at(i)
		if ch == " ":
			continue
		var lab: Label = Label.new()
		lab.name = "Cell_%d" % i
		var col: int = i % ROWS
		var row: int = int(i / ROWS)
		lab.position = Vector2(GRID_X + col * CELL_W - 6.0, GRID_Y + row * CELL_H - 4.0)
		lab.text = ch
		if font != null:
			lab.add_theme_font_override("font", font)
		lab.add_theme_font_size_override("font_size", 24)
		lab.add_theme_color_override("font_color", Color(16 / 255.0, 24 / 255.0, 32 / 255.0))
		lab.add_theme_color_override("font_shadow_color", Color(160 / 255.0, 160 / 255.0, 160 / 255.0))
		lab.add_theme_constant_override("shadow_offset_x", 0)
		lab.add_theme_constant_override("shadow_offset_y", 2)
		add_child(lab)
	# Tab overlay por modo
	var tab_path: String = DIR + "overlay_tab_%d.png" % (_mode + 1)
	if ResourceLoader.exists(tab_path):
		tab.texture = load(tab_path) as Texture2D


func _update_name() -> void:
	name_label.text = _text


func _update_cursor() -> void:
	if _cursor < 0:
		return
	var col: int = _cursor % ROWS
	var row: int = int(_cursor / ROWS)
	cursor.position = Vector2(GRID_X + col * CELL_W - 8.0, GRID_Y + row * CELL_H - 8.0)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Left"):
		_cursor = posmod(_cursor - 1, ROWS * COLS)
		_update_cursor()
	elif event.is_action_pressed("Right"):
		_cursor = posmod(_cursor + 1, ROWS * COLS)
		_update_cursor()
	elif event.is_action_pressed("Up"):
		_cursor = posmod(_cursor - ROWS, ROWS * COLS)
		_update_cursor()
	elif event.is_action_pressed("Down"):
		_cursor = posmod(_cursor + ROWS, ROWS * COLS)
		_update_cursor()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_press_cell()
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		_backspace()
	# Select = cambiar pestaña (MAYUS/minus)
	elif event.is_action_pressed("buttonSelect") or event.is_action_pressed("ui_focus_next"):
		_mode = (_mode + 1) % CHARS.size()
		_rebuild_grid_labels()


func _press_cell() -> void:
	var ch: String = _char_at(_cursor)
	if ch == " ":
		return
	if _text.length() >= MAX_LEN:
		return
	_text += ch
	_update_name()


func _backspace() -> void:
	if _text.is_empty():
		return
	_text = _text.substr(0, _text.length() - 1)
	_update_name()


## Confirmar: mantén Start o un botón dedicado; aquí Start = OK
func _input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("buttonStart") or event.is_action_pressed("ui_home"):
		_confirm()


func _confirm() -> void:
	var n: String = _text.strip_edges()
	if n.is_empty():
		return
	_busy = true
	NewGameState.player_name = n
	await FadeScreen.fade_out(0.4)
	SessionBoot.start_data = NewGameState.build_start_data()
	get_tree().change_scene_to_file("res://scenes/overworld/game/game_start.tscn")
