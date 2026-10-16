extends Control
class_name PartyPanel

@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel
@onready var hp_label: Label = $HpLabel
@onready var hp_bar: ProgressBar = $HpBar   # o TextureProgressBar luego

var _selected: bool = false


func bind(mon: Pokemon) -> void:
	visible = mon != null
	if mon == null:
		return
	name_label.text = mon.display_name()
	level_label.text = "Nv.%d" % mon.level
	var mx: int = mon.max_hp()
	hp_label.text = "%d/%d" % [mon.hp, mx]
	hp_bar.max_value = mx
	hp_bar.value = mon.hp


func set_selected(on: bool) -> void:
	_selected = on
	modulate = Color(1.2, 1.2, 1.0) if on else Color.WHITE
