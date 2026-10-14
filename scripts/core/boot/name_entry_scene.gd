extends Control
class_name NameEntryScene
## Nombre por teclado (modalidad PC de PE). Sprite = overworld, no intro.

const DIR: String = "res://assets/ui/Naming/"
const MAX_LEN: int = 7

var _bg: TextureRect
var _subject: TextureRect
var _help: Label
var _line: LineEdit
var _busy: bool = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	await FadeScreen.fade_in(0.4)
	_line.grab_focus()
	_busy = false


func _build() -> void:
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP
	var bg_path: String = DIR + "bg_2.png"
	if not ResourceLoader.exists(bg_path):
		bg_path = DIR + "bg.png"
	if ResourceLoader.exists(bg_path):
		_bg.texture = load(bg_path) as Texture2D
	add_child(_bg)

	_subject = TextureRect.new()
	_subject.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_subject.stretch_mode = TextureRect.STRETCH_KEEP
	_subject.texture = _load_overworld_preview()
	if _subject.texture != null:
		_subject.size = _subject.texture.get_size()
	_subject.position = Vector2(48, 48)
	add_child(_subject)

	_help = Label.new()
	_help.text = "¿Cómo te llamas?"
	_help.position = Vector2(160, 28)
	_apply_font(_help, 24)
	_help.add_theme_color_override("font_color", Color.WHITE)
	add_child(_help)

	_line = LineEdit.new()
	_line.position = Vector2(172, 70)
	_line.size = Vector2(240, 32)
	_line.max_length = MAX_LEN
	_line.text = "Rojo" if NewGameState.is_male else "Hoja"
	_line.placeholder_text = "Nombre"
	_apply_line_font(_line, 24)
	_line.text_submitted.connect(_on_submitted)
	add_child(_line)


## Frame del charset de overworld (idle abajo), no introBoy.
func _load_overworld_preview() -> Texture2D:
	var pd: PlayerData = NewGameState.male_player_data if NewGameState.is_male \
		else NewGameState.female_player_data
	if pd == null:
		return null
	# Ajusta al campo real de tu CharacterBase / PlayerData:
	# ejemplos comunes: pd.sprite_sheet, pd.texture, pd.charset
	var sheet: Texture2D = null
	if pd.get("sprite_sheet") != null:
		sheet = pd.sprite_sheet as Texture2D
	elif pd.get("texture") != null:
		sheet = pd.texture as Texture2D
	if sheet == null:
		return null
	# Una celda idle mirando abajo (ajusta frame_w/h a tu sheet)
	var frame_w: int = 32
	var frame_h: int = 32
	if sheet.get_width() >= 128:
		frame_w = int(sheet.get_width() / 4.0)
		frame_h = int(sheet.get_height() / 4.0)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	# Fila "down", primer frame (idle) — típico en sheets 4×4
	atlas.region = Rect2(0, 0, frame_w, frame_h)
	return atlas


func _apply_font(lab: Label, size: int) -> void:
	var font: Font = MessageConfig.load_font()
	if font != null:
		lab.add_theme_font_override("font", font)
	lab.add_theme_font_size_override("font_size", size)


func _apply_line_font(line: LineEdit, size: int) -> void:
	var font: Font = MessageConfig.load_font()
	if font != null:
		line.add_theme_font_override("font", font)
	line.add_theme_font_size_override("font_size", size)


func _on_submitted(text: String) -> void:
	_finish(text)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	# Enter ya lo maneja text_submitted; Start también confirma
	if event.is_action_pressed("buttonStart"):
		_finish(_line.text)


func _finish(raw: String) -> void:
	var n: String = raw.strip_edges()
	if n.is_empty():
		return
	_busy = true
	NewGameState.player_name = n
	await FadeScreen.fade_out(0.4)
	SessionBoot.start_data = NewGameState.build_start_data()
	get_tree().change_scene_to_file("res://scenes/overworld/game/game_start.tscn")
