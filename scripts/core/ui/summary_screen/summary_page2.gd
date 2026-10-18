extends Node2D
class_name SummaryPage2
## Skills (PE page 3). Tres subvistas: Skills / Ability desc / Stats.

enum SubView { SKILLS, ABILITY_DESC, STATS }

@onready var bg: Sprite2D = $Bg
@onready var bg_ability: Sprite2D = $Bg_Ability_Desc
@onready var bg_stats: Sprite2D = $Bg_Stats
@onready var skills: Node2D = $Skills
@onready var stats: Node2D = $Stats

@onready var ps_number: Label = $Skills/PS/PS_Number
@onready var atk_number: Label = $Skills/Attack/Attack_Number
@onready var def_number: Label = $Skills/Defense/Defense_Number
@onready var spa_number: Label = $Skills/Sp_Attack/Sp_Attack_Number
@onready var spd_number: Label = $Skills/Sp_Defense/Sp_Defense_Number
@onready var spe_number: Label = $Skills/Velocity/Velocity_Number
@onready var hp_bar: Sprite2D = $Skills/Hp_Bar
@onready var ability_name: Label = $Skills/Ability/Ability_Name
@onready var ability_desc: Label = $Bg_Ability_Desc/Ability_Description

@onready var st_ps: Label = $Stats/PS/PS_Number
@onready var st_ps_iv: Label = $Stats/PS/PS_Number_IV
@onready var st_ps_ev: Label = $Stats/PS/PS_Number_EV
@onready var st_atk: Label = $Stats/Attack/Attack_Number
@onready var st_atk_iv: Label = $Stats/Attack/Attack_Number_IV
@onready var st_atk_ev: Label = $Stats/Attack/Attack_Number_EV
@onready var st_def: Label = $Stats/Defense/Defense_Number
@onready var st_def_iv: Label = $Stats/Defense/Defense_Number_IV
@onready var st_def_ev: Label = $Stats/Defense/Defense_Number_EV
@onready var st_spa: Label = $Stats/Sp_Attack/Sp_Attack_Number
@onready var st_spa_iv: Label = $Stats/Sp_Attack/Sp_Attack_Number_IV
@onready var st_spa_ev: Label = $Stats/Sp_Attack/Sp_Attack_Number_EV
@onready var st_spd: Label = $Stats/Sp_Defense/Sp_Defense_Number
@onready var st_spd_iv: Label = $Stats/Sp_Defense/Sp_Defense_Number_IV
@onready var st_spd_ev: Label = $Stats/Sp_Defense/Sp_Defense_Number_EV
@onready var st_spe: Label = $Stats/Velocity/Velocity_Number
@onready var st_spe_iv: Label = $Stats/Velocity/Velocity_Number_IV
@onready var st_spe_ev: Label = $Stats/Velocity/Velocity_Number_EV
@onready var evs_total_num: Label = $Stats/EVs_Total/Number_Evs_Total

var _sub: SubView = SubView.SKILLS


func bind(mon: Pokemon) -> void:
	if mon == null:
		return
	_set_sub(SubView.SKILLS)
	_bind_skills(mon)
	_bind_stats_detail(mon)
	_bind_ability(mon)


func is_in_subview() -> bool:
	return _sub != SubView.SKILLS


func open_ability_desc() -> void:
	if _sub == SubView.SKILLS:
		_set_sub(SubView.ABILITY_DESC)


func open_stats() -> void:
	if _sub == SubView.SKILLS:
		_set_sub(SubView.STATS)


## true = consumió B (volver de subvista); false = delegar cierre al summary
func try_back() -> bool:
	if _sub != SubView.SKILLS:
		_set_sub(SubView.SKILLS)
		return true
	return false


func reset_subview() -> void:
	_set_sub(SubView.SKILLS)


func _set_sub(s: SubView) -> void:
	_sub = s
	if bg != null:
		bg.visible = (s == SubView.SKILLS)
	if skills != null:
		skills.visible = (s == SubView.SKILLS)
	if bg_ability != null:
		bg_ability.visible = (s == SubView.ABILITY_DESC)
	if bg_stats != null:
		bg_stats.visible = (s == SubView.STATS)
	if stats != null:
		stats.visible = (s == SubView.STATS)


