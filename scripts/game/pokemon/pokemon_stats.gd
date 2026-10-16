extends Object
class_name PokemonStats
## Fórmulas de stats alineadas a Pokémon Essentials.

## Índices: 0 HP, 1 Atk, 2 Def, 3 Spe, 4 SpA, 5 SpDef
const NATURE_MOD: Array[Array] = [
	# HARDY
	[1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
	# LONELY +Atk -Def
	[1.0, 1.1, 0.9, 1.0, 1.0, 1.0],
	# BRAVE +Atk -Spe
	[1.0, 1.1, 1.0, 0.9, 1.0, 1.0],
	# ADAMANT +Atk -SpA
	[1.0, 1.1, 1.0, 1.0, 0.9, 1.0],
	# NAUGHTY +Atk -SpD
	[1.0, 1.1, 1.0, 1.0, 1.0, 0.9],
	# BOLD +Def -Atk
	[1.0, 0.9, 1.1, 1.0, 1.0, 1.0],
	# DOCILE
	[1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
	# RELAXED +Def -Spe
	[1.0, 1.0, 1.1, 0.9, 1.0, 1.0],
	# IMPISH +Def -SpA
	[1.0, 1.0, 1.1, 1.0, 0.9, 1.0],
	# LAX +Def -SpD
	[1.0, 1.0, 1.1, 1.0, 1.0, 0.9],
	# TIMID +Spe -Atk
	[1.0, 0.9, 1.0, 1.1, 1.0, 1.0],
	# HASTY +Spe -Def
	[1.0, 1.0, 0.9, 1.1, 1.0, 1.0],
	# SERIOUS
	[1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
	# JOLLY +Spe -SpA
	[1.0, 1.0, 1.0, 1.1, 0.9, 1.0],
	# NAIVE +Spe -SpD
	[1.0, 1.0, 1.0, 1.1, 1.0, 0.9],
	# MODEST +SpA -Atk
	[1.0, 0.9, 1.0, 1.0, 1.1, 1.0],
	# MILD +SpA -Def
	[1.0, 1.0, 0.9, 1.0, 1.1, 1.0],
	# QUIET +SpA -Spe
	[1.0, 1.0, 1.0, 0.9, 1.1, 1.0],
	# BASHFUL
	[1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
	# RASH +SpA -SpD
	[1.0, 1.0, 1.0, 1.0, 1.1, 0.9],
	# CALM +SpD -Atk
	[1.0, 0.9, 1.0, 1.0, 1.0, 1.1],
	# GENTLE +SpD -Def
	[1.0, 1.0, 0.9, 1.0, 1.0, 1.1],
	# SASSY +SpD -Spe
	[1.0, 1.0, 1.0, 0.9, 1.0, 1.1],
	# CAREFUL +SpD -SpA
	[1.0, 1.0, 1.0, 1.0, 0.9, 1.1],
	# QUIRKY
	[1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
]


static func calc_hp(base: int, iv: int, ev: int, level: int) -> int:
	if base <= 1:
		return 1
	return int(floor((2.0 * base + iv + floor(ev / 4.0)) * level / 100.0)) + level + 10


static func calc_stat(base: int, iv: int, ev: int, level: int, nature: PokemonEnums.Nature,stat_index: int) -> int:
	var n: float = 1.0
	var ni: int = int(nature)
	if ni >= 0 and ni < NATURE_MOD.size() and stat_index >= 0 and stat_index < 6:
		n = float(NATURE_MOD[ni][stat_index])
	var inner: float = floor((2.0 * base + iv + floor(ev / 4.0)) * level / 100.0) + 5.0
	return int(floor(inner * n))


static func all_stats(base_stats: PackedInt32Array, ivs: PackedInt32Array, evs: PackedInt32Array, level: int, nature: PokemonEnums.Nature) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(6)
	out[0] = calc_hp(base_stats[0], ivs[0], evs[0], level)
	for i: int in range(1, 6):
		out[i] = calc_stat(base_stats[i], ivs[i], evs[i], level, nature, i)
	return out
