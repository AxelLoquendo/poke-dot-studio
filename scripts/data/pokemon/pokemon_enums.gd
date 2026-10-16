extends Object
class_name PokemonEnums

enum TypeId {
	NONE = -1,
	NORMAL, FIGHTING, FLYING, POISON, GROUND, ROCK, BUG, GHOST,
	STEEL, MYSTERY, FIRE, WATER, GRASS, ELECTRIC, PSYCHIC, ICE,
	DRAGON, DARK, FAIRY, STELLAR,
}

enum StatId { HP, ATTACK, DEFENSE, SPEED, SPECIAL_ATTACK, SPECIAL_DEFENSE }

enum GrowthRate { MEDIUM_FAST, ERRATIC, FLUCTUATING, MEDIUM_SLOW, FAST, SLOW }

enum GenderRatio {
	ALWAYS_MALE,
	FEMALE_ONE_EIGHTH,
	FEMALE_25_PERCENT,
	FEMALE_50_PERCENT,
	FEMALE_75_PERCENT,
	FEMALE_SEVEN_EIGHTHS,
	ALWAYS_FEMALE,
	GENDERLESS,
}

enum EggGroup {
	NONE, MONSTER, WATER_1, BUG, FLYING, FIELD, FAIRY, GRASS,
	HUMAN_LIKE, WATER_3, MINERAL, AMORPHOUS, WATER_2, DITTO, DRAGON, UNDISCOVERED,
}

enum Nature {
	HARDY, LONELY, BRAVE, ADAMANT, NAUGHTY,
	BOLD, DOCILE, RELAXED, IMPISH, LAX,
	TIMID, HASTY, SERIOUS, JOLLY, NAIVE,
	MODEST, MILD, QUIET, BASHFUL, RASH,
	CALM, GENTLE, SASSY, CAREFUL, QUIRKY,
}

enum MoveCategory { PHYSICAL, SPECIAL, STATUS }

enum BodyColor { RED, BLUE, YELLOW, GREEN, BLACK, BROWN, PURPLE, GRAY, WHITE, PINK }

enum BodyShape {
	HEAD, SERPENTINE, FINNED, HEAD_ARMS, HEAD_BASE, BIPEDAL_TAIL,
	HEAD_LEGS, QUADRUPED, WINGED, MULTIPEDAL, MULTI_WINGED, INSECTOID,
	HEAD_TORSO, BIPEDAL,
}

const STAT_COUNT: int = 6


static func type_from_key(key: String) -> TypeId:
	var k: String = key.strip_edges().to_upper()
	if k.is_empty():
		return TypeId.NONE
	if k in TypeId:
		return TypeId[k] as TypeId
	return TypeId.NONE


static func growth_from_key(key: String) -> GrowthRate:
	match key.strip_edges():
		"Fast": return GrowthRate.FAST
		"Slow": return GrowthRate.SLOW
		"Erratic": return GrowthRate.ERRATIC
		"Fluctuating": return GrowthRate.FLUCTUATING
		"Parabolic", "MediumSlow", "Medium Slow": return GrowthRate.MEDIUM_SLOW
		_: return GrowthRate.MEDIUM_FAST


static func gender_from_key(key: String) -> GenderRatio:
	match key.strip_edges():
		"AlwaysMale": return GenderRatio.ALWAYS_MALE
		"AlwaysFemale": return GenderRatio.ALWAYS_FEMALE
		"Genderless": return GenderRatio.GENDERLESS
		"FemaleOneEighth": return GenderRatio.FEMALE_ONE_EIGHTH
		"Female25Percent": return GenderRatio.FEMALE_25_PERCENT
		"Female75Percent": return GenderRatio.FEMALE_75_PERCENT
		"FemaleSevenEighths": return GenderRatio.FEMALE_SEVEN_EIGHTHS
		_: return GenderRatio.FEMALE_50_PERCENT


static func egg_from_key(key: String) -> EggGroup:
	match key.strip_edges():
		"Monster": return EggGroup.MONSTER
		"Water1": return EggGroup.WATER_1
		"Water2": return EggGroup.WATER_2
		"Water3": return EggGroup.WATER_3
		"Bug": return EggGroup.BUG
		"Flying": return EggGroup.FLYING
		"Field": return EggGroup.FIELD
		"Fairy": return EggGroup.FAIRY
		"Grass": return EggGroup.GRASS
		"Humanlike", "HumanLike": return EggGroup.HUMAN_LIKE
		"Mineral": return EggGroup.MINERAL
		"Amorphous": return EggGroup.AMORPHOUS
		"Ditto": return EggGroup.DITTO
		"Dragon": return EggGroup.DRAGON
		"Undiscovered": return EggGroup.UNDISCOVERED
		_: return EggGroup.NONE


static func color_from_key(key: String) -> BodyColor:
	var k: String = key.strip_edges().to_upper()
	if k in BodyColor:
		return BodyColor[k] as BodyColor
	return BodyColor.GREEN


static func shape_from_key(key: String) -> BodyShape:
	match key.strip_edges():
		"Head": return BodyShape.HEAD
		"Serpentine": return BodyShape.SERPENTINE
		"Finned": return BodyShape.FINNED
		"HeadArms": return BodyShape.HEAD_ARMS
		"HeadBase": return BodyShape.HEAD_BASE
		"BipedalTail": return BodyShape.BIPEDAL_TAIL
		"HeadLegs": return BodyShape.HEAD_LEGS
		"Quadruped": return BodyShape.QUADRUPED
		"Winged": return BodyShape.WINGED
		"Multipedal": return BodyShape.MULTIPEDAL
		"MultiWinged": return BodyShape.MULTI_WINGED
		"Insectoid": return BodyShape.INSECTOID
		"HeadTorso": return BodyShape.HEAD_TORSO
		"Bipedal": return BodyShape.BIPEDAL
		_: return BodyShape.QUADRUPED


static func category_from_key(key: String) -> MoveCategory:
	match key.strip_edges():
		"Special": return MoveCategory.SPECIAL
		"Status": return MoveCategory.STATUS
		_: return MoveCategory.PHYSICAL
