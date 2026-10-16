extends RefCounted
class_name Pokemon
## Ejemplar de equipo. No es la ficha de especie.

var species_key: StringName = &""
var form: int = 0
var nickname: String = ""
var level: int = 1
var exp: int = 0
var nature: PokemonEnums.Nature = PokemonEnums.Nature.HARDY
var ivs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
var evs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
var hp: int = 0
var status: StringName = &""
var held_item: StringName = &""
var move_keys: Array[StringName] = []
var move_pp: PackedInt32Array = PackedInt32Array()
var friendship: int = 70
var shiny: bool = false
var ot_name: String = ""
var ot_is_male: bool = true


static func create(
	species_key: StringName,
	level: int = 5,
	form: int = 0
) -> Pokemon:
	var mon: Pokemon = Pokemon.new()
	mon.species_key = species_key
	mon.form = form
	mon.level = clampi(level, 1, 100)
	mon.ivs = _random_ivs()
	mon.nature = PokemonEnums.Nature.values()[randi() % 25] as PokemonEnums.Nature
	var data: SpeciesData = mon.species_data()
	if data != null:
		mon.friendship = data.happiness
		mon.exp = PokemonExp.total_for_level(data.growth_rate, mon.level)
		mon._fill_moves_from_species(data)
	mon.recalc_hp(true)
	return mon


func species_data() -> SpeciesData:
	return PokemonDB.species(species_key, form)


func display_name() -> String:
	if not nickname.is_empty():
		return nickname
	var data: SpeciesData = species_data()
	if data == null:
		return String(species_key)
	if form > 0 and not data.form_name.is_empty():
		return data.form_name
	return data.name


func stats() -> PackedInt32Array:
	var data: SpeciesData = species_data()
	if data == null:
		return PackedInt32Array([1, 1, 1, 1, 1, 1])
	return PokemonStats.all_stats(data.base_stats, ivs, evs, level, nature)


func max_hp() -> int:
	return stats()[0]


func recalc_hp(fill: bool = false) -> void:
	var mx: int = max_hp()
	if fill or hp <= 0:
		hp = mx
	else:
		hp = mini(hp, mx)


func add_exp(amount: int) -> bool:
	## Devuelve true si subió de nivel.
	if amount <= 0 or level >= 100:
		return false
	var data: SpeciesData = species_data()
	if data == null:
		return false
	exp += amount
	var old_level: int = level
	level = PokemonExp.level_from_exp(data.growth_rate, exp)
	if level > old_level:
		recalc_hp(false)
		# Al subir nivel, los PS suben la diferencia de max_hp (simplificado: no curamos del todo)
		return true
	return false


func to_dict() -> Dictionary:
	return {
		"species_key": String(species_key),
		"form": form,
		"nickname": nickname,
		"level": level,
		"exp": exp,
		"nature": int(nature),
		"ivs": Array(ivs),
		"evs": Array(evs),
		"hp": hp,
		"status": String(status),
		"held_item": String(held_item),
		"move_keys": _names_to_array(move_keys),
		"move_pp": Array(move_pp),
		"friendship": friendship,
		"shiny": shiny,
		"ot_name": ot_name,
		"ot_is_male": ot_is_male,
	}


static func from_dict(data: Dictionary) -> Pokemon:
	var mon: Pokemon = Pokemon.new()
	mon.species_key = StringName(str(data.get("species_key", "")))
	mon.form = int(data.get("form", 0))
	mon.nickname = str(data.get("nickname", ""))
	mon.level = int(data.get("level", 1))
	mon.exp = int(data.get("exp", 0))
	mon.nature = int(data.get("nature", 0)) as PokemonEnums.Nature
	mon.ivs = _to_six(data.get("ivs", []), 0)
	mon.evs = _to_six(data.get("evs", []), 0)
	mon.hp = int(data.get("hp", 0))
	mon.status = StringName(str(data.get("status", "")))
	mon.held_item = StringName(str(data.get("held_item", "")))
	mon.move_keys = _to_names(data.get("move_keys", []))
	mon.move_pp = _to_packed(data.get("move_pp", []))
	mon.friendship = int(data.get("friendship", 70))
	mon.shiny = bool(data.get("shiny", false))
	mon.ot_name = str(data.get("ot_name", ""))
	mon.ot_is_male = bool(data.get("ot_is_male", true))
	return mon


func _fill_moves_from_species(data: SpeciesData) -> void:
	move_keys.clear()
	var learned: Array[StringName] = []
	for entry: LearnsetEntry in data.moves:
		if entry.level <= level:
			learned.append(entry.move_key)
	# Últimos 4
	var start: int = maxi(0, learned.size() - 4)
	for i: int in range(start, learned.size()):
		move_keys.append(learned[i])
	move_pp.resize(move_keys.size())
	for i: int in range(move_keys.size()):
		var md: MoveData = PokemonDB.move(move_keys[i])
		move_pp[i] = md.total_pp if md != null else 5


static func _random_ivs() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(6)
	for i: int in range(6):
		out[i] = randi_range(0, 31)
	return out


static func _to_six(value: Variant, fill: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(6)
	out.fill(fill)
	if value is Array:
		for i: int in mini(6, value.size()):
			out[i] = int(value[i])
	return out


static func _to_packed(value: Variant) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	if value is Array:
		for item: Variant in value:
			out.append(int(item))
	return out


static func _to_names(value: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if value is Array:
		for item: Variant in value:
			out.append(StringName(str(item)))
	return out


static func _names_to_array(names: Array[StringName]) -> Array:
	var out: Array = []
	for n: StringName in names:
		out.append(String(n))
	return out
