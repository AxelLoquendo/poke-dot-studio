extends CanvasLayer
class_name DialogueBox
## Caja de mensaje estilo Essentials + choices con teclado.

signal typing_finished
signal choice_picked(index: int)

const CHARS_PER_SECOND: float = 45.0
const LAYER_INDEX: int = 95

@onready var panel: NinePatchRect = $Panel
@onready var name_panel: NinePatchRect = $NamePanel
@onready var name_label: Label = $NamePanel/NameLabel
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var choice_panel: NinePatchRect = $ChoicePanel
@onready var choice_list: VBoxContainer = $ChoicePanel/ChoiceList

var _full_text: String = ""
var _visible_chars: float = 0.0
var _typing: bool = false
var _choices: PackedStringArray = PackedStringArray()
var _choice_index: int = 0
var _showing_choices: bool = false


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if choice_panel:
		choice_panel.visible = false
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
	if line.speaker_name.is_empty():
		name_panel.visible = false
	else:
		name_panel.visible = true
		name_label.text = line.speaker_name


func skip_typing() -> void:
	if not _typing:
		return
	_typing = false
	text_label.visible_characters = -1
	typing_finished.emit()


func hide_box() -> void:
	visible = false
	_typing = false
	_showing_choices = false
	if choice_panel:
		choice_panel.visible = false


func show_choices(choices: PackedStringArray) -> void:
	visible = true
	_typing = false
	_choices = choices
	_choice_index = 0
	_showing_choices = true
	if choice_panel == null or choice_list == null:
		# Fallback: primera opción automática
		DialogueManager.select_choice(0)
		return
	for c: Node in choice_list.get_children():
		c.queue_free()
	for i: int in range(choices.size()):
		var label: Label = Label.new()
		label.text = "  " + choices[i]
		label.add_theme_font_size_override("font_size", 10)
		choice_list.add_child(label)
	choice_panel.visible = true
	_refresh_choice_visual()


func _refresh_choice_visual() -> void:
	for i: int in range(choice_list.get_child_count()):
		var label: Label = choice_list.get_child(i) as Label
		if label == null:
			continue
		var prefix: String = "> " if i == _choice_index else "  "
		label.text = prefix + _choices[i]
		label.modulate = Color(1, 1, 0.4) if i == _choice_index else Color.WHITE


func _process(delta: float) -> void:
	if not _typing:
		return
	_visible_chars += CHARS_PER_SECOND * delta
	var count: int = int(_visible_chars)
	text_label.visible_characters = count
	if count >= _full_text.length():
		_typing = false
		text_label.visible_characters = -1
		typing_finished.emit()


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
