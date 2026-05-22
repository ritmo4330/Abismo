class_name DemoSceneDoor
extends Interactable

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = "InitialSpawn"
@export var auto_timeline: String = ""
@export var next_step_id: String = ""

var _is_transitioning: bool = false


func interact(_player: Player) -> void:
	if _is_transitioning:
		return
	if target_scene_path.is_empty():
		push_error("DemoSceneDoor target_scene_path is empty.")
		return

	_is_transitioning = true
	if ToastManager != null:
		ToastManager.show_notice("大门打开了。", "info", 1.5)
	if not next_step_id.is_empty():
		FlowManager.set_step(next_step_id)
	FlowManager.request_scene_change(target_scene_path, target_spawn_point, auto_timeline)
