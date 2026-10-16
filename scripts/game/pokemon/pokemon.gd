extends RefCounted
class_name Pokemon

var species_key: StringName = &""
var form: int = 0
var level: int = 1
var nature: PokemonEnums.Nature = PokemonEnums.Nature.HARDY
var ivs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
var evs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
var exp: int = 0
var held_item: StringName = &""
var move_keys: Array[StringName] = []
var nickname: String = ""


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
