@tool
extends RefCounted
class_name ScriptTextParser
## Parser de scripts .txt estilo pokeemerald / PokeDot-Engine v2.

const COMANDOS_VALIDOS: Array[String] = [
	"text", "multichoice", "label", "goto", "ifchoice", "ifflag",
	"compare", "applymovement", "weather", "fadeout", "fadein",
	"savegame", "waitbutton", "setflag", "clearflag", "moveplayer",
	"faceplayer", "lock", "release", "warp", "giveitem", "sound",
	"return", "end", "checkitem", "trainerbattle",
]

const MSGBOX_MAP: Dictionary = {
	"MSGBOX_NPC": true,
	"MSGBOX_DEFAULT": true,
	"MSGBOX_SIGN": true,
	"MSGBOX_YESNO": true,
	"MSGBOX_AUTOCLOSE": true,
	"MSGBOX_GETINPUT": true,
}

var parsed_commands: Array = []
var error_message: String = ""
var has_error: bool = false


func parse_script(script_text: String) -> Array:
	parsed_commands.clear()
	has_error = false
	error_message = ""
	var line_number: int = 0
	for raw_line: String in script_text.split("\n"):
		line_number += 1
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("//"):
			continue
		var command_dict: Dictionary = _parse_line(line, line_number)
		if has_error:
			return []
		if not command_dict.is_empty():
			parsed_commands.append(command_dict)
	return parsed_commands


func load_script_file(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		has_error = true
		error_message = "Archivo no encontrado: %s" % file_path
		push_error(error_message)
		return []
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		has_error = true
		error_message = "No se pudo abrir: %s" % file_path
		push_error(error_message)
		return []
	var text: String = file.get_as_text()
	file.close()
	return parse_script(text)


func _parse_line(line: String, line_number: int) -> Dictionary:
	var separator: int = line.find(" ")
	var command_name: String = line if separator == -1 else line.left(separator)
	command_name = command_name.to_lower()
	var args_source: String = "" if separator == -1 else line.substr(separator + 1)
	var args: Array[String] = _tokenize_arguments(args_source, line_number)
	if has_error:
		return {}
	if command_name not in COMANDOS_VALIDOS:
		has_error = true
		error_message = "Línea %d: comando desconocido '%s'" % [line_number, command_name]
		push_error(error_message)
		return {}
	return {
		"command": command_name,
		"args": args,
		"line": line_number,
	}


func _tokenize_arguments(source: String, line_number: int) -> Array[String]:
	var args: Array[String] = []
	var current: String = ""
	var inside_quotes: bool = false
	for i: int in range(source.length()):
		var character: String = source[i]
		if character == "\"":
			inside_quotes = not inside_quotes
		elif (character == " " or character == "\t") and not inside_quotes:
			if not current.is_empty():
				args.append(current)
				current = ""
		else:
			current += character
	if inside_quotes:
		has_error = true
		error_message = "Línea %d: comillas sin cerrar" % line_number
		push_error(error_message)
		return []
	if not current.is_empty():
		args.append(current.replace("\r", ""))
	return args
