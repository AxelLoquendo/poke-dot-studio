extends Control
class_name SplashTitleScene
## Splash → Title (PE IntroEventScene). Al confirmar, emite title_accepted.
## No conoce el menú de carga ni GameSession.

signal title_accepted

@onready var bg: TextureRect = $Bg
@onready var start_prompt: TextureRect = $StartPrompt

var _phase: StringName = &"splash"
var _splash_index: int = 0
var _busy: bool = false
var _flash_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.size = TitleConfig.SCREEN_SIZE
	start_prompt.visible = false
	start_prompt.position = TitleConfig.START_POS
	start_prompt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	start_prompt.stretch_mode = TextureRect.STRETCH_KEEP
	_run()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if not (event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	match _phase:
		&"splash":
			_skip_splash()
		&"title":
			_accept_title()


func _run() -> void:
	_busy = true
	FadeScreen.set_covered()
	# Créditos opcionales
	for file_name: String in TitleConfig.CREDITS_IMAGES:
		await _show_still(TitleConfig.path(file_name), TitleConfig.SECONDS_PER_SPLASH, true)
	_splash_index = 0
	_phase = &"splash"
	_busy = false
	await _show_splash_current()


func _show_splash_current() -> void:
	if _splash_index >= TitleConfig.SPLASH_IMAGES.size():
		await _open_title()
		return
	var path: String = TitleConfig.path(TitleConfig.SPLASH_IMAGES[_splash_index])
	await _show_still(path, TitleConfig.SECONDS_PER_SPLASH, true)
	if _phase != &"splash":
		return
	_splash_index += 1
	await _show_splash_current()


func _skip_splash() -> void:
	if _phase != &"splash" or _busy:
		return
	_busy = true
	_splash_index += 1
	await FadeScreen.fade_out(TitleConfig.FADE_DURATION)
	_busy = false
	await _show_splash_current()


func _show_still(path: String, linger: float, allow_skip_timer: bool) -> void:
	_busy = true
	start_prompt.visible = false
	_kill_flash()
	if ResourceLoader.exists(path):
		bg.texture = load(path) as Texture2D
	await FadeScreen.fade_in(TitleConfig.FADE_DURATION)
	_busy = false
	if linger <= 0.0:
		return
	var t: float = 0.0
	while t < linger:
		if _phase != &"splash" and allow_skip_timer:
			# Si el input cambió de fase, salir
			break
		# Si el usuario ya avanzó el índice con skip, el caller no usa este linger
		await get_tree().process_frame
		t += get_process_delta_time()
		if _busy:
			# Skip en curso
			return
	if _phase == &"splash" and not _busy:
		_busy = true
		await FadeScreen.fade_out(TitleConfig.FADE_DURATION)
		_busy = false


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
		start_prompt.modulate.a = 1.0
		start_prompt.position = TitleConfig.START_POS
	await FadeScreen.fade_in(TitleConfig.FADE_DURATION)
	_start_flash()
	# BGM de título si tienes id; descomenta y ajusta:
	# MusicManager.reproducir_bgm(...)
	_busy = false


func _start_flash() -> void:
	_kill_flash()
	_flash_tween = create_tween()
	_flash_tween.set_loops()
	_flash_tween.tween_property(start_prompt, "modulate:a", 0.0, TitleConfig.START_FLASH_HALF) \
		.set_trans(Tween.TRANS_LINEAR)
	_flash_tween.tween_property(start_prompt, "modulate:a", 1.0, TitleConfig.START_FLASH_HALF) \
		.set_trans(Tween.TRANS_LINEAR)


func _kill_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null


func _accept_title() -> void:
	if _phase != &"title" or _busy:
		return
	_busy = true
	_kill_flash()
	await get_tree().create_timer(0.35).timeout
	await FadeScreen.fade_out(TitleConfig.FADE_DURATION)
	get_tree().change_scene_to_file("res://scenes/boot/load_menu.tscn")


func _go_to_load_menu_placeholder() -> void:
	# Siguiente paso: escena Load. Mientras tanto, console.
	print("SplashTitleScene: title_accepted → aquí va el menú Load")
	# Ejemplo cuando exista:
	# get_tree().change_scene_to_file("res://scenes/boot/load_menu.tscn")
