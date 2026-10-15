extends Control
class_name IntroScene
## Usa nodos de intro.tscn: Bg, Character. No mueve offsets del editor.

@onready var bg: TextureRect = $Bg
@onready var character: Sprite2D = $Character

const PIC: String = "res://assets/Pictures/"

var _busy: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_message_ui()
	character.visible = false
	FadeScreen.set_clear()
	bg.modulate.a = 0.0
	await _tween_alpha(bg, 1.0)
	await _play()


func _play() -> void:
	_set_character("introOak.png")
	await _say([
		"¡Hola! ¡Qué bueno verte!",
		"¡Bienvenido al mundo de los Pokémon!",
		"Me llamo Oak. ¡Pero todo el mundo me\nllama el Profesor Pokémon!",
	])
	_set_character("introMarill.png")
	await _say([
		"Este mundo está habitado por criaturas\nllamadas Pokémon.",
		"Los humanos y los Pokémon viven juntos\nayudándose unos a otros.",
	])
	character.visible = false
	await _say([
		"Pero primero, cuéntame un poco sobre ti.",
		"¿Eres un chico o una chica?",
	])
	await _tween_alpha(bg, 0.0)
	get_tree().change_scene_to_file("res://scenes/boot/gender_select.tscn")


func _set_character(file_name: String) -> void:
	var path: String = PIC + file_name
	if not ResourceLoader.exists(path):
		character.visible = false
		return
	character.texture = load(path) as Texture2D
	character.visible = true
	# No tocamos position/size: los dejas en el editor


func _say(pages: Array[String]) -> void:
	MessageService.show_texts(pages)
	await MessageService.message_finished


func _tween_alpha(node: CanvasItem, a: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", a, 0.4).set_trans(Tween.TRANS_LINEAR)
	await tw.finished


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)
