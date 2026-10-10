class_name MessageUI
extends CanvasLayer
## Orquesta MessageWindow + NameWindow + ChoiceWindow (layout PE).

signal message_finished
signal choice_selected(index: int)

var message_window: MessageWindow
var name_window: NameWindow
var choice_window: ChoiceWindow

var _pages: PackedStringArray = PackedStringArray()
var _page_index: int = 0
var _speaker: String = ""
var _pending_choices: PackedStringArray = PackedStringArray()
var _busy: bool = false
var _awaiting_advance: bool = false


func _ready() -> void:
	layer = MessageConfig.MESSAGE_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"message_ui")

	message_window = MessageWindow.new()
	message_window.name = "MessageWindow"
	add_child(message_window)
	message_window.setup()
	message_window.typing_finished.connect(_on_typing_finished)

	name_window = NameWindow.new()
	name_window.name = "NameWindow"
	add_child(name_window)
	name_window.setup()

	choice_window = ChoiceWindow.new()
	choice_window.name = "ChoiceWindow"
	add_child(choice_window)
	choice_window.setup()
	choice_window.choice_confirmed.connect(_on_choice_confirmed)

	if MessageService != null:
		MessageService.register_ui(self)


func is_busy() -> bool:
	return _busy


func show_pages(pages: PackedStringArray, speaker: String = "", choices: PackedStringArray = PackedStringArray()) -> void:
	if pages.is_empty():
		message_finished.emit()
		return
	_pages = pages
	_page_index = 0
	_speaker = speaker
	_pending_choices = choices
	_busy = true
	_show_current_page()


func _show_current_page() -> void:
	_awaiting_advance = false
	var msg_rect: Rect2 = MessageConfig.message_rect()
	if _speaker.is_empty():
		name_window.hide_window()
	else:
		name_window.show_name(_speaker, msg_rect)
	message_window.display_text(_pages[_page_index])
	var last_page: bool = _page_index >= _pages.size() - 1
	if last_page and not _pending_choices.is_empty():
		choice_window.show_choices(_pending_choices, msg_rect)
	else:
		choice_window.hide_window()


func _on_typing_finished() -> void:
	_awaiting_advance = true


func _on_choice_confirmed(index: int) -> void:
	_busy = false
	name_window.hide_window()
	message_window.hide_window()
	choice_selected.emit(index)
	message_finished.emit()


func _finish_all() -> void:
	_busy = false
	_pending_choices = PackedStringArray()
	name_window.hide_window()
	message_window.hide_window()
	choice_window.hide_window()
	message_finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _busy:
		return
	if choice_window.is_active():
		if message_window.is_typing() and (event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept")):
			message_window.skip_typing()
			get_viewport().set_input_as_handled()
			return
		if choice_window.handle_input(event):
			get_viewport().set_input_as_handled()
		return
	if not (event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if message_window.is_typing():
		message_window.skip_typing()
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		return
	if not _awaiting_advance:
		return
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
	_page_index += 1
	if _page_index >= _pages.size():
		_finish_all()
	else:
		_show_current_page()
