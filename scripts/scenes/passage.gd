class_name Passage
extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _should_block_room_exit():
		return
	if target_scene_path.is_empty():
		push_error("Passage target_scene_path is empty.")
		return

	if _request_standalone_scene_change():
		return
	EventBus.scene_change_requested.emit(target_scene_path, target_spawn_point)


func _should_block_room_exit() -> bool:
	if FlowManager == null:
		return false
	if not FlowManager.has_method("should_block_current_room_exit"):
		return false
	return FlowManager.should_block_current_room_exit()


func _request_standalone_scene_change() -> bool:
	if FlowManager == null or not FlowManager.has_method("request_scene_change"):
		return false
	if SceneManager == null or not SceneManager.has_method("is_initialized"):
		return false
	if SceneManager.is_initialized():
		return false
	return FlowManager.request_scene_change(target_scene_path, target_spawn_point)
