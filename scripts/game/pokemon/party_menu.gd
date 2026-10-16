extends CanvasLayer
class_name PartyMenu
## Menú de equipo. Solo lectura + navegación por ahora.

signal closed

const BG_PATH: String = "res://assets/ui/Party/bg.png"
const PANEL_W: float = 236.0
const PANEL_H: float = 76.0
const ORIGIN: Vector2 = Vector2(12.0, 12.0)
const COL_GAP: float = 12.0
const ROW_GAP: float = 8.0

var party: Party
var _index: int = 0
var _panels: Array[PartyPanel] = []
var _active: bool = false
var _root: Control
var _cancel_label: Label


func _ready() -> void:
	layer = 91
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_if_needed()


func open(p: Party) -> void:
	party = p
	_index = 0
	_active = true
	_build_if_needed()
	_refresh()
	visible = true
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	closed.emit()


func _build_if_needed() -> void:
	if _root != null:
		return

	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg_tex: Texture2D = null
	if ResourceLoader.exists(BG_PATH):
		bg_tex = load(BG_PATH) as Texture2D
	if bg_tex != null:
		var bg: TextureRect = TextureRect.new()
		bg.name = "Background"
		bg.texture = bg_tex
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		_root.add_child(bg)

	for i: int in range(6):
		var panel: PartyPanel = PartyPanel.new()
		panel.name = "Panel%d" % i
		var col: int = i % 2
		var row: int = int(i / 2.0)
		panel.position = ORIGIN + Vector2(
			col * (PANEL_W + COL_GAP),
			row * (PANEL_H + ROW_GAP)
		)
		panel.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
		panel.size = Vector2(PANEL_W, PANEL_H)
		_root.add_child(panel)
		panel.build_ui()
		_panels.append(panel)

	_cancel_label = Label.new()
	_cancel_label.name = "CancelLabel"
	_cancel_label.text = "Salir"
	_cancel_label.position = Vector2(400.0, 340.0)
	var font: Font = MessageConfig.load_font() if MessageConfig != null else null
	if font != null:
		_cancel_label.add_theme_font_override("font", font)
		_cancel_label.add_theme_font_size_override("font_size", 24)
	_root.add_child(_cancel_label)


func _refresh() -> void:
	var count: int = party.size() if party != null else 0
	for i: int in range(6):
		var mon: Pokemon = party.get_at(i) if party != null else null
		_panels[i].bind(mon)
		_panels[i].set_selected(_active and i == _index and i < count)
	if _cancel_label != null:
		var on_cancel: bool = _active and count > 0 and _index >= count
		_cancel_label.modulate = Color(1.2, 1.2, 0.8) if on_cancel else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not _active or party == null:
		return

	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	var size: int = party.size()
	if size <= 0:
		if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
			close()
			get_viewport().set_input_as_handled()
		return

	# Navegación en rejilla 2 columnas (como PE)
	var moved: bool = false
	if event.is_action_pressed("ui_down") or event.is_action_pressed("Down"):
		_index = mini(_index + 2, size - 1)
		moved = true
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("Up"):
		_index = maxi(_index - 2, 0)
		moved = true
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		_index = mini(_index + 1, size - 1)
		moved = true
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("Left"):
		_index = maxi(_index - 1, 0)
		moved = true
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		# Por ahora solo cierra; luego submenú Resumen/Cambiar
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		close()
		get_viewport().set_input_as_handled()
		return

	if moved:
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		_refresh()
		get_viewport().set_input_as_handled()
