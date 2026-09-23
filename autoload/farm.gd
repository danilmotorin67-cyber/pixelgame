extends Node

var tiles: Dictionary = {}

func serialize() -> Dictionary:
	return {"tiles": tiles}

func deserialize(d: Dictionary) -> void:
	tiles = d.get("tiles", {})
