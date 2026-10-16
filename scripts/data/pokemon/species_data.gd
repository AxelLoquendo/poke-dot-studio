extends Resource
class_name SpeciesData

@export var key: StringName = &""
@export var name: String = ""
@export var form: int = 0
@export var form_name: String = ""

@export var types: Array[PokemonEnums.TypeId] = []
@export var base_stats: PackedInt32Array = PackedInt32Array([1, 1, 1, 1, 1, 1])
@export var evs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])

@export var gender_ratio: PokemonEnums.GenderRatio = PokemonEnums.GenderRatio.FEMALE_50_PERCENT
@export var growth_rate: PokemonEnums.GrowthRate = PokemonEnums.GrowthRate.MEDIUM_FAST
@export var base_exp: int = 0
@export var catch_rate: int = 45
@export var happiness: int = 70

@export var abilities: Array[StringName] = []
@export var hidden_abilities: Array[StringName] = []

@export var moves: Array[LearnsetEntry] = []
@export var tutor_moves: Array[StringName] = []
@export var egg_moves: Array[StringName] = []

@export var egg_groups: Array[PokemonEnums.EggGroup] = []
@export var hatch_steps: int = 5120
@export var height_m: float = 0.1
@export var weight_kg: float = 0.1
@export var color: PokemonEnums.BodyColor = PokemonEnums.BodyColor.GREEN
@export var shape: PokemonEnums.BodyShape = PokemonEnums.BodyShape.QUADRUPED
@export var habitat: String = ""
@export var category: String = ""
@export_multiline var pokedex: String = ""
@export var generation: int = 1

@export var evolutions: Array[EvolutionRule] = []
@export var flags: PackedStringArray = PackedStringArray()
@export var wild_item_common: StringName = &""
@export var wild_item_uncommon: StringName = &""
@export var wild_item_rare: StringName = &""
@export var incense: StringName = &""
@export var offspring: StringName = &""

@export var mega_stone: StringName = &""
@export var mega_move: StringName = &""
@export var mega_message: String = ""
@export var unmega_form: int = 0
@export var pokedex_form: int = 0


func registry_key() -> String:
	if form <= 0:
		return String(key)
	return "%s#%d" % [String(key), form]


func duplicate_base() -> SpeciesData:
	return duplicate(true) as SpeciesData


func apply_form(patch: SpeciesData) -> void:
	form = patch.form
	if not patch.form_name.is_empty():
		form_name = patch.form_name
	if not patch.name.is_empty():
		name = patch.name
	if not patch.types.is_empty():
		types = patch.types.duplicate()
	if patch.base_stats.size() == PokemonEnums.STAT_COUNT and patch.base_stats[0] > 0:
		base_stats = patch.base_stats.duplicate()
	if _evs_any(patch.evs):
		evs = patch.evs.duplicate()
	if not patch.abilities.is_empty():
		abilities = patch.abilities.duplicate()
	if not patch.hidden_abilities.is_empty():
		hidden_abilities = patch.hidden_abilities.duplicate()
	if not patch.moves.is_empty():
		moves = patch.moves.duplicate(true)
	if not patch.tutor_moves.is_empty():
		tutor_moves = patch.tutor_moves.duplicate()
	if not patch.egg_moves.is_empty():
		egg_moves = patch.egg_moves.duplicate()
	if not patch.egg_groups.is_empty():
		egg_groups = patch.egg_groups.duplicate()
	if patch.base_exp > 0:
		base_exp = patch.base_exp
	if patch.height_m > 0.0:
		height_m = patch.height_m
	if patch.weight_kg > 0.0:
		weight_kg = patch.weight_kg
	if not patch.category.is_empty():
		category = patch.category
	if not patch.pokedex.is_empty():
		pokedex = patch.pokedex
	if not patch.habitat.is_empty():
		habitat = patch.habitat
	if not patch.flags.is_empty():
		flags = patch.flags.duplicate()
	if patch.generation > 0:
		generation = patch.generation
	if not patch.evolutions.is_empty():
		evolutions = patch.evolutions.duplicate(true)
	mega_stone = patch.mega_stone
	mega_move = patch.mega_move
	mega_message = patch.mega_message
	unmega_form = patch.unmega_form
	pokedex_form = patch.pokedex_form
	color = patch.color
	shape = patch.shape


func _evs_any(values: PackedInt32Array) -> bool:
	for n: int in values:
		if n != 0:
			return true
	return false
