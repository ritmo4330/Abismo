class_name DemoTimelineTrigger
extends Area2D

@export var timeline_name: String = ""
@export var played_flag: String = ""
@export var one_shot: bool = true

var _has_triggered: bool = false


func _ready() -> void:
	monitoring = true
	collision_mask = 0xFFFFFFFF
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if one_shot and _has_triggered:
		return
	if body == null or not body.is_in_group("player"):
		return
	if not played_flag.is_empty() and DataManager.get_world_flag(played_flag):
		return
	if timeline_name.is_empty():
		push_error("DemoTimelineTrigger timeline_name is empty.")
		return
	if SceneManager != null and SceneManager.is_transitioning:
		return
	if Dialogic != null and Dialogic.current_timeline != null:
		return

	_has_triggered = true
	if not played_flag.is_empty():
		DataManager.set_world_flag(played_flag, true)
	EventBus.dialogue_requested.emit(timeline_name)
