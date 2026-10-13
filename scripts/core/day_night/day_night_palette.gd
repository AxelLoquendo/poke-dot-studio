extends Object
class_name DayNightPalette
## Tonos horarios (PE PBDayNight::HOURLY_TONES) → Color multiplicativo.


static func _tone(r: float, g: float, b: float) -> Color:
	return Color(
		clampf(1.0 + r / 255.0, 0.15, 1.35),
		clampf(1.0 + g / 255.0, 0.15, 1.35),
		clampf(1.0 + b / 255.0, 0.15, 1.35),
		1.0
	)


## Índice 0 = 00:00 … 23 = 23:00
static var HOURLY: Array[Color] = [
	_tone(-70, -90, 15),
	_tone(-70, -90, 15),
	_tone(-70, -90, 15),
	_tone(-70, -90, 15),
	_tone(-60, -70, -5),
	_tone(-40, -50, -35),
	_tone(-40, -50, -35),
	_tone(-40, -50, -35),
	_tone(-40, -50, -35),
	_tone(-20, -25, -15),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(0, 0, 0),
	_tone(-5, -30, -20),
	_tone(-15, -60, -10),
	_tone(-15, -60, -10),
	_tone(-40, -75, 5),
	_tone(-70, -90, 15),
	_tone(-70, -90, 15),
]


static func color_at(hour: int, minute: int) -> Color:
	var h: int = posmod(hour, 24)
	var n: int = (h + 1) % 24
	var t: float = clampf(float(minute) / 60.0, 0.0, 1.0)
	return HOURLY[h].lerp(HOURLY[n], t)
