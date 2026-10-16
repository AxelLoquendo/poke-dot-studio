extends Object
class_name PokemonExp
## Experiencia total para estar a cierto nivel (PE / growth rate).


static func total_for_level(rate: PokemonEnums.GrowthRate, level: int) -> int:
	level = clampi(level, 1, 100)
	if level <= 1:
		return 0
	match rate:
		PokemonEnums.GrowthRate.FAST:
			return int(floor(0.8 * pow(level, 3)))
		PokemonEnums.GrowthRate.SLOW:
			return int(floor(1.25 * pow(level, 3)))
		PokemonEnums.GrowthRate.MEDIUM_SLOW:
			# Parabolic en PBS
			return int(floor(1.2 * pow(level, 3) - 15.0 * pow(level, 2) + 100.0 * level - 140.0))
		PokemonEnums.GrowthRate.ERRATIC:
			return _erratic(level)
		PokemonEnums.GrowthRate.FLUCTUATING:
			return _fluctuating(level)
		_:
			# MEDIUM_FAST
			return int(floor(pow(level, 3)))


static func level_from_exp(rate: PokemonEnums.GrowthRate, exp: int) -> int:
	var level: int = 1
	while level < 100 and total_for_level(rate, level + 1) <= exp:
		level += 1
	return level


static func exp_to_next(rate: PokemonEnums.GrowthRate, level: int, exp: int) -> int:
	if level >= 100:
		return 0
	return maxi(0, total_for_level(rate, level + 1) - exp)


static func _erratic(n: int) -> int:
	if n < 50:
		return int(floor(pow(n, 3) * (100.0 - n) / 50.0))
	if n < 68:
		return int(floor(pow(n, 3) * (150.0 - n) / 100.0))
	if n < 98:
		return int(floor(pow(n, 3) * floor((1911.0 - 10.0 * n) / 3.0) / 500.0))
	return int(floor(pow(n, 3) * (160.0 - n) / 100.0))


static func _fluctuating(n: int) -> int:
	if n < 15:
		return int(floor(pow(n, 3) * (floor((n + 1) / 3.0) + 24.0) / 50.0))
	if n < 36:
		return int(floor(pow(n, 3) * (n + 14.0) / 50.0))
	return int(floor(pow(n, 3) * (floor(n / 2.0) + 32.0) / 50.0))