func _bind_skills(mon: Pokemon) -> void:
	var st: PackedInt32Array = mon.stats()
	var mx: int = maxi(1, mon.max_hp())
	var hp: int = clampi(mon.hp, 0, mx)
	if ps_number != null:
		ps_number.text = "%d/%d" % [hp, mx]
	if atk_number != null:
		atk_number.text = str(st[1])
	if def_number != null:
		def_number.text = str(st[2])
	if spa_number != null:
		spa_number.text = str(st[4])
	if spd_number != null:
		spd_number.text = str(st[5])
	if spe_number != null:
		spe_number.text = str(st[3])
	_bind_hp_bar(hp, mx)


func _bind_hp_bar(hp: int, mx: int) -> void:
	if hp_bar == null:
		return
	# PE overlay_hp: vframes 0 verde, 1 amarillo, 2 rojo
	var ratio: float = float(hp) / float(maxi(1, mx))
	var zone: int = 0
	if ratio <= 0.25:
		zone = 2
	elif ratio <= 0.5:
		zone = 1
	hp_bar.vframes = 3
	hp_bar.frame = zone
	hp_bar.region_enabled = true
	var full_w: float = float(hp_bar.texture.get_width()) if hp_bar.texture else 96.0
	var full_h: float = float(hp_bar.texture.get_height()) / 3.0 if hp_bar.texture else 6.0
	var w: float = floor(ratio * full_w / 2.0) * 2.0
	if w < 2.0 and hp > 0:
		w = 2.0
	hp_bar.region_rect = Rect2(0.0, float(zone) * full_h, w, full_h)
	hp_bar.visible = hp > 0


func _bind_ability(mon: Pokemon) -> void:
	var key: StringName = &""
	if mon.get("ability") != null and str(mon.get("ability")) != "":
		key = mon.get("ability") as StringName
	else:
		var data: SpeciesData = mon.species_data()
		if data != null and data.abilities.size() > 0:
			key = data.abilities[0]
	var aname: String = String(key)
	var desc: String = ""
	if PokemonDB != null and key != &"":
		var ab: AbilityData = PokemonDB.ability(key)
		if ab != null:
			if not str(ab.name).is_empty():
				aname = str(ab.name)
			if "description" in ab:
				desc = str(ab.description)
			elif ab.get("description") != null:
				desc = str(ab.get("description"))
	if ability_name != null:
		ability_name.text = aname
	if ability_desc != null:
		ability_desc.text = desc


func _bind_stats_detail(mon: Pokemon) -> void:
	var st: PackedInt32Array = mon.stats()
	_set_row(st_ps, st_ps_iv, st_ps_ev, st[0], mon.ivs, mon.evs, 0)
	_set_row(st_atk, st_atk_iv, st_atk_ev, st[1], mon.ivs, mon.evs, 1)
	_set_row(st_def, st_def_iv, st_def_ev, st[2], mon.ivs, mon.evs, 2)
	_set_row(st_spa, st_spa_iv, st_spa_ev, st[4], mon.ivs, mon.evs, 4)
	_set_row(st_spd, st_spd_iv, st_spd_ev, st[5], mon.ivs, mon.evs, 5)
	_set_row(st_spe, st_spe_iv, st_spe_ev, st[3], mon.ivs, mon.evs, 3)
	if evs_total_num != null:
		var total: int = 0
		for i: int in range(mini(6, mon.evs.size())):
			total += int(mon.evs[i])
		evs_total_num.text = str(total)


func _set_row(val: Label, iv_l: Label, ev_l: Label, stat: int, ivs: PackedInt32Array, evs: PackedInt32Array, idx: int) -> void:
	if val != null:
		val.text = str(stat)
	if iv_l != null:
		iv_l.text = str(int(ivs[idx]) if idx < ivs.size() else 0)
	if ev_l != null:
		ev_l.text = str(int(evs[idx]) if idx < evs.size() else 0)
