extends Control
class_name IntroScene
## Intro de nueva partida (gráficos PE intro*). Luego género.

const PIC_DIR: String = "res://assets/Pictures/"

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
		return
	var path: String = PIC_DIR + file_name
	if ResourceLoader.exists(path):
		character.texture = load(path) as Texture2D


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)
