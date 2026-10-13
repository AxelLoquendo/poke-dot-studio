extends CanvasLayer
## Overlay de pantalla completa al estilo Pokémon Essentials (pbFadeOutIn).
## Autoload: FadeScreen
## No conoce mapas ni scripts. Solo alpha lineal sobre un color sólido.

signal fade_out_finished
signal fade_in_finished
signal fade_finished

## PE: duration = 0.4
const DEFAULT_DURATION: float = 0.4
const DEFAULT_COLOR: Color = Color.BLACK
## Por encima de MessageUI (95) y clima.
const LAYER_INDEX: int = 100

var _rect: ColorRect
var _tween: Tween
var _is_fading: bool = false
## Equivalente a $game_temp.fadestate (fade anidados).
var _fade_depth: int = 0


func _ready() -> void:
	layer = LAYER_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_rect()
	_rect.color = Color(DEFAULT_COLOR, 0.0)


# ============================================================
# API PÚBLICA (async, awaitable)
# ============================================================

## Oscurece hasta alpha 1.0 (PE: fade out del viewport).
func fade_out(duration: float = DEFAULT_DURATION, color: Color = DEFAULT_COLOR) -> void:
	await _fade_alpha(1.0, duration, color)
	fade_out_finished.emit()
	fade_finished.emit()


## Aclara hasta alpha 0.0 (PE: fade in del viewport).
func fade_in(duration: float = DEFAULT_DURATION, color: Color = DEFAULT_COLOR) -> void:
	await _fade_alpha(0.0, duration, color)
	fade_in_finished.emit()
	fade_finished.emit()


## Equivalente a pbFadeOutIn: out → callback → in.
## Si nofade_out=true, deja la pantalla cubierta (útil en warps encadenados).
func fade_out_in(
	action: Callable = Callable(),
	duration: float = DEFAULT_DURATION,
	color: Color = DEFAULT_COLOR,
	nofade_out: bool = false
) -> void:
	await fade_out(duration, color)
	_fade_depth += 1
	if action.is_valid():
		var result: Variant = action.call()
		if result is Object and result.has_method("is_valid"):
			# Si el callback devuelve otra corrutina, no la esperamos aquí;
			# el caller puede hacer el trabajo síncrono dentro del Callable.
			pass
	_fade_depth = maxi(_fade_depth - 1, 0)
	if not nofade_out:
		await fade_in(duration, color)


## Cubre al instante (alpha 1).
func set_covered(color: Color = DEFAULT_COLOR) -> void:
	_kill_tween()
	_rect.color = Color(color.r, color.g, color.b, 1.0)
	_is_fading = false


## Limpia al instante (alpha 0).
func set_clear() -> void:
	_kill_tween()
	_rect.color = Color(_rect.color.r, _rect.color.g, _rect.color.b, 0.0)
	_is_fading = false


func is_fading() -> bool:
	return _is_fading


func is_covered() -> bool:
	return is_equal_approx(_rect.color.a, 1.0)


func is_fade_active() -> bool:
	return _fade_depth > 0 or _is_fading


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
	# Bloquea input solo cuando está cubierto / en medio de fade
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


## PE usa lerp lineal 0↔255 en `duration` segundos. Sin ease.
func _fade_alpha(target_alpha: float, duration: float, color: Color) -> void:
	_kill_tween()
	_is_fading = true
	# Conserva el alpha actual; solo fija RGB del color pedido
	_rect.color = Color(color.r, color.g, color.b, _rect.color.a)

	if duration <= 0.0:
		_rect.color.a = target_alpha
		_is_fading = false
		return

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# TRANS_LINEAR = mismo feeling que lerp de Essentials
	_tween.tween_property(_rect, "color:a", target_alpha, duration) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN)
	await _tween.finished
	_is_fading = false


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
