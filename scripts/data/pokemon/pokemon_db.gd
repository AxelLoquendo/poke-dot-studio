extends Node

const DATA_DIR: String = "res://data/pokemon/"

var _types: Dictionary = {}
var _abilities: Dictionary = {}
var _moves: Dictionary = {}
var _items: Dictionary = {}
var _species: Dictionary = {}
var _forms: Dictionary = {}


func _ready() -> void:
	_load_all()


func species(key: StringName, form: int = 0) -> SpeciesData:
	var base: SpeciesData = _species.get(String(key), null)
	if base == null or form <= 0:
		return base
	var patch: SpeciesData = _forms.get("%s#%d" % [String(key), form], null)
	if patch == null:
		return base
	var merged: SpeciesData = base.duplicate_base()
	merged.apply_form(patch)
	return merged


func move(key: StringName) -> MoveData:
	return _moves.get(String(key), null)


func ability(key: StringName) -> AbilityData:
	return _abilities.get(String(key), null)


func item(key: StringName) -> ItemData:
	return _items.get(String(key), null)


func type_data(id: PokemonEnums.TypeId) -> TypeData:
	return _types.get(id, null)


func type_effectiveness(attack: PokemonEnums.TypeId, def1: PokemonEnums.TypeId, def2: PokemonEnums.TypeId = PokemonEnums.TypeId.NONE) -> float:
	var m: float = TypeChart.multiplier(attack, type_data(def1))
	if def2 != PokemonEnums.TypeId.NONE and def2 != def1:
		m *= TypeChart.multiplier(attack, type_data(def2))
	return m


func _load_all() -> void:
	_load_types(_read_json("types.json"))
	_load_abilities(_read_json("abilities.json"))
	_load_moves(_read_json("moves.json"))
	_load_items(_read_json("items.json"))
	_load_species(_read_json("species.json"))
	_load_forms(_read_json("forms.json"))


