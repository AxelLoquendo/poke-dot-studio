extends Control
class_name GenderSelectScene

const PIC_DIR: String = "res://assets/Pictures/"

@onready var bg: TextureRect = $Bg
@onready var boy: TextureRect = $Boy
@onready var girl: TextureRect = $Girl
@onready var hint: Label = $Hint

var _index: int = 0  # 0 boy, 1 girl
var _busy: bool = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(PIC_DIR + "introbg.png"):
		bg.texture = load(PIC_DIR + "introbg.png") as Texture2D
	if ResourceLoader.exists(PIC_DIR + "introBoy.png"):
		boy.texture = load(PIC_DIR + "introBoy.png") as Texture2D
	if ResourceLoader.exists(PIC_DIR + "introGirl.png"):
		girl.texture = load(PIC_DIR + "introGirl.png") as Texture2D
	# Posiciones aproximadas PE (ajusta al ojo)
	boy.position = Vector2(64, 48)
	girl.position = Vector2(280, 48)
	hint.text = "← → elegir · Z confirmar"
	hint.position = Vector2(120, 340)
	_refresh()
	await FadeScreen.fade_in(0.4)
	_busy = false


func _refresh() -> void:
	boy.modulate.a = 1.0 if _index == 0 else 0.45
	girl.modulate.a = 1.0 if _index == 1 else 0.45


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_index = 0
		_refresh()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_index = 1
		_refresh()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_confirm()


func _confirm() -> void:
	_busy = true
	NewGameState.is_male = (_index == 0)
	await FadeScreen.fade_out(0.4)
	# Nombre: escena simple o naming.tscn cuando esté lista
	get_tree().change_scene_to_file("res://scenes/boot/name_entry.tscn")
