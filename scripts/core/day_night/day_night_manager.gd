extends Node
## Reloj y consultas de periodo. No dibuja.
## Autoload: DayNightManager

signal time_changed(hour: int, minute: int)
signal period_changed(period: Period)

enum Period { MORNING, DAY, EVENING, NIGHT }

var hour: int = 12
var minute: int = 0
var period: Period = Period.DAY
var outdoor_tint_enabled: bool = true
var use_system_clock: bool = true

var _accum: float = 0.0
const POLL_INTERVAL: float = 1.0


func _ready() -> void:
	_tick()


func _process(delta: float) -> void:
	_accum += delta
	if _accum < POLL_INTERVAL:
		return
	_accum = 0.0
	_tick()


func _tick() -> void:
	var h: int = hour
	var m: int = minute
	if use_system_clock:
		var now: Dictionary = Time.get_datetime_dict_from_system()
		h = int(now.get("hour", 12))
		m = int(now.get("minute", 0))
	_set_time(h, m)


func _set_time(h: int, m: int) -> void:
	var changed: bool = h != hour or m != minute
	hour = h
	minute = m
	var p: Period = period_for_hour(h)
	if p != period:
		period = p
		period_changed.emit(period)
	if changed:
		time_changed.emit(hour, minute)


static func period_for_hour(h: int) -> Period:
	if h >= 5 and h < 10:
		return Period.MORNING
	if h >= 10 and h < 18:
		return Period.DAY
	if h >= 18 and h < 20:
		return Period.EVENING
	return Period.NIGHT


func is_day() -> bool:
	return hour >= 5 and hour < 20


func is_night() -> bool:
	return not is_day()


func is_morning() -> bool:
	return hour >= 5 and hour < 10


func is_evening() -> bool:
	return hour >= 17 and hour < 20


func current_tint() -> Color:
	if not outdoor_tint_enabled:
		return Color.WHITE
	return DayNightPalette.color_at(hour, minute)


func set_outdoor(enabled: bool) -> void:
	outdoor_tint_enabled = enabled
