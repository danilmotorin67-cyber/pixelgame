extends Node

# Renders a reproducible view of the actual cape scene for the project's screenshots.
func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	Game.reset()
	Game.world_seed = 42
	Clock.reset()
	Inventory.reset()
	Farm.reset()
	Inventory.add("seed_turnip", 15)
	Inventory.add("bread_rye", 3)
	Inventory.add("tool_hoe")
	Inventory.add("tool_can")
	Router.current_map = "cape"
	Router.spawn = Vector2(682, 245)
	for x in 7:
		for y in 4:
			var cell := Vector2i(x, y)
			Farm.till(cell)
			if (x + y) % 4 != 0:
				Farm.plant(cell, "seed_turnip")
				Farm.water(cell)
	for day in 4:
		Clock.start_next_day()
		Farm.advance_day()
		for x in 7:
			for y in 4:
				Farm.water(Vector2i(x, y))
	Weather.set_weather("clear")
	Clock.set_time(16, 20)
	Inventory.select_hotbar(2)
	var cape: Node2D = load("res://scenes/world/cape.tscn").instantiate()
	get_tree().root.add_child(cape)
	get_tree().current_scene = cape
	Clock.paused = true
	for frame in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	if screenshot.is_empty():
		push_error("Godot did not render the screenshot")
		get_tree().quit(1)
		return
	if screenshot.get_width() < 1920:
		screenshot.resize(1920, 1080, Image.INTERPOLATE_NEAREST)
	var error := screenshot.save_png("res://saltlight-cape.png")
	if error != OK:
		push_error("Could not save game screenshot: %d" % error)
	var player: Player = cape.get_node("Player")
	player.global_position = Vector2(658, 318)
	player.play_tool("can", Vector2(681, 318))
	player.tool_time = Player.TOOL_DURATION * 0.45
	player.tool_art.queue_redraw()
	for frame in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var action_image := get_viewport().get_texture().get_image()
	if action_image.get_width() < 1920:
		action_image.resize(1920, 1080, Image.INTERPOLATE_NEAREST)
	var action_error := action_image.save_png("res://saltlight-action.png")
	if action_error != OK:
		push_error("Could not save farm action screenshot: %d" % action_error)
	get_tree().quit(0 if error == OK and action_error == OK else 1)
