extends Node
## Autoload: DialogueManager
## Cola de diálogo. Bloquea input de overworld mientras is_active.

signal dialogue_started
signal dialogue_finished
signal line_shown(line: DialogueLine)
signal choice_selected(index: int)

var _queue: Array[DialogueLine] = []
var _choices: PackedStringArray = PackedStringArray()
var _active: bool = false
var _waiting_choice: bool = false

var box: DialogueBox  # asignado por la UI al entrar al árbol


func is_active() -> bool:
	return _active


func show_text(text: String, speaker: String = "") -> void:
	var line: DialogueLine = DialogueLine.new()
	line.text = text
	line.speaker_name = speaker
	show_sequence_lines([line])


func show_sequence(seq: DialogueSequence) -> void:
	if seq == null:
		return
	_choices = seq.choices.duplicate()
	show_sequence_lines(seq.lines)


func show_sequence_lines(lines: Array[DialogueLine]) -> void:
	for line: DialogueLine in lines:
		if line != null and not line.text.is_empty():
			_queue.append(line)
	if not _active and not _queue.is_empty():
		_start()


func advance() -> void:
	if not _active or _waiting_choice:
		return
	if box != null and box.is_typing():
		box.skip_typing()
		return
	_show_next()


func select_choice(index: int) -> void:
	if not _waiting_choice:
		return
	_waiting_choice = false
	choice_selected.emit(index)
	_end()


func _start() -> void:
	_active = true
	dialogue_started.emit()
	_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		if not _choices.is_empty() and box != null:
			_waiting_choice = true
			box.show_choices(_choices)
			return
		_end()
		return
	var line: DialogueLine = _queue.pop_front()
	line_shown.emit(line)
	if box != null:
		box.display_line(line)


func _end() -> void:
	_queue.clear()
	_choices = PackedStringArray()
	_waiting_choice = false
	_active = false
	if box != null:
		box.hide_box()
	dialogue_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()
