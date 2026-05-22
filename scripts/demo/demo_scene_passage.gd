class_name DemoScenePassage
extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = "InitialSpawn"
@export var auto_timeline: String = ""
@export var required_flag: String = ""
@export var blocked_notice: String = ""
@export var next_step_id: String = ""

var _is_transitioning: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _is_transitioning:
		return
	if not body.is_in_group("player"):
		return
	if not required_flag.is_empty() and not DataManager.get_world_flag(required_flag):
		if not blocked_notice.is_empty() and ToastManager != null:
			ToastManager.show_notice(blocked_notice, "warning")
		return
	if target_scene_path.is_empty():
		push_error("DemoScenePassage target_scene_path is empty.")
		return

	_is_transitioning = true
	if not next_step_id.is_empty():
		FlowManager.set_step(next_step_id)
	FlowManager.request_scene_change(target_scene_path, target_spawn_point, auto_timeline)
