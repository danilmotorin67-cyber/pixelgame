extends Node

const MINUTES_PER_DAY := 24 * 60
const DAYS_PER_SEASON := 28
const SEASONS: PackedStringArray = ["spring", "summer", "autumn", "winter"]

var day_index: int = 0
var minutes: int = 6 * 60
var paused: bool = false
var seconds_per_10min: float = 8.0
var _acc: float = 0.0

var year: int:
	get:
		return 1 + int(day_index / 112)

var season_index: int:
	get:
		return int((day_index % 112) / DAYS_PER_SEASON)

var season: String:
	get:
		return SEASONS[season_index]

var day: int:
	get:
		return 1 + (day_index % DAYS_PER_SEASON)

var weekday_index: int:
	get:
		return day_index % 7

var weekday: String:
	get:
		return ["mon", "tue", "wed", "thu", "fri", "sat", "sun"][weekday_index]

var hour: int:
	get:
		return minutes / 60

var minute: int:
	get:
		return minutes % 60


func _process(delta: float) -> void:
	if paused:
		return
	_acc += delta
	var step := seconds_per_10min
	while _acc >= step:
		_acc -= step
		advance(10)


func advance(mins: int) -> void:
	var old_hour := hour
	minutes += mins
	Events.time_tick.emit(mins)
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		_next_day()
	if hour != old_hour:
		Events.hour_changed.emit(hour)


func _next_day() -> void:
	Events.day_ending.emit()
	day_index += 1
	minutes = 6 * 60
	if day == 1:
		Events.season_changed.emit(season)
	Events.day_started.emit(day_index)


func set_time(h: int, m: int = 0) -> void:
	minutes = clampi(h, 0, 23) * 60 + clampi(m, 0, 59)


func goto_date(y: int, season_name: String, d: int) -> void:
	var si := SEASONS.find(season_name)
	if si < 0:
		si = 0
	day_index = (y - 1) * 112 + si * DAYS_PER_SEASON + (d - 1)
	minutes = 6 * 60
	Events.day_started.emit(day_index)


func is_night() -> bool:
	return hour >= 21 or hour < 6


func moon() -> int:
	return day % 28


func tide_height() -> float:
	# Semi-diurnal approximation; refined in M1 from tides.json
	var t := float(minutes) / 60.0
	var phase := (float(day_index) * 0.53)
	return sin((t / 12.42) * TAU + phase) * 1.4


func serialize() -> Dictionary:
	return {"day_index": day_index, "minutes": minutes, "seconds_per_10min": seconds_per_10min}


func deserialize(d: Dictionary) -> void:
	day_index = int(d.get("day_index", 0))
	minutes = int(d.get("minutes", 360))
	seconds_per_10min = float(d.get("seconds_per_10min", 8.0))
