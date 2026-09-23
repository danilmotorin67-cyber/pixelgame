extends Node2D

const TILE := 16
const REACH := 48.0


func _ready() -> void:
	Events.farm_changed.connect(queue_redraw)
	queue_redraw()


func use_at(world_position: Vector2, player: Player) -> bool:
	var local := to_local(world_position)
	var cell := Vector2i(floori(local.x / TILE), floori(local.y / TILE))
	if cell.x < 0 or cell.y < 0 or cell.x >= Farm.WIDTH or cell.y >= Farm.HEIGHT:
		return false
	if player.global_position.distance_to(to_global(Vector2(cell) * TILE + Vector2(8, 8))) > REACH:
		_hint("Подойди ближе к грядке.")
		return true
	var plot := Farm.get_tile(cell)
	if not plot.is_empty() and bool(plot["ready"]):
		_hint("Репа собрана." if Farm.harvest(cell) else "Нет места для урожая.")
		return true
	var selected := Inventory.selected_id()
	if selected in ["tool_hoe", "tool_can"] and player.energy < 2.0:
		_hint("Нужен отдых, сил на работу нет.")
		return true
	if selected == "tool_hoe":
		if Farm.till(cell):
			player.energy -= 2.0
			_hint("Земля взрыхлена. Теперь посади семена.")
		else:
			_hint("Здесь уже есть грядка.")
	elif selected == "tool_can":
		if Farm.water(cell):
			player.energy -= 2.0
			_hint("Грядка полита.")
		else:
			_hint("Сначала взрыхли землю или дождись следующего дня.")
	elif Farm.plant(cell, selected):
		_hint("Посажено. Для роста нужен полив.")
	else:
		_hint("Выбери мотыгу, лейку или семена репы.")
	return true


func _hint(message: String) -> void:
	var hint := get_parent().get_node_or_null("HUD/Hint") as Label
	if hint:
		hint.text = message


func _draw() -> void:
	for y in Farm.HEIGHT:
		for x in Farm.WIDTH:
			var cell := Vector2i(x, y)
			var plot := Farm.get_tile(cell)
			var at := Vector2(cell) * TILE
			draw_rect(Rect2(at, Vector2(TILE - 1, TILE - 1)),
				Color("#735e47") if plot.is_empty() else
				(Color("#443b31") if bool(plot["watered"]) else Color("#594633")))
			if plot.is_empty():
				continue
			if str(plot["crop"]) != "":
				var height := mini(3 + int(plot["days"]) * 2, 10)
				draw_rect(Rect2(at + Vector2(6, 12 - height), Vector2(4, height)), Color("#81ab52"))
				if bool(plot["ready"]):
					draw_rect(Rect2(at + Vector2(4, 8), Vector2(8, 5)), Color("#d9bf98"))
