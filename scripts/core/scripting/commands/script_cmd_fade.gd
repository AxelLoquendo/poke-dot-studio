@tool
extends ScriptCommand
class_name ScriptCmdFade
@export var fade_out: bool = true
@export var duration: float = 0.4
func execute(context: ScriptExecutionContext) -> bool:
	context.is_waiting = true
	if fade_out:
		# Ajusta a la API real de tu FadeScreen (awaitable o signal)
		if FadeScreen.has_method("fade_out"):
			var result: Variant = FadeScreen.call("fade_out", duration)
			if result is Signal:
				(result as Signal).connect(context.complete_async, CONNECT_ONE_SHOT)
			elif result is bool:
				# si es async awaitable no usable aquí: fallback timer
				context.runner.get_tree().create_timer(duration).timeout.connect(context.complete_async, CONNECT_ONE_SHOT)
			else:
				context.runner.get_tree().create_timer(duration).timeout.connect(context.complete_async, CONNECT_ONE_SHOT)
		else:
			context.runner.get_tree().create_timer(duration).timeout.connect(context.complete_async, CONNECT_ONE_SHOT)
	else:
		if FadeScreen.has_method("fade_in"):
			FadeScreen.call("fade_in", duration)
		context.runner.get_tree().create_timer(duration).timeout.connect(context.complete_async, CONNECT_ONE_SHOT)
	return false
