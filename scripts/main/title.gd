extends Control

func _ready() -> void:
	$Menu/NewGame.grab_focus()


func _on_new_game() -> void:
	Game.world_seed = randi()
	Clock.day_index = 0
	Clock.minutes = 17 * 60
	Economy.money = 500
	Inventory.add("seed_turnip", 15)
	Inventory.add("bread_rye", 3)
	Inventory.add("tea", 1)
	Inventory.add("tool_hoe", 1)
	Inventory.add("tool_can", 1)
	Inventory.add("tool_pick", 1)
	Inventory.add("tool_axe", 1)
	Inventory.add("tool_shovel", 1)
	Inventory.add("lantern_tin", 1)
	Inventory.add("oar", 1)
	Router.current_map = "cape"
	get_tree().change_scene_to_file("res://scenes/world/cape.tscn")


func _on_quit() -> void:
	get_tree().quit()
