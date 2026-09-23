extends Node

var slots: Array = []
const MAX_SLOTS := 36
const HOTBAR := 12

func _ready() -> void:
	reset()


func reset() -> void:
	slots.clear()
	for i in MAX_SLOTS:
		slots.append({"id": "", "count": 0, "quality": 0, "meta": {}})

func add(id: String, count: int = 1, quality: int = 0) -> int:
	var left := count
	for s in slots:
		if s["id"] == id and int(s["quality"]) == quality:
			var can := 99 - int(s["count"])
			var n := mini(can, left)
			s["count"] = int(s["count"]) + n
			left -= n
			if left <= 0:
				break
	if left > 0:
		for s in slots:
			if s["id"] == "":
				var n := mini(99, left)
				s["id"] = id
				s["count"] = n
				s["quality"] = quality
				left -= n
				if left <= 0:
					break
	var added := count - left
	if added > 0:
		Events.item_added.emit(id, added)
	return added

func count_of(id: String) -> int:
	var n := 0
	for s in slots:
		if s["id"] == id:
			n += int(s["count"])
	return n

func take(id: String, count: int = 1) -> bool:
	if count_of(id) < count:
		return false
	var left := count
	for s in slots:
		if s["id"] == id:
			var n := mini(int(s["count"]), left)
			s["count"] = int(s["count"]) - n
			left -= n
			if int(s["count"]) <= 0:
				s["id"] = ""
				s["quality"] = 0
			if left <= 0:
				return true
	return left <= 0

func serialize() -> Dictionary:
	return {"slots": slots}

func deserialize(d: Dictionary) -> void:
	var loaded = d.get("slots", [])
	if loaded is Array and loaded.size() == MAX_SLOTS:
		slots = loaded
