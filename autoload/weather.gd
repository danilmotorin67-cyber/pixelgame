extends Node

var current: String = "clear"
var wind: float = 0.2
var hmar_night: bool = false
var forecast: Array = ["clear","clear","cloud","rain","clear","fog","clear"]

func set_weather(id: String) -> void:
	current = id
	Events.weather_changed.emit(id)

func serialize() -> Dictionary:
	return {"current": current, "wind": wind, "hmar_night": hmar_night, "forecast": forecast}

func deserialize(d: Dictionary) -> void:
	current = str(d.get("current", "clear"))
	wind = float(d.get("wind", 0.2))
	hmar_night = bool(d.get("hmar_night", false))
	forecast = d.get("forecast", forecast)
