extends Node

var current_map: String = ""
var spawn: Vector2 = Vector2(600, 360)


func serialize() -> Dictionary:
	return {"current_map": current_map, "spawn_x": spawn.x, "spawn_y": spawn.y}


func deserialize(d: Dictionary) -> void:
	current_map = str(d.get("current_map", "cape"))
	spawn = Vector2(float(d.get("spawn_x", 600)), float(d.get("spawn_y", 360)))

func goto_map(id: String, pos: Vector2 = Vector2.ZERO) -> void:
	current_map = id
	if pos != Vector2.ZERO:
		spawn = pos
	Events.map_entered.emit(id)
	var tree := get_tree()
	if tree:
		var path := "res://scenes/world/%s.tscn" % id
		if ResourceLoader.exists(path):
			tree.change_scene_to_file(path)
