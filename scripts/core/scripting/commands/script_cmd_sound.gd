@tool
extends ScriptCommand
class_name ScriptCmdSound

@export var sound_token: String = ""

func execute(_context: ScriptExecutionContext) -> bool:
	var key: String = sound_token.strip_edges().to_upper()
	if key.is_empty():
		return true
	if not key.begins_with("SE_"):
		key = "SE_" + key
	for name: String in SFXGame.SoundEffectID.keys():
		if name == key:
			MusicManager.reproducir_se(SFXGame.SoundEffectID[name])
			return true
	push_warning("sound: desconocido '%s'" % sound_token)
	return true
