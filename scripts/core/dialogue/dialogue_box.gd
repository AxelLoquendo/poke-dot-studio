extends CanvasLayer
class_name DialogueBox
## Caja estilo Pokémon Essentials (speech + name + choice).

signal typing_finished
signal choice_picked(index: int)

const CHARS_PER_SECOND: float = 50.0
const LAYER_INDEX: int = 95
const FONT_PATH: String = "res://font/power green.ttf"
const ARROW_PATH: String = "res://assets/ui/sel_arrow.png"

@onready var panel: NinePatchRect = $Panel
@onready var name_panel: NinePatchRect = $NamePanel
@onready var name_label: Label = $NamePanel/NameLabel
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var pause_arrow: TextureRect = $Panel/PauseArrow
@onready var choice_panel: NinePatchRect = $ChoicePanel
@onready var choice_list: VBoxContainer = $ChoicePanel/ChoiceList

var _full_text: String = ""
var _visible_chars: float = 0.0
var _typing: bool = false
var _choices: PackedStringArray = PackedStringArray()
var _choice_index: int = 0
var _showing_choices: bool = false
var _font: Font = null
var _sel_arrow: Texture2D = null
var _arrow_bob: float = 0.0


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if choice_panel:
		choice_panel.visible = false
	if name_panel:
		name_panel.visible = false
	if pause_arrow:
		pause_arrow.visible = false
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	if ResourceLoader.exists(ARROW_PATH):
		_sel_arrow = load(ARROW_PATH) as Texture2D
	DialogueManager.box = self
	add_to_group(&"dialogue_box")


func is_typing() -> bool:
	return _typing


func is_showing_choices() -> bool:
	return _showing_choices


func display_line(line: DialogueLine) -> void:
	visible = true
	_showing_choices = false
	if choice_panel:
		choice_panel.visible = false
	_full_text = line.text
	_visible_chars = 0.0
	_typing = true
	text_label.text = _full_text
	text_label.visible_characters = 0
	if pause_arrow:
		pause_arrow.visible = false
	if line.speaker_name.is_empty():
		name_panel.visible = false
	else:
		name_panel.visible = true
		name_label.text = line.speaker_name
		_fit_name_panel()


func skip_typing() -> void:
	if not _typing:
		return
	_typing = false
	text_label.visible_characters = -1
	if pause_arrow:
		pause_arrow.visible = true
	typing_finished.emit()


func hide_box() -> void:
	visible = false
	_typing = false
	_showing_choices = false
	if choice_panel:
		choice_panel.visible = false
	if name_panel:
		name_panel.visible = false
	if pause_arrow:
		pause_arrow.visible = false


func show_choices(choices: PackedStringArray) -> void:
	visible = true
	_typing = false
	_choices = choices
	_choice_index = 0
	_showing_choices = true
	if pause_arrow:
		pause_arrow.visible = false
	if choice_panel == null or choice_list == null or choices.is_empty():
		DialogueManager.select_choice(0)
		return
	for c: Node in choice_list.get_children():
		c.queue_free()
	for i: int in range(choices.size()):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var arrow: TextureRect = TextureRect.new()
		arrow.custom_minimum_size = Vector2(12, 12)
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if _sel_arrow != null:
			arrow.texture = _sel_arrow
		arrow.visible = (i == 0)
		arrow.name = "Arrow"
		var label: Label = Label.new()
		label.text = choices[i]
		if _font != null:
			label.add_theme_font_override("font", _font)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25))
		label.name = "Text"
		row.add_child(arrow)
		row.add_child(label)
		choice_list.add_child(row)
	# Altura dinámica del panel de choices
	var row_h: float = 28.0
	var h: float = 24.0 + float(choices.size()) * row_h
	choice_panel.offset_top = choice_panel.offset_bottom - h
	choice_panel.visible = true
	_refresh_choice_visual()


func _fit_name_panel() -> void:
	if name_label == null or name_panel == null:
		return
	var font: Font = name_label.get_theme_font("font")
	var size: int = name_label.get_theme_font_size("font_size")
	var text_w: float = 40.0
	if font != null:
		text_w = font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	name_panel.offset_right = name_panel.offset_left + text_w + 28.0


func _refresh_choice_visual() -> void:
	for i: int in range(choice_list.get_child_count()):
		var row: HBoxContainer = choice_list.get_child(i) as HBoxContainer
		if row == null:
			continue
		var arrow: TextureRect = row.get_node_or_null("Arrow") as TextureRect
		if arrow != null:
			arrow.visible = (i == _choice_index)


func _process(delta: float) -> void:
	if _typing:
		_visible_chars += CHARS_PER_SECOND * delta
		var count: int = int(_visible_chars)
		text_label.visible_characters = count
		if count >= _full_text.length():
			_typing = false
			text_label.visible_characters = -1
			if pause_arrow:
				pause_arrow.visible = true
			typing_finished.emit()
		return
	# Flecha de "más texto" parpadea / sube-baja
	if pause_arrow != null and pause_arrow.visible:
		_arrow_bob += delta * 6.0
		pause_arrow.position.y = sin(_arrow_bob) * 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _showing_choices:
		if event.is_action_pressed("Up"):
			_choice_index = (_choice_index - 1 + _choices.size()) % _choices.size()
			_refresh_choice_visual()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("Down"):
			_choice_index = (_choice_index + 1) % _choices.size()
			_refresh_choice_visual()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
			var idx: int = _choice_index
			_showing_choices = false
			choice_panel.visible = false
			choice_picked.emit(idx)
			DialogueManager.select_choice(idx)
			get_viewport().set_input_as_handled()
		return
