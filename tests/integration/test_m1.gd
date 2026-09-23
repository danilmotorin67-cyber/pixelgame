extends Node

# Run with: godot --headless --path . res://tests/integration/test_m1.tscn
const TEST_SAVE_ROOT := "user://saltlight_m1_test_saves"
var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var tree := get_tree()
	Save.save_root = TEST_SAVE_ROOT
	Save.current_slot = 2
	Game.reset()
	Game.world_seed = 42
	Clock.reset()
	Weather.start_day(0)
	var cape: Node2D = load("res://scenes/world/cape.tscn").instantiate()
	tree.root.add_child(cape)
	tree.current_scene = cape
	await tree.process_frame
	TranslationServer.set_locale("ru")
	_check(TranslationServer.translate("game.title") == "Солёный свет", "Russian CSV translation is unavailable")
	TranslationServer.set_locale("en")
	_check(TranslationServer.translate("game.title") == "Saltlight", "English CSV translation is unavailable")
	TranslationServer.set_locale("ru")

	_check(is_equal_approx(Clock.tide_amplitude(0), 1.4), "spring tide amplitude")
	_check(is_equal_approx(Clock.tide_amplitude(7), 0.6), "neap tide amplitude")
	Clock.day_index = 14
	Clock.set_time(12, 40)
	_check(Clock.tide_height() < -1.39, "Spring 15 story low tide")
	Clock.day_index = 0
	var high_minute := 0
	var low_minute := 0
	var high := -10.0
	var low := 10.0
	for at_minute in range(0, 1440, 10):
		var level := Clock.tide_height_at(0, at_minute)
		if level > high:
			high = level
			high_minute = at_minute
		if level < low:
			low = level
			low_minute = at_minute
	Clock.set_time(int(high_minute / 60), high_minute % 60)
	await tree.process_frame
	var first_shore_tile: CollisionShape2D = cape.get_node("TideShore/TideCollision").get_child(0)
	_check(not first_shore_tile.disabled, "high tide must block shore tile")
	Clock.set_time(int(low_minute / 60), low_minute % 60)
	await tree.process_frame
	_check(first_shore_tile.disabled, "low tide must unblock shore tile")
	_check(Weather.weather_for_day(0) == "clear" and Weather.weather_for_day(2) == "clear",
		"first three days must be clear")

	Game.set_flag("m1_roundtrip", true)
	Economy.money = 731
	var player: Player = cape.get_node("Player")
	player.global_position = Vector2(612, 401)
	Clock.set_time(19, 40)
	_check(Save.save_game(2), "save failed")
	var expected_game := JSON.stringify(Game.serialize())
	var expected_clock := JSON.stringify(Clock.serialize())
	var expected_weather := JSON.stringify(Weather.serialize())
	var expected_inventory := JSON.stringify(Inventory.serialize())
	Game.set_flag("m1_roundtrip", false)
	Economy.money = 1
	Clock.set_time(8, 0)
	Weather.set_weather("storm")
	_check(Save.load_game(2), "load failed")
	_check(JSON.stringify(Game.serialize()) == expected_game, "game/player state changed after load")
	_check(JSON.stringify(Clock.serialize()) == expected_clock, "clock changed after load")
	_check(JSON.stringify(Weather.serialize()) == expected_weather, "weather changed after load")
	_check(JSON.stringify(Inventory.serialize()) == expected_inventory, "inventory changed after load")
	_check(Economy.money == 731, "money changed after load")

	Game.set_flag("backup", true)
	_check(Save.save_game(2), "second save failed")
	var broken := FileAccess.open(Save._slot_path(2), FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	_check(Save.load_game(2) and not Game.flag("backup"), "backup recovery failed")
	_check(Router.goto_map("village", Vector2(1224, 488)), "cape to village failed")
	await tree.process_frame
	_check(tree.current_scene.get("map_id") == "village", "village scene did not load")
	_check(tree.current_scene.get_node("Terrain/To_cape") is RegionExit,
		"village return portal is missing")
	_check(tree.current_scene.get_node("Player").global_position == Vector2(1224, 488),
		"player arrived at wrong village entrance")
	_check(Router.goto_map("moor", Vector2(568, 904)), "village to moor failed")
	await tree.process_frame
	_check(tree.current_scene.get("map_id") == "moor", "moor scene did not load")
	tree.current_scene.get_node("Terrain/To_bird_cliffs").interact(tree.current_scene.get_node("Player"))
	_check(Router.current_map == "moor", "cliffs must be gated before the festival")
	for region_id in ["birch", "seal_shore", "wreck_bay", "bird_cliffs", "lagoon"]:
		_check(Router.goto_map(region_id), "cannot route to " + region_id)
		await tree.process_frame
		_check(tree.current_scene.get("map_id") == region_id, "wrong region: " + region_id)
		_check(tree.current_scene.get_node("Terrain").width > 0, "region failed to build: " + region_id)
		if region_id == "seal_shore":
			tree.current_scene.get_node("Terrain/To_wreck_bay").interact(tree.current_scene.get_node("Player"))
			_check(Router.current_map == "seal_shore", "bay must open on Spring 5")
	Clock.set_time(1, 50)
	Clock.paused = false
	var previous_day := Clock.day_index
	Clock.advance(10)
	await tree.process_frame
	var morning_scene := tree.current_scene
	_check(Clock.day_index == previous_day + 1 and Clock.minutes == 360,
		"fainting must start next day at 06:00")
	_check(morning_scene.get("map_id") == "cape", "morning must return to cape")
	_check(is_equal_approx(morning_scene.get_node("Player").energy, 135.0),
		"fainting must restore half energy")
	_check(Save.has_save(2), "night must create a save")
	_check(morning_scene.get_node("HUD/MorningPanel").visible, "night report must be shown")

	for file_path in Save._candidate_paths(2):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save._slot_path(2) + ".tmp"))
	Save.save_root = "user://saves"
	Save.current_slot = 0
	print("M1 integration: %d failure(s)" % failures.size())
	tree.quit(1 if not failures.is_empty() else 0)
