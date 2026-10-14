extends Control
class_name IntroScene
## Intro PE: introbg + sprites nativos + MessageUI + género en la misma escena.

const PIC: String = "res://assets/Pictures/"
const SCREEN: Vector2 = Vector2(512, 384)

const BASE_SIZE: Vector2 = Vector2(176, 48)
const BASE_POS: Vector2 = Vector2(168, 208)  # (512-176)/2, Y peana

var _bg: TextureRect
var _sprite: TextureRect
var _base: TextureRect
var _boy: TextureRect
var _girl: TextureRect
var _gender_index: int = 0
var _phase: StringName = &"talk"
var _busy: bool = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_ensure_message_ui()
	FadeScreen.set_clear()
	await _fade_bg(1.0)
	await _play_intro()


func _build() -> void:
	_bg = _tex_full(PIC + "introbg.png")
	add_child(_bg)
	_bg.modulate.a = 0.0

	_sprite = _tex_free()
	add_child(_sprite)

	_base = _tex_free()
	_base.texture = load(PIC + "introbase.png") as Texture2D
	_base.size = BASE_SIZE
	_base.position = BASE_POS
	_base.visible = false
	add_child(_base)

	_boy = _tex_free()
	_boy.texture = load(PIC + "introBoy.png") as Texture2D
	_boy.size = Vector2(80, 160)
	_boy.position = Vector2(BASE_POS.x + 8.0, BASE_POS.y - 152.0)
	_boy.visible = false
	add_child(_boy)

	_girl = _tex_free()
	_girl.texture = load(PIC + "introGirl.png") as Texture2D
	_girl.size = Vector2(80, 160)
	_girl.position = Vector2(BASE_POS.x + BASE_SIZE.x - 88.0, BASE_POS.y - 152.0)
	_girl.visible = false
	add_child(_girl)


func _tex_full(path: String) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP
	if ResourceLoader.exists(path):
		t.texture = load(path) as Texture2D
	return t


func _tex_free() -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP
	return t


func _show_char(file_name: String) -> void:
	_base.visible = false
	_boy.visible = false
	_girl.visible = false
	if file_name.is_empty():
		_sprite.visible = false
		return
	var path: String = PIC + file_name
	if not ResourceLoader.exists(path):
		_sprite.visible = false
		return
	_sprite.visible = true
	_sprite.texture = load(path) as Texture2D
	var sz: Vector2 = _sprite.texture.get_size()
	_sprite.size = sz
	# Centrado horizontal; pies hacia la zona media (sobre el mensaje)
	_sprite.position = Vector2((SCREEN.x - sz.x) * 0.5, 120.0 - sz.y * 0.15)


func _say(pages: Array[String]) -> void:
	MessageService.show_texts(pages)
	await MessageService.message_finished


func _play_intro() -> void:
	_phase = &"talk"
	_show_char("introOak.png")
	await _say([
		"¡Hola! ¡Qué bueno verte!",
		"¡Bienvenido al mundo de los Pokémon!",
		"Me llamo Oak.\n¡Pero todo el mundo me llama el Profesor Pokémon!",
	])
	_show_char("introMarill.png")
	await _say([
		"Este mundo está habitado por criaturas\nllamadas Pokémon.",
		"Los humanos y los Pokémon viven juntos\nayudándose unos a otros.",
	])
	_show_char("")
	await _say([
		"Pero primero, cuéntame un poco sobre ti.",
		"¿Eres un chico o una chica?",
	])
	await _start_gender()


func _start_gender() -> void:
	_phase = &"gender"
	_sprite.visible = false
	_base.visible = true
	_boy.visible = true
	_girl.visible = true
	_gender_index = 0
	_refresh_gender()
	_busy = false


func _refresh_gender() -> void:
	_boy.modulate = Color.WHITE if _gender_index == 0 else Color(1, 1, 1, 0.45)
	_girl.modulate = Color.WHITE if _gender_index == 1 else Color(1, 1, 1, 0.45)


func _unhandled_input(event: InputEvent) -> void:
	if _phase != &"gender" or _busy:
		return
	if event.is_action_pressed("Left"):
		_gender_index = 0
		_refresh_gender()
	elif event.is_action_pressed("Right"):
		_gender_index = 1
		_refresh_gender()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_confirm_gender()


func _confirm_gender() -> void:
	_busy = true
	NewGameState.is_male = (_gender_index == 0)
	await _fade_bg(0.0)
	get_tree().change_scene_to_file("res://scenes/boot/name_entry.tscn")


func _fade_bg(target_a: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_bg, "modulate:a", target_a, 0.4).set_trans(Tween.TRANS_LINEAR)
	await tw.finished


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)
