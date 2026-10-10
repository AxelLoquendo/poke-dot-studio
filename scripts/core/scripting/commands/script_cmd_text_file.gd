@tool
extends ScriptCommand
class_name ScriptCmdTextFile
## Carga un .txt y lo expande inline en el runner.

@export_file("*.txt") var script_file_path: String = ""

var _loaded: Array = []


func get_inline_commands(context: ScriptExecutionContext) -> Array[ScriptCommand]:
	if script_file_path.is_empty():
		push_warning("ScriptCmdTextFile: sin ruta")
		return []
	if _loaded.is_empty():
		var parser: ScriptTextParser = ScriptTextParser.new()
		_loaded = parser.load_script_file(script_file_path)
		if parser.has_error:
			return []
	return _convert(_loaded, context)


func execute(_context: ScriptExecutionContext) -> bool:
	return true


func _convert(parsed: Array, _context: ScriptExecutionContext) -> Array[ScriptCommand]:
	var commands: Array[ScriptCommand] = []
	var pending_texts: Array[String] = []

	for cmd_dict: Variant in parsed:
		var d: Dictionary = cmd_dict as Dictionary
		var command_name: String = str(d.get("command", ""))
		var args: Array = d.get("args", []) as Array

		if command_name == "text":
			var message_text: String = str(args[0]) if not args.is_empty() else ""
			var msgbox_name: String = ""
			var speaker_token: String = ""
			if args.size() > 1:
				if ScriptTextParser.MSGBOX_MAP.has(str(args[1])):
					msgbox_name = str(args[1])
					if args.size() > 2:
						speaker_token = str(args[2])
				else:
					speaker_token = str(args[1])
			if not msgbox_name.is_empty() or not speaker_token.is_empty():
				_flush_texts(commands, pending_texts)
				pending_texts.clear()
				var typed: ScriptCmdText = ScriptCmdText.new()
				typed.message = message_text
				typed.messages = [message_text]
				_configure_msgbox(typed, msgbox_name)
				if not speaker_token.is_empty():
					typed.speaker_id = StringName(speaker_token)
				commands.append(typed)
			else:
				pending_texts.append(message_text)
			continue

		_flush_texts(commands, pending_texts)
		pending_texts.clear()

		if command_name == "end" or command_name == "return":
			commands.append(ScriptCmdReturn.new())
			continue

		var cmd: ScriptCommand = _create(command_name, args)
		if cmd != null:
			commands.append(cmd)

	_flush_texts(commands, pending_texts)
	return commands


func _flush_texts(commands: Array[ScriptCommand], texts: Array[String]) -> void:
	if texts.is_empty():
		return
	var cmd: ScriptCmdText = ScriptCmdText.new()
	cmd.message = texts[0]
	cmd.messages = texts.duplicate()
	commands.append(cmd)


func _configure_msgbox(command: ScriptCmdText, msgbox_name: String) -> void:
	match msgbox_name:
		"MSGBOX_SIGN":
			command.hide_speaker = true
		"MSGBOX_YESNO":
			command.choices = ["Sí", "No"]
			command.choice_variable = "last_choice"


func _create(command_name: String, args: Array) -> ScriptCommand:
	match command_name:
		"label":
			var c: ScriptCmdLabel = ScriptCmdLabel.new()
			if not args.is_empty():
				c.label_name = str(args[0])
			return c
		"goto":
			var c: ScriptCmdGoto = ScriptCmdGoto.new()
			if not args.is_empty():
				c.target_label = str(args[0])
			return c
		"ifchoice":
			var c: ScriptCmdIfChoice = ScriptCmdIfChoice.new()
			if not args.is_empty():
				c.expected_choice = str(args[0])
			if args.size() > 1:
				c.target_label = str(args[1])
			return c
		"ifflag":
			var c: ScriptCmdIfFlag = ScriptCmdIfFlag.new()
			if not args.is_empty():
				c.flag_name = str(args[0])
			if args.size() > 1:
				c.target_label = str(args[1])
			return c
		"setflag":
			var c: ScriptCmdSetFlag = ScriptCmdSetFlag.new()
			if not args.is_empty():
				c.flag_name = str(args[0])
			c.value = true
			return c
		"clearflag":
			var c: ScriptCmdSetFlag = ScriptCmdSetFlag.new()
			if not args.is_empty():
				c.flag_name = str(args[0])
			c.value = false
			return c
		"faceplayer":
			return ScriptCmdFacePlayer.new()
		"lock":
			var c: ScriptCmdLock = ScriptCmdLock.new()
			c.lock_player = true
			return c
		"release":
			var c: ScriptCmdLock = ScriptCmdLock.new()
			c.lock_player = false
			return c
		"waitbutton":
			var c: ScriptCmdWait = ScriptCmdWait.new()
			c.wait_for_input = true
			return c
		"fadeout":
			var c: ScriptCmdFade = ScriptCmdFade.new()
			c.fade_out = true
			if not args.is_empty() and str(args[0]).is_valid_float():
				c.duration = float(args[0])
			return c
		"fadein":
			var c: ScriptCmdFade = ScriptCmdFade.new()
			c.fade_out = false
			if not args.is_empty() and str(args[0]).is_valid_float():
				c.duration = float(args[0])
			return c
		"weather":
			var c: ScriptCmdWeather = ScriptCmdWeather.new()
			if not args.is_empty():
				c.weather_name = str(args[0])
			return c
		"multichoice":
			var c: ScriptCmdText = ScriptCmdText.new()
			if not args.is_empty():
				c.message = str(args[0])
			for i: int in range(1, args.size()):
				c.choices.append(str(args[i]))
			c.choice_variable = "last_choice"
			return c
		_:
			push_warning("ScriptCmdTextFile: comando no portado aún '%s'" % command_name)
			return null


func get_display_text() -> String:
	return "script: %s" % script_file_path.get_file()
