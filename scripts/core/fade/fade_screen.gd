extends CanvasLayer
## Overlay de pantalla completa para fades (negro, blanco, color arbitrario).
##
## Autoload: FadeScreen
## No conoce mapas, clima ni combate. Solo controla opacidad/color del overlay.
## Funciona aunque el árbol esté pausado (PROCESS_MODE_ALWAYS).

signal fade_out_finished
signal fade_in_finished
signal fade_finished

const DEFAULT_DURATION: float = 0.4
const DEFAULT_COLOR: Color = Color.BLACK
const LAYER_INDEX: int = 100

var _rect: ColorRect
var _tween: Tween
var _is_fading: bool = false


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_rect()
	_rect.color = Color(DEFAULT_COLOR, 0.0)


# ============================================================
# API PÚBLICA
# ============================================================

## Oscurece la pantalla hasta alpha 1.0.
func fade_out(duration: float = DEFAULT_DURATION, color: Color = DEFAULT_COLOR) -> void:
	await _fade(1.0, duration, color)
	fade_out_finished.emit()
	fade_finished.emit()


## Aclara la pantalla hasta alpha 0.0.
## El color base se mantiene (útil para salir de un flash blanco, por ejemplo).
func fade_in(duration: float = DEFAULT_DURATION, color: Color = DEFAULT_COLOR) -> void:
	_rect.color = Color(color, _rect.color.a)
	await _fade(0.0, duration, color)
	fade_in_finished.emit()
	fade_finished.emit()


## Lleva el overlay a un color concreto (incluye su alpha).
func fade_to(target_color: Color, duration: float = DEFAULT_DURATION) -> void:
	await _fade(target_color.a, duration, target_color)
	fade_finished.emit()


## Cubre la pantalla al instante (sin tween).
func set_covered(color: Color = DEFAULT_COLOR) -> void:
	_kill_tween()
	_rect.color = Color(color, 1.0)
	_is_fading = false


## Limpia el overlay al instante (sin tween).
func set_clear() -> void:
	_kill_tween()
	_rect.color = Color(_rect.color, 0.0)
	_is_fading = false


func is_fading() -> bool:
	return _is_fading


func is_covered() -> bool:
	return is_equal_approx(_rect.color.a, 1.0)


# ============================================================
# INTERNO
# ============================================================

func _crear_rect() -> void:
	_rect = ColorRect.new()
	_rect.name = "FadeRect"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.offset_left = 0.0
	_rect.offset_top = 0.0
	_rect.offset_right = 0.0
	_rect.offset_bottom = 0.0
	add_child(_rect)


func _fade(target_alpha: float, duration: float, color: Color) -> void:
	_kill_tween()
	_is_fading = true
	_rect.color = Color(color, _rect.color.a)

	if duration <= 0.0:
		_rect.color.a = target_alpha
		_is_fading = false
		return

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_rect, "color:a", target_alpha, duration) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_SINE)
	await _tween.finished
	_is_fading = false


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
