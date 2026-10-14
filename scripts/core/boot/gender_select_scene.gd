extends Control
class_name GenderSelectScene
## Selector de género estilo PE: introbg + introbase + boy/girl (80×160).

const PIC_DIR: String = "res://assets/Pictures/"
const SCREEN: Vector2 = Vector2(512.0, 384.0)

const BOY_SIZE: Vector2 = Vector2(80.0, 160.0)
const GIRL_SIZE: Vector2 = Vector2(80.0, 160.0)
const BASE_SIZE: Vector2 = Vector2(176.0, 48.0)

## Peana centrada; pies de los sprites sobre el borde superior de la base.
const BASE_POS: Vector2 = Vector2((512.0 - 176.0) * 0.5, 200.0)

@onready var bg: TextureRect = $Bg
@onready var base_spr: TextureRect = $Base
@onready var boy: TextureRect = $Boy
@onready var girl: TextureRect = $Girl

var _index: int = 0
var _busy: bool = true
var _bounce_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_bg()
	_setup_sprites()
	_refresh_selection()
	_ensure_message_ui()
	await FadeScreen.fade_in(0.4)
	# Pregunta en caja PE, no un Label de “hint”
	MessageService.show_texts(["¿Eres un chico o una chica?"])
	# Si show_texts es awaitable en tu API:
	# await MessageService.show_texts([...])
	_busy = false


func _setup_bg() -> void:
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.texture = load(PIC_DIR + "introbg.png") as Texture2D


func _setup_sprites() -> void:
	# Base
	base_spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_spr.stretch_mode = TextureRect.STRETCH_KEEP
	base_spr.texture = load(PIC_DIR + "introbase.png") as Texture2D
	base_spr.size = BASE_SIZE
	base_spr.position = BASE_POS

	# Boy a la izquierda de la peana
	boy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boy.stretch_mode = TextureRect.STRETCH_KEEP
	boy.texture = load(PIC_DIR + "introBoy.png") as Texture2D
	boy.size = BOY_SIZE
	boy.position = Vector2(
		BASE_POS.x + 8.0,
		BASE_POS.y - BOY_SIZE.y + 8.0
	)

	# Girl a la derecha
	girl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	girl.stretch_mode = TextureRect.STRETCH_KEEP
	girl.texture = load(PIC_DIR + "introGirl.png") as Texture2D
	girl.size = GIRL_SIZE
	girl.position = Vector2(
		BASE_POS.x + BASE_SIZE.x - GIRL_SIZE.x - 8.0,
		BASE_POS.y - GIRL_SIZE.y + 8.0
	)


func _refresh_selection() -> void:
	# Seleccionado: opacidad plena + leve “bounce”; el otro más tenue
	boy.modulate = Color.WHITE if _index == 0 else Color(1, 1, 1, 0.5)
	girl.modulate = Color.WHITE if _index == 1 else Color(1, 1, 1, 0.5)
	_play_bounce()


func _play_bounce() -> void:
	if _bounce_tween != null and _bounce_tween.is_valid():
		_bounce_tween.kill()
	var target: TextureRect = boy if _index == 0 else girl
	var base_y: float = target.position.y
	target.position.y = base_y
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(target, "position:y", base_y - 6.0, 0.12)
	_bounce_tween.tween_property(target, "position:y", base_y, 0.12)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		if _index != 0:
			_index = 0
			_refresh_selection()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		if _index != 1:
			_index = 1
			_refresh_selection()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_confirm()


func _confirm() -> void:
	_busy = true
	NewGameState.is_male = (_index == 0)
	await FadeScreen.fade_out(0.4)
	get_tree().change_scene_to_file("res://scenes/boot/name_entry.tscn")


func _ensure_message_ui() -> void:
	if get_tree().get_first_node_in_group(&"message_ui") != null:
		return
	var ui: MessageUI = MessageUI.new()
	ui.name = "MessageUI"
	add_child(ui)
