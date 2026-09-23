extends Node2D

@export var map_id: String = "cape"

@onready var hud: CanvasLayer = $HUD
@onready var time_label: Label = $HUD/TimePanel/TimeLabel
@onready var tide_label: Label = $HUD/TidePanel/TideLabel
@onready var weather_label: Label = $HUD/WeatherLabel
@onready var compass_label: Label = $HUD/Compass/CompassLabel
@onready var console: LineEdit = $HUD/Console
@onready var console_out: Label = $HUD/ConsoleOut
@onready var morning_panel: Panel = $HUD/MorningPanel
@onready var morning_text: Label = $HUD/MorningPanel/MorningText

const WEATHER_NAMES := {
	"clear": "Ясно", "cloud": "Облачно", "rain": "Дождь",
	"fog": "Туман", "storm": "Шторм", "snow": "Снег", "blizzard": "Метель",
}

var _was_paused_before_console: bool = false


func _ready() -> void:
	if map_id == "":
		map_id = Router.current_map
	Router.current_map = map_id
	Clock.paused = not Night.pending_report.is_empty()
	Events.map_entered.emit(map_id)
	Events.time_tick.connect(_on_world_changed)
	Events.tide_changed.connect(_on_world_changed)
	Events.weather_changed.connect(_on_world_changed)
	Events.money_changed.connect(_on_world_changed)
	Events.night_resolved.connect(_on_night_resolved)
	console.visible = false
	console_out.visible = false
	morning_panel.visible = false
	if map_id != "cape":
		var info: Dictionary = Data.tables.get("regions", {}).get(map_id, {})
		$HUD/Hint.text = "%s   E: переход" % str(info.get("title", map_id))
	else:
		$HUD/Hint.text = "WASD ходить  E: кровать  Сольвик ←"
	_refresh_hud()
	if not Night.pending_report.is_empty():
		var report := Night.pending_report.duplicate(true)
		Night.pending_report.clear()
		call_deferred("_deliver_report", report)


func _deliver_report(report: Dictionary) -> void:
	Events.night_resolved.emit(report)


func _on_world_changed(_value: Variant = null) -> void:
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if morning_panel.visible:
		return
	if event.is_action_pressed("debug_console"):
		console.visible = not console.visible
		console_out.visible = console.visible
		if console.visible:
			_was_paused_before_console = Clock.paused
			Clock.paused = true
			console.grab_focus()
			console.text = ""
		else:
			Clock.paused = _was_paused_before_console
			console.release_focus()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause") and not console.visible:
		Clock.paused = not Clock.paused


func _on_console_submitted(text: String) -> void:
	var res := Debug.exec(text)
	console_out.text = res
	console.clear()
	Events.debug_message.emit(res)
	_refresh_hud()


func _on_night_resolved(report: Dictionary) -> void:
	var reason := "Вы потеряли сознание." if report["fainted"] else "Ночь прошла спокойно."
	var loss := "\nПотеряно: %d кр." % report["money_lost"] if report["money_lost"] > 0 else ""
	var save_line := "Игра сохранена." if report["saved"] else "Ошибка сохранения."
	morning_text.text = "Утро, %s %d. %s\n%s%s\n%s" % [
		report["season"], report["day"], WEATHER_NAMES.get(report["weather"], ""),
		reason, loss, save_line]
	morning_panel.visible = true
	Clock.paused = true
	_refresh_hud()
	$HUD/MorningPanel/MorningOk.grab_focus()


func _on_morning_ok() -> void:
	morning_panel.visible = false
	Clock.paused = false
	$HUD/MorningPanel/MorningOk.release_focus()


func _refresh_hud() -> void:
	var wd := {"mon":"Пн","tue":"Вт","wed":"Ср","thu":"Чт","fri":"Пт","sat":"Сб","sun":"Вс"}
	var sn := {"spring":"Весна","summer":"Лето","autumn":"Осень","winter":"Зима"}
	time_label.text = "%s, %s %d  %02d:%02d" % [
		wd.get(Clock.weekday, Clock.weekday),
		sn.get(Clock.season, Clock.season),
		Clock.day,
		Clock.hour,
		Clock.minute,
	]
	var peak := Clock.next_high_tide()
	tide_label.text = "%s %.1f    Пик %02d:%02d" % [
		"↑" if Clock.tide_rising() else "↓", Clock.tide_height(),
		peak / 60, peak % 60]
	weather_label.text = "%s · %s" % [WEATHER_NAMES.get(Weather.current, ""), Clock.moon_name()]
	compass_label.text = "Свет %d  Покой %d  Море %d   %d кр" % [
		int(Lighthouse.fire_power),
		int(Graveyard.peace),
		int(Sea.mercy),
		Economy.money,
	]
