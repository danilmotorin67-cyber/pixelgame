extends Node

var current_map: String = ""
var spawn: Vector2 = Vector2(48, 48)

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
