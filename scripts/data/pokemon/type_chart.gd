extends Object
class_name TypeChart

static func multiplier(attack: PokemonEnums.TypeId, defend: TypeData) -> float:
	if defend == null or attack == PokemonEnums.TypeId.NONE:
		return 1.0
	if attack in defend.immunities:
		return 0.0
	if attack in defend.weaknesses:
		return 2.0
	if attack in defend.resistances:
		return 0.5
	return 1.0
