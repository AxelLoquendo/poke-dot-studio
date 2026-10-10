extends CanvasLayer
class_name DialogueBox
## Caja de mensaje estilo Essentials. Tipado letra a letra.

signal typing_finished

const CHARS_PER_SECOND: float = 45.0
const LAYER_INDEX: int = 95

@onready var panel: NinePatchRect = $Panel
@onready var name_panel: NinePatchRect = $NamePanel
@onready var name_label: Label = $NamePanel/NameLabel
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var choice_container: VBoxContainer = $Panel/ChoiceContainer

var _full_text: String = ""
var _visible_chars: float = 0.0
var _typing: bool = false


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if choice_container:
		choice_container.visible = false
	DialogueManager.box = self


func is_typing() -> bool:
	return _typing


func display_line(line: DialogueLine) -> void:
	visible = true
	if choice_container:
		choice_container.visible = false
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
	if choice_container:
		choice_container.visible = false


func show_choices(choices: PackedStringArray) -> void:
	# v1: labels simples; luego botones con skin Sky
	visible = true
	_typing = false
	if choice_container == null:
		return
	for c: Node in choice_container.get_children():
		c.queue_free()
	choice_container.visible = true
	for i: int in range(choices.size()):
		var btn: Button = Button.new()
		btn.text = choices[i]
		var idx: int = i
		btn.pressed.connect(func() -> void: DialogueManager.select_choice(idx))
		choice_container.add_child(btn)


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
