@tool
extends Resource
class_name ScriptCommand
## Base de todos los comandos de script de overworld.

@export var enabled: bool = true
@export var comment: String = ""


## true = síncrono (sigue al instante). false = asíncrono (espera complete_async).
func execute(_context: ScriptExecutionContext) -> bool:
	push_warning("ScriptCommand.execute() no implementado")
	return true


## Expande este comando en varios (p. ej. .txt → lista de cmds).
func get_inline_commands(_context: ScriptExecutionContext) -> Array[ScriptCommand]:
	return []


func get_display_text() -> String:
	return comment if not comment.is_empty() else get_class()
