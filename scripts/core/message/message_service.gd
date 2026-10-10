extends Node
## Autoload: MessageService
## API estable para scripts. No conoce mapas ni NPCs.

signal message_started
signal message_finished
signal choice_selected(index: int)

var _ui: MessageUI = null
var _active: bool = false
var _last_choice: int = -1


func register_ui(ui: MessageUI) -> void:
	_ui = ui
	if not _ui.message_finished.is_connected(_on_ui_finished):
		_ui.message_finished.connect(_on_ui_finished)
	if not _ui.choice_selected.is_connected(_on_ui_choice):
		_ui.choice_selected.connect(_on_ui_choice)


func is_active() -> bool:
	return _active


func get_last_choice() -> int:
	return _last_choice


func show_text(text: String, speaker: String = "") -> void:
	var pages: PackedStringArray = PackedStringArray([text])
	show_pages(pages, speaker)


func show_pages(pages: PackedStringArray, speaker: String = "", choices: PackedStringArray = PackedStringArray()) -> void:
	if _ui == null:
		push_warning("MessageService: MessageUI no registrado")
		message_finished.emit()
		return
	_active = true
	_last_choice = -1
	message_started.emit()
	_ui.show_pages(pages, speaker, choices)


func show_texts(texts: Array[String], speaker: String = "", choices: Array[String] = []) -> void:
	var pages: PackedStringArray = PackedStringArray()
	for t: String in texts:
		if not t.is_empty():
			pages.append(t)
	var ch: PackedStringArray = PackedStringArray()
	for c: String in choices:
		ch.append(c)
	show_pages(pages, speaker, ch)


func _on_ui_finished() -> void:
	_active = false
	message_finished.emit()


func _on_ui_choice(index: int) -> void:
	_last_choice = index
	choice_selected.emit(index)
