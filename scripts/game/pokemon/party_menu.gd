extends CanvasLayer
class_name PartyMenu

signal closed

const MENU_SCENE: String = "res://scenes/ui/party_menu/party_menu.tscn"
const CANCEL_PATH: String = "res://assets/ui/Party/icon_cancel.png"
const CANCEL_SEL_PATH: String = "res://assets/ui/Party/icon_cancel_sel.png"

var party: Party
var _index: int = 0
var _slots: Array[PartySlot] = []
var _active: bool = false
var _cancel: Sprite2D
var _cancel_label: Label
var _msg_label: Label


func _ready() -> void:
	layer = 91
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_collect_slots()


func open(p: Party) -> void:
	party = p
	_index = 0
	_active = true
	_collect_slots()
	_refresh()
	_set_help("Elige un Pokémon.")
	visible = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	closed.emit()


func _collect_slots() -> void:
	_slots.clear()
	var panels: Node = get_node_or_null("Panels")
	if panels == null:
		return
	for child: Node in panels.get_children():
		if child is PartySlot:
			_slots.append(child as PartySlot)
		elif child.get_script() != null and child.has_method("bind"):
			_slots.append(child as PartySlot)
	# Orden por nombre Party_Slot, Party_Slot2…
	_slots.sort_custom(func(a: Node, b: Node) -> bool: return str(a.name) < str(b.name))

	_cancel = get_node_or_null("Cancel") as Sprite2D
	if _cancel != null:
		_cancel_label = _cancel.get_node_or_null("CancelLabel") as Label
	var box_msg: Node = get_node_or_null("Box_Msg")
	if box_msg != null:
		_msg_label = box_msg.get_node_or_null("Text") as Label


func _refresh() -> void:
	var count: int = party.size() if party != null else 0
	for i: int in range(_slots.size()):
		var mon: Pokemon = party.get_at(i) if party != null else null
		_slots[i].bind(mon)
		# índice 0..count-1 mons; count = cancel
		_slots[i].set_selected(_active and i == _index and i < count)

	var on_cancel: bool = _active and _index >= count
	if _cancel != null:
		var path: String = CANCEL_SEL_PATH if on_cancel else CANCEL_PATH
		if ResourceLoader.exists(path):
			_cancel.texture = load(path) as Texture2D


func _set_help(text: String) -> void:
	if _msg_label != null:
		_msg_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	var count: int = party.size() if party != null else 0
	# Navegación: 0..count-1 mons, count = Salir
	var max_index: int = count  # incluye cancel
	var moved: bool = false

	if event.is_action_pressed("ui_down") or event.is_action_pressed("Down"):
		if _index < count:
			_index = mini(_index + 2, count)
		moved = true
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("Up"):
		if _index >= count:
			_index = maxi(count - 1, 0)
		else:
			_index = maxi(_index - 2, 0)
		moved = true
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		_index = mini(_index + 1, max_index)
		moved = true
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("Left"):
		_index = maxi(_index - 1, 0)
		moved = true
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		if _index >= count:
			close()
		else:
			# Más adelante: submenú Resumen / Mover
			_set_help("Resumen (próximamente).")
		get_viewport().set_input_as_handled()
		return

	if moved:
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_refresh()
		get_viewport().set_input_as_handled()
