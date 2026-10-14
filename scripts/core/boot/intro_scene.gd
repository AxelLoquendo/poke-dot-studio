extends Control
class_name IntroScene
## Intro de nueva partida (gráficos PE intro*). Luego género.

const PIC_DIR: String = "res://assets/Pictures/"
const SCREEN: Vector2 = Vector2(512, 384)

@onready var bg: TextureRect = $Bg
@onready var character: TextureRect = $Character

var _busy: bool = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_rect(bg)
	_setup_rect(character)
	character.texture = null
	if ResourceLoader.exists(PIC_DIR + "introbg.png"):
		bg.texture = load(PIC_DIR + "introbg.png") as Texture2D
	await FadeScreen.fade_in(0.4)
	await _play()


func _setup_rect(r: TextureRect) -> void:
	# Solo el fondo:
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP

func _play() -> void:
	_ensure_message_ui()
	# Oak
	_set_char("introOak.png")
	await MessageService.show_texts([
		"¡Hola! ¡Qué bueno verte!",
		"¡Bienvenido al mundo de los Pokémon!",
		"Me llamo Oak.\n¡Pero todo el mundo me llama Profesor Pokémon!",
	])
	# Mundo / Marill opcional
	_set_char("introMarill.png")
	await MessageService.show_texts([
		"Este mundo está habitado por criaturas\nllamadas Pokémon.",
	])
	_set_char("")
	await MessageService.show_texts([
		"Pero primero, cuéntame un poco\nsobre ti.",
		"¿Eres chico o chica?",
	])
	await FadeScreen.fade_out(0.4)
	get_tree().change_scene_to_file("res://scenes/boot/gender_select.tscn")


func _set_char(file_name: String) -> void:
	if file_name.is_empty():
		character.texture = null
		character.visible = false
		return
	character.visible = true
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP
	# Quitar full-rect del character si lo tenía en la escena
	character.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var path: String = PIC_DIR + file_name
	if not ResourceLoader.exists(path):
		return
	character.texture = load(path) as Texture2D
	var sz: Vector2 = character.texture.get_size()
	character.size = sz
	# Centrado horizontal, apoyado hacia el medio-bajo (sobre zona de mensaje)
	character.position = Vector2(
		(SCREEN.x - sz.x) * 0.5,
		160.0 - sz.y * 0.25
	)



func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)
