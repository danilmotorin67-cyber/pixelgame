extends Node

var lamp_on: bool = false
var fuel: float = 1.0
var cleanliness: float = 6.0
var fire_power: float = 0.0
var last_report: Dictionary = {}

func light_lamp(on_time: bool = true) -> void:
	lamp_on = true
	Events.lamp_lit.emit(on_time)

func serialize() -> Dictionary:
	return {"lamp_on": lamp_on, "fuel": fuel, "cleanliness": cleanliness, "fire_power": fire_power}

func deserialize(d: Dictionary) -> void:
	lamp_on = bool(d.get("lamp_on", false))
	fuel = float(d.get("fuel", 1.0))
	cleanliness = float(d.get("cleanliness", 6.0))
	fire_power = float(d.get("fire_power", 0.0))
