extends Control
class_name NameEntryScene
## Nombre por teclado. Preview = frame idle Down del PlayerData elegido.

const DIR: String = "res://assets/ui/Naming/"
const MAX_LEN: int = 7

# PE-ish
const SUBJECT_POS: Vector2 = Vector2(40, 32)
const HELP_POS: Vector2 = Vector2(168, 26)
const NAME_POS: Vector2 = Vector2(172, 72)
const LINE_SIZE: Vector2 = Vector2(200, 28)

var _bg: TextureRect
var _subject: TextureRect
var _help: Label
var _line: LineEdit
var _busy: bool = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	await _fade_in()
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
	_bg.modulate.a = 0.0
	add_child(_bg)

	_subject = TextureRect.new()
	_subject.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_subject.stretch_mode = TextureRect.STRETCH_KEEP
	_subject.texture = _overworld_idle_down()
	if _subject.texture != null:
		_subject.size = _subject.texture.get_size()
	_subject.position = SUBJECT_POS
	add_child(_subject)

	_help = Label.new()
	_help.text = "¿Cómo te llamas?"
	_help.position = HELP_POS
	_font(_help)
	_help.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	add_child(_help)

	_line = LineEdit.new()
	_line.position = NAME_POS
	_line.size = LINE_SIZE
	_line.max_length = MAX_LEN
	_line.text = "Rojo" if NewGameState.is_male else "Hoja"
	_font_line(_line)
	_line.text_submitted.connect(func(t: String) -> void: _finish(t))
	add_child(_line)


func _overworld_idle_down() -> Texture2D:
	var pd: PlayerData = NewGameState.male_player_data if NewGameState.is_male \
		else NewGameState.female_player_data
	if pd == null:
		return null
	var path: String = str(EventObjects.ow_sprites.get(pd.ow, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var sheet: Texture2D = load(path) as Texture2D
	# Character.gd: sheet 3×4 → Idle Down = columna 1, fila 0
	var frame: Vector2 = sheet.get_size() / Vector2(3, 4)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(1, 0) * frame, frame)
	return atlas


func _font(lab: Label) -> void:
	var f: Font = MessageConfig.load_font()
	if f:
		lab.add_theme_font_override("font", f)
	lab.add_theme_font_size_override("font_size", 24)


func _font_line(line: LineEdit) -> void:
	var f: Font = MessageConfig.load_font()
	if f:
		line.add_theme_font_override("font", f)
	line.add_theme_font_size_override("font_size", 24)


func _fade_in() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_bg, "modulate:a", 1.0, 0.4)
	await tw.finished


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("buttonStart"):
		_finish(_line.text)


func _finish(raw: String) -> void:
	var n: String = raw.strip_edges()
	if n.is_empty():
		return
	_busy = true
	NewGameState.player_name = n
	var tw: Tween = create_tween()
	tw.tween_property(_bg, "modulate:a", 0.0, 0.4)
	await tw.finished
	FadeScreen.set_covered()
	SessionBoot.start_data = NewGameState.build_start_data()
	get_tree().change_scene_to_file("res://scenes/overworld/game/game_start.tscn")
