extends Control
class_name IntroScene

@onready var bg: TextureRect = $Bg
@onready var character: Sprite2D = $Character

const PIC: String = "res://assets/Pictures/"
const CROSSFADE: float = 0.35


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_message_ui()
	character.visible = false
	character.modulate.a = 0.0
	FadeScreen.set_clear()
	bg.modulate.a = 0.0
	MusicManager.reproducir_mapa(SFXGame.MapMusicID.BGM_NEW_START)
	await _tween_alpha(bg, 1.0)
	await _play()


func _play() -> void:
	await _show_character("introOak.png")
	await _say([
		"¡Hola! ¡Qué bueno verte!",
		"¡Bienvenido al mundo de los Pokémon!",
		"Me llamo Oak. ¡Pero todo el mundo me\nllama el Profesor Pokémon!",
	])
	await _crossfade_character("introMarill.png")
	await _say([
		"Este mundo está habitado por criaturas\nllamadas Pokémon.",
		"Los humanos y los Pokémon viven juntos\nayudándose unos a otros.",
	])
	await _tween_alpha(character, 0.0)
	character.visible = false
	await _say([
		"Pero primero, cuéntame un poco sobre ti.",
		"¿Eres un chico o una chica?",
	])
	await _tween_alpha(bg, 0.0)
	# New Start sigue en género + naming; se corta al entrar al juego
	get_tree().change_scene_to_file("res://scenes/boot/gender_select.tscn")


func _show_character(file_name: String) -> void:
	var path: String = PIC + file_name
	if not ResourceLoader.exists(path):
		character.visible = false
		return
	character.texture = load(path) as Texture2D
	character.visible = true
	character.modulate.a = 0.0
	await _tween_alpha(character, 1.0)


func _crossfade_character(file_name: String) -> void:
	if character.visible:
		await _tween_alpha(character, 0.0)
	var path: String = PIC + file_name
	if not ResourceLoader.exists(path):
		character.visible = false
		return
	character.texture = load(path) as Texture2D
	character.visible = true
	character.modulate.a = 0.0
	await _tween_alpha(character, 1.0)


func _say(pages: Array[String]) -> void:
	MessageService.show_texts(pages)
	await MessageService.message_finished


func _tween_alpha(node: CanvasItem, a: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", a, CROSSFADE).set_trans(Tween.TRANS_LINEAR)
	await tw.finished


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)
