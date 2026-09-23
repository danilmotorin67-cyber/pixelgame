extends Node2D

# Six rows of 16px shoreline tiles bridge the permanent sea and dry ground.
# Each cell has its own elevation; only tiles crossing the tide threshold change collision.
const TILE := 16
const FIRST_ROW := 54
const ROWS := 6
const COLUMNS := 90
const WATER := Color("#24465b")
const FOAM := Color("#a7bbad")
const WET_SAND := Color("#806c58")
const DRY_SAND := Color("#9b8970")

var _cells: Array[Dictionary] = []
var _body: StaticBody2D


func _ready() -> void:
	_body = StaticBody2D.new()
	_body.name = "TideCollision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	var tile_shape := RectangleShape2D.new()
	tile_shape.size = Vector2(TILE, TILE)
	for row in ROWS:
		for column in COLUMNS:
			var shape := CollisionShape2D.new()
			shape.shape = tile_shape
			shape.position = Vector2(column * TILE + TILE / 2, (FIRST_ROW + row) * TILE + TILE / 2)
			shape.disabled = true
			_body.add_child(shape)
			var elevation := 1.25 - float(row) * 0.5 + sin(float(column) * 0.37) * 0.06
			_cells.append({"x": column * TILE, "y": (FIRST_ROW + row) * TILE,
				"z": elevation, "wet": false, "flooded": false, "shape": shape})
	Events.tide_changed.connect(_on_tide_changed)
	_on_tide_changed(Clock.tide_height())


func _on_tide_changed(height: float) -> void:
	for cell in _cells:
		var flooded: bool = height >= float(cell["z"])
		cell["wet"] = height >= float(cell["z"]) - 0.5
		if flooded != bool(cell["flooded"]):
			cell["flooded"] = flooded
			var shape: CollisionShape2D = cell["shape"]
			shape.set_deferred("disabled", not flooded)
	queue_redraw()


func _draw() -> void:
	for cell in _cells:
		var x: int = cell["x"]
		var y: int = cell["y"]
		var rect := Rect2(x, y, TILE, TILE)
		if cell["flooded"]:
			draw_rect(rect, WATER)
			if (x / TILE + y / TILE) % 5 == 0:
				draw_rect(Rect2(x, y, 6, 1), FOAM)
		else:
			draw_rect(rect, WET_SAND if cell["wet"] else DRY_SAND)
			if (x / TILE * 13 + y / TILE * 7) % 11 == 0:
				draw_rect(Rect2(x + 3, y + 8, 2, 1), WET_SAND)
