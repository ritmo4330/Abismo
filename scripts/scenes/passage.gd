class_name Passage
extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if target_scene_path.is_empty():
		push_error("Passage target_scene_path is empty.")
		return

	EventBus.scene_change_requested.emit(target_scene_path, target_spawn_point)
