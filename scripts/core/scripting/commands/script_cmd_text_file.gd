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
			return _cmd_label(args)
		"goto":
			return _cmd_goto(args)
		"ifchoice":
			return _cmd_if_choice(args)
		"ifflag":
			return _cmd_if_flag(args)
		"setflag":
			return _cmd_flag(args, true)
		"clearflag":
			return _cmd_flag(args, false)
		"faceplayer":
			return ScriptCmdFacePlayer.new()
		"lock":
			return _cmd_lock(true)
		"release":
			return _cmd_lock(false)
		"waitbutton":
			return _cmd_wait_button()
		"fadeout":
			return _cmd_fade(args, true)
		"fadein":
			return _cmd_fade(args, false)
		"weather":
			return _cmd_weather(args)
		"multichoice":
			return _cmd_multichoice(args)
		"warp":
			return _cmd_warp(args)
		"applymovement":
			return _cmd_apply_movement(args, false)
		"moveplayer":
			return _cmd_apply_movement(args, true)
		"waitmovement":
			return _cmd_wait_movement(args)
		"wait":
			return _cmd_wait_time(args)
		"sound":
			return _cmd_sound(args)
		"setvar":
			return _cmd_set_var(args, false)
		"addvar":
			return _cmd_set_var(args, true)
		"compare":
			return _cmd_compare(args)
		"savegame":
			return _cmd_save_game(args)
		_:
			push_warning("ScriptCmdTextFile: comando no portado aún '%s'" % command_name)
			return null


func _cmd_label(args: Array) -> ScriptCmdLabel:
	var c: ScriptCmdLabel = ScriptCmdLabel.new()
	if not args.is_empty():
		c.label_name = str(args[0])
	return c


func _cmd_goto(args: Array) -> ScriptCmdGoto:
	var c: ScriptCmdGoto = ScriptCmdGoto.new()
	if not args.is_empty():
		c.target_label = str(args[0])
	return c


func _cmd_if_choice(args: Array) -> ScriptCmdIfChoice:
	var c: ScriptCmdIfChoice = ScriptCmdIfChoice.new()
	if not args.is_empty():
		c.expected_choice = str(args[0])
	if args.size() > 1:
		c.target_label = str(args[1])
	return c


func _cmd_if_flag(args: Array) -> ScriptCmdIfFlag:
	var c: ScriptCmdIfFlag = ScriptCmdIfFlag.new()
	if not args.is_empty():
		c.flag_name = str(args[0])
	if args.size() > 1:
		c.target_label = str(args[1])
	return c


func _cmd_flag(args: Array, value: bool) -> ScriptCmdSetFlag:
	var c: ScriptCmdSetFlag = ScriptCmdSetFlag.new()
	if not args.is_empty():
		c.flag_name = str(args[0])
	c.value = value
	return c


func _cmd_lock(lock_player: bool) -> ScriptCmdLock:
	var c: ScriptCmdLock = ScriptCmdLock.new()
	c.lock_player = lock_player
	return c


func _cmd_wait_button() -> ScriptCmdWait:
	var c: ScriptCmdWait = ScriptCmdWait.new()
	c.wait_for_input = true
	return c


func _cmd_fade(args: Array, fade_out: bool) -> ScriptCmdFade:
	var c: ScriptCmdFade = ScriptCmdFade.new()
	c.fade_out = fade_out
	if not args.is_empty() and str(args[0]).is_valid_float():
		c.duration = float(args[0])
	return c


func _cmd_weather(args: Array) -> ScriptCmdWeather:
	var c: ScriptCmdWeather = ScriptCmdWeather.new()
	if not args.is_empty():
		c.weather_name = str(args[0])
	return c


func _cmd_multichoice(args: Array) -> ScriptCmdText:
	var c: ScriptCmdText = ScriptCmdText.new()
	if not args.is_empty():
		c.message = str(args[0])
	for i: int in range(1, args.size()):
		c.choices.append(str(args[i]))
	c.choice_variable = "last_choice"
	return c

func _cmd_warp(args: Array) -> ScriptCmdWarp:
	var c: ScriptCmdWarp = ScriptCmdWarp.new()
	if args.is_empty():
		push_warning("warp: falta map_id")
		return c
	c.map_token = str(args[0])
	if args.size() >= 3:
		c.cell = Vector2i(int(str(args[1])), int(str(args[2])))
	if args.size() >= 4:
		c.facing = ScriptCmdWarp._resolve_facing(str(args[3]))
	return c

func _cmd_apply_movement(args: Array, force_player: bool) -> ScriptCmdApplyMovement:
	var c: ScriptCmdApplyMovement = ScriptCmdApplyMovement.new()
	var i: int = 0
	if force_player:
		c.target_token = "player"
	elif not args.is_empty() and not _is_step(str(args[0])):
		c.target_token = str(args[0])
		i = 1
	var tokens: PackedStringArray = PackedStringArray()
	while i < args.size():
		for part: String in str(args[i]).split(",", false):
			var p: String = part.strip_edges()
			if not p.is_empty():
				tokens.append(p)
		i += 1
	c.route_tokens = tokens
	return c

func _is_step(s: String) -> bool:
	var t: String = s.to_lower()
	return t.begins_with("walk_") or t.begins_with("face_") or t.begins_with("wait_")

func _cmd_wait_movement(args: Array) -> ScriptCmdWaitMovement:
	var c: ScriptCmdWaitMovement = ScriptCmdWaitMovement.new()
	if not args.is_empty():
		c.target_token = str(args[0])
	return c

func _cmd_wait_time(args: Array) -> ScriptCmdWait:
	var c: ScriptCmdWait = ScriptCmdWait.new()
	c.wait_for_input = false
	if not args.is_empty() and str(args[0]).is_valid_float():
		c.duration = float(args[0])
	return c

func _cmd_sound(args: Array) -> ScriptCmdSound:
	var c: ScriptCmdSound = ScriptCmdSound.new()
	if not args.is_empty():
		c.sound_token = str(args[0])
	return c

func _cmd_set_var(args: Array, is_add: bool) -> ScriptCmdSetVar:
	var c: ScriptCmdSetVar = ScriptCmdSetVar.new()
	c.is_add = is_add
	if args.size() >= 1:
		c.var_name = str(args[0])
	if args.size() >= 2 and str(args[1]).is_valid_float():
		c.value = float(args[1])
	return c

func _cmd_compare(args: Array) -> ScriptCmdCompare:
	var c: ScriptCmdCompare = ScriptCmdCompare.new()
	# compare nombre == 1 etiqueta
	if args.size() >= 1:
		c.var_name = str(args[0])
	if args.size() >= 2:
		c.op = str(args[1])
	if args.size() >= 3 and str(args[2]).is_valid_float():
		c.expected = float(args[2])
	if args.size() >= 4:
		c.target_label = str(args[3])
	return c

func _cmd_save_game(args: Array) -> ScriptCmdSaveGame:
	var c: ScriptCmdSaveGame = ScriptCmdSaveGame.new()
	if not args.is_empty() and str(args[0]).strip_edges().to_lower() == "silent":
		c.silent = true
	return c

func get_display_text() -> String:
	return "script: %s" % script_file_path.get_file()
