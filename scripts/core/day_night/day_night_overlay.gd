extends CanvasModulate
class_name DayNightOverlay
## Tinte del overworld. Hijo del World, no de la UI.

const LERP_SPEED: float = 1.5


func _ready() -> void:
	color = Color.WHITE


func _process(delta: float) -> void:
	var target: Color = DayNightManager.current_tint()
	color = color.lerp(target, delta * LERP_SPEED)