func _read_json(file_name: String) -> Array:
	var path: String = DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		push_warning("PokemonDB: falta %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Array:
		return parsed
	push_error("PokemonDB: %s no es un array" % path)
	return []


func _load_types(rows: Array) -> void:
	for row: Variant in rows:
		if row is not Dictionary:
			continue
		var data: TypeData = TypeData.new()
		data.key = StringName(str(row.get("key", "")))
		data.id = PokemonEnums.type_from_key(String(data.key))
		data.name = str(row.get("name", ""))
		data.icon_position = int(row.get("icon_position", 0))
		data.weaknesses = _type_list(row.get("weaknesses", []))
		data.resistances = _type_list(row.get("resistances", []))
		data.immunities = _type_list(row.get("immunities", []))
		_types[data.id] = data


func _load_abilities(rows: Array) -> void:
	for row: Variant in rows:
		if row is not Dictionary:
			continue
		var data: AbilityData = AbilityData.new()
		data.key = StringName(str(row.get("key", "")))
		data.name = str(row.get("name", ""))
		data.description = str(row.get("description", ""))
		_abilities[String(data.key)] = data


func _load_moves(rows: Array) -> void:
	for row: Variant in rows:
		if row is not Dictionary:
			continue
		var data: MoveData = MoveData.new()
		data.key = StringName(str(row.get("key", "")))
		data.name = str(row.get("name", ""))
		data.type = PokemonEnums.type_from_key(str(row.get("type", "NORMAL")))
		data.category = PokemonEnums.category_from_key(str(row.get("category", "Physical")))
		data.power = int(row.get("power", 0))
		data.accuracy = int(row.get("accuracy", 100))
		data.total_pp = int(row.get("total_pp", 5))
		data.target = StringName(str(row.get("target", "NearOther")))
		data.function_code = StringName(str(row.get("function_code", "None")))
		data.effect_chance = int(row.get("effect_chance", 0))
		data.priority = int(row.get("priority", 0))
		data.description = str(row.get("description", ""))
		data.flags = _string_pack(row.get("flags", []))
		_moves[String(data.key)] = data


func _load_items(rows: Array) -> void:
	for row: Variant in rows:
		if row is not Dictionary:
			continue
		var data: ItemData = ItemData.new()
		data.key = StringName(str(row.get("key", "")))
		data.name = str(row.get("name", ""))
		data.pocket = StringName(str(row.get("pocket", "ITEMS")))
		data.price = int(row.get("price", 0))
		data.description = str(row.get("description", ""))
		data.flags = _string_pack(row.get("flags", []))
		_items[String(data.key)] = data


func _load_species(rows: Array) -> void:
	for row: Variant in rows:
		if row is not Dictionary:
			continue
		var data: SpeciesData = _species_from_dict(row, 0)
		_species[String(data.key)] = data


func _load_forms(rows: Array) -> void:
	for row: Variant in rows:
		if row is not Dictionary:
			continue
		var form: int = int(row.get("form", 1))
		var data: SpeciesData = _species_from_dict(row, form)
		_forms["%s#%d" % [String(data.key), form]] = data


func _species_from_dict(row: Dictionary, form: int) -> SpeciesData:
	var data: SpeciesData = SpeciesData.new()
	data.key = StringName(str(row.get("key", "")))
	data.form = form
	data.form_name = str(row.get("form_name", ""))
	data.name = str(row.get("name", ""))
	data.types = _type_list(row.get("types", []))
	data.base_stats = _six(row.get("base_stats", []), 1)
	data.evs = _evs(row.get("evs", []))
	data.gender_ratio = PokemonEnums.gender_from_key(str(row.get("gender_ratio", "Female50Percent")))
	data.growth_rate = PokemonEnums.growth_from_key(str(row.get("growth_rate", "Medium")))
	data.base_exp = int(row.get("base_exp", 0))
	data.catch_rate = int(row.get("catch_rate", 45))
	data.happiness = int(row.get("happiness", 70))
	data.abilities = _name_list(row.get("abilities", []))
	data.hidden_abilities = _name_list(row.get("hidden_abilities", []))
	data.moves = _learnset(row.get("moves", []))
	data.tutor_moves = _name_list(row.get("tutor_moves", []))
	data.egg_moves = _name_list(row.get("egg_moves", []))
	data.egg_groups = _egg_list(row.get("egg_groups", []))
	data.hatch_steps = int(row.get("hatch_steps", 5120))
	data.height_m = float(row.get("height_m", 0.1))
	data.weight_kg = float(row.get("weight_kg", 0.1))
	data.color = PokemonEnums.color_from_key(str(row.get("color", "Green")))
	data.shape = PokemonEnums.shape_from_key(str(row.get("shape", "Quadruped")))
	data.habitat = str(row.get("habitat", ""))
	data.category = str(row.get("category", ""))
	data.pokedex = str(row.get("pokedex", ""))
	data.generation = int(row.get("generation", 1))
	data.evolutions = _evolutions(row.get("evolutions", []))
	data.flags = _string_pack(row.get("flags", []))
	data.wild_item_common = StringName(str(row.get("wild_item_common", "")))
	data.wild_item_uncommon = StringName(str(row.get("wild_item_uncommon", "")))
	data.wild_item_rare = StringName(str(row.get("wild_item_rare", "")))
	data.incense = StringName(str(row.get("incense", "")))
	data.offspring = StringName(str(row.get("offspring", "")))
	data.mega_stone = StringName(str(row.get("mega_stone", "")))
	data.mega_move = StringName(str(row.get("mega_move", "")))
	data.mega_message = str(row.get("mega_message", ""))
	data.unmega_form = int(row.get("unmega_form", 0))
	data.pokedex_form = int(row.get("pokedex_form", 0))
	return data


func _type_list(value: Variant) -> Array[PokemonEnums.TypeId]:
	var out: Array[PokemonEnums.TypeId] = []
	if value is Array:
		for item: Variant in value:
			out.append(PokemonEnums.type_from_key(str(item)))
	return out


func _name_list(value: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if value is Array:
		for item: Variant in value:
			out.append(StringName(str(item)))
	return out


func _egg_list(value: Variant) -> Array[PokemonEnums.EggGroup]:
	var out: Array[PokemonEnums.EggGroup] = []
	if value is Array:
		for item: Variant in value:
			out.append(PokemonEnums.egg_from_key(str(item)))
	return out


func _learnset(value: Variant) -> Array[LearnsetEntry]:
	var out: Array[LearnsetEntry] = []
	if value is not Array:
		return out
	for item: Variant in value:
		if item is not Dictionary:
			continue
		var entry: LearnsetEntry = LearnsetEntry.new()
		entry.level = int(item.get("level", 1))
		entry.move_key = StringName(str(item.get("move", "")))
		out.append(entry)
	return out


func _evolutions(value: Variant) -> Array[EvolutionRule]:
	var out: Array[EvolutionRule] = []
	if value is not Array:
		return out
	for item: Variant in value:
		if item is not Dictionary:
			continue
		var rule: EvolutionRule = EvolutionRule.new()
		rule.into_species = StringName(str(item.get("into", "")))
		rule.method = StringName(str(item.get("method", "")))
		rule.parameter = str(item.get("parameter", ""))
		out.append(rule)
	return out


func _six(value: Variant, fill: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(PokemonEnums.STAT_COUNT)
	out.fill(fill)
	if value is Array:
		for i: int in mini(PokemonEnums.STAT_COUNT, value.size()):
			out[i] = int(value[i])
	return out


func _evs(value: Variant) -> PackedInt32Array:
	return _six(value, 0)


func _string_pack(value: Variant) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if value is Array:
		for item: Variant in value:
			out.append(str(item))
	return out
