@tool
extends ScriptCommand
class_name ScriptCmdText
## Muestra texto vía MessageService. Asíncrono.

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
			speaker = _display_name(node)
	elif speaker.is_empty() and context.npc != null:
		speaker = _display_name(context.npc)

	if not MessageService.message_finished.is_connected(context.complete_async):
		MessageService.message_finished.connect(context.complete_async, CONNECT_ONE_SHOT)

	if not choices.is_empty():
		if not MessageService.choice_selected.is_connected(_on_choice.bind(context)):
			MessageService.choice_selected.connect(_on_choice.bind(context), CONNECT_ONE_SHOT)

	MessageService.show_texts(pages, speaker, choices)
	context.is_waiting = true
	return false


func _on_choice(index: int, context: ScriptExecutionContext) -> void:
	context.set_variable(choice_variable, str(index))


func _display_name(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_display_name"):
		return str(node.call("get_display_name"))
	if "data" in node:
		var data: Variant = node.get("data")
		if data != null and data is Resource and "name" in data:
			var n: String = str(data.get("name"))
			if not n.is_empty():
				return n
	return str(node.name)


func get_display_text() -> String:
	var preview: String = message if not message.is_empty() else (messages[0] if not messages.is_empty() else "")
	if preview.length() > 28:
		preview = preview.substr(0, 28) + "..."
	return "text: %s" % preview
