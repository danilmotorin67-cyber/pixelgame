extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var time_label: Label = $HUD/TimePanel/TimeLabel
@onready var compass_label: Label = $HUD/Compass/CompassLabel
@onready var console: LineEdit = $HUD/Console
@onready var console_out: Label = $HUD/ConsoleOut


func _ready() -> void:
	Clock.paused = false
	if Clock.day_index == 0 and Clock.hour < 17:
		Clock.minutes = 17 * 60
	Events.map_entered.emit("cape")
	console.visible = false
	console_out.visible = false
	_refresh_hud()


func _process(_delta: float) -> void:
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_console"):
		console.visible = not console.visible
		console_out.visible = console.visible
		if console.visible:
			console.grab_focus()
			console.text = ""
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause") and not console.visible:
		Clock.paused = not Clock.paused


func _on_console_submitted(text: String) -> void:
	var res := Debug.exec(text)
	console_out.text = res
	console.clear()
	Events.debug_message.emit(res)


func _refresh_hud() -> void:
	var wd := {"mon":"Пн","tue":"Вт","wed":"Ср","thu":"Чт","fri":"Пт","sat":"Сб","sun":"Вс"}
	var sn := {"spring":"Весна","summer":"Лето","autumn":"Осень","winter":"Зима"}
	time_label.text = "%s, %s %d  %02d:%02d  %s" % [
		wd.get(Clock.weekday, Clock.weekday),
		sn.get(Clock.season, Clock.season),
		Clock.day,
		Clock.hour,
		Clock.minute,
		Weather.current,
	]
	compass_label.text = "Свет %d  Покой %d  Море %d   %d кр" % [
		int(Lighthouse.fire_power),
		int(Graveyard.peace),
		int(Sea.mercy),
		Economy.money,
	]
