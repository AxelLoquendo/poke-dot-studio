extends CanvasLayer
class_name SummaryScreen
## Header compartido (Mon) + páginas. Page0 = INFO.

signal closed

const SCENE_PATH: String = "res://scenes/ui/summary_screen/summary_screen.tscn"

var party: Party
var party_index: int = 0
var _page: int = 0
var _active: bool = false

@onready var page0: SummaryPage0 = $Page0 as SummaryPage0
@onready var mon_sprite: Sprite2D = $Mon
@onready var mon_name: Label = $Mon/Mon_Name
@onready var mon_level: Label = $Mon/Lvl
@onready var mon_gender: Label = $Mon/Gender
@onready var ball: Sprite2D = $Mon/Ball
@onready var item_sprite: Node2D = $Mon/Item_Sprite
@onready var item_name: Label = $Mon/Item/Item_Name


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
	_play_current_cry()

func close() -> void:
	if not _active:
		return
	PokemonCry.stop()
	_active = false
	visible = false
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	closed.emit()

func _play_current_cry() -> void:
	if party == null:
		return
	var mon: Pokemon = party.get_at(party_index)
	if mon == null:
		return
	PokemonCry.play(mon.species_key, mon.form)

func _refresh() -> void:
	if party == null:
		return
	var mon: Pokemon = party.get_at(party_index)
	_bind_header(mon)
	if page0 != null:
		page0.visible = (_page == 0)
		if _page == 0:
			page0.bind(mon)

func _bind_header(mon: Pokemon) -> void:
	if mon == null:
		return
	if mon_sprite != null:
		mon_sprite.texture = PokemonGraphics.load_front(mon.species_key, mon.form, mon.shiny)
	if mon_name != null:
		mon_name.text = mon.display_name()
	if mon_level != null:
		mon_level.text = str(mon.level)
	_bind_gender(mon)
	if ball != null:
		var path: String = "res://assets/ui/Summary/icon_ball_POKEBALL.png"
		if ResourceLoader.exists(path):
			ball.texture = load(path) as Texture2D
	# Sin objeto: ocultar todo el bloque Item_Sprite (como PE)
	var has_item: bool = mon.held_item != &""
	if item_sprite != null:
		item_sprite.visible = has_item
	if has_item and item_name != null:
		var iname: String = String(mon.held_item)
		var idata: ItemData = PokemonDB.item(mon.held_item) if PokemonDB != null else null
		if idata != null and not idata.name.is_empty():
			iname = idata.name
		item_name.text = iname

func _bind_gender(mon: Pokemon) -> void:
	if mon_gender == null:
		return
	var g: int = 2
	if mon.get("gender") != null:
		g = int(mon.get("gender"))
	match g:
		0:
			mon_gender.text = "♂"
			mon_gender.visible = true
		1:
			mon_gender.text = "♀"
			mon_gender.visible = true
		_:
			mon_gender.text = ""
			mon_gender.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("buttonB"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Up"):
		if party != null and party.size() > 1:
			party_index = posmod(party_index - 1, party.size())
			_refresh()
			MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
			_play_current_cry()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Down"):
		if party != null and party.size() > 1:
			party_index = posmod(party_index + 1, party.size())
			_refresh()
			MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
			_play_current_cry()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Left") or event.is_action_pressed("Right"):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("buttonSelect"):
		_play_current_cry()
		get_viewport().set_input_as_handled()
		return

static func open_for(host: Node, p: Party, index: int = 0) -> SummaryScreen:
	var sc: SummaryScreen = (load(SCENE_PATH) as PackedScene).instantiate() as SummaryScreen
	host.add_child(sc)
	sc.open(p, index)
	return sc
