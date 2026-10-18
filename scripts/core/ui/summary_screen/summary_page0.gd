extends Node2D
class_name SummaryPage0
## Página INFO. No toca el header Mon (está en SummaryScreen).

@onready var dex_number: Label = $Info/No_Dex/Dex_Number
@onready var species_name: Label = $Info/Specie/Specie_Name
@onready var type1: Sprite2D = $Info/Type/Type_1
@onready var type2: Sprite2D = $Info/Type/Type_2
@onready var tera_type: Sprite2D = $Info/Type/Tera_Type
@onready var ot_name: Label = $Info/EO/EO_Name
@onready var id_number: Label = $Info/No_ID/ID_Number
@onready var exp_points: Label = $Info/Exp_Points/Number_Exp_Points
@onready var next_lvl: Label = $Info/Next_Lvl/Number_Next_Lvl
@onready var exp_bar: Sprite2D = $Info/Exp_Bar


func bind(mon: Pokemon) -> void:
	if mon == null:
		return
	var data: SpeciesData = mon.species_data()

	if dex_number != null:
		var dex: int = 0
		if PokemonDB != null and PokemonDB.has_method("national_dex"):
			dex = PokemonDB.national_dex(mon.species_key)
		dex_number.text = "????" if dex <= 0 else "%04d" % dex

	if species_name != null:
		species_name.text = data.name if data != null else String(mon.species_key)

	_bind_types(data)

	if ot_name != null:
		ot_name.text = mon.ot_name if not mon.ot_name.is_empty() else "?????"
	if id_number != null:
		id_number.text = "00000"

	_bind_exp(mon, data)

	if tera_type != null:
		tera_type.visible = false


func _bind_types(data: SpeciesData) -> void:
	if type1 == null:
		return
	if data == null or data.types.is_empty():
		type1.visible = false
		if type2 != null:
			type2.visible = false
		return
	type1.frame = clampi(int(data.types[0]), 0, type1.vframes - 1)
	type1.visible = true
	if type2 != null:
		if data.types.size() >= 2:
			type2.frame = clampi(int(data.types[1]), 0, type2.vframes - 1)
			type2.visible = true
		else:
			type2.visible = false


func _bind_exp(mon: Pokemon, data: SpeciesData) -> void:
	var rate: PokemonEnums.GrowthRate = PokemonEnums.GrowthRate.MEDIUM_FAST
	if data != null:
		rate = data.growth_rate
	if exp_points != null:
		exp_points.text = _format_number(mon.exp)
	if next_lvl != null:
		next_lvl.text = _format_number(PokemonExp.exp_to_next(rate, mon.level, mon.exp))
	if exp_bar == null or exp_bar.texture == null:
		return
	if mon.level >= 100:
		exp_bar.visible = false
		return
	exp_bar.visible = true
	var start_e: int = PokemonExp.total_for_level(rate, mon.level)
	var end_e: int = PokemonExp.total_for_level(rate, mon.level + 1)
	var span: int = maxi(1, end_e - start_e)
	var frac: float = clampf(float(mon.exp - start_e) / float(span), 0.0, 1.0)
	var full_w: float = float(exp_bar.texture.get_width())
	var full_h: float = float(exp_bar.texture.get_height())
	var w: float = floor(frac * full_w / 2.0) * 2.0
	exp_bar.region_enabled = true
	exp_bar.region_rect = Rect2(0.0, 0.0, w, full_h)


func _format_number(n: int) -> String:
	var s: String = str(n)
	var out: String = ""
	var c: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		if c > 0 and c % 3 == 0:
			out = "," + out
		out = s[i] + out
		c += 1
	return out
