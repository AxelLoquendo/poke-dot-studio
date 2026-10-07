class_name MapMusicController
extends Node
## Sin autoplay. Solo el mapa current llama activar().

var _mapa: Map


func _ready() -> void:
	_mapa = get_parent() as Map
	if _mapa == null:
		push_warning("MapMusicController: el padre no es Map")


func on_map_attributes_ready(mapa: Map) -> void:
	_mapa = mapa


func activar() -> void:
	if Engine.is_editor_hint():
		return
	if _mapa == null or _mapa.attributes == null:
		return
	MusicManager.reproducir_mapa(_mapa.attributes.map_music)
