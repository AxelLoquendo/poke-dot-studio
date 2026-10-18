extends Object
class_name PokemonCry

const CRIES_DIR: String = "res://sfx/se/cries/"
static var _player: AudioStreamPlayer

static func play(species_key: StringName, form: int = 0) -> void:
	stop()
	var stream: AudioStream = _load_stream(species_key, form)
	if stream == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = AudioStreamPlayer.new()
		_player.name = "PokemonCryPlayer"
		# Bus de SFX si lo tienes
		if AudioServer.get_bus_index("SFX") >= 0:
			_player.bus = "SFX"
		Engine.get_main_loop().root.add_child(_player)
	_player.stream = stream
	_player.play()

static func stop() -> void:
	if _player != null and is_instance_valid(_player) and _player.playing:
		_player.stop()

static func _load_stream(species_key: StringName, form: int) -> AudioStream:
	var key: String = String(species_key).to_upper()
	var candidates: PackedStringArray = PackedStringArray()
	if form > 0:
		candidates.append(CRIES_DIR + "%s_%d.ogg" % [key, form])
		candidates.append(CRIES_DIR + "%s_%d.wav" % [key, form])
	candidates.append(CRIES_DIR + "%s.ogg" % key)
	candidates.append(CRIES_DIR + "%s.wav" % key)
	# Variante nombre en minúsculas (algunos packs)
	candidates.append(CRIES_DIR + key.to_lower() + ".ogg")
	for path: String in candidates:
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
