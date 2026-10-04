class_name MapMusicController
extends Node

var _mapa: Map

func _ready() -> void:
	_mapa = get_parent() as Map
	if _mapa == null:
		push_warning("MapMusicController: el padre no es Map")
		return
	if Engine.is_editor_hint():
		return
	_reproducir()

func on_map_attributes_ready(mapa: Map) -> void:
	_mapa = mapa
	if Engine.is_editor_hint():
		return
	_reproducir()

func _reproducir() -> void:
	if _mapa == null or _mapa.attributes == null:
		return
	MusicManager.reproducir_mapa(_mapa.attributes.map_music)
