class_name Door
extends Interactable

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var flow_signal_name: String = ""


func interact(_player: Player) -> void:
	if not flow_signal_name.is_empty():
		EventBus.flow_signal_requested.emit(flow_signal_name)
		return

	if target_scene_path.is_empty():
		push_error("Door target_scene_path is empty.")
		return

	EventBus.scene_change_requested.emit(target_scene_path, target_spawn_point)
