extends Control
class_name NamingScreen
## Escena reutilizable: res://scenes/ui/naming/naming.tscn
## - Nueva partida, renombrar, apodos, etc.

signal confirmed(result_name: String)
signal cancelled

enum PreviewMode { NONE, CHARACTER, POKEMON }

const MAX_LEN_DEFAULT: int = 7

@onready var character_root: Node2D = $Character
@onready var mon_root: Node2D = $Mon
@onready var character_sprite: AnimatedSprite2D = $Character/AnimatedSprite2D
@onready var pregunta: Label = $Text/Pregunta
@onready var box_message: Label = $Text/Box_message
@onready var print_name: LineEdit = $Text/Print_Name

## Contexto al abrir por change_scene (opcional).
## SessionBoot.naming_config: Dictionary
var _max_len: int = MAX_LEN_DEFAULT
var _busy: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg: Dictionary = {}
	if SessionBoot != null and SessionBoot.get("naming_config") != null:
		cfg = SessionBoot.naming_config as Dictionary

	var help: String = str(cfg.get("help", "¿Cómo te llamas?"))
	var initial: String = str(cfg.get("initial", ""))
	var msg: String = str(cfg.get(
		"message",
		"Escribe con el teclado. Enter/Z confirma, X cancela."
	))
	_max_len = int(cfg.get("max_length", MAX_LEN_DEFAULT))
	var mode: int = int(cfg.get("preview_mode", PreviewMode.CHARACTER))

	setup(help, initial, _max_len, mode as PreviewMode, msg)

	# Si venimos de fade cubierto
	if FadeScreen.is_covered():
		await FadeScreen.fade_in(0.4)
	_busy = false
	print_name.grab_focus()


## API reutilizable (también si instancias la escena como hijo).
func setup(
	help_text: String,
	initial_text: String = "",
	max_length: int = MAX_LEN_DEFAULT,
	preview: PreviewMode = PreviewMode.CHARACTER,
	footer_message: String = ""
) -> void:
	_max_len = max_length
	pregunta.text = help_text
	if not footer_message.is_empty():
		box_message.text = footer_message
	print_name.max_length = _max_len
	print_name.text = initial_text
	print_name.caret_column = initial_text.length()

	character_root.visible = (preview == PreviewMode.CHARACTER)
	mon_root.visible = (preview == PreviewMode.POKEMON)

	if preview == PreviewMode.CHARACTER and character_sprite != null:
		var pd: PlayerData = NewGameState.male_player_data if NewGameState.is_male \
			else NewGameState.female_player_data
		if pd != null:
			var built: SpriteFrames = frames_from_ow(pd.ow)
			if built != null:
				character_sprite.sprite_frames = built
		# Caminar en el sitio (no mueve el Node2D)
		if character_sprite.sprite_frames.has_animation("Walk_Down"):
			character_sprite.play("Walk_Down")
		elif character_sprite.sprite_frames.has_animation("First_Step_Down"):
			character_sprite.play("First_Step_Down")

	if not print_name.text_submitted.is_connected(_on_submitted):
		print_name.text_submitted.connect(_on_submitted)


func _on_submitted(text: String) -> void:
	_confirm(text)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("buttonStart"):
		_confirm(print_name.text)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()


func _confirm(raw: String) -> void:
	var n: String = raw.strip_edges()
	if n.is_empty():
		return
	_busy = true
	confirmed.emit(n)
	# Flujo nueva partida (si el config lo pide)
	var cfg: Dictionary = SessionBoot.naming_config if SessionBoot else {}
	var next: String = str(cfg.get("on_confirm_scene", ""))
	if not next.is_empty():
		NewGameState.player_name = n
		await FadeScreen.fade_out(0.4)
		SessionBoot.start_data = NewGameState.build_start_data()
		SessionBoot.naming_config = {}
		get_tree().change_scene_to_file(next)
		return
	# Uso embebido: el caller escucha `confirmed`


func _cancel() -> void:
	_busy = true
	cancelled.emit()
	var cfg: Dictionary = SessionBoot.naming_config if SessionBoot else {}
	var back: String = str(cfg.get("on_cancel_scene", ""))
	SessionBoot.naming_config = {}
	if not back.is_empty():
		await FadeScreen.fade_out(0.4)
		get_tree().change_scene_to_file(back)

static func frames_from_ow(ow: EventObjects.Obj_Event) -> SpriteFrames:
	var path: String = str(EventObjects.ow_sprites.get(ow, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path) as Texture2D
	var frames: SpriteFrames = SpriteFrames.new()
	var frame_size: Vector2 = texture.get_size() / Vector2(3, 4)
	var directions: Dictionary = {"Down": 0, "Up": 1, "Left": 2, "Right": 3}
	var steps: Dictionary = {"First_Step": 0, "Idle": 1, "Second_Step": 2}
	for direction: String in directions:
		var y: int = directions[direction]
		for step: String in steps:
			var x: int = steps[step]
			var anim: String = step + "_" + direction
			frames.add_animation(anim)
			frames.set_animation_speed(anim, 6.0)
			frames.set_animation_loop(anim, true)
			var atlas_0: AtlasTexture = AtlasTexture.new()
			atlas_0.atlas = texture
			atlas_0.region = Rect2(Vector2(x, y) * frame_size, frame_size)
			frames.add_frame(anim, atlas_0)
			if step != "Idle":
				var atlas_1: AtlasTexture = AtlasTexture.new()
				atlas_1.atlas = texture
				atlas_1.region = Rect2(Vector2(1, y) * frame_size, frame_size)
				frames.add_frame(anim, atlas_1)
	# Walk_Down en sitio: First → Idle → Second → Idle
	frames.add_animation("Walk_Down")
	frames.set_animation_speed("Walk_Down", 6.0)
	frames.set_animation_loop("Walk_Down", true)
	for step_name: String in ["First_Step_Down", "Idle_Down", "Second_Step_Down", "Idle_Down"]:
		# reusa frames ya añadidos copiando texturas del anim step
		var src: String = step_name
		if frames.has_animation(src) and frames.get_frame_count(src) > 0:
			frames.add_frame("Walk_Down", frames.get_frame_texture(src, 0))
	return frames
