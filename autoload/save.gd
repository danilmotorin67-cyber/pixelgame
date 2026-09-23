extends Node

const SLOT_COUNT := 3
var current_slot: int = 0

func _slot_path(n: int) -> String:
	return "user://saves/slot_%d.json" % n

func save_game(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot
	DirAccess.make_dir_recursive_absolute("user://saves")
	var payload := {
		"version": 1,
		"header": {
			"name": Game.hero.get("name", ""),
			"day_index": Clock.day_index,
			"money": Economy.money,
			"playtime_sec": Game.playtime_sec,
		},
		"game": Game.serialize(),
		"clock": Clock.serialize(),
		"weather": Weather.serialize(),
		"inventory": Inventory.serialize(),
		"economy": Economy.serialize(),
		"skills": Skills.serialize(),
		"knowledge": Knowledge.serialize(),
		"relationships": Relationships.serialize(),
		"quests": Quests.serialize(),
		"lighthouse": Lighthouse.serialize(),
		"graveyard": Graveyard.serialize(),
		"sea": Sea.serialize(),
		"farm": Farm.serialize(),
		"animals": Animals.serialize(),
		"settings": Settings.serialize(),
	}
	var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	return true

func load_game(slot: int) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		return false
	var d: Dictionary = parsed
	Game.deserialize(d.get("game", {}))
	Clock.deserialize(d.get("clock", {}))
	Weather.deserialize(d.get("weather", {}))
	Inventory.deserialize(d.get("inventory", {}))
	Economy.deserialize(d.get("economy", {}))
	Skills.deserialize(d.get("skills", {}))
	Knowledge.deserialize(d.get("knowledge", {}))
	Relationships.deserialize(d.get("relationships", {}))
	Quests.deserialize(d.get("quests", {}))
	Lighthouse.deserialize(d.get("lighthouse", {}))
	Graveyard.deserialize(d.get("graveyard", {}))
	Sea.deserialize(d.get("sea", {}))
	Farm.deserialize(d.get("farm", {}))
	Animals.deserialize(d.get("animals", {}))
	Settings.deserialize(d.get("settings", {}))
	current_slot = slot
	return true
