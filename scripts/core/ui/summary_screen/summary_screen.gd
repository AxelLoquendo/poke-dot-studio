extends CanvasLayer
class_name SummaryScreen
## Resumen estilo PE. Por ahora solo página INFO (page 0).

signal closed

const SCENE_PATH: String = "res://scenes/ui/summary_screen/summary_screen.tscn"

var party: Party
var party_index: int = 0
var _page: int = 0
var _active: bool = false

@onready var page0: SummaryPage0 = $Page0 as SummaryPage0


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(p: Party, index: int = 0) -> void:
	party = p
	party_index = clampi(index, 0, maxi(0, p.size() - 1) if p != null else 0)
	_page = 0
	_active = true
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


func _refresh() -> void:
	if party == null or page0 == null:
		return
	var mon: Pokemon = party.get_at(party_index)
	page0.visible = true
	page0.bind(mon)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	# Cambiar de Pokémon (PE: arriba/abajo)
	if event.is_action_pressed("ui_up") or event.is_action_pressed("Up"):
		if party != null and party.size() > 1:
			party_index = posmod(party_index - 1, party.size())
			_refresh()
			MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("Down"):
		if party != null and party.size() > 1:
			party_index = posmod(party_index + 1, party.size())
			_refresh()
			MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		get_viewport().set_input_as_handled()
		return
	# Páginas futuras: Left/Right
	if event.is_action_pressed("ui_left") or event.is_action_pressed("Left") \
			or event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		# Solo page 0 por ahora
		get_viewport().set_input_as_handled()


static func open_for(host: Node, p: Party, index: int = 0) -> SummaryScreen:
	var sc: SummaryScreen = (load(SCENE_PATH) as PackedScene).instantiate() as SummaryScreen
	host.add_child(sc)
	sc.open(p, index)
	return sc
