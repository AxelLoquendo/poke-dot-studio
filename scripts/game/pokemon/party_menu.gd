extends CanvasLayer
class_name PartyMenu

signal closed

var party: Party
var _index: int = 0
var _panels: Array[PartyPanel] = []
var _active: bool = false


func open(p: Party) -> void:
	party = p
	_index = 0
	_active = true
	visible = true
	_refresh()


func close() -> void:
	_active = false
	visible = false
	closed.emit()


func _refresh() -> void:
	for i: int in range(6):
		if i < _panels.size():
			_panels[i].bind(party.get_at(i) if party else null)
			_panels[i].set_selected(i == _index and party != null and i < party.size())


func _unhandled_input(event: InputEvent) -> void:
	if not _active or party == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("buttonB"):
		close()
		get_viewport().set_input_as_handled()
		return
	var size: int = party.size()
	if size <= 0:
		return
	if event.is_action_pressed("Down"):
		_index = mini(_index + 2, size - 1)
		_refresh()
	elif event.is_action_pressed("Up"):
		_index = maxi(_index - 2, 0)
		_refresh()
	elif event.is_action_pressed("Right"):
		_index = mini(_index + 1, size - 1)
		_refresh()
	elif event.is_action_pressed("Left"):
		_index = maxi(_index - 1, 0)
		_refresh()
