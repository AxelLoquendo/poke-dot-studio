extends Control
class_name SplashTitleScene
## IntroEventScene de Sky: opacidad de la imagen, no solo cortina negra.

@onready var bg: TextureRect = $Bg
@onready var start_prompt: TextureRect = $StartPrompt

var _index: int = 0
var _phase: StringName = &"sequence"  # sequence | title
var _busy: bool = true
var _skip: bool = false
var _flash_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.size = TitleConfig.SCREEN_SIZE
	bg.modulate.a = 0.0
	start_prompt.visible = false
	start_prompt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	start_prompt.stretch_mode = TextureRect.STRETCH_KEEP
	start_prompt.position = TitleConfig.START_POS
	# Sin cortina negra al arrancar: PE funde la propia imagen
	FadeScreen.set_clear()
	await _run_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _phase == &"sequence" and not _busy:
		_skip = true
	elif _phase == &"title" and not _busy:
		_accept_title()


func _run_sequence() -> void:
	_phase = &"sequence"
	_index = 0
	while _index < TitleConfig.SEQUENCE.size():
		var path: String = TitleConfig.path(TitleConfig.SEQUENCE[_index])
		await _show_image(path)
		_index += 1
	await _open_title()


func _show_image(path: String) -> void:
	_busy = true
	_skip = false
	if ResourceLoader.exists(path):
		bg.texture = load(path) as Texture2D
	# Fade IN de la imagen (PE moveOpacity → 255)
	await _tween_bg_alpha(1.0)
	_busy = false
	# Linger o skip
	var t: float = 0.0
	while t < TitleConfig.SECONDS_PER_SPLASH:
		if _skip:
			break
		await get_tree().process_frame
		t += get_process_delta_time()
	_busy = true
	_skip = false
	# Fade OUT de la imagen (PE moveOpacity → 0)
	await _tween_bg_alpha(0.0)
	_busy = false


func _tween_bg_alpha(target: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(bg, "modulate:a", target, TitleConfig.FADE_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	await tw.finished


func _open_title() -> void:
	_phase = &"title"
	_busy = true
	var title_path: String = TitleConfig.path(TitleConfig.TITLE_BG)
	if ResourceLoader.exists(title_path):
		bg.texture = load(title_path) as Texture2D
	var start_path: String = TitleConfig.path(TitleConfig.TITLE_START)
	if ResourceLoader.exists(start_path):
		start_prompt.texture = load(start_path) as Texture2D
		start_prompt.visible = true
		start_prompt.modulate.a = 0.0
		start_prompt.position = TitleConfig.START_POS
	await _tween_bg_alpha(1.0)
	if start_prompt.visible:
		var tw: Tween = create_tween()
		tw.tween_property(start_prompt, "modulate:a", 1.0, TitleConfig.FADE_DURATION)
		await tw.finished
		_start_flash()
	_busy = false


func _start_flash() -> void:
	_kill_flash()
	_flash_tween = create_tween()
	_flash_tween.set_loops()
	_flash_tween.tween_property(start_prompt, "modulate:a", 0.0, TitleConfig.START_FLASH_HALF)
	_flash_tween.tween_property(start_prompt, "modulate:a", 1.0, TitleConfig.START_FLASH_HALF)


func _kill_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null


func _accept_title() -> void:
	_busy = true
	_kill_flash()
	# PE: pausa corta + fade out de las imágenes
	await get_tree().create_timer(0.35).timeout
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(bg, "modulate:a", 0.0, TitleConfig.FADE_DURATION)
	tw.tween_property(start_prompt, "modulate:a", 0.0, TitleConfig.FADE_DURATION)
	await tw.finished
	# Cortina negra solo al cambiar de escena (hacia Load)
	FadeScreen.set_covered()
	get_tree().change_scene_to_file("res://scenes/boot/load_menu.tscn")
