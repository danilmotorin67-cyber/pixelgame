extends CharacterBody2D
class_name Player

@export var walk_speed: float = 70.0
@export var slow_speed: float = 40.0
@export var dodge_speed: float = 140.0

var facing: Vector2 = Vector2.DOWN
var energy: float = 270.0
var health: float = 100.0
var cold: float = 0.0
var lantern_on: bool = false
var _dodge_t: float = 0.0
var _walk_time: float = 0.0

@onready var sprite: Sprite2D = $Body


func _ready() -> void:
	if Game.player_state.is_empty():
		global_position = Router.spawn
	else:
		restore_state(Game.player_state)


func _physics_process(delta: float) -> void:
	if Cutscenes.playing or Clock.paused:
		velocity = Vector2.ZERO
		return
	if _dodge_t > 0.0:
		_dodge_t -= delta
		move_and_slide()
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.1:
		facing = dir.normalized()
	var spd := slow_speed if Input.is_action_pressed("walk_slow") else walk_speed
	velocity = dir * spd
	move_and_slide()
	if dir.length() > 0.1:
		_walk_time += delta
		sprite.frame = int(_walk_time * 5.0) % 2
	else:
		sprite.frame = 0
	_tint()


func _unhandled_input(event: InputEvent) -> void:
	if Clock.paused:
		return
	if event.is_action_pressed("dodge") and _dodge_t <= 0.0:
		_dodge_t = 0.18
		velocity = facing * dodge_speed
	if event.is_action_pressed("lantern"):
		lantern_on = not lantern_on
	if event.is_action_pressed("interact"):
		_try_interact()


func _try_interact() -> void:
	var space := get_world_2d().direct_space_state
	var to := global_position + facing * 16.0
	var q := PhysicsRayQueryParameters2D.create(global_position, to)
	q.collide_with_areas = true
	q.hit_from_inside = true
	q.collision_mask = 8
	var hit := space.intersect_ray(q)
	if hit:
		var n: Node = hit.get("collider")
		if n and n.has_method("interact"):
			n.interact(self)


func _tint() -> void:
	if sprite:
		sprite.modulate = Color.WHITE if not lantern_on else Color(1.0, 0.92, 0.73)


func serialize_state() -> Dictionary:
	return {"x": global_position.x, "y": global_position.y,
		"energy": energy, "health": health, "cold": cold,
		"lantern_on": lantern_on, "face_x": facing.x, "face_y": facing.y}


func restore_state(state: Dictionary) -> void:
	global_position = Vector2(float(state.get("x", 600)), float(state.get("y", 360)))
	energy = float(state.get("energy", 270.0))
	health = float(state.get("health", 100.0))
	cold = float(state.get("cold", 0.0))
	lantern_on = bool(state.get("lantern_on", false))
	facing = Vector2(float(state.get("face_x", 0)), float(state.get("face_y", 1)))
	velocity = Vector2.ZERO
	_tint()
