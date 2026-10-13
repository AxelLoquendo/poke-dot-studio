@tool
extends Resource
class_name MapScriptEntry
## Script de nivel (no NPC / no casilla). Estilo PokeDot-Engine v2.

enum Trigger {
	ON_TRANSITION,  ## Al pasar a este mapa (cluster o warp)
	ON_LOAD,        ## Tras cargar el cluster que tiene este mapa como actual
	ON_FRAME,       ## Cuando la condición pasa de false→true (opcional)
}

@export var trigger: Trigger = Trigger.ON_LOAD
@export_file("*.txt") var script_file: String = ""
@export var condition_flag: StringName = &""
@export var expected_value: String = "true"


func condition_matches() -> bool:
	if condition_flag.is_empty():
		return true
	var valor: Variant = ScriptExecutionContext.global_flags.get(condition_flag, false)
	return str(valor).to_lower() == expected_value.to_lower()
