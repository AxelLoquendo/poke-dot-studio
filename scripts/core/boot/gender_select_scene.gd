extends Control
class_name GenderSelectScene

@onready var bg: TextureRect = $Bg
@onready var boy: Sprite2D = $Base/Boy
@onready var girl: Sprite2D = $Base2/Girl

var _index: int = 0
var _busy: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_message_ui()
	_refresh()
	FadeScreen.set_clear()
	bg.modulate.a = 0.0
	# Si New Start no suena (entrada directa), relanzar
	if not MusicManager.esta_sonando():
		MusicManager.reproducir_mapa(SFXGame.MapMusicID.BGM_NEW_START)
	await _tween_alpha(bg, 1.0)
	_busy = false


func _refresh() -> void:
	boy.modulate = Color.WHITE if _index == 0 else Color(1, 1, 1, 0.4)
	girl.modulate = Color.WHITE if _index == 1 else Color(1, 1, 1, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Left"):
		if _index != 0:
			_index = 0
			_refresh()
			MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
	elif event.is_action_pressed("Right"):
		if _index != 1:
			_index = 1
			_refresh()
			MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		_ask_confirm()


func _ask_confirm() -> void:
	_busy = true
	var prompt: String = "¿Así que eres un chico?" if _index == 0 else "¿Así que eres una chica?"
	MessageService.show_texts([prompt], "", ["SÍ", "NO"])
	await MessageService.message_finished
	var choice: int = MessageService.get_last_choice()
	if choice != 0:
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
		_busy = false
		return
	NewGameState.is_male = (_index == 0)
	_go_naming()


func _go_naming() -> void:
	var initial: String = "Rojo" if NewGameState.is_male else "Hoja"
	if NewGameState.config != null:
		initial = NewGameState.config.default_male_name if NewGameState.is_male \
			else NewGameState.config.default_female_name
	SessionBoot.naming_config = {
		"help": "¿Cómo te llamas?",
		"initial": initial,
		"max_length": 7,
		"preview_mode": NamingScreen.PreviewMode.CHARACTER,
		"message": "Escribe con el teclado. Enter/Z confirma, X cancela.",
		"on_confirm_scene": "res://scenes/overworld/game/game_start.tscn",
		"on_cancel_scene": "res://scenes/boot/gender_select.tscn",
	}
	await _tween_alpha(bg, 0.0)
	get_tree().change_scene_to_file("res://scenes/ui/naming/naming.tscn")


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
