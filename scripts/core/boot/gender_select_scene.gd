extends Control
class_name GenderSelectScene
## gender_select.tscn: Bg, Base/Boy, Base2/Girl. Posiciones del editor.

@onready var bg: TextureRect = $Bg
@onready var boy: Sprite2D = $Base/Boy
@onready var girl: Sprite2D = $Base2/Girl

var _index: int = 0
var _busy: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()
	FadeScreen.set_clear()
	bg.modulate.a = 0.0
	await _tween_alpha(bg, 1.0)
	_busy = false


func _refresh() -> void:
	boy.modulate = Color.WHITE if _index == 0 else Color(1, 1, 1, 0.4)
	girl.modulate = Color.WHITE if _index == 1 else Color(1, 1, 1, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Left"):
		_index = 0
		_refresh()
	elif event.is_action_pressed("Right"):
		_index = 1
		_refresh()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_confirm()


func _confirm() -> void:
	_busy = true
	NewGameState.is_male = (_index == 0)
	SessionBoot.naming_config = {
		"help": "¿Cómo te llamas?",
		"initial": "Rojo" if NewGameState.is_male else "Hoja",
		"max_length": 7,
		"preview_mode": NamingScreen.PreviewMode.CHARACTER,
		"message": "Escribe con el teclado. Enter/Z confirma, X cancela.",
		"on_confirm_scene": "res://scenes/overworld/game/game_start.tscn",
		"on_cancel_scene": "res://scenes/boot/gender_select.tscn",
	}
	await FadeScreen.fade_out(0.4)  # o tween de tu bg
	get_tree().change_scene_to_file("res://scenes/ui/naming/naming.tscn")


func _tween_alpha(node: CanvasItem, a: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", a, 0.4).set_trans(Tween.TRANS_LINEAR)
	await tw.finished
