extends Node2D
class_name SummaryPage0
## Página INFO. La escena ya define layout, fuentes y colores.

@onready var mon_sprite: Sprite2D = $Mon
@onready var mon_name: Label = $Mon/Mon_Name
@onready var mon_level: Label = $Mon/Lvl
@onready var mon_gender: Label = $Mon/Gender
@onready var ball: Sprite2D = $Mon/Ball
@onready var item_sprite: Sprite2D = $Mon/Item_Sprite
@onready var item_label: Label = $Mon/Item_Sprite/Item_Name

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

	if mon_sprite != null:
		mon_sprite.texture = PokemonGraphics.load_front(mon.species_key, mon.form, mon.shiny)

	if mon_name != null:
		mon_name.text = mon.display_name()
	if mon_level != null:
		mon_level.text = str(mon.level)

	_bind_gender(mon)

	if ball != null:
		var ball_path: String = "res://assets/ui/Summary/icon_ball_POKEBALL.png"
		if ResourceLoader.exists(ball_path):
			ball.texture = load(ball_path) as Texture2D

	if item_label != null:
		if mon.held_item == &"":
			item_label.text = "Ninguno"
		else:
			var iname: String = String(mon.held_item)
			var idata: ItemData = PokemonDB.item(mon.held_item) if PokemonDB != null else null
			if idata != null and not idata.name.is_empty():
				iname = idata.name
			item_label.text = iname

	if dex_number != null:
		var dex: int = 0
		if PokemonDB != null and PokemonDB.has_method("national_dex"):
			dex = PokemonDB.national_dex(mon.species_key)
		dex_number.text = "???" if dex <= 0 else "%03d" % dex

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


func _bind_gender(mon: Pokemon) -> void:
	if mon_gender == null:
		return
	var g: int = 2
	if mon.get("gender") != null:
		g = int(mon.get("gender"))
	match g:
		0:
			mon_gender.text = "♂"
			mon_gender.visible = true
		1:
			mon_gender.text = "♀"
			mon_gender.visible = true
		_:
			mon_gender.text = ""
			mon_gender.visible = false


func _bind_types(data: SpeciesData) -> void:
	# types.png con vframes = 20 → frame = índice del tipo
	if type1 == null:
		return
	if data == null or data.types.is_empty():
		type1.visible = false
		if type2 != null:
			type2.visible = false
		return
	type1.vframes = 20
	type1.frame = clampi(int(data.types[0]), 0, 19)
	type1.visible = true
	if type2 != null:
		if data.types.size() >= 2:
			type2.vframes = 20
			type2.frame = clampi(int(data.types[1]), 0, 19)
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
	# No tocar position: la dejaste en el editor


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
