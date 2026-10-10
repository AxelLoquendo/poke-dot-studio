@tool
extends ScriptCommand
class_name ScriptCmdText
## Muestra texto vía DialogueManager. Asíncrono.

@export_multiline var message: String = ""
@export var messages: Array[String] = []
@export var speaker_name: String = ""
@export var speaker_id: StringName = &""
@export var choices: Array[String] = []
@export var choice_variable: String = "last_choice"
@export var hide_speaker: bool = false


func execute(context: ScriptExecutionContext) -> bool:
	var pages: Array[String] = []
	for m: String in messages:
		if not m.is_empty():
			pages.append(m)
	if pages.is_empty() and not message.is_empty():
		pages.append(message)
	if pages.is_empty():
		return true

	var speaker: String = speaker_name
	if hide_speaker:
		speaker = ""
	elif speaker.is_empty() and speaker_id != &"":
		var node: Node = context.find_character_by_id(speaker_id)
		if node != null:
			speaker = str(node.name)

	# Choices → se anexan a la secuencia
	var lines: Array[DialogueLine] = []
	for i: int in range(pages.size()):
		var line: DialogueLine = DialogueLine.new()
		line.text = pages[i]
		line.speaker_name = speaker
		lines.append(line)

	var packed_choices: PackedStringArray = PackedStringArray()
	for c: String in choices:
		packed_choices.append(c)

	if not DialogueManager.dialogue_finished.is_connected(context.complete_async):
		DialogueManager.dialogue_finished.connect(context.complete_async, CONNECT_ONE_SHOT)

	if not choices.is_empty():
		if not DialogueManager.choice_selected.is_connected(_on_choice.bind(context)):
			DialogueManager.choice_selected.connect(_on_choice.bind(context), CONNECT_ONE_SHOT)
		var seq: DialogueSequence = DialogueSequence.new()
		seq.lines = lines
		seq.choices = packed_choices
		DialogueManager.show_sequence(seq)
	else:
		DialogueManager.show_sequence_lines(lines)

	context.is_waiting = true
	return false


func _on_choice(index: int, context: ScriptExecutionContext) -> void:
	context.set_variable(choice_variable, str(index))


func get_display_text() -> String:
	var preview: String = message if not message.is_empty() else (messages[0] if not messages.is_empty() else "")
	if preview.length() > 28:
		preview = preview.substr(0, 28) + "..."
	return "text: %s" % preview
