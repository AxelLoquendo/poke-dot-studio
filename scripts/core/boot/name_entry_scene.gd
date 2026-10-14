extends Control
class_name NameEntryScene

@onready var line: LineEdit = $LineEdit
@onready var label: Label = $Label


func _ready() -> void:
	label.text = "¿Cómo te llamas?"
	line.text = "Rojo" if NewGameState.is_male else "Hoja"
	line.grab_focus()
	line.text_submitted.connect(_on_submit)
	await FadeScreen.fade_in(0.4)


func _on_submit(text: String) -> void:
	var n: String = text.strip_edges()
	if n.is_empty():
		return
	NewGameState.player_name = n
	await FadeScreen.fade_out(0.4)
	_start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_on_submit(line.text)


func _start_game() -> void:
	# Pasar GameStartData: lo más simple es un autoload SessionBoot
	SessionBoot.start_data = NewGameState.build_start_data()
	get_tree().change_scene_to_file("res://scenes/overworld/game/game_start.tscn")
